; sp_FreeBlock (envoltorio __smallc para SDCC)
; void sp_FreeBlock (void *addr)

	.module sp_FreeBlock
	.globl _sp_FreeBlock
	.globl __sp_ixsave

	.area _CODE

_sp_FreeBlock::
	ld (__sp_ixsave), ix

	.globl SPFreeBlock

	ld hl, #2
	add hl, sp
	ld e, (hl)
	inc hl
	ld d, (hl)
	call SPFreeBlock

__sp_FreeBlock_ret:
	ld ix, (__sp_ixsave)
	ret
