; sp_PixelRight (envoltorio __smallc para SDCC)
; void * sp_PixelRight (void *scrnaddr, uchar *mask)

	.module sp_PixelRight
	.globl _sp_PixelRight
	.globl __sp_ixsave

	.area _CODE

_sp_PixelRight::
	ld (__sp_ixsave), ix

	.globl SPPixelRight

	ld hl, #2
	add hl, sp
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl
	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a
	ld a, (de)
	ld b, a
	push de
	call SPPixelRight
	pop de
	ld a, b
	ld (de), a

__sp_PixelRight_ret:
	ld ix, (__sp_ixsave)
	ret
