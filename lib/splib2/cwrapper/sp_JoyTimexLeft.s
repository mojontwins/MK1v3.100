; sp_JoyTimexLeft (envoltorio __smallc para SDCC)
; uchar sp_JoyTimexLeft (void)

	.module sp_JoyTimexLeft
	.globl _sp_JoyTimexLeft
	.globl __sp_ixsave

	.area _CODE

_sp_JoyTimexLeft::
	ld (__sp_ixsave), ix

	.globl SPJoyTimexLeft

	call SPJoyTimexLeft
	ld l, a
	ld h, #0

__sp_JoyTimexLeft_ret:
	ld ix, (__sp_ixsave)
	ret
