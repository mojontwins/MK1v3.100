/* gbrun - Game Boy sin pantalla para las pruebas de MK1 (como zxrun).
 *
 * Carga la ROM, la ejecuta N frames con una secuencia de botones programada
 * y puede sacar capturas PNG y volcar memoria.
 *
 * Uso:
 *   gbrun juego.gb [opciones]
 *     -f N          frames a ejecutar (300)
 *     -k GUION      botones: "frame:boton+,frame:boton-,..." con boton
 *                   a, b, sel, sta, u, d, l, r. Ejemplo: "60:sta+,62:sta-"
 *     -s F1,F2,...  frames en los que sacar captura (PREFIJO_FFFFF.png)
 *     -o PREFIJO    prefijo de las capturas (shot)
 *     -h            imprime un hash de la pantalla en cada captura
 *     -d DIR,LEN    al terminar, vuelca LEN bytes desde DIR (repetible)
 *
 * Compilar: gcc -O2 -w -o tests/gbrun/gbrun tests/gbrun/gbrun.c
 *
 * El emulador es Peanut-GB (peanut_gb.h, licencia MIT, de Mahyar Koshkouei).
 */
#define ENABLE_SOUND 0
#define ENABLE_LCD 1
#include "peanut_gb.h"
#include <stdio.h>
#include <string.h>
#include <stdint.h>

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "../../src/utils/src/fbpng-linux/stb_image_write.h"

static uint8_t *rom, *cram;
static size_t romsize;
static uint8_t fb [144][160];

static uint8_t rom_read (struct gb_s *gb, const uint_fast32_t a) { return a < romsize ? rom [a] : 0xff; }
static uint8_t cram_read (struct gb_s *gb, const uint_fast32_t a) { return cram [a]; }
static void cram_write (struct gb_s *gb, const uint_fast32_t a, const uint8_t v) { cram [a] = v; }
static void gb_err (struct gb_s *gb, const enum gb_error_e e, const uint16_t a) {
	fprintf (stderr, "Error del emulador %d en %04X\n", e, a); exit (2);
}
static void draw_line (struct gb_s *gb, const uint8_t px [160], const uint_fast8_t line) {
	for (int x = 0; x < 160; x ++) fb [line][x] = px [x] & 3;
}

static const char *names [] = { "a", "b", "sel", "sta", "r", "l", "u", "d" };
typedef struct { int frame, bit, down; } EV;
static EV evs [4096]; static int nevs;

static void parse_keys (char *s) {
	char *t = strtok (s, ",");
	while (t) {
		int f = atoi (t); char *c = strchr (t, ':');
		if (c) {
			c ++; int l = strlen (c); int down = c [l - 1] == '+';
			for (int i = 0; i < 8; i ++) if ((int) strlen (names [i]) == l - 1 && !strncmp (c, names [i], l - 1)) {
				evs [nevs].frame = f; evs [nevs].bit = i; evs [nevs].down = down; nevs ++;
			}
		}
		t = strtok (NULL, ",");
	}
}

static uint32_t hash (void) {
	uint32_t h = 2166136261u;
	for (int y = 0; y < 144; y ++) for (int x = 0; x < 160; x ++) h = (h ^ fb [y][x]) * 16777619u;
	return h;
}

int main (int argc, char **argv) {
	char *romf = NULL, *prefix = "shot"; int frames = 300, shots [512], nshots = 0, dohash = 0;
	int dumps [64][2], ndumps = 0;
	for (int i = 1; i < argc; i ++) {
		if (!strcmp (argv [i], "-f")) frames = atoi (argv [++ i]);
		else if (!strcmp (argv [i], "-k")) parse_keys (argv [++ i]);
		else if (!strcmp (argv [i], "-o")) prefix = argv [++ i];
		else if (!strcmp (argv [i], "-h")) dohash = 1;
		else if (!strcmp (argv [i], "-s")) { char *p = argv [++ i]; while (*p) { shots [nshots ++] = atoi (p); while (*p && *p != ',') p ++; if (*p) p ++; } }
		else if (!strcmp (argv [i], "-d")) { char *c; dumps [ndumps][0] = (int) strtol (argv [++ i], &c, 0); dumps [ndumps][1] = (*c == ',') ? (int) strtol (c + 1, NULL, 0) : 16; ndumps ++; }
		else romf = argv [i];
	}
	if (!romf) { fprintf (stderr, "uso: gbrun juego.gb [-f frames] [-k teclas] [-s frames] [-o prefijo] [-h] [-d dir,len]\n"); return 1; }
	FILE *f = fopen (romf, "rb"); if (!f) { perror (romf); return 1; }
	fseek (f, 0, SEEK_END); romsize = ftell (f); rewind (f);
	rom = malloc (romsize); if (fread (rom, 1, romsize, f) != romsize) return 1; fclose (f);

	static struct gb_s gb; size_t ss;
	if (gb_init (&gb, rom_read, cram_read, cram_write, gb_err, NULL) != GB_INIT_NO_ERROR) { fprintf (stderr, "ROM no válida\n"); return 1; }
	gb_get_save_size_s (&gb, &ss); cram = calloc (ss ? ss : 1, 1);
	gb_init_lcd (&gb, draw_line);

	uint8_t pad = 0xff;		// 0 = pulsado
	int si = 0;
	for (int fr = 0; fr <= frames; fr ++) {
		for (int e = 0; e < nevs; e ++) if (evs [e].frame == fr) {
			if (evs [e].down) pad &= ~(1 << evs [e].bit); else pad |= (1 << evs [e].bit);
		}
		gb.direct.joypad = pad;
		gb_run_frame (&gb);
		for (int s = 0; s < nshots; s ++) if (shots [s] == fr) {
			static uint8_t rgb [144 * 160 * 3]; const uint8_t sh [4] = { 0xe0, 0xa8, 0x58, 0x18 };
			for (int i = 0; i < 144 * 160; i ++) rgb [i * 3] = rgb [i * 3 + 1] = rgb [i * 3 + 2] = sh [fb [i / 160][i % 160]];
			char fn [512]; snprintf (fn, sizeof fn, "%s_%05d.png", prefix, fr);
			stbi_write_png (fn, 160, 144, 3, rgb, 160 * 3);
			if (dohash) printf ("frame %d hash %08x pc %04x\n", fr, hash (), gb.cpu_reg.pc.reg);
		}
	}
	for (int d = 0; d < ndumps; d ++) {
		for (int i = 0; i < dumps [d][1]; i ++) {
			if ((i & 15) == 0) printf ("%s%04X:", i ? "\n" : "", dumps [d][0] + i);
			printf (" %02X", __gb_read (&gb, (uint16_t) (dumps [d][0] + i)));
		}
		printf ("\n");
	}
	return 0;
}
