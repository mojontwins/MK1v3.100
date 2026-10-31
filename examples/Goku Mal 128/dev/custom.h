// Goku Mal - custom.h
// Copyleft 2013, 2026 The Mojon Twins
//
// Todo lo que Goku Mal añade al motor de MK1 v3.100, con los ganchos de
// src/dev/custom.h:
//
//   HOOK_GAME_INIT      logos al arrancar y elección de idioma.
//   HOOK_AFTER_TITLE    menú JUGAR / PASSWORD: devuelve el nivel inicial.
//   HOOK_LEVEL_INTRO    cinemáticas (antes de los niveles 1 y 4) y pantalla
//                       de zona con el número de nivel en grande y la
//                       contraseña.
//   HOOK_WIN_CONDITION  cada nivel se supera a su manera.
//   HOOK_LEVEL_END      "ZONE CLEAR".
//   HOOK_GAME_ENDING    cinemática final y pantalla del final.
//   HOOK_GAME_OVER      game over con su música.
//
// Recursos (librarian.txt): RES_LOGO, RES_ZONEA, RES_INTRO1... Canciones
// (ogt/zx128/canciones.asm): 0 título, 1 intro, 2 zona, 6 zona superada,
// 8 game over, 9 final; las de cada fase van en levelset.h.

// ---------------------------------------------------------------------------
// Idioma
// ---------------------------------------------------------------------------

unsigned char language;			// 0 inglés, 1 español

// Efectos (números de MK1, ver ogt/zx128/efectos.asm)
#define SFX_SELECT			12
#define SFX_START			2

// Pone a negro los atributos de la zona de juego (las cinemáticas y la
// pantalla de zona se cargan "a oscuras").
void blackout_area (void) {
	unsigned char *p;
	p = (unsigned char *) (22528 + 32 * VIEWPORT_Y + VIEWPORT_X);
	for (gpit = 0; gpit < 20; gpit ++) {
		for (gpjt = 0; gpjt < 30; gpjt ++) p [gpjt] = 0;
		p += 32;
	}
}

// ---------------------------------------------------------------------------
// Cinemáticas
// ---------------------------------------------------------------------------
//
// Cada trozo de la historia es un dibujo a pantalla completa (RES_INTRO1 + n)
// con un texto que se escribe letra a letra (una tecla lo escribe de golpe).
// En los textos, @ es un salto de línea. Los 7 primeros están en inglés y
// los 7 siguientes en español.

#define INTRO_X				2		// Esquina del texto
#define INTRO_Y 			12
#define INTRO_TEXT_COLOUR	71
#define SCREEN_WAIT			250		// Frames que se queda cada dibujo
#define LANG_TEXT_OFFS		7		// Textos por idioma

const unsigned char * const intro_texts [] = {
	//    "----------------------------OOOOOOOOOOOOOOOOOOOOOOOOOOOO----------------------------OOOOOOOOOOOOOOOOOOOOOOOOOOOO"
	"'WILL BUILD A PRETTY LADY!'@SAID ELEUTERIO IN HIS NOOK@AND WITH A GRIN SHADY@AWAITS FOR THE MIX TO COOK",
	"BUT AYE! THIS HAS GONE BAD!@'THIS AIN'T A PRETTY LADY'@'THIS IS A 'GOKU BAD'!'@SAID THE MONKEY, SHAKY",
	"ANGRY, HE THREW GOKU AWAY,@AND IN A MOUNTAIN OF SOCKS@HE PUT HIM TO LAY@AND FLEW TO THE DOCKS.",
	"BUT GOKU SOON AWOKE,@AND SWORE LIKE FEY@HE WOULD CHASE THAT BLOKE@AND MAKE HIM PAY!",
	"MONKEY CALLS GOKU SCOURED:@'WE COULD MAKE A DEAL:@PICK UP SOME FLOWERS@FOR A LADY IN STILETTO HEELS'",
	"'MONKEY, YOU SHALL PAY!'@'WAIT, MEET THIS LADY HERE'@SAID THE MONKEY IN DISARRAY@'I MADE HER FOR YOU, SEE!'",
	"'GET OUT OF MY WAY, MAD APE'@SAID GOKU THROWING A PUNCH@AND WITH THE LADY HE ESCAPED@MARRIED AND BRED A BUNCH.",

	"'ME HARE UNA MUJER ENCUERA'@DIJO ELEUTERIO EL MONO,@Y EN SU LABORATORIO ESPERA@QUE LA MEZCLA ESTE A TONO.",
	"SIN EMBARGO, ALGO FUE FATAL:@NO SALIO UNA MUJER ENCUERA.@'ME HA SALIDO UN GOKU MAL!'@DIJO EL MONO CON CARRASPERA.",
	"ENFADADO, AL GOKU DESECHO,@Y EN UN MONTON DE CALCETINES@DE CABEZA LO TIRO...@Y SE FUE A LOS MULTICINES.",
	"PERO GOKU DESPERTO,@Y JURO QUE SE VENGARIA@DE AQUEL QUE LO ENGENDRO@Y QUE NO LO QUERIA.",
	"EL MONO LLAMA A GOKU MAL@'TENGO ALGO QUE PROPONERTE:@REUNE UN RAMILLETE FLORAL,@UNA CHICA QUIERE CONOCERTE'",
	"'MONO, TENDRAS TU MERECIDO'@'TU NECESITAS NOVIA FORMAL'@CONTESTO EL MONO CONVENCIDO@'HE HECHO UNA MORTICIA MAL'",
	"'QUITA, YA NO ME INTERESAS'@DIJO GOKU DANDO UN MANOTAZO@SE MARCHO CON LA TIPA ESA@Y CERRO DANDO UN PORTAZO."
};

unsigned char introx, introy, stepbystep, character;

void show_intro_text (const unsigned char *s) {
	introx = INTRO_X;
	introy = INTRO_Y;
	stepbystep = 1;
	while (*s) {
		character = *s ++;
		if (character != '@') sp_PrintAtInv (introy, introx ++, INTRO_TEXT_COLOUR, character - 32);
		if (stepbystep) {
			// Letra a letra, hasta que se pulse una tecla
			__asm
				halt
				halt
				halt
				halt
			__endasm;
			sp_UpdateNow ();
			if (sp_GetKey ()) stepbystep = 0;
		}
		if (character == '@') { introy += 2; introx = INTRO_X; }
	}
	if (!stepbystep) sp_UpdateNow ();
}

// Muestra los trozos de historia ini a fin.
unsigned char intro_iterator;
void do_intro (unsigned char ini, unsigned char fin) {
	for (intro_iterator = ini; intro_iterator <= fin; intro_iterator ++) {
		sp_UpdateNow ();
		blackout_area ();
		get_resource (RES_INTRO1 + intro_iterator, 16384);
		show_intro_text (intro_texts [intro_iterator + LANG_TEXT_OFFS * language]);
		sp_WaitForNoKey ();
		espera_activa (SCREEN_WAIT);
		sp_WaitForNoKey ();
	}
	blackout_area ();
}

// ---------------------------------------------------------------------------
// Menú y contraseñas
// ---------------------------------------------------------------------------
//
// JUGAR empieza en el nivel 1; con la contraseña de un nivel se empieza en
// él. Las contraseñas tienen PASSWORD_LENGTH letras (una por nivel, desde el 2).

#define PASSWORD_LENGTH	6
#define MENU_Y 			16
#define MENU_X			11

const unsigned char passwords [] = "TETICA" "PICHON" "CULETE" "BUTACA";

const unsigned char clearout [] = "          ";
unsigned char password [PASSWORD_LENGTH + 2];		// Las letras, un espacio y el 0 final
unsigned char pw_ok;

// Pide una contraseña; devuelve su nivel (0 si no es ninguna).
unsigned char which_level (void) {
	const unsigned char *passpointer;
	passpointer = passwords;
	print_str (MENU_X, MENU_Y, 7, " PASSWORD ");
	print_str (MENU_X, MENU_Y + 1, 7, clearout);
	print_str (MENU_X, MENU_Y + 2, 7, clearout);
	for (gpit = 0; gpit < PASSWORD_LENGTH; gpit ++) password [gpit] = '.';
	password [PASSWORD_LENGTH] = ' ';
	gpit = 0;
	sp_WaitForNoKey ();
	while (1) {
		password [gpit] = '*';
		print_str (16 - PASSWORD_LENGTH / 2, MENU_Y + 2, 71, password);
		sp_UpdateNow ();
		do {
			gpjt = sp_GetKey ();
		} while (!gpjt);
		if (gpjt == 12 && gpit > 0) {			// Borrar
			password [gpit] = gpit == PASSWORD_LENGTH ? ' ' : '.';
			gpit --;
		}
		if (gpjt == 13) break;					// ENTER
		if (gpjt > 'Z') gpjt -= 32;
		if (gpjt >= 'A' && gpjt <= 'Z' && gpit < PASSWORD_LENGTH) {
			password [gpit] = gpjt;
			gpit ++;
		}
		PLAY_SFX (SFX_SELECT);
		sp_WaitForNoKey ();
	}

	sp_WaitForNoKey ();
	wyz_stop_sound ();
	PLAY_SFX (SFX_START);

	for (gpit = 0; gpit < MAX_LEVELS - 1; gpit ++) {
		pw_ok = 1;
		for (gpjt = 0; gpjt < PASSWORD_LENGTH; gpjt ++) {
			if (password [gpjt] != *passpointer ++) pw_ok = 0;
		}
		if (pw_ok) return 1 + gpit;
	}

	return 0;
}

unsigned char simple_menu (void) {
	if (language) {
		print_str (MENU_X, MENU_Y, 7, "-= MENU =-");
		print_str (MENU_X, MENU_Y + 1, 7, "1 JUGAR   ");
	} else {
		print_str (MENU_X, MENU_Y, 7, "-=SELECT=-");
		print_str (MENU_X, MENU_Y + 1, 7, "1 PLAY    ");
	}
	print_str (MENU_X, MENU_Y + 2, 7, "2 PASSWORD");
	sp_UpdateNow ();
	sp_WaitForNoKey ();
	while (1) {
		gpjt = sp_GetKey ();
		if (gpjt == '1') {
			wyz_stop_sound ();
			PLAY_SFX (SFX_START);
			return 0;
		}
		if (gpjt == '2') {
			PLAY_SFX (SFX_SELECT);
			return which_level ();
		}
	}
}

void print_password (unsigned char x, unsigned char y, unsigned char lvl) {
	const unsigned char *passpointer;
	passpointer = passwords + (lvl - 1) * PASSWORD_LENGTH;
	for (gpit = 0; gpit < PASSWORD_LENGTH; gpit ++) {
		sp_PrintAtInv (y, x ++, 70, (*passpointer ++) - 32);
	}
}

// ---------------------------------------------------------------------------
// Números de nivel
// ---------------------------------------------------------------------------
//
// El número de cada nivel, en grande: 9x6 caracteres del tileset de la
// pantalla de zona (RES_LEVELTSC).

const unsigned char levelnumbers [54 * 5] = {
	 64, 65, 66, 66, 66, 66, 66,  0,  0,
	 67, 68, 66, 66, 66, 66, 66,  0,  0,
	  0,  0, 66, 66, 66, 66, 66,  0,  0,
	  0,  0, 66, 66, 66, 66, 66,  0,  0,
	  0,  0, 66, 66, 66, 66, 66,  0,  0,
	 69, 66, 66, 66, 66, 66, 66, 66, 70,

	 71, 66, 66, 66, 66, 66, 66, 66, 72,
	 66, 66, 73, 74, 74, 74, 75, 66, 66,
	  0,  0, 76, 77, 78, 79, 66, 66, 80,
	 81, 79, 66, 66, 82, 83, 84, 85,  0,
	 66, 66, 86, 85,  0,  0,  0, 66, 66,
	 66, 66, 66, 66, 66, 66, 66, 66, 66,

	 66, 66, 66, 66, 66, 66, 66, 66, 66,
	 66, 66, 87, 88, 89, 90, 66, 91, 92,
	  0, 93, 94, 95, 66, 66, 66, 96, 97,
	 98, 68, 68, 68, 68, 68, 99, 66, 66,
	 66, 66,114,  0,  0,  0,115, 66, 66,
	100, 66, 66, 66, 66, 66, 66, 66,101,

	  0,  0,102,103, 66,104,105,  0,  0,
	102,103, 66,104,105,  0,  0,  0,  0,
	 66,104,105,  0,106,106,  0,  0,  0,
	 66, 66, 66, 66, 66, 66, 66, 66, 66,
	 66, 66, 66, 66, 66, 66, 66, 66, 66,
	  0,  0,  0,  0, 66, 66,  0,  0,  0,

	 66, 66, 66, 66, 66, 66, 66, 66, 66,
	 66, 66,  0,  0,  0,  0,  0,  0,  0,
	 66, 66,107,108, 66, 66, 66,109,110,
	 68, 68,111,112,112,112,113, 66, 66,
	 66, 66,114,  0,  0,  0,115, 66, 66,
	100, 66, 66, 66, 66, 66, 66, 66,101
};

// ---------------------------------------------------------------------------
// Ganchos
// ---------------------------------------------------------------------------

// Al arrancar: los logos y el idioma.
#define HOOK_GAME_INIT
void hook_game_init (void) {
	blackout ();
	get_resource (RES_LOGO, 16384);
	PLAY_SFX (SFX_START);
	espera_activa (250);
	cortina ();

	blackout ();
	get_resource (RES_CONTROLS, 16384);
	PLAY_SFX (SFX_START);
	espera_activa (500);
	cortina ();

	blackout ();
	get_resource (RES_DEDICADO, 16384);
	PLAY_SFX (SFX_START);
	espera_activa (250);
	cortina ();

	print_str (11, 11, 71, "1. ENGLISH");
	print_str (11, 12, 71, "2. SPANISH");
	sp_UpdateNow ();
	sp_WaitForNoKey ();
	while (1) {
		gpjt = sp_GetKey ();
		if (gpjt == '1' || gpjt == '2') break;
	}
	language = gpjt - '1';
	cortina ();
}

// Tras el título: menú JUGAR / PASSWORD.
#define HOOK_AFTER_TITLE
unsigned char hook_after_title (void) {
	gpaux = simple_menu ();
	espera_activa (54);			// Deja sonar el efecto
	return gpaux;
}

// Antes de cada nivel: cinemática (niveles 1 y 4) y pantalla de zona.
const unsigned char *levelnumbers_ptr;
#define HOOK_LEVEL_INTRO
void hook_level_intro (void) {
	blackout_area ();

	if (level == 0) {
		wyz_play_music (1);
		do_intro (0, 3);
		wyz_stop_sound ();
	} else if (level == 3) {
		wyz_play_music (1);
		do_intro (4, 4);
		wyz_stop_sound ();
	}
	sp_UpdateNow ();

	// Tileset con los números grandes (prepare_level carga luego el del nivel)
	get_resource (RES_LEVELTSC, (unsigned int) (tileset));

	if (level > 0) {
		get_resource (RES_ZONEB, 16384);
		print_str (7, 18, 70, " PASSWORD ");
		print_password (9, 19, level);
	} else {
		get_resource (RES_ZONEA, 16384);
	}

	levelnumbers_ptr = levelnumbers + level * 54;
	for (gpit = 0; gpit < 6; gpit ++) {
		for (gpjt = 0; gpjt < 9; gpjt ++) {
			sp_PrintAtInv (16 + gpit, 22 + gpjt, 71, *levelnumbers_ptr ++);
		}
	}
	sp_UpdateNow ();

	wyz_play_music (2);
	espera_activa (250);
	wyz_stop_sound ();
}

// Cómo se supera cada nivel: llegar a la otra punta del mapa o, en el
// nivel 4, coger todas las flores (max_objs del nivel).
#define HOOK_WIN_CONDITION
unsigned char hook_win_condition (void) {
	if (level == 3) return player.objs == LEVEL_MAX_OBJS;
	if (level == 0 || level == 2) return n_pant == 0;
	return n_pant == 24;
}

#define HOOK_LEVEL_END
void hook_level_end (void) {
	wyz_play_music (6);
	print_str (10, 11, 79, spacer);
	print_str (10, 12, 79, " ZONE CLEAR ");
	print_str (10, 13, 79, spacer);
	sp_UpdateNow ();
	sp_WaitForNoKey ();
	espera_activa (250);
	wyz_stop_sound ();
}

#define HOOK_GAME_ENDING
void hook_game_ending (void) {
	wyz_play_music (9);
	do_intro (5, 6);
	game_ending ();
	wyz_stop_sound ();
}

#define HOOK_GAME_OVER
void hook_game_over (void) {
	wyz_play_music (8);
	if (ctimer.zero) {
		time_over ();
	} else {
		recuadre (" GAME OVER! ");
		sp_UpdateNow ();
		espera_activa (500);
	}
}
