; sp_RemoveDList (envoltorio __smallc para SDCC)
; void sp_RemoveDList (struct sp_SS *sprite)

	.module sp_RemoveDList
	.globl _sp_RemoveDList
	.globl __sp_ixsave

	.area _CODE

_sp_RemoveDList::
	ld (__sp_ixsave), ix

	.globl SPRemoveDList

	ld hl, #2
	add hl, sp
	ld e, (hl)
	inc hl
	ld d, (hl)
	.db 0xdd
	ld l, e
	.db 0xdd
	ld h, d
	call SPRemoveDList

__sp_RemoveDList_ret:
	ld ix, (__sp_ixsave)
	ret
