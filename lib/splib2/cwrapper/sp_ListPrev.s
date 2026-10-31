; sp_ListPrev (envoltorio __smallc para SDCC)
; void * sp_ListPrev (struct sp_List *list)

	.module sp_ListPrev
	.globl _sp_ListPrev
	.globl __sp_ixsave

	.area _CODE

_sp_ListPrev::
	ld (__sp_ixsave), ix

	.globl SPListPrev

	ld hl, #2
	add hl, sp
	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a
	call SPListPrev
	ccf
	ex de, hl
	jp nc, __sp_ListPrev_ret
	ld hl, #0

__sp_ListPrev_ret:
	ld ix, (__sp_ixsave)
	ret
