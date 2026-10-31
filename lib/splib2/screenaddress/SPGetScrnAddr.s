;
; GetScrnAddr
; Alvin Albrecht 2002
;

	.include "SPconfig.inc"
	.module SPGetScrnAddr
	.globl SPGetScrnAddr

; Get Screen Address
;
; Computes the screen address given a valid pixel coordinate.
; (0,0) is located at the top left corner of the screen.
;
; enter: a = h = y coord
;        l = x coord
;        In hi-res mode, Carry is most significant bit of x coord (0..511 pixels)
; exit : de = screen address, b = pixel mask
; uses : af, b, de, hl

	.ifeq DISP_HIRES

SPGetScrnAddr:
	and #0x07
	or #0x40
	ld d, a
	ld a, h
	rra
	rra
	rra
	and #0x18
	or d
	ld d, a

	ld a, l
	and #0x07
	ld b, a
	ld a, #0x80
	jr z, norotate

rotloop:
	rra
	djnz rotloop

norotate:
	ld b, a
	srl l
	srl l
	srl l
	ld a, h
	rla
	rla
	and #0xe0
	or l
	ld e, a
	ret

	.else

SPGetScrnAddr:
	ld b, #0
	ld d, b
	rr l
	rl b
	srl l
	rl b
	srl l
	rl b
	srl l
	jr nc, notodd
	ld d, #0x20

notodd:
	ld a, b
	or a
	ld a, #0x80
	jr z, norotate

rotloop:
	rra
	djnz rotloop

norotate:
	ld b, a
	ld a, h
	and #0x07
	or #0x40
	or d
	ld d, a
	ld a, h
	rra
	rra
	rra
	and #0x18
	or d
	ld d, a

	ld a, h
	rla
	rla
	and #0xe0
	or l
	ld e, a
	ret

	.endif
