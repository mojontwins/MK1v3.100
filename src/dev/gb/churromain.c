// La Churrera Engine 3.100 - Game Boy
// Copyleft 2010-2014, 2026 the Mojon Twins

// gb/churromain.c
// El motor para Game Boy: lo mismo que churromain.c, con la capa del Game
// Boy (gb/sysvars.h, gb/printer.h) en lugar de la del Spectrum o el CPC.
//
// Se compila entero en el banco 1 (comp-gb: -Wf-bo1), que está siempre
// puesto: con el banco 0 (gb/home.c y GBDK) el motor ve 32K seguidos y no
// necesita llamadas entre bancos. Lo que lee de otros bancos (recursos,
// scripts, textos) lo hacen funciones del banco 0.

#include <string.h>
#include "mk1gb.h"

// Según la configuración, algunas funciones no usan todos sus argumentos o
// variables locales: el aviso 85 de SDCC no dice nada útil aquí.
#pragma disable_warning 85

// Funciones del motor que se usan antes de definirlas
unsigned char rand (void);

#include "../config.h"

// En Game Boy no hay modo 128K: los recursos van en bancos de ROM
#undef MODE_128K

// Lo que necesitan los scripts (generado por msc4)
#ifdef ACTIVATE_SCRIPTING
	#include "../msc-config.h"
#endif

// Constantes y banderas derivadas de config.h
#include "../config_derived.h"

#include "sysvars.h"
#include "../definitions.h"
#include "../librarian.h"

// ***********
// GAME ASSETS
// ***********

// Los gráficos van a la VRAM como recursos (RES_TILESET, RES_SPRITES y los
// de cada nivel). Datos de juego: con COMPRESSED_LEVELS vienen en el bundle
// de cada nivel; si no, de mapa.h y enems.h.
#ifdef COMPRESSED_LEVELS
	#include "../levels.h"
#else
	#include "../enems.h"
	#include "../mapa.h"
#endif

// Scripts (bytecode) y textos, generado por msc4
#ifdef ACTIVATE_SCRIPTING
	#include "../msc-scripts.h"
#endif

// **********
// HW BACKEND
// **********

#include "printer.h"
#include "../speccy/cell_arrays.h"

// ***********
// ENGINE
// ***********

#include "../pantallas.h"

#ifdef ENABLE_TILANIMS
	#include "../tilanim.h"
#endif

#ifdef ENABLE_CHECKPOINTS
	#include "../savegame.h"
#endif

#include "../engine.h"

// Código propio del juego y ganchos (hooks) del bucle principal.
#include "../custom.h"

// Intérprete de scripts
#ifdef ACTIVATE_SCRIPTING
	#if defined MSC_AU_E4 || defined MSC_AU_E6 || defined MSC_RV_E6
		#include "../extern.h"
	#endif
	#include "../msc.h"
#endif

#include "../mainloop.h"
