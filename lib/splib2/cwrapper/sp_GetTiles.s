; sp_GetTiles (envoltorio __smallc para SDCC)
; void sp_GetTiles (struct sp_Rect *r, void *dest)

	.module sp_GetTiles
	.globl _sp_GetTiles
	.globl __sp_ixsave

	.area _CODE

_sp_GetTiles::
	ld (__sp_ixsave), ix

	.globl SPGetTiles

	ld hl, #2
	add hl, sp
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl
	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a
	ld b, (hl)
	inc hl
	ld c, (hl)
	inc hl
	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a
	ld a, b
	ex de, hl
	call SPGetTiles

__sp_GetTiles_ret:
	ld ix, (__sp_ixsave)
	ret
