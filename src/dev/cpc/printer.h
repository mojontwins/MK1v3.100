// La Churrera Engine 3.100
// Copyleft 2010-2014 the Mojon Twins

// printer.h
// Pantalla, sprites y teclado del CPC. El fondo es un tilemap de 32x24 (el
// nametable, un byte por tile); lo que se escribe ahí se marca como tocado
// y cpcrslib lo vuelca al superbuffer y a la pantalla en sp_UpdateNow.

unsigned char px, py, pxx, pyy, pt, pn;

// Borra la pantalla: en cada bloque de 2K, los 0x600 bytes que se ven (en
// el resto hay buffers).
void blackout (void) {
	gpit = 0xC0; do {
		memset ((void *) (gpit << 8), BLACK_COLOUR_BYTE, 0x600);
		gpit += 8;
	} while (gpit);
}

// Marca como tocados los tiles del rectángulo (px, py) - (pxx, pyy).
void invalidate_rect (void) __naked {
	__asm
		ld a, (_py)
		ld b, a
		ld a, (_px)
		ld c, a
		ld a, (_pyy)
		ld d, a
		ld a, (_pxx)
		ld e, a
		jp cpc_InvalidateRect
	__endasm;
}

// Estado de las teclas de una línea de la matriz del teclado (bit a 1 =
// pulsada). line es el byte alto del código de la tecla.
unsigned char key_line (unsigned char line) __naked {
	(void) line;
	__asm
		jp cpc_TestKeyboard				; A = línea -> A = teclas
	__endasm;
}

// Actualiza la pantalla: borra los sprites de donde estaban (restaura el
// fondo en el superbuffer), vuelca el nametable tocado al superbuffer,
// dibuja los sprites en su sitio nuevo, espera a que pasen los frames de la
// sincronía y vuelca lo tocado del superbuffer a la pantalla.
void sp_UpdateNow (void) {
	for (gpit = 0; gpit < SW_SPRITES_ALL; gpit ++) {
		#ifdef PLAYER_CAN_FIRE
			if (gpit >= SP_BULLETS_BASE) {
				cpc_PutSPTileMap2Bx8 (&sp_sw [gpit]);
			} else
		#endif
		cpc_PutSPTileMap4Bx16 (&sp_sw [gpit]);
	}

	cpc_UpdScr ();

	for (gpit = 0; gpit < SW_SPRITES_ALL; gpit ++) {
		#ifdef PLAYER_CAN_FIRE
			if (gpit >= SP_BULLETS_BASE) {
				cpc_PutTrSp2Bx8TileMap (&sp_sw [gpit]);
			} else
		#endif
		cpc_PutTrSp4Bx16TileMap (&sp_sw [gpit]);
	}

	while (isr_c2 < MIN_FAPS_PER_FRAME);
	isr_c2 = 0;

	cpc_ShowTouchedTiles ();
	cpc_ResetTouchedTiles ();
}

// Pone el sprite spr_idx en (cx, cy) (pixels del área de juego) con el
// frame next_frame. En el CPC la coordenada x va en bytes (4 pixels).
void cpc_MoveSprAbs (unsigned char spr_idx, const unsigned char *next_frame, unsigned char cx, unsigned char cy) {
	SPR *s = &sp_sw [spr_idx];
	s->cx = (cx >> 2) + VIEWPORT_X * 2;
	s->cy = cy + VIEWPORT_Y * 8;
	s->sp0 = (unsigned int) next_frame;
}

// Color del borde (valor hardware)
void cpc_Border (unsigned char b) {
	gate_array = 0x11;
	gate_array = b;
}

// La ISR (en 0x38, modo 1 de interrupciones): 6 interrupciones por frame.
// En cada frame cuenta isr_c2 y, si está sonando, llama al WYZ player.
void isr (void) __naked {
	__asm
		push af
		push hl
		push de
		push bc
		push ix
		push iy

		ld a, (_isr_c1)
		inc a
		cp #6
		jr c, isr_done

		ld hl, #_isr_c2
		inc (hl)

		ld a, (_isr_player_on)
		or a
		call nz, WYZ_PLAYER_ISR

		xor a
	isr_done:
		ld (_isr_c1), a

		pop iy
		pop ix
		pop bc
		pop de
		pop hl
		pop af
		ei
		ret
	__endasm;
}

// Espera al retrazado vertical
void wait_vsync (void) __naked {
	__asm
		ld b, #0xf5
	wait_vsync_loop:
		in a, (c)
		rra
		jr nc, wait_vsync_loop
		ret
	__endasm;
}

// Lo primero que se llama: prepara el CPC.
void system_init (void) {
	wyz_init ();

	__asm__ ("di");

	// Pantalla y buffers que hay en ella a cero
	memset ((void *) 0xC000, 0, 0x3E00);

	// La ISR: jp _isr en 0x38
	*((unsigned char *) 0x38) = 0xC3;
	*((unsigned int *) 0x39) = (unsigned int) isr;

	// Se sincroniza con el retrazado para empezar a contar
	wait_vsync ();
	isr_c1 = 0;
	__asm__ ("ei");

	cpc_Border (0x54);

	// La LUT de transparencias, descomprimida en su sitio
	unpack ((unsigned char *) trpixlutc, (unsigned char *) BASE_LUT);

	blackout ();

	// Paleta (cpc/pal.h, de mkts_om)
	for (gpit = 0; gpit < 16; gpit ++) {
		gate_array = gpit;
		gate_array = my_inks [gpit] | 0x40;
	}

	#ifdef MODE_1
		cpc_SetMode (1);
	#else
		cpc_SetMode (0);
	#endif

	// Modo retocado de 32x24 caracteres (gracias, Augusto Ruiz)
	crtc_select = 1; crtc_data = 32;		// Caracteres por línea
	crtc_select = 2; crtc_data = 42;		// Posición horizontal
	#if defined MODE_1 && defined AUTO_SPLIT
		crtc_select = 5; crtc_data = 4;		// Ajuste vertical
	#endif
	crtc_select = 6; crtc_data = 24;		// Líneas de caracteres

	// Todos los sprites fuera, en la esquina del área de juego
	for (gpit = 0; gpit < SW_SPRITES_ALL; gpit ++) {
		sp_sw [gpit].ox = (VIEWPORT_X * 8) / 4;
		sp_sw [gpit].oy = VIEWPORT_Y * 8;
	}

	// Teclas por defecto (las del teclado)
	memcpy (keys, def_keys, sizeof (keys));
}

// Dibuja el tile grande t (2x2 caracteres) en (x, y).
void draw_coloured_tile (unsigned char x, unsigned char y, unsigned char t) {
	unsigned char *p = nametable + (y << 5) + x;
	t = 64 + (t << 2);
	p [0] = t ++;
	p [1] = t ++;
	p [32] = t ++;
	p [33] = t;
	px = x; py = y; pxx = x + 1; pyy = y + 1;
	invalidate_rect ();
}

// Pone el carácter t en (x, y). El color no se usa en CPC.
void sp_PrintAtInv (unsigned char y, unsigned char x, unsigned char c, unsigned char t) {
	(void) c;
	nametable [(y << 5) + x] = t;
	px = pxx = x; py = pyy = y;
	invalidate_rect ();
}

// Número de dos cifras en (x, y)
void print_number2 (unsigned char x, unsigned char y, unsigned char value) {
	unsigned char *p = nametable + (y << 5) + x;
	p [0] = 16 + value / 10;
	p [1] = 16 + value % 10;
	px = x; pxx = x + 1; py = pyy = y;
	invalidate_rect ();
}

// Cadena terminada en 0 en (x, y). El color no se usa en CPC.
void print_str (unsigned char x, unsigned char y, unsigned char c, const unsigned char *s) {
	unsigned char *p = nametable + (y << 5) + x;
	(void) c;
	px = pxx = x; py = pyy = y;
	while (*s) {
		*p ++ = *s ++ - 32;
		pxx ++;
	}
	if (pxx != x) {
		pxx --;
		invalidate_rect ();
	}
}

#ifndef DEACTIVATE_OBJECTS
	void draw_objs (void) {
		// Con un solo objeto y scripting: icono del objeto y contador en un flag.
		#ifdef SHOW_OBJECT_ICON
			if (player.objs) {
				sp_PrintAtInv (OBJECTS_ICON_Y, OBJECTS_ICON_X, 135, 132);
				sp_PrintAtInv (OBJECTS_ICON_Y, OBJECTS_ICON_X + 1, 135, 133);
				sp_PrintAtInv (OBJECTS_ICON_Y + 1, OBJECTS_ICON_X, 135, 134);
				sp_PrintAtInv (OBJECTS_ICON_Y + 1, OBJECTS_ICON_X + 1, 135, 135);
			} else {
				draw_coloured_tile (OBJECTS_ICON_X, OBJECTS_ICON_Y, 17);
			}
			print_number2 (OBJECTS_X, OBJECTS_Y, flags [OBJECT_COUNT]);
		#else
			print_number2 (OBJECTS_X, OBJECTS_Y, player.objs);
		#endif
	}
#endif

// Lee las 8 primeras teclas de keys en pad0 y pad1 (bit a 0 = pulsada,
// como en el Spectrum) y en pad_this_frame las que se acaban de pulsar.
void pad_read (void) {
	unsigned char b;
	pad_this_frame = pad1;

	pad0 = 0xff; b = 1;
	for (gpit = 0; gpit < 8; gpit ++) {
		if (key_line (keys [gpit] >> 8) & (unsigned char) keys [gpit]) pad0 &= ~b;
		b <<= 1;
	}
	pad1 = pad0;

	pad_this_frame = (~pad_this_frame) | pad1;
}

// Quita todos los sprites (les pone el frame vacío)
void saca_a_todo_el_mundo_de_aqui (void) {
	for (gpit = 0; gpit < SW_SPRITES_ALL; gpit ++) {
		sp_sw [gpit].sp0 = (unsigned int) (sprite_18_a);
	}
}

void update_this_enemy (void) {
	cpc_MoveSprAbs (SP_ENEMS_BASE + gpit, en_an_next_frame [gpit], _en_x, _en_y);
}

void render_sprites (void) {
	// Render enemies

	for (gpit = 0; gpit < 3; gpit ++) {
		// Fanties y enemigos de tipo 6 tienen sus propias coordenadas (8.8).
		#ifdef ENEMS_HAVE_FREE_COORDS
			if (
				#ifdef ENABLE_RANDOM_RESPAWN
					en_an_fanty_activo [gpit] ||
				#endif
				(malotes [enoffs + gpit].t & 15) == 6	// también muerto (explosión en su sitio)
			) {
				_en_x = FIXED_PIX (en_an_x [gpit]);
				_en_y = FIXED_PIX (en_an_y [gpit]);
			} else
		#endif
		{
			_en_x = malotes [enoffs + gpit].x;
			_en_y = malotes [enoffs + gpit].y;
		}
		update_this_enemy ();
	}

	// Render player

	if (!(player.estado & EST_PARP) || half_life) {
		cpc_MoveSprAbs (0, player.next_frame, gpx, gpy);
	} else {
		sp_sw [SP_PLAYER].sp0 = (unsigned int) (sprite_18_a);
	}

	// Render bullets

	#ifdef PLAYER_CAN_FIRE
		for (gpit = 0; gpit < MAX_BULLETS; gpit ++) {
			if (bullets_estado [gpit] == 1) {
				cpc_MoveSprAbs (SP_BULLETS_BASE + gpit, sprite_19_a, bullets_x [gpit], bullets_y [gpit]);
			} else {
				sp_sw [SP_BULLETS_BASE + gpit].sp0 = (unsigned int) (sprite_18_a);
			}
		}
	#endif
}

#ifdef PLAYER_STEP_SOUND
	void step (void) {
	}
#endif

void cortina (void) {
	// Do something... someday
}

// En el título: 1 = teclado, 2 = joystick.
void select_joyfunc (void) {
	while (1) {
		pad_read ();
		if ((pad_this_frame & sp_AUX3) == 0) {
			memcpy (keys, def_keys, sizeof (keys));
			break;
		}
		if ((pad_this_frame & sp_AUX4) == 0) {
			memcpy (keys, def_keys_joy, sizeof (keys));
			break;
		}
	}
}

// Las pantallas fijas se descomprimen en el superbuffer
void unpack_screen (const unsigned char *src) {
	unpack (src, (unsigned char *) (BASE_SUPERBUFF));
}

// Equivalente a sp_KeyPressed de splib2: distinto de 0 si la tecla está
// pulsada (key = ((0x40 | línea de la matriz) << 8) | bit).
unsigned char sp_KeyPressed (unsigned int key) {
	return key_line (key >> 8) & (unsigned char) key;
}

void sp_WaitForNoKey (void) {
	do {
		pad_read ();
	} while (pad0 != 0xff);
}

// Espera hasta que se pulse una tecla o pasen espera frames
void espera_activa (int espera) {
	sp_WaitForNoKey ();
	do {
		pad_read ();
		// 6 interrupciones = 1 frame
		__asm
			halt
			halt
			halt
			halt
			halt
			halt
		__endasm;
		if (pad_this_frame != 0xff) break;
	} while (espera --);
}
