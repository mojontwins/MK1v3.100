; sp_RegisterHookFirst (envoltorio __smallc para SDCC)
; void sp_RegisterHookFirst (uchar vector, void *hook)

	.module sp_RegisterHookFirst
	.globl _sp_RegisterHookFirst
	.globl __sp_ixsave

	.area _CODE

_sp_RegisterHookFirst::
	ld (__sp_ixsave), ix

	.globl SPRegisterHookFirst

	ld hl, #2
	add hl, sp
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl
	ld l, (hl)
	call SPRegisterHookFirst

__sp_RegisterHookFirst_ret:
	ld ix, (__sp_ixsave)
	ret
