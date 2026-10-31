; sp_MouseSim (envoltorio __smallc para SDCC)
; void sp_MouseSim (struct sp_UDM *m, uint *xcoord, uchar *ycoord, uchar *buttons)

	.module sp_MouseSim
	.globl _sp_MouseSim
	.globl __sp_ixsave

	.area _CODE

_sp_MouseSim::
	ld (__sp_ixsave), ix

	.include "SPconfig.inc"
	.globl SPMouseSim

	ld hl, #2
	add hl, sp
	push hl
	ld hl, #10
	add hl, sp
	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a; hl = UDM
	call SPMouseSim
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

__sp_MouseSim_ret:
	ld ix, (__sp_ixsave)
	ret
