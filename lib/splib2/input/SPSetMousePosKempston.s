;
; Kempston Mouse Position
; Alvin Albrecht 02.2003
;

	.include "SPconfig.inc"

	.module SPSetMousePosKempston
	.globl SPSetMousePosKempston
	.globl SPMouseKempston
	.globl SPKEMPX
	.globl SPKEMPY

; Set Position for Kempston Mouse
;
; enter: h = y coord 0..191
;        l = x coord 0.255, hi-res: carry set adds 256
; used : af

SPSetMousePosKempston:
	push af
	push hl
	call SPMouseKempston; to zero out kempston readings
	pop hl
	pop af
	.if DISP_HIRES
	ld a, #0
	adc a, #0
	ld (SPKEMPX+1), a
	.endif
	ld a, l
	ld (SPKEMPX), a
	ld a, h
	ld (SPKEMPY), a
	ret
