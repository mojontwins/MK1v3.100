; ******************************************************
; **       LibrerÃ­a de rutinas para Amstrad CPC       **
; **	   RaÃºl Simarro, 	  Artaburu 2007           **
; ******************************************************

; Cambio radical al tema de los tiles tocados marca ACME (ActualizaciÃ³n de
; CÃ³digo Mojona Eructo) by na_th_an

; Ahora en lugar de haber una lista de tiles tocados, tenemos un bitfield. El
; bitfield se ubica a partir de `tiles_tocados` y ocupa 96 bytes, con 1 bit
; para cada uno de las 768 casillas.

; Esta rutina invalida un rectÃ¡ngulo en el bitfield

; Adapted from splib2

	.module cpc_InvalidateRect
	.globl cpc_InvalidateRect
	.include "CPCconfig.inc"
	.area _CODE
	.globl cpc_bitleft2mask
	.globl cpc_bitright2mask

; Invalidate Rectangle
;
; enter:  B = row coord top left corner
;         C = col coord top left corner
;         D = row coord bottom right corner
;         E = col coord bottom right corner
;        IY = clipping rectangle, set it to "ClipStruct" for full screen

cpc_InvalidateRect:

	; Transform DE into height / width

	ld a, d
	sub b
	inc a
	ld d, a
	ld a, e
	sub c
	inc a
	ld e, a

cpc_InvalidateRect_P:

	; Call here if D = height, E = width

	; b = row, c = col, d = height, e = width

	push de
	ld a, b; row position

	add a, a
	add a, a; Y * 4

	ld l, a
	ld h, #0
	ld a, c; col position

	and #0x07; bitmask
	srl c
	srl c
	srl c

	ld b, h
	add hl, bc; HL = Y * 4 + X / 8

	ld de, #tiles_tocados
	add hl, de

	; HL = PosiciÃ³n en el buffer
	; A  = PosiciÃ³n de la celda en el byte

	pop de

	dec e
	ld b, a
	add a, e
	ld c, a
	ld a, b
	add a, #<cpc_bitleft2mask
	ld e, a
	ld b, d
	ld d, #>cpc_bitleft2mask
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
	push de
	ld b, e
	add a, #<cpc_bitright2mask
	ld e, a
	ld d, #>cpc_bitright2mask
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
	ld a, #32/8

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

	jp nc, invcollp

	ret
