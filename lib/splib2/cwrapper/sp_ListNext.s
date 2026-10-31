; sp_ListNext (envoltorio __smallc para SDCC)
; void * sp_ListNext (struct sp_List *list)

	.module sp_ListNext
	.globl _sp_ListNext
	.globl __sp_ixsave

	.area _CODE

_sp_ListNext::
	ld (__sp_ixsave), ix

	.globl SPListNext

	ld hl, #2
	add hl, sp
	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a
	call SPListNext
	ccf
	ex de, hl
	jp nc, __sp_ListNext_ret
	ld hl, #0

__sp_ListNext_ret:
	ld ix, (__sp_ixsave)
	ret
