; sp_IntLargeRect (envoltorio __smallc para SDCC)
; int sp_IntLargeRect (struct sp_LargeRect *r1, struct sp_LargeRect *r2, struct sp_LargeRect *result)

	.module sp_IntLargeRect
	.globl _sp_IntLargeRect
	.globl __sp_ixsave

	.area _CODE

_sp_IntLargeRect::
	ld (__sp_ixsave), ix

	.globl SPIntLargeRect

	ld hl, #7
	add hl, sp
	ld d, (hl)
	dec hl
	ld e, (hl)
	dec hl
	ld b, (hl)
	dec hl
	ld c, (hl)
	.db 0xdd
	ld l, e
	.db 0xdd
	ld h, d
	.db 0xfd
	ld l, c
	.db 0xfd
	ld h, b
	call SPIntLargeRect
	ld hl, #0
	jp c, __sp_IntLargeRect_ret
	ld hl, #10
	add hl, sp
	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a
	ld bc, #7
	add hl, bc
	pop bc
	ld (hl), b
	dec hl
	ld (hl), c
	dec hl
	pop bc
	ld (hl), b
	dec hl
	ld (hl), c
	dec hl
	pop bc
	ld (hl), b
	dec hl
	ld (hl), c
	dec hl
	pop bc
	ld (hl), b
	dec hl
	ld (hl), c
	ld hl, #1

__sp_IntLargeRect_ret:
	ld ix, (__sp_ixsave)
	ret
