// La Churrera Engine 3.100
// Copyleft 2010-2014 the Mojon Twins

// churromain.c
// Esqueleto de juegos de la churrera
// Copyleft 2010-2014 The Mojon Twins

#include "config.h"

#ifdef CPC
	#undef MODE_128K
#endif

// Constantes y banderas derivadas de config.h
#include "config_derived.h"

// NUMBLOCKS es el número de bloques necesario para mover los sprites
// Configurar bien este número es MUY IMPORTANTE

// [v3.100] Se calcula solo: antes valía 40 fijo y al activar los disparos
// splib2 se quedaba sin bloques. MAX_BULLETS vale 0 si no hay disparos.
#define NUMBLOCKS (40 + 5 * MAX_BULLETS)

// La regla es esta: cada sprite de 16x16 ocupa 10 bloques.
// Cada proyectil ocupa 5 bloques.

// Si, por ejemplo, tu juego no tiene disparos, sólo necesitas bloques
// para el sprite principal y tres enemigos, o sea, 4*10 = 40 bloques.

// Si, por ejemplo, tu juego además lleva 3 proyectiles, necesitarás
// 4*10 + 3*5 = 55 bloques.

// [v3.100] Mapa de memoria según el modo (antes había que comentar/descomentar).
#ifdef MODE_128K
	// En 128K la pila NO puede estar entre 0xC000 y 0xFFFF: al paginar otra RAM
	// para descomprimir un recurso se perderían las direcciones de retorno.
	// Va justo debajo del programa (24200) y crece hacia abajo, hacia la zona
	// libre que deja BASE_BRK_BUFF (hasta 23877).
	// Por la misma razón todo lo que se use con otra página puesta (pila,
	// descompresor, ISR y los destinos de get_resource: level_data, tileset y
	// sprites) tiene que quedar por debajo de 0xC000. comp-zx.sh lo comprueba.
	#define STACK_ADDR		24200
	// [FIX v3.100] Los bloques de sprites (sp_AddMemory) acababan en 61952
	// (0xF200), pisando la tabla de vectores IM2 (0xF000-0xF100) y la ISR
	// genérica que se copia en 0xF1F1. Al mover el primer sprite se corrompía
	// la ISR y el juego saltaba a la ROM. En 48K no pasa porque las
	// interrupciones están deshabilitadas. Ahora terminan en 0xF000.
	#define AD_FREE 		(0xF000 - (NUMBLOCKS * 15))
#else
	// [v3.100] En 48K ahora también hay interrupciones IM2 (sincronía de
	// frames): la tabla de vectores va en 0xF000-0xF100 y la ISR en 0xF1F1
	// (splib2 usa 0xF200-0xFFFF para sus tablas de rotación). La pila va en el
	// hueco libre entre ambas (0xF1F0 hacia abajo, 64 bytes) y los bloques de
	// sprites terminan en 0xF000. Antes la pila estaba en 0xF200 y los bloques
	// debajo, pisando esa zona.
	#define STACK_SIZE 		64
	#define STACK_ADDR		0xF1F0
	#define AD_FREE 		(0xF000 - (NUMBLOCKS * 15))
#endif

// Cosas del juego:

#ifdef CPC
	#include "cpc/sysvars.h"
#else
	#include "speccy/sysvars.h"
#endif

#include "definitions.h"

#ifdef ACTIVATE_SCRIPTING
	#include "msc-config.h"
#endif

#ifndef CPC
	#ifdef MODE_128K
		#include "speccy_128/128k.h"
		#include "speccy_128/wyzplayer.h"
	#else
		#include "speccy/isr.h"
		#include "speccy/beeper.h"
	#endif
#else
	#include "cpc/efectos.h"
	#include "cpc/instrumentos.h"
	#include "cpc/songs.h"
	#include "cpc/wyz_player.h"
#endif

#include "zx0.h"

#ifdef MODE_128K
	#include "librarian.h"
#endif

// ***********
// GAME ASSETS
// ***********

// Los gráficos van primero: en 128K tienen que quedar por debajo de 0xC000
// porque los niveles pueden cargar tileset y spriteset encima.
#ifdef CPC
	#include "cpc/tileset.h"
	#include "cpc/sprites.h"
	#include "cpc/extrasprites.h"
	#include "cpc/spriteset_mappings.h"
	#include "cpc/pal.h"
#else
	#include "speccy/tileset.h"
	#include "speccy/sprites.h"
	#include "speccy/extrasprites.h"
#endif

// [v3.100] Con COMPRESSED_LEVELS los datos de juego (mapa, enemigos, hotspots,
// cerrojos, comportamientos) vienen en los bundles de cada nivel. Antes aquí
// había dos sistemas (48K y 128K) que no llegaban a compilar.
#ifdef COMPRESSED_LEVELS
	#include "levels.h"
#else
	#include "enems.h"
	#include "mapa.h"
#endif

// **********
// HW BACKEND
// **********

#ifdef CPC
	#include "cpc/printer.h"
	#include "cpc/cell_arrays.h"
#else
	#include "speccy/printer.h"
	#include "speccy/cell_arrays.h"
#endif

// ***********
// ENGINE
// ***********

#include "pantallas.h"

#ifdef ACTIVATE_SCRIPTING
	#ifdef ENABLE_EXTERN_CODE
		#include "extern.h"
	#endif
	#include "msc.h"
#endif

#ifdef ENABLE_TILANIMS
	#include "tilanim.h"
#endif

// [FIX v3.100] savegame.h iba después de engine.h, pero kill_player (en
// engine.h) usa sg_saved y sg_pool.
#ifdef ENABLE_CHECKPOINTS
	#include "savegame.h"
#endif

#include "engine.h"

// [v3.100] Código propio del juego y ganchos (hooks) del bucle principal.
#include "custom.h"

#include "mainloop.h"

#ifdef HAS_BEEPER
	// From beepola. Phaser engine by Shiru.
	#include "speccy/music.h"
#endif
