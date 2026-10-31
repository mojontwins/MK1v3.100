; sp_IterateDList (envoltorio __smallc para SDCC)
; void sp_IterateDList (struct sp_Rect *r, void *hook)

	.module sp_IterateDList
	.globl _sp_IterateDList
	.globl __sp_ixsave

	.area _CODE

_sp_IterateDList::
	ld (__sp_ixsave), ix

	.globl SPIterateDList

	pop hl
	pop iy
	pop de
	push de
	push iy
	push hl
	ex de, hl
	ld a, (hl)
	inc hl
	ld c, (hl)
	inc hl
	ld e, (hl)
	inc hl
	ld d, (hl)
	call SPIterateDList

__sp_IterateDList_ret:
	ld ix, (__sp_ixsave)
	ret
