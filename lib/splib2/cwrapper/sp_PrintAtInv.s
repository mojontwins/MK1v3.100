; sp_PrintAtInv (envoltorio __smallc para SDCC)
; void sp_PrintAtInv (uchar row, uchar col, uchar colour, uchar graphic)

	.module sp_PrintAtInv
	.globl _sp_PrintAtInv
	.globl __sp_ixsave

	.area _CODE

_sp_PrintAtInv::
	ld (__sp_ixsave), ix

	.globl SPPrintAtInv

	ld hl, #2
	add hl, sp
	ld e, (hl)
	inc hl
	inc hl
	ld d, (hl)
	inc hl
	inc hl
	ld c, (hl)
	inc hl
	inc hl
	ld a, (hl)
	call SPPrintAtInv

__sp_PrintAtInv_ret:
	ld ix, (__sp_ixsave)
	ret
