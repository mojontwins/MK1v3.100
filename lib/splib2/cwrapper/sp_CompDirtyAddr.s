; sp_CompDirtyAddr (envoltorio __smallc para SDCC)
; void * sp_CompDirtyAddr (uchar row, uchar col, uchar *mask)

	.module sp_CompDirtyAddr
	.globl _sp_CompDirtyAddr
	.globl __sp_ixsave

	.area _CODE

_sp_CompDirtyAddr::
	ld (__sp_ixsave), ix

	.globl SPCompDirtyAddr

	ld hl, #6
	add hl, sp
	ld a, (hl)
	dec hl
	dec hl
	ld c, (hl)
	dec hl
	push hl
	call SPCompDirtyAddr
	pop de
	ex de, hl
	ld b, (hl)
	dec hl
	ld c, (hl)
	ex de, hl
	ld (bc), a

__sp_CompDirtyAddr_ret:
	ld ix, (__sp_ixsave)
	ret
