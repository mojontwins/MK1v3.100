// La Churrera Engine 3.100 - Game Boy
// Copyleft 2026 the Mojon Twins

// gb/home.c
// El banco 0, siempre visible: arranque, interrupciones, paletas y fundidos,
// los sprites (OAM), recursos y datos que están en otros bancos de ROM y
// pantallas fijas. El motor (gb/churromain.c) va en el banco 1, que está
// puesto siempre salvo mientras una función de aquí lee de otro banco.

#include "mk1gb.h"
#define LIBRARIAN_TABLE
#include "../librarian.h"

uint8_t gb_pal_bg, gb_pal_obj0, gb_pal_obj1;
uint8_t gb_faded;					// La pantalla está fundida (a negro o a blanco)

// La pantalla del juego: cámara, ventana y sprites. La cámara (gb_scx,
// gb_scy) se pone en el vblank, a la vez que el DMA copia los sprites.
uint8_t gb_game_on;
uint8_t gb_scx, gb_scy;
uint8_t gb_wy;

// Los sprites se escriben en gb_oam y gb_oam_commit lo deja para el
// siguiente vblank: hay dos buffers (el de GBDK en 0xC000 y otro en 0xDE00,
// debajo de la pila) y el DMA copia siempre el último que se ha cerrado.
uint8_t *gb_oam;

// Frames (vblanks): los cuenta el motor (isr_frames, en definitions.h)
extern volatile uint8_t isr_frames;

// ---------------------------------------------------------------------------
// Interrupciones
// ---------------------------------------------------------------------------

// vblank: la cámara y los sprites (que se apagan en la línea de la ventana)
static void gb_vbl (void) NONBANKED {
	if (gb_game_on) {
		SCX_REG = gb_scx;
		SCY_REG = gb_scy;
		LCDC_REG |= LCDCF_OBJON;
	}
	isr_frames ++;
}

// Línea gb_wy - 1 (LYC): en su hblank se apagan los sprites, para que no se
// pinten encima de la ventana.
static void gb_lcd (void) NONBANKED {
	while (STAT_REG & 3);
	LCDC_REG &= ~LCDCF_OBJON;
}

// ---------------------------------------------------------------------------
// Arranque y pantalla
// ---------------------------------------------------------------------------

// Pone la pantalla como la usa el motor (con el LCD apagado), las paletas y
// la fuente.
void gb_init (void) NONBANKED {
	DISPLAY_OFF;
	LCDC_REG = LCDCF_BGON | LCDCF_BG8800 | LCDCF_BG9800 | LCDCF_OBJ16 | LCDCF_WIN9C00;
	gb_pal_bg = GB_PAL_BG;
	gb_pal_obj0 = GB_PAL_OBJ0;
	gb_pal_obj1 = GB_PAL_OBJ1;
	BGP_REG = OBP0_REG = OBP1_REG = 0;		// Empieza en blanco
	gb_faded = 1;
	SCX_REG = SCY_REG = 0;
	gb_game_on = 0;
	gb_oam = GB_OAM_B;
	gb_oam_clear ();
	get_resource (RES_FONT, GB_VRAM_FONT);

	__critical {
		add_VBL (gb_vbl);
		add_LCD (gb_lcd);
	}
	set_interrupts (VBL_IFLAG);
}

// La pantalla del juego: la ventana (el marcador) desde la línea wy y los
// sprites, que se apagan donde empieza la ventana.
void gb_game_screen (uint8_t wy) NONBANKED {
	gb_set_wy (wy);
	WX_REG = 7;
	STAT_REG = STATF_LYC;
	LCDC_REG |= LCDCF_WINON | LCDCF_OBJON;
	gb_game_on = 1;
	set_interrupts (VBL_IFLAG | LCD_IFLAG);
}

// Mueve el borde de arriba de la ventana (más arriba para los textos)
void gb_set_wy (uint8_t wy) NONBANKED {
	gb_wy = wy;
	WY_REG = wy;
	LYC_REG = wy - 1;
}

// Pantallas fijas: sin ventana, sin sprites y sin cámara
void gb_fixed_screen (void) NONBANKED {
	set_interrupts (VBL_IFLAG);
	gb_game_on = 0;
	LCDC_REG &= ~(LCDCF_WINON | LCDCF_OBJON);
	SCX_REG = SCY_REG = 0;
}

// ---------------------------------------------------------------------------
// Sprites
// ---------------------------------------------------------------------------

// Todos los sprites fuera (en los dos buffers)
void gb_oam_clear (void) NONBANKED {
	uint8_t i;
	for (i = 0; i < 160; i ++) {
		((uint8_t *) shadow_OAM) [i] = 0;
		GB_OAM_B [i] = 0;
	}
}

// Lo escrito en gb_oam se verá en el siguiente vblank (con la cámara que se
// pasa). Se sigue escribiendo en el otro buffer, que empieza igual.
void gb_oam_commit (uint8_t scx, uint8_t scy) NONBANKED {
	uint8_t *next;
	uint8_t i;
	__critical {
		_shadow_OAM_base = (uint8_t) ((uint16_t) gb_oam >> 8);
		gb_scx = scx;
		gb_scy = scy;
	}
	next = (gb_oam == GB_OAM_B) ? (uint8_t *) shadow_OAM : GB_OAM_B;
	for (i = 0; i < 160; i ++) next [i] = gb_oam [i];
	gb_oam = next;
}

// ---------------------------------------------------------------------------
// Paletas y fundidos
// ---------------------------------------------------------------------------

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

// Fundido a negro (o a blanco) desde las paletas actuales. Si ya está
// fundida, no hace nada.
void gb_fade_out (uint8_t to_white) NONBANKED {
	uint8_t k;
	if (gb_faded) return;
	for (k = 1; k < 4; k ++) fade_step (k, to_white);
	gb_faded = 1;
}

// Fundido desde negro (o desde blanco) hasta las paletas actuales
void gb_fade_in (uint8_t from_white) NONBANKED {
	uint8_t k;
	for (k = 3; k; k --) fade_step (k, from_white);
	gb_set_palettes ();
	gb_faded = 0;
}

// ---------------------------------------------------------------------------
// Recursos y datos en otros bancos
// ---------------------------------------------------------------------------

// Descomprime el recurso res en dest (RAM o, con la pantalla apagada, VRAM).
// Pone el banco del recurso y luego deja el que estaba.
void get_resource (uint8_t res, uint16_t dest) NONBANKED {
	uint8_t old_bank = _current_bank;
	SWITCH_ROM (resources [res].ramPage);
	zx0_unpack ((const uint8_t *) resources [res].ramOffset, (uint8_t *) dest);
	SWITCH_ROM (old_bank);
}

// Dónde está (banco y dirección) el recurso res, para leerlo sin descomprimir
uint8_t gb_res_bank (uint8_t res) NONBANKED {
	return resources [res].ramPage;
}

const uint8_t *gb_res_addr (uint8_t res) NONBANKED {
	return (const uint8_t *) resources [res].ramOffset;
}

// El byte p del banco bank
uint8_t gb_peek (uint8_t bank, const uint8_t *p) NONBANKED {
	uint8_t old_bank = _current_bank;
	uint8_t v;
	SWITCH_ROM (bank);
	v = *p;
	SWITCH_ROM (old_bank);
	return v;
}

// Copia n bytes desde src (en el banco bank) a dst (en RAM)
void gb_copy_from_bank (uint8_t bank, const uint8_t *src, uint8_t *dst, uint16_t n) NONBANKED {
	uint8_t old_bank = _current_bank;
	SWITCH_ROM (bank);
	while (n --) *dst ++ = *src ++;
	SWITCH_ROM (old_bank);
}

// Una pantalla fija (mkts_om platform=gb mode=scr, comprimida): fundido a
// negro, se carga con la pantalla apagada y fundido desde negro.
void gb_show_screen (uint8_t res) NONBANKED {
	gb_fade_out (0);
	DISPLAY_OFF;
	gb_fixed_screen ();
	get_resource (res, GB_VRAM_PATTERNS);
	DISPLAY_ON;
	gb_fade_in (0);
}
