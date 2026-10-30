/* cpcrun - Amstrad CPC 464 sin pantalla para pruebas de regresión de MK1.
 *
 * Igual que zxrun: arranca el firmware, coloca el binario en su dirección
 * (0x400 por defecto), salta a él y lo ejecuta N frames con teclas
 * programadas, sacando capturas PNG (384x272, la mitad de ancho) y hashes.
 *
 * Uso: cpcrun juego.bin [-a DIR] [-f N] [-k GUION] [-s F1,F2] [-o PREFIJO] [-h] [-d DIR,LEN]
 * Las teclas usan los mismos nombres que zxrun ("spc", "ent", letras, dígitos).
 *
 * Compilar: gcc -O2 -w -o tests/cpcrun/cpcrun tests/cpcrun/cpcrun.c
 * Basado en los emuladores de floooh/chips (licencia zlib).
 */
#define CHIPS_IMPL
#include "../zxrun/chips/chips_common.h"
#include "../zxrun/chips/z80.h"
#include "../zxrun/chips/ay38910.h"
#include "../zxrun/chips/i8255.h"
#include "../zxrun/chips/mc6845.h"
#include "../zxrun/chips/am40010.h"
#include "../zxrun/chips/upd765.h"
#include "../zxrun/chips/mem.h"
#include "../zxrun/chips/kbd.h"
#include "../zxrun/chips/clk.h"
#include "../zxrun/chips/fdd.h"
#include "../zxrun/chips/fdd_cpc.h"
#include "../zxrun/chips/cpc.h"
#include "cpc464_rom.h"
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "../../src/utils/src/fbpng-linux/stb_image_write.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static cpc_t sys;

typedef struct { int frame; int key; int down; } KEYEV;
static KEYEV evs[4096]; static int nevs;
static int shots[1024]; static int nshots;

#define W (AM40010_DISPLAY_WIDTH / 2)
#define H (AM40010_DISPLAY_HEIGHT)

static uint32_t screen_hash(void) {
	uint32_t h = 2166136261u;
	for (int y = 0; y < H; y++) for (int x = 0; x < AM40010_DISPLAY_WIDTH; x++) {
		h ^= sys.fb[x + y * AM40010_FRAMEBUFFER_WIDTH]; h *= 16777619u;
	}
	return h;
}

static void save_png(const char *fn) {
	static uint8_t img[H][W][3];
	const uint32_t *pal = sys.ga.hw_colors;
	for (int y = 0; y < H; y++) for (int x = 0; x < W; x++) {
		uint32_t c = pal[sys.fb[x * 2 + y * AM40010_FRAMEBUFFER_WIDTH] & 31];
		img[y][x][0] = c; img[y][x][1] = c >> 8; img[y][x][2] = c >> 16;	/* ABGR */
	}
	stbi_write_png(fn, W, H, 3, img, W * 3);
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
	int dumps[64][2], ndumps = 0;
	const char *bin = NULL, *prefix = "shot"; int addr = 0x400, frames = 500, hash = 0;
	for (int i = 1; i < argc; i++) {
		if (!strcmp(argv[i], "-a")) addr = (int)strtol(argv[++i], NULL, 0);
		else if (!strcmp(argv[i], "-f")) frames = atoi(argv[++i]);
		else if (!strcmp(argv[i], "-k")) parse_keys(argv[++i]);
		else if (!strcmp(argv[i], "-s")) { char *p = argv[++i]; while (*p) { shots[nshots++] = atoi(p); while (*p && *p != ',') p++; if (*p) p++; } }
		else if (!strcmp(argv[i], "-o")) prefix = argv[++i];
		else if (!strcmp(argv[i], "-h")) hash = 1;
		else if (!strcmp(argv[i], "-d")) { char *c; dumps[ndumps][0] = (int)strtol(argv[++i], &c, 0); dumps[ndumps][1] = (*c == ',') ? (int)strtol(c + 1, NULL, 0) : 16; ndumps++; }
		else bin = argv[i];
	}
	if (!bin) { fprintf(stderr, "uso: cpcrun juego.bin [-a dir] [-f frames] [-k teclas] [-s frames] [-o prefijo] [-h] [-d dir,len]\n"); return 1; }

	FILE *f = fopen(bin, "rb"); if (!f) { perror(bin); return 1; }
	static uint8_t data[1 << 17]; size_t n = fread(data, 1, sizeof data, f); fclose(f);

	cpc_desc_t desc = { .type = CPC_TYPE_464, .joystick_type = CPC_JOYSTICK_NONE };
	desc.roms.cpc464.os = (chips_range_t){ (void *)cpc464_os_bin, 16384 };
	desc.roms.cpc464.basic = (chips_range_t){ (void *)cpc464_basic_bin, 16384 };
	cpc_init(&sys, &desc);

	/* Arranque del firmware (~3 s) y salto al juego, como un RUN"" */
	for (int i = 0; i < 150; i++) cpc_exec(&sys, 20000);
	/* Se carga como un .bin de AMSDOS (cabecera de 128 bytes) para que el
	   emulador pagine bien la ROM baja antes de saltar al juego. */
	size_t bl = strlen(bin);
	if (bl > 4 && !strcmp(bin + bl - 4, ".sna")) {
		/* Instantánea: se carga tal cual */
		if (!cpc_quickload(&sys, (chips_range_t){ data, n }, true)) { fprintf(stderr, "quickload falló\n"); return 1; }
	} else {
	static uint8_t img[128 + 65536]; memset(img, 0, 128);
	img[18] = 2;										/* binario */
	img[21] = addr & 255; img[22] = addr >> 8;			/* dirección de carga */
	img[24] = n & 255; img[25] = n >> 8;				/* longitud */
	img[26] = addr & 255; img[27] = addr >> 8;			/* dirección de ejecución */
	img[64] = n & 255; img[65] = n >> 8;
	{ unsigned cs = 0; for (int i = 0; i < 67; i++) cs += img[i]; img[67] = cs & 255; img[68] = cs >> 8; }
	memcpy(img + 128, data, n);
	if (!cpc_quickload(&sys, (chips_range_t){ img, 128 + n }, true)) { fprintf(stderr, "quickload falló\n"); return 1; }
	}

	for (int fr = 0; fr <= frames; fr++) {
		for (int e = 0; e < nevs; e++) if (evs[e].frame == fr) {
			if (evs[e].down) cpc_key_down(&sys, evs[e].key); else cpc_key_up(&sys, evs[e].key);
		}
		cpc_exec(&sys, 20000);
		for (int s = 0; s < nshots; s++) if (shots[s] == fr) {
			char fn[512]; snprintf(fn, sizeof fn, "%s_%05d.png", prefix, fr); save_png(fn);
			if (hash) printf("frame %d hash %08x\n", fr, screen_hash());
		}
	}
	for (int d = 0; d < ndumps; d++) {
		for (int a = 0; a < dumps[d][1]; a++) {
			if ((a & 15) == 0) printf("%s%04X:", a ? "\n" : "", (dumps[d][0] + a) & 0xffff);
			printf(" %02X", mem_rd(&sys.mem, (uint16_t)(dumps[d][0] + a)));
		}
		printf("\n");
	}
	return 0;
}
