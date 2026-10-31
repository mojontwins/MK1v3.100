; sp_ScreenStr (envoltorio __smallc para SDCC)
; uint sp_ScreenStr (uchar row, uchar col)

	.module sp_ScreenStr
	.globl _sp_ScreenStr
	.globl __sp_ixsave

	.area _CODE

_sp_ScreenStr::
	ld (__sp_ixsave), ix

	.globl SPScreenStr

	ld hl, #2
	add hl, sp
	ld c, (hl)
	inc hl
	inc hl
	ld a, (hl)
	call SPScreenStr
	ex de, hl

__sp_ScreenStr_ret:
	ld ix, (__sp_ixsave)
	ret
