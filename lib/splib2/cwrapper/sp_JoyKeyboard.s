; sp_JoyKeyboard (envoltorio __smallc para SDCC)
; uchar sp_JoyKeyboard (struct sp_UDK *keys)

	.module sp_JoyKeyboard
	.globl _sp_JoyKeyboard
	.globl __sp_ixsave

	.area _CODE

_sp_JoyKeyboard::
	ld (__sp_ixsave), ix

	.globl SPJoyKeyboard

	ld hl, #2
	add hl, sp
	ld e, (hl)
	inc hl
	ld d, (hl)
	call SPJoyKeyboard
	ld l, a
	ld h, #0

__sp_JoyKeyboard_ret:
	ld ix, (__sp_ixsave)
	ret
