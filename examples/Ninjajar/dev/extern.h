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
//   TEXT BOX "..."  el recuadro de los diálogos, con el texto letra a letra
//                   (una tecla lo escribe de golpe).
//
// En los textos, "<" es la Ñ y ";" las comillas (la fuente tiene ahí esos
// dibujos).

unsigned char is_cutscene;
unsigned char exti, extx, exty, stepbystep, keyp;
const unsigned char *extptr;

// La cortina: borra la zona de juego de fuera hacia dentro
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
			get_resource (RES_ENDING1 + m - 1, 16384);
			break;
		case 3:
			cortina ();
			is_cutscene = 0;
			break;
	}
}

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
