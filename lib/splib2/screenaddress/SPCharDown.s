;
; CharDown
; Alvin Albrecht 2002
;

	.include "SPconfig.inc"
	.module SPCharDown
	.globl SPCharDown

; Char Down
;
; Adjusts screen address HL to move eight pixels down on the display.
;
; enter: HL = valid screen address
; exit : Carry = moved off screen
;        HL = moves one character down
; used : AF, HL

SPCharDown:
	ld a, l
	add a, #0x20
	ld l, a
	ret nc
	ld a, h
	add a, #0x08
	ld h, a
	.if DISP_HIRES
	and #0x18
	cp #0x18
	.else
	cp #0x58
	.endif
	ccf
	ret
