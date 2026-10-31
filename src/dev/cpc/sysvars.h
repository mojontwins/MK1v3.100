// La Churrera Engine 3.100
// Copyleft 2010-2014 the Mojon Twins

// Variables dependientes del sistema (Amstrad CPC)

#include "cpcrslib_mt.h"

#define PLAY_SFX(n) 		wyz_play_sound(n)

// msc.h y el motor llaman a peta_el_beeper para los efectos
#define peta_el_beeper(n)	wyz_play_sound(n)

// Colocación de variables en direcciones fijas
#define AT(a)				__at (a)

// Mapa de memoria. El programa empieza en 0x400 y sus variables van detrás
// del código, hasta WYZ_SONG_BUFFER (ihx2bin lo comprueba con MEM_LIMIT).
// Por encima, buffers en direcciones fijas: la canción descomprimida, el
// superbuffer (0x9000-0xBFFF) y, en la pantalla (32x24 tiles, en cada
// bloque de 2K solo se usan 0x600 bytes), los huecos de 0x200 bytes que
// quedan: buffers de la pantalla, tiles tocados, arrays, sprites, la LUT de
// transparencias y la pila (encima de la LUT).
#define BASE_TILEMAP 		0x0100
#define WYZ_SONG_BUFFER 	0x8800
#define BASE_SUPERBUFF  	0x9000

#define BASE_ROOM_BUFFERS	(0xC000 + 0x600)
#define BASE_DIRTY_CELLS 	(0xC800 + 0x600)
#define BASE_ARRAYS 		(0xD000 + 0x600)
#define BASE_BRK_BUFF		(0xD080 + 0x600)	// muros rompibles: 150 bytes
#define BASE_WYZ 			0xDF80
#define BASE_SPRITES 		(0xE000 + 0x600)
#define BASE_CUSTOM 		(0xF000 + 0x600)
#define BASE_LUT			(0xF800 + 0x600)

#define STACK_ADDR			0xFFFF
#define MEM_LIMIT			WYZ_SONG_BUFFER

// El nametable: un byte por tile de la pantalla (32x24)
#define nametable			((unsigned char *) BASE_TILEMAP)

#define BLACK_PEN 1
// Sincronía de frames: interrupciones por frame de juego (GAME_FRAME_TICKS).
#ifdef GAME_FRAME_TICKS
	#define MIN_FAPS_PER_FRAME GAME_FRAME_TICKS
#else
	#define MIN_FAPS_PER_FRAME 2
#endif

// cpcrslib recorta los sprites al área de juego: le pasamos dónde está.
void viewport_symbols (void) __naked {
	__asm
		viewport_x == VIEWPORT_X
		viewport_y == VIEWPORT_Y
	__endasm;
}

// Puertos: el gate array (paleta, borde, modo) y el CRTC
__sfr __banked __at (0x7F00) gate_array;
__sfr __banked __at (0xBC00) crtc_select;
__sfr __banked __at (0xBD00) crtc_data;

// WYZ player (cpc/wyz_player.s)
void wyz_init (void);
void wyz_play_music (unsigned char m);
void wyz_play_sound (unsigned char s);
void wyz_stop_sound (void);
unsigned char isr_player_on;
unsigned char wyz_beat_ct;

// Contadores de la ISR: isr_c1 cuenta interrupciones (6 por frame) e isr_c2
// frames, para la sincronía de sp_UpdateNow.
unsigned char isr_c1, isr_c2;

// Number of sprites and handy macros

#define MAX_ENEMS 3

// Sprites software: jugador, enemigos y balas.
#define SW_SPRITES_ALL 		(1 + MAX_ENEMS + MAX_BULLETS)

#define SP_PLAYER 			0
#define SP_ENEMS_BASE 		1
#define SP_BULLETS_BASE 	(SP_ENEMS_BASE + MAX_ENEMS)

#ifdef MODE_1
	// P_0 P_1 P_2 P_3
	// 1 0 1 0 1 0 1 0
	// 3 7 2 6 1 5 0 4
	#define BLACK_COLOUR_BYTE ((BLACK_PEN>>1)|((BLACK_PEN>>1)<<1)\
								|((BLACK_PEN>>1)<<2)|((BLACK_PEN>>1)<<3)\
								|((BLACK_PEN&1)<<4)|((BLACK_PEN&1)<<5)\
								|((BLACK_PEN&1)<<6)|((BLACK_PEN&1)<<7))
#else
	// PIXEL 0  PIXEL 1
	// 3 2 1 0  3 2 1 0
	// 1 5 3 7  0 4 2 6
	#define BLACK_COLOUR_BYTE (((BLACK_PEN>>3)&1)|(((BLACK_PEN>>3)&1)<<1)\
								|(((BLACK_PEN>>1)&1)<<2)|(((BLACK_PEN>>1)&1)<<3)\
								|(((BLACK_PEN>>2)&1)<<4)|(((BLACK_PEN>>2)&1)<<5)\
								|((BLACK_PEN&1)<<6)|((BLACK_PEN&1)<<7))
#endif

// LUT de pixels transparentes para los sprites (de CPCTelera), comprimida.
// system_init la descomprime en BASE_LUT.
extern const unsigned char trpixlutc [];
void trpixlut_data (void) __naked {
	__asm
		_trpixlutc:
		.incbin "trpixlutc.bin"
	__endasm;
}

#define BORDER(b) 				cpc_Border((b))

// Teclas. Cada una es ((0x40 | línea de la matriz) << 8) | bit; los números
// en https://lronaldo.github.io/cpctelera/files/keyboard/keyboard-txt.html
// keys tiene las que se usan (pad_read lee las 8 primeras); select_joyfunc
// copia ahí def_keys o def_keys_joy.

#define N_KEYS 12
unsigned int keys [N_KEYS];

const unsigned int def_keys [N_KEYS] = {
	0x4404, 	// LEFT     O
	0x4308, 	// RIGHT    P
	0x4808, 	// UP       Q
	0x4820, 	// DOWN     A
	0x4580, 	// BUTTON_A SPACE
	0x4808, 	// BUTTON_B Q
	0x4801, 	// KEY_AUX3 1
	0x4802, 	// KEY_AUX4 2
	0x4880,		// KEY_AUX1 Z
	0x4780, 	// KEY_AUX2 X
	0x4204,		// KEY_ENTER
	0x4804		// KEY_ESC
};

// Joystick (se lee como teclas)
const unsigned int def_keys_joy [N_KEYS] = {
	0x4904, 0x4908, 0x4901, 0x4902, 0x4910, 0x4920,
	0x4801, 0x4802, 0x4880, 0x4780, 0x4204, 0x4804
};

// Con dos botones, teclas fijas: saltar = Q, disparar = ESPACIO.
#ifdef USE_TWO_BUTTONS
	#define key_jump 0x4808
	#define key_fire 0x4580
#endif

#define KEY_M 0x4440
#define KEY_H 0x4510
#define KEY_Y 0x4508
#define KEY_Z 0x4880
#define KEY_S 0x4710

#define KEY_1 0x4801
#define KEY_2 0x4802
#define KEY_3 0x4701

#define KEY_LEFT 		0
#define KEY_RIGHT		1
#define KEY_UP  		2
#define KEY_DOWN 		3
#define KEY_BUTTON_A	4
#define KEY_BUTTON_B	5
#define KEY_AUX3 		6
#define KEY_AUX4 		7
#define KEY_AUX1		8
#define KEY_AUX2		9
#define KEY_ENTER		10
#define KEY_ESC			11

#define sp_LEFT           0x01
#define sp_RIGHT          0x02
#define sp_UP             0x04
#define sp_DOWN           0x08
#define sp_FIRE           0x10
#define sp_FIRE2          0x20
#define sp_AUX3           0x40
#define sp_AUX4           0x80

// Sprites software: la estructura que usa cpcrslib (16 bytes)

typedef struct sprite {
	unsigned int sp0;			// 0	frame actual
	unsigned int sp1; 			// 2	frame anterior
	unsigned int coord0;		// 4
	signed char cox, coy;		// 6 7
	unsigned char cx, cy; 		// 8 9	posición: byte (0-63) y línea (0-191)
	unsigned char ox, oy;		// 10 11
	void *invfunc;				// 12
	void *updfunc;				// 14
} SPR;

AT (BASE_SPRITES) SPR sp_sw [SW_SPRITES_ALL];
