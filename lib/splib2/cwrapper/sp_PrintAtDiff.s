; sp_PrintAtDiff (envoltorio __smallc para SDCC)
; void sp_PrintAtDiff (uchar row, uchar col, uchar colour, uchar graphic)

	.module sp_PrintAtDiff
	.globl _sp_PrintAtDiff
	.globl __sp_ixsave

	.area _CODE

_sp_PrintAtDiff::
	ld (__sp_ixsave), ix

	.globl SPPrintAtDiff

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
	call SPPrintAtDiff

__sp_PrintAtDiff_ret:
	ld ix, (__sp_ixsave)
	ret
