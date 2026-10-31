; sp_ClearRect (envoltorio __smallc para SDCC)
; void sp_ClearRect (struct sp_Rect *area, uchar colour, uchar graphic, uchar affect)

	.module sp_ClearRect
	.globl _sp_ClearRect
	.globl __sp_ixsave

	.area _CODE

_sp_ClearRect::
	ld (__sp_ixsave), ix

	.globl SPClearRect
	.globl SPClearRectP

	ld hl, #2
	add hl, sp
	ld a, (hl)
	inc hl
	inc hl
	ex af, af
	ld e, (hl)
	inc hl
	inc hl
	ld d, (hl)
	inc hl
	inc hl

	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a; hl = area

	ld b, (hl)
	inc hl
	ld c, (hl)
	inc hl
	ld a, (hl)
	inc hl
	ld l, (hl)
	ld h, b
	ld b, a
	ld a, c
	ld c, l
	ld l, a

	call SPClearRectP

__sp_ClearRect_ret:
	ld ix, (__sp_ixsave)
	ret
