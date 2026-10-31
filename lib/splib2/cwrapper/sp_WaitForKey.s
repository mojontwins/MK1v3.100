; sp_WaitForKey (envoltorio __smallc para SDCC)
; void sp_WaitForKey (void)

	.module sp_WaitForKey
	.globl _sp_WaitForKey
	.globl __sp_ixsave

	.area _CODE

_sp_WaitForKey::
	ld (__sp_ixsave), ix

	.globl SPWaitForKey

	call SPWaitForKey

__sp_WaitForKey_ret:
	ld ix, (__sp_ixsave)
	ret
