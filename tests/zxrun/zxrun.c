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
	const char *bin = NULL, *prefix = "shot"; int addr = 24200, frames = 500, hash = 0, watch = -1;
	for (int i = 1; i < argc; i++) {
		if (!strcmp(argv[i], "-a")) addr = atoi(argv[++i]);
		else if (!strcmp(argv[i], "-f")) frames = atoi(argv[++i]);
		else if (!strcmp(argv[i], "-k")) parse_keys(argv[++i]);
		else if (!strcmp(argv[i], "-s")) { char *p = argv[++i]; while (*p) { shots[nshots++] = atoi(p); while (*p && *p != ',') p++; if (*p) p++; } }
		else if (!strcmp(argv[i], "-o")) prefix = argv[++i];
		else if (!strcmp(argv[i], "-h")) hash = 1;
		else if (!strcmp(argv[i], "-p")) watch = (int)strtol(argv[++i], NULL, 0);
		else bin = argv[i];
	}
	if (!bin) { fprintf(stderr, "uso: zxrun juego.bin [-a dir] [-f frames] [-k teclas] [-s frames] [-o prefijo] [-h]\n"); return 1; }

	FILE *f = fopen(bin, "rb"); if (!f) { perror(bin); return 1; }
	static uint8_t data[65536]; size_t n = fread(data, 1, sizeof data, f); fclose(f);

	zx_desc_t desc = { .type = ZX_TYPE_48K, .joystick_type = ZX_JOYSTICKTYPE_NONE };
	desc.roms.zx48k = (chips_range_t){ (void *)zx48k_rom, sizeof zx48k_rom };
	zx_init(&sys, &desc);

	/* Arranque de la ROM (~2 s), como si viniéramos de LOAD "" CODE + RANDOMIZE USR */
	for (int i = 0; i < 100; i++) zx_exec(&sys, 20000);
	for (size_t i = 0; i < n; i++) mem_wr(&sys.mem, (uint16_t)(addr + i), data[i]);
	sys.pins = z80_prefetch(&sys.cpu, (uint16_t)addr);

	int si = 0, hit = 0;
	for (int fr = 0; fr <= frames; fr++) {
		for (int e = 0; e < nevs; e++) if (evs[e].frame == fr) {
			if (evs[e].down) zx_key_down(&sys, evs[e].key); else zx_key_up(&sys, evs[e].key);
		}
		if (watch >= 0) {
			/* paso a paso dentro del frame para vigilar el PC */
			uint32_t t = 0, ticks = clk_us_to_ticks(sys.freq_hz, 20000);
			for (; t < ticks; t++) { sys.pins = _zx_tick(&sys, sys.pins);
				if (z80_opdone(&sys.cpu) && sys.cpu.pc - 1 == watch && !hit) { hit = 1; printf("PC=%04X en frame %d\n", watch, fr); } }
			kbd_update(&sys.kbd, 20000);
		} else zx_exec(&sys, 20000);
		for (int s = 0; s < nshots; s++) if (shots[s] == fr) {
			char fn[512]; snprintf(fn, sizeof fn, "%s_%05d.png", prefix, fr); save_png(fn);
			if (hash) printf("frame %d hash %08x\n", fr, screen_hash());
			si++;
		}
	}
	(void)si;
	return 0;
}
