; sp_AddColSpr (envoltorio __smallc para SDCC)
; int sp_AddColSpr (struct sp_SS *sprite, void *graphic)

	.module sp_AddColSpr
	.globl _sp_AddColSpr
	.globl __sp_ixsave

	.area _CODE

_sp_AddColSpr::
	ld (__sp_ixsave), ix

	.globl SPAddColSpr

	ld hl, #2
	add hl, sp
   ;ld a,(hl)
   ;ex af,af
   ;inc hl
   ;inc hl
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl
	ld c, (hl)
	inc hl
	ld b, (hl)
	.db 0xdd
	ld l, c
	.db 0xdd
	ld h, b
	call SPAddColSpr
	ld hl, #1
	ccf
	jp nc, __sp_AddColSpr_ret
	dec l

__sp_AddColSpr_ret:
	ld ix, (__sp_ixsave)
	ret
