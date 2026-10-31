; sp_BlockCount (envoltorio __smallc para SDCC)
; uint sp_BlockCount (uchar queue)

	.module sp_BlockCount
	.globl _sp_BlockCount
	.globl __sp_ixsave

	.area _CODE

_sp_BlockCount::
	ld (__sp_ixsave), ix

	.globl SPBlockCount

	ld hl, #2
	add hl, sp
	ld a, (hl)
	call SPBlockCount
	ld l, c
	ld h, b

__sp_BlockCount_ret:
	ld ix, (__sp_ixsave)
	ret
