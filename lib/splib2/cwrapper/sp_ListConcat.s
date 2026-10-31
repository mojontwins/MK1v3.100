; sp_ListConcat (envoltorio __smallc para SDCC)
; void sp_ListConcat (struct sp_List *list1, struct sp_List *list2)

	.module sp_ListConcat
	.globl _sp_ListConcat
	.globl __sp_ixsave

	.area _CODE

_sp_ListConcat::
	ld (__sp_ixsave), ix

	.globl SPListConcat

	ld hl, #2
	add hl, sp
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl
	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a
	ex de, hl
	call SPListConcat

__sp_ListConcat_ret:
	ld ix, (__sp_ixsave)
	ret
