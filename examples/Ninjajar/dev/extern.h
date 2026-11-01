// Ninjajar - extern.h
// Copyleft 2014, 2026 The Mojon Twins
//
// Lo que llaman los scripts:
//
//   EXTERN 0        la cortina: borra la zona de juego desde los bordes.
//   EXTERN 1        empiezan las cinemáticas del final: los textos van
//                   debajo del dibujo, sin recuadro.
//   EXTERN 2, n     una cinemática: el dibujo ENDINGn a pantalla completa.
//   EXTERN 3        se acaban las cinemáticas.
//   EXTERN 4..6, t  el inventario: el tile t en el hueco 0..2 del marcador
//                   (47 lo vacía).
//   TEXT BOX "..."  el recuadro de los diálogos, con el texto letra a letra
//                   (una tecla lo escribe de golpe).
//
// En los textos, "<" es la Ñ y ";" las comillas (la fuente tiene ahí esos
// dibujos).
//
// En Game Boy los textos van en la ventana: el recuadro debajo del marcador
// (la ventana crece) y, en las cinemáticas, encima del dibujo, abajo.

unsigned char is_cutscene;
unsigned char exti, extx, exty, stepbystep, keyp;
const unsigned char *extptr;

// La cortina: borra la zona de juego de fuera hacia dentro. En Game Boy,
// un fundido a negro: se vuelve a ver en cuanto se pinte otra cosa.
#ifdef GB
void curtain (void) {
	saca_a_todo_el_mundo_de_aqui ();
	sp_UpdateNow ();
	gb_fade_out (0);
	gb_fade_pending = 1;
}
#else
void curtain (void) {
	saca_a_todo_el_mundo_de_aqui ();
	for (exti = 0; exti < 10; exti ++) {
		for (extx = exti; extx < 30 - exti; extx ++) {
			sp_PrintAtInv (VIEWPORT_Y + exti, VIEWPORT_X + extx, 71, 0);
			sp_PrintAtInv (VIEWPORT_Y + 19 - exti, VIEWPORT_X + extx, 71, 0);
			if (extx < 19 - exti) {
				sp_PrintAtInv (VIEWPORT_Y + extx, VIEWPORT_X + exti, 71, 0);
				sp_PrintAtInv (VIEWPORT_Y + extx, VIEWPORT_X + 29 - exti, 71, 0);
			}
		}
		__asm
			halt
		__endasm;
		sp_UpdateNow ();
	}
}
#endif

// El inventario del marcador: tres huecos para un tile cada uno (las cosas
// que se llevan; qué se lleva lo saben los flags del script). En el Spectrum
// van en la fila 22, en x = 22, 24 y 28; en Game Boy, a la derecha de la
// ventana (dos filas de marcador).
#ifdef GB
	const unsigned char hud_slot_x [] = { 13, 15, 17 };
	#define HUD_SLOT_Y		20
#else
	const unsigned char hud_slot_x [] = { 22, 24, 28 };
	#define HUD_SLOT_Y		22
#endif

void hud_slot (unsigned char n, unsigned char t) {
	draw_coloured_tile (hud_slot_x [n], HUD_SLOT_Y, t);
}

void do_extern_action (unsigned char n, unsigned char m) {
	switch (n) {
		case 0:
			curtain ();
			break;
		case 1:
			is_cutscene = 1;
			break;
		case 2:
			cortina ();
			#ifdef GB
				gb_show_screen (RES_ENDING1 + m - 1);
			#else
				get_resource (RES_ENDING1 + m - 1, 16384);
			#endif
			break;
		case 3:
			cortina ();
			is_cutscene = 0;
			break;
		case 4:
		case 5:
		case 6:
			// El inventario: el tile m en el hueco n - 4 del marcador
			hud_slot (n - 4, m);
			break;
	}
}

#ifdef GB
// TEXT BOX: el texto (ya partido en líneas de GB_TEXT_WIDTH) está en
// msc_text_buf. Va en la ventana: en un recuadro debajo del marcador o, en
// las cinemáticas, sin recuadro, sobre la parte de abajo del dibujo.
void text_box (void) {
	sp_UpdateNow ();						// Por si estaba fundida (curtain)
	exti = 1;
	for (extptr = msc_text_buf; *extptr; extptr ++) if (*extptr == '\n') exti ++;

	if (is_cutscene == 0) {
		gb_win_open (exti + 2);
		exty = 20 + GB_HUD_ROWS;				// Fila del borde de arriba
		print_str (0, exty, 1, "#$$$$$$$$$$$$$$$$$$%");
		for (extx = 1; extx <= exti; extx ++) print_str (0, exty + extx, 1, "&                  '");
		print_str (0, exty + exti + 1, 1, "())))))))))))))))))*");
		exty ++;
	} else {
		gb_win_fixed (exti);
		exty = 20;
	}

	// Letra a letra hasta que se pulse algo (después de soltar lo que se
	// estuviera pulsando)
	extx = 1;
	stepbystep = 1; keyp = 1;
	for (extptr = msc_text_buf; (exti = *extptr); extptr ++) {
		if (exti == '\n') {
			extx = 1; exty ++;
		} else {
			sp_PrintAtInv (exty, extx, 71, exti - 32);
			extx ++;
		}
		if (stepbystep) {
			if (exti != ' ' && is_cutscene == 0) PLAY_SFX (NJ_SFX (8));
			gb_wait_frames (3);
		}
		if (button_pressed ()) {
			if (keyp == 0) stepbystep = 0;
		} else keyp = 0;
	}

	sp_WaitForNoKey ();
	wait_button (5000);
	sp_WaitForNoKey ();

	if (is_cutscene) gb_win_fixed_off (); else gb_win_close ();
}
#else
// TEXT BOX: el texto (ya partido en líneas de 24) está en msc_text_buf
void text_box (void) {
	if (is_cutscene == 0) {
		// Recuadro de 26 de ancho y dos filas por línea de texto
		exti = 1;
		for (extptr = msc_text_buf; *extptr; extptr ++) if (*extptr == '\n') exti ++;
		extx = 3 + exti + exti;			// Fila del borde de abajo

		// Fuera los sprites (el jugador también si el recuadro lo tapa)
		saca_a_todo_el_mundo_de_aqui ();
		if (VIEWPORT_Y + (gpy >> 3) >= extx)
			sp_MoveSprAbs (sp_player, SPRITES_CLIP, 0, VIEWPORT_Y + (gpy >> 3), VIEWPORT_X + (gpx >> 3), gpx & 7, gpy & 7);

		print_str (3, 3, 1, "#$$$$$$$$$$$$$$$$$$$$$$$$%");
		for (exty = 4; exty < extx; exty ++) print_str (3, exty, 1, "&                        '");
		print_str (3, extx, 1, "())))))))))))))))))))))))*");

		exty = 4;
	} else {
		exty = 13;
	}

	// Letra a letra hasta que se pulse algo (después de soltar lo que se
	// estuviera pulsando)
	extx = 4;
	stepbystep = 1; keyp = 1;
	for (extptr = msc_text_buf; (exti = *extptr); extptr ++) {
		if (exti == '\n') {
			extx = 4; exty += 2;
		} else {
			sp_PrintAtInv (exty, extx, 71, exti - 32);
			extx ++;
		}
		if (stepbystep) {
			__asm
				halt
			__endasm;
			if (exti != ' ' && is_cutscene == 0) PLAY_SFX (NJ_SFX (8));
			__asm
				halt
				halt
			__endasm;
			sp_UpdateNow ();
		}
		if (button_pressed ()) {
			if (keyp == 0) stepbystep = 0;
		} else keyp = 0;
	}
	sp_UpdateNow ();

	sp_WaitForNoKey ();
	while (button_pressed ());
	wait_button (5000);

	if (is_cutscene) {
		// Se borra el texto, fila a fila
		for (exty = 13; exty < 21; exty ++) {
			print_str (3, exty, 71, "                          ");
			__asm
				halt
				halt
				halt
				halt
			__endasm;
			sp_UpdateNow ();
		}
	}
}
#endif
