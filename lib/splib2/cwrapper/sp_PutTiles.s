; sp_PutTiles (envoltorio __smallc para SDCC)
; void sp_PutTiles (struct sp_Rect *r, void *src)

	.module sp_PutTiles
	.globl _sp_PutTiles
	.globl __sp_ixsave

	.area _CODE

_sp_PutTiles::
	ld (__sp_ixsave), ix

	.globl SPPutTiles

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
	call SPPutTiles

__sp_PutTiles_ret:
	ld ix, (__sp_ixsave)
	ret
