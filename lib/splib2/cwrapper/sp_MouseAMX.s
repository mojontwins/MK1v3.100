; sp_MouseAMX (envoltorio __smallc para SDCC)
; void sp_MouseAMX (uint *xcoord, uchar *ycoord, uchar *buttons)

	.module sp_MouseAMX
	.globl _sp_MouseAMX
	.globl __sp_ixsave

	.area _CODE

_sp_MouseAMX::
	ld (__sp_ixsave), ix

	.include "SPconfig.inc"
	.globl SPMouseAMX

	ld hl, #2
	add hl, sp
	push hl
	call SPMouseAMX
	ld a, e; a = buttons
	ld c, l
	ld b, h; bc = pixel coords, carry=+256 to x coord
	pop hl
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl
	ld (de), a
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl
	ld a, b
	ld (de), a
	ld e, (hl)
	inc hl
	ld d, (hl)
	ld a, c
	ld (de), a
	inc de
	ld a, #0
	.if DISP_HIRES
	adc a, #0
	.endif
	ld (de), a

__sp_MouseAMX_ret:
	ld ix, (__sp_ixsave)
	ret
