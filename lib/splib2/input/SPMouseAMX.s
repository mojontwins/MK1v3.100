;
; AMX Mouse
; Alvin Albrecht 01.2003
; 08.2003: Read buttons fixed.

	.include "SPconfig.inc"

	.module SPMouseAMX
	.globl SPMouseAMX
	.globl SPMouseAMXInit
	.globl SPtbllookup
	.globl SPAMXxcoord
	.globl SPAMXycoord
	.dw SPMouseAMXInit

; Mouse AMX
;
; Don't forget to initialize the AMX interface.
;
; exit : a = h = y coord 0..191
;        l = x coord 0.255, hi-res: carry set adds 256
;        e = 11111MRL active low button press
; used : af,de,hl

SPMouseAMX:
	ld e, #0x1f
	in a, (#0xdf); mouse button state will randomly
	or e; fluctuate except when the mouse
	ld e, a; buttons are really pressed!
	in a, (#0xdf)
	or e
	ld e, a
	in a, (#0xdf)
	or e
	ld e, a
	in a, (#0xdf)
	or e
	ld e, a
	in a, (#0xdf)
	or e
	ld e, a
	in a, (#0xdf)
	or e
	ld e, a
	in a, (#0xdf)
	or e
	ld e, a
	in a, (#0xdf)
	or e
	rlca
	rlca
	rlca
	and #0x07
	ld de, #AMXButTbl
	call SPtbllookup
	ld e, a

	ld a, (SPAMXycoord+1)
	cp #8*(SP_ROWEND - SP_ROWSTART); keep it in spritepack's row range
	jp c, notoutofrange
	ld a, #8*(SP_ROWEND - SP_ROWSTART) - 1
	ld (SPAMXycoord+1), a
notoutofrange:
	ld h, a
	.if DISP_HIRES
	ld a, (SPAMXxcoord)
	rla
	ld a, (SPAMXxcoord+1)
	rla
	.else
	ld a, (SPAMXxcoord+1)
	.endif
	ld l, a
	ld a, h
	ret

AMXButTbl:
	.db 0xf8, 0xfc, 0xfa, 0xfe, 0xf9, 0xfd, 0xfb, 0xff
