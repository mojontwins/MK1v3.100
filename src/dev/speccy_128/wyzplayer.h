// La Churrera Engine 3.100
// Copyleft 2010-2014 the Mojon Twins

// WYZ player hook functions

// WYZ player and songs are loaded into RAM 1 ($C000).
// In each interrupt, we just page in RAM 1, call the player,
// then page back RAM 0 and exit.

// The player is, thus, compiled to $C000, and its addresses
// are:

// comp-zx.sh ensambla speccy_128/wyz/wyzplayer.asm y genera wyz_addrs.h con
// WYZPLAYERINIT, WYZPLAYERISR, INICIAEFECTO, CARGA_CANCION y SILENCIA_PLAYER
// a partir de su tabla de símbolos.
#include "wyz_addrs.h"

// Start.

// La ISR: cuenta frames (sincronía) y llama al WYZ player con la RAM 1
// puesta. Como en 48K (speccy/isr.h), los 2 primeros bytes son el enlace de
// la lista de hooks de splib2 e ISR_HOOK es la dirección del código.
void isr_hook (void) __naked {
	__asm
		.dw 0
		ld hl, #_isr_frames
		inc (hl)
		ld b, #1
		call SetRAMBank
		call WYZPLAYERISR
		ld b, #0
		call SetRAMBank
		or a					; acarreo a 0: sigue con los demás hooks
		ret
	__endasm;
}

#define ISR_HOOK	((void *) ((unsigned char *) isr_hook + 2))

void wyz_init (void) __naked {
	__asm
		ld b, #1
		call SetRAMBank
		call WYZPLAYERINIT
		ld b, #0
		jp SetRAMBank
	__endasm;
}

// El número de efecto llega en A (convención de SDCC para un argumento de 8 bits).
void wyz_play_sound (unsigned char fx_number) __naked {
	(void) fx_number;
	__asm
		di
		push af
		ld b, #1
		call SetRAMBank
		pop bc					; B = número de efecto
		call INICIAEFECTO
		ld b, #0
		call SetRAMBank
		ei
		ret
	__endasm;
}

// La canción llega en A.
void wyz_play_music (unsigned char song_number) __naked {
	(void) song_number;
	__asm
		di
		push af
		ld b, #1
		call SetRAMBank
		pop af
		call CARGA_CANCION
		ld b, #0
		call SetRAMBank
		ei
		ret
	__endasm;
}

void wyz_stop_sound (void) __naked {
	__asm
		di
		ld b, #1
		call SetRAMBank
		call SILENCIA_PLAYER
		ld b, #0
		call SetRAMBank
		ei
		ret
	__endasm;
}

// Sample (extra.asm del juego con PLAY_SAMPLE): se toca con las
// interrupciones deshabilitadas. El número de sample llega en A.
#ifdef WYZ_PLAY_SAMPLE
	void wyz_play_sample (unsigned char sample_number) __naked {
		(void) sample_number;
		__asm
			di
			push af
			ld b, #1
			call SetRAMBank
			pop af
			push ix
			push iy
			call WYZ_PLAY_SAMPLE
			pop iy
			pop ix
			ld b, #0
			call SetRAMBank
			ei
			ret
		__endasm;
	}
#endif
