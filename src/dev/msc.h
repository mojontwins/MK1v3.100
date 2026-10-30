// La Churrera Engine 3.100
// Copyleft 2010-2014, 2026 the Mojon Twins

// msc.h
// Intérprete de scripts de msc4 (MojonTwins Scripting Compiler 4).
//
// msc4 compila los scripts (.spt) a bytecode y escribe msc-config.h, que dice
// qué condiciones, acciones y variables usan. Aquí está el intérprete
// completo, pero cada parte va dentro de su #ifdef MSC_xx_yy: solo se compila
// lo que los scripts del juego necesitan.
//
// Para compilar los scripts:
//     msc4 in=script.spt v=3_100 output=c
// (varios scripts, uno por nivel: in=nivel1.spt,nivel2.spt,... comparten un
// solo msc-config.h).
//
// ---------------------------------------------------------------------------
// El bytecode
// ---------------------------------------------------------------------------
//
// Un script empieza con un índice de palabras de 16 bits (offsets desde el
// principio del script; 0 = la sección no existe):
//
//     [0]  ENTERING GAME              [6]  TIMER ZERO
//     [1]  ENTERING ANY               [7]  TILE PUSHED
//     [2]  PRESS FIRE AT ANY          [8]  ENEMY TOUCHED
//     [3]  PLAYER GOT SOMETHING       [9]  TILE DESTROYED
//     [4]  PLAYER KILLS ENEMY         [15] número de pantallas del índice
//     [5]  SPECIAL TILE TOUCHED
//     [16 + 2n] ENTERING SCREEN n     [17 + 2n] PRESS FIRE AT SCREEN n
//
// Una sección es una lista de cláusulas terminada en 0xFF. Cada cláusula es:
//
//     tamaño  cond cond ... 0xFF  acción acción ... 0xFF
//
// "tamaño" cuenta desde el propio byte de tamaño hasta el principio de la
// cláusula siguiente, así se puede saltar si una condición falla. Las
// acciones que terminan la sección (BREAK, WIN GAME...) no llevan 0xFF.
//
// Los valores (operandos) se leen con msc_value:
//     n           el número n (0-254)
//     0xFF n      el flag n (o una variable especial si n >= 0xE6)
//     0xFF 0xFF n el flag cuyo número está en el flag n... (indirección)

// ---------------------------------------------------------------------------
// Estado del intérprete
// ---------------------------------------------------------------------------

unsigned char *msc_script;		// Script activo (empieza por el índice)
unsigned char *msc_ptr;			// Siguiente byte a leer
unsigned char msc_stop;			// Para cortar la ejecución (ver MSC_STOP_*)

#define MSC_STOP_NO		0
#define MSC_STOP_BREAK	1		// BREAK: termina la sección (o la SUB)
#define MSC_STOP_ALL	2		// WIN GAME, GAME OVER: termina todo
#define MSC_STOP_RERUN	3		// RERUN: vuelve a empezar la sección

unsigned char msc_read (void) {
	return *msc_ptr ++;
}

// Palabra de 16 bits (LSB, MSB), como los offsets del índice. Se copia
// byte a byte (en Z80 y en GB las palabras van LSB, MSB en memoria).
// Ojo con sccz80: no entiende "(unsigned int *) p" ni "&(variable)" tras
// un cast; "(unsigned char *) (&variable)" sí funciona.
unsigned int msc_word;
unsigned int msc_read_word (void) {
	((unsigned char *) (&msc_word)) [0] = *msc_ptr ++;
	((unsigned char *) (&msc_word)) [1] = *msc_ptr ++;
	return msc_word;
}

// Tile, comportamiento... de la casilla (x, y) de la pantalla actual. Fuera de
// la pantalla, 0.
#define MSC_IN_SCREEN(x, y)		((x) < 15 && (y) < 10)

// ---------------------------------------------------------------------------
// Textos (TEXT BOX, DIALOG)
// ---------------------------------------------------------------------------
//
// msc4 codifica los textos a 5 bits por carácter:
//     1-26     A-Z
//     27-30    , . ? !
//     31       espacio
//     0 m      escape: m = 0 fin, m = 1-30 ASCII 32 + m, m = 31 salto de línea
// Ya vienen partidos en líneas de MSC_TEXT_WIDTH caracteres como mucho.

#ifdef MSC_TEXTS
	// msc_text_buf está en definitions.h (lo pueden usar los ganchos de custom.h)
	unsigned char *msc_tptr;
	unsigned char msc_tbyte, msc_tbits;
	unsigned char msc_punct [] = ",.?! ";

	// Lee los siguientes 5 bits (del más alto al más bajo).
	unsigned char msc_5bits (void) {
		unsigned char i, r;
		r = 0;
		for (i = 0; i < 5; i ++) {
			if (msc_tbits == 0) {
				msc_tbyte = *msc_tptr ++;
				msc_tbits = 8;
			}
			r = r + r;
			if (msc_tbyte & 128) r ++;
			msc_tbyte = msc_tbyte + msc_tbyte;
			msc_tbits --;
		}
		return r;
	}

	// Descodifica el texto que empieza en msc_texts [offset] en msc_text_buf
	// (ASCII, con '\n' en los saltos de línea y 0 al final).
	void msc_decode_text (unsigned int offset) {
		unsigned char c, *p;
		p = msc_text_buf;
		if (offset != 0xffff) {
			msc_tptr = msc_texts + offset;
			msc_tbits = 0;
			while (1) {
				c = msc_5bits ();
				if (c == 0) {
					c = msc_5bits ();
					if (c == 0) break;
					*p ++ = (c == 31) ? '\n' : 32 + c;
				} else if (c < 27) {
					*p ++ = 64 + c;
				} else {
					*p ++ = msc_punct [c - 27];
				}
			}
		}
		*p = 0;
	}

	#ifndef MSC_TEXT_ATTR
		#define MSC_TEXT_ATTR 71
	#endif

	// Pinta msc_text_buf en un recuadro centrado en la zona de juego, a partir
	// de la fila y (relativa a la zona de juego). Devuelve la fila siguiente.
	unsigned char msc_print_text (unsigned char y) {
		unsigned char *p, x;
		x = VIEWPORT_X + (30 - MSC_TEXT_WIDTH) / 2;
		p = msc_text_buf;
		y += VIEWPORT_Y;
		while (1) {
			// Una línea: se rellena con espacios hasta MSC_TEXT_WIDTH
			for (gpit = 0; gpit < MSC_TEXT_WIDTH; gpit ++) {
				if (*p == 0 || *p == '\n') {
					sp_PrintAtInv (y, x + gpit, MSC_TEXT_ATTR, 0);
				} else {
					sp_PrintAtInv (y, x + gpit, MSC_TEXT_ATTR, *p ++ - 32);
				}
			}
			y ++;
			if (*p == 0) break;
			p ++;	// salta el '\n'
		}
		return y - VIEWPORT_Y;
	}

	void msc_wait_and_redraw (void) {
		// Hasta que se pulse una tecla (o pasen 100 segundos)
		sp_UpdateNow ();
		sp_WaitForNoKey ();
		espera_activa (5000);
		sp_WaitForNoKey ();
		redraw_scr ();
	}

	// TEXT BOX "...": un recuadro con el texto hasta que se pulse una tecla.
	// Un juego puede mostrarlo a su manera con HOOK_TEXT_BOX en custom.h
	// (el texto ya está descodificado en msc_text_buf).
	void msc_text_box (unsigned int offset) {
		msc_decode_text (offset);
		#ifdef HOOK_TEXT_BOX
			hook_text_box ();
		#else
			msc_print_text (8);
			msc_wait_and_redraw ();
		#endif
	}

	// DIALOG "PREGUNTA", "OPCIÓN 1", "OPCIÓN 2": muestra la pregunta y las
	// opciones (las vacías no salen) y devuelve 1 o 2 según la tecla pulsada.
	// Un juego puede hacerlo a su manera con HOOK_DIALOG en custom.h:
	// unsigned char hook_dialog (unsigned int t1, unsigned int t2, unsigned int t3)
	// (offsets de los textos para msc_decode_text, 0xffff si está vacío).
	#ifdef MSC_RV_E6
		unsigned char msc_dialog (unsigned int t1, unsigned int t2, unsigned int t3) {
			#ifdef HOOK_DIALOG
				return hook_dialog (t1, t2, t3);
			#else
				unsigned char y, r;
				msc_decode_text (t1); y = msc_print_text (5);
				msc_decode_text (t2); y = msc_print_text (y + 1);
				msc_decode_text (t3); msc_print_text (y);
				sp_UpdateNow ();
				sp_WaitForNoKey ();
				while (1) {
					if (sp_KeyPressed (KEY_1)) { r = 1; break; }
					if (sp_KeyPressed (KEY_2)) { r = 2; break; }
				}
				sp_WaitForNoKey ();
				redraw_scr ();
				return r;
			#endif
		}
	#endif
#endif

// ---------------------------------------------------------------------------
// Variables: flags y variables especiales
// ---------------------------------------------------------------------------
//
// Los números de flag a partir de 0xE6 son variables del motor. msc4 las
// traduce: NPANT -> 0xFE, PX -> 0xFD...

unsigned char msc_value (void);

// Valor del flag o variable especial n.
unsigned char msc_var (unsigned char n) {
	#if defined MSC_RV_E8 || defined MSC_RV_E7
		unsigned char x;
	#endif
	switch (n) {
		#ifdef MSC_RV_FE
			case 0xFE: return n_pant;					// NPANT
		#endif
		#ifdef MSC_RV_FD
			case 0xFD: return gpx;						// PX (píxeles)
		#endif
		#ifdef MSC_RV_FC
			case 0xFC: return gpy;						// PY (píxeles)
		#endif
		#ifdef MSC_RV_FB
			case 0xFB: return player.killed;			// KILLED
		#endif
		#ifdef MSC_RV_FA
			case 0xFA: return player.objs;				// OBJS
		#endif
		#ifdef MSC_RV_F9
			case 0xF9: return player.life;				// LIFE
		#endif
		#ifdef MSC_RV_F8
			case 0xF8: return msc_tx;					// TX
		#endif
		#ifdef MSC_RV_F7
			case 0xF7: return msc_ty;					// TY
		#endif
		#ifdef MSC_RV_F6
			case 0xF6: 									// TN: tile en (TX, TY)
				return MSC_IN_SCREEN (msc_tx, msc_ty) ? qtile (msc_tx, msc_ty) : 0;
		#endif
		#ifdef MSC_RV_F5
			case 0xF5: return hotspot_t;				// HOTSPOT
		#endif
		#ifdef MSC_RV_F4
			case 0xF4: return msc_moved_tile;			// MOVED_TILE
		#endif
		#ifdef MSC_RV_F3
			case 0xF3: return msc_moved_x;				// MOVED_X
		#endif
		#ifdef MSC_RV_F2
			case 0xF2: return msc_moved_y;				// MOVED_Y
		#endif
		#ifdef MSC_RV_F1
			#ifndef TIMER_ENABLE
				#error "El script usa TIMER pero no está definido TIMER_ENABLE"
			#endif
			case 0xF1: return ctimer.t;					// TIMER
		#endif
		#ifdef MSC_RV_F0
			case 0xF0: return hide_hotspots;			// HIDE_HOTSPOTS
		#endif
		#ifdef MSC_RV_EF
			case 0xEF: return dont_make_fanties;		// DONT_MAKE_FANTIES
		#endif
		#ifdef MSC_RV_EE
			case 0xEE: return _en_t;					// EN_T
		#endif
		#ifdef MSC_RV_ED
			case 0xED: return gpit;						// EN_N
		#endif
		#ifdef MSC_RV_EC
			case 0xEC: return _en_x;					// EN_X
		#endif
		#ifdef MSC_RV_EB
			case 0xEB: return _en_y;					// EN_Y
		#endif
		#ifdef MSC_RV_EA
			case 0xEA: return o_pant;					// OPANT
		#endif
		#ifdef MSC_RV_E9
			case 0xE9: return msc_param;				// PARAM
		#endif
		#ifdef MSC_RV_E8
			case 0xE8:									// TILE AT X, Y
				x = msc_value (); n = msc_value ();
				return MSC_IN_SCREEN (x, n) ? qtile (x, n) : 0;
		#endif
		#ifdef MSC_RV_E7
			case 0xE7:									// BEH AT X, Y
				x = msc_value ();
				return attr (x, msc_value ());
		#endif
		#ifdef MSC_RV_E6
			case 0xE6:									// DIALOG
				{
					unsigned int t1, t2;
					t1 = msc_read_word ();
					t2 = msc_read_word ();
					return msc_dialog (t1, t2, msc_read_word ());
				}
		#endif
	}
	return n < MAX_FLAGS ? flags [n] : 0;
}

// Escribe v en el flag o variable especial n (lo que está a la izquierda de
// un "=", INC, DEC...). Las variables que solo se pueden leer se ignoran.
void msc_set_var (unsigned char n, unsigned char v) {
	switch (n) {
		#ifdef MSC_LV_FE
			case 0xFE: n_pant = v; return;				// Se cambia de pantalla
		#endif
		#ifdef MSC_LV_FD
			case 0xFD: set_player_at (v, gpy); return;
		#endif
		#ifdef MSC_LV_FC
			case 0xFC: set_player_at (gpx, v); return;
		#endif
		#ifdef MSC_LV_FB
			case 0xFB: player.killed = v; return;
		#endif
		#ifdef MSC_LV_FA
			case 0xFA: player.objs = v; return;
		#endif
		#ifdef MSC_LV_F9
			case 0xF9: player.life = v; return;
		#endif
		#ifdef MSC_LV_F1
			case 0xF1: ctimer.t = v; return;
		#endif
		#ifdef MSC_LV_F0
			case 0xF0: hide_hotspots = v; return;
		#endif
		#ifdef MSC_LV_EF
			case 0xEF: dont_make_fanties = v; return;
		#endif
		#ifdef MSC_LV_EE
			case 0xEE: _en_t = v; return;
		#endif
		#ifdef MSC_LV_EC
			case 0xEC: _en_x = v; return;
		#endif
		#ifdef MSC_LV_EB
			case 0xEB: _en_y = v; return;
		#endif
		#ifdef MSC_LV_EA
			case 0xEA: o_pant = v; return;
		#endif
		#ifdef MSC_LV_E9
			case 0xE9: msc_param = v; return;
		#endif
	}
	if (n < MAX_FLAGS) flags [n] = v;
}

// Lee un valor: un número o, tras 0xFF, el contenido de un flag (que se lee
// a su vez con msc_value, así $$3 es "el flag cuyo número está en el flag 3").
unsigned char msc_value (void) {
	unsigned char v;
	v = msc_read ();
	if (v != 0xFF) return v;
	return msc_var (msc_value ());
}

// ---------------------------------------------------------------------------
// Condiciones
// ---------------------------------------------------------------------------

// Comprueba las condiciones de la cláusula hasta el 0xFF (THEN). Devuelve 0
// en cuanto una falla (el resto de la cláusula se salta con su tamaño).
unsigned char msc_conditions (void) {
	unsigned char a, b;
	while (1) {
		switch (msc_read ()) {
			case 0xFF:									// THEN
				return 1;
			#ifdef MSC_CU_01
				case 0x01:								// IF A = B
					a = msc_value ();
					if (a != msc_value ()) return 0;
					break;
			#endif
			#ifdef MSC_CU_02
				case 0x02:								// IF A < B
					a = msc_value ();
					if (a >= msc_value ()) return 0;
					break;
			#endif
			#ifdef MSC_CU_03
				case 0x03:								// IF A >= B
					a = msc_value ();
					if (a < msc_value ()) return 0;
					break;
			#endif
			#ifdef MSC_CU_04
				case 0x04:								// IF A <> B
					a = msc_value ();
					if (a == msc_value ()) return 0;
					break;
			#endif
			#ifdef MSC_CU_05
				case 0x05:								// IF NPANT = N (fastnpant)
					if (n_pant != msc_value ()) return 0;
					break;
			#endif
			#ifdef MSC_CU_21
				case 0x21:								// IF PLAYER IN_X X1, X2
					a = msc_value (); b = msc_value ();
					if (gpx < a || gpx > b) return 0;
					break;
			#endif
			#ifdef MSC_CU_22
				case 0x22:								// IF PLAYER IN_Y Y1, Y2
					a = msc_value (); b = msc_value ();
					if (gpy < a || gpy > b) return 0;
					break;
			#endif
			#ifdef MSC_CU_23
				case 0x23:								// IF PLAYER AT X, Y (centro del sprite)
					a = msc_value (); b = msc_value ();
					if (((gpx + 8) >> 4) != a || ((gpy + 8) >> 4) != b) return 0;
					break;
			#endif
			#ifdef MSC_CU_24
				case 0x24:								// IF PLAYER FALLING
					if (possee) return 0;
					break;
			#endif
			#ifdef MSC_CU_25
				case 0x25:								// IF PLAYER NOT_FALLING
					if (!possee) return 0;
					break;
			#endif
			#ifdef MSC_CU_26
				case 0x26:								// IF PLAYER STILL
					if (player.vx || player.vy) return 0;
					break;
			#endif
			#ifdef MSC_CU_30
				case 0x30:								// IF TILE AT X, Y = T (forma antigua)
					a = msc_value (); b = msc_value ();
					if (qtile (a, b) != msc_value ()) return 0;
					break;
			#endif
			#ifdef MSC_CU_31
				case 0x31:								// IF BEH AT X, Y = B (forma antigua)
					a = msc_value (); b = msc_value ();
					if (attr (a, b) != msc_value ()) return 0;
					break;
			#endif
			// 0xF0 (IF TRUE) y cualquier otra: se cumple.
		}
	}
}

// ---------------------------------------------------------------------------
// Acciones
// ---------------------------------------------------------------------------

void msc_clausules (void);

#if defined MSC_AU_20 || defined MSC_AU_22
	void msc_set_tile (unsigned char x, unsigned char y, unsigned char t) {
		set_map_tile (x, y, t, comportamiento_tiles [t]);
	}
#endif

#ifdef MSC_AU_E5
	// PAUSE n: espera n frames (1/50 s).
	void msc_pause (unsigned char n) {
		while (n --) {
			#ifdef CPC
				// En CPC hay 6 interrupciones por frame
				#asm
					halt
					halt
					halt
					halt
					halt
					halt
				#endasm
			#else
				#asm
					halt
				#endasm
			#endif
		}
	}
#endif

// Ejecuta las acciones de la cláusula hasta el 0xFF (o una acción que
// termina la sección: entonces deja msc_stop puesto).
void msc_actions (void) {
	unsigned char a, b, c;
	while (1) {
		switch (msc_read ()) {
			case 0xFF:									// Fin de la cláusula
				return;
			#ifdef MSC_AU_00
				case 0x00:								// $A = B
					a = msc_value ();
					msc_set_var (a, msc_value ());
					break;
			#endif
			#ifdef MSC_AU_01
				case 0x01:								// INC $A, B
					a = msc_value ();
					msc_set_var (a, msc_var (a) + msc_value ());
					break;
			#endif
			#ifdef MSC_AU_02
				case 0x02:								// DEC $A, B
					a = msc_value ();
					msc_set_var (a, msc_var (a) - msc_value ());
					break;
			#endif
			#ifdef MSC_AU_20
				case 0x20:								// SET TILE X, Y = T
					a = msc_value (); b = msc_value ();
					msc_set_tile (a, b, msc_value ());
					break;
			#endif
			#ifdef MSC_AU_21
				case 0x21:								// SET BEH X, Y = B
					a = msc_value (); b = msc_value ();
					map_attr [bufidx (a, b)] = msc_value ();
					break;
			#endif
			#ifdef MSC_AU_22
				case 0x22:								// DECOS: T YX T YX ... 0xFF
					while ((c = msc_read ()) != 0xFF) {
						a = msc_read ();
						msc_set_tile (a & 15, a >> 4, c);
					}
					break;
			#endif
			#ifdef MSC_AU_30
				case 0x30:								// GET ITEM SET $F
					// Si no se lleva nada: $F = 1, el objeto pasa a ser el tile
					// TN y se borra de (TX, TY).
					a = msc_value ();
					if (flags [MSC_ITEM_SLOT] == MSC_ITEM_EMPTY) {
						msc_set_var (a, 1);
						flags [MSC_ITEM_SLOT] = qtile (msc_tx, msc_ty);
						set_map_tile (msc_tx, msc_ty, 0, 0);
					}
					break;
			#endif
			#ifdef MSC_AU_50
				case 0x50:								// PRINT TILE X, Y = T
					// Coordenadas de pantalla en caracteres (para el marcador...).
					a = msc_value (); b = msc_value ();
					draw_coloured_tile (a, b, msc_value ());
					break;
			#endif
			#ifdef MSC_AU_51
				case 0x51:								// SET FIRE ZONE X1, Y1, X2, Y2
					// En píxeles: si el jugador está dentro, es como pulsar FIRE.
					fzx1 = msc_value (); fzy1 = msc_value ();
					fzx2 = msc_value (); fzy2 = msc_value ();
					f_zone_ac = 1;
					break;
			#endif
			#ifdef MSC_AU_52
				case 0x52:								// SET FIRE ZONE TILES X1, Y1, X2, Y2
					fzx1 = msc_value () << 4; fzy1 = msc_value () << 4;
					fzx2 = (msc_value () << 4) + 15; fzy2 = (msc_value () << 4) + 15;
					f_zone_ac = 1;
					break;
			#endif
			#ifdef MSC_AU_6D
				case 0x6D:								// WARP TO N, X, Y
					n_pant = msc_value ();
					a = msc_value ();
					set_player_at (a << 4, msc_value () << 4);
					break;
			#endif
			#ifdef MSC_AU_E0
				case 0xE0:								// SOUND N
					PLAY_SFX (msc_value ());
					break;
			#endif
			#ifdef MSC_AU_E1
				case 0xE1:								// SHOW
					sp_UpdateNow ();
					break;
			#endif
			#ifdef MSC_AU_E2
				case 0xE2:								// RECHARGE
					player.life = PLAYER_LIFE;
					break;
			#endif
			#ifdef MSC_AU_E3
				#ifndef LINE_OF_TEXT
					#error "TEXT necesita LINE_OF_TEXT (y LINE_OF_TEXT_X, LINE_OF_TEXT_ATTR) en config.h"
				#endif
				case 0xE3:								// TEXT "..." (línea de texto)
					// Longitud (con el 0 final) y el texto en ASCII
					a = msc_read ();
					print_str (LINE_OF_TEXT_X, LINE_OF_TEXT, LINE_OF_TEXT_ATTR, msc_ptr);
					msc_ptr += a;
					break;
			#endif
			#ifdef MSC_AU_E4
				case 0xE4:								// EXTERN N, M (extern.h)
					a = msc_value ();
					do_extern_action (a, msc_value ());
					break;
			#endif
			#ifdef MSC_AU_E5
				case 0xE5:								// PAUSE N
					msc_pause (msc_value ());
					break;
			#endif
			#ifdef MSC_AU_E6
				case 0xE6:								// TEXT BOX "..."
					msc_text_box (msc_read_word ());
					break;
			#endif
			#ifdef MSC_AU_F0
				case 0xF0:								// WIN GAME
					script_result = 1;
					msc_stop = MSC_STOP_ALL;
					return;
			#endif
			#ifdef MSC_AU_F1
				case 0xF1:								// GAME OVER
					script_result = 2;
					msc_stop = MSC_STOP_ALL;
					return;
			#endif
			#ifdef MSC_AU_F2
				case 0xF2:								// BREAK
					msc_stop = MSC_STOP_BREAK;
					return;
			#endif
			#ifdef MSC_AU_F3
				case 0xF3:								// RERUN V
					// Vuelve a ejecutar la sección desde el principio con PARAM = V
					msc_param = msc_value ();
					msc_stop = MSC_STOP_RERUN;
					return;
			#endif
			#ifdef MSC_AU_F4
				case 0xF4:								// CALL SUB
					{
						unsigned char *ret;
						unsigned int offset;
						offset = msc_read_word ();
						ret = msc_ptr;
						msc_ptr = msc_script + offset;
						msc_clausules ();
						msc_ptr = ret;
						// Un BREAK solo termina la SUB
						if (msc_stop == MSC_STOP_BREAK) msc_stop = MSC_STOP_NO;
						if (msc_stop) return;
					}
					break;
			#endif
		}
	}
}

// ---------------------------------------------------------------------------
// Secciones
// ---------------------------------------------------------------------------

// Ejecuta las cláusulas desde msc_ptr hasta el final de la sección.
void msc_clausules (void) {
	unsigned char *next;
	while (*msc_ptr != 0xFF) {
		next = msc_ptr + *msc_ptr;
		msc_ptr ++;
		if (msc_conditions ()) {
			msc_actions ();
			if (msc_stop) return;
		}
		msc_ptr = next;
	}
}

// Ejecuta la sección sect del script activo, si existe.
void msc_run (unsigned char sect) {
	unsigned int offset;
	msc_ptr = msc_script + sect + sect;
	offset = msc_read_word ();
	if (offset == 0) return;
	msc_param = 0xFF;
	do {
		msc_stop = MSC_STOP_NO;
		msc_ptr = msc_script + offset;
		msc_clausules ();
	} while (msc_stop == MSC_STOP_RERUN);
}

// Igual, pero con TX, TY apuntando a la casilla (x, y).
void msc_run_at (unsigned char sect, unsigned char x, unsigned char y) {
	msc_tx = x; msc_ty = y;
	msc_run (sect);
}

// Secciones de la pantalla: primero la general (ANY) y luego la de la
// pantalla n_pant, si el índice la tiene. sect es MSC_ENTERING_ANY o
// MSC_FIRE_ANY.
void msc_run_screen (unsigned char sect) {
	msc_tx = (gpx + 8) >> 4;
	msc_ty = (gpy + 8) >> 4;
	msc_run (sect);
	#ifdef MSC_SECT_ROOMS
		if (n_pant < msc_script [MSC_IDX_ROOMS << 1]) {
			// ENTERING SCREEN n = 16 + 2n, PRESS FIRE AT SCREEN n = 17 + 2n
			msc_run (16 + n_pant + n_pant + (sect == MSC_FIRE_ANY));
		}
	#endif
}

// Al empezar la partida (o el nivel): flags a 0, sin objeto y sin zona de
// fuego. Con niveles, el script del nivel ya está en msc_buffer.
void msc_init (void) {
	for (gpit = 0; gpit < MAX_FLAGS; gpit ++) flags [gpit] = 0;
	#ifdef MSC_AU_30
		flags [MSC_ITEM_SLOT] = MSC_ITEM_EMPTY;
	#endif
	#ifdef FIRE_ZONE
		f_zone_ac = 0;
	#endif
	script_result = 0;
	#ifdef MSC_SCRIPTS_AS_RESOURCES
		msc_script = msc_buffer;
	#else
		msc_script = msc_scripts [0];
	#endif
}
