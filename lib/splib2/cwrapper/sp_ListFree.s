; sp_ListFree (envoltorio __smallc para SDCC)
; void sp_ListFree (struct sp_List *list, void *freeitem)

	.module sp_ListFree
	.globl _sp_ListFree
	.globl __sp_ixsave

	.area _CODE

_sp_ListFree::
	ld (__sp_ixsave), ix

	.globl SPListFree

	ld hl, #2
	add hl, sp
	ld c, (hl)
	inc hl
	ld b, (hl)
	inc hl
	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a
	call SPListFree

__sp_ListFree_ret:
	ld ix, (__sp_ixsave)
	ret
