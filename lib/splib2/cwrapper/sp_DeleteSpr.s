; sp_DeleteSpr (envoltorio __smallc para SDCC)
; void sp_DeleteSpr (struct sp_SS *sprite)

	.module sp_DeleteSpr
	.globl _sp_DeleteSpr
	.globl __sp_ixsave

	.area _CODE

_sp_DeleteSpr::
	ld (__sp_ixsave), ix

	.globl SPDeleteSpr

	ld hl, #2
	add hl, sp
	ld e, (hl)
	inc hl
	ld d, (hl)
	call SPDeleteSpr

__sp_DeleteSpr_ret:
	ld ix, (__sp_ixsave)
	ret
