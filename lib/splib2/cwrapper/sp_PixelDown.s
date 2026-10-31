; sp_PixelDown (envoltorio __smallc para SDCC)
; void * sp_PixelDown (void *scrnaddr)

	.module sp_PixelDown
	.globl _sp_PixelDown
	.globl __sp_ixsave

	.area _CODE

_sp_PixelDown::
	ld (__sp_ixsave), ix

	.globl SPPixelDown

	ld hl, #2
	add hl, sp
	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a
	or a
	call SPPixelDown
	ccf

__sp_PixelDown_ret:
	ld ix, (__sp_ixsave)
	ret
