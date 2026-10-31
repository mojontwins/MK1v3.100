; sp_Inkey (envoltorio __smallc para SDCC)
; uchar sp_Inkey (void)

	.module sp_Inkey
	.globl _sp_Inkey
	.globl __sp_ixsave

	.area _CODE

_sp_Inkey::
	ld (__sp_ixsave), ix

	.globl SPGetKey
	.globl SPInkey

	call SPInkey
	jr c, sp_Inkey_keyok
	xor a

sp_Inkey_keyok:
	ld l, a
	ld h, #0
	ccf

__sp_Inkey_ret:
	ld ix, (__sp_ixsave)
	ret
