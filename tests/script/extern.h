// extern.h de la prueba del intérprete (tests/script): un ejemplo de cómo
// puede un juego mostrar TEXT BOX y DIALOG. tests/build.sh lo copia a
// src/dev en lugar del extern.h vacío.

#ifdef MSC_AU_E4
	void do_extern_action (unsigned char n, unsigned char m) {
	}
#endif

#if defined MSC_AU_E6 || defined MSC_RV_E6
	// Pinta un texto (con '\n' entre líneas) en un recuadro centrado en la
	// zona de juego, desde la fila y. Devuelve la fila siguiente.
	unsigned char test_print_box (unsigned char *p, unsigned char y) {
		unsigned char x, i;
		x = VIEWPORT_X + (30 - MSC_TEXT_WIDTH) / 2;
		y += VIEWPORT_Y;
		while (1) {
			// Una línea, rellena con espacios hasta MSC_TEXT_WIDTH
			for (i = 0; i < MSC_TEXT_WIDTH; i ++) {
				if (*p == 0 || *p == '\n') {
					sp_PrintAtInv (y, x + i, 71, 0);
				} else {
					sp_PrintAtInv (y, x + i, 71, *p ++ - 32);
				}
			}
			y ++;
			if (*p == 0) break;
			p ++;	// salta el '\n'
		}
		return y - VIEWPORT_Y;
	}
#endif

#ifdef MSC_AU_E6
	// Recuadro con el texto hasta que se pulse una tecla
	void text_box (void) {
		test_print_box (msc_text_buf, 8);
		sp_UpdateNow ();
		sp_WaitForNoKey ();
		espera_activa (5000);
		sp_WaitForNoKey ();
		redraw_scr ();
	}
#endif

#ifdef MSC_RV_E6
	// Las opciones numeradas; se elige con 1, 2 o 3
	unsigned char dialog_box (void) {
		unsigned char y, r;
		y = 6;
		for (r = 0; r < 3; r ++) {
			if (msc_options [r][0]) y = test_print_box (msc_options [r], y);
		}
		sp_UpdateNow ();
		sp_WaitForNoKey ();
		while (1) {
			if (sp_KeyPressed (KEY_1)) { r = 1; break; }
			if (sp_KeyPressed (KEY_2) && msc_n_options > 1) { r = 2; break; }
			if (sp_KeyPressed (KEY_3) && msc_n_options > 2) { r = 3; break; }
		}
		sp_WaitForNoKey ();
		redraw_scr ();
		return r;
	}
#endif
