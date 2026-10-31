; sp_Invalidate (envoltorio __smallc para SDCC)
; void sp_Invalidate (struct sp_Rect *area, struct sp_Rect *clip)

	.module sp_Invalidate
	.globl _sp_Invalidate
	.globl __sp_ixsave

	.area _CODE

_sp_Invalidate::
	ld (__sp_ixsave), ix

	.globl sp_fixcliprect
	.globl SPInvalidate
	.globl SPInvalidateP

	ld hl, #2
	add hl, sp

	ld iy, #-4
	add iy, sp
	ld sp, iy

	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl
	call sp_fixcliprect

	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a
	ld b, (hl)
	inc hl
	ld c, (hl)
	inc hl
	ld d, (hl)
	inc hl
	ld e, (hl)

	call SPInvalidateP
	pop hl
	pop hl

__sp_Invalidate_ret:
	ld ix, (__sp_ixsave)
	ret
