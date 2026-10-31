;
; CreateSpr
; Alvin Albrecht 2002
;

	.include "SPconfig.inc"

	.module SPCreateSpr
	.globl SPCreateSpr
	.globl SPBlockAlloc
	.globl SPDeleteSpr
	.globl SPNullSprPtr

	.if COMPRESS
	.globl SPCompNullSprPtr
	.endif

; CreateSpr
;
; Create a new sprite.  The first column of the sprite bitdef is added.  More
; columns are added with "AddColSpr".  The sprite is not added to the display
; list and will not be visible until it is moved.
;
; enter:  B = #rows
;         C = sprite attribute
;             bits 7..6 = 00 (mask-type), 01 (or-type), 10 (xor-type), 11 (load-type)
;             bits 5..0 = sprite plane 0..63, lower means closer to viewer
;        DE = sprite column definition (bitdef)
;        A' = (spectrum )  colour attribute for column
;           = (hi-colour)  colour threshold
;           = (hi-res   )  unused
; exit : IX = sprite structure address
;        carry for success
;
; The display order of sprites in the same plane is indeterminate.
; The call will only fail if sufficient memory is not available from u_malloc.

SPCreateSpr:
	.if DISP_HICOLOUR
	ex af, af'
	add a, a; convert threshold number
	or #>SProtatetbl; to rotation table msb
	ex af, af'
	.endif
	push de
	push bc
	xor a
	call SPBlockAlloc; get memory for sprite struct (bloque de 14 bytes, cola 0)
	ex de, hl; si no hay memoria, SPBlockAlloc deja DE = 0 (HL no)
	pop bc
	ld a, h
	or l
	jp z, csfail1
	ld e, l
	ld d, h; hl = de = sprite struct address
	.db 0xdd
	ld l, e
	.db 0xdd
	ld h, d; ix = sprite struct address
	xor a
	ld (hl), a; row position = 0
	inc hl
	.if DISP_HIRES
	ld (hl), #64; col position = 64
	.else
	ld (hl), #32; col position = 32
	.endif
	inc hl
	ld (hl), b; height in char rows
	inc hl
	ld (hl), #1; width = 1 char
	inc hl
	ld (hl), a; no horizontal rotation
	inc hl
	ld (hl), a; no vertical rotation
	inc hl
	ld (hl), a; no next char struct
	ld a, c
	and #0x3f
	ld 12(ix), a; sprite plane
	ld a, c
	and #0xc0
	ld 13(ix), a; sprite type
	push hl
	push bc
	xor a
	call SPBlockAlloc; get memory for char struct (bloque de 14 bytes, cola 0)
	ex de, hl; si no hay memoria, SPBlockAlloc deja DE = 0 (HL no)
	pop bc
	ld a, h
	or l
	jr z, csfail2
	ex de, hl
	ld 8(ix), e; last column in sprite is
	ld 9(ix), d; the one being made now
	jp csenter

csloop:
	push de
	push hl
	push bc
	xor a
	call SPBlockAlloc; get memory for char struct (bloque de 14 bytes, cola 0)
	ex de, hl; si no hay memoria, SPBlockAlloc deja DE = 0 (HL no)
	pop bc
	ld a, h
	or l
	jr z, csfail2
	ex de, hl

csenter:
	pop hl; hl = next char struct ptr
	ld (hl), d; store address of next char struct
	inc hl
	ld (hl), e
	pop hl; hl = sprite column def
	ex de, hl; de = spr col def, hl = char struct
	push hl
	xor a
	ld (hl), a; no next char struct in sprite
	inc hl
	ld (hl), a
	inc hl
	ld (hl), a; no previous char struct in display list
	inc hl
	ld (hl), a
	inc hl
	ld (hl), c; sprite attribute
	inc hl
	.if COMPRESS
	ld a, c
	and #0xc0
	.if DISP_HICOLOUR
	ld a, #24
	.else
	ld a, #16
	.endif
	jr z, notcompress
	.if DISP_HICOLOUR
	ld a, #16
	.else
	ld a, #8
	.endif
	ld (hl), #<SPCompNullSprPtr
	inc hl
	ld (hl), #>SPCompNullSprPtr
	jp cont
	.endif
notcompress:
	ld (hl), #<SPNullSprPtr; empty space to left of sprite
	inc hl; so sprite rotations will introduce
	ld (hl), #>SPNullSprPtr; empty space at leftmost column
cont:
	inc hl
	ld (hl), e; sprite column bitdef
	inc hl
	ld (hl), d
	inc hl
	ld (hl), #>SProtatetbl; no horizontal rotation
	inc hl
;IF !DISP_HIRES
;   ex af,af'
;   ld (hl),a
;   ex af,af'
;ENDIF
	inc hl
	ld (hl), #0; no next char struct in display list
	pop hl; hl = char struct (next in sprite ptr)
	.ifeq COMPRESS
	.if DISP_HICOLOUR
	ld a, #24
	.else
	ld a, #16
	.endif
	.endif
	add a, e
	ld e, a; de = sprite column bitdef, next char
	jp nc, csnocry
	inc d

csnocry:
	djnz csloop; for all rows in sprite
	ld 10(ix), l
	ld 11(ix), h; last char struct in sprite
	scf; success
	ret

csfail1:
	pop de
	ret

csfail2:
	pop hl
	pop de
	.db 0xdd
	ld e, l
	.db 0xdd
	ld d, h; de = sprite struct address
	jp SPDeleteSpr

JPHL:
	jp (hl)
