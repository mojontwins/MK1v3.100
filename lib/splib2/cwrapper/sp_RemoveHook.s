; sp_RemoveHook (envoltorio __smallc para SDCC)
; int sp_RemoveHook (uchar vector, void *hook)

	.module sp_RemoveHook
	.globl _sp_RemoveHook
	.globl __sp_ixsave

	.area _CODE

_sp_RemoveHook::
	ld (__sp_ixsave), ix

	.globl SPRemoveHook

	ld hl, #2
	add hl, sp
	ld c, (hl)
	inc hl
	ld b, (hl)
	inc hl
	ld l, (hl)
	call SPRemoveHook
	ld hl, #1
	ccf
	jp nc, __sp_RemoveHook_ret
	dec l

__sp_RemoveHook_ret:
	ld ix, (__sp_ixsave)
	ret
