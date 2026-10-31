; sp_InstallISR (envoltorio __smallc para SDCC)
; void * sp_InstallISR (uchar vector, void *isr)

	.module sp_InstallISR
	.globl _sp_InstallISR
	.globl __sp_ixsave

	.area _CODE

_sp_InstallISR::
	ld (__sp_ixsave), ix

	.globl SPInstallISR

	ld hl, #2
	add hl, sp
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl
	ld l, (hl)
	call SPInstallISR
	ex de, hl

__sp_InstallISR_ret:
	ld ix, (__sp_ixsave)
	ret
