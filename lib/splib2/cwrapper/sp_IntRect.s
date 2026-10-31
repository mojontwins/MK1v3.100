; sp_IntRect (envoltorio __smallc para SDCC)
; int sp_IntRect (struct sp_Rect *r1, struct sp_Rect *r2, struct sp_Rect *result)

	.module sp_IntRect
	.globl _sp_IntRect
	.globl __sp_ixsave

	.area _CODE

_sp_IntRect::
	ld (__sp_ixsave), ix

	.globl sp_fixcliprect
	.globl SPIntRect

	ld hl, #7
	add hl, sp

	ld iy, #-4; allocate a ClipStruct on stack
	add iy, sp
	ld sp, iy

	ld d, (hl)
	dec hl
	ld e, (hl); de = r1
	dec hl
	call sp_fixcliprect; converted to clip rect and stored at iy

	ld d, (hl)
	dec hl
	ld e, (hl); de = r2
	dec hl
	push hl
	ex de, hl
	ld b, (hl)
	inc hl
	ld c, (hl)
	inc hl
	ld d, (hl)
	inc hl
	ld e, (hl)

	call SPIntRect
	pop hl
	ld a, (hl)
	dec hl
	ld l, (hl)
	ld h, a; hl = result
	ld (hl), b
	inc hl
	ld (hl), c
	inc hl
	ld (hl), d
	inc hl
	ld (hl), e

	pop hl
	pop hl

	ld hl, #1
	jp nc, __sp_IntRect_ret
	dec l

__sp_IntRect_ret:
	ld ix, (__sp_ixsave)
	ret
