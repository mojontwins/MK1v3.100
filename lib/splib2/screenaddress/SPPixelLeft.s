;
; PixelLeft
; Alvin Albrecht 06.2003
;

	.include "SPconfig.inc"
	.module SPPixelLeft
	.globl SPPixelLeft

; Pixel Left
;
; Adjusts screen address HL and pixel mask B to move left
; one pixel on screen.
;
; enter: HL = valid screen address
;         B = pixel mask for screen byte
; exit : Carry = moved off screen
;        HL, B moved left one pixel
; used : AF, HL

SPPixelLeft:
	.ifeq DISP_HIRES
	rlc b
	ret nc
	ld a, l
	dec l
	and #0x1f
	ret nz
	scf
	ret
	.else
	rlc b
	ret nc
	ld a, h
	xor #0x20
	ld h, a
	and #0x20
	ret z
	ld a, l
	dec l
	and #0x1f
	ret nz
	scf
	ret
	.endif
