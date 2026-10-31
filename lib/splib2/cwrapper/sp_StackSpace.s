; sp_StackSpace (envoltorio __smallc para SDCC)
; int sp_StackSpace (void *addr)

	.module sp_StackSpace
	.globl _sp_StackSpace
	.globl __sp_ixsave

	.area _CODE

_sp_StackSpace::
	ld (__sp_ixsave), ix

	ld hl, #3
	add hl, sp
	ld d, (hl)
	dec hl
	ld e, (hl)
	or a
	sbc hl, de

__sp_StackSpace_ret:
	ld ix, (__sp_ixsave)
	ret
