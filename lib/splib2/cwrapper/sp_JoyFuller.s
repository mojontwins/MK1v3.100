; sp_JoyFuller (envoltorio __smallc para SDCC)
; uchar sp_JoyFuller (void)

	.module sp_JoyFuller
	.globl _sp_JoyFuller
	.globl __sp_ixsave

	.area _CODE

_sp_JoyFuller::
	ld (__sp_ixsave), ix

	.globl SPJoyFuller

	call SPJoyFuller
	ld l, a
	ld h, #0

__sp_JoyFuller_ret:
	ld ix, (__sp_ixsave)
	ret
