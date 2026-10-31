; sp_Pallette (envoltorio __smallc para SDCC)
; void * sp_Pallette (uchar c, void *addr)

	.module sp_Pallette
	.globl _sp_Pallette
	.globl __sp_ixsave

	.area _CODE

_sp_Pallette::
	ld (__sp_ixsave), ix

	.globl SPPallette

	ld hl, #2
	add hl, sp
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl
	ld a, (hl)
	call SPPallette
	ex de, hl

__sp_Pallette_ret:
	ld ix, (__sp_ixsave)
	ret
