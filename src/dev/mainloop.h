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

	// [v3.100] Ganchos (hooks): funciones opcionales que define cada juego en
	// custom.h. Cada una se activa definiendo su HOOK_*. Ver custom.h.
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
					// [v3.100] RES_MARCO lo genera librarian (antes, un 1 fijo)
					get_resource (RES_MARCO, 16384);
				#else
					unpack_screen (s_marco);
				#endif
			#endif

			// Let's do it.

			init_player ();

			// [v3.100] Con niveles, hotspots, cerrojos y enemigos vienen nuevos en
			// el bundle; aun así init_malotes hace falta para fijar su vida.
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
				script_result = 0;
				msc_init_all ();

				// Entering game
				script = e_scripts [MAP_W * MAP_H];
				run_script ();
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

			// [FIX v3.100] x_pant / y_pant se calculaban antes de cargar el
			// checkpoint, que cambia n_pant.
			#ifdef PLAYER_CHECK_MAP_BOUNDARIES
				x_pant = n_pant % LEVEL_MAP_W;
				y_pant = n_pant / LEVEL_MAP_W;
			#endif

			// [v3.100] La música estaba comentada en 128K.
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

			#ifdef MSC_MAXITEMS
				display_items ();
			#endif

			#ifdef HOOK_LEVEL_START
				hook_level_start ();
			#endif

			playing = 1;
			while (playing) {
				if (o_pant != n_pant) {
					draw_scr ();
					o_pant = n_pant;
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

					#if defined(TIMER_SCRIPT_0) && defined(ACTIVATE_SCRIPTING)
						if (ctimer.zero) {
							ctimer.zero = 0;
							#ifdef SHOW_TIMER_OVER
								saca_a_todo_el_mundo_de_aqui ();
								time_over ();
							#endif
							script = e_scripts [MAP_W * MAP_H + 2];
							run_script ();	
						}	
					#endif

					#ifdef TIMER_KILL_0
						if (ctimer.zero) {
							#ifdef SHOW_TIMER_OVER
								#ifndef TIMER_SCRIPT_0
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

				#ifndef DEACTIVATE_OBJECTS
					if (player.objs != objs_old) {
						draw_objs ();
						objs_old = player.objs;
					}
				#endif
			
				if (player.life != life_old) {
					print_number2 (LIFE_X, LIFE_Y, player.life);
					life_old = player.life;
				}
			
				#ifndef DEACTIVATE_KEYS
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

				#ifdef MAX_AMMO 	
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
						if (gpx >= fzx1 && gpx <= fzx2 && gpy >= fzy1 && gpy <= fzy2) {
							run_fire_script ();
						}	
					}
				#endif			

				// Update to screen
				sp_UpdateNow();

				// [v3.100] Sincronía de frames (en CPC la hace sp_UpdateNow)
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
				
				// Select object
				#if defined ACTIVATE_SCRIPTING 

					#if defined MSC_MAXITEMS
						if (sp_KeyPressed (KEY_Z)) {
							if (!key_z_pressed) {
								PLAY_SFX (2);
								flags [FLAG_SLOT_SELECTED] = (flags [FLAG_SLOT_SELECTED] + 1) % MSC_MAXITEMS;
								display_items ();
							}
							key_z_pressed = 1;
						} else {
							key_z_pressed = 0;
						}
					#endif			

					if (
						#if defined SCRIPTING_KEY_M			
							sp_KeyPressed (KEY_M)
						#elif defined SCRIPTING_DOWN
							(pad_this_frame & sp_DOWN) == 0
						#else
							(pad_this_frame & sp_FIRE) == 0
						#endif
					) {
						// Any scripts to run in this screen?
						run_fire_script ();
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
						// [FIX v3.100] Ponía key_h (en minúsculas), que no existe.
						while (!sp_KeyPressed (KEY_H));
						sp_WaitForNoKey ();
						redraw_scr ();		// [FIX v3.100] antes draw_scr ()
						
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
				
				// [v3.100] Todos los cambios de pantalla usan LEVEL_MAP_W / H, que con
				// niveles es el tamaño del mapa del nivel actual. Antes había una
				// mezcla de MAP_W y level_data->map_w (MAP_BOTTOM_KILLS y el paso hacia
				// arriba usaban siempre MAP_W).
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
						player.x = 14336; gpx = 224;
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
						player.y = 9216; gpy = 144;
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
							if (player.vy > 256) player.vy = 256;
						}
					}
				}


				// Win game condition
				// [FIX v3.100] LEVEL_MAX_OBJS, LEVEL_FIN_X / Y: con niveles dependen del nivel.
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
