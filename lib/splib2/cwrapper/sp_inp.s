; sp_inp (envoltorio __smallc para SDCC)
; uchar sp_inp (uint port)

	.module sp_inp
	.globl _sp_inp
	.globl __sp_ixsave

	.area _CODE

_sp_inp::
	ld (__sp_ixsave), ix

	ld hl, #2
	add hl, sp
	ld c, (hl)
	inc hl
	ld b, (hl)
	in l, (c)
	ld h, #0

__sp_inp_ret:
	ld ix, (__sp_ixsave)
	ret
