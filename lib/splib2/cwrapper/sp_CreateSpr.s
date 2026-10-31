; sp_CreateSpr (envoltorio __smallc para SDCC)
; struct sp_SS * sp_CreateSpr (uchar type, uchar rows, void *graphic, uchar plane)

	.module sp_CreateSpr
	.globl _sp_CreateSpr
	.globl __sp_ixsave

	.area _CODE

_sp_CreateSpr::
	ld (__sp_ixsave), ix

	.globl SPCreateSpr

	ld hl, #2
	add hl, sp; hl points past ret address
   ;ld a,(hl)         ; 'extra' parameter is colour or threshold info
   ;ex af,af'         ; a' = extra
   ;inc hl
   ;inc hl
	ld c, (hl); c = plane
	inc hl
	inc hl
	ld e, (hl)
	inc hl
	ld d, (hl); de = sprite graphic
	inc hl
	ld b, (hl); b = # rows in sprite
	inc hl
	inc hl
	ld a, (hl); sprite type
	or c
	ld c, a; c = sprite attribute

	call SPCreateSpr; carry = success, ix = sprite struct address

	push ix
	pop hl; hl = sprite struct
	ccf; no carry indicates success, compatible with C "iferror(..)"

__sp_CreateSpr_ret:
	ld ix, (__sp_ixsave)
	ret
