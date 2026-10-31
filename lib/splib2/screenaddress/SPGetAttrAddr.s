;
; GetAttrAddr
; Alvin Albrecht 2002
;

	.include "SPconfig.inc"
	.module SPGetAttrAddr
	.globl SPGetAttrAddr

; Get Attribute Address
;
; Computes the attribute address corresponding to a screen
; address such as returned by 'GetCharAddr' or 'GetScrnAddr'.
;
; enter: hl = screen address
; exit : de = address of attribute square
; uses : af, de

	.if DISP_SPECTRUM

SPGetAttrAddr:
	ld e, l
	ld a, h
	or #0x07
	xor #0x85
	rrca
	rrca
	rrca
	ld d, a
	ret

	.else
	.if DISP_HICOLOUR

SPGetAttrAddr:
	ld e, l
	ld d, h
	set 5, d
	ret

	.else

SPGetAttrAddr:
	ld e, l
	ld d, h
	ret; There are no attributes in hi-res mode

	.endif
	.endif
