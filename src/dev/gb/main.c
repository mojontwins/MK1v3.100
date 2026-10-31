// La Churrera Engine 3.100 - Game Boy
// Copyleft 2026 the Mojon Twins

// gb/main.c
// Etapa 1 del port: arranque, título y final con fundidos (prueba).

#pragma bank 1

#include "mk1gb.h"
#include "../librarian.h"

void main_banked (void) BANKED {
	while (1) {
		gb_show_screen (RES_TITLE);
		waitpad (J_START);
		waitpadup ();
		gb_show_screen (RES_ENDING);
		waitpad (J_START);
		waitpadup ();
	}
}
