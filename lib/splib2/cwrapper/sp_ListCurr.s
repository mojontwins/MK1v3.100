; sp_ListCurr (envoltorio __smallc para SDCC)
; void * sp_ListCurr (struct sp_List *list)

	.module sp_ListCurr
	.globl _sp_ListCurr
	.globl __sp_ixsave

	.area _CODE

_sp_ListCurr::
	ld (__sp_ixsave), ix

	.globl SPListCurr

	ld hl, #2
	add hl, sp
	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a
	call SPListCurr
	ccf
	ex de, hl
	jp nc, __sp_ListCurr_ret
	ld hl, #0

__sp_ListCurr_ret:
	ld ix, (__sp_ixsave)
	ret
