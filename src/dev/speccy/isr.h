// La Churrera Engine 3.100
// Copyleft 2010-2014, 2026 the Mojon Twins

// isr.h
// [v3.100] ISR de 48K: solo cuenta frames para la sincronía (GAME_FRAME_TICKS).
// En 128K la ISR está en speccy_128/wyzplayer.h y además llama al WYZ player.

// splib2 guarda el enlace de la lista de "hooks" en los 2 bytes anteriores.
#asm
	defw 0
#endasm

void ISR (void) {
	isr_frames ++;
}
