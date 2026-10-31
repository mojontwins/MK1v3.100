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

// Canción del título
#ifndef TITLE_MUSIC
	#define TITLE_MUSIC 0
#endif

// Interrupciones (1/50 s) por frame de juego: 2 = 25 fps, 0 = sin sincronía.
#ifndef GAME_FRAME_TICKS
	#define GAME_FRAME_TICKS 2
#endif

// ---------------------------------------------------------------------------
// Jugador
// ---------------------------------------------------------------------------

// Tecla de salto: con disparo o puñetazo, ARRIBA (o una tecla aparte con dos
// botones); si no, FIRE.
#if defined PLAYER_CAN_FIRE || defined PLAYER_CAN_PUNCH
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

// Motores del jugador: con salto y nado, cada nivel dice cuál usa (cabecera
// del bundle, ver docs/formato-niveles.md). SWIMMING dice si se está nadando
// (una constante si solo hay un motor).
#define ENGINE_JUMP		0
#define ENGINE_SWIM		1
#if defined PLAYER_HAS_SWIM && defined PLAYER_HAS_JUMP && !defined SWITCHABLE_ENGINES
	#define SWITCHABLE_ENGINES
#endif
#ifdef SWITCHABLE_ENGINES
	#define SWIMMING		(player.engine == ENGINE_SWIM)
#elif defined PLAYER_HAS_SWIM
	#define SWIMMING		1
#else
	#define SWIMMING		0
#endif

// Morir y reaparecer en el último sitio seguro necesita saber cuándo se ha
// muerto: kill_player lo marca y el bucle principal lo atiende.
#if defined DIE_AND_RESPAWN && defined PLAYER_MOGGY_STYLE
	#error "DIE_AND_RESPAWN solo funciona en vista lateral"
#endif

// Tiles que matan: comportamiento con el bit 1. En las cintas transportadoras
// (bit 32) el bit 1 es la dirección.
#ifdef ENABLE_CONVEYORS
	#define EVIL_TILE(a)	(((a) & 33) == 1)
	#ifndef CONVEYOR_SPEED
		#define CONVEYOR_SPEED	256			// 1 píxel por frame
	#endif
#else
	#define EVIL_TILE(a)	((a) & 1)
#endif

#if defined PLAYER_CAN_PUNCH && defined PLAYER_CAN_FIRE
	#error "PLAYER_CAN_PUNCH y PLAYER_CAN_FIRE no pueden ir juntos (los dos usan FIRE)"
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

// El jugador puede matar enemigos (pisándolos, disparando o a puñetazos).
#if defined PLAYER_KILLS_ENEMIES || defined PLAYER_CAN_FIRE || defined PLAYER_CAN_PUNCH
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

// ¿Tiene la estructura MALOTE el campo life? (enems.h, que escribe ene2h,
// lo mira).
#if ((defined PLAYER_CAN_FIRE || defined PLAYER_CAN_PUNCH) && ENEMS_LIFE_GAUGE > 1) || defined FORCE_ENEMS_LIFE
	#define MALOTE_HAS_LIFE
#endif

// Enemigos que disparan (tipo 8) y nubes que dejan caer cosas (tipo 9): sus
// proyectiles ("cocos") usan el sprite de la bala.
#if defined ENABLE_SHOOTERS || defined ENABLE_CLOUDS
	#define ENABLE_COCOS
	#ifndef MAX_COCOS
		#define MAX_COCOS 3
	#endif
#else
	#define MAX_COCOS 0
#endif

#ifdef ENABLE_COCOS
	#if defined TYPE_8_FIRE_ONE || defined TYPE_9_FIRE_ONE
		#define COCOS_FIRE_ONE			// Un coco por enemigo (el de su índice)
		#if MAX_COCOS < 3
			#error "TYPE_8_FIRE_ONE / TYPE_9_FIRE_ONE necesitan MAX_COCOS 3"
		#endif
	#endif
	#ifndef TYPE_8_SAFE_DISTANCE
		#define TYPE_8_SAFE_DISTANCE 1
	#endif
	#ifndef TYPE_9_SAFE_DISTANCE
		#define TYPE_9_SAFE_DISTANCE 1
	#endif
#endif

// distance () la usan el tipo 6 y los cocos.
#if defined ENABLE_CUSTOM_TYPE_6 || defined ENABLE_COCOS
	#define NEEDS_DISTANCE
#endif

// Sprites extra: explosión (sprite 17), bala (sprite 19) y puño (20 y 21).
#if defined PLAYER_CAN_FIRE || defined PLAYER_CAN_PUNCH || defined PLAYER_KILLS_ENEMIES || defined ENABLE_PURSUERS || defined MODE_128K
	#define NEEDS_EXPLOSION_SPRITE
#endif
#if defined PLAYER_CAN_FIRE || defined ENABLE_COCOS || defined MODE_128K
	#define NEEDS_BULLET_SPRITE
#endif
#ifdef PLAYER_CAN_PUNCH
	#define NEEDS_PUNCH_SPRITES
	#ifdef PLAYER_MOGGY_STYLE
		#error "PLAYER_CAN_PUNCH solo funciona en vista lateral"
	#endif
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

// Muros rompibles: con BREAKABLE_WALLS_LIFE > 0 cada tile aguanta ese número
// de golpes de más (brk_buff); sin él (o 0) se rompe al primer golpe.
#if defined BREAKABLE_WALLS && defined BREAKABLE_WALLS_LIFE
	#if BREAKABLE_WALLS_LIFE > 0
		#define BREAKABLE_WALLS_HAVE_LIFE
	#endif
#endif
#if defined BREAKABLE_ANIM && !defined BREAKABLE_WALLS
	#error "BREAKABLE_ANIM necesita BREAKABLE_WALLS"
#endif
#if defined PERSISTENT_BREAKABLE && !defined COMPRESSED_LEVELS
	#error "PERSISTENT_BREAKABLE necesita COMPRESSED_LEVELS (el mapa tiene que estar en RAM)"
#endif
#ifdef BREAKABLE_ANIM
	#ifndef MAX_BREAKABLE
		#define MAX_BREAKABLE 3
	#endif
	#ifndef MAX_BREAKABLE_FRAMES
		#define MAX_BREAKABLE_FRAMES 4
	#endif
#endif

// Tiles que se cogen al pasar (TILE_GET) y contador de un flag en el marcador.
#if (defined TILE_GET || defined PLAYER_SHOW_FLAG) && !defined ACTIVATE_SCRIPTING
	#error "TILE_GET y PLAYER_SHOW_FLAG usan los flags del script: necesitan ACTIVATE_SCRIPTING"
#endif
#if defined BREAKABLE_TILE_GET && !defined TILE_GET
	#error "BREAKABLE_TILE_GET necesita TILE_GET"
#endif

// Repintar la pantalla actual desde los buffers (pausa, "get X more").
// (también para que text_box () y dialog_box () puedan borrar su recuadro, y
// para REDRAW)
#if defined PAUSE_ABORT || defined GET_X_MORE || (defined ACTIVATE_SCRIPTING && (defined MSC_AU_E6 || defined MSC_RV_E6 || defined MSC_AU_61))
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
	#define LEVEL_MAP_W			(level_data.header.map_w)
	#define LEVEL_MAP_H			(level_data.header.map_h)
	#define LEVEL_SCR_INI		(level_data.header.scr_ini)
	#define LEVEL_INI_X			(level_data.header.ini_x)
	#define LEVEL_INI_Y			(level_data.header.ini_y)
	#define LEVEL_MAX_OBJS		(level_data.header.max_objs)
	#define LEVEL_ENEMS_LIFE	(level_data.header.enems_life)
	#define LEVEL_SCR_FIN		(level_data.header.scr_fin)
	#define LEVEL_FIN_X			(level_data.header.fin_x)
	#define LEVEL_FIN_Y			(level_data.header.fin_y)
	#define LEVEL_ENGINE		(level_data.header.engine)
	#define LEVEL_FACING		(level_data.header.facing)
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
	#define LEVEL_ENGINE		ENGINE_JUMP
	#define LEVEL_FACING		0
#endif

// Tilesets de los niveles sin la fuente (ts2bin nofont): se cargan encima de
// los 64 primeros caracteres, que se quedan con la fuente del binario.
#ifdef LEVEL_TILESETS_NO_FONT
	#define LEVEL_TILESET_ADDR	((unsigned int) (tileset) + 512)
#else
	#define LEVEL_TILESET_ADDR	((unsigned int) (tileset))
#endif
