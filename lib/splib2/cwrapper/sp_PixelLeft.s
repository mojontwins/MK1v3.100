; sp_PixelLeft (envoltorio __smallc para SDCC)
; void * sp_PixelLeft (void *scrnaddr, uchar *mask)

	.module sp_PixelLeft
	.globl _sp_PixelLeft
	.globl __sp_ixsave

	.area _CODE

_sp_PixelLeft::
	ld (__sp_ixsave), ix

	.globl SPPixelLeft

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
	call SPPixelLeft
	pop de
	ld a, b
	ld (de), a

__sp_PixelLeft_ret:
	ld ix, (__sp_ixsave)
	ret
