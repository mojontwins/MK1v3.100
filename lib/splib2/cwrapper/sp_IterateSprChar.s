; sp_IterateSprChar (envoltorio __smallc para SDCC)
; void sp_IterateSprChar (struct sp_SS *sprite, void *hook)

	.module sp_IterateSprChar
	.globl _sp_IterateSprChar
	.globl __sp_ixsave

	.area _CODE

_sp_IterateSprChar::
	ld (__sp_ixsave), ix

	.globl SPIterateSprChar

	pop hl
	pop iy
	pop ix
	push ix
	push iy
	push hl
	call SPIterateSprChar

__sp_IterateSprChar_ret:
	ld ix, (__sp_ixsave)
	ret
