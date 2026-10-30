// La Churrera Engine 3.100
// Copyleft 2010-2014 the Mojon Twins

// mainloop.h
// Churrera copyleft 2011 by The Mojon Twins.

// Special keys

void main (void) {
	#ifndef CPC
		#asm
				ld  sp, STACK_ADDR
		#endasm
	#endif

	cortina ();
	system_init ();

	// Ganchos (hooks): funciones opcionales que define cada juego en custom.h.
	// Cada una se activa definiendo su HOOK_*.
	#ifdef HOOK_GAME_INIT
		hook_game_init ();
	#endif

	while (1) {
		title ();

		#ifdef ENABLE_CHECKPOINTS
			sg_submenu ();
		#endif

		mlplaying = 1;
		#ifdef COMPRESSED_LEVELS
			// Nivel inicial: el gancho puede devolver otro (menú, contraseñas...)
			#ifdef HOOK_AFTER_TITLE
				level = hook_after_title ();
			#else
				level = 0;
			#endif
			#ifdef ENABLE_CHECKPOINTS
				if (sg_do_load) level = sg_level;
			#endif

			#ifndef REFILL_ME
				player.life = PLAYER_LIFE;
			#endif
		#elif defined HOOK_AFTER_TITLE
			hook_after_title ();
		#endif

		while (mlplaying) {
			#ifndef COMPRESSED_LEVELS
				mlplaying = 0;
			#else
				// Presentación del nivel: la del juego o "LEVEL XX".
				#ifdef HOOK_LEVEL_INTRO
					hook_level_intro ();
				#else
					clear_gamearea_tiles ();
					level_str [7] = '0' + (level + 1) / 10;
					level_str [8] = '0' + (level + 1) % 10;
					print_str (VIEWPORT_X + 10, VIEWPORT_Y + 9, 71, level_str);
					sp_UpdateNow ();
					PLAY_SFX (2);
					espera_activa (100);
				#endif

				prepare_level ();
			#endif

			#ifndef DIRECT_TO_PLAY
				// Clear screen and show game frame
				cortina ();
				sp_UpdateNow();

				#ifdef MODE_128K
					get_resource (RES_MARCO, 16384);
				#else
					unpack_screen (s_marco);
				#endif
			#endif

			// Let's do it.

			init_player ();

			// Con niveles, hotspots, cerrojos y enemigos vienen nuevos en el
			// bundle; init_malotes sigue haciendo falta para fijar su vida.
			#ifndef COMPRESSED_LEVELS
				init_hotspots ();
				#if !defined DEACTIVATE_KEYS
					init_cerrojos ();
				#endif
			#endif

			#ifdef NEEDS_INIT_MALOTES
				init_malotes ();
			#endif

			n_pant = LEVEL_SCR_INI;
			o_pant = 0xff;

			#ifdef PLAYER_CAN_FIRE
				init_bullets ();
			#endif


			#ifdef ACTIVATE_SCRIPTING
				// Flags a 0 y el script del nivel (o el del juego)
				msc_init ();
				#ifdef MSC_SECT_ENTERING_GAME
					msc_run (MSC_ENTERING_GAME);
				#endif
			#endif

			#ifdef PLAYER_KILLS_ENEMIES
				#ifdef SHOW_TOTAL
						// Show total of enemies next to the killed amount.

						sp_PrintAtInv (KILLED_Y, 2 + KILLED_X, 71, 15);
						sp_PrintAtInv (KILLED_Y, 3 + KILLED_X, 71, 16 + BADDIES_COUNT / 10);
						sp_PrintAtInv (KILLED_Y, 4 + KILLED_X, 71, 16 + BADDIES_COUNT % 10);
				#endif
			#endif

			half_life = 0;
			maincounter = 0;
			success = 0;
			objs_old = keys_old = life_old = killed_old = 0xff;
			#ifdef MSC_SHOW_ITEM
				item_old = 0xff;
			#endif

			#ifdef MAX_AMMO
				ammo_old = 0xff;
			#endif

			#ifdef SHOW_TIMER
				timer_old = 0;
			#endif

			#ifdef ENABLE_CHECKPOINTS
				if (sg_do_load) {
					mem_load ();
				}
			#endif

			// Coordenadas de la pantalla en el mapa (después de cargar el
			// checkpoint, que puede cambiar n_pant).
			#ifdef PLAYER_CHECK_MAP_BOUNDARIES
				x_pant = n_pant % LEVEL_MAP_W;
				y_pant = n_pant / LEVEL_MAP_W;
			#endif

			// Música del nivel
			#ifdef MODE_128K
				#ifdef COMPRESSED_LEVELS
					wyz_play_music (levels [level].music);
				#else
					wyz_play_music (1);
				#endif
			#endif
			#ifdef CPC
				wyz_play_music (1);
			#endif

			#ifdef HOOK_LEVEL_START
				hook_level_start ();
			#endif

			playing = 1;
			while (playing) {
				if (o_pant != n_pant) {
					#ifdef ACTIVATE_SCRIPTING
						// Durante draw_scr, o_pant es la pantalla de la que venimos
						// (OPANT en los scripts). Si un script de ENTERING cambia
						// n_pant (WARP TO...), en la siguiente vuelta se pinta la nueva.
						rdn = n_pant;
						draw_scr ();
						o_pant = rdn;
					#else
						draw_scr ();
						o_pant = n_pant;
					#endif
					#ifdef HOOK_ENTERING_SCREEN
						hook_entering_screen ();
					#endif
				}
			
				#ifdef TIMER_ENABLE
					// Timer
					if (ctimer.on) {
						ctimer.count ++;
						if (ctimer.count == ctimer.frames) {
							ctimer.count = 0;
							ctimer.t --;
							if (ctimer.t == 0) ctimer.zero = 1;
						}
					}

					#if defined ACTIVATE_SCRIPTING && defined MSC_SECT_TIMER_ZERO
						// El tiempo llega a 0: sección TIMER ZERO del script
						if (ctimer.zero) {
							ctimer.zero = 0;
							#ifdef SHOW_TIMER_OVER
								saca_a_todo_el_mundo_de_aqui ();
								time_over ();
							#endif
							msc_run (MSC_TIMER_ZERO);
						}	
					#endif

					#ifdef TIMER_KILL_0
						if (ctimer.zero) {
							#ifdef SHOW_TIMER_OVER
								#ifndef MSC_SECT_TIMER_ZERO
									saca_a_todo_el_mundo_de_aqui ();
									time_over ();
								#endif
							#endif				
							
							ctimer.zero = 0;
							
							#ifdef TIMER_AUTO_RESET 			
								ctimer.t = TIMER_INITIAL;
							#endif
				
							kill_player (4);
							
							#ifdef PLAYER_FLICKERS
								player.estado = EST_PARP;
								player.ct_estado = 50;
							#endif

							#if defined(TIMER_WARP_TO_X) && defined(TIMER_WARP_TO_Y)
								set_player_at (TIMER_WARP_TO_X << 4, TIMER_WARP_TO_Y << 4);
							#endif

							#ifdef TIMER_WARP_TO
								n_pant = TIMER_WARP_TO;
								draw_scr ();
							#endif
						}
					#endif
				#endif

				// Marcador. Un contador con coordenada X 99 no se muestra.
				#if !defined DEACTIVATE_OBJECTS && OBJECTS_X != 99
					if (player.objs != objs_old) {
						draw_objs ();
						objs_old = player.objs;
					}
				#endif
			
				if (player.life != life_old) {
					print_number2 (LIFE_X, LIFE_Y, player.life);
					life_old = player.life;
				}
			
				#if !defined DEACTIVATE_KEYS && KEYS_X != 99
					if (player.keys != keys_old) {
						print_number2 (KEYS_X, KEYS_Y, player.keys);
						keys_old = player.keys;
					}
				#endif

				#ifdef SHOW_KILLS
					if (player.killed != killed_old) {
						print_number2 (KILLED_X, KILLED_Y, player.killed);
						killed_old = player.killed; 
					}
				#endif

				#ifdef MSC_SHOW_ITEM
					// El objeto que se lleva (GET ITEM): su tile en ITEM_X, ITEM_Y
					if (flags [MSC_ITEM_SLOT] != item_old) {
						draw_coloured_tile (ITEM_X, ITEM_Y, flags [MSC_ITEM_SLOT]);
						item_old = flags [MSC_ITEM_SLOT];
					}
				#endif

				#if defined MAX_AMMO && AMMO_X != 99
					if (player.ammo != ammo_old) {
						print_number2 (AMMO_X, AMMO_Y, player.ammo);
						ammo_old = player.ammo;
					}
				#endif

				#ifdef SHOW_TIMER
					if (ctimer.t != timer_old) {
						print_number2 (TIMER_X, TIMER_Y, ctimer.t);
						timer_old = ctimer.t;
					}
				#endif

				maincounter ++;
				half_life ^= 1;
			
				// Move player
				move ();

				#ifdef ACTIVATE_SCRIPTING
					#ifdef PUSHED_SCRIPTING
						// Se ha empujado un bloque: TILE PUSHED (TX, TY = donde quedó)
						if (just_pushed) {
							just_pushed = 0;
							#ifdef MSC_SECT_TILE_PUSHED
								msc_run_at (MSC_TILE_PUSHED, msc_moved_x, msc_moved_y);
							#endif
						}
					#endif

					#ifdef MSC_SECT_SPECIAL_TILE
						// El centro del jugador está en un tile con comportamiento 128
						rdx = (gpx + 8) >> 4; rdy = (gpy + 8) >> 4;
						if (attr (rdx, rdy) & 128) msc_run_at (MSC_SPECIAL_TILE, rdx, rdy);
					#endif
				#endif
				
				// Move enemies
				mueve_bicharracos ();

				#ifdef PLAYER_CAN_FIRE
					// Move bullets 			
					mueve_bullets ();
				#endif

				#ifdef ENABLE_TILANIMS
					do_tilanims ();
				#endif

				render_sprites ();
	
				#ifdef FIRE_ZONE
					if (f_zone_ac == 1) {
						// Dentro de la zona de fuego es como pulsar FIRE
						if (gpx >= fzx1 && gpx <= fzx2 && gpy >= fzy1 && gpy <= fzy2) {
							msc_run_screen (MSC_FIRE_ANY);
						}	
					}
				#endif			

				// Update to screen
				sp_UpdateNow();

				// Sincronía de frames: espera a que pasen GAME_FRAME_TICKS
				// interrupciones desde el frame anterior (en CPC lo hace sp_UpdateNow).
				#if !defined CPC && GAME_FRAME_TICKS > 0
					while (isr_frames < GAME_FRAME_TICKS);
					isr_frames = 0;
				#endif
			
				#ifdef PLAYER_CAN_FIRE
					for (gpit = 0; gpit < 3; gpit ++) {
						if (en_an_morido [gpit]) {
							PLAY_SFX (1);
							en_an_morido [gpit] = 0;
						}	
					}
				#endif

				#ifdef PLAYER_FLICKERS
					// Flickering
					if (player.estado == EST_PARP) {
						player.ct_estado --;
						if (player.ct_estado == 0)
							player.estado = EST_NORMAL; 
					}
				#endif			
			
				// Hotspot interaction.

				do_hotspots ();

				// Flick screen checks and scripting related stuff
				
				// Tecla de acción: PRESS FIRE AT ANY y PRESS FIRE AT SCREEN n_pant
				#if defined ACTIVATE_SCRIPTING && (defined MSC_SECT_FIRE_ANY || defined MSC_SECT_ROOMS)
					if (
						#if defined SCRIPTING_KEY_M			
							sp_KeyPressed (KEY_M)
						#elif defined SCRIPTING_DOWN
							(pad_this_frame & sp_DOWN) == 0
						#else
							(pad_this_frame & sp_FIRE) == 0
						#endif
					) {
						msc_run_screen (MSC_FIRE_ANY);
					}
				#endif

				#ifdef PAUSE_ABORT
					// Pause/Abort handling
					if (sp_KeyPressed (KEY_H)) {
						sp_WaitForNoKey ();
						#ifdef MODE_128K
							wyz_stop_sound ();
							wyz_play_sound (1);
						#endif				
						saca_a_todo_el_mundo_de_aqui ();
						pause_screen ();
						while (!sp_KeyPressed (KEY_H));
						sp_WaitForNoKey ();
						redraw_scr ();
						
						#ifdef MODE_128K
							#ifdef COMPRESSED_LEVELS
								//wyz_play_music (levels [level].music_id);
							#else
								//wyz_play_music (1);
							#endif
						#endif				
					}			
					if (sp_KeyPressed (KEY_Y)) {
						playing = 0;
					}
				#endif

				// Change screen
				
				// Cambio de pantalla al salir por un borde. LEVEL_MAP_W / H es el
				// tamaño del mapa (con niveles, el del nivel actual).
				{
					if (gpx == 0 && player.vx < 0
						#ifdef PLAYER_CHECK_MAP_BOUNDARIES
							&& x_pant > 0
						#endif
					) {
						n_pant --;
						#ifdef PLAYER_CHECK_MAP_BOUNDARIES
							x_pant --;
						#endif
						player.x = FIXED_MAX_X; gpx = 224;
					}

					if (
						gpx == 224 && player.vx > 0
						#ifdef PLAYER_CHECK_MAP_BOUNDARIES
							&& x_pant < (LEVEL_MAP_W - 1)
						#endif
					) {
						n_pant ++;
						#ifdef PLAYER_CHECK_MAP_BOUNDARIES
							x_pant ++;
						#endif
						player.x = 0; gpx = 0;
					}

					if (gpy == 0 && player.vy < 0 && n_pant >= LEVEL_MAP_W) {
						n_pant -= LEVEL_MAP_W;
						#ifdef PLAYER_CHECK_MAP_BOUNDARIES
							y_pant --;
						#endif
						player.y = FIXED_MAX_Y; gpy = 144;
					}

					if (
						gpy == 144 && player.vy > 0
						#ifdef PLAYER_CHECK_MAP_BOUNDARIES
							&& y_pant < (LEVEL_MAP_H - 1)
						#endif
					) {
						#ifdef MAP_BOTTOM_KILLS
							if (n_pant >= LEVEL_MAP_W * LEVEL_MAP_H - LEVEL_MAP_W) {
								player.vy = -PLAYER_MAX_VY_CAYENDO;
								kill_player (10);

							} else
						#endif
						{
							n_pant += LEVEL_MAP_W;
							#ifdef PLAYER_CHECK_MAP_BOUNDARIES
								y_pant ++;
							#endif
							player.y = 0; gpy = 0;
							if (player.vy > 1024) player.vy = 1024;
						}
					}
				}


				// Win game condition
				// Todos los objetos y, si hay pantalla final, estar en su tile.
				// Un juego puede poner su propia condición con HOOK_WIN_CONDITION.
				#ifdef HOOK_WIN_CONDITION
					if (hook_win_condition ()
						#ifdef ACTIVATE_SCRIPTING
							|| script_result == 1
						#endif
					) {
						success = 1;
						playing = 0;
					}
				#else
					if (player.objs == LEVEL_MAX_OBJS
						#ifdef ACTIVATE_SCRIPTING
							|| script_result == 1
						#endif
					) {
						if (
							pant_final == 99 ||
							(n_pant == pant_final && (gpx >> 4 == LEVEL_FIN_X && gpy >> 4 == LEVEL_FIN_Y))
						) {
							success = 1;
							playing = 0;
						}
					}
				#endif

				// Game over condition
				if (player.life == 0
					#ifdef ACTIVATE_SCRIPTING
						|| script_result == 2
					#endif
					#if defined(TIMER_ENABLE) && defined(TIMER_GAMEOVER_0)
						|| ctimer.zero
					#endif
				) {
					playing = 0;
				}
			}
			sp_WaitForNoKey ();

			#ifdef HAS_AY_MUSIC
				wyz_stop_sound ();
			#endif

			saca_a_todo_el_mundo_de_aqui ();
			sp_UpdateNow ();

			if (success) {
				#ifdef HOOK_LEVEL_END
					hook_level_end ();
				#endif
				#ifdef COMPRESSED_LEVELS
					level ++;
					if (level == MAX_LEVELS) {
						mlplaying = 0;
					}
				#endif
				if (mlplaying == 0) {
					#ifdef HOOK_GAME_ENDING
						hook_game_ending ();
					#else
						game_ending ();
					#endif
				}
			} else {
				mlplaying = 0;
				#ifdef HOOK_GAME_OVER
					hook_game_over ();
				#elif defined(TIMER_ENABLE) && defined(TIMER_GAMEOVER_0) && defined(SHOW_TIMER_OVER)
					if (ctimer.zero) time_over (); else game_over ();
				#else
					game_over ();
				#endif
				#ifdef HAS_AY_MUSIC
					wyz_stop_sound ();
				#endif
			}
		}

		cortina ();
	}
}
