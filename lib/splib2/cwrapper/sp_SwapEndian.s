; sp_SwapEndian (envoltorio __smallc para SDCC)
; void * sp_SwapEndian (void *ptr)

	.module sp_SwapEndian
	.globl _sp_SwapEndian
	.globl __sp_ixsave

	.area _CODE

_sp_SwapEndian::
	ld (__sp_ixsave), ix

	ld hl, #2
	add hl, sp
	ld a, (hl)
	inc hl
	ld l, (hl)
	ld h, a; reverse endianness

__sp_SwapEndian_ret:
	ld ix, (__sp_ixsave)
	ret
