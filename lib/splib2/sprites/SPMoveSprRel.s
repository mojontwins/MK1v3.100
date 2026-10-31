;
; MoveSprRel
; Alvin Albrecht 2002
;

	.module SPMoveSprRel
	.globl SPMoveSprRel
	.globl SPMoveSprRelC
	.globl SPMoveSprRelNC
	.globl SPMoveSprAbs
	.globl SPMoveSprAbsC
	.globl SPMoveSprAbsNC
	.dw SPMoveSprAbs

; Move Sprite Relative Calculation
;
; enter: IX = sprite structure address
;        BC = animate bitdef displacement (0 for no animation)
;         H = relative row coord, signed byte
;         L = relative col coord, signed byte
;         D = relative horizontal pixel movement, signed byte
;         E = relative vertical pixel movement, signed byte
; time : 244

MoveSprRelCalc:
	ld a, 4(ix); current horizontal rotation
	add a, d
	ld d, a
	sra a
	sra a
	sra a
	add a, l
	add a, 1(ix)
	ld l, a; l = absolute column position
	ld a, d
	cp #0x80
	jp c, mvpos1
	add a, #8

mvpos1:
	and #0x07
	ld d, a; d = absolute horizontal rotation
	ld a, 5(ix); current vertical rotation
	add a, e
	ld e, a
	sra a
	sra a
	sra a
	add a, h
	add a, 0(ix)
	ld h, a; h = absolute row position
	ld a, e
	cp #0x80
	jp c, mvpos2
	add a, #8

mvpos2:
	and #0x07
	ld e, a; e = absolute vertical rotation
	ret


; see MoveSprRelCalc for register setup
; also IY = clipping rectangle, set it to "ClipStruct" for full screen
;           (only used if row,col coord change)

SPMoveSprRel:
	call MoveSprRelCalc
	jp SPMoveSprAbs

SPMoveSprRelNC:
	call MoveSprRelCalc
	jp SPMoveSprAbsNC

SPMoveSprRelC:
	call MoveSprRelCalc
	jp SPMoveSprAbsC
