// La Churrera Engine 3.100
// Copyleft 2010-2014 the Mojon Twins

// Variables del motor

#define EST_NORMAL 		0
#define EST_PARP 		2
#define EST_MUR 		4

// ---------------------------------------------------------------------------
// [v3.100] Constantes derivadas de config.h
// ---------------------------------------------------------------------------

// enoffs, enoffsmasi y los bucles de enemigos usan unsigned char: como mucho
// 85 pantallas (85 * 3 = 255 enemigos).
#if MAP_W * MAP_H > 85
	#error "MAP_W * MAP_H no puede pasar de 85 pantallas"
#endif

// Los bundles de nivel (COMPRESSED_LEVELS) siempre llevan la vida de los enemigos.
#ifdef COMPRESSED_LEVELS
	#define FORCE_ENEMS_LIFE
#endif

// ¿Tiene la estructura MALOTE el campo life? Tiene que coincidir con la
// condición que escribe ene2h en enems.h.
#if ((defined PLAYER_CAN_FIRE || defined ENABLE_SWORD) && ENEMS_LIFE_GAUGE > 1) || defined FORCE_ENEMS_LIFE
	#define MALOTE_HAS_LIFE
#endif

// Datos que dependen del nivel. Con niveles comprimidos se leen de la
// cabecera del bundle, que sigue en level_data mientras dura el nivel (ver
// levels.h); si no, de config.h.
// El motor usa siempre estas macros: LEVEL_MAP_W en lugar de MAP_W, etc.
// MAP_W y MAP_H pasan a ser el tamaño máximo (el de los buffers).
#ifdef COMPRESSED_LEVELS
	#define LEVEL_MAP_W			(level_data [0].map_w)
	#define LEVEL_MAP_H			(level_data [0].map_h)
	#define LEVEL_SCR_INI		(level_data [0].scr_ini)
	#define LEVEL_INI_X			(level_data [0].ini_x)
	#define LEVEL_INI_Y			(level_data [0].ini_y)
	#define LEVEL_MAX_OBJS		(level_data [0].max_objs)
	#define LEVEL_ENEMS_LIFE	(level_data [0].enems_life)
	#define LEVEL_SCR_FIN		(level_data [0].scr_fin)
	#define LEVEL_FIN_X			(level_data [0].fin_x)
	#define LEVEL_FIN_Y			(level_data [0].fin_y)
#else
	#define LEVEL_SCR_INI		SCR_INICIO
	#define LEVEL_INI_X			PLAYER_INI_X
	#define LEVEL_INI_Y			PLAYER_INI_Y
	#define LEVEL_SCR_FIN		SCR_FIN
	#define LEVEL_MAP_W			MAP_W
	#define LEVEL_MAP_H			MAP_H
	#define LEVEL_MAX_OBJS		PLAYER_NUM_OBJETOS
	#ifdef ENEMS_LIFE_GAUGE
		#define LEVEL_ENEMS_LIFE	ENEMS_LIFE_GAUGE
	#else
		#define LEVEL_ENEMS_LIFE	1
	#endif
	#define LEVEL_FIN_X			PLAYER_FIN_X
	#define LEVEL_FIN_Y			PLAYER_FIN_Y
#endif

// Número de flags que guardan los checkpoints (ninguno sin scripting).
#ifdef ACTIVATE_SCRIPTING
	#define SG_NFLAGS MAX_FLAGS
#else
	#define SG_NFLAGS 0
#endif

// [v3.100] Sincronía de frames: la ISR cuenta interrupciones en isr_frames y
// el bucle principal espera a que pasen GAME_FRAME_TICKS antes de seguir.
#ifndef GAME_FRAME_TICKS
	#define GAME_FRAME_TICKS 2
#endif
unsigned char isr_frames;

#define sgni(n)			(n < 0 ? -1 : 1)
#define saturate(n)		(n < 0 ? 0 : n)

#define WTOP 1
#define WBOTTOM 2
#define WLEFT 3
#define WRIGHT 4

#define GENITAL_FACING_RIGHT 0
#define GENITAL_FACING_LEFT 2
#define GENITAL_FACING_UP 4
#define GENITAL_FACING_DOWN 6

#define LATERAL_FACING_LEFT 4
#define LATERAL_FACING_RIGHT 0

#define TYPE_6_IDLE 		0
#define TYPE_6_PURSUING		1
#define TYPE_6_RETREATING	2
#define GENERAL_DYING 		4

// Teclado
unsigned char pad0, pad1, pad_this_frame;

// [FIX v3.100] key_jump y key_fire se declaraban aquí y se volvían a definir
// (inicializadas) en {speccy,cpc}/sysvars.h -> "Already defined". Ahora solo
// existen en sysvars.h.

// Player

typedef struct {
	int x, y, cx;
	int vx, vy;
	char g, ax, rx;
	unsigned char crouch, cont_salto;
	unsigned char *current_frame, *next_frame;
	unsigned char saltando;
	unsigned char frame, subframe, facing;
	unsigned char estado;
	unsigned char ct_estado;
	unsigned char gotten;
	unsigned char life, objs, keys;
	unsigned char fuel;
	unsigned char killed;
	unsigned char disparando;
	unsigned char facing_v, facing_h;
#ifdef MAX_AMMO
	unsigned char ammo;
#endif	
} INERCIA;

INERCIA player;
signed int ptgmx, ptgmy; 			// Arrastre de las plataformas móviles
unsigned char gpx, gpy; 			// Coordenadas de pixel

// Bicharracos

unsigned char enoffs; 				// Índice de los enemigos de la pantalla
unsigned char enoffsmasi;
unsigned char *map_pointer;

unsigned char en_an_frame [3]						AT (BASE_ARRAYS);
unsigned char en_an_count [3] 						AT (BASE_ARRAYS + 3);
unsigned char *en_an_current_frame [3] 				AT (BASE_ARRAYS + 6);
unsigned char *en_an_next_frame [3] 				AT (BASE_ARRAYS + 12);
	
#ifdef PLAYER_CAN_FIRE
	unsigned char en_an_morido  [3] 				AT (BASE_ARRAYS + 18);
#endif

// [FIX v3.100] Aquí se usaba RANDOM_RESPAWN pero config.h define
// ENABLE_RANDOM_RESPAWN. Ahora todo el motor usa ENABLE_RANDOM_RESPAWN.
#if defined(ENABLE_RANDOM_RESPAWN) || defined (ENABLE_CUSTOM_TYPE_6)
	#define ENEMS_HAVE_FREE_COORDS		// Hay enemigos con coordenadas propias (x64)
	signed int en_an_x [3] 							AT (BASE_ARRAYS + 21);
	signed int en_an_y [3] 							AT (BASE_ARRAYS + 27);
	signed int en_an_vx [3] 						AT (BASE_ARRAYS + 33);
	signed int en_an_vy [3] 						AT (BASE_ARRAYS + 39);
	#ifdef ENABLE_RANDOM_RESPAWN
		unsigned char en_an_fanty_activo [3] 		AT (BASE_ARRAYS + 45);
	#endif
#endif
		
unsigned char en_an_state [3] 						AT (BASE_ARRAYS + 48);

#ifdef ENABLE_PURSUERS
	unsigned char en_an_alive [3] 					AT (BASE_ARRAYS + 51);
	unsigned char en_an_dead_row [3] 				AT (BASE_ARRAYS + 54);
	unsigned char en_an_rawv [3] 					AT (BASE_ARRAYS + 57);
#endif

unsigned char en_an_base_frame [3]	 				AT (BASE_ARRAYS + 60);

// Variables temporales para los enemigos
unsigned char _en_x, _en_y, _en_x1, _en_x2, _en_y1, _en_y2, _en_t, _en_life;
signed char _en_mx, _en_my;

#if defined(SLOW_DRAIN) && defined(PLAYER_BOUNCES)
	unsigned char lasttimehit;
#endif

// Disparos
// [FIX v3.100] bullets_my y bullets_life terminaban en ";;": un ";" suelto
// fuera de una función es un error en sccz80. Rompía PLAYER_CAN_FIRE.

#ifdef PLAYER_CAN_FIRE
	unsigned char bullets_x [MAX_BULLETS] 			AT (BASE_ARRAYS + 63);
	unsigned char bullets_y [MAX_BULLETS] 			AT (BASE_ARRAYS + 63 + MAX_BULLETS);
	signed char bullets_mx [MAX_BULLETS] 			AT (BASE_ARRAYS + 63 + 2 * MAX_BULLETS);
	unsigned char bullets_estado [MAX_BULLETS] 		AT (BASE_ARRAYS + 63 + 3 * MAX_BULLETS);
	signed char bullets_my [MAX_BULLETS] 			AT (BASE_ARRAYS + 63 + 4 * MAX_BULLETS);
	#ifdef LIMITED_BULLETS
		unsigned char bullets_life [MAX_BULLETS] 	AT (BASE_ARRAYS + 63 + 5 * MAX_BULLETS);
	#endif

	unsigned char blx, bly;
#endif

unsigned char *address AT (BASE_ARRAYS + 63 + 6 * MAX_BULLETS);
unsigned char *destination AT (BASE_ARRAYS + 65 + 6 * MAX_BULLETS);
unsigned char ram_page AT (BASE_ARRAYS + 67 + 6 * MAX_BULLETS);

// Mapa / pantallas

// atributos de la pantalla: Contiene información
// sobre qué tipo de tile hay en cada casilla
unsigned char map_attr [150] AT (BASE_ROOM_BUFFERS);
unsigned char map_buff [150] AT (BASE_ROOM_BUFFERS + 150);

// posición del objeto (hotspot). Para no objeto,
// se colocan a 240,240, que está siempre fuera de pantalla.
unsigned char hotspot_x;
unsigned char hotspot_y;
unsigned char orig_tile;	// Tile que había originalmente bajo el objeto

unsigned char pant_final;

unsigned char o_pant;
unsigned char n_pant;

#ifdef PLAYER_CHECK_MAP_BOUNDARIES
	unsigned char x_pant, y_pant;
#endif

unsigned char level = 0;
unsigned char maincounter;

unsigned char objs_old, keys_old, life_old, killed_old;

// Breakable walls/etc
// [FIX v3.100] brk_buff estaba en BASE_ROOM_BUFFERS + 300, que en ZX es
// exactamente BASE_ARRAYS: al romper muros se machacaban los arrays de
// animación de los enemigos. Ahora cada plataforma define BASE_BRK_BUFF.
#ifdef BREAKABLE_WALLS
	unsigned char brk_buff [150] AT (BASE_BRK_BUFF);
#endif

// Scripting

#ifdef ACTIVATE_SCRIPTING
	#define MAX_FLAGS 32
	unsigned char flags[MAX_FLAGS];
#endif

#ifdef ENABLE_FIRE_ZONE
	unsigned char fzx1, fzy1, fzx2, fzy2, f_zone_ac;
#endif

#if defined(ACTIVATE_SCRIPTING) && defined(ENABLE_PUSHED_SCRIPTING)
	unsigned char just_pushed;
#endif

#ifdef MSC_MAXITEMS
	unsigned char key_z_pressed = 0;
#endif

// Timer

#ifdef TIMER_ENABLE
typedef struct {
	unsigned char on;
	unsigned char t;
	unsigned char frames;
	unsigned char count;
	unsigned char zero;
} CTIMER;
CTIMER ctimer;
#endif

// Control

int seed;
unsigned char half_life;
unsigned char playing;
unsigned char mlplaying;
unsigned char success;

// Aux vars

signed int rds;

unsigned char rda, rdc, rdd, rdt, rdx, rdy;
unsigned char possee, hit_v, hit_h, hit;
unsigned char gpen_cx, gpen_cy, gpen_xx, gpen_yy, gpaux;
unsigned char tocado, active;
unsigned char gpit, gpjt;

// Collision

unsigned char cx1, cx2, cy1, cy2, at1, at2;

#ifdef MAX_AMMO
	unsigned char ammo_old;
#endif

#if defined(TIMER_ENABLE) && defined(PLAYER_SHOW_TIMER)
	unsigned char timer_old;
#endif

#ifdef COMPRESSED_LEVELS
	unsigned char *level_str = " LEVEL 00 ";
#endif

#ifdef GET_X_MORE
	unsigned char *getxmore = " GET X MORE ";
#endif

unsigned char *spacer = "            ";

unsigned char *allpurposepuntero;

#ifdef FIRE_TO_PUSH	
	unsigned char pushed_any;
#endif
