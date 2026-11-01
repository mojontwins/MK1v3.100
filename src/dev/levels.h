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
//   const LEVEL levels [MAX_LEVELS] = {
//       // bundle      tileset        spriteset      música  script
//       { RES_LEVEL1C, RES_TILESET1C, RES_SPRITES1C, 2,      RES_SCRIPT1C },
//       { RES_LEVEL2C, NO_RESOURCE,   NO_RESOURCE,   3,      RES_SCRIPT2C },
//   };
//
// Los RES_* los genera librarian a partir de los nombres de archivo. Sin
// script (o sin scripting), NO_RESOURCE.

#if !defined MODE_128K && !defined GB
	#error "COMPRESSED_LEVELS necesita MODE_128K (o Game Boy)"
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
	unsigned char engine;					// Motor del jugador (ENGINE_JUMP, ENGINE_SWIM)
	unsigned char facing;					// Hacia dónde mira al empezar: 0 derecha, 1 izquierda
	unsigned char reserved;
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

// Buffer del nivel actual: la imagen exacta del bundle. get_resource lo
// descomprime entero aquí y cada sección queda en su campo. El orden y los
// tamaños tienen que coincidir con buildlevel (ver docs/formato-niveles.md).
// Es RAM normal (crt0 la pone a cero), así que el bundle no ocupa nada en
// el binario. Al empezar o repetir un nivel se vuelve a descomprimir, y con
// eso enemigos, hotspots y cerrojos vuelven a su estado inicial.

#ifdef UNPACKED_MAP
	#define MAP_BYTES		(MAX_PANT * 150)
#else
	#define MAP_BYTES		(MAX_PANT * 75)
#endif

typedef struct {
	LEVELHEADER header;
	unsigned char behs [48];
	CERROJOS cerrojos [MAX_CERROJOS];
	HOTSPOT hotspots [MAX_PANT];
	MALOTE malotes [MAX_PANT * 3];
	unsigned char mapa [MAP_BYTES];
} LEVELBUNDLE;

LEVELBUNDLE level_data;

// El motor usa los mismos nombres con niveles y sin ellos
#define comportamiento_tiles	(level_data.behs)
#define cerrojos				(level_data.cerrojos)
#define hotspots				(level_data.hotspots)
#define malotes					(level_data.malotes)
#define mapa					(level_data.mapa)

// Tabla de niveles del juego
#include "levelset.h"
