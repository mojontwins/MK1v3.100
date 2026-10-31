; sp_InitAlloc (envoltorio __smallc para SDCC)
; void sp_InitAlloc (void)

	.module sp_InitAlloc
	.globl _sp_InitAlloc
	.globl __sp_ixsave

	.area _CODE

_sp_InitAlloc::
	ld (__sp_ixsave), ix

	.globl SPInitAlloc

	call SPInitAlloc

__sp_InitAlloc_ret:
	ld ix, (__sp_ixsave)
	ret
