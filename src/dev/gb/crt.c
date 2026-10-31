// La Churrera Engine 3.100 - Game Boy
// Copyleft 2026 the Mojon Twins

// gb/crt.c
// main () en el banco 0: arranca el Game Boy y salta al motor (banco 1).

#include "mk1gb.h"

void main_banked (void) BANKED;

void main (void) {
	gb_init ();
	main_banked ();
}
