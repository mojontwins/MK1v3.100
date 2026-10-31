; sp_JoyKempston (envoltorio __smallc para SDCC)
; uchar sp_JoyKempston (void)

	.module sp_JoyKempston
	.globl _sp_JoyKempston
	.globl __sp_ixsave

	.area _CODE

_sp_JoyKempston::
	ld (__sp_ixsave), ix

	.globl SPJoyKempston

	call SPJoyKempston
	ld l, a
	ld h, #0

__sp_JoyKempston_ret:
	ld ix, (__sp_ixsave)
	ret
