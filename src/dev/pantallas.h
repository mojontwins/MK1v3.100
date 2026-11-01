// La Churrera Engine 3.100
// Copyleft 2010-2014 the Mojon Twins

// Pantallas.h
// Carga las pantallas fijas
// Copyleft 2010 The Mojon Twins

#if !defined MODE_128K && !defined GB
	extern const unsigned char s_title [];
	extern const unsigned char s_marco [];
	extern const unsigned char s_ending [];

	void pantallas_data (void) __naked {
		__asm
			_s_title:
			.incbin "title.bin"
			_s_marco:
			#ifndef DIRECT_TO_PLAY
			.incbin "marco.bin"
			#endif
			_s_ending:
			.incbin "ending.bin"
		__endasm;
	}
#endif

void title (void) {
	// Here the title screen
	sp_UpdateNow();
	blackout ();

	#ifdef GB
		gb_show_screen (RES_TITLE);
	#elif defined MODE_128K
		get_resource (RES_TITLE, 16384);
	#else		
		unpack_screen (s_title);
	#endif

	#ifdef CPC
		cpc_UpdScr ();
		cpc_ShowTileMap (1);
	#endif

	#ifdef HAS_AY_MUSIC
		wyz_play_music (TITLE_MUSIC);
	#endif

	// La música se para en mainloop (o en el gancho HOOK_AFTER_TITLE)
	select_joyfunc ();
}

void game_ending (void) {
	sp_UpdateNow();
	blackout ();

	#ifdef GB
		gb_show_screen (RES_ENDING);
	#elif defined MODE_128K
		get_resource (RES_ENDING, 16384);
	#else
		unpack_screen (s_ending);
	#endif

	#ifdef MODE_128K
	#else
		gpit = 4; do {
			PLAY_SFX (7);
			PLAY_SFX (2);
		} while (--gpit);
		PLAY_SFX (9);
	#endif
	
	espera_activa (500);
}

void recuadre (char *s) {
	#ifdef GB
		// En la ventana, debajo del marcador
		gb_win_open (3);
		print_str (4, 20 + GB_HUD_ROWS + 1, 79, s);
	#else
		print_str (10, 11, 79, spacer);
		print_str (10, 12, 79, s);
		print_str (10, 13, 79, spacer);
	#endif
}

void game_over (void) {
	recuadre (" GAME OVER! ");
	sp_UpdateNow ();

	#ifdef HAS_AY_MUSIC
		wyz_play_music (2);	
	#else
		gpit = 4; do {
			PLAY_SFX (7);
			PLAY_SFX (2);
		} while (--gpit);
		PLAY_SFX (9);
	#endif

	espera_activa (500);
}

#if defined(TIMER_ENABLE) && defined(SHOW_TIMER_OVER)
	void time_over (void) {
		recuadre (" TIME'S UP! ");
		sp_UpdateNow ();
			
		#ifdef MODE_128K
		#else
			gpit = 4; do {
				PLAY_SFX (1);
				PLAY_SFX (2);
			} while (--gpit);
			PLAY_SFX (0);
		#endif
			
		espera_activa (250);
		#ifdef GB
			gb_win_close ();
		#endif
	}
#endif

#ifdef PAUSE_ABORT
	void pause_screen (void) {
		recuadre ("   PAUSED   ");
		sp_UpdateNow ();
	}
#endif
