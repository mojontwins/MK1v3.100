; sp_KeyPressed (envoltorio __smallc para SDCC)
; int sp_KeyPressed (uint scancode)

	.module sp_KeyPressed
	.globl _sp_KeyPressed
	.globl __sp_ixsave

	.area _CODE

_sp_KeyPressed::
	ld (__sp_ixsave), ix

	.globl SPKeyPressed

	ld hl, #2
	add hl, sp
	ld c, (hl)
	inc hl
	ld b, (hl)
	call SPKeyPressed
	ld hl, #0
	jp nc, __sp_KeyPressed_ret
	inc l

__sp_KeyPressed_ret:
	ld ix, (__sp_ixsave)
	ret
