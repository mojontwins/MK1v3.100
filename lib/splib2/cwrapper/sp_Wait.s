; sp_Wait (envoltorio __smallc para SDCC)
; void sp_Wait (uint ticks)

	.module sp_Wait
	.globl _sp_Wait
	.globl __sp_ixsave

	.area _CODE

_sp_Wait::
	ld (__sp_ixsave), ix

	.globl SPWait

	pop hl
	pop bc
	push bc
	push hl
	call SPWait

__sp_Wait_ret:
	ld ix, (__sp_ixsave)
	ret
