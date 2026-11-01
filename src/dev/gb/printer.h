// La Churrera Engine 3.100 - Game Boy
// Copyleft 2026 the Mojon Twins

// gb/printer.h
// Pantalla, sprites y mandos del Game Boy (el equivalente de speccy/printer.h
// y cpc/printer.h).
//
// La pantalla del juego (30x20 caracteres) está en el fondo (0x9800) y se
// escribe directamente en la VRAM, esperando en cada escritura a que se
// pueda (gb/vram.s). Los números de carácter son los del Spectrum (0-63 la
// fuente, 64 + 4 * t el tile t): en el modo 0x8800 del fondo, el carácter c
// es el tile c ^ 128 (ver gb/mk1gb.h).

unsigned char px, py, pt;
unsigned char *gb_ptr;

// Cámara: la esquina de arriba a la izquierda de lo que se ve
unsigned char gb_cam_x, gb_cam_y;

// Recursos que van a la VRAM y se cargan en gb_game_frame (con la pantalla
// apagada): el tileset que toca y, si un nivel trae el suyo, el spriteset.
unsigned char gb_tileset_res, gb_spriteset_res;

// Al empezar la pantalla del juego está en negro: se funde desde negro en el
// primer sp_UpdateNow, cuando ya está pintada.
unsigned char gb_fade_pending;

// Dirección en la VRAM del carácter (x, y): en el fondo si y < 20 y en la
// ventana (fila y - 20) si no. Fuera de 32x32 (los 99 de config.h), 0.
unsigned char *gb_xy (unsigned char x, unsigned char y) {
	if (x > 31) return 0;
	if (y < 20) return (unsigned char *) (GB_BKG_MAP + ((unsigned int) y << 5) + x);
	y -= 20;
	if (y > 17) return 0;
	return (unsigned char *) (GB_WIN_MAP + ((unsigned int) y << 5) + x);
}

void blackout (void) {
	gb_fade_out (0);
}

void cortina (void) {
	gb_fade_out (0);
}

void system_init (void) {
	// Paletas de config.h (gb_init ha puesto las de mk1gb.h)
	gb_pal_bg = GB_PAL_BG;
	gb_pal_obj0 = GB_PAL_OBJ0;
	gb_pal_obj1 = GB_PAL_OBJ1;

	// Los sprites (la pantalla sigue apagada desde gb_init)
	get_resource (RES_SPRITES, GB_VRAM_SPRITES);
	// El tileset del juego (con niveles, cada nivel pone el suyo)
	#ifdef RES_TILESET
		gb_tileset_res = RES_TILESET;
	#endif
	gb_spriteset_res = 0xff;
}

// Escribe el texto s (ASCII) en la VRAM desde p
void gb_print_raw (unsigned char *p, const unsigned char *s) {
	while (*s) gb_vram_put (p ++, *s ++ + 96);
}

// La pantalla del juego: fundido a negro y, con la pantalla apagada, el
// tileset (y el spriteset del nivel), el fondo vacío y el marcador. Se queda
// en negro hasta el primer sp_UpdateNow.
void gb_game_frame (void) {
	gb_fade_out (0);
	DISPLAY_OFF;
	get_resource (gb_tileset_res, GB_VRAM_PATTERNS);
	if (gb_spriteset_res != 0xff) {
		get_resource (gb_spriteset_res, GB_VRAM_SPRITES);
		gb_spriteset_res = 0xff;
	}

	// Fondo vacío (el tile 0, que suele ser el fondo) y ventana en blanco
	memset ((void *) GB_BKG_MAP, GB_PATTERN (0), 32 * 20);
	memset ((void *) GB_WIN_MAP, GB_CHAR (' '), 32 * 18);

	// Los textos fijos del marcador
	#ifdef GB_HUD_LINE0
		gb_print_raw ((unsigned char *) GB_WIN_MAP, GB_HUD_LINE0);
	#endif
	#ifdef GB_HUD_LINE1
		gb_print_raw ((unsigned char *) GB_WIN_MAP + 32, GB_HUD_LINE1);
	#endif
	#ifdef GB_HUD_LINE2
		gb_print_raw ((unsigned char *) GB_WIN_MAP + 64, GB_HUD_LINE2);
	#endif
	#ifdef GB_HUD_LINE3
		gb_print_raw ((unsigned char *) GB_WIN_MAP + 96, GB_HUD_LINE3);
	#endif

	gb_oam_clear ();
	gb_cam_x = gb_cam_y = 0;
	gb_game_screen ((unsigned char) GB_VIEW_H);
	DISPLAY_ON;
	gb_fade_pending = 1;
}

// Mensajes: la ventana crece n filas hacia arriba y debajo del marcador
// quedan n filas vacías (las filas 20 + GB_HUD_ROWS... para print_str).
void gb_win_open (unsigned char n) {
	gb_ptr = (unsigned char *) GB_WIN_MAP + GB_HUD_ROWS * 32;
	for (pt = 0; pt < n; pt ++) {
		for (px = 0; px < 20; px ++) gb_vram_put (gb_ptr ++, GB_CHAR (' '));
		gb_ptr += 12;
	}
	wait_vbl_done ();
	gb_set_wy ((unsigned char) GB_VIEW_H - (n << 3));
}

// La ventana vuelve a ser solo el marcador
void gb_win_close (void) {
	wait_vbl_done ();
	gb_set_wy ((unsigned char) GB_VIEW_H);
}

// Texto sobre una pantalla fija (cinemáticas): la ventana, con n filas
// vacías (las 20... para print_str), tapa la parte de abajo.
void gb_win_fixed (unsigned char n) {
	gb_ptr = (unsigned char *) GB_WIN_MAP;
	for (pt = 0; pt < n; pt ++) {
		for (px = 0; px < 20; px ++) gb_vram_put (gb_ptr ++, GB_CHAR (' '));
		gb_ptr += 12;
	}
	wait_vbl_done ();
	WY_REG = 144 - (n << 3);
	WX_REG = 7;
	LCDC_REG |= LCDCF_WINON;
}

void gb_win_fixed_off (void) {
	wait_vbl_done ();
	LCDC_REG &= ~LCDCF_WINON;
}

// Una pantalla vacía (todo el fondo con espacios), sin sprites ni ventana,
// con fundido.
void gb_text_screen (void) {
	gb_fade_out (0);
	DISPLAY_OFF;
	gb_fixed_screen ();
	memset ((void *) GB_BKG_MAP, GB_CHAR (' '), 32 * 18);
	DISPLAY_ON;
	gb_fade_in (0);
}

// Dibuja el tile grande t (2x2 caracteres) en (x, y).
void draw_coloured_tile (unsigned char x, unsigned char y, unsigned char t) {
	if ((gb_ptr = gb_xy (x, y))) gb_vram_tile2x2 (gb_ptr, GB_PATTERN (t << 2));
}

// Pone el carácter t en (x, y). El color no se usa.
void sp_PrintAtInv (unsigned char y, unsigned char x, unsigned char c, unsigned char t) {
	(void) c;
	if ((gb_ptr = gb_xy (x, y))) gb_vram_put (gb_ptr, t ^ 128);
}

// Número de dos cifras en (x, y). Las decenas se cuentan restando.
void print_number2 (unsigned char x, unsigned char y, unsigned char number) {
	if ((gb_ptr = gb_xy (x, y))) {
		pt = 0;
		while (number >= 10) { number -= 10; pt ++; }
		gb_vram_put (gb_ptr, GB_CHAR ('0' + pt));
		gb_vram_put (gb_ptr + 1, GB_CHAR ('0' + number));
	}
}

// Cadena terminada en 0 en (x, y). El color no se usa.
void print_str (unsigned char x, unsigned char y, unsigned char c, const unsigned char *s) {
	(void) c;
	if ((gb_ptr = gb_xy (x, y))) gb_print_raw (gb_ptr, s);
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

// ---------------------------------------------------------------------------
// Mandos
// ---------------------------------------------------------------------------

// pad0 y pad1: botones pulsados (bit a 0); pad_this_frame: los que se
// acaban de pulsar. B salta: hace de ARRIBA (o de FIRE si se salta con FIRE).
void pad_read (void) {
	unsigned char j;
	pad_this_frame = pad1;
	j = joypad ();
	#ifdef JUMP_ON_UP
		if (j & J_B) j |= J_UP;
	#elif defined JUMP_ON_FIRE
		if (j & J_B) j |= J_A;
	#endif
	pad1 = pad0 = ~j;
	pad_this_frame = (~pad_this_frame) | pad1;
}

// Distinto de 0 si el botón (o los botones) key está pulsado
unsigned char sp_KeyPressed (unsigned char key) {
	return joypad () & key;
}

// Distinto de 0 si hay algún botón pulsado
unsigned char sp_GetKey (void) {
	return joypad ();
}

void sp_WaitForNoKey (void) {
	while (joypad ()) wait_vbl_done ();
}

// Espera "espera" frames o hasta que se pulse un botón
void espera_activa (int espera) {
	do {
		wait_vbl_done ();
		if (joypad ()) break;
	} while (-- espera);
}

// En el título: START o A
void select_joyfunc (void) {
	while (!(joypad () & (J_START | J_A))) {
		wait_vbl_done ();
		rand ();
	}
	sp_WaitForNoKey ();
}

// ---------------------------------------------------------------------------
// Sprites
// ---------------------------------------------------------------------------

// La cámara sigue al jugador, sin salirse de la pantalla del juego
void gb_camera (void) {
	gb_cam_x = gpx < 72 ? 0 : gpx - 72;
	if (gb_cam_x > GB_CAM_MAX_X) gb_cam_x = GB_CAM_MAX_X;
	gb_cam_y = gpy < (GB_VIEW_H / 2 - 8) ? 0 : gpy - (GB_VIEW_H / 2 - 8);
	if (gb_cam_y > GB_CAM_MAX_Y) gb_cam_y = GB_CAM_MAX_Y;
}

// Sprite de 16x16 (dos del hardware, desde el n) en (x, y) de la pantalla del
// juego con el frame f. El sprite 18 (vacío) lo quita.
void gb_spr16 (unsigned char n, unsigned char x, unsigned char y, const unsigned char *f) {
	gb_ptr = gb_oam + (n << 2);
	if (f == sprite_18_a) {
		gb_ptr [0] = gb_ptr [4] = 0;
		return;
	}
	pt = (unsigned char) (unsigned int) f;
	y = y - gb_cam_y + 16;
	x = x - gb_cam_x + 8;
	gb_ptr [0] = y; gb_ptr [1] = x; gb_ptr [2] = pt; gb_ptr [3] = 0;
	gb_ptr [4] = y; gb_ptr [5] = x + 8; gb_ptr [6] = pt + 2; gb_ptr [7] = 0;
}

// Sprite de 8x8 (la mitad de arriba de un 8x16 del hardware)
void gb_spr8 (unsigned char n, unsigned char x, unsigned char y, const unsigned char *f) {
	gb_ptr = gb_oam + (n << 2);
	gb_ptr [0] = y - gb_cam_y + 16;
	gb_ptr [1] = x - gb_cam_x + 8;
	gb_ptr [2] = (unsigned char) (unsigned int) f;
	gb_ptr [3] = 0;
}

void gb_spr_off (unsigned char n) {
	gb_oam [n << 2] = 0;
}

// Actualiza la pantalla: los sprites y la cámara se verán en el próximo
// vblank. La primera vez después de gb_game_frame, fundido desde negro.
void sp_UpdateNow (void) {
	gb_oam_commit (gb_cam_x, gb_cam_y);
	if (gb_fade_pending) {
		gb_fade_pending = 0;
		wait_vbl_done ();
		gb_fade_in (0);
	}
}

void saca_a_todo_el_mundo_de_aqui (void) {
	for (gpit = 0; gpit < GB_OAM_USED; gpit ++) gb_spr_off (gpit);
}

void update_this_enemy (void) {
	gb_spr16 (GB_OAM_ENEMS + (gpit << 1), _en_x, _en_y, en_an_next_frame [gpit]);
	en_an_current_frame [gpit] = en_an_next_frame [gpit];
}

void render_sprites (void) {
	gb_camera ();

	// Enemigos

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

	// Jugador (parpadea si le acaban de dar)

	if (!(player.estado & EST_PARP) || !half_life)
		gb_spr16 (GB_OAM_PLAYER, gpx, gpy, player.next_frame);
	else
		gb_spr16 (GB_OAM_PLAYER, gpx, gpy, sprite_18_a);
	player.current_frame = player.next_frame;

	// Balas

	#ifdef PLAYER_CAN_FIRE
		for (gpit = 0; gpit < MAX_BULLETS; gpit ++) {
			if (bullets_estado [gpit] == 1) {
				gb_spr8 (GB_OAM_BULLETS + gpit, bullets_x [gpit], bullets_y [gpit], sprite_19_a);
			} else {
				gb_spr_off (GB_OAM_BULLETS + gpit);
			}
		}
	#endif

	// Cocos

	#ifdef ENABLE_COCOS
		for (gpit = 0; gpit < MAX_COCOS; gpit ++) {
			if (coco_s [gpit]) {
				gb_spr8 (GB_OAM_COCOS + gpit, coco_x [gpit], coco_y [gpit], sprite_19_a);
			} else {
				gb_spr_off (GB_OAM_COCOS + gpit);
			}
		}
	#endif

	// Puño (do_hitter ya ha avanzado su frame: si se acaba de apagar, se quita)

	#ifdef PLAYER_CAN_PUNCH
		if (hitter_on) {
			gb_spr8 (GB_OAM_HITTER, hitter_x, hitter_y, hitter_next_frame);
			hitter_current_frame = hitter_next_frame;
		} else {
			gb_spr_off (GB_OAM_HITTER);
			if (hitter_frame == 5) hitter_frame = 0;
		}
	#endif
}

#ifdef PLAYER_STEP_SOUND
	void step (void) {
	}
#endif
