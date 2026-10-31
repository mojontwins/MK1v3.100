// La Churrera Engine 3.100
// Copyleft 2010-2014 the Mojon Twins

// mainloop.h
// Churrera copyleft 2011 by The Mojon Twins.

// Música del nivel (level_music: la de la tabla de niveles o la que ponga
// MUSIC n en el script)
void play_level_music (void) {
	#ifdef HAS_AY_MUSIC
		wyz_play_music (level_music);
	#endif
}

// Entra en la pantalla n_pant: la pinta y ejecuta sus scripts de entrada y
// el gancho HOOK_ENTERING_SCREEN.
void enter_screen (void) {
	#ifdef ACTIVATE_SCRIPTING
		// Durante draw_scr, o_pant es la pantalla de la que venimos
		// (OPANT en los scripts). Si un script de ENTERING cambia
		// n_pant (WARP TO...), en la siguiente vuelta se pinta la nueva. Con
		// REENTER se vuelve a entrar en la misma.
		rdn = n_pant;
		msc_reenter = 0;
		draw_scr ();
		o_pant = msc_reenter ? 0xff : rdn;
	#else
		draw_scr ();
		o_pant = n_pant;
	#endif
	#ifdef PLAYER_CHECK_MAP_BOUNDARIES
		// Por si se ha llegado sin pasar por un borde (warp, respawn...)
		x_pant = o_pant % LEVEL_MAP_W;
		y_pant = o_pant / LEVEL_MAP_W;
	#endif
	#ifdef HOOK_ENTERING_SCREEN
		hook_entering_screen ();
	#endif
}

#ifdef DIE_AND_RESPAWN
	// Tras morir (p_killme): el gancho HOOK_PLAYER_DIES (o un sonido y una
	// pausa) y, si quedan vidas y no se está nadando, se vuelve al último
	// sitio seguro: el primer tile a partir de él con suelo debajo y sin
	// obstáculo.
	void respawn (void) {
		sp_UpdateNow ();
		#ifdef HOOK_PLAYER_DIES
			hook_player_dies ();
		#else
			PLAY_SFX (4);
			espera_activa (50);
		#endif
		if (player.life && !SWIMMING) {
			if (n_pant != p_safe_pant) {
				n_pant = p_safe_pant;
				enter_screen ();
			}
			while (p_safe_x < 14 && (
				!(attr (p_safe_x, p_safe_y + 1) & 12) ||
				(attr (p_safe_x, p_safe_y) & 8)
			)) p_safe_x ++;
			set_player_at (p_safe_x << 4, p_safe_y << 4);
			player.vx = player.vy = 0;
			player.saltando = 0;
		}
		p_killme = 0;
		play_level_music ();
	}
#endif

void main (void) {
	// La pila la coloca crt0 (en STACK_ADDR, ver churromain.c).
	cortina ();
	system_init ();

	// Ganchos (hooks): funciones opcionales que define cada juego en custom.h.
	// Cada una se activa definiendo su HOOK_*.
	#ifdef HOOK_GAME_INIT
		hook_game_init ();
	#endif

	while (1) {
		title ();

		// La música del título sigue durante el gancho HOOK_AFTER_TITLE (un
		// menú), que la para cuando quiera; si no, se para aquí.
		#if defined HAS_AY_MUSIC && !defined HOOK_AFTER_TITLE
			wyz_stop_sound ();
		#endif

		#ifdef ENABLE_CHECKPOINTS
			sg_submenu ();
		#endif

		mlplaying = 1;

		// Flags de la partida (con KEEP_FLAGS_BETWEEN_LEVELS duran toda la
		// partida y no se borran en cada nivel)
		#if defined ACTIVATE_SCRIPTING && defined KEEP_FLAGS_BETWEEN_LEVELS
			msc_clear_flags ();
		#endif

		#ifdef COMPRESSED_LEVELS
			// La vida se pone antes del gancho, que puede cambiarla (una
			// contraseña puede llevar la vida y los flags).
			#ifndef REFILL_ME
				player.life = PLAYER_LIFE;
			#endif
			level_warped = silent_level = 0;

			// Nivel inicial: el gancho puede devolver otro (menú, contraseñas...)
			#ifdef HOOK_AFTER_TITLE
				level = hook_after_title ();
			#else
				level = 0;
			#endif
			#ifdef ENABLE_CHECKPOINTS
				if (sg_do_load) level = sg_level;
			#endif
		#elif defined HOOK_AFTER_TITLE
			hook_after_title ();
		#endif

		while (mlplaying) {
			#ifndef COMPRESSED_LEVELS
				mlplaying = 0;
			#else
				// Presentación del nivel: la del juego o "LEVEL XX". Un WARP TO
				// LEVEL "silencioso" se la salta.
				if (!silent_level) {
					#ifdef HOOK_LEVEL_INTRO
						hook_level_intro ();
					#else
						clear_gamearea_tiles ();
						memcpy (level_str, " LEVEL 00 ", 11);
						level_str [7] = '0' + (level + 1) / 10;
						level_str [8] = '0' + (level + 1) % 10;
						print_str (VIEWPORT_X + 10, VIEWPORT_Y + 9, 71, level_str);
						sp_UpdateNow ();
						PLAY_SFX (2);
						espera_activa (100);
					#endif
				}

				prepare_level ();
			#endif

			#ifndef DIRECT_TO_PLAY
				// Clear screen and show game frame (salvo en un WARP TO LEVEL
				// silencioso, que sigue con la pantalla que había)
				#ifdef COMPRESSED_LEVELS
					if (!silent_level)
				#endif
				{
					cortina ();
					sp_UpdateNow();

					#ifdef MODE_128K
						get_resource (RES_MARCO, 16384);
					#else
						unpack_screen (s_marco);
					#endif
				}
			#endif
			#ifdef COMPRESSED_LEVELS
				silent_level = 0;
			#endif

			// Let's do it.

			init_player ();

			// Con niveles, hotspots, cerrojos y enemigos vienen nuevos en el
			// bundle; init_malotes sigue haciendo falta para fijar su vida.
			#ifndef COMPRESSED_LEVELS
				init_enems ();
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

			#ifdef COMPRESSED_LEVELS
				// Llegando por un WARP TO LEVEL: donde diga el script
				if (level_warped) {
					n_pant = warp_pant;
					set_player_at (warp_x << 4, warp_y << 4);
					#ifdef DIE_AND_RESPAWN
						p_safe_pant = warp_pant; p_safe_x = warp_x; p_safe_y = warp_y;
					#endif
					level_warped = 0;
				}
			#endif

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
			success = LEVEL_FAILED;
			objs_old = keys_old = life_old = killed_old = 0xff;
			#ifdef PLAYER_SHOW_FLAG
				flag_old = 0xff;
			#endif
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
			#ifdef COMPRESSED_LEVELS
				level_music = levels [level].music;
			#else
				level_music = 1;
			#endif
			play_level_music ();

			#ifdef HOOK_LEVEL_START
				hook_level_start ();
			#endif

			playing = 1;
			while (playing) {
				if (o_pant != n_pant) enter_screen ();
			
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

				#ifdef PLAYER_SHOW_FLAG
					// Un flag del script en el marcador (monedas...)
					if (flags [PLAYER_SHOW_FLAG] != flag_old) {
						print_number2 (FLAG_X, FLAG_Y, flags [PLAYER_SHOW_FLAG]);
						flag_old = flags [PLAYER_SHOW_FLAG];
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

				#ifdef PLAYER_CAN_PUNCH
					if (hitter_on) do_hitter ();
				#endif

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

				#ifdef ENABLE_COCOS
					move_cocos ();
				#endif

				#ifdef BREAKABLE_ANIM
					if (do_process_breakable) process_breakable ();
				#endif

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

				// Lo que el juego haga en cada frame (puede acabar el nivel:
				// playing = 0 y success = LEVEL_*)
				#ifdef HOOK_EACH_FRAME
					hook_each_frame ();
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

				#ifdef DIE_AND_RESPAWN
					if (p_killme) respawn ();
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

				// WARP TO LEVEL y GAME ENDING del script
				#if defined ACTIVATE_SCRIPTING && defined COMPRESSED_LEVELS
					if (script_result > 2) {
						success = script_result;
						playing = 0;
					}
				#endif
			}

			// Se espera a que se suelten las teclas, salvo al saltar a otro
			// nivel (WARP TO LEVEL): se sigue jugando sin pararse.
			#ifdef COMPRESSED_LEVELS
				if (success != LEVEL_WARP)
			#endif
			sp_WaitForNoKey ();

			#ifdef HAS_AY_MUSIC
				wyz_stop_sound ();
			#endif

			saca_a_todo_el_mundo_de_aqui ();
			sp_UpdateNow ();

			#ifdef COMPRESSED_LEVELS
				if (success == LEVEL_WARP) {
					// Al nivel que dice el script, en su pantalla y su tile
					level = warp_to_level;
					level_warped = 1;
				} else if (success == LEVEL_GAME_ENDING) {
					// El script termina el juego
					mlplaying = 0;
					#ifdef HOOK_GAME_ENDING
						hook_game_ending ();
					#else
						game_ending ();
					#endif
				} else if (success == LEVEL_REPEAT) {
					// Se vuelve a empezar el nivel (lo pide un gancho)
				} else
			#endif
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
