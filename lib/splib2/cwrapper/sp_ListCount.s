; sp_ListCount (envoltorio __smallc para SDCC)
; uint sp_ListCount (struct sp_List *list)

	.module sp_ListCount
	.globl _sp_ListCount
	.globl __sp_ixsave

	.area _CODE

_sp_ListCount::
	ld (__sp_ixsave), ix

	.globl SPListCount

	ld hl, #2
	add hl, sp
	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a
	call SPListCount
	ex de, hl

__sp_ListCount_ret:
	ld ix, (__sp_ixsave)
	ret
