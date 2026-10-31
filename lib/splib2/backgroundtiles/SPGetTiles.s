;
; Get Background Tiles
; Alvin Albrecht 07.2003
;

	.include "SPconfig.inc"

	.module SPGetTiles
	.globl SPGetTiles
	.globl SPCompDListAddr

; Get Background Tiles
;
; Copy the background tiles in a rectangle on screen
; into memory.  PutTiles can be used to print the
; rectangle of tiles to screen.
;
; enter : hl = destination address
;          A = row coord of top left corner of rectangle
;          C = col coord of top left corner of rectangle
;          D = width of rectangle
;          E = height of rectangle
; uses  : af, bc, de, hl

SPGetTiles:
	push hl; save dest address
	push de; save rectangle size
	call SPCompDListAddr; hl = DList Address
	pop bc; bc = rectangle size
	pop de; de = dest address

	ld a, c; a = height
	ld c, #0xff
rowloop:
	push bc; save b = width
	push hl; save DList address at start of row
colloop:
	ldi; copy tile colour
	ldi; copy tile character
	inc hl
	inc hl; hl = next column's DList address
	djnz colloop
	pop hl; hl = DList at start of row
	.if DISP_HIRES
	inc h
	.else
	ld c, #4*32
	add hl, bc; add row displacement
	.endif
	pop bc; restore b = width
	dec a; finished full height?
	jp nz, rowloop
	ret
