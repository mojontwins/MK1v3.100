; sp_GetKey (envoltorio __smallc para SDCC)
; uchar sp_GetKey (void)

	.module sp_GetKey
	.globl _sp_GetKey
	.globl __sp_ixsave

	.area _CODE

_sp_GetKey::
	ld (__sp_ixsave), ix

	.globl SPGetKey

	call SPGetKey
	jr c, sp_GetKey_keyok
	xor a

sp_GetKey_keyok:
	ld l, a
	ld h, #0
	ccf

__sp_GetKey_ret:
	ld ix, (__sp_ixsave)
	ret
