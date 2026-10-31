;
; CharRight
; Alvin Albrecht 2002
;

	.include "SPconfig.inc"
	.module SPCharRight
	.globl SPCharRight

; Char Right
;
; Adjusts screen address HL to move one character to the right
; on the display.  End of line wraps to the next row.
;
; enter: HL = valid screen address
;        Carry reset
; exit : Carry = moved off screen
;        HL = moves one character right, with line wrap
; used : AF, HL

	.ifeq DISP_HIRES

SPCharRight:
	inc l
	ret nz
	ld a, #8
	add a, h
	ld h, a
	cp #0x58
	ccf
	ret

	.else

SPCharRight:
	ld a, h
	xor #0x20
	ld h, a
	cp #0x58
	ret nc
	inc l
	ret nz
	ld a, #8
	add a, h
	ld h, a
	cp #0x58
	ccf
	ret

	.endif
