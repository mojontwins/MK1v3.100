; sp_PixelUp (envoltorio __smallc para SDCC)
; void * sp_PixelUp (void *scrnaddr)

	.module sp_PixelUp
	.globl _sp_PixelUp
	.globl __sp_ixsave

	.area _CODE

_sp_PixelUp::
	ld (__sp_ixsave), ix

	.globl SPPixelUp

	ld hl, #2
	add hl, sp
	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a
	call SPPixelUp

__sp_PixelUp_ret:
	ld ix, (__sp_ixsave)
	ret
