/* zxrun - Spectrum 48K sin pantalla para pruebas de regresión de MK1.
 *
 * Arranca la ROM, coloca el binario del juego en su dirección de origen,
 * salta a él y lo ejecuta N frames con una secuencia de teclas programada.
 * Puede volcar capturas PNG y hashes de la memoria de vídeo.
 *
 * Uso:
 *   zxrun juego.bin [opciones]
 *     -a DIR        dirección de carga y de arranque (24200)
 *     -f N          frames a ejecutar tras el arranque (500)
 *     -k GUION      teclas: "frame:tecla+,frame:tecla-,..." (ver abajo)
 *     -s F1,F2,...  frames en los que sacar captura
 *     -o PREFIJO    prefijo de las capturas: PREFIJO_FFFFF.png (shot)
 *     -h            imprimir hash de pantalla en cada captura
 *     -p PC         avisa si la CPU ejecuta en esta dirección (detector de "colgado")
 *     -d DIR,LEN    al terminar, vuelca LEN bytes de memoria desde DIR (repetible)
 *     -t SP         trampa: cuando la pila vale SP (p.ej. tras el "ld sp" de main) y luego sube por encima
 *                   (la pila se ha desequilibrado), para e imprime los
 *                   últimos 4096 PC con su SP
 *     -rt FRAME     trampa: para la primera vez que se ejecuta la ROM (< 0x4000)
 *                   a partir de ese frame
 *     -tr DESDE HASTA  con -t, solo comprueba cuando el PC está en ese rango
 *     -prof F1 FICH perfil: desde el frame F1, cuenta los ciclos de reloj gastados en
 *                   cada dirección y los guarda en FICH (65536 enteros de 32 bits)
 *     -count DIR F1 cuenta cuántas veces se ejecuta DIR desde el frame F1 e imprime
 *                   los ciclos de reloj medios entre ejecuciones (p.ej. _move =
 *                   ciclos por frame de juego)
 *     -incl DIR F1  tiempo inclusivo: desde el frame F1, mide los ciclos entre que se
 *                   entra en la función DIR y se vuelve de ella (incluye lo que
 *                   llame) e imprime llamadas y ciclos medios por llamada
 *     -sp SP        pone la pila en SP antes de saltar al juego (como un cargador)
 *     -128          emula un Spectrum 128K
 *     -page N FICH  (128K) carga FICH en el banco de RAM N, desde su inicio
 *                   (lo mismo que hace el cargador con reubica). Repetible.
 *
 * Teclas: un carácter (0-9, a-z, ' '=espacio, '\n'=enter escrito como "ent"),
 * seguido de + (pulsar) o - (soltar). Ejemplo: "60:1+,62:1-,100:p+,140:p-".
 *

 * Compilar: gcc -O2 -w -o tests/zxrun/zxrun tests/zxrun/zxrun.c
 *
 * Basado en los emuladores de floooh/chips (licencia zlib).
 */
#define CHIPS_IMPL
#include "chips/chips_common.h"
#include "chips/z80.h"
#include "chips/beeper.h"
#include "chips/ay38910.h"
#include "chips/kbd.h"
#include "chips/mem.h"
#include "chips/clk.h"
#include "chips/zx.h"
#include "zx48k_rom.h"
#include "zx128k_rom.h"
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "../../src/utils/src/fbpng-linux/stb_image_write.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static zx_t sys;

typedef struct { int frame; int key; int down; } KEYEV;
static KEYEV evs[4096]; static int nevs;
static int shots[1024]; static int nshots;

static uint8_t rd(uint16_t a) { return mem_rd(&sys.mem, a); }

static uint32_t screen_hash(void) {
	uint32_t h = 2166136261u;
	for (int a = 16384; a < 16384 + 6912; a++) { h ^= rd(a); h *= 16777619u; }
	return h;
}

static void save_png(const char *fn) {
	static const uint32_t pal[16] = {
		0x000000, 0x0000D7, 0xD70000, 0xD700D7, 0x00D700, 0x00D7D7, 0xD7D700, 0xD7D7D7,
		0x000000, 0x0000FF, 0xFF0000, 0xFF00FF, 0x00FF00, 0x00FFFF, 0xFFFF00, 0xFFFFFF };
	static uint8_t img[192][256][3];
	for (int y = 0; y < 192; y++) for (int cx = 0; cx < 32; cx++) {
		uint16_t pa = 16384 | ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2) | cx;
		uint8_t px = rd(pa), at = rd(22528 + (y >> 3) * 32 + cx);
		int br = (at & 64) ? 8 : 0, ink = (at & 7) + br, pap = ((at >> 3) & 7) + br;
		for (int b = 0; b < 8; b++) {
			uint32_t c = pal[(px & (128 >> b)) ? ink : pap];
			uint8_t *d = img[y][cx * 8 + b]; d[0] = c >> 16; d[1] = c >> 8; d[2] = c;
		}
	}
	stbi_write_png(fn, 256, 192, 3, img, 256 * 3);
}

static int keycode(const char *s, int len) {
	if (len == 3 && !strncmp(s, "ent", 3)) return 0x0D;
	if (len == 3 && !strncmp(s, "spc", 3)) return ' ';
	if (len == 1) return s[0];
	return -1;
}

static void parse_keys(const char *s) {
	while (*s) {
		int f = atoi(s); s = strchr(s, ':'); if (!s) break; s++;
		const char *k = s; while (*s && *s != '+' && *s != '-') s++;
		int code = keycode(k, (int)(s - k)); int down = (*s == '+');
		if (code < 0 || !*s) { fprintf(stderr, "tecla mal: %s\n", k); exit(2); }
		evs[nevs++] = (KEYEV){ f, code, down }; s++;
		if (*s == ',') s++;
	}
}

int main(int argc, char **argv) {
	int dumps[64][2], ndumps = 0, is128 = 0, npages = 0, trap = 0, proffrom = -1;
	const char *proffile = NULL; int cntaddr = -1, cntfrom = 0; uint64_t cnt = 0, cntticks = 0;
	int initsp = -1;
	int incaddr = -1, incfrom = 0, inside = 0; uint16_t incsp = 0; uint64_t inccalls = 0, incticks = 0; static uint32_t prof[65536]; uint16_t curpc = 0;
	uint16_t ring[4096]; uint16_t ringsp[4096]; int rp = 0, armed = 0, tlo = 0, thi = 0x10000, romfrom = 0;
	int page_n[8]; const char *page_f[8];
	const char *bin = NULL, *prefix = "shot"; int addr = 24200, frames = 500, hash = 0, watch = -1;
	for (int i = 1; i < argc; i++) {
		if (!strcmp(argv[i], "-a")) addr = atoi(argv[++i]);
		else if (!strcmp(argv[i], "-f")) frames = atoi(argv[++i]);
		else if (!strcmp(argv[i], "-k")) parse_keys(argv[++i]);
		else if (!strcmp(argv[i], "-s")) { char *p = argv[++i]; while (*p) { shots[nshots++] = atoi(p); while (*p && *p != ',') p++; if (*p) p++; } }
		else if (!strcmp(argv[i], "-o")) prefix = argv[++i];
		else if (!strcmp(argv[i], "-h")) hash = 1;
		else if (!strcmp(argv[i], "-d")) { char *c; dumps[ndumps][0] = (int)strtol(argv[++i], &c, 0); dumps[ndumps][1] = (*c == ',') ? (int)strtol(c + 1, NULL, 0) : 16; ndumps++; }
		else if (!strcmp(argv[i], "-128")) is128 = 1;
		else if (!strcmp(argv[i], "-sp")) initsp = (int)strtol(argv[++i], NULL, 0);
		else if (!strcmp(argv[i], "-incl")) { incaddr = (int)strtol(argv[++i], NULL, 0); incfrom = atoi(argv[++i]); }
		else if (!strcmp(argv[i], "-count")) { cntaddr = (int)strtol(argv[++i], NULL, 0); cntfrom = atoi(argv[++i]); }
		else if (!strcmp(argv[i], "-prof")) { proffrom = atoi(argv[++i]); proffile = argv[++i]; }
		else if (!strcmp(argv[i], "-t")) trap = (int)strtol(argv[++i], NULL, 0);
		else if (!strcmp(argv[i], "-rt")) { trap = -1; romfrom = atoi(argv[++i]); }
		else if (!strcmp(argv[i], "-tr")) { tlo = (int)strtol(argv[++i], NULL, 0); thi = (int)strtol(argv[++i], NULL, 0); }
		else if (!strcmp(argv[i], "-page")) { page_n[npages] = atoi(argv[++i]); page_f[npages++] = argv[++i]; }
		else if (!strcmp(argv[i], "-p")) watch = (int)strtol(argv[++i], NULL, 0);
		else bin = argv[i];
	}
	if (!bin) { fprintf(stderr, "uso: zxrun juego.bin [-a dir] [-f frames] [-k teclas] [-s frames] [-o prefijo] [-h]\n"); return 1; }

	FILE *f = fopen(bin, "rb"); if (!f) { perror(bin); return 1; }
	static uint8_t data[65536]; size_t n = fread(data, 1, sizeof data, f); fclose(f);

	zx_desc_t desc = { .type = is128 ? ZX_TYPE_128 : ZX_TYPE_48K, .joystick_type = ZX_JOYSTICKTYPE_NONE };
	desc.roms.zx48k = (chips_range_t){ (void *)zx48k_rom, sizeof zx48k_rom };
	desc.roms.zx128_0 = (chips_range_t){ (void *)zx128k_0_bin, 16384 };
	desc.roms.zx128_1 = (chips_range_t){ (void *)zx128k_1_bin, 16384 };
	zx_init(&sys, &desc);

	/* Arranque de la ROM (~2 s), como si viniéramos de LOAD "" CODE + RANDOMIZE USR */
	for (int i = 0; i < 100; i++) zx_exec(&sys, 20000);
	if (is128) {
		/* Como tras el cargador: ROM 48K (bit 4), RAM 0 en 0xC000 */
		_zx_update_memory_map_zx128(&sys, 0x10);
		for (int p = 0; p < npages; p++) {
			FILE *pf = fopen(page_f[p], "rb"); if (!pf) { perror(page_f[p]); return 1; }
			size_t r = fread(sys.ram[page_n[p] & 7], 1, 0x4000, pf); fclose(pf); (void)r;
		}
	}
	for (size_t i = 0; i < n; i++) mem_wr(&sys.mem, (uint16_t)(addr + i), data[i]);
	if (initsp >= 0) sys.cpu.sp = (uint16_t)initsp;
	sys.pins = z80_prefetch(&sys.cpu, (uint16_t)addr);

	int si = 0, hit = 0;
	for (int fr = 0; fr <= frames; fr++) {
		for (int e = 0; e < nevs; e++) if (evs[e].frame == fr) {
			if (evs[e].down) zx_key_down(&sys, evs[e].key); else zx_key_up(&sys, evs[e].key);
		}
		if (incaddr >= 0 && fr >= incfrom) {
			uint32_t t = 0, ticks = clk_us_to_ticks(sys.freq_hz, 20000);
			for (; t < ticks; t++) { sys.pins = _zx_tick(&sys, sys.pins);
				if (inside) {
					incticks ++;
					if (z80_opdone(&sys.cpu) && sys.cpu.sp > incsp) inside = 0;	/* ret: SP por encima de la entrada */
				} else if (z80_opdone(&sys.cpu) && sys.cpu.pc - 1 == incaddr) {
					inside = 1; incsp = sys.cpu.sp; inccalls ++;
				} }
			kbd_update(&sys.kbd, 20000);
		} else if (cntaddr >= 0 && fr >= cntfrom) {
			uint32_t t = 0, ticks = clk_us_to_ticks(sys.freq_hz, 20000);
			for (; t < ticks; t++) { sys.pins = _zx_tick(&sys, sys.pins);
				if (z80_opdone(&sys.cpu) && sys.cpu.pc - 1 == cntaddr) cnt ++; }
			cntticks += ticks;
			kbd_update(&sys.kbd, 20000);
		} else if (proffile && fr >= proffrom) {
			/* Perfil: cada tick se atribuye a la instrucción en curso */
			uint32_t t = 0, ticks = clk_us_to_ticks(sys.freq_hz, 20000);
			for (; t < ticks; t++) { sys.pins = _zx_tick(&sys, sys.pins);
				if (z80_opdone(&sys.cpu)) curpc = sys.cpu.pc - 1;
				prof[curpc] ++; }
			kbd_update(&sys.kbd, 20000);
		} else if (trap) {
			uint32_t t = 0, ticks = clk_us_to_ticks(sys.freq_hz, 20000);
			for (; t < ticks; t++) { sys.pins = _zx_tick(&sys, sys.pins);
				if (z80_opdone(&sys.cpu)) {
					uint16_t pc = sys.cpu.pc - 1;
					if (sys.cpu.sp == trap) armed = 1;
					if ((trap < 0 && fr >= romfrom && pc < 0x4000) || (trap > 0 && armed && sys.cpu.sp > trap && pc >= tlo && pc < thi)) {
						printf("Trampa: SP=%04X en PC %04X, frame %d. Últimos PC (sp):\n", sys.cpu.sp, pc, fr);
						for (int k = 0; k < 4096; k++) { int q = (rp + k) & 4095; printf("%04X(%04X) ", ring[q], ringsp[q]); if ((k & 7) == 7) printf("\n"); }
						return 3;
					}
					ring[rp] = pc; ringsp[rp] = sys.cpu.sp; rp = (rp + 1) & 4095;
				} }
			kbd_update(&sys.kbd, 20000);
		} else if (watch >= 0) {
			/* paso a paso dentro del frame para vigilar el PC */
			uint32_t t = 0, ticks = clk_us_to_ticks(sys.freq_hz, 20000);
			for (; t < ticks; t++) { sys.pins = _zx_tick(&sys, sys.pins);
				if (z80_opdone(&sys.cpu) && sys.cpu.pc - 1 == watch && !hit) { hit = 1; printf("PC=%04X en frame %d\n", watch, fr); } }
			kbd_update(&sys.kbd, 20000);
		} else zx_exec(&sys, 20000);
		for (int s = 0; s < nshots; s++) if (shots[s] == fr) {
			char fn[512]; snprintf(fn, sizeof fn, "%s_%05d.png", prefix, fr); save_png(fn);
			if (hash) printf("frame %d hash %08x pc %04x sp %04x 7ffd %02x\n", fr, screen_hash(), sys.cpu.pc, sys.cpu.sp, sys.last_mem_config);
			si++;
		}
	}
	(void)si;
	if (incaddr >= 0) printf("incl %llu llamadas, %llu ciclos/llamada\n", (unsigned long long)inccalls, inccalls ? (unsigned long long)(incticks / inccalls) : 0ULL);
	if (cntaddr >= 0) printf("count %llu, %llu ciclos/vez\n", (unsigned long long)cnt, cnt ? (unsigned long long)(cntticks / cnt) : 0ULL);
	if (proffile) { FILE *pf = fopen(proffile, "wb"); fwrite(prof, 4, 65536, pf); fclose(pf); }
	for (int d = 0; d < ndumps; d++) {
		for (int a = 0; a < dumps[d][1]; a++) {
			if ((a & 15) == 0) printf("%s%04X:", a ? "\n" : "", (dumps[d][0] + a) & 0xffff);
			printf(" %02X", rd((uint16_t)(dumps[d][0] + a)));
		}
		printf("\n");
	}
	return 0;
}
