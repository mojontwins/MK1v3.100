;
; PixelRight
; Alvin Albrecht 06.2003
;

	.include "SPconfig.inc"
	.module SPPixelRight
	.globl SPPixelRight

; Pixel Right
;
; Adjusts screen address HL and pixel mask B to move right
; one pixel on screen.
;
; enter: HL = valid screen address
;         B = pixel mask for screen byte
; exit : Carry = moved off screen
;        HL, B moved right one pixel
; used : AF, HL

SPPixelRight:
	.ifeq DISP_HIRES
	rrc b
	ret nc
	inc l
	ld a, l
	and #0x1f
	ret nz
	scf
	ret
	.else
	rrc b
	ret nc
	ld a, h
	xor #0x20
	ld h, a
	and #0x20
	ret nz
	inc l
	ld a, l
	and #0x1f
	ret nz
	scf
	ret
	.endif
