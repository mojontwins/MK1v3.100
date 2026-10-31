;
; Invalidate Rectangle
; Alvin Albrecht 01.2003
;

	.include "SPconfig.inc"

	.module SPInvalidate
	.globl SPInvalidate
	.globl SPInvalidateP
	.globl SPIntRect
	.globl SPCompDirtyAddr
	.globl SPbitleft2mask
	.globl SPbitright2mask


; Invalidate Rectangle
;
; enter:  B = row coord top left corner
;         C = col coord top left corner
;         D = row coord bottom right corner
;         E = col coord bottom right corner
;        IY = clipping rectangle, set it to "ClipStruct" for full screen

SPInvalidate:
	ld a, d
	sub b
	inc a
	ld d, a; d = row height
	ld a, e
	sub c
	inc a
	ld e, a; e = col width

SPInvalidateP:
	call SPIntRect; call here if D = height, E = width
	ret c

   ; b = row, c = col, d = height, e = width

	push de
	ld a, b
	call SPCompDirtyAddr; hl = address into dirty chars array, a = bit position
	pop de

	dec e
	ld b, a
	add a, e
	ld c, a
	ld a, b
	add a, #<SPbitleft2mask
	ld e, a
	ld b, d
	ld d, #>SPbitleft2mask
	jp nc, noinc1
	inc d

noinc1:
	ld a, (de)
	ld e, a
	ld d, b
	ld a, c

invcollp:
	cp #8
	jr nc, invfullchar
   ;dec a
	push de
	ld b, e
	add a, #<SPbitright2mask
	ld e, a
	ld d, #>SPbitright2mask
	jp nc, noinc2
	inc d

noinc2:
	ld a, (de)
	and b
	pop de
	ld e, a

invfullchar:
	ld b, d
	push hl

invrowlp:
	ld a, (hl)
	or e
	ld (hl), a
	.if DISP_HIRES
	ld a, #64/8
	.else
	ld a, #32/8
	.endif
	add a, l
	ld l, a
	jp nc, noinc3
	inc h

noinc3:
	djnz invrowlp
	pop hl
	inc hl
	ld e, #0xff
	ld a, c
	sub #8
	ld c, a
   ;ret z
	jp nc, invcollp
	ret
