;
; CompDListAddr
; Alvin Albrecht 01.2003
;

	.include "SPconfig.inc"

	.module SPCompDListAddr
	.globl SPCompDListAddr
	.globl SPDisplayList

; Compute display list address corresponding to a specific
; character coordinate.
;
; enter:  A = row position (0..23)
;         C = col position (0..31/63)
; exit : HL = display list address
; used : f, b, de, hl

SPCompDListAddr:
	.if DISP_HIRES
	ld h, #>SProtatetbl + 4
	.else
	ld h, #>SProtatetbl + 6
	.endif
	ld l, a
	ld e, (hl)
	inc h
	ld l, (hl)
	ld h, e; hl = row*32 or row*64
	ld b, #0
	add hl, bc; hl = row*32 + col
	add hl, hl
	add hl, hl; hl = 4*(row*32 + col)
	ld de, #SPDisplayList
	add hl, de
	ret
