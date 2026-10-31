;
; PtInLargeRect
; Alvin Albrecht 03.2003
;

	.module SPPtInLargeRect
	.globl SPPtInLargeRect
	.globl SPPtInIval

; Point In Large Rectangle?
;
; enter:  Rectangle #1:
;
;         ix+0/1   xtop
;         ix+2/3   xbot
;         ix+4/5   xleft
;         ix+6/7   xright
;
;         hl = y coordinate
;         de = x coordinate
;
; exit :  carry = not in rectangle
;
; used :  f, bc, de, hl
;

SPPtInLargeRect:
	push de; save x coordinate
	ld c, 0(ix)
	ld b, 1(ix)
	ld e, 2(ix)
	ld d, 3(ix)
	call SPPtInIval; is y in [xtop,xbot]?
	pop hl
	ret c; return if fail
	ld c, 4(ix)
	ld b, 5(ix)
	ld e, 6(ix)
	ld d, 7(ix)
	call SPPtInIval; is x in [xleft,xright]?
	ret
