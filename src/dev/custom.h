// La Churrera Engine 3.100
// Copyleft 2010-2014, 2026 the Mojon Twins

// custom.h
// Código propio del juego y ganchos (hooks) del bucle principal.

// Aquí va todo lo que un juego añade al motor sin tocarlo: pantallas
// de presentación de nivel, cinemáticas, menús, efectos... El motor llama a
// estas funciones desde mainloop.h solo si se define su HOOK_*, así que un
// gancho que no se usa no ocupa nada.
//
// Se incluye después de engine.h: se puede usar cualquier función o variable
// del motor (print_str, draw_coloured_tile, get_resource, level, n_pant...).
//
// Ganchos disponibles (todos opcionales):
//
//   HOOK_GAME_INIT        void hook_game_init (void)
//                         Una vez, al arrancar, tras system_init ().
//
//   HOOK_AFTER_TITLE      unsigned char hook_after_title (void)
//                         Tras la pantalla de título. Con COMPRESSED_LEVELS
//                         devuelve el nivel por el que empezar (menús,
//                         contraseñas...); sin niveles se ignora lo devuelto.
//
//   HOOK_LEVEL_INTRO      void hook_level_intro (void)
//                         Sustituye a la pantalla "LEVEL XX" antes de cada
//                         nivel (solo COMPRESSED_LEVELS). El nivel está en
//                         "level". Se llama antes de cargar el nivel, así que
//                         se puede usar la pantalla y el tileset libremente.
//
//   HOOK_LEVEL_START      void hook_level_start (void)
//                         Con el nivel ya cargado e inicializado, justo
//                         antes de empezar a jugar.
//
//   HOOK_ENTERING_SCREEN  void hook_entering_screen (void)
//                         Cada vez que se entra en una pantalla, tras
//                         dibujarla (n_pant es la nueva pantalla).
//
//   HOOK_WIN_CONDITION    unsigned char hook_win_condition (void)
//                         Cada frame: devuelve distinto de 0 si se ha superado
//                         el nivel (o el juego). Sustituye a la condición
//                         normal (todos los objetos y, si la hay, la casilla
//                         final). WIN GAME del script sigue funcionando.
//
//   HOOK_LEVEL_END        void hook_level_end (void)
//                         Al superar un nivel (o el juego, sin niveles).
//
//   HOOK_GAME_OVER        void hook_game_over (void)
//                         Sustituye a game_over ().
//
//   HOOK_GAME_ENDING      void hook_game_ending (void)
//                         Sustituye a game_ending () al terminar el juego.
//
// Ejemplo:
//
//   #define HOOK_LEVEL_START
//   void hook_level_start (void) {
//       print_str (VIEWPORT_X + 9, VIEWPORT_Y + 9, 71, "GET READY!");
//       sp_UpdateNow ();
//       espera_activa (50);
//   }

// Bootee no usa ningún gancho.
