; sp_BlockAlloc (envoltorio __smallc para SDCC)
; void * sp_BlockAlloc (uchar queue)

	.module sp_BlockAlloc
	.globl _sp_BlockAlloc
	.globl __sp_ixsave

	.area _CODE

_sp_BlockAlloc::
	ld (__sp_ixsave), ix

	.globl SPBlockAlloc

	ld hl, #2
	add hl, sp
	ld a, (hl)
	call SPBlockAlloc
	ccf
	jp nc, __sp_BlockAlloc_ret
	ld hl, #0

__sp_BlockAlloc_ret:
	ld ix, (__sp_ixsave)
	ret
