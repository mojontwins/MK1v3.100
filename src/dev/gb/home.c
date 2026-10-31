// La Churrera Engine 3.100 - Game Boy
// Copyleft 2026 the Mojon Twins

// gb/home.c
// El banco 0, siempre visible: arranque, paletas y fundidos, recursos (que
// están en otros bancos) y pantallas fijas.

#include "../config.h"
#include "mk1gb.h"
#define LIBRARIAN_TABLE
#include "../librarian.h"

uint8_t gb_pal_bg, gb_pal_obj0, gb_pal_obj1;

// Pone la pantalla como la usa el motor (con el LCD apagado), las paletas y
// la fuente.
void gb_init (void) NONBANKED {
	DISPLAY_OFF;
	LCDC_REG = LCDCF_BGON | LCDCF_BG8800 | LCDCF_BG9800 | LCDCF_OBJ16 | LCDCF_OBJON | LCDCF_WIN9C00;
	gb_pal_bg = GB_PAL_BG;
	gb_pal_obj0 = GB_PAL_OBJ0;
	gb_pal_obj1 = GB_PAL_OBJ1;
	BGP_REG = OBP0_REG = OBP1_REG = 0;		// Empieza en blanco
	SCX_REG = SCY_REG = 0;
	get_resource (RES_FONT, GB_VRAM_FONT);
}

void gb_set_palettes (void) NONBANKED {
	BGP_REG = gb_pal_bg;
	OBP0_REG = gb_pal_obj0;
	OBP1_REG = gb_pal_obj1;
}

void gb_wait_frames (uint8_t n) NONBANKED {
	while (n --) wait_vbl_done ();
}

// La paleta p con cada tono k pasos más oscuro (o más claro, hacia el blanco)
static uint8_t pal_step (uint8_t p, uint8_t k, uint8_t to_white) {
	uint8_t r, i, c;
	r = 0;
	for (i = 0; i < 8; i += 2) {
		c = (p >> i) & 3;
		if (to_white) c = c > k ? c - k : 0;
		else c = c + k < 3 ? c + k : 3;
		r |= c << i;
	}
	return r;
}

static void fade_step (uint8_t k, uint8_t to_white) {
	BGP_REG = pal_step (gb_pal_bg, k, to_white);
	OBP0_REG = pal_step (gb_pal_obj0, k, to_white);
	OBP1_REG = pal_step (gb_pal_obj1, k, to_white);
	gb_wait_frames (GB_FADE_FRAMES);
}

// Fundido a negro (o a blanco) desde las paletas actuales
void gb_fade_out (uint8_t to_white) NONBANKED {
	uint8_t k;
	for (k = 1; k < 4; k ++) fade_step (k, to_white);
}

// Fundido desde negro (o desde blanco) hasta las paletas actuales
void gb_fade_in (uint8_t from_white) NONBANKED {
	uint8_t k;
	for (k = 3; k; k --) fade_step (k, from_white);
	gb_set_palettes ();
}

// Descomprime el recurso res en dest (RAM o, con la pantalla apagada, VRAM).
// Pone el banco del recurso y luego deja el que estaba.
void get_resource (uint8_t res, uint16_t dest) NONBANKED {
	uint8_t old_bank = _current_bank;
	SWITCH_ROM (resources [res].ramPage);
	zx0_unpack ((const uint8_t *) resources [res].ramOffset, (uint8_t *) dest);
	SWITCH_ROM (old_bank);
}

// Una pantalla fija (mkts_om platform=gb mode=scr, comprimida): fundido a
// negro, se carga con la pantalla apagada y fundido desde negro.
void gb_show_screen (uint8_t res) NONBANKED {
	gb_fade_out (0);
	DISPLAY_OFF;
	get_resource (res, GB_VRAM_PATTERNS);
	SCX_REG = SCY_REG = 0;
	DISPLAY_ON;
	gb_fade_in (0);
}
