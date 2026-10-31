// La Churrera Engine 3.100 - Game Boy
// Copyleft 2026 the Mojon Twins

// gb/mk1gb.h
// Lo que comparten los ficheros del Game Boy: el banco 0 (gb/home.c, siempre
// visible), el motor (banco 1) y el código del juego (su banco).
//
// La VRAM:
//   0x8000-0x87FF  sprites (128 patrones, 8x16: 32 sprites de 16x16)
//   0x8800-0x8BFF  la fuente: tiles 128-191 del fondo (modo 0x8800)
//   0x8C00-0x97FF  192 patrones: el tileset del nivel o una pantalla fija
//                  (tiles 192-255 y 0-127)
//   0x9800         el fondo (32x32: cabe la pantalla de 30x20 entera)
//   0x9C00         la ventana (el marcador, mensajes, textos)

#include <gb/gb.h>
#include <stdint.h>

#define GB_VRAM_SPRITES		0x8000
#define GB_VRAM_FONT		0x8800
#define GB_VRAM_PATTERNS	0x8C00
#define GB_BKG_MAP			0x9800
#define GB_WIN_MAP			0x9C00

// El carácter c (ASCII 32...95) de la fuente es el tile 128 + c - 32; el
// patrón k del tileset o de la pantalla fija, el tile (192 + k) & 255.
#define GB_CHAR(c)			((uint8_t) (96 + (c)))
#define GB_PATTERN(k)		((uint8_t) (192 + (k)))

// Paletas (DMG): cada par de bits es el tono (0 blanco ... 3 negro) del
// color 0, 1, 2 y 3. Se pueden cambiar en config.h.
#ifndef GB_PAL_BG
	#define GB_PAL_BG		0xE4		// 3 2 1 0: tal cual
#endif
#ifndef GB_PAL_OBJ0
	#define GB_PAL_OBJ0		0xE4		// el color 0 es transparente
#endif
#ifndef GB_PAL_OBJ1
	#define GB_PAL_OBJ1		0xE4
#endif
#ifndef GB_FADE_FRAMES
	#define GB_FADE_FRAMES	4			// Frames por paso de los fundidos
#endif

extern uint8_t gb_pal_bg, gb_pal_obj0, gb_pal_obj1;

void zx0_unpack (const uint8_t *src, uint8_t *dst);

// Banco 0 (gb/home.c)
void gb_init (void) NONBANKED;
void gb_set_palettes (void) NONBANKED;
void gb_fade_out (uint8_t to_white) NONBANKED;
void gb_fade_in (uint8_t from_white) NONBANKED;
void gb_wait_frames (uint8_t n) NONBANKED;
void get_resource (uint8_t res, uint16_t dest) NONBANKED;
void gb_show_screen (uint8_t res) NONBANKED;
