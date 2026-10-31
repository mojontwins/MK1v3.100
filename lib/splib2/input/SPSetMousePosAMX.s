;
; AMX Mouse Position
; Alvin Albrecht 02.2003
;

	.include "SPconfig.inc"

	.module SPSetMousePosAMX
	.globl SPSetMousePosAMX
	.globl SPMouseAMXInit
	.globl SPAMXxcoord
	.globl SPAMXycoord
	.dw SPMouseAMXInit

; Set Position for AMX Mouse
;
; Don't forget to initialize the AMX interface.
;
; enter: h = y coord 0..191
;        l = x coord 0.255, hi-res: carry set adds 256
; used : af, l

SPSetMousePosAMX:
	di
	.if DISP_HIRES
	rr l
	ld a, #0
	rra
	ld (SPAMXxcoord), a
	.endif
	ld a, l
	ld (SPAMXxcoord+1), a
	ld a, h
	ld (SPAMXycoord+1), a
	ei
	ret
