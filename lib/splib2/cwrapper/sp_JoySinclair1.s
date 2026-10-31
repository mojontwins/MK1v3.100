; sp_JoySinclair1 (envoltorio __smallc para SDCC)
; uchar sp_JoySinclair1 (void)

	.module sp_JoySinclair1
	.globl _sp_JoySinclair1
	.globl __sp_ixsave

	.area _CODE

_sp_JoySinclair1::
	ld (__sp_ixsave), ix

	.globl SPJoySinclair1

	call SPJoySinclair1
	ld l, a
	ld h, #0

__sp_JoySinclair1_ret:
	ld ix, (__sp_ixsave)
	ret
