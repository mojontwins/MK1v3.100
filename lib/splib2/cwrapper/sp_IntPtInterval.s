; sp_IntPtInterval (envoltorio __smallc para SDCC)
; int sp_IntPtInterval (uint x, struct sp_Interval *i)

	.module sp_IntPtInterval
	.globl _sp_IntPtInterval
	.globl __sp_ixsave

	.area _CODE

_sp_IntPtInterval::
	ld (__sp_ixsave), ix

	.globl SPPtInIval

	pop bc
	pop hl
	ld c, (hl)
	inc hl
	ld b, (hl)
	inc hl
	ld e, (hl)
	inc hl
	ld d, (hl)
	pop hl
	push hl
	push hl
	push bc
	call SPPtInIval
	ld hl, #0
	jp c, __sp_IntPtInterval_ret
	inc l

__sp_IntPtInterval_ret:
	ld ix, (__sp_ixsave)
	ret
