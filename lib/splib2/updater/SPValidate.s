;
; Validate Rectangle
; Alvin Albrecht 01.2003
;

	.include "SPconfig.inc"

	.module SPValidate
	.globl SPValidate
	.globl SPValidateP
	.globl SPIntRect
	.globl SPCompDirtyAddr
	.globl SPbitleft2mask
	.globl SPbitright2mask


; Validate Rectangle
;
; enter:  B = row coord top left corner
;         C = col coord top left corner
;         D = row coord bottom right corner
;         E = col coord bottom right corner
;        IY = clipping rectangle, set it to "ClipStruct" for full screen

SPValidate:
	ld a, d
	sub b
	inc a
	ld d, a; d = row height
	ld a, e
	sub c
	inc a
	ld e, a; e = col width

SPValidateP:
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
	cpl
	ld e, a
	ld d, b
	ld a, c

valcollp:
	cp #8
	jr nc, valfullchar
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
	cpl
	or b
	pop de
	ld e, a

valfullchar:
	ld b, d
	push hl

valrowlp:
	ld a, (hl)
	and e
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
	djnz valrowlp
	pop hl
	inc hl
	ld e, #0x00
	ld a, c
	sub #8
	ld c, a
   ;ret z
	jp nc, valcollp
	ret
