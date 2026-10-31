; sp_PFill (envoltorio __smallc para SDCC)
; int sp_PFill (uint xcoord, uchar ycoord, void *pattern, uint stackdepth)

	.module sp_PFill
	.globl _sp_PFill
	.globl __sp_ixsave

	.area _CODE

_sp_PFill::
	ld (__sp_ixsave), ix

	.globl SPPFill

	ld hl, #2
	add hl, sp
	ld c, (hl)
	inc hl
	ld b, (hl)
	inc hl
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl; bc, de set up
	ld a, (hl); a = ycoord
	inc hl
	inc hl
	ex af, af
	inc hl
	ld a, (hl)
	rrca
	ex af, af; alternate carry set for top 256 pixels
	dec hl
	ld l, (hl); l = x coord
	ld h, a; h = y coord   
	call SPPFill
	ld hl, #1
	jp nc, __sp_PFill_ret
	dec l

__sp_PFill_ret:
	ld ix, (__sp_ixsave)
	ret
