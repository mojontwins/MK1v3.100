// Ninjajar - custom.h
// Copyleft 2014, 2026 The Mojon Twins
//
// Todo lo que Ninjajar añade al motor de MK1 v3.100, con los ganchos de
// src/dev/custom.h:
//
//   HOOK_GAME_INIT        la dedicatoria al arrancar.
//   HOOK_AFTER_TITLE      menú JUGAR / PASSWORD: la contraseña lleva el nivel,
//                         la vida y las monedas (flag 1).
//   HOOK_LEVEL_INTRO      el mapa del mundo con la flecha en el nivel y su
//                         contraseña.
//   HOOK_LEVEL_START      la lava empieza parada (flag 30 a 0).
//   HOOK_ENTERING_SCREEN  repinta la lava que ya ha subido.
//   HOOK_EACH_FRAME       la lava sube y mata (se repite el nivel).
//   HOOK_PLAYER_DIES      el "¡ay!" (un sample) al perder una vida.
//   HOOK_LEVEL_END        "ZONE CLEAR".
//   HOOK_GAME_OVER        "GAME OVER!".
//   HOOK_GAME_ENDING      la pantalla del final y los créditos (las
//                         cinemáticas las hace el script antes de GAME
//                         ENDING, ver extern.h).
//
// Recursos (librarian.txt): RES_DEDICADO, RES_LEVEL (el mapa del mundo),
// RES_ENDING, RES_ENDING1..4, RES_CREDITS. Canciones (ogt/zx128/wyzplayer.asm):
// 4 título, 5 mapa del mundo, 7 zona superada, 8 game over, 9 final, 12
// créditos. Efectos: los de Ninjajar son PLAY_SFX (NJ_SFX (n)).

#define NJ_SFX(n)			(15 + (n))		// Efecto n de Ninjajar (wyzplayer.asm)

// Ganchos que se usan antes de definirlos (extern.h va después)
void curtain (void);

// ¿Tecla o fuego pulsado?
unsigned char button_pressed (void) {
	return sp_GetKey () || (joyfunc ((struct sp_UDK *) &keys) & sp_FIRE) == 0;
}

// Espera n frames o hasta que se pulse algo
void wait_button (unsigned int n) {
	do {
		__asm
			halt
		__endasm;
		if (button_pressed ()) break;
	} while (-- n);
}

// Un mensaje en el centro de la pantalla
#define MESSAGE_COLOUR		79
void print_message (const unsigned char *s) {
	print_str (10, 11, MESSAGE_COLOUR, spacer);
	print_str (10, 12, MESSAGE_COLOUR, s);
	print_str (10, 13, MESSAGE_COLOUR, spacer);
	sp_UpdateNow ();
	sp_WaitForNoKey ();
}

// ---------------------------------------------------------------------------
// Contraseñas
// ---------------------------------------------------------------------------
//
// 8 letras de la A a la P (un nibble cada una): la vida, el nivel, las
// monedas (flag 1) y una suma de comprobación, desordenados.

#define PASSWORD_LENGTH		8
#define MENU_Y 				20
#define MENU_X				11
#define MENU_COLOR			48

unsigned char password_text [PASSWORD_LENGTH + 2];
unsigned char pass_a, pass_b, pass_c, pass_d;

unsigned char makebyte (unsigned char v1, unsigned char v2) {
	return ((v1 - 'A') << 4) + ((v2 - 'A') & 15);
}

void addchar (unsigned char i1, unsigned char i2, unsigned char v) {
	password_text [i1] = (v >> 4) + 'A';
	password_text [i2] = (v & 15) + 'A';
}

void gen_password (void) {
	addchar (7, 0, player.life);
	addchar (1, 6, level);
	addchar (5, 2, flags [1]);
	addchar (3, 4, (player.life << 2) + (level << 1) + flags [1]);
	password_text [PASSWORD_LENGTH] = 0;
}

void do_password (void) {
	print_str (MENU_X, MENU_Y, MENU_COLOR, " PASSWORD ");
	print_str (MENU_X, MENU_Y + 2, MENU_COLOR, "          ");
	password_text [PASSWORD_LENGTH] = ' ';
	password_text [PASSWORD_LENGTH + 1] = 0;
	gpit = PASSWORD_LENGTH; while (-- gpit) password_text [gpit] = '.';
	sp_WaitForNoKey ();
	while (1) {
		password_text [gpit] = '+';
		print_str (16 - PASSWORD_LENGTH / 2, MENU_Y + 2, MENU_COLOR, password_text);
		sp_UpdateNow ();
		do {
			gpjt = sp_GetKey ();
		} while (!gpjt);
		if (gpjt == 12) {						// Borrar
			if (gpit > 0) {
				password_text [gpit] = gpit == PASSWORD_LENGTH ? ' ' : '.';
				gpit --;
			}
		} else if (gpjt == 13) {				// ENTER
			break;
		} else if (gpit < PASSWORD_LENGTH) {
			password_text [gpit] = (gpjt > 'Z') ? gpjt - 32 : gpjt;
			gpit ++;
		}
		PLAY_SFX (NJ_SFX (0));
		sp_WaitForNoKey ();
	}

	sp_WaitForNoKey ();
	wyz_stop_sound ();
	PLAY_SFX (NJ_SFX (1));
	password_text [PASSWORD_LENGTH] = ' ';

	// Si la comprobación cuadra, vale
	pass_a = makebyte (password_text [7], password_text [0]);
	pass_b = makebyte (password_text [1], password_text [6]);
	pass_c = makebyte (password_text [5], password_text [2]);
	pass_d = makebyte (password_text [3], password_text [4]);
	if (pass_d == (unsigned char) ((pass_a << 2) + (pass_b << 1) + pass_c) && pass_b < MAX_LEVELS) {
		player.life = pass_a;
		level = pass_b;
		flags [1] = pass_c;
	}
}

// Tras el título: 1 JUGAR, 2 PASSWORD. Devuelve el nivel.
#define HOOK_AFTER_TITLE
unsigned char hook_after_title (void) {
	level = 0;
	flags [1] = 0;
	print_str (MENU_X - 6, MENU_Y, MENU_COLOR,     "      1 JUGAR         ");
	print_str (MENU_X - 6, MENU_Y + 1, MENU_COLOR, "                      ");
	print_str (MENU_X - 6, MENU_Y + 2, MENU_COLOR, "      2 PASSWORD      ");
	sp_UpdateNow ();
	while (1) {
		gpjt = sp_GetKey ();
		if (gpjt == '1') {
			wyz_stop_sound ();
			PLAY_SFX (NJ_SFX (1));
			break;
		}
		if (gpjt == '2') {
			PLAY_SFX (NJ_SFX (0));
			do_password ();
			break;
		}
	}
	espera_activa (40);
	return level;
}

// ---------------------------------------------------------------------------
// La dedicatoria y el mapa del mundo
// ---------------------------------------------------------------------------

#define HOOK_GAME_INIT
void hook_game_init (void) {
	get_resource (RES_DEDICADO, 16384);
	memset ((unsigned char *) 22528, 71, 768);
	wait_button (250);
}

// Dónde está cada nivel (de la secuencia) en el mapa del mundo
const unsigned char arrowcoords [] = {
	6, 16,		// Tutorial

	7, 14,		// Pueblo
	6, 11,		// Montaña
	7, 10,		// Lago
	8, 8,		// Tienda 1

	7, 6,		// Llanos 1
	6, 5,		// Pozo poroso
	8, 4,		// Bruja Sarollán
	12, 4,		// Tienda 2

	12, 6,		// Llanos 2
	10, 10,		// Cueva Kave
	11, 15,		// Bosque monos
	13, 13, 	// Tienda 3

	16, 16,		// Lago oscuro
	21, 13,		// Castillo 1
	24, 12,		// Tienda 4

	21, 10,		// Pit
	24, 8,		// Cave 2
	20, 7,		// Lava!
	19, 5,		// Tienda 5

	19, 4,		// Playa o montaña
	23, 5,		// Playa (mal)
	16, 4,		// Castillo 2 (bien)
	16, 4		// Final
};

// Antes de cada nivel: el mapa del mundo con la contraseña y una flecha.
#define HOOK_LEVEL_INTRO
void hook_level_intro (void) {
	cortina ();
	get_resource (RES_LEVEL, 16384);
	if (level > 0) {
		gen_password ();
		print_str (12, 20, 71, password_text);
	} else {
		print_str (12, 20, 71, "TUTORIAL");
	}
	sp_PrintAtInv (arrowcoords [level + level + 1], arrowcoords [level + level], (unsigned char) (71 + 128), 30);
	sp_UpdateNow ();
	wyz_play_music (5);
	wait_button (2500);
	curtain ();
}

// ---------------------------------------------------------------------------
// La lava (nivel de la lava): sube cada LAVA_PERIOD frames desde el fondo
// del mapa (que es una columna de pantallas) cuando el script pone el flag
// LAVA_FLAG a 1. Si alcanza al jugador, pierde una vida y se repite el nivel.
// ---------------------------------------------------------------------------

#define LAVA_FLAG			30
#define LAVA_PERIOD			7
#define LAVA_X1				2
#define LAVA_X2				28
#define LAVA_T				18

unsigned char lava_y, lava_ct;

#define HOOK_LEVEL_START
void hook_level_start (void) {
	lava_y = 20 * level_data.header.map_h;
	lava_ct = 0;
	flags [LAVA_FLAG] = 0;
}

// Repinta la lava que ya ha subido en esta pantalla
#define HOOK_ENTERING_SCREEN
void hook_entering_screen (void) {
	if (flags [LAVA_FLAG] == 1 && lava_y / 20 == n_pant) {
		rdd = VIEWPORT_Y + (lava_y % 20);
		for (gpjt = 18 + VIEWPORT_Y; gpjt >= rdd; gpjt --) {
			for (gpit = VIEWPORT_X + LAVA_X1; gpit < VIEWPORT_X + LAVA_X2; gpit += 2) {
				draw_coloured_tile (gpit, gpjt, LAVA_T);
			}
		}
	}
}

#define HOOK_EACH_FRAME
void hook_each_frame (void) {
	if (flags [LAVA_FLAG] != 1) return;
	rdd = lava_y % 20;
	rdt = (lava_y / 20 == n_pant);
	if (LAVA_PERIOD == lava_ct ++) {
		lava_y --;
		lava_ct = 0;
		if (rdt) {
			PLAY_SFX (NJ_SFX (9));
			if (rdd < 19) {
				for (gpit = VIEWPORT_X + LAVA_X1; gpit < VIEWPORT_X + LAVA_X2; gpit += 2) {
					draw_coloured_tile (gpit, VIEWPORT_Y + rdd, LAVA_T);
				}
			}
		}
	}
	if (rdt && (gpy >> 3) + 1 >= rdd) {
		// La lava alcanza al jugador: una vida menos y, si quedan, otra vez
		kill_player (4);
		if (player.life) success = LEVEL_REPEAT;
		playing = 0;
	}
}

// ---------------------------------------------------------------------------
// Morir, superar un nivel, perder, ganar
// ---------------------------------------------------------------------------

// Al perder una vida: el "¡ay!"
#define HOOK_PLAYER_DIES
void hook_player_dies (void) {
	wyz_play_sample (0);
	gpit = 50; do {
		__asm
			halt
		__endasm;
	} while (-- gpit);
}

#define HOOK_LEVEL_END
void hook_level_end (void) {
	wyz_play_music (7);
	print_message (" ZONE CLEAR ");
	wait_button (250);
	curtain ();
}

#define HOOK_GAME_OVER
void hook_game_over (void) {
	wyz_play_music (8);
	print_message (" GAME OVER! ");
	wait_button (250);
}

// Los créditos: pares de líneas de 32 caracteres en RES_CREDITS (sin
// comprimir), que se copian de su página de RAM.
#define CREDITS_PAIRS		27
unsigned char credits_line [33];

void credits_line_at (unsigned char y) {
	ram_page = resources [RES_CREDITS].ramPage;
	address = (unsigned char *) (resources [RES_CREDITS].ramOffset + gpjt * 32);
	destination = credits_line;
	ram_copy_len = 32;
	copy_from_RAMn ();
	credits_line [32] = 0;
	print_str (0, y, 71, credits_line);
	gpjt ++;
}

void credits (void) {
	gpjt = 0;
	for (rdt = 0; rdt < CREDITS_PAIRS; rdt ++) {
		credits_line_at (10);
		credits_line_at (13);
		sp_UpdateNow ();
		wait_button (rdt < CREDITS_PAIRS - 1 ? 200 : 9999);
		cortina ();
	}
}

// GAME ENDING del script (que ya ha mostrado las cinemáticas)
#define HOOK_GAME_ENDING
void hook_game_ending (void) {
	get_resource (RES_ENDING, 16384);
	wait_button (1000);
	wyz_stop_sound ();
	cortina ();
	wyz_play_music (12);
	wait_button (130);
	credits ();
}
