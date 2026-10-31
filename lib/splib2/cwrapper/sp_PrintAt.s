; sp_PrintAt (envoltorio __smallc para SDCC)
; void sp_PrintAt (uchar row, uchar col, uchar colour, uchar graphic)

	.module sp_PrintAt
	.globl _sp_PrintAt
	.globl __sp_ixsave

	.area _CODE

_sp_PrintAt::
	ld (__sp_ixsave), ix

	.globl SPPrintAt

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
	call SPPrintAt

__sp_PrintAt_ret:
	ld ix, (__sp_ixsave)
	ret
