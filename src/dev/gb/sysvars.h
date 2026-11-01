// La Churrera Engine 3.100 - Game Boy
// Copyleft 2026 the Mojon Twins

// gb/sysvars.h
// Variables y macros que dependen del sistema (Game Boy). Es el equivalente
// de speccy/sysvars.h y cpc/sysvars.h.

// Efectos de sonido y música (todavía no hay: llegarán con el driver de
// sonido). Las llamadas al WYZ player del código de los juegos no hacen nada.
#define PLAY_SFX(n)
#define peta_el_beeper(n)
#define wyz_play_music(n)
#define wyz_play_sound(n)
#define wyz_stop_sound()
#define wyz_play_sample(n)

// En Game Boy las variables no van en direcciones fijas: la RAM (8K) la
// reparte el enlazador y gbcheck comprueba que cabe. (GBDK define AT como
// __at: aquí no se usa.)
#undef AT
#define AT(a)

// ---------------------------------------------------------------------------
// Mandos
// ---------------------------------------------------------------------------
//
// pad0, pad1 y pad_this_frame tienen un bit por botón, a 0 si está pulsado
// (como en el Spectrum). Los bits son los de joypad () de GBDK.
//
//   cruceta   moverse (ARRIBA salta si el juego no usa dos botones)
//   A         FIRE (disparo, puñetazo, acción)
//   B         saltar (ARRIBA, o key_jump con USE_TWO_BUTTONS)
//   ABAJO     acción de los scripts (con SCRIPTING_DOWN)
//   START     pausa (KEY_H)
//   SELECT    abortar la partida (KEY_Y)

#define sp_RIGHT		J_RIGHT
#define sp_LEFT			J_LEFT
#define sp_UP			J_UP
#define sp_DOWN			J_DOWN
#define sp_FIRE			J_A

// sp_KeyPressed (k) mira si está pulsado el botón k (máscara de joypad ())
#define key_fire		J_A
#define key_jump		J_B
#define KEY_M			J_DOWN
#define KEY_H			J_START
#define KEY_Y			J_SELECT
#define KEY_Z			J_SELECT
#define KEY_1			J_A
#define KEY_2			J_B
#define KEY_3			J_SELECT

// ---------------------------------------------------------------------------
// Sprites
// ---------------------------------------------------------------------------
//
// Los sprites son los del hardware, en modo 8x16. Los 128 patrones de los
// sprites (0x8000) son 32 "caras" de 16x16 de 4 patrones cada una (columna
// izquierda arriba y abajo, columna derecha arriba y abajo, como las
// convierte mkts_om platform=gb mode=sprites):
//
//   caras 0-15    los sprites 1-16 (jugador 1-8, enemigos 9-16)
//   cara 16       la explosión (sprite 17)
//   cara 17       vacía (sprite 18)
//   cara 18       la bala y los cocos (sprite 19, 8x8 arriba a la izquierda)
//   cara 19, 20   el puño (sprites 20 y 21, 8x8 arriba a la izquierda)
//   caras 21-31   libres para el juego
//
// Un "frame" de sprite (player.next_frame, en_an_next_frame...) es el
// número del primer patrón de su cara: sprite_N_a vale 4 * (N - 1).

#define GB_FRAME(n)		((const unsigned char *) (4 * ((n) - 1)))
#define sprite_1_a		GB_FRAME (1)
#define sprite_2_a		GB_FRAME (2)
#define sprite_3_a		GB_FRAME (3)
#define sprite_4_a		GB_FRAME (4)
#define sprite_5_a		GB_FRAME (5)
#define sprite_6_a		GB_FRAME (6)
#define sprite_7_a		GB_FRAME (7)
#define sprite_8_a		GB_FRAME (8)
#define sprite_9_a		GB_FRAME (9)
#define sprite_10_a		GB_FRAME (10)
#define sprite_11_a		GB_FRAME (11)
#define sprite_12_a		GB_FRAME (12)
#define sprite_13_a		GB_FRAME (13)
#define sprite_14_a		GB_FRAME (14)
#define sprite_15_a		GB_FRAME (15)
#define sprite_16_a		GB_FRAME (16)
#define sprite_17_a		GB_FRAME (17)
#define sprite_18_a		GB_FRAME (18)
#define sprite_19_a		GB_FRAME (19)
#define sprite_20_a		GB_FRAME (20)
#define sprite_21_a		GB_FRAME (21)

// Sprites del hardware (OAM) que usa cada cosa: los de 16x16 usan dos.
#define GB_OAM_PLAYER	0
#define GB_OAM_ENEMS	2
#define GB_OAM_BULLETS	8
#define GB_OAM_COCOS	(GB_OAM_BULLETS + MAX_BULLETS)
#ifdef ENABLE_COCOS
	#define GB_OAM_HITTER	(GB_OAM_COCOS + MAX_COCOS)
#else
	#define GB_OAM_HITTER	GB_OAM_COCOS
#endif
#define GB_OAM_USED		(GB_OAM_HITTER + 1)

// ---------------------------------------------------------------------------
// Pantalla
// ---------------------------------------------------------------------------
//
// La pantalla del juego (30x20 caracteres) está entera en el fondo (0x9800)
// y la cámara (SCX, SCY) enseña 160 x GB_VIEW_H píxeles, siguiendo al
// jugador. El marcador va en la ventana, abajo (GB_HUD_ROWS filas).
// Las funciones de printer.h escriben en el fondo si y < 20 y en la ventana
// (fila y - 20) si no; lo que está fuera de 32x32 (99 en config.h) no se pinta.

#ifndef GB_HUD_ROWS
	#define GB_HUD_ROWS		2
#endif
#define GB_VIEW_H		(144 - 8 * GB_HUD_ROWS)
#define GB_CAM_MAX_X	(240 - 160)
#define GB_CAM_MAX_Y	(160 - GB_VIEW_H)
