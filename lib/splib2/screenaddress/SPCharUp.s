;
; CharUp
; Alvin Albrecht 2002
;

	.include "SPconfig.inc"
	.module SPCharUp
	.globl SPCharUp

; Char Up
;
; Adjusts screen address HL to move eight pixels up on the display.
;
; enter: HL = valid screen address
; exit : Carry = moved off screen
;        HL = moves one character up
; used : AF, HL

SPCharUp:
	ld a, l
	sub #0x20
	ld l, a
	ret nc
	ld a, h
	sub #0x08
	ld h, a
	.if DISP_HIRES
	and #0x18
	cp #0x18
	ccf
	.else
	cp #0x40
	.endif
	ret
