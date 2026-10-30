// La Churrera Engine 3.100
// Copyleft 2010-2014 the Mojon Twins

// WYZ player hook functions

// WYZ player and songs are loaded into RAM 1 ($C000).
// In each interrupt, we just page in RAM 1, call the player,
// then page back RAM 0 and exit.

// The player is, thus, compiled to $C000, and its addresses
// are:

// [v3.100] Las direcciones ya no están escritas a mano: comp-zx.sh ensambla
// speccy_128/wyz/wyzplayer.asm y genera wyz_addrs.h con WYZPLAYERINIT,
// WYZPLAYERISR, INICIAEFECTO, CARGA_CANCION y SILENCIA_PLAYER a partir de su
// tabla de símbolos. Si cambian el reproductor o sus datos, siguen siendo válidas.
#include "wyz_addrs.h"

// Start.

// isr
#asm
	defw 0	// 2 bytes libres
#endasm

void ISR(void) {
	isr_frames ++;		// [v3.100] Sincronía de frames
	#asm
		ld b, 1
		call SetRAMBank
		call WYZPLAYERISR
		ld b, 0
		call SetRAMBank			
	#endasm
}

void wyz_init (void) {
	#asm
		ld b,1
		call SetRAMBank
		call WYZPLAYERINIT	
		ld b,0
		call SetRAMBank
	#endasm
}

void __FASTCALL__ wyz_play_sound (unsigned char fx_number) {
	#asm
		di
		ld b,1
		call SetRAMBank
		ld a, l
		ld b, a
		call INICIAEFECTO
		ld b,0
		call SetRAMBank
		ei
	#endasm
}

void __FASTCALL__ wyz_play_music (unsigned char song_number) {
	#asm
		di
		ld b, 1
		call SetRAMBank
		ld a, l
		call CARGA_CANCION
		ld b, 0
		call SetRAMBank
		ei
	#endasm
}

void wyz_stop_sound (void)
{
	#asm
		di
		ld b,1
		call SetRAMBank
		call SILENCIA_PLAYER
		ld b,0
		call SetRAMBank
		ei
	#endasm
}
