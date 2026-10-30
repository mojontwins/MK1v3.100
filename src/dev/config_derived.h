// La Churrera Engine 3.100
// Copyleft 2010-2014, 2026 the Mojon Twins

// config_derived.h
// Constantes y "banderas" derivadas de config.h.
//
// En lugar de repetir por todo el motor condiciones como
//     #if defined PLAYER_KILLS_ENEMIES || defined PLAYER_CAN_FIRE
// se calculan aquí una vez, con un nombre que dice qué necesita el motor
// (ENEMIES_CAN_DIE) y no qué combinación de opciones lo provoca.
// Se incluye justo después de config.h. No hay que tocarlo: se configura todo
// en config.h.

// ---------------------------------------------------------------------------
// Comprobaciones
// ---------------------------------------------------------------------------

// enoffs, enoffsmasi y los bucles de enemigos usan unsigned char: como mucho
// 85 pantallas (85 * 3 = 255 enemigos).
#if MAP_W * MAP_H > 85
	#error "MAP_W * MAP_H no puede pasar de 85 pantallas"
#endif

#if defined USE_AUTO_SHADOWS && defined USE_AUTO_TILE_SHADOWS
	#error "USE_AUTO_SHADOWS y USE_AUTO_TILE_SHADOWS son incompatibles"
#endif

// ---------------------------------------------------------------------------
// Plataforma
// ---------------------------------------------------------------------------

// Música y efectos con el WYZ player (chip AY) o con el beeper.
#if defined MODE_128K || defined CPC
	#define HAS_AY_MUSIC
#else
	#define HAS_BEEPER
#endif

// Interrupciones (1/50 s) por frame de juego: 2 = 25 fps, 0 = sin sincronía.
#ifndef GAME_FRAME_TICKS
	#define GAME_FRAME_TICKS 2
#endif

// ---------------------------------------------------------------------------
// Jugador
// ---------------------------------------------------------------------------

// Tecla de salto: con disparo, ARRIBA (o una tecla aparte con dos botones);
// sin disparo, FIRE.
#ifdef PLAYER_CAN_FIRE
	#ifdef USE_TWO_BUTTONS
		#define JUMP_ON_KEY
	#else
		#define JUMP_ON_UP
	#endif
#else
	#define JUMP_ON_FIRE
#endif

// El jugador recupera la vida al empezar cada nivel.
#if !defined COMPRESSED_LEVELS || defined REFILL_ME
	#define REFILL_LIFE_ON_LEVEL
#endif

// El jugador rebota y el daño es 4 veces más lento.
#if defined SLOW_DRAIN && defined PLAYER_BOUNCES
	#define SLOW_DRAIN_ON
#endif

// Al chocar con algo se comprueba si es un cerrojo o una caja.
#if !defined DEACTIVATE_KEYS || defined PLAYER_PUSH_BOXES
	#define CHECK_LOCKS_OR_BOXES
	// En vista cenital también al chocar en vertical.
	#ifdef PLAYER_MOGGY_STYLE
		#define CHECK_LOCKS_OR_BOXES_VERT
	#endif
#endif

// Las cajas se empujan también en vertical (solo vista cenital).
#if defined PLAYER_PUSH_BOXES && defined PLAYER_MOGGY_STYLE
	#define PUSH_BOXES_VERT
#endif

// ---------------------------------------------------------------------------
// Enemigos
// ---------------------------------------------------------------------------

// El jugador puede matar enemigos (pisándolos o disparando).
#if defined PLAYER_KILLS_ENEMIES || defined PLAYER_CAN_FIRE
	#define ENEMIES_CAN_DIE
	#ifdef PLAYER_SHOW_KILLS
		#define SHOW_KILLS
	#endif
#endif

// Hay que reiniciar los enemigos (muertos y vida) al empezar.
#if defined ENEMIES_CAN_DIE || defined ENABLE_RANDOM_RESPAWN
	#define NEEDS_INIT_MALOTES
#endif

// Pisar enemigos hace algo (matarlos o rebotar).
#if defined PLAYER_KILLS_ENEMIES || defined PLAYER_STOMPS_ON_ENEMIES
	#define PLAYER_STEPS_ON_ENEMIES
#endif

// Hay enemigos con coordenadas propias (en_an_x / en_an_y) en lugar de las
// del array malotes: fanties y tipo 6.
#if defined ENABLE_RANDOM_RESPAWN || defined ENABLE_CUSTOM_TYPE_6
	#define ENEMS_HAVE_FREE_COORDS
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

// Sprites extra: explosión (sprite 17) y bala (sprite 19).
#if defined PLAYER_CAN_FIRE || defined PLAYER_KILLS_ENEMIES || defined ENABLE_PURSUERS || defined MODE_128K
	#define NEEDS_EXPLOSION_SPRITE
#endif
#if defined PLAYER_CAN_FIRE || defined MODE_128K
	#define NEEDS_BULLET_SPRITE
#endif

// ---------------------------------------------------------------------------
// Disparos
// ---------------------------------------------------------------------------

#ifndef PLAYER_CAN_FIRE
	#ifdef MAX_BULLETS
		#undef MAX_BULLETS
	#endif
	#define MAX_BULLETS 0
#endif

// Las balas se mueven también en vertical.
#if defined PLAYER_MOGGY_STYLE || defined CAN_FIRE_UP
	#define BULLETS_MOVE_VERT
#endif

// ---------------------------------------------------------------------------
// Pantalla y marcador
// ---------------------------------------------------------------------------

// Repintar la pantalla actual desde los buffers (pausa, "get X more").
// (también para que text_box () y dialog_box () puedan borrar su recuadro)
#if defined PAUSE_ABORT || defined GET_X_MORE || (defined ACTIVATE_SCRIPTING && (defined MSC_AU_E6 || defined MSC_RV_E6))
	#define NEEDS_REDRAW_SCR
#endif

// Limpiar la zona de juego (pantalla de nivel, menú de checkpoints).
#if defined COMPRESSED_LEVELS || defined ENABLE_CHECKPOINTS
	#define NEEDS_CLEAR_GAMEAREA
#endif

// Icono del objeto en el marcador (un solo objeto, con scripting).
#if defined ONLY_ONE_OBJECT && defined ACTIVATE_SCRIPTING
	#define SHOW_OBJECT_ICON
#endif

#if defined TIMER_ENABLE && defined PLAYER_SHOW_TIMER
	#define SHOW_TIMER
#endif

// ---------------------------------------------------------------------------
// Scripting
// ---------------------------------------------------------------------------

// Lo que necesitan los scripts lo dice msc-config.h (lo genera msc4 y se
// incluye antes que este archivo).
#ifdef ACTIVATE_SCRIPTING
	// Empujar un bloque: sección TILE PUSHED y variables MOVED_*
	#if defined MSC_SECT_TILE_PUSHED || defined MSC_RV_F4 || defined MSC_RV_F3 || defined MSC_RV_F2
		#define PUSHED_SCRIPTING
	#endif

	// SET FIRE ZONE
	#if defined MSC_AU_51 || defined MSC_AU_52
		#define FIRE_ZONE
	#endif

	// Con niveles cada uno tiene su script, como recurso (ver levels.h).
	#ifdef COMPRESSED_LEVELS
		#define MSC_SCRIPTS_AS_RESOURCES
	#endif

	// Marcador del objeto que se lleva (GET ITEM SET, ITEM SLOT)
	#if defined MSC_AU_30 && defined ITEM_X
		#define MSC_SHOW_ITEM
	#endif

	// TIMER ZERO
	#if defined MSC_SECT_TIMER_ZERO && !defined TIMER_ENABLE
		#error "El script tiene TIMER ZERO pero no está definido TIMER_ENABLE"
	#endif
#endif

// Número de flags que guardan los checkpoints (ninguno sin scripting).
#ifdef ACTIVATE_SCRIPTING
	#define SG_NFLAGS MAX_FLAGS
#else
	#define SG_NFLAGS 0
#endif

// ---------------------------------------------------------------------------
// Niveles
// ---------------------------------------------------------------------------

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
