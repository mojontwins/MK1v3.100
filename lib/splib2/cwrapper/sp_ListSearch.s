; sp_ListSearch (envoltorio __smallc para SDCC)
; void * sp_ListSearch (struct sp_List *list, void *match, void *item1)

	.module sp_ListSearch
	.globl _sp_ListSearch
	.globl __sp_ixsave

	.area _CODE

_sp_ListSearch::
	ld (__sp_ixsave), ix

	.globl SPListSearch

	ld hl, #2
	add hl, sp
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl
	ld c, (hl)
	inc hl
	ld b, (hl)
	inc hl
	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a
	call SPListSearch
	ccf
	ex de, hl
	jp nc, __sp_ListSearch_ret
	ld hl, #0

__sp_ListSearch_ret:
	ld ix, (__sp_ixsave)
	ret
