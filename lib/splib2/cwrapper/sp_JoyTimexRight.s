; sp_JoyTimexRight (envoltorio __smallc para SDCC)
; uchar sp_JoyTimexRight (void)

	.module sp_JoyTimexRight
	.globl _sp_JoyTimexRight
	.globl __sp_ixsave

	.area _CODE

_sp_JoyTimexRight::
	ld (__sp_ixsave), ix

	.globl SPJoyTimexRight

	call SPJoyTimexRight
	ld l, a
	ld h, #0

__sp_JoyTimexRight_ret:
	ld ix, (__sp_ixsave)
	ret
