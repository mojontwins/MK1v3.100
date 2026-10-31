;
; Set Border Colour
; Alvin Albrecht 07.2003
;

	.include "SPconfig.inc"

	.module SPBorder
	.globl SPBorder
	.globl SPBorderClr

SPBorderClr:
	.if DISP_HIRES
	.db 0x00
	.else
	.db 0x07
	.endif

; Set Border Colour
;
; Stores border colour in variable SPBorderClr.
; In hi-res mode, the "border colour" selects the
; paper colour with the ink colour selected by
; the Timex hardware.
;
; enter:   a = border colour 0..7
; exit :   border colour changed
;
; used :   af,c

SPBorder:
	.ifeq DISP_HIRES
	and #0x07
	ld (SPBorderClr), a
	out (#0xfe), a
	.else
	and #0x07
	ld (SPBorderClr), a
	xor #0x07
	rlca
	rlca
	rlca
	ld c, a
	in a, (#0xff)
	and #0xc7
	or c
	out (#0xff), a
	.endif
	ret
