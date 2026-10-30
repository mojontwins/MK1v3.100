// La Churrera Engine 3.100
// Copyleft 2010-2014 the Mojon Twins

// Motor.h

// Safe!

// ---------------------------------------------------------------------------
// Funciones generales
// ---------------------------------------------------------------------------

// Índice de la casilla (x, y) en los buffers de la pantalla (15x10 tiles):
// x + 15 * y. El producto sale de una tabla, que es mucho más rápido que
// multiplicar o desplazar en sccz80. Se usa en cada consulta al mapa.
unsigned char mul15 [] = { 0, 15, 30, 45, 60, 75, 90, 105, 120, 135 };
#define bufidx(x, y) ((x) + mul15 [(y)])

// attr: comportamiento del tile (x, y); 0 si está fuera de la pantalla.
// Las coordenadas son sin signo: un valor "negativo" (p.ej. x - 1 con x = 0)
// da la vuelta a 255 y queda fuera del rango, así que bastan dos comparaciones.
// qtile: número del tile (x, y).
// cm_two_points: comportamiento de los puntos (cx1, cy1) y (cx2, cy2) en at1
// y at2, para las colisiones del jugador.

unsigned char attr (unsigned char x, unsigned char y) {
	if (x > 14 || y > 9) return 0;
	return map_attr [bufidx (x, y)];
}

unsigned char qtile (unsigned char x, unsigned char y) {
	return map_buff [bufidx (x, y)];
}

void cm_two_points (void) {
	if (cx1 > 14 || cy1 > 9) at1 = 0;
	else at1 = map_attr [bufidx (cx1, cy1)];

	if (cx2 > 14 || cy2 > 9) at2 = 0;
	else at2 = map_attr [bufidx (cx2, cy2)];
}

unsigned char collide (unsigned char x1, unsigned char y1, unsigned char x2, unsigned char y2) {
	#ifdef SMALL_COLLISION
		return (x1 + 8 >= x2 && x1 <= x2 + 8 && y1 + 8 >= y2 && y1 <= y2 + 8);
	#else
		return (x1 + 13 >= x2 && x1 <= x2 + 13 && y1 + 12 >= y2 && y1 <= y2 + 12);
	#endif
}

unsigned char rand (void) {
	#asm
		.rand16
			ld	hl, _seed
			ld	a, (hl)
			ld	e, a
			inc	hl
			ld	a, (hl)
			ld	d, a
			
			// Ahora DE = [SEED]
						
			ld	a,	d
			ld	h,	e
			ld	l,	253
			or	a
			sbc	hl,	de
			sbc	a, 	0
			sbc	hl,	de
			ld	d, 	0
			sbc	a, 	d
			ld	e,	a
			sbc	hl,	de
			jr	nc,	nextrand
			inc	hl
		.nextrand
			ld	d,	h
			ld	e,	l
			ld	hl, _seed
			ld	a,	e
			ld	(hl), a
			inc	hl
			ld	a,	d
			ld	(hl), a
			
			// Ahora [SEED] = HL
		
			ld  l, e 
			ld  h, 0	
	#endasm
}

unsigned int __FASTCALL__ abs (signed int n) {
	if (n < 0)
		return (unsigned int) (-n);
	else 
		return (unsigned int) n;
}

signed int addsign (signed int n, signed int value) {
	if (n >= 0) return value; else return -value;
}

// ---------------------------------------------------------------------------
// Funciones para la disparasión
// ---------------------------------------------------------------------------

#ifdef BREAKABLE_WALLS
	// break_wall se define más abajo, pero mueve_bullets ya la usa.
	void break_wall (unsigned char x, unsigned char y);
#endif

#ifdef NEEDS_REDRAW_SCR
	void redraw_scr (void);
#endif

#ifdef PLAYER_CAN_FIRE
	void init_bullets (void) {
		// Inicializa las balas
		for (gpit = 0; gpit < MAX_BULLETS; gpit ++)
			bullets_estado [gpit] = 0;
	}

	void fire_bullet (void) {
		#ifdef PLAYER_CAN_FIRE_FLAG 
			if (flags [PLAYER_CAN_FIRE_FLAG] == 0) return;
		#endif

		#ifdef MAX_AMMO
			if (player.ammo == 0) return;
			player.ammo --;
		#endif

		// Buscamos una bala libre
		for (gpit = 0; gpit < MAX_BULLETS; gpit ++) {
			if (bullets_estado [gpit] == 0) {
				bullets_estado [gpit] = 1;
				#ifdef PLAYER_MOGGY_STYLE
					switch (player.facing) {
						case GENITAL_FACING_LEFT:
							bullets_x [gpit] = gpx - 4;
							bullets_mx [gpit] = -PLAYER_BULLET_SPEED;
							bullets_y [gpit] = gpy + PLAYER_BULLET_Y_OFFSET;
							bullets_my [gpit] = 0;
							break;
						case GENITAL_FACING_RIGHT:
							bullets_x [gpit] = gpx + 12;
							bullets_mx [gpit] = PLAYER_BULLET_SPEED;
							bullets_y [gpit] = gpy + PLAYER_BULLET_Y_OFFSET;
							bullets_my [gpit] = 0;
							break;
						case GENITAL_FACING_DOWN:
							bullets_x [gpit] = gpx + PLAYER_BULLET_X_OFFSET;
							bullets_y [gpit] = gpy + 12;
							bullets_my [gpit] = PLAYER_BULLET_SPEED;
							bullets_mx [gpit] = 0;
							break;
						case GENITAL_FACING_UP:
							bullets_x [gpit] = gpx + 8 - PLAYER_BULLET_X_OFFSET;
							bullets_y [gpit] = gpy - 4;
							bullets_my [gpit] = -PLAYER_BULLET_SPEED;
							bullets_mx [gpit] = 0;
							break;
					}
				#else

					#ifdef CAN_FIRE_UP	
						if (!(pad0 & sp_UP)) {
							bullets_y [gpit] = gpy;
							bullets_my [gpit] = -PLAYER_BULLET_SPEED;
						} else if (!(pad0 & sp_DOWN)) {
							bullets_y [gpit] = 8 + gpy;
							bullets_my [gpit] = PLAYER_BULLET_SPEED;	 
						} else
					#endif
					{
						bullets_y [gpit] = gpy + PLAYER_BULLET_Y_OFFSET;
						bullets_my [gpit] = 0;
					}

					#ifdef CAN_FIRE_UP
						if ((pad0 & sp_LEFT) == 0 || (pad0 & sp_RIGHT) == 0 || ((pad0 & sp_UP) && (pad0 & sp_DOWN))) 
					#endif
					{
						if (player.facing == 0) {
							bullets_x [gpit] = gpx - 4;
							bullets_mx [gpit] = -PLAYER_BULLET_SPEED;
						} else {
							bullets_x [gpit] = gpx + 12;
							bullets_mx [gpit] = PLAYER_BULLET_SPEED;
						}
					} 
					#ifdef CAN_FIRE_UP
						else {
							bullets_x [gpit] = gpx + 4;
							bullets_mx [gpit] = 0;
						}
					#endif

				#endif

				PLAY_SFX (6);
				
				#ifdef LIMITED_BULLETS
					#if defined (LB_FRAMES) || !defined (ACTIVATE_SCRIPTING)
						bullets_life [gpit] = LB_FRAMES;
					#else
						bullets_life [gpit] = flags [LB_FRAMES_FLAG];
					#endif
				#endif

				break;
			}
		}
	}

	void mueve_bullets (void) {
		for (gpit = 0; gpit < MAX_BULLETS; gpit ++) {
			if (bullets_estado [gpit]) {			
				if (bullets_mx [gpit]) {
					bullets_x [gpit] += bullets_mx [gpit];								
					if (bullets_x [gpit] > 240) {
						bullets_estado [gpit] = 0;
					}
				} 

				#ifdef BULLETS_MOVE_VERT
					if (bullets_my [gpit]) {
						bullets_y [gpit] += bullets_my [gpit];
						if (bullets_y [gpit] > 160) {
							bullets_estado [gpit] = 0;
						}
					}
				#endif

				rdx = (bullets_x [gpit] + 3) >> 4;
				rdy = (bullets_y [gpit] + 3) >> 4;

				#ifdef BREAKABLE_WALLS			
					if (attr (rdx, rdy) & 16) break_wall (rdx, rdy);
				#endif
				
				if (attr (rdx, rdy) > 7) bullets_estado [gpit] = 0;
				
				#ifdef LIMITED_BULLETS
					if (bullets_life [gpit] > 0) {
						bullets_life [gpit] --;
					} else {
						bullets_estado [gpit] = 0;
					}
				#endif
				
			}	
		}	
	}
#endif

// ---------------------------------------------------------------------------
// Funciones relacionadas con el mapa y las pantallas
// ---------------------------------------------------------------------------

void set_map_tile (unsigned char x, unsigned char y, unsigned char t, unsigned char beh) {
	draw_coloured_tile (VIEWPORT_X + (x << 1), VIEWPORT_Y + (y << 1), t);
	gpit = bufidx (x, y);
	map_attr [gpit] = beh;
	map_buff [gpit] = t;
}

#if !defined COMPRESSED_LEVELS && !defined DEACTIVATE_KEYS
	void init_cerrojos (void) {
		// Activa todos los cerrojos	
		for (gpit = 0; gpit < MAX_CERROJOS; gpit ++)
			cerrojos [gpit].st = 1;	
	}
#endif

#if !defined COMPRESSED_LEVELS
	void init_hotspots (void) {
		// Activa todos los hotspots
		for (gpit = 0; gpit < MAP_W * MAP_H; gpit ++) {
			hotspots [gpit].act = 1;
		}
	}
#endif

void do_hotspots (void) {
	if (collide (gpx, gpy, hotspot_x, hotspot_y)) {

		// Deactivate hotspot
		set_map_tile (hotspot_x >> 4, hotspot_y >> 4, orig_tile, 0);
		gpit = 0;

		#ifdef MSC_RV_F5
			// HOTSPOT (scripts): tipo del objeto (3 si es una recarga de vida)
			#ifndef USE_HOTSPOTS_TYPE_3
				hotspot_t = hotspots [n_pant].act ? hotspots [n_pant].tipo : 3;
			#else
				hotspot_t = hotspots [n_pant].tipo;
			#endif
		#endif

		#ifndef USE_HOTSPOTS_TYPE_3
			// Was it an object, key or life boost?
			if (hotspots [n_pant].act == 0) {
				player.life += PLAYER_REFILL;
				if (player.life > PLAYER_LIFE)
					player.life = PLAYER_LIFE;
				hotspots [n_pant].act = 2;
				PLAY_SFX (9);

			} else 
		#endif

		{					
			switch (hotspots [n_pant].tipo) {
			
				#ifndef DEACTIVATE_OBJECTS						
					case 1:
						#ifdef ONLY_ONE_OBJECT
							if (player.objs == 0) {
								player.objs = 1;
								PLAY_SFX (7);
							} else {
								PLAY_SFX (4);
								set_map_tile (hotspot_x >> 4, hotspot_y >> 4, 17, 0);
								gpit = 1;
							}
						#else
							player.objs ++;
							#ifdef OBJECT_COUNT
								flags [OBJECT_COUNT] = player.objs;
							#endif

							PLAY_SFX (7);

							#ifdef GET_X_MORE
								// Cartel "GET X MORE" con los objetos que faltan.
								if (LEVEL_MAX_OBJS > player.objs) {
									print_str (10, 11, 79, spacer);
									getxmore [5] = '0' + LEVEL_MAX_OBJS - player.objs;
									print_str (10, 12, 79, getxmore);
									print_str (10, 13, 79, spacer);
									sp_UpdateNow ();
									sp_WaitForNoKey ();
									espera_activa (100);
									redraw_scr ();
								}
							#endif	
						#endif
						break;
				#endif

				#ifndef DEACTIVATE_KEYS
					case 2:
						player.keys ++;
						PLAY_SFX (8);
						break;
				#endif

				#ifdef USE_HOTSPOTS_TYPE_3
					case 3:
						player.life += PLAYER_REFILL;
						if (player.life > PLAYER_LIFE) {
							player.life = PLAYER_LIFE;
						}
						PLAY_SFX (9);
						break;
				#endif

				#ifdef MAX_AMMO
					case 4:
						if (MAX_AMMO - player.ammo > AMMO_REFILL) {
							player.ammo += AMMO_REFILL;
						} else { 
							player.ammo = MAX_AMMO;
						}
						PLAY_SFX (7);
						break;
				#endif

				// Recarga de tiempo (si se define TIMER_REFILL).
				#if defined TIMER_ENABLE && defined TIMER_REFILL
					case 5:
						if (99 - ctimer.t > TIMER_REFILL) {
							ctimer.t += TIMER_REFILL;
						} else {
							ctimer.t = 99;
						}
						PLAY_SFX (7);
						break;
				#endif

				#ifdef ENABLE_CHECKPOINTS
					case 6:
						mem_save ();
						PLAY_SFX (2);
						break;						
				#endif
			}

			hotspots [n_pant].act = gpit;
		}

		hotspot_y = 240;

		#ifdef MSC_SECT_PLAYER_GOT_SOMETHING
			msc_run (MSC_PLAYER_GOT_SOMETHING);
		#endif
	}
}

#ifndef DEACTIVATE_KEYS
	void check_and_clear_cerrojo (void) {
		// search & toggle @ rdx, rdy
		if (qtile (rdx, rdy) == 15 && player.keys) {

			// Lo quitamos de la pantalla
			set_map_tile (rdx, rdy, 0, 0);

			// Abrir un cerrojo gasta una llave.
			player.keys --;

			// Buscamos y borramos
			for (gpit = 0; gpit < MAX_CERROJOS; gpit ++) {
				if (cerrojos [gpit].np == n_pant &&
					cerrojos [gpit].x == rdx &&
					cerrojos [gpit].y == rdy
				) {
					cerrojos [gpit].st = 0;
					PLAY_SFX (14);
				}
			}
		}
	}
#endif

#ifdef PLAYER_PUSH_BOXES
	// Origen (x0, y0) y destino (x1, y1) de la caja que se empuja.
	unsigned char x0, y0, x1, y1;

	void move_tile_with_check (void) {
		// Moves to x0, y0 to x1, y1 if x1, y1 is walkable
		// El destino tiene que estar dentro de la pantalla (fuera, attr ()
		// devuelve 0, que parecería un hueco libre).
		if (x1 < 15 && y1 < 10 && (attr (x1, y1) & 8) == 0) {
			#ifdef PUSHED_SCRIPTING
				// Para el script (TILE PUSHED, MOVED_TILE, MOVED_X, MOVED_Y): el
				// tile que tapa la caja y su nueva posición. La sección se
				// ejecuta en el bucle principal, después de move ().
				msc_moved_tile = qtile (x1, y1);
				msc_moved_x = x1;
				msc_moved_y = y1;
				just_pushed = 1;
			#endif
			set_map_tile (x0, y0, 0, 0);
			// La caja conserva el comportamiento del tile 14 (normalmente 10).
			set_map_tile (x1, y1, 14, comportamiento_tiles [14]);
			#ifdef FIRE_TO_PUSH
				// Se ha empujado con FIRE: este frame no se dispara.
				pushed_any = 1;
			#endif
			PLAY_SFX (2);
		}
	}
#endif


void draw_scr_background (void) {

	#ifdef UNPACKED_MAP
		map_pointer = mapa + (n_pant * 150);
	#else
		map_pointer = mapa + (n_pant * 75);
	#endif

	// Inicializamos en RNG
	seed = n_pant;

	// Coordenadas de la pintasión
	rdx = rdy = 0;	

	// Dibujar 150 tiles
	for (gpit = 0; gpit < 150; gpit ++) {	
		#ifdef UNPACKED_MAP
			// Mapa tipo UNPACKED. 1 byte = 1 tile
			rdd = *map_pointer ++;
			rda = comportamiento_tiles [rdd];
		#else
			// Mapa tipo PACKED: 1 byte = 2 tiles

			if (gpit & 1) {
				// Tiles impares del nibble menos significativo
				rdd = rdc & 15;
			} else {
				// Tiles pares del nibble más significativo
				rdc = *map_pointer ++;
				rdd = rdc >> 4;
			}
			rda = comportamiento_tiles [rdd];
			
			#ifndef NO_ALT_TILE
				if (rdd == 0 && (rand () & 15) == 1) rdd = 19;
			#endif
		#endif

		// El tile actual es rdd y su comportamiento es rda

		// Como set_map_tile, pero el índice en el buffer ya es gpit.
		map_attr [gpit] = rda;
		map_buff [gpit] = rdd;
		draw_coloured_tile (VIEWPORT_X + (rdx << 1), VIEWPORT_Y + (rdy << 1), rdd);

		#ifdef BREAKABLE_WALLS
			brk_buff [gpit] = 0;
		#endif		

		#ifdef ENABLE_TILANIMS
			// Detect tilanims
			if (rdd >= ENABLE_TILANIMS) {
				add_tilanim (rdx, rdy, rdd);
			}
		#endif
			
		rdx ++; if (rdx == 15) { rdx = 0; rdy ++; }
	}
	
	// Object setup
	
	hotspot_y = 240;
	
	rdt = hotspots [n_pant].tipo;

	if (hotspots [n_pant].act != 1) {
		rdt = 0;
		#ifndef USE_HOTSPOTS_TYPE_3
			// Vieja lógica: si el hotspot no está activo y no era 0, puede aparecer una recarga.
			if ((rand () & 3) == 2) rdt = 3;
		#endif
	}

	if (rdt) {
		hotspot_x = hotspots [n_pant].xy;
		rdx = hotspot_x >> 4;
		rdy = hotspot_x & 15;
		hotspot_x &= 0xf0;
		hotspot_y = rdy << 4;
		orig_tile = map_buff [bufidx (rdx, rdy)];
		set_map_tile (rdx, rdy, 16 + (rdt == 3 ? 0 : rdt), 0);
	}

	// Open locks

	#ifndef DEACTIVATE_KEYS
		for (gpit = 0; gpit < MAX_CERROJOS; gpit ++) {
			if (cerrojos [gpit].np == n_pant && cerrojos [gpit].st == 0) {
				set_map_tile (cerrojos [gpit].x, cerrojos [gpit].y, 0, 0);
			}
		}
	#endif
}

#ifdef NEEDS_REDRAW_SCR
	// Repinta la pantalla actual desde map_buff, sin reiniciar nada: los muros
	// rotos, las cajas empujadas y los objetos cogidos se quedan como están, y
	// no se vuelven a ejecutar los scripts de entrada. Lo usan la pausa y
	// GET_X_MORE.
	void redraw_scr (void) {
		rdx = rdy = 0;
		for (gpit = 0; gpit < 150; gpit ++) {
			draw_coloured_tile (VIEWPORT_X + (rdx << 1), VIEWPORT_Y + (rdy << 1), map_buff [gpit]);
			rdx ++; if (rdx == 15) { rdx = 0; rdy ++; }
		}
	}
#endif

void draw_scr (void) {
	#ifdef ENABLE_TILANIMS
		max_tilanims = 0; 		// Reset animated tiles
	#endif

	#ifdef FIRE_ZONE
		f_zone_ac = 0; 			// La zona de fuego es de cada pantalla
	#endif	

	// Pintamos el fondo

	draw_scr_background ();
	
	// Movemos y cambiamos a los enemigos según el tipo que tengan

	enoffs = n_pant * 3;

	for (gpit = 0; gpit < 3; gpit ++) {
		// Índice del enemigo en el array malotes.
		enoffsmasi = enoffs + gpit;

		en_an_frame [gpit] = 0;
		en_an_count [gpit] = 3;
		en_an_state [gpit] = 0;

		#ifdef ENABLE_RANDOM_RESPAWN
			en_an_fanty_activo [gpit] = 0;
		#endif

		// Back to life!

		#ifdef RESPAWN_ON_ENTER
			malotes [enoffsmasi].t &= ~16;

			#ifdef MALOTE_HAS_LIFE
				malotes [enoffsmasi].life = LEVEL_ENEMS_LIFE;
			#endif
		#endif

		switch (malotes [enoffsmasi].t) {
			case 1:
			case 2:
			case 3:
			case 4:
				en_an_base_frame [gpit] = (malotes [enoffsmasi].t - 1) << 1;
				break;

			#ifdef ENABLE_RANDOM_RESPAWN
				case 5: 
					en_an_base_frame [gpit] = 4;
					break;
			#endif

			#ifdef ENABLE_CUSTOM_TYPE_6
				case 6:
					// Añade aquí tu código custom. Esto es un ejemplo:
					en_an_base_frame [gpit] = TYPE_6_FIXED_SPRITE << 1;
					SET_FIXED_PIX (en_an_x [gpit], malotes [enoffsmasi].x);
					SET_FIXED_PIX (en_an_y [gpit], malotes [enoffsmasi].y);
					en_an_vx [gpit] = en_an_vy [gpit] = 0;
					en_an_state [gpit] = TYPE_6_IDLE;				
					break;				
			#endif

			#ifdef ENABLE_PURSUERS
				case 7:
					en_an_alive [gpit] = 0;
					en_an_dead_row [gpit] = 0;//DEATH_COUNT_EXPRESSION;
					break;
			#endif

			default:
				en_an_next_frame [gpit] = sprite_18_a;
		}
	}
	
	// Scripting

	#ifdef ACTIVATE_SCRIPTING
		#ifdef LINE_OF_TEXT
			print_str (LINE_OF_TEXT_X, LINE_OF_TEXT, LINE_OF_TEXT_ATTR, "                              ");
		#endif
		#ifdef MSC_RV_F0
			hide_hotspots = 0;
		#endif
		#ifdef MSC_RV_EF
			dont_make_fanties = 0;
		#endif

		// Scripts de entrar en pantalla: ENTERING ANY y ENTERING SCREEN n_pant
		msc_run_screen (MSC_ENTERING_ANY);

		#ifdef MSC_RV_F0
			// El script puede esconder el objeto de esta pantalla
			if (hide_hotspots && hotspot_y < 240) {
				set_map_tile (hotspot_x >> 4, hotspot_y >> 4, orig_tile, 0);
				hotspot_y = 240;
			}
		#endif
	#endif

	// Inicializamos las balas.

	#ifdef PLAYER_CAN_FIRE
		init_bullets ();
	#endif	
}

#ifdef BREAKABLE_WALLS
	void break_wall (unsigned char x, unsigned char y) {
		gpaux = bufidx (x, y);
		if (brk_buff [gpaux] < BREAKABLE_WALLS_LIFE) {
			brk_buff [gpaux] ++;
			gpaux = 1;
		} else {
			map_attr [gpaux] = 0;
			map_buff [gpaux] = 0;
			set_map_tile (x, y, 0, 0);
			gpaux = 0;
			#ifdef MSC_SECT_TILE_DESTROYED
				msc_run_at (MSC_TILE_DESTROYED, x, y);
			#endif
		}
		PLAY_SFX (gpaux);
		
	}
#endif

// ---------------------------------------------------------------------------
// Funciones del player
// ---------------------------------------------------------------------------

void set_player_at (unsigned char x, unsigned char y) {
	gpx = x; gpy = y;
	SET_FIXED_PIX (player.x, x);
	SET_FIXED_PIX (player.y, y);
}

void init_player (void) {
	// Inicializa player con los valores iniciales
	// (de ahí lo de inicializar).
	
	// Posición inicial: de la cabecera del nivel o de config.h.
	set_player_at (LEVEL_INI_X << 4, LEVEL_INI_Y << 4);

	player.vy = 		0;
	player.vx = 		0;
	player.cont_salto = 1;
	player.saltando = 	0;
	player.frame = 		0;
	player.subframe = 	0;

	#ifdef PLAYER_MOGGY_STYLE
		player.facing = GENITAL_FACING_DOWN;
		player.facing_v = player.facing_h = 0xff;
	#else
		player.facing = 	0;
	#endif	

	player.estado = 	EST_NORMAL;
	player.ct_estado = 	0;

	#ifdef REFILL_LIFE_ON_LEVEL	
		player.life = 		PLAYER_LIFE;
	#endif
	
	player.objs =		0;
	player.keys = 		0;
	player.killed = 	0;
	player.disparando = 0;

	#ifdef MAX_AMMO
		#ifdef INITIAL_AMMO
			player.ammo = INITIAL_AMMO;
		#else
			player.ammo = MAX_AMMO;
		#endif
	#endif	

	pant_final = LEVEL_SCR_FIN;

	#ifdef TIMER_ENABLE
		ctimer.count = 0;
		ctimer.zero = 0;
		#ifdef TIMER_LAPSE
			ctimer.frames = TIMER_LAPSE;
		#endif
		#ifdef TIMER_INITIAL
			ctimer.t = TIMER_INITIAL;
		#endif
		#ifdef TIMER_START
			ctimer.on = 1;
		#else
			ctimer.on = 0;
		#endif
	#endif
}

void kill_player (unsigned char sound) {
	if (player.life == 0) return;
	player.life --;
	PLAY_SFX (sound);
	#ifdef CP_RESET_WHEN_DYING
		// Vuelve al último checkpoint, si se ha tocado alguno.
		if (sg_saved) {
			#ifdef CP_RESET_ALSO_FLAGS
				mem_load ();
			#else
				n_pant = sg_pool [SG_NFLAGS];
				SET_FIXED_PIX (player.x, sg_pool [SG_NFLAGS + 1] << 4);
				SET_FIXED_PIX (player.y, sg_pool [SG_NFLAGS + 2] << 4);
			#endif
			player.vx = player.vy = 0;
		}
	#endif
}

#ifdef ENABLE_RANDOM_RESPAWN
	char player_hidden (void) {
		if ( (gpy & 15) == 0 && player.vx == 0 ) {
			return attr ((gpx + 8) >> 4, (gpy + 8) >> 4) & 2;
		}			
		return 0;
	}
#endif

#ifdef CHECK_LOCKS_OR_BOXES
	void check_lock_or_box_horz (void) {
		rdx = cx1; rdy = (gpy + 8) >> 4;
		rda = qtile (rdx, rdy);

		#if defined PLAYER_PUSH_BOXES
			if (rda == 14) {
				x0 = rdx; y0 = y1 = rdy;
				if (player.vx > 0) {
					x1 = x0 + 1;
				} else {
					x1 = x0 - 1;
				}

				// Con FIRE_TO_PUSH solo se empuja si se pulsa FIRE.
				#ifdef FIRE_TO_PUSH
					if ((pad0 & sp_FIRE) == 0)
				#endif
				move_tile_with_check ();
			}
		#endif

		#if !defined DEACTIVATE_KEYS
			if (rda == 15) {
				check_and_clear_cerrojo ();
			}
		#endif
	}

	void check_lock_or_box_vert (void) {
		rdx = (gpx + 8) >> 4; rdy = cy1;
		rda = qtile (rdx, rdy);

		#ifdef PUSH_BOXES_VERT
			if (rda == 14) {
				x0 = x1 = rdx; y0 = rdy;
				if (player.vy > 0) {
					y1 = y0 + 1;
				} else {
					y1 = y0 - 1;
				}

				#ifdef FIRE_TO_PUSH
					if ((pad0 & sp_FIRE) == 0)
				#endif
				move_tile_with_check ();
			}
		#endif

		#if !defined DEACTIVATE_KEYS
			if (rda == 15) {
				check_and_clear_cerrojo ();
			}
		#endif
	}
#endif

// Mueve al jugador: lee el mando, aplica la física y las colisiones con el
// escenario y elige el frame de animación.
void move (void) {
	
	pad_read ();			// Leemos el controlador seleccionado.

	// pushed_any se pone a 1 si se empuja algo durante las colisiones; el
	// disparo lo consulta más abajo.
	#ifdef FIRE_TO_PUSH
		pushed_any = 0;
	#endif
	
	// ---------------------------------------------------------------------------
	// EJE VERTICAL
	// ---------------------------------------------------------------------------

	// Vista genital

	#ifdef PLAYER_MOGGY_STYLE
		// La pulsación de las direcciones acelera. Si no se pulsa nada, se decelera.

		//if ( ! ((pad0 & sp_UP) == 0 || (pad0 & sp_DOWN) == 0)) {
		if ( (pad0 & sp_UP) && (pad0 & sp_DOWN) ) {
			player.facing_v = 0xff;		// Señal de que no pulsamos una dirección vertical
			if (player.vy > 0) {
				player.vy -= PLAYER_RX;
				if (player.vy < 0) player.vy = 0;
			} else if (player.vy < 0) {
				player.vy += PLAYER_RX;
				if (player.vy > 0) player.vy = 0;
			}
		} else {

			if ((pad0 & sp_UP) == 0) {
				player.facing_v = GENITAL_FACING_UP;
				player.vy -= PLAYER_AX;
				if (player.vy < -PLAYER_MAX_VX) {
					player.vy = -PLAYER_MAX_VX;
				}
			}

			if ((pad0 & sp_DOWN) == 0) {
				player.facing_v = GENITAL_FACING_DOWN;
				player.vy += PLAYER_AX;
				if (player.vy > PLAYER_MAX_VX) {
					player.vy = PLAYER_MAX_VX;
				}
			}
		}

	#else
		// Vista lateral

		// Gravedad

		player.vy += PLAYER_G;
		if (player.vy > PLAYER_MAX_VY_CAYENDO) player.vy = PLAYER_MAX_VY_CAYENDO;

		// Salto

		#ifdef PLAYER_HAS_JUMP
		
			// Inicio del salto

			if (
				#ifdef JUMP_ON_UP
					(pad0 & sp_UP) == 0
				#elif defined JUMP_ON_KEY
					sp_KeyPressed (key_jump)
				#else
					(pad0 & sp_FIRE) == 0
				#endif
				&& (possee || player.gotten || hit_v)
				#ifndef PLAYER_CUMULATIVE_JUMP
					&& player.saltando == 0
				#endif
			) {
				#ifdef PLAYER_CUMULATIVE_JUMP
					player.vy = -player.vy - PLAYER_VY_INICIAL_SALTO;
					if (player.vy < -PLAYER_MAX_VY_SALTANDO) player.vy = -PLAYER_MAX_VY_SALTANDO;
				#endif

				player.saltando = 1;
				player.cont_salto = 0;
				PLAY_SFX (3);
			}

			// Continuación del salto

			#ifndef PLAYER_CUMULATIVE_JUMP	
				if (
					#ifdef JUMP_ON_UP
						(pad0 & sp_UP) == 0 
					#elif defined JUMP_ON_KEY
						sp_KeyPressed (key_jump)
					#else
						(pad0 & sp_FIRE) == 0 
					#endif
					&& player.saltando
				) {
					player.vy -= (PLAYER_VY_INICIAL_SALTO + PLAYER_INCR_SALTO - (player.cont_salto << 1));
					if (player.vy < -PLAYER_MAX_VY_SALTANDO) player.vy = -PLAYER_MAX_VY_SALTANDO;
					player.cont_salto ++;
					if (player.cont_salto == 8)
						player.saltando = 0;
				}
			#endif

			// Interrupción del salto

			if (
				#ifdef JUMP_ON_UP
					(pad0 & sp_UP)
				#elif defined JUMP_ON_KEY
					!sp_KeyPressed (key_jump)
				#else
					(pad0 & sp_FIRE)
				#endif
			) player.saltando = 0;

		#endif

		// Bootee engine

		#ifdef PLAYER_BOOTEE
			if ( player.saltando == 0 && (possee || player.gotten || hit_v) ) {
				player.saltando = 1;
				player.cont_salto = 0;
				if (hit == 0) PLAY_SFX (3);
			}
			
			if (player.saltando ) {
				player.vy -= (PLAYER_VY_INICIAL_SALTO + PLAYER_INCR_SALTO - (player.cont_salto << 1));
				if (player.vy < -PLAYER_MAX_VY_SALTANDO) player.vy = -PLAYER_MAX_VY_SALTANDO;
				player.cont_salto ++;
				if (player.cont_salto == 8)
					player.saltando = 0;
			}

			if ((pad0 & sp_DOWN) == 0) {
				if (player.vy < -PLAYER_BOOTEE_CROUCH) player.vy = -PLAYER_BOOTEE_CROUCH;
				player.crouch = 1;
			} else player.crouch = 0;
		#endif	

		// Jetpac

		#ifdef PLAYER_HAS_JETPAC
			// Si pulsamos arriba se decrementa la velocidad hasta un límite

			if ((pad0 & sp_UP) == 0) {
				player.vy -= PLAYER_INCR_JETPAC;
				if (player.vy < -PLAYER_MAX_VY_JETPAC) player.vy = -PLAYER_MAX_VY_JETPAC;
			}
		#endif

	#endif

	player.y += player.vy;
	FIXED_CLAMP (player.y, FIXED_MAX_Y);

	// Convertimos a pixel
	gpy = FIXED_PIX (player.y);

	// Reiniciamos las banderas de "sobre plataforma" y "colisión matadora vertical"
	possee = 0; hit_v = 0;

	// Colisión vertical

	rds = player.vy + ptgmy;
	if (rds) {
		
		// Las coordenadas de los tiles que tendremos que revisar cambian según
		// el tipo de colisión y la dirección

		#ifdef BOUNDING_BOX_8_BOTTOM
			cx1 = (gpx + 4) >> 4; cx2 = (gpx + 11) >> 4;
		#elif defined BOUNDING_BOX_8_CENTERED
			cx1 = (gpx + 4) >> 4; cx2 = (gpx + 11) >> 4;
		#else
			cx1 = gpx >> 4; cx2 = (gpx + 15) >> 4;
		#endif

		if (rds < 0) { 			// Estamos ascendiendo

			// Dependiendo del tipo de colisión, las comprobaciones son diferentes:
			#ifdef BOUNDING_BOX_8_BOTTOM
				cy1 = cy2 = (gpy + 8) >> 4;
			#elif defined BOUNDING_BOX_8_CENTERED
				cy1 = cy2 = (gpy + 4) >> 4;
			#else
				cy1 = cy2 = gpy >> 4;
			#endif

			// Calculamos la colisión en esos dos puntos cx1,cy1 y cx2, cy2
			cm_two_points ();

			// Si topamos con obstáculo hay que parar y sacar al sprite del obstáculo.
			if ((at1 & 8) || (at2 & 8)) {

				// Como hemos colisionado, vemos si hay una caja que empujar o un cerrojo que abrir
				#ifdef CHECK_LOCKS_OR_BOXES_VERT
					check_lock_or_box_vert ();
				#endif

				#ifdef PLAYER_BOUNCE_WITH_WALLS
					player.vy = -(player.vy / 2);
				#else
					player.vy = 0;
				#endif

				// ajustamos
				#ifdef BOUNDING_BOX_8_BOTTOM
					gpy = (gpy & 0xf0) + 8;
				#elif defined BOUNDING_BOX_8_CENTERED
					gpy = (gpy & 0xf0) + 12;
				#else
					gpy = (gpy & 0xf0) + 16;
				#endif

				SET_FIXED_PIX (player.y, gpy);
			}
		} else if (rds > 0) {		// Estamos descendiendo

			// Dependiendo del tipo de colisión, las comprobaciones son diferentes:
			#ifdef BOUNDING_BOX_8_BOTTOM
				cy1 = cy2 = (gpy + 15) >> 4;
			#elif defined BOUNDING_BOX_8_CENTERED
				cy1 = cy2 = (gpy + 11) >> 4;
			#else
				cy1 = cy2 = (gpy + 15) >> 4;
			#endif

			// Calculamos la colisión en esos dos puntos cx1,cy1 y cx2, cy2
			cm_two_points ();

			// Si topamos con obstáculo hay que parar y sacar al sprite del obstáculo.
			if (
				#if defined PLAYER_MOGGY_STYLE || defined SIMPLE_PLATFORMS
					(at1 & 12) || (at2 & 12)
				#else
					((at1 & 8) || (at2 & 8) || (((gpy - 1) & 15) < 8 && ((at1 & 4) || (at2 & 4))))
				#endif
			) {

				// Como hemos colisionado, vemos si hay una caja que empujar o un cerrojo que abrir
				#ifdef CHECK_LOCKS_OR_BOXES_VERT
					check_lock_or_box_vert ();
				#endif

				#ifdef PLAYER_CUMULATIVE_JUMP
					if (!player.saltando)
				#endif
				{
					#ifdef PLAYER_BOUNCE_WITH_WALLS
						player.vy = -(player.vy / 2);
					#else
						player.vy = 0;
					#endif
				}

				// ajustamos
				#ifdef BOUNDING_BOX_8_BOTTOM
					gpy = (gpy & 0xf0);
				#elif defined BOUNDING_BOX_8_CENTERED
					gpy = (gpy & 0xf0) + 4;
				#else
					gpy = (gpy & 0xf0);
				#endif

				SET_FIXED_PIX (player.y, gpy);
				possee = 1;
			}
		}

		if ((at1 & 1) || (at2 & 1)) {
			hit_v = 1;
		}

		// Cuando la gravedad es menor de 64, habrá un frame en el que no hay colisión,
		// por lo que hay que detectar que estamos posados de forma explícita
		#if !defined PLAYER_MOGGY_STYLE && PLAYER_G < 256
			cy1 = cy2 = (gpy + 16) >> 4;
			cm_two_points ();
			possee = (at1 & 12) || (at2 & 12);
		#endif
	}

	// ---------------------------------------------------------------------------
	// EJE HORIZONTAL
	// ---------------------------------------------------------------------------

	if ((pad0 & sp_LEFT) && (pad0 & sp_RIGHT)) {
		#ifdef PLAYER_MOGGY_STYLE		
			player.facing_h = 0xff;
		#endif
		
		if (player.vx > 0) {
			player.vx -= PLAYER_RX;
			if (player.vx < 0) player.vx = 0;
		} else if (player.vx < 0) {
			player.vx += PLAYER_RX;
			if (player.vx > 0) player.vx = 0;
		}
	} else {
		if ((pad0 & sp_LEFT) == 0) {
			#ifdef PLAYER_MOGGY_STYLE
				player.facing_h = GENITAL_FACING_LEFT;
			#else
				player.facing = LATERAL_FACING_LEFT;
			#endif
			player.vx -= PLAYER_AX;
			if (player.vx < -PLAYER_MAX_VX) {
				player.vx = -PLAYER_MAX_VX;
			}
		}

		if ((pad0 & sp_RIGHT) == 0) {
			#ifdef PLAYER_MOGGY_STYLE	
				player.facing_h = GENITAL_FACING_RIGHT;
			#else
				player.facing = LATERAL_FACING_RIGHT;
			#endif
			player.vx += PLAYER_AX;
			if (player.vx > PLAYER_MAX_VX) {
				player.vx = PLAYER_MAX_VX;
			}
		}
	}

	player.x += player.vx;
	#ifndef PLAYER_MOGGY_STYLE
		player.x += ptgmx;
	#endif
	
	FIXED_CLAMP (player.x, FIXED_MAX_X);

	// Convertimos a pixel
	gpx = FIXED_PIX (player.x);

	// Colisión

	hit_h = 0;
	rds = player.vx + ptgmx;
	if (rds) {
		
		#ifdef BOUNDING_BOX_8_BOTTOM
				cy1 = (gpy + 8) >> 4; cy2 = (gpy + 15) >> 4;
		#elif defined BOUNDING_BOX_8_CENTERED
				cy1 = (gpy + 4) >> 4; cy2 = (gpy + 11) >> 4;
		#else
				cy1 = gpy >> 4; cy2 = (gpy + 15) >> 4;
		#endif

		if (rds < 0) {			// Hacia la izquierda

			// Dependiendo del tipo de colisión, las comprobaciones son diferentes
			#ifdef BOUNDING_BOX_8_BOTTOM
				cx1 = cx2 = (gpx + 4) >> 4;
			#elif defined BOUNDING_BOX_8_CENTERED
				cx1 = cx2 = (gpx + 4) >> 4;
			#else
				cx1 = cx2 = gpx >> 4;
			#endif

			// Calculamos la colisión en esos dos puntos cx1,cy1 y cx2, cy2
			cm_two_points ();

			// Si topamos con obstáculo hay que parar y sacar al sprite del obstáculo.
			if ((at1 & 8) || (at2 & 8)) {

				// Como hemos colisionado, vemos si hay una caja que empujar o un cerrojo que abrir
				#ifdef CHECK_LOCKS_OR_BOXES
					check_lock_or_box_horz ();
				#endif

				#ifdef PLAYER_BOUNCE_WITH_WALLS
					player.vx = -(player.vx / 2);
				#else
					player.vx = 0;
				#endif
				
				// ajustamos
				#ifdef BOUNDING_BOX_8_BOTTOM
					gpx = (gpx & 0xf0) + 12;
				#elif defined BOUNDING_BOX_8_CENTERED
					gpx = (gpx & 0xf0) + 12;
				#else
					gpx = (gpx & 0xf0) + 16;
				#endif

				SET_FIXED_PIX (player.x, gpx);
			}

		} else if (rds > 0) { 	// Hacia la derecha

			// Dependiendo del tipo de colisión, las comprobaciones son diferentes
			// Nótese que detectamos un pixel antes de tiempo. Esto es necesario por cómo
			// funciona el punto fijo.
			#ifdef BOUNDING_BOX_8_BOTTOM
				cx1 = cx2 = (gpx + 12) >> 4;
			#elif defined BOUNDING_BOX_8_CENTERED
				cx1 = cx2 = (gpx + 12) >> 4;
			#else
				cx1 = cx2 = gpx >> 4;
			#endif

			// Calculamos la colisión en esos dos puntos cx1,cy1 y cx2, cy2
			cm_two_points ();

			// Si topamos con obstáculo hay que parar y sacar al sprite del obstáculo.
			if ((at1 & 8) || (at2 & 8)) {

				// Como hemos colisionado, vemos si hay una caja que empujar o un cerrojo que abrir
				#ifdef CHECK_LOCKS_OR_BOXES
					check_lock_or_box_horz ();
				#endif

				#ifdef PLAYER_BOUNCE_WITH_WALLS
					player.vx = -(player.vx / 2);
				#else
					player.vx = 0;
				#endif
				
				// ajustamos
				#ifdef BOUNDING_BOX_8_BOTTOM
					gpx = (gpx & 0xf0) + 4;
				#elif defined BOUNDING_BOX_8_CENTERED
					gpx = (gpx & 0xf0) + 4;
				#else
					gpx = (gpx & 0xf0);
				#endif

				SET_FIXED_PIX (player.x, gpx);
			}

		}

		if ((at1 & 1) || (at2 & 1)) {
			hit_h = 1;
		}

	}

	// En vista genital hay una prioridad entre vertical y horizontal
	// para decidir adónde mira el muñeco

	#ifdef PLAYER_MOGGY_STYLE
		#ifdef TOP_OVER_SIDE
			if (player.facing_v != 0xff) {
				player.facing = player.facing_v;
			} else if (player.facing_h != 0xff) {
				player.facing = player.facing_h;
			}
		#else
			if (player.facing_h != 0xff) {
				player.facing = player.facing_h;
			} else if (player.facing_v != 0xff) {
				player.facing = player.facing_v;
			}
		#endif	
	#endif

	// pushed_any (FIRE_TO_PUSH) dice si se empujó algo en este frame, para no
	// disparar a la vez. Ahora se pone a 0 al principio de move ().

	// Disparos

	#ifdef PLAYER_CAN_FIRE
		if (
			player.disparando == 0
			#ifdef USE_TWO_BUTTONS
				&& ((pad0 & sp_FIRE) == 0 || sp_KeyPressed (key_fire))
			#else
				&& (pad0 & sp_FIRE) == 0
			#endif
			#ifdef FIRE_TO_PUSH
				&& pushed_any == 0
			#endif
		) {
			player.disparando = 1;
			fire_bullet ();
		}

		if ((pad0 & sp_FIRE)) player.disparando = 0;
	#endif

	// Tiles que te matan. 

	#ifndef DEACTIVATE_EVIL_TILE
		// hit_v tiene preferencia sobre hit_h
		hit = 0;
		if (hit_v) {
			hit = 1;
			#ifndef PLAYER_MOGGY_STYLE
				if (player.vy < 0 && player.cont_salto > 1) 
			#endif
			{
				#ifdef FULL_BOUNCE
					player.vy = addsign (-player.vy, PLAYER_MAX_VX);
				#else
					player.vy = -player.vy;
				#endif
			}
		} else if (hit_h) {
			hit = 1;
			#ifdef FULL_BOUNCE
				player.vx = addsign (-player.vx, PLAYER_MAX_VX);
			#else
				player.vx = -player.vx;
			#endif
		}

		if (hit) {
			#ifdef PLAYER_FLICKERS
				if (player.estado == EST_NORMAL)
			#endif
			{
				#ifdef PLAYER_FLICKERS
					player.estado = EST_PARP;
					player.ct_estado = 50;
				#endif		
				kill_player(10);

			}
		}
	#endif

	// Select animation frame 
		
	#ifndef PLAYER_MOGGY_STYLE
		#ifdef PLAYER_BOOTEE
			if (player.crouch) {
				gpit = player.facing + 3;
			} else if (player.vy == 0) {
				gpit = player.facing;
			} else if (player.vy < 0) {
				gpit = player.facing + 1;
			} else {
				gpit = player.facing + 2;
			}
			player.next_frame = player_frames [gpit];
		#else	
			if (!possee && !player.gotten) {
				player.next_frame = player_frames [player.facing == LATERAL_FACING_RIGHT ? 8 : 9];
			} else {
				if (player.vx == 0) {
					#ifdef PLAYER_ALTERNATE_ANIMATION
						player.next_frame = player_frames [player.facing];
					#else
						player.next_frame = player_frames [player.facing + 1];
					#endif
				} else {
					player.subframe ++;
					if (player.subframe == 4) {
						player.subframe = 0;
						#ifdef PLAYER_ALTERNATE_ANIMATION
							player.frame ++; if (player.frame == 3) player.frame = 0;
						#else
							player.frame = (player.frame + 1) & 3;
						#endif
						#ifdef PLAYER_STEP_SOUND
							step ();
						#endif
					}
					player.next_frame = player_frames [player.facing + player.frame];
				}
			}
		#endif
	#else
		
		if (player.vx || player.vy) {
			player.subframe ++;
			if (player.subframe == 4) {
				player.subframe = 0;
				player.frame = !player.frame;
				#ifdef PLAYER_STEP_SOUND			
					step (); 
				#endif
			}
		}
		
		player.next_frame = player_frames [player.facing + player.frame];
	#endif
}

// ---------------------------------------------------------------------------
// Funciones sobre niveles comprimidos:
// ---------------------------------------------------------------------------

#ifdef NEEDS_CLEAR_GAMEAREA
	void clear_gamearea_tiles (void) {
		for (gpit = 0; gpit < 10; gpit ++) {
			for (gpjt = 0; gpjt < 15; gpjt ++) {
				draw_coloured_tile (VIEWPORT_X + (gpjt<<1), VIEWPORT_Y + (gpit<<1), 47);
			}
		}
	}
#endif

#ifdef COMPRESSED_LEVELS
	// Carga el nivel "level": el bundle (datos de juego) en level_data y, si
	// el nivel los define, su tileset y su spriteset encima de los actuales.
	void prepare_level (void) {
		get_resource (levels [level].bundle, (unsigned int) (level_data));

		if (levels [level].tileset != NO_RESOURCE)
			get_resource (levels [level].tileset, (unsigned int) (tileset));

		if (levels [level].spriteset != NO_RESOURCE)
			get_resource (levels [level].spriteset, (unsigned int) (sprite_1_a - 16));

		#ifdef ACTIVATE_SCRIPTING
			// El script del nivel. Sin script, un índice vacío (todo 0).
			if (levels [level].script != NO_RESOURCE) {
				get_resource (levels [level].script, (unsigned int) (msc_buffer));
			} else {
				for (gpit = 0; gpit < 32; gpit ++) msc_buffer [gpit] = 0;
			}
		#endif
	}
#endif

// ---------------------------------------------------------------------------
// Funciones de los bicharracos
// ---------------------------------------------------------------------------

// Al empezar: resucita a todos los enemigos y les devuelve la vida.
#ifdef NEEDS_INIT_MALOTES
	void init_malotes (void) {
		for (gpit = 0; gpit < MAP_W * MAP_H * 3; gpit ++) {
			// Clear bit 4
			malotes [gpit].t &= ~16;

			// Restore life
			#ifdef MALOTE_HAS_LIFE
				malotes [gpit].life = LEVEL_ENEMS_LIFE;
			#endif

			// Autokill type 5s for RANDOM RESPAWN (legacy leftout)
			#ifdef ENABLE_RANDOM_RESPAWN
				if (malotes [gpit].t == 5) malotes [gpit].t |= 16;
			#endif
		}
	}
#endif

// Funciones auxiliares custom

#ifdef WALLS_STOP_ENEMIES
	// ¿Choca el enemigo actual (_en_*) con el escenario al moverse en x / en y?
	unsigned char mons_col_sc_x (void) {
		gpaux = gpen_xx + (_en_mx > 0);
		#ifdef EVERYTHING_IS_A_WALL
			return (attr (gpaux, gpen_yy) || ((_en_y & 15) && attr (gpaux, gpen_yy + 1)));
		#else
			return ((attr (gpaux, gpen_yy) & 8) || ((_en_y & 15) && (attr (gpaux, gpen_yy + 1) & 8)));
		#endif
	}

	unsigned char mons_col_sc_y (void) {
		gpaux = gpen_yy + (_en_my > 0);
		#ifdef EVERYTHING_IS_A_WALL
			return (attr (gpen_xx, gpaux) || ((_en_x & 15) && attr (gpen_xx + 1, gpaux)));
		#else
			return ((attr (gpen_xx, gpaux) & 8) || ((_en_x & 15) && (attr (gpen_xx + 1, gpaux) & 8)));
		#endif
	}
#endif

#ifdef ENABLE_CUSTOM_TYPE_6
	unsigned char distance (unsigned char x1, unsigned char y1, unsigned char x2, unsigned char y2) {
		rdx = abs (x2 - x1);
		rdy = abs (y2 - y1);
		rda = rdx < rdy ? rdx : rdy;
		return (rdx + rdy - (rda >> 1) - (rda >> 2) + (rda >> 4));
	}
#endif

#ifdef ENEMS_HAVE_FREE_COORDS
	int limit (int val, int min, int max) {
		if (val < min) return min;
		if (val > max) return max;
		return val;
	}
#endif

#ifndef PLAYER_MOGGY_STYLE
	void platform_get_player (void) {
		player.gotten = 1;
		gpy = _en_y - 16;
		SET_FIXED_PIX (player.y, gpy);
		#ifdef PLAYER_CUMULATIVE_JUMP
			if (player.saltando == 0)
		#endif
		player.vy = 0;
		// Arrastre vertical de la plataforma
		ptgmy = _en_my << 8;
	}
#endif

// El enemigo actual (gpit, _en_t) muere: explosión durante 8 frames y se
// marca como muerto (t |= 16). Los fanties desaparecen y los perseguidores
// reaparecen al cabo de un rato. La usan el pisotón y los disparos.
#ifdef ENEMIES_CAN_DIE
void enemy_dies (void) {
	en_an_next_frame [gpit] = sprite_17_a;		// Explosión
	en_an_state [gpit] = GENERAL_DYING;
	en_an_count [gpit] = 8;
	player.killed ++;

	#ifdef MSC_SECT_PLAYER_KILLS_ENEMY
		// EN_T, EN_N, EN_X, EN_Y: el enemigo que muere
		msc_run (MSC_PLAYER_KILLS_ENEMY);
	#endif

	#ifdef ENABLE_RANDOM_RESPAWN
		if (en_an_fanty_activo [gpit]) {
			// Muere el fanty; el enemigo original ya estaba muerto.
			en_an_fanty_activo [gpit] = 0;
			return;
		}
	#endif

	#ifdef ENABLE_PURSUERS
		if (_en_t == 7) {
			// Los perseguidores reaparecen al cabo de un rato.
			en_an_alive [gpit] = 0;
			en_an_dead_row [gpit] = DEATH_COUNT_EXPRESSION;
			return;
		}
	#endif

	_en_t |= 16;
}
#endif

void mueve_bicharracos (void) {

	// Init some flags
	tocado = 0; player.gotten = 0;

	// Arrastre de plataformas: lo fija la plataforma que lleve al jugador y lo
	// aplica move () en el frame siguiente.
	ptgmx = ptgmy = 0;

	for (gpit = 0; gpit < 3; gpit ++) {

		// Enemies that are alive and moving will set active to 1 and will collide, etc
		active = 0;

		enoffsmasi = enoffs + gpit;

		// Extract values from the array
		// Se copia el enemigo a variables globales (_en_*), que en sccz80 son
		// mucho más rápidas que acceder a la estructura, y al final se guarda.
		// Los paréntesis importan: "(unsigned char *) malotes + n" sumaría n
		// bytes en C estándar (sccz80 lo trata distinto).
		allpurposepuntero = (unsigned char *) (malotes + enoffsmasi);
		_en_x = *allpurposepuntero ++;
		_en_y = *allpurposepuntero ++;
		_en_x1 = *allpurposepuntero ++;
		_en_y1 = *allpurposepuntero ++;
		_en_x2 = *allpurposepuntero ++;
		_en_y2 = *allpurposepuntero ++;
		// Sin cast: sccz80 aplicaría "(signed char) *p ++" al puntero y lo
		// corrompería. La asignación a un signed char ya convierte el valor.
		_en_mx = *allpurposepuntero ++;
		_en_my = *allpurposepuntero ++;
		_en_t = *allpurposepuntero ++;
		#ifdef MALOTE_HAS_LIFE
			_en_life = *allpurposepuntero;
		#endif

		// Make explosion

		if (en_an_state [gpit] == GENERAL_DYING) {
			en_an_count [gpit] --;
			if (en_an_count [gpit] == 0) {
				en_an_state [gpit] = 0;
				en_an_next_frame [gpit] = sprite_18_a;
			}
			continue;
		}

		#ifdef ENABLE_RANDOM_RESPAWN
			// rdt es el tipo con el que se comporta el enemigo: 5 si hay un fanty
			// en su lugar. _en_t (el del enemigo original, que está muerto) no se
			// toca.
			rdt = en_an_fanty_activo [gpit] ? 5 : _en_t;
		#else
			#define rdt _en_t
		#endif

		// Update enemies upon type
		// gpen_cx / gpen_cy will be used for collision later on

		switch (rdt) {

			// Linear enemies

			case 1:
			case 2:
			case 3:
			case 4:
				active = 1;
				_en_x += _en_mx;
				_en_y += _en_my;

				// Tile coordinates used by mons_col_sc_?

				gpen_xx = _en_x >> 4;
				gpen_yy = _en_y >> 4;

				// Turn around?

				if (_en_x == _en_x1 || _en_x == _en_x2
					#ifdef WALLS_STOP_ENEMIES
						|| mons_col_sc_x ()
					#endif
				) {
					_en_mx = -_en_mx;
				}

				if (_en_y == _en_y1 || _en_y == _en_y2
					#ifdef WALLS_STOP_ENEMIES
						|| mons_col_sc_y ()
					#endif
				) {
					_en_my = -_en_my;
				}

				gpen_cx = _en_x;
				gpen_cy = _en_y;

				break;

			// RR fanties

			#ifdef ENABLE_RANDOM_RESPAWN
				case 5:
					active = 1;

					// Se acelera hacia el jugador (o se aleja si está escondido).
					// Las direcciones se comparan en píxeles: la diferencia de dos
					// posiciones 8.8 no cabe en un int con signo.
					gpen_cx = FIXED_PIX (en_an_x [gpit]);
					gpen_cy = FIXED_PIX (en_an_y [gpit]);
					if (player_hidden ()) {
						en_an_vx [gpit] = limit (
							en_an_vx [gpit] + addsign (gpen_cx - gpx, FANTY_A >> 1),
							-FANTY_MAX_V, FANTY_MAX_V);
						en_an_vy [gpit] = limit (
							en_an_vy [gpit] + addsign (gpen_cy - gpy, FANTY_A >> 1),
							-FANTY_MAX_V, FANTY_MAX_V);
					} else if ((rand () & 7) > 1) {
						en_an_vx [gpit] = limit (
							en_an_vx [gpit] + addsign (gpx - gpen_cx, FANTY_A),
							-FANTY_MAX_V, FANTY_MAX_V);
						en_an_vy [gpit] = limit (
							en_an_vy [gpit] + addsign (gpy - gpen_cy, FANTY_A),
							-FANTY_MAX_V, FANTY_MAX_V);
					}

					en_an_x [gpit] += en_an_vx [gpit];
					FIXED_CLAMP (en_an_x [gpit], FIXED_MAX_X);
					en_an_y [gpit] += en_an_vy [gpit];
					FIXED_CLAMP (en_an_y [gpit], FIXED_MAX_Y);

					gpen_cx = FIXED_PIX (en_an_x [gpit]);
					gpen_cy = FIXED_PIX (en_an_y [gpit]);

					break;
			#endif

			#ifdef ENABLE_CUSTOM_TYPE_6
				case 6:
					active = 1;
					// Posición actual en píxeles y distancia al jugador.
					gpen_cx = FIXED_PIX (en_an_x [gpit]);
					gpen_cy = FIXED_PIX (en_an_y [gpit]);
					rdd = distance (gpx, gpy, gpen_cx, gpen_cy);

					switch (en_an_state [gpit]) {
						case TYPE_6_IDLE:
							if (rdd <= SIGHT_DISTANCE)
								en_an_state [gpit] = TYPE_6_PURSUING;
							break;
						case TYPE_6_PURSUING:
							if (rdd > SIGHT_DISTANCE) {
								en_an_state [gpit] = TYPE_6_RETREATING;
							} else {
								en_an_vx [gpit] = limit (
									en_an_vx [gpit] + addsign (gpx - gpen_cx, FANTY_A),
									-FANTY_MAX_V, FANTY_MAX_V);
								en_an_vy [gpit] = limit (
									en_an_vy [gpit] + addsign (gpy - gpen_cy, FANTY_A),
									-FANTY_MAX_V, FANTY_MAX_V);

								en_an_x [gpit] += en_an_vx [gpit];
								FIXED_CLAMP (en_an_x [gpit], FIXED_MAX_X);
								en_an_y [gpit] += en_an_vy [gpit];
								FIXED_CLAMP (en_an_y [gpit], FIXED_MAX_Y);
							}
							break;
						case TYPE_6_RETREATING:
							// Vuelve a su posición original (_en_x, _en_y)
							if (gpen_cx != _en_x) en_an_x [gpit] += addsign (_en_x - gpen_cx, 256);
							if (gpen_cy != _en_y) en_an_y [gpit] += addsign (_en_y - gpen_cy, 256);

							if (rdd <= SIGHT_DISTANCE)
								en_an_state [gpit] = TYPE_6_PURSUING;
							break;
					}
					gpen_cx = FIXED_PIX (en_an_x [gpit]);
					gpen_cy = FIXED_PIX (en_an_y [gpit]);
					if (en_an_state [gpit] == TYPE_6_RETREATING &&
						gpen_cx == _en_x &&
						gpen_cy == _en_y
						)
						en_an_state [gpit] = TYPE_6_IDLE;
					break;
			#endif

			#ifdef ENABLE_PURSUERS
				case 7:
					switch (en_an_alive [gpit]) {

						// State: Dead
						case 0:
							if (en_an_dead_row [gpit] == 0) {
								_en_x = _en_x1;
								_en_y = _en_y1;

								en_an_alive [gpit] = 1;
								en_an_rawv [gpit] = 1 << (rand () % 5);

								if (en_an_rawv [gpit] > 4) en_an_rawv [gpit] = 2;
								en_an_dead_row [gpit] = 11 + (rand () & 7);

								#ifdef MALOTE_HAS_LIFE
									_en_life = LEVEL_ENEMS_LIFE;
								#endif
							} else {
								en_an_dead_row [gpit] --;
							}
							break;

						// State: Appearing
						case 1:

							if (en_an_dead_row [gpit] == 0) {
								#ifdef TYPE_7_FIXED_SPRITE
									en_an_base_frame [gpit] = (TYPE_7_FIXED_SPRITE - 1) << 1;
								#else
									en_an_base_frame [gpit] = (rand () & 3) << 1;
								#endif
								en_an_alive [gpit] = 2;
							} else {
								en_an_dead_row [gpit] --;
								en_an_next_frame [gpit] = sprite_17_a;
							}
							break;

						// State: pursuing
						case 2:
							active = 1;
							if (player.estado == EST_NORMAL) {
								// Avanza hacia el jugador en x y en y; con WALLS_STOP_ENEMIES
								// se deshace el paso si choca con el escenario.
								rda = _en_x;
								_en_mx = (signed char) (addsign ((gpx & 0xFC) - _en_x, en_an_rawv [gpit]));
								_en_x += _en_mx;

								gpen_xx = _en_x >> 4;
								gpen_yy = _en_y >> 4;
								#ifdef WALLS_STOP_ENEMIES
									if (mons_col_sc_x ()) _en_x = rda;
								#endif

								rda = _en_y;
								_en_my = (signed char) (addsign ((gpy & 0xFC) - _en_y, en_an_rawv [gpit]));
								_en_y += _en_my;
								gpen_xx = _en_x >> 4;
								gpen_yy = _en_y >> 4;
								#ifdef WALLS_STOP_ENEMIES
									if (mons_col_sc_y ()) _en_y = rda;
								#endif
							}
							gpen_cx = _en_x;
							gpen_cy = _en_y;
					}
					break;
			#endif
		}

		if (active) {
			// Animate
			if((maincounter & 3) == 0) en_an_frame [gpit] ^= 1;
			en_an_next_frame [gpit] = enem_frames [en_an_base_frame [gpit] + en_an_frame [gpit]];

			// Collide with player

			// Plataformas móviles
			#ifndef PLAYER_MOGGY_STYLE
				if (rdt == 4) {
					// If (horizontally) within range...
					if (gpx + 15 >= _en_x && gpx <= _en_x + 15) {

						if (_en_my < 0) {
							// vertical, up

							if (gpy + 16 >= _en_y && gpy + 9 <= _en_y && player.vy >= -(PLAYER_INCR_SALTO)) {
								platform_get_player ();
							}

						} else if (_en_my > 0) {
							// vertical, down
							if (gpy + 20 >= _en_y && gpy + 13 <= _en_y && player.vy >= 0) {
								platform_get_player ();
							}
						}

						// Horizontal
						if (_en_mx != 0 && gpy + 16 >= _en_y && gpy + 11 <= _en_y && player.vy >= 0) {
							platform_get_player ();
							// Arrastre horizontal de la plataforma
							ptgmx = _en_mx << 8;
						}
					}
				} else
			#endif
			{
				// In genital, _en_t = any; in lateral, _en_t != 4
				if (!tocado && collide (gpx, gpy, gpen_cx, gpen_cy) && player.estado == EST_NORMAL) {

					#ifdef MSC_SECT_ENEMY_TOUCHED
						// EN_T, EN_N, EN_X, EN_Y: el enemigo que se toca
						msc_run (MSC_ENEMY_TOUCHED);
					#endif

					// Colisión especial: pisar enemigo

					#ifdef PLAYER_STEPS_ON_ENEMIES
						// El jugador cae desde arriba sobre el enemigo (gpen_cy es su
						// posición real, también para fanties y tipo 6).
						if (
							gpy + 2 < gpen_cy && player.vy >= 0
							#ifdef PLAYER_MIN_KILLABLE
								&& rdt >= PLAYER_MIN_KILLABLE
							#endif
							#ifdef PLAYER_CAN_KILL_FLAG
								&& flags [PLAYER_CAN_KILL_FLAG]
							#endif
						) {
							#ifdef PLAYER_KILLS_ENEMIES
								enemy_dies ();
								update_this_enemy ();
								sp_UpdateNow ();
								PLAY_SFX (5); 				// Spectrum 48K friendly (pause)
							#else
								PLAY_SFX (3);
							#endif

							gpy = gpen_cy >= 16 ? gpen_cy - 16 : 0;
							SET_FIXED_PIX (player.y, gpy);
							player.vy = -1024;

						} else
					#endif

					// Colisión normal
					{
						tocado = 1;

						#ifdef SLOW_DRAIN_ON
							if (!lasttimehit || ((maincounter & 3) == 0))
						#endif
						{
							kill_player(4);
						}

						#ifdef PLAYER_BOUNCES
							#ifdef PLAYER_MOGGY_STYLE
								// Rebote genital
								if (_en_mx) {
									player.vx = addsign (gpx - gpen_cx, abs (_en_mx) << 10);
								}
								if (_en_my) {
									player.vy = addsign (gpy - gpen_cy, abs (_en_my) << 10);
								}
							#else
								#ifdef ENEMS_HAVE_FREE_COORDS
									if (rdt == 5 || rdt == 6) {
										player.vx = en_an_vx [gpit] + en_an_vx [gpit];
										player.vy = en_an_vy [gpit] + en_an_vy [gpit];
									} else
								#endif
								{
									player.vx = addsign (_en_mx, PLAYER_MAX_VX);
									player.vy = addsign (_en_my, PLAYER_MAX_VX);
								}
							#endif
						#endif

						#ifdef PLAYER_FLICKERS
							player.estado = EST_PARP;
							player.ct_estado = 50;
						#endif

					}
				}
			}

			// Collide with bullets

			#ifdef PLAYER_CAN_FIRE

				#ifdef FIRE_MIN_KILLABLE
					if (rdt >= FIRE_MIN_KILLABLE)
				#endif
				{
					for (gpjt = 0; gpjt < MAX_BULLETS; gpjt ++) {
						if (bullets_estado [gpjt]) {
							blx = bullets_x [gpjt] + 3;
							bly = bullets_y [gpjt] + 3;
							if (blx >= gpen_cx && blx <= gpen_cx + 15 && bly >= gpen_cy && bly <= gpen_cy + 15) {
								bullets_estado [gpjt] = 0;
								en_an_morido [gpit] = 1;		// Suena al final del frame

								// Los que se mueven libremente reculan
								#ifdef ENEMS_HAVE_FREE_COORDS
									if (rdt == 5 || rdt == 6) {
										en_an_vx [gpit] += addsign (bullets_mx [gpjt], 512);
									}
								#endif

								// Cada impacto quita una vida; el enemigo muere al
								// llegar a 0. Las plataformas (tipo 4, vista lateral)
								// son invulnerables.
								#ifndef PLAYER_MOGGY_STYLE
									if (rdt != 4)
								#endif
								{
									#ifdef MALOTE_HAS_LIFE
										if (_en_life) _en_life --;
										if (_en_life == 0)
									#endif
									{
										enemy_dies ();
									}
								}
								break;
							}
						}
					}
				}
			#endif
		}

		#ifdef ENABLE_RANDOM_RESPAWN
			// Activar fanty
			// De vez en cuando aparece un fanty en lugar de un enemigo muerto.
			if (_en_t > 15 && en_an_fanty_activo [gpit] == 0 && en_an_state [gpit] != GENERAL_DYING && (rand () & 31) == 1
				#ifdef MSC_RV_EF
					&& !dont_make_fanties
				#endif
			) {
				en_an_fanty_activo [gpit] = 1;
				// Aparece por arriba o por abajo, lejos del jugador
				SET_FIXED_PIX (en_an_y [gpit], gpy > 80 ? 0 : 144);
				SET_FIXED_PIX (en_an_x [gpit], rand () % 225);
				en_an_vx [gpit] = en_an_vy [gpit] = 0;
				en_an_base_frame [gpit] = 4;
				#ifdef MALOTE_HAS_LIFE
					_en_life = FANTIES_LIFE_GAUGE;
				#endif
			}
		#else
			#undef rdt
		#endif

		// Put stuff back into the array
		allpurposepuntero = (unsigned char *) (malotes + enoffsmasi);
		*allpurposepuntero ++ = _en_x;
		*allpurposepuntero ++ = _en_y;
		*allpurposepuntero ++ = _en_x1;
		*allpurposepuntero ++ = _en_y1;
		*allpurposepuntero ++ = _en_x2;
		*allpurposepuntero ++ = _en_y2;
		*allpurposepuntero ++ = _en_mx;
		*allpurposepuntero ++ = _en_my;
		*allpurposepuntero ++ = _en_t;
		#ifdef MALOTE_HAS_LIFE
			*allpurposepuntero = _en_life;
		#endif
	}

	#ifdef SLOW_DRAIN_ON
		lasttimehit = tocado;
	#endif
}
