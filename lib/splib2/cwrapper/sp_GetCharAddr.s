; sp_GetCharAddr (envoltorio __smallc para SDCC)
; void * sp_GetCharAddr (uchar row, uchar col)

	.module sp_GetCharAddr
	.globl _sp_GetCharAddr
	.globl __sp_ixsave

	.area _CODE

_sp_GetCharAddr::
	ld (__sp_ixsave), ix

	.globl SPGetCharAddr

	ld hl, #2
	add hl, sp
	ld a, (hl)
	inc hl
	inc hl
	ld h, (hl)
	ld l, a
	call SPGetCharAddr

__sp_GetCharAddr_ret:
	ld ix, (__sp_ixsave)
	ret
