// La Churrera Engine 3.100
// Copyleft 2010-2014, 2026 the Mojon Twins

// isr.h
// ISR de 48K: solo cuenta frames para la sincronía (GAME_FRAME_TICKS).
// En 128K la ISR está en speccy_128/wyzplayer.h y además llama al WYZ player.

// splib2 guarda el enlace de la lista de "hooks" en los 2 bytes anteriores al
// código del hook: isr_hook empieza por esos 2 bytes y el código está en
// ISR_HOOK (isr_hook + 2), que es lo que se registra con sp_RegisterHook.
void isr_hook (void) __naked {
	__asm
		.dw 0
		ld hl, #_isr_frames
		inc (hl)
		or a					; acarreo a 0: sigue con los demás hooks
		ret
	__endasm;
}

#define ISR_HOOK	((void *) ((unsigned char *) isr_hook + 2))
