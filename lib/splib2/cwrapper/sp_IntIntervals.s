; sp_IntIntervals (envoltorio __smallc para SDCC)
; int sp_IntIntervals (struct sp_Interval *i1, struct sp_Interval *i2, struct sp_Interval *result)

	.module sp_IntIntervals
	.globl _sp_IntIntervals
	.globl __sp_ixsave

	.area _CODE

_sp_IntIntervals::
	ld (__sp_ixsave), ix

	.globl SPIntIvals

	pop bc
	pop hl
	pop iy
	pop ix
	push hl
	push hl
	push hl
	push bc
	push hl
	call SPIntIvals
	pop hl
	ld (hl), c
	inc hl
	ld (hl), b
	inc hl
	ld (hl), e
	inc hl
	ld (hl), d
	ld hl, #0
	jp c, __sp_IntIntervals_ret
	inc l

__sp_IntIntervals_ret:
	ld ix, (__sp_ixsave)
	ret
