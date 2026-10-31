; sp_ListFirst (envoltorio __smallc para SDCC)
; void * sp_ListFirst (struct sp_List *list)

	.module sp_ListFirst
	.globl _sp_ListFirst
	.globl __sp_ixsave

	.area _CODE

_sp_ListFirst::
	ld (__sp_ixsave), ix

	.globl SPListFirst

	ld hl, #2
	add hl, sp
	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a
	call SPListFirst
	ccf
	ex de, hl
	jp nc, __sp_ListFirst_ret
	ld hl, #0

__sp_ListFirst_ret:
	ld ix, (__sp_ixsave)
	ret
