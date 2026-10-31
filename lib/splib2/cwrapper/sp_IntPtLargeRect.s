; sp_IntPtLargeRect (envoltorio __smallc para SDCC)
; int sp_IntPtLargeRect (uint x, uint y, struct sp_LargeRect *r)

	.module sp_IntPtLargeRect
	.globl _sp_IntPtLargeRect
	.globl __sp_ixsave

	.area _CODE

_sp_IntPtLargeRect::
	ld (__sp_ixsave), ix

	.globl SPPtInLargeRect

	pop bc
	pop ix
	pop hl
	pop de
	push de
	push hl
	push hl
	push bc
	call SPPtInLargeRect
	ld hl, #0
	jp c, __sp_IntPtLargeRect_ret
	inc l

__sp_IntPtLargeRect_ret:
	ld ix, (__sp_ixsave)
	ret
