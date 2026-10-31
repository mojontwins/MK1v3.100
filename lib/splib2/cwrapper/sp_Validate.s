; sp_Validate (envoltorio __smallc para SDCC)
; void sp_Validate (struct sp_Rect *area, struct sp_Rect *clip)

	.module sp_Validate
	.globl _sp_Validate
	.globl __sp_ixsave

	.area _CODE

_sp_Validate::
	ld (__sp_ixsave), ix

	.globl sp_fixcliprect
	.globl SPValidate
	.globl SPValidateP

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

	call SPValidateP
	pop hl
	pop hl

__sp_Validate_ret:
	ld ix, (__sp_ixsave)
	ret
