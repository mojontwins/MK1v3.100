; sp_BlockFit (envoltorio __smallc para SDCC)
; void * sp_BlockFit (uchar queue, uchar numcheck)

	.module sp_BlockFit
	.globl _sp_BlockFit
	.globl __sp_ixsave

	.area _CODE

_sp_BlockFit::
	ld (__sp_ixsave), ix

	.globl SPBlockFit

	ld hl, #2
	add hl, sp
	ld b, (hl)
	inc hl
	inc hl
	ld a, (hl)
	call SPBlockFit
	ccf
	jp nc, __sp_BlockFit_ret
	ld hl, #0

__sp_BlockFit_ret:
	ld ix, (__sp_ixsave)
	ret
