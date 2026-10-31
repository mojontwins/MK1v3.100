; sp_RegisterHookLast (envoltorio __smallc para SDCC)
; void sp_RegisterHookLast (uchar vector, void *hook)

	.module sp_RegisterHookLast
	.globl _sp_RegisterHookLast
	.globl __sp_ixsave

	.area _CODE

_sp_RegisterHookLast::
	ld (__sp_ixsave), ix

	.globl SPRegisterHookLast

	ld hl, #2
	add hl, sp
	ld c, (hl)
	inc hl
	ld b, (hl)
	inc hl
	ld l, (hl)
	call SPRegisterHookLast

__sp_RegisterHookLast_ret:
	ld ix, (__sp_ixsave)
	ret
