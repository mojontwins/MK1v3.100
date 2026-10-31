; sp_Swap (envoltorio __smallc para SDCC)
; void sp_Swap (void *addr1, void *addr2, uint bytes)

	.module sp_Swap
	.globl _sp_Swap
	.globl __sp_ixsave

	.area _CODE

_sp_Swap::
	ld (__sp_ixsave), ix

	.globl SPSwap

	ld hl, #2
	add hl, sp
	ld c, (hl)
	inc hl
	ld b, (hl)
	inc hl
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl
	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a
	call SPSwap

__sp_Swap_ret:
	ld ix, (__sp_ixsave)
	ret
