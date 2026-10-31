; sp_JoyTimexEither (envoltorio __smallc para SDCC)
; uchar sp_JoyTimexEither (void)

	.module sp_JoyTimexEither
	.globl _sp_JoyTimexEither
	.globl __sp_ixsave

	.area _CODE

_sp_JoyTimexEither::
	ld (__sp_ixsave), ix

	.globl SPJoyTimexEither

	call SPJoyTimexEither
	ld l, a
	ld h, #0

__sp_JoyTimexEither_ret:
	ld ix, (__sp_ixsave)
	ret
