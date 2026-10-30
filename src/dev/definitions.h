// La Churrera Engine 3.100
// Copyleft 2010-2014 the Mojon Twins

// Variables del motor

#define EST_NORMAL 		0
#define EST_PARP 		2
#define EST_MUR 		4

// Sincronía de frames: la ISR cuenta interrupciones en isr_frames y el bucle
// principal espera a que pasen GAME_FRAME_TICKS antes de seguir.
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

// key_jump y key_fire (USE_TWO_BUTTONS) están en {speccy,cpc}/sysvars.h.

// Player

// Posiciones en punto fijo 8.8 (sin signo): el byte alto es el píxel y el
// bajo la fracción. Las velocidades (con signo) son 1/256 de píxel por frame.
// FIXED_PIX da el píxel; SET_FIXED_PIX pone un píxel exacto. Los dos acceden
// al byte alto directamente: en sccz80 un desplazamiento es una llamada a una
// rutina con un bucle. Z80 y SM83 guardan primero el byte bajo.
#define FIXED_PIX(v)			((unsigned char) ((v) >> 8))
#define SET_FIXED_PIX(v, p)		{ ((unsigned char *) (&(v))) [1] = (p); ((unsigned char *) (&(v))) [0] = 0; }

// Límites de la zona de juego en 8.8 (224 y 144 píxeles). En hexadecimal para
// que sccz80 los trate como unsigned int y no como long.
#define FIXED_MAX_X				0xE000
#define FIXED_MAX_Y				0x9000

// Tras sumar una velocidad: si la posición ha bajado de 0 ha dado la vuelta
// (un valor enorme) y se deja en 0; si pasa del máximo, en el máximo.
#define FIXED_CLAMP(v, max)		if ((v) >= 0xF000) (v) = 0; else if ((v) > (max)) (v) = (max)

typedef struct {
	unsigned int x, y;
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

// Posición (8.8) y velocidad propias de fanties y enemigos de tipo 6.
#ifdef ENEMS_HAVE_FREE_COORDS
	unsigned int en_an_x [3] 						AT (BASE_ARRAYS + 21);
	unsigned int en_an_y [3] 						AT (BASE_ARRAYS + 27);
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

#ifdef SLOW_DRAIN_ON
	unsigned char lasttimehit;
#endif

// Disparos

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
// Golpes recibidos por cada tile de la pantalla (BASE_BRK_BUFF lo fija cada
// plataforma en su sysvars.h).
#ifdef BREAKABLE_WALLS
	unsigned char brk_buff [150] AT (BASE_BRK_BUFF);
#endif

// Scripting (msc4, ver msc.h)

#ifdef ACTIVATE_SCRIPTING
	// Flags del script: los que usa (MSC_FLAGS, de msc-config.h), salvo que
	// config.h pida más con MAX_FLAGS.
	#ifndef MAX_FLAGS
		#if MSC_FLAGS > 0
			#define MAX_FLAGS MSC_FLAGS
		#else
			#define MAX_FLAGS 1
		#endif
	#endif
	unsigned char flags [MAX_FLAGS];

	// Secciones del script (entradas del índice)
	#define MSC_ENTERING_GAME			0
	#define MSC_ENTERING_ANY			1
	#define MSC_FIRE_ANY				2
	#define MSC_PLAYER_GOT_SOMETHING	3
	#define MSC_PLAYER_KILLS_ENEMY		4
	#define MSC_SPECIAL_TILE			5
	#define MSC_TIMER_ZERO				6
	#define MSC_TILE_PUSHED				7
	#define MSC_ENEMY_TOUCHED			8
	#define MSC_TILE_DESTROYED			9
	#define MSC_IDX_ROOMS				15	// Nº de pantallas del índice

	// Con niveles, el script del nivel se descomprime aquí (prepare_level).
	// Como mínimo 32 bytes: un índice vacío.
	#ifdef MSC_SCRIPTS_AS_RESOURCES
		#if MSC_SCRIPT_MAX_SIZE > 32
			unsigned char msc_buffer [MSC_SCRIPT_MAX_SIZE];
		#else
			unsigned char msc_buffer [32];
		#endif
	#endif

	unsigned char script_result;		// 1: WIN GAME, 2: GAME OVER
	unsigned char msc_param;			// PARAM
	unsigned char msc_tx, msc_ty;		// TX, TY: casilla que lanza el script
	unsigned char rdn;					// Pantalla que se está pintando (mainloop)

	#ifdef MSC_RV_F5
		unsigned char hotspot_t;		// HOTSPOT: tipo del último objeto
	#endif
	#ifdef MSC_RV_F0
		unsigned char hide_hotspots;	// HIDE_HOTSPOTS (vuelve a 0 en cada pantalla)
	#endif
	#ifdef MSC_RV_EF
		unsigned char dont_make_fanties;	// DONT_MAKE_FANTIES (ídem)
	#endif
	#ifdef PUSHED_SCRIPTING
		unsigned char msc_moved_tile, msc_moved_x, msc_moved_y;
		unsigned char just_pushed;
	#endif

	// Textos descodificados para text_box () y dialog_box () (extern.h)
	#ifdef MSC_AU_E6
		unsigned char msc_text_buf [MSC_TEXT_MAX_LEN + 1];		// TEXT BOX
	#endif
	#ifdef MSC_RV_E6
		// DIALOG: una cadena por opción (msc_options [0..2])
		unsigned char msc_option1 [MSC_TEXT_MAX_LEN + 1];
		unsigned char msc_option2 [MSC_TEXT_MAX_LEN + 1];
		unsigned char msc_option3 [MSC_TEXT_MAX_LEN + 1];
		unsigned char *msc_options [] = { msc_option1, msc_option2, msc_option3 };
		unsigned char msc_n_options;
	#endif

	// Están en msc.h, que se incluye después del motor.
	void msc_run (unsigned char sect);
	void msc_run_at (unsigned char sect, unsigned char x, unsigned char y);
	void msc_run_screen (unsigned char sect);
#endif

#ifdef FIRE_ZONE
	unsigned char fzx1, fzy1, fzx2, fzy2, f_zone_ac;
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

#ifdef SHOW_TIMER
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
