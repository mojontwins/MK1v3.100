;
; AddColSpr
; Alvin Albrecht 2002
;

	.include "SPconfig.inc"

	.module SPAddColSpr
	.globl SPAddColSpr
	.globl SPBlockAlloc
	.globl SPDeleteSpr
	.globl SPdsloop
	.dw SPDeleteSpr

; AddColSpr
;
; Adds a column to an existing sprite.  The column is not in the display list
; and will not be displayed until the sprite is moved.
;
; enter: IX = sprite structure address
;        DE = sprite column definition
;        A' = (spectrum )  colour attribute for entire column
;             (hi-colour)  colour threshold
;             (hi-res   )  unused
; exit : carry for success
;
; The call will only fail if sufficient memory is unavailable.

SPAddColSpr:
	.if DISP_HICOLOUR
	ex af, af'
	add a, a; convert threshold number
	or #>SProtatetbl; to rotation table msb
	ex af, af'
	.endif
	ld a, 5(ix); adjust sprite column address
; ******** POSSIBLE BUG FOR COMPRESS SPRITES?
	add a, a; for existing vertical rotation
	.if DISP_HICOLOUR
	add a, 5(ix)
	.endif
	neg
	add a, e
	jp nc, acnocry
	dec d

acnocry:
	ld e, a
	ld c, 8(ix); bc = first char struct in last
	ld b, 9(ix);      column of this sprite
	ld l, 10(ix); hl = last char struct in sprite
	ld h, 11(ix)
	exx
	ld b, 2(ix); b' = row height in chars

acloop:
	exx
	push de
	push hl

	push bc
	push ix
	xor a
	call SPBlockAlloc; get memory for new char struct (bloque de 14 bytes, cola 0)
	ex de, hl; si no hay memoria, SPBlockAlloc deja DE = 0 (HL no)
	pop ix
	pop bc
	ld a, h
	or l
	jr z, acfail
	ex de, hl

	pop hl; hl = last char struct in sprite (next ptr)
	ld (hl), d; store address of new char struct
	inc hl
	ld (hl), e
	pop hl; hl = sprite column bitdef
	ex de, hl; de = spr col bitdef, hl = char struct (next ptr)
	push hl
	push bc
	xor a
	ld (hl), a; no next char struct in sprite
	inc hl
	ld (hl), a
	inc hl
	ld (hl), a; no previous char struct in display list
	inc hl
	ld (hl), a
	inc hl
	ld a, 13(ix)
	and #0xc0; sprite type
	or 12(ix); OR in sprite plane
	ld (hl), a; sprite attribute
	inc hl; hl = char struct bitdef left
	ld a, #7
	add a, c
	ld c, a; bc = last column char struct bitdef
	jp nc, noinc1
	inc b

noinc1:
	ld a, (bc); store bitdef left in char struct
	ld (hl), a
	inc bc
	inc hl
	ld a, (bc)
	ld (hl), a
	inc hl
	inc bc
	ld (hl), e; store bitdef in char struct
	inc hl
	ld (hl), d
	inc hl
	.if COMPRESS
	ld a, 13(ix)
	and #0xc0
	.endif
	.if DISP_HICOLOUR
	ld a, #24
	.else
	ld a, #16
	.endif
	.if COMPRESS
	jr z, nochange
	.if DISP_HICOLOUR
	ld a, #16
	.else
	ld a, #8
	.endif
nochange:
	.endif
	add a, e
	ld e, a; next char in sprite column definition
	jp nc, acnocry3
	inc d

acnocry3:
	ld a, (bc); store current horizontal rotation in char struct
	ld (hl), a
	inc hl
;IF !DISP_HIRES
;   ex af,af'
;   ld (hl),a
;   ex af,af'
;ENDIF
	inc hl
	ld (hl), #0; no next char struct in display list
	pop hl; hl = last column char struct
	ld b, (hl)
	inc hl
	ld c, (hl); bc = next char struct in last column
	pop hl; hl = last char struct in sprite
	exx
	djnz acloop; add char for all rows
	exx
	ld e, 10(ix); de = old last char struct in sprite
	ld d, 11(ix)
	ld 10(ix), l; store new last char struct
	ld 11(ix), h
	ex de, hl
	ld d, (hl)
	inc hl
	ld e, (hl); de = char struct following old last char struct
	ld 8(ix), e; becomes last column in sprite
	ld 9(ix), d
	inc 3(ix); sprite width increases by 1
	scf; success
	ret

acfail:
	pop hl
	pop de
	ld l, 10(ix)
	ld h, 11(ix)
	ld d, (hl)
	ld (hl), #0
	inc hl
	ld e, (hl)
	ex de, hl
	jp SPdsloop

JPHL:
	jp (hl)
