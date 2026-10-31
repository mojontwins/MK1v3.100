;
; IntIvals
; Alvin Albrecht 03.2003
;

	.module SPIntIvals
	.globl SPIntIvals
	.globl SPPtInIval

; Intersect Intervals
;
; Returns the intersection of two intervals [x1,x2] and [y1,y2].
;
; NOTE: In cases where the result would be two disjoint intervals,
;       only one is returned.
;
; enter:   ix+0 = x1 low
;          ix+1 = x1 hi
;          ix+2 = x2 low
;          ix+3 = x2 hi
;          iy+0 = y1 low
;          iy+1 = y1 hi
;          iy+2 = y2 low
;          iy+3 = y2 hi
;
; exit :   carry = no intersection
;          otherwise the resulting intersect interval is [bc,de]
;
; used :   f, bc, de, hl

SPIntIvals:
	ld l, 0(ix)
	ld h, 1(ix); hl = x1
	ld c, 0(iy)
	ld b, 1(iy); bc = y1
	ld e, 2(iy)
	ld d, 3(iy); de = y2
	push de; save y2
	push hl; save x1
	call SPPtInIval; is x1 in [y1,y2]?
	jr c, notinival; if no


   ; bc = y1, stack = x1 then y2

	ld l, 2(ix)
	ld h, 3(ix); hl = x2
	pop bc; bc = x1
	sbc hl, bc
	ex de, hl; de = x2-x1
	pop hl; hl = y2
	or a
	sbc hl, bc; hl = y2-x1
	or a
	sbc hl, de; if ((y2-x1) < (x2-x1)) set carry
	jr c, retY2
retX2:
	ld e, 2(ix)
	ld d, 3(ix); return interval [bc,de] = [x1,x2]
	ret
retY2:
	ld e, 2(iy)
	ld d, 3(iy)
	or a
	ret; return interval [bc,de] = [x1,y2]


   ; bc = y1, stack = x1 then y2, carry flag set

notinival:
	ld l, c
	ld h, b; hl = y1
	pop bc; bc = x1
	push hl; save y1
	ld e, 2(ix)
	ld d, 3(ix); de = x2
	push de; save x2
	call SPPtInIval
	jr c, failintival; if (y1 not in [x1,x2]) then fail intersection


   ; bc = x1, stack = x2 y1 y2

	pop hl; hl = x2
	pop bc; bc = y1
	sbc hl, bc
	ex de, hl; de = x2-y1
	pop hl; hl = y2
	or a
	sbc hl, bc; hl = y2-y1
	ex de, hl
	or a
	sbc hl, de; if ((x2-y1) < (y2-y1)) set carry
	jp nc, retY2; return [y1,y2]
	or a
	jp retX2; return [y1,x2]

failintival:
	pop hl
	pop hl
	pop hl
	ret; carry = no intersection
