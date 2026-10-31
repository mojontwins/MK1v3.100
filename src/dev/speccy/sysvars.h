// La Churrera Engine 3.100
// Copyleft 2010-2014 the Mojon Twins

// Variables dependientes del sistema (ZX Spectrum)

#include "spritepack.h"

#ifdef MODE_128K
	#define PLAY_SFX(n) 	wyz_play_sound(n)
#else
	#define PLAY_SFX(n)		peta_el_beeper(n)
#endif

// Colocación de variables en direcciones fijas (SDCC): AT (dirección) va
// delante de la declaración.
#define AT(a)				__at (a)

// Mapa de memoria baja (el juego empieza en 24200 y BASIC ya no se usa).
// Las interrupciones están deshabilitadas durante el juego en 48K, así que
// la ROM no escribe en las variables del sistema que pisamos.
#define BASE_ROOM_BUFFERS	23300		// map_attr + map_buff: 300 bytes
#define BASE_ARRAYS 		23600		// arrays de enemigos/balas: 69 + 6 * MAX_BULLETS
#define BASE_BRK_BUFF		23728		// muros rompibles: 150 bytes (hasta 23877)

#ifdef KEYS_CUSTOM
	// Teclas del juego (config.h): fire, right, left, down, up. Los códigos
	// son los de sp_LookupKey: (bit << 8) | semifila, p.ej. 0x01fb = Q.
	const struct sp_UDK keys = { KEYS_CUSTOM };
	#ifdef USE_TWO_BUTTONS
		#ifndef key_fire
			#define key_fire 0x047f
		#endif
		#ifndef key_jump
			#define key_jump 0x087f
		#endif
	#endif
#elif defined USE_TWO_BUTTONS
	// Define here if you selected the TWO BUTTONS configuration

	const struct sp_UDK keys = {
		0x047f, // .fire
		0x04fd, // .right
		0x01fd, // .left
		0x02fd, // .down
		0x02fb	// .up
	};
	
	#define key_jump 0x087f
	#define key_fire 0x047f
#else
	// Define here if you selected the NORMAL configuration

	const struct sp_UDK keys = {
		0x017f, // .fire
		0x01df, // .right
		0x02df, // .left
		0x01fd, // .down
		0x01fb	// .up
	};
#endif

// Teclas especiales: M (acción del script), H / Y (pausa / abortar),
// Z (cambiar objeto), 1 / 2 (menú de checkpoints), 1 / 2 / 3 (diálogos).
#define KEY_M 0x047f
#define KEY_H 0x10bf
#define KEY_Y 0x10df
#define KEY_Z 0x02fe
#define KEY_1 0x01f7
#define KEY_2 0x02f7
#define KEY_3 0x04f7

// Puntero a la función de manejo seleccionada (sp_JoyKeyboard, sp_JoyKempston
// o sp_JoySinclair1; las dos últimas no usan el argumento).

typedef uchar (*JOYFUNC) (struct sp_UDK *keys) __smallc;
JOYFUNC joyfunc;

// splib2 saca la memoria de los sprites directamente de la cola 0 del
// asignador de bloques (sp_AddMemory en system_init).

// Estructuras que representan los sprites

struct sp_SS *sp_player;
struct sp_SS *sp_moviles [3];
#ifdef PLAYER_CAN_FIRE
	struct sp_SS *sp_bullets [MAX_BULLETS];
#endif
#ifdef PLAYER_CAN_PUNCH
	struct sp_SS *sp_hitter;
#endif
#ifdef ENABLE_COCOS
	struct sp_SS *sp_cocos [MAX_COCOS];
#endif
// Zona de la pantalla en la que se ven los sprites: fila, columna, alto, ancho.
const struct sp_Rect spritesClip = { VIEWPORT_Y, VIEWPORT_X, 20, 30 };
#define SPRITES_CLIP	((struct sp_Rect *) &spritesClip)

		
