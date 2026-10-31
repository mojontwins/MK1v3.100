; sp_UpdateNow (envoltorio __smallc para SDCC)
; void sp_UpdateNow (void)

	.module sp_UpdateNow
	.globl _sp_UpdateNow
	.globl __sp_ixsave

	.area _CODE

_sp_UpdateNow::
	ld (__sp_ixsave), ix

	.globl SPUpdateNow

	call SPUpdateNow

__sp_UpdateNow_ret:
	ld ix, (__sp_ixsave)
	ret
