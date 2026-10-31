; sp_ListLast (envoltorio __smallc para SDCC)
; void * sp_ListLast (struct sp_List *list)

	.module sp_ListLast
	.globl _sp_ListLast
	.globl __sp_ixsave

	.area _CODE

_sp_ListLast::
	ld (__sp_ixsave), ix

	.globl SPListLast

	ld hl, #2
	add hl, sp
	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a
	call SPListLast
	ccf
	ex de, hl
	jp nc, __sp_ListLast_ret
	ld hl, #0

__sp_ListLast_ret:
	ld ix, (__sp_ixsave)
	ret
