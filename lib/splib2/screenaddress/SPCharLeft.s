;
; CharLeft
; Alvin Albrecht 2002
;

	.include "SPconfig.inc"
	.module SPCharLeft
	.globl SPCharLeft

; Char Left
;
; Adjusts screen address HL to move one character to the left
; on the display.  Start of line wraps to the previous row.
;
; enter: HL = valid screen address
;        Carry reset
; exit : Carry = moved off screen
;        HL = moves one character left, with line wrap
; used : AF, HL

	.ifeq DISP_HIRES

SPCharLeft:
	ld a, l
	dec l
	or a
	ret nz
	ld a, h
	sub #0x08
	ld h, a
	cp #0x40
	ret

	.else

SPCharLeft:
	ld a, h
	xor #0x20
	ld h, a
	cp #0x58
	ccf
	ret nc
	ld a, l
	dec l
	or a
	ret nz
	ld a, h
	sub #0x08
	ld h, a
	and #0x18
	cp #0x18
	ccf
	ret

	.endif
