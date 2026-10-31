; sp_TileArray (envoltorio __smallc para SDCC)
; void * sp_TileArray (uchar c, void *addr)

	.module sp_TileArray
	.globl _sp_TileArray
	.globl __sp_ixsave

	.area _CODE

_sp_TileArray::
	ld (__sp_ixsave), ix

	.globl SPTileEntry

	ld hl, #2
	add hl, sp
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl
	ld a, (hl)
	call SPTileEntry
	ex de, hl

__sp_TileArray_ret:
	ld ix, (__sp_ixsave)
	ret
