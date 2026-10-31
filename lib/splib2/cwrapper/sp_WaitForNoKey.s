; sp_WaitForNoKey (envoltorio __smallc para SDCC)
; void sp_WaitForNoKey (void)

	.module sp_WaitForNoKey
	.globl _sp_WaitForNoKey
	.globl __sp_ixsave

	.area _CODE

_sp_WaitForNoKey::
	ld (__sp_ixsave), ix

	.globl SPWaitForNoKey

	call SPWaitForNoKey

__sp_WaitForNoKey_ret:
	ld ix, (__sp_ixsave)
	ret
