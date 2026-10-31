; sp_EmptyISR (envoltorio __smallc para SDCC)
; void sp_EmptyISR (void)

	.module sp_EmptyISR
	.globl _sp_EmptyISR
	.globl __sp_ixsave

	.area _CODE

_sp_EmptyISR::
	ld (__sp_ixsave), ix

	.globl SPEmptyISR

	jp SPEmptyISR

__sp_EmptyISR_ret:
	ld ix, (__sp_ixsave)
	ret
