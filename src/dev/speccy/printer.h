// La Churrera Engine 3.100
// Copyleft 2010-2014 the Mojon Twins

// printer.h
// Miscellaneous printing functions (tiles, status, etc).
unsigned char px, py, pxx, pyy, pt, pt_alt;
unsigned char *pptr, *pptr_alt; 

void blackout (void) {
	// Atributos a 0: tinta y papel negros
	memset ((void *) 22528, 0, 768);
}

#ifdef NO_MASKS
	#define BLIT_TYPE sp_OR_SPRITE
#else
	#define BLIT_TYPE sp_MASK_SPRITE
#endif

void system_init (void) {
	// Install ISR
	
	__asm__ ("di");

	// Interrupciones en modo 2 con la ISR de splib2 en 0xF1F1 y nuestro
	// "hook" ISR: cuenta frames para la sincronía (GAME_FRAME_TICKS) y en 128K
	// además llama al WYZ player.
	sp_InitIM2 ((void *) 0xf1f1);
	sp_CreateGenericISR ((void *) 0xf1f1);
	sp_RegisterHook (255, ISR_HOOK);

	__asm__ ("ei");

	#ifdef MODE_128K
		wyz_init ();
	#endif
	
	// splib2 initialization
	sp_Initialize (7, 0);
	sp_Border (BLACK);
	sp_AddMemory (0, NUMBLOCKS, 14, (void *) AD_FREE);

	joyfunc = sp_JoyKeyboard;

	// Load tileset
	allpurposepuntero = (unsigned char *) tileset;
	gpit = 0; do {
		sp_TileArray (gpit, allpurposepuntero);
		allpurposepuntero += 8;
		gpit ++;
	} while (gpit);

	// Sprite creation
	sp_player = sp_CreateSpr (BLIT_TYPE, 3, sprite_2_a, 1);
	sp_AddColSpr (sp_player, sprite_2_b);
	sp_AddColSpr (sp_player, sprite_2_c);
	player.current_frame = player.next_frame = sprite_2_a;
	
	for (gpit = 0; gpit < 3; gpit ++) {
		sp_moviles [gpit] = sp_CreateSpr(BLIT_TYPE, 3, sprite_9_a, 1);
		sp_AddColSpr (sp_moviles [gpit], sprite_9_b);
		sp_AddColSpr (sp_moviles [gpit], sprite_9_c);	
		en_an_current_frame [gpit] = sprite_9_a;
	}

	#ifdef PLAYER_CAN_FIRE
		for (gpit = 0; gpit < MAX_BULLETS; gpit ++) {
			#ifdef MASKED_BULLETS
				sp_bullets [gpit] = sp_CreateSpr (sp_MASK_SPRITE, 2, sprite_19_a, 1);
			#else		
				sp_bullets [gpit] = sp_CreateSpr (sp_OR_SPRITE, 2, sprite_19_a, 1);
			#endif
			sp_AddColSpr (sp_bullets [gpit], sprite_19_b);
		}
	#endif
}

#ifdef UNPACKED_MAP
	// Draw unpacked tile

	void draw_coloured_tile (unsigned char x, unsigned char y, unsigned char t) {
		px = x; py = y; pt = t;
		pt = 64 + (pt << 2);
		pptr = tileset + 2048 + pt; 
		sp_PrintAtInv (py, px, *pptr ++, pt ++);
		sp_PrintAtInv (py, px + 1, *pptr ++, pt ++);
		sp_PrintAtInv (py + 1, px, *pptr ++, pt ++);
		sp_PrintAtInv (py + 1, px + 1, *pptr, pt);
	}

#else
	// Draw packed tile (with special effects)


	void draw_coloured_tile (unsigned char x, unsigned char y, unsigned char t) {
		px = x; py = y; pt = t;
		
		#ifdef USE_AUTO_SHADOWS
			pxx = (px - VIEWPORT_X) >> 1;
			pyy = (py - VIEWPORT_Y) >> 1;	
			if (attr (pxx, pyy) < 8 && (pt < 16 || pt == 19)) {
				pt = 64 + (pt << 2);
				pptr = (unsigned char *) &tileset [2048 + pt];
				sp_PrintAtInv (py, px, attr (pxx - 1, pyy - 1) == 8 ? (pptr[0] & 7)-1 : pptr [0], pt);
				sp_PrintAtInv (py, px + 1, attr (pxx, pyy - 1) == 8 ? (pptr[1] & 7)-1 : pptr [1], pt + 1);
				sp_PrintAtInv (py + 1, px, attr (pxx - 1, pyy) == 8 ? (pptr[2] & 7)-1 : pptr [2], pt + 2);
				sp_PrintAtInv (py + 1, px + 1, pptr [3], pt + 3);
			} else
		#endif

		#ifdef USE_AUTO_TILE_SHADOWS
			pxx = (px - VIEWPORT_X) >> 1;
			pyy = (py - VIEWPORT_Y) >> 1;	
			if (attr (pxx, pyy) < 4 && (pt < 16 || pt == 19)) {
				if (pt == 19) {
					pt = 140;
					pptr = tileset + 2188; 
					pt_alt = 192;
					pptr_alt = tileset + 2188;
				} else {
					pt = 64 + (pt << 2);
					pptr = tileset + 2048 + pt; 
					pt_alt = pt + 128;
					pptr_alt = pptr + 128;
				}
				
				if (attr (pxx - 1, pyy - 1) >= 4) {
					sp_PrintAtInv (py, px, pptr_alt [0], pt_alt);
				} else {
					sp_PrintAtInv (py, px, pptr [0], pt);
				}

				if (attr (pxx, pyy - 1) >= 4) {
					sp_PrintAtInv (py, px + 1, pptr_alt [1], pt_alt + 1);
				} else {
					sp_PrintAtInv (py, px + 1, pptr [1], pt + 1);
				}

				if (attr (pxx - 1, pyy) >= 4) {
					sp_PrintAtInv (py + 1, px, pptr_alt [2], pt_alt + 2);
				} else {
					sp_PrintAtInv (py + 1, px, pptr [2], pt + 2);
				}

				sp_PrintAtInv (py + 1, px + 1, pptr [3], pt + 3);
			} else
		#endif
		{
			pt = 64 + (pt << 2);
			pptr = tileset + 2048 + pt; //(unsigned char *) &tileset [2048 + pt];
			sp_PrintAtInv (py, px, *pptr ++, pt ++);
			sp_PrintAtInv (py, px + 1, *pptr ++, pt ++);
			sp_PrintAtInv (py + 1, px, *pptr ++, pt ++);
			sp_PrintAtInv (py + 1, px + 1, *pptr, pt);
		}
	}
#endif

// Imprime un número de 0 a 99. Las decenas se cuentan restando, que es más
// rápido que "/ 10" y "% 10" (dos llamadas a la rutina de división).
void print_number2 (unsigned char x, unsigned char y, unsigned char number) {
	pt = 16;
	while (number >= 10) { number -= 10; pt ++; }
	sp_PrintAtInv (y, x, 7, pt);
	sp_PrintAtInv (y, x + 1, 7, 16 + number);
}

void print_str (unsigned char x, unsigned char y, unsigned char c, const unsigned char *s) {
	while (*s)	{
		sp_PrintAtInv (y, x ++, c, (*s ++) - 32);
	}
}

#ifndef DEACTIVATE_OBJECTS
	void draw_objs (void) {
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

void pad_read (void) {
	pad_this_frame = pad1;
	pad1 = pad0 = joyfunc ((struct sp_UDK *) &keys); 

	// Keys held this frame
	pad_this_frame = (~pad_this_frame) | pad1;
}

// Última posición dibujada de cada enemigo (ver update_this_enemy)
unsigned char en_an_last_x [3], en_an_last_y [3];

void saca_a_todo_el_mundo_de_aqui (void) {
	sp_MoveSprAbs (sp_player, SPRITES_CLIP, 0, VIEWPORT_Y + 30, VIEWPORT_X + 20, 0, 0);				
	for (gpit = 0; gpit < 3; gpit ++) {
		sp_MoveSprAbs (sp_moviles [gpit], SPRITES_CLIP, 0, VIEWPORT_Y + 30, VIEWPORT_X + 20, 0, 0);
		en_an_last_y [gpit] = 0xff;		// Fuera de pantalla: obliga a moverlo la próxima vez
	}
	#ifdef PLAYER_CAN_FIRE
		for (gpit = 0; gpit < MAX_BULLETS; gpit ++)
			sp_MoveSprAbs (sp_bullets [gpit], SPRITES_CLIP, 0, 254, 254, 0, 0);	// fuera de la pantalla
	#endif

}

// Mueve el sprite del enemigo gpit a (_en_x, _en_y). Si no ha cambiado de
// posición ni de frame no se llama a sp_MoveSprAbs, que invalidaría sus
// celdas y obligaría a splib2 a repintarlas. Es seguro: splib2 repinta los
// sprites de cualquier celda invalidada por otro motivo (otro sprite, un tile).
void update_this_enemy (void) {
	if (en_an_next_frame [gpit] == en_an_current_frame [gpit] &&
		_en_x == en_an_last_x [gpit] && _en_y == en_an_last_y [gpit]) return;
	en_an_last_x [gpit] = _en_x; en_an_last_y [gpit] = _en_y;
	sp_MoveSprAbs (sp_moviles [gpit], SPRITES_CLIP, en_an_next_frame [gpit] - en_an_current_frame [gpit], VIEWPORT_Y + (_en_y >> 3), VIEWPORT_X + (_en_x >> 3), _en_x & 7, _en_y & 7);
	en_an_current_frame [gpit] = en_an_next_frame [gpit];
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

	if ( !(player.estado & EST_PARP) || !(half_life) )
		sp_MoveSprAbs (sp_player, SPRITES_CLIP, player.next_frame - player.current_frame, VIEWPORT_Y + (gpy >> 3), VIEWPORT_X + (gpx >> 3), gpx & 7, gpy & 7);
	else
		sp_MoveSprAbs (sp_player, SPRITES_CLIP, player.next_frame - player.current_frame, 254, 254, 0, 0);	// fuera de la pantalla

	player.current_frame = player.next_frame;

	// Render bullets

	#ifdef PLAYER_CAN_FIRE
		for (gpit = 0; gpit < MAX_BULLETS; gpit ++) {
			if (bullets_estado [gpit] == 1) {
				sp_MoveSprAbs (sp_bullets [gpit], SPRITES_CLIP, 0, VIEWPORT_Y + (bullets_y [gpit] >> 3), VIEWPORT_X + (bullets_x [gpit] >> 3), bullets_x [gpit] & 7, bullets_y [gpit] & 7);
			} else {
				sp_MoveSprAbs (sp_bullets [gpit], SPRITES_CLIP, 0, 254, 254, 0, 0);	// fuera de la pantalla
			}
		}
	#endif		

}

#ifdef PLAYER_STEP_SOUND
	void step (void) __naked {
		__asm
			ld a, #16
			out (254), a
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			xor #16
			out (254), a
			ret
		__endasm;
	}
#endif

void cortina (void) __naked {
	__asm
		; Antes que nada vamos a limpiar el PAPER de toda la pantalla
		; para que no queden artefactos feos

		ld de, #22528; Apuntamos con DE a la zona de atributos
		ld b, #3; Procesamos 3 tercios
		clearb1:
		push bc

		; Con b = 0, djnz da 256 vueltas.
		ld b, #0; Procesamos los 256 atributos de cada tercio
		clearb2:

		ld a, (de); Nos traemos un atributo
		and #199; Le hacemos la máscara 11000111 y dejamos PAPER a 0
		ld (de), a; Y lo volvemos a poner

		inc de; Siguiente atributo

		djnz clearb2

		pop bc
		djnz clearb1

		;// Y ahora el código original que escribí para UWOL:

		ld a, #8

		repitatodo:
		ld c, a; Salvamos el contador de "repitatodo" en 'c'

		ld hl, #16384
		ld a, #12

		bucle:
		ld b, a; Salvamos el contador de "bucle" en 'b'
		ld a, #255

		bucle1:
		sla (hl)
		inc hl
		dec a
		jr nz, bucle1

		ld a, #255
		bucle2:
		srl (hl)
		inc hl
		dec a
		jr nz, bucle2

		ld a, b; Restituimos el contador de "bucle" a 'a'
		dec a
		jr nz, bucle

		ld a, c; Restituimos el contador de "repitatodo" a 'a'
		dec a
		jr nz, repitatodo
		ret
	__endasm;
}

void espera_activa (int espera) {
	// Espera "espera" frames (1/50 s cada uno, con halt) o hasta que se pulse
	// una tecla.
	do {
		__asm
			halt
		__endasm;
		if (sp_GetKey ()) break;
	} while (--espera);
}

void select_joyfunc (void) {
	#ifndef MODE_128K
		// La música del título (Beepola, speccy/music.s)
		play_title_music ();
	#endif
	
	gpit = 0;
	while (!gpit) {
		gpjt = sp_GetKey ();
		switch (gpjt) {
			case '1':
				gpit = 1;
				joyfunc = sp_JoyKeyboard;
				break;
			case '2':
				gpit = 1;
				joyfunc = (JOYFUNC) sp_JoyKempston;
				break;
			case '3':
				gpit = 1;
				joyfunc = (JOYFUNC) sp_JoySinclair1;
				break;
		}			
	}
	#ifdef MODE_128K
		wyz_play_sound (0);
		sp_WaitForNoKey ();
	#endif
}

void unpack_screen (const unsigned char *src) {
	unpack (src, (unsigned char *)(16384));
}
