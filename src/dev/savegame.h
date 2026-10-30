// La Churrera Engine 3.100
// Copyleft 2010-2014 the Mojon Twins

// Savegame / checkpoint routines

// [FIX v3.100] Cambios en este archivo:
//  * Se incluye antes de engine.h (kill_player usa sg_saved y sg_pool).
//  * Funciona sin scripting: entonces no se guardan flags (SG_NFLAGS = 0).
//  * "sg_pool [sgit] = flags [sgit ++]" lee y modifica sgit en la misma
//    expresión: en C el orden no está definido. Ahora es un for normal.
//  * El menú imprimía las dos opciones en la misma línea y usaba sp_GetKey,
//    que no existe en CPC. Ahora usa 1 / 2 con sp_KeyPressed.
//  * Fuera los stubs vacíos tape_save / tape_load.

// Contenido de sg_pool:
// [0 .. SG_NFLAGS - 1]  flags
// [SG_NFLAGS + 0]       pantalla
// [SG_NFLAGS + 1]       x (en tiles)
// [SG_NFLAGS + 2]       y (en tiles)
// [SG_NFLAGS + 3]       munición
// [SG_NFLAGS + 4]       tiempo
unsigned char sg_pool [SG_NFLAGS + 5];
unsigned char sgit;
unsigned char sg_saved = 0;
unsigned char sg_do_load = 0;
unsigned char sg_level;

void clear_gamearea_tiles (void);

void mem_save (void) {
	sg_saved = 1;
	#ifdef ACTIVATE_SCRIPTING
		for (sgit = 0; sgit < SG_NFLAGS; sgit ++) sg_pool [sgit] = flags [sgit];
	#endif
	sg_pool [SG_NFLAGS] = n_pant;
	sg_pool [SG_NFLAGS + 1] = player.x >> 10;
	sg_pool [SG_NFLAGS + 2] = player.y >> 10;
	#ifdef MAX_AMMO
		sg_pool [SG_NFLAGS + 3] = player.ammo;
	#endif
	#ifdef TIMER_ENABLE
		sg_pool [SG_NFLAGS + 4] = ctimer.t;
	#endif
	#ifdef COMPRESSED_LEVELS
		sg_level = level;
	#endif
}

void mem_load (void) {
	#ifdef ACTIVATE_SCRIPTING
		for (sgit = 0; sgit < SG_NFLAGS; sgit ++) flags [sgit] = sg_pool [sgit];
	#endif
	n_pant = sg_pool [SG_NFLAGS];
	player.x = sg_pool [SG_NFLAGS + 1] << 10;
	player.y = sg_pool [SG_NFLAGS + 2] << 10;
	#ifdef MAX_AMMO
		player.ammo = sg_pool [SG_NFLAGS + 3];
	#endif
	#ifdef TIMER_ENABLE
		ctimer.t = sg_pool [SG_NFLAGS + 4];
	#endif
}

void sg_submenu (void) {
	sg_do_load = 0;
	if (sg_saved) {
		clear_gamearea_tiles ();
		print_str (VIEWPORT_X + 10, VIEWPORT_Y + 8, 71, "1 START");
		print_str (VIEWPORT_X + 10, VIEWPORT_Y + 10, 71, "2 CONTINUE");
		sp_UpdateNow ();
		while (1) {
			if (sp_KeyPressed (KEY_1)) break;
			if (sp_KeyPressed (KEY_2)) {
				sg_do_load = 1;
				break;
			}
		}
		sp_WaitForNoKey ();
	}
}
