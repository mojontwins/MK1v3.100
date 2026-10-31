; sp_Pause (envoltorio __smallc para SDCC)
; uint sp_Pause (uint ticks)

	.module sp_Pause
	.globl _sp_Pause
	.globl __sp_ixsave

	.area _CODE

_sp_Pause::
	ld (__sp_ixsave), ix

	.globl SPPause

	ld hl, #2
	add hl, sp
	ld c, (hl)
	inc hl
	ld b, (hl)
	call SPPause
	ld l, c
	ld h, b

__sp_Pause_ret:
	ld ix, (__sp_ixsave)
	ret
