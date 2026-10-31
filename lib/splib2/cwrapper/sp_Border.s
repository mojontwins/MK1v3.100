; sp_Border (envoltorio __smallc para SDCC)
; void sp_Border (uchar colour)

	.module sp_Border
	.globl _sp_Border
	.globl __sp_ixsave

	.area _CODE

_sp_Border::
	ld (__sp_ixsave), ix

	.globl SPBorder

	ld hl, #2
	add hl, sp
	ld a, (hl)
	call SPBorder

__sp_Border_ret:
	ld ix, (__sp_ixsave)
	ret
