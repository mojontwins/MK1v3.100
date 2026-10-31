// La Churrera Engine 3.100
// Copyleft 2010-2014 the Mojon Twins

// churromain.c
// Esqueleto de juegos de la churrera
// Copyleft 2010-2014 The Mojon Twins

// Funciones de la librería de SDCC que usa el motor
void *memcpy (void *dest, const void *src, unsigned int n);
void *memset (void *s, int c, unsigned int n) __sdcccall(0) __z88dk_callee;

// Funciones del motor que se usan antes de definirlas
unsigned char rand (void);

// Según la configuración, algunas funciones no usan todos sus argumentos o
// variables locales: el aviso 85 de SDCC no dice nada útil aquí.
#pragma disable_warning 85

#include "config.h"

#ifdef CPC
	#undef MODE_128K
#endif

// Lo que necesitan los scripts (generado por msc4)
#ifdef ACTIVATE_SCRIPTING
	#include "msc-config.h"
#endif

// Constantes y banderas derivadas de config.h
#include "config_derived.h"

// NUMBLOCKS es el número de bloques necesario para mover los sprites
// Configurar bien este número es MUY IMPORTANTE

// Bloques de memoria que necesita splib2 para mover los sprites: 10 por cada
// sprite de 16x16 (jugador y 3 enemigos) y 5 por cada bala, coco o puño.
#ifdef PLAYER_CAN_PUNCH
	#define HITTER_BLOCKS	5
#else
	#define HITTER_BLOCKS	0
#endif
#define NUMBLOCKS (40 + 5 * MAX_BULLETS + 5 * MAX_COCOS + HITTER_BLOCKS)

// La regla es esta: cada sprite de 16x16 ocupa 10 bloques.
// Cada proyectil ocupa 5 bloques.

// Si, por ejemplo, tu juego no tiene disparos, sólo necesitas bloques
// para el sprite principal y tres enemigos, o sea, 4*10 = 40 bloques.

// Si, por ejemplo, tu juego además lleva 3 proyectiles, necesitarás
// 4*10 + 3*5 = 55 bloques.

// Mapa de memoria de la pila y los bloques de sprites, según el modo (el de
// CPC está en cpc/sysvars.h).
#ifdef CPC
#elif defined MODE_128K
	// En 128K la pila NO puede estar entre 0xC000 y 0xFFFF: al paginar otra RAM
	// para descomprimir un recurso se perderían las direcciones de retorno.
	// Va justo debajo del programa (24200) y crece hacia abajo, hacia la zona
	// libre que deja BASE_BRK_BUFF (hasta 23877).
	// Por la misma razón todo lo que se use con otra página puesta (pila,
	// descompresor, ISR y los destinos de get_resource: level_data, tileset y
	// sprites) tiene que quedar por debajo de 0xC000. comp-zx.sh lo comprueba.
	#define STACK_ADDR		24200
	// Los bloques de sprites (sp_AddMemory) terminan en 0xF000, justo antes
	// de la tabla de vectores IM2 (0xF000-0xF100) y de la ISR (0xF1F1).
	#define AD_FREE 		(0xF000 - (NUMBLOCKS * 15))
#else
	// En 48K: tabla de vectores IM2 en 0xF000-0xF100 e ISR en 0xF1F1 (splib2
	// usa 0xF200-0xFFFF para sus tablas de rotación). La pila va en el hueco
	// libre entre ambas (de 0xF1F0 hacia abajo, 64 bytes) y los bloques de
	// sprites terminan en 0xF000.
	#define STACK_SIZE 		64
	#define STACK_ADDR		0xF1F0
	#define AD_FREE 		(0xF000 - (NUMBLOCKS * 15))
#endif
// El programa y sus variables tienen que acabar antes de los bloques de los
// sprites (en CPC, antes de los buffers: ver cpc/sysvars.h).
#ifndef CPC
	#define MEM_LIMIT		AD_FREE
#endif


// Cosas del juego:

#ifdef CPC
	#include "cpc/sysvars.h"
#else
	#include "speccy/sysvars.h"
#endif

#include "definitions.h"

// Símbolos del mapa de memoria para crt0 (la pila, en __stack_top) e ihx2bin
// (comprueba que el programa acaba antes de __mem_limit). En CPC, además, las
// direcciones de los buffers del WYZ player (cpc/wyz_player.s).
void memory_map_symbols (void) __naked {
	__asm
		__stack_top == STACK_ADDR
		__mem_limit == MEM_LIMIT
	#ifdef CPC
		__wyz_song_buffer == WYZ_SONG_BUFFER
		__base_wyz == BASE_WYZ
	#endif
	__endasm;
}

#ifndef CPC
	#ifdef MODE_128K
		#include "speccy_128/128k.h"
		#include "speccy_128/wyzplayer.h"
	#else
		#include "speccy/isr.h"
		#include "speccy/beeper.h"
		// La música del título (Beepola, Phaser1 de Shiru) está en speccy/music.s,
		// que genera beepola2s y se enlaza aparte.
		void play_title_music (void);
	#endif
#else
	// El WYZ player, sus efectos y los instrumentos del juego son módulos
	// aparte (cpc/wyz_player.s, cpc/efectos.s, instrumentos.s).
	#include "cpc/songs.h"
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

// Datos de juego: con COMPRESSED_LEVELS (mapa, enemigos, hotspots, cerrojos y
// comportamientos) vienen en el bundle de cada nivel; si no, de mapa.h y enems.h.
#ifdef COMPRESSED_LEVELS
	#include "levels.h"
#else
	#include "enems.h"
	#include "mapa.h"
#endif

// Hasta aquí, lo que se usa con otra página de RAM en 0xC000 (descompresor,
// paginación, ISR, tileset y sprites, que cargan los niveles). En 128K
// comp-zx comprueba que low_end queda por debajo de 0xC000.
void low_end (void) __naked {
	__asm
	__endasm;
}

// Scripts (bytecode) y textos, generado por msc4
#ifdef ACTIVATE_SCRIPTING
	#include "msc-scripts.h"
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

#ifdef ENABLE_TILANIMS
	#include "tilanim.h"
#endif

// Checkpoints. Va antes de engine.h porque kill_player usa sg_saved y sg_pool.
#ifdef ENABLE_CHECKPOINTS
	#include "savegame.h"
#endif

#include "engine.h"

// Código propio del juego y ganchos (hooks) del bucle principal.
#include "custom.h"

// Intérprete de scripts
#ifdef ACTIVATE_SCRIPTING
	// Código del juego para EXTERN, TEXT BOX y DIALOG
	#if defined MSC_AU_E4 || defined MSC_AU_E6 || defined MSC_RV_E6
		#include "extern.h"
	#endif
	#include "msc.h"
#endif

#include "mainloop.h"

