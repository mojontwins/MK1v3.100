// La Churrera Engine 3.100
// Copyleft 2010-2014, 2026 the Mojon Twins

// levels.h
// Sistema de niveles (COMPRESSED_LEVELS)

// Ver docs/formato-niveles.md.
//
// Cada nivel tiene:
//  * un "bundle" con los datos de juego, independiente de la plataforma, que
//    genera utils/buildlevel: cabecera, comportamientos, cerrojos, hotspots,
//    enemigos y mapa. Cada nivel puede tener un tamaño de mapa distinto;
//    MAP_W * MAP_H (config.h) es el máximo y fija el tamaño de los buffers.
//  * recursos gráficos aparte (tileset, spriteset), que pueden compartir
//    varios niveles.
//  * su script (con ACTIVATE_SCRIPTING): el .bin que genera msc4, comprimido
//    y como recurso. Todos los scripts se compilan juntos (in=a.spt,b.spt...)
//    para que el intérprete tenga todo lo que necesitan.
//
// La tabla de niveles la define cada juego en levelset.h:
//
//   LEVEL levels [MAX_LEVELS] = {
//       // bundle      tileset        spriteset      música  script
//       { RES_LEVEL1C, RES_TILESET1C, RES_SPRITES1C, 2,      RES_SCRIPT1C },
//       { RES_LEVEL2C, NO_RESOURCE,   NO_RESOURCE,   3,      RES_SCRIPT2C },
//   };
//
// Los RES_* los genera librarian a partir de los nombres de archivo. Sin
// script (o sin scripting), NO_RESOURCE.

#ifndef MODE_128K
	#error "COMPRESSED_LEVELS necesita MODE_128K"
#endif

#define MAX_PANT			(MAP_W * MAP_H)
#define MAX_CERROJOS		32
#define NO_RESOURCE 		0xff

typedef struct {
	unsigned char map_w, map_h;
	unsigned char scr_ini, ini_x, ini_y;
	unsigned char max_objs;
	unsigned char enems_life;
	unsigned char scr_fin, fin_x, fin_y;
	unsigned char n_cerrojos;
	unsigned char flags;					// bit 0: mapa unpacked
	unsigned char version;
	unsigned char reserved [3];
} LEVELHEADER;

typedef struct {
	unsigned char np, x, y, st;
} CERROJOS;

typedef struct {
	unsigned char x, y;
	unsigned char x1, y1, x2, y2;
	signed char mx, my;
	signed char t;
	unsigned char life;						// Los bundles siempre llevan vida
} MALOTE;

typedef struct {
	unsigned char xy, tipo, act;
} HOTSPOT;

typedef struct {
	unsigned char bundle;					// Recurso con el bundle del nivel
	unsigned char tileset;					// Recurso del tileset o NO_RESOURCE
	unsigned char spriteset;				// Recurso del spriteset o NO_RESOURCE
	unsigned char music;					// Canción del WYZ player
	unsigned char script;					// Recurso del script o NO_RESOURCE
} LEVEL;

// Buffer del nivel actual. get_resource descomprime el bundle entero aquí y
// cada sección queda en su etiqueta. El orden y los tamaños tienen que
// coincidir con buildlevel.

extern LEVELHEADER level_data [0];
extern unsigned char comportamiento_tiles [0];
extern CERROJOS cerrojos [0];
extern HOTSPOT hotspots [0];
extern MALOTE malotes [0];
extern unsigned char mapa [0];

#asm
	._level_data
		defs 16
	._comportamiento_tiles
		defs 48
	._cerrojos
		defs MAX_CERROJOS * 4
	._hotspots
		defs MAX_PANT * 3
	._malotes
		defs MAX_PANT * 3 * 10
	._mapa
	#ifdef UNPACKED_MAP
		defs MAX_PANT * 150
	#else
		defs MAX_PANT * 75
	#endif
	._level_data_end
#endasm

// Tabla de niveles del juego
#include "levelset.h"
