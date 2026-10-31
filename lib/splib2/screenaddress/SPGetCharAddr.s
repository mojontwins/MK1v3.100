;
; GetCharAddr
; Alvin Albrecht 2002
;

	.include "SPconfig.inc"
	.module SPGetCharAddr
	.globl SPGetCharAddr

; Get Character Address
;
; Computes the screen address of the top of a character square.
; (0,0) is located at the top left corner of the screen.
;
; enter: h = y coord 0..23, l = x coord 0..31 (0..63 for hi-res mode)
; exit : hl = screen address
; uses : af,c,hl

	.ifeq DISP_HIRES

SPGetCharAddr:
	ld a, h
	rrca
	rrca
	rrca
	and #0xe0
	or l
	ld l, a
	ld a, h
	and #0x18
	or #0x40
	ld h, a
	ret

	.else

SPGetCharAddr:
	ld a, h
	and #0x18
	or #0x40
	srl l
	jr nc, notodd
	or #0x20

notodd:
	ld c, a
	ld a, h
	rrca
	rrca
	rrca
	and #0xe0
	or l
	ld l, a
	ld h, c
	ret

	.endif
