; sp_GetScrnAddr (envoltorio __smallc para SDCC)
; void * sp_GetScrnAddr (uint xcoord, uchar ycoord, uchar *mask)

	.module sp_GetScrnAddr
	.globl _sp_GetScrnAddr
	.globl __sp_ixsave

	.area _CODE

_sp_GetScrnAddr::
	ld (__sp_ixsave), ix

	.globl SPGetScrnAddr

	ld hl, #7
	add hl, sp
	ld b, (hl)
	dec hl
	ld c, (hl); bc = x coord
	dec hl
	dec hl
	push hl
	ld h, (hl)
	ld l, c
	ld a, h
	rrc b
	call SPGetScrnAddr
	ex de, hl
	ex (sp), hl
	dec hl
	ld d, (hl)
	dec hl
	ld e, (hl); de = mask
	ex de, hl
	ld (hl), b
	pop hl

__sp_GetScrnAddr_ret:
	ld ix, (__sp_ixsave)
	ret
