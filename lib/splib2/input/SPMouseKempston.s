;
; Kempston Mouse
; Based on Chris Cowley's Basic Mouse Driver code <ccowley@grok.co.uk>
; 03.2003
;

	.include "SPconfig.inc"
	.module SPMouseKempston
	.globl SPMouseKempston
	.globl SPKEMPX
	.globl SPKEMPY

;
; Local Statics
;

SPKEMPX:
xcoord:
	.dw 0

SPKEMPY:
ycoord:
	.db 0

kempx:
	.db 0

kempy:
	.db 0


; MouseKempston
;
; exit : a = h = y coord 0..191
;        l = x coord 0.255, hi-res mode: carry set adds 256
;        e = 111111RL active low button press
; used : af,de,hl

SPMouseKempston:
	ld a, (kempx)
	ld e, a; e = last x coord reported by kempston
	ld a, #0xfb
	in a, (#0xdf); current x coord reported by kempston
	ld (kempx), a
	sub e
	ld hl, (xcoord)
	jp pe, overflow; if overflow, kill the x movement
nooverflow:
	ld e, a
	ld d, #0
	jp p, posdx
	dec d; de = signed dx, positive for right movement
posdx:
	add hl, de
	bit 7, h
	jp z, xleftokay
	ld hl, #0; hit left border, set x to 0
	jp xokay
xleftokay:
	.if DISP_HIRES
	bit 1, h
	.else
	bit 0, h
	.endif
	jp z, xokay
	.if DISP_HIRES
	ld hl, #511
	.else
	ld hl, #255; hit right border, set x to 255
	.endif
xokay:
	ld (xcoord), hl; hl = x coord

overflow:
	ld a, #0xfa
	in a, (#0xdf)
	and #0x03
	ld e, a
	rla
	srl e
	or #0xfc
	or e
	ld e, a; e = buttons 111111RL active low

	ld a, (kempy)
	ld d, a; d = last y coord reported by kempston
	ld a, #0xff
	in a, (#0xdf); a = current y coord reported by kempston
	ld (kempy), a
	sub d
	ld d, a; d = dy, positive for up
	ld a, (ycoord); a = current mouse y coord
	sub d
	cp #192
	jp c, yokay
	ld a, (ycoord); y moved off screen, stop it at screen edge
	cp #96; were we closer to the top or bottom of the screen?
	jr c, yattop
	ld a, #191
	jp yokay
yattop:
	xor a
yokay:
	cp #8*(SP_ROWEND - SP_ROWSTART)
	jp c, rowinrange
	ld a, #8*(SP_ROWEND - SP_ROWSTART) - 1

rowinrange:
	ld (ycoord), a
	.if DISP_HIRES
	rrc h
	.endif
	ld h, a
	ret
