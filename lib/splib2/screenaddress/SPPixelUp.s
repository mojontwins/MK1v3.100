;
; PixelUp
; Alvin Albrecht 2002
;

	.include "SPconfig.inc"
	.module SPPixelUp
	.globl SPPixelUp

; Pixel Up
;
; Adjusts screen address HL to move one pixel up in the display.
; (0,0) is located at the top left corner of the screen.
;
; enter: HL = valid screen address
; exit : Carry = moved off screen
;        HL = moves one pixel up
; used : AF, HL

SPPixelUp:
	ld a, h
	dec h
	and #0x07
	ret nz
	ld a, #0x08
	add a, h
	ld h, a
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
