; sp_CreateGenericISR (envoltorio __smallc para SDCC)
; void * sp_CreateGenericISR (void *addr)

	.module sp_CreateGenericISR
	.globl _sp_CreateGenericISR
	.globl __sp_ixsave

	.area _CODE

_sp_CreateGenericISR::
	ld (__sp_ixsave), ix

	.globl SPCreateGenericISR

	pop hl
	pop de
	push de
	push hl
	call SPCreateGenericISR
	ex de, hl

__sp_CreateGenericISR_ret:
	ld ix, (__sp_ixsave)
	ret
