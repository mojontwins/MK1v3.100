; sp_JoySinclair2 (envoltorio __smallc para SDCC)
; uchar sp_JoySinclair2 (void)

	.module sp_JoySinclair2
	.globl _sp_JoySinclair2
	.globl __sp_ixsave

	.area _CODE

_sp_JoySinclair2::
	ld (__sp_ixsave), ix

	.globl SPJoySinclair2

	call SPJoySinclair2
	ld l, a
	ld h, #0

__sp_JoySinclair2_ret:
	ld ix, (__sp_ixsave)
	ret
