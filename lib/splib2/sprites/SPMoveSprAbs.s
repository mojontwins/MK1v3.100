;
; MoveSprAbs
; Alvin Albrecht 2002
; AA: Fixed 08.2003: Displacement not added to null sprite ptr.
;

	.include "SPconfig.inc"

	.module SPMoveSprAbs
	.globl SPMoveSprAbs
	.globl SPMoveSprAbsC
	.globl SPMoveSprAbsNC
	.globl SPInvalidate
	.globl SPDisplayList
	.globl SPNullSprPtr
	.globl SPCompNullSprPtr
	.globl SPInvalidateP
	.dw SPInvalidate

; MoveSprAbs
;
; Moves the sprite to a new absolute position.  Portions of the sprite that are
; outside the clipping rectangle will not be displayed.  The sprite is automatically
; invalidated so that it and the space it left will be redrawn in the next update.
; Only enters sprite into the display list if its character coordinate changes.
;
; enter: IX = sprite structure address
;        BC = animate bitdef displacement (0 for no animation)
;         H = new row coord in chars
;         L = new col coord in chars
;         D = new horizontal rotation (0..7) ie horizontal pixel position
;         E = new vertical rotation (0..7) ie vertical pixel position
;        IY = clipping rectangle, set it to "ClipStruct" for full screen

SPMoveSprAbs:
	ld a, h
	cp 0(ix); avoid changing coords if we can to avoid expensive
	jp nz, SPMoveSprAbsC; insertions and deletions in the display list
	ld a, l
	cp 1(ix)
	jp nz, SPMoveSprAbsC

SPMoveSprAbsNC:
	call computedisp; bc' = bitdef displacement, d' = msb horizontal rotate table
	.db 0xdd
	ld c, l
	.db 0xdd
	ld b, h; bc = ix
	ld hl, #6
	add hl, bc; hl = ix+6 = ptr to ptr to first char struct in sprite

adjloop:
	ld a, (hl)
	or a
	jp z, invalidate; no more char structs in sprite
	inc hl
	ld l, (hl)
	ld h, a; hl = char struct + 0
	call adjustgraphics; apply bitdef displacement and vertical rotation to graphic ptrs
	jp adjloop


SPMoveSprAbsC:
	exx
	call invalidate; invalidate area currently occupied by sprite
	exx

	ld 0(ix), h; store new row coord
	ld 1(ix), l; store new col coord
	call computedisp; bc' = bitdef displacement, d' = msb horizontal rotate table

   ; compute address in display list for top left corner of sprite

	ld h, #0
	ld a, 0(ix);  a = row coordinate top left corner
	cp #SP_ROWEND-SP_ROWSTART
	jr c, yinscreen
	dec h

yinscreen:
	ld l, a; hl = signed row disp from start of screen
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	.if DISP_HIRES
	add hl, hl
	.endif; hl = (row coordinate)*(COLEND-COLSTART)
	ld d, #0
	ld a, 1(ix);  a = col coordinate of top left corner
	.if DISP_HIRES
	cp #64
	.else
	cp #32
	.endif
	jr c, xinscreen
	dec d

xinscreen:
	ld e, a; de = signed column disp from start of row
	add hl, de; hl = row*(COLEND-COLSTART)+col
	add hl, hl; four bytes per display list entry
	add hl, hl; hl = (row*(COLEND-COLSTART)+col)*4
	ld de, #SPDisplayList
	add hl, de
	ex de, hl; de = display list address, top left corner of sprite
	inc de
	inc de; point at linked list of sprites

	.db 0xdd
	ld c, l
	.db 0xdd
	ld b, h; bc = ix
	ld hl, #6
	add hl, bc; hl = ix+6 = ptr to ptr to first char struct in sprite

	ld c, 1(ix); c = current col coord
	push de; save display list address, top row of sprite

mvcolloop:
	ld b, 0(ix); b = current row coord
	ld a, 2(ix); a = sprite row height

mvrowloop:
	ex af, af'; a ' = row height
	ld a, (hl)
	or a
	jp nz, notdone; still more char structs in sprite
	pop de; pop off saved display list address
	jp invalidate; invalidate area sprite moved to

notdone:
	inc hl
	ld l, (hl)
	ld h, a; hl = char struct + 0

   ; first remove char struct from display list

	push de; save current display list position
	push hl; save current char struct + 0
	inc hl
	inc hl
	ld a, (hl); can't remove char struct from display list
	or a;   if it's not there now!
	jr z, notinDList
	ld (hl), #0; mark it not in display list
	inc hl
	ld e, (hl)
	ld d, a; de = previous char struct + 11
	ld a, l
	add a, #8
	ld l, a
	jp nc, noinc1
	inc h

noinc1:; hl = current char struct + 11
	ld a, (hl)
	ld (hl), #0; mark not in display list
	inc hl
	ld l, (hl)
	ld h, a; hl = next char struct + 4
	ex de, hl; de = next char struct + 4, hl = previous char struct + 11
	ld (hl), d
	inc hl
	ld (hl), e; previous char struct next ptr = next char struct + 4
	dec hl; hl = previous char struct + 11
	ex de, hl; de = previous char struct + 11, hl = next char struct + 4
	ld a, h
	or a
	jr z, nonext1; if msb = 0, there is no next char struct
	dec hl
	ld (hl), e
	dec hl
	ld (hl), d; next char struct's previous ptr = previous char struct + 11

   ; next add char struct to new position in display list

nonext1:
notinDList:
	ld a, c;  a = current column coordinate
	cp 2(iy); left column of clipping rectangle
	jr c, notdisplayed
	cp 3(iy); right column + 1 of clipping rectangle
	jr nc, notdisplayed
	ld a, b;  a = current row coordinate
	cp 0(iy); top row of clipping rectangle
	jr c, notdisplayed
	cp 1(iy); bottom row + 1 of clipping rectangle
	jr nc, notdisplayed

	pop de
	pop hl; hl = current display list address, linked list
	push hl
	push de
	jp noinc2

pdloop:
	ld a, #7
	add a, l
	ld l, a
	jp nc, noinc2
	inc h; hl = char struct + 11

noinc2:
	ld e, l
	ld d, h; de = tentative previous char struct + 11
	ld a, (hl)
	or a
	jr z, puthere; at end of list, attach current char struct to end
	inc hl
	ld l, (hl)
	ld h, a; hl = next char struct + 4
	ld a, (hl)
	and #0x3f;  a = sprite plane
	cp 12(ix)
	jp nc, pdloop; if the next char struct is lower priority

puthere:
	pop hl; de = previous char struct + 11
	push hl; hl = current char struct + 0
	inc hl
	inc hl
	ld (hl), d
	inc hl
	ld (hl), e; current's previous char struct + 11 pointer updated
	ld a, #8
	add a, l
	ld l, a
	jp nc, noinc3
	inc h

noinc3:; hl = current char struct + 11
	ld a, (de)
	ld (hl), a
	inc hl; hl = current char struct + 12
	inc de; de = previous char struct + 12
	ld a, (de)
	ld (hl), a; current's next char struct ptr = previous's next char struct + 4
	ld a, l
	sub #8
	ld l, a
	jp nc, nodec1
	dec h

nodec1:; hl = current char struct + 4
	ex de, hl; de = current char struct + 4, hl = previous char struct + 12
	ld (hl), e
	dec hl
	ld (hl), d; previous's next ptr = current char struct + 4
	ld a, #7
	add a, e
	ld e, a
	jp nc, noinc4
	inc d

noinc4:; de = current char struct + 11
	ld a, (de)
	or a
	jr z, nonext2; no next char struct to update
	ld h, a
	inc de
	ld a, (de)
	ld l, a
	dec hl; hl = next char struct + 3
	dec de; de = current char struct + 11
	ld (hl), e
	dec hl
	ld (hl), d; next's previous ptr = current char struct + 11

nonext2:
notdisplayed:
	pop hl; hl = current char struct + 0, stack: disp list address, linked list
	call adjustgraphics; apply bitdef displacement and vertical rotation to graphic ptrs

   ; hl = current char struct + 0, on stack = display list address, linked list
   ; b = current row coordinate, c = current col coordinate, a' = height

	inc b; next row coord
	ex (sp), hl; hl = display list address
	.if DISP_HIRES
	ld de, #4*64
	.else
	ld de, #4*32
	.endif
	add hl, de
	ex de, hl; de = next row in display list address
	pop hl; hl = char struct + 0
	ex af, af'; a = row height count
	dec a
	jp nz, mvrowloop; more rows in this column
	inc c; row done, move to next column
	pop de; de = display list address, top of row
	inc de
	inc de
	inc de
	inc de; move display list right one column
	push de
	jp mvcolloop


invalidate:
	ld b, 0(ix)
	ld c, 1(ix)
	ld e, 3(ix)
	ld d, 2(ix)
	jp SPInvalidateP; invalidate area currently occupied by sprite


computedisp:
	ld a, d
	and #0x07; a = new horizontal pixel rotation 0..7
	ld 4(ix), a; store new horizontal rotation
	rla; next find rotation table address for this rotation
	or #>SProtatetbl
	ld d, a; d = msb hor rotation table address

	ld a, e
	and #0x07
	ld e, a; a = e = new vertical pixel rotation 0..7
	sub 5(ix); compute the change from the old vertical rotation
	ld 5(ix), e; store new vertical rotation
	.ifeq COMPRESS
	.if DISP_HICOLOUR
	ld e, a
	add a, a
	add a, e; triple change to get byte displacement (1 graphic, 1 mask, 1 colour)
	.else
	add a, a; double change to get byte displacement (1 graphic, 1 mask)
	.endif
	.else
	ld e, a; some clumsiness added after-the-fact to cope with COMPRESS sprites
	ld a, 13(ix); first find out if this is a masked sprite
	and #0xc0
	ld a, e
	.if DISP_HICOLOUR
	rla
	.endif
	jp nz, notmask
	.if DISP_HICOLOUR
	add a, e
	.else
	add a, a
	.endif
notmask:
	.endif
	neg
	ld l, a
	ld h, #0; sign extend a into hl
	jp p, notnegative
	dec h

notnegative:
	add hl, bc; add this vertical rotation displacement to animation displacement
	ld c, l
	ld b, h
	exx; bc' = bitdef displacement, d' = msb horizontal rotate table
	ret


adjustgraphics:
	push hl
	exx; bc = bitdef displacement, d = msb of hor rotate table
	pop hl; hl = current char struct + 0
	push de
	ld a, #9
	add a, l
	ld l, a
	jp nc, noinc5
	inc h

noinc5:; hl = current char struct + 9
	ld (hl), d; store msb horizontal rotate tbl
	dec hl; hl = current char struct + 8
	ld a, (hl)
	cp #>SPNullSprPtr
	jr z, skip1
	.if COMPRESS
	cp #>SPCompNullSprPtr
	jr z, skip1
	.endif
	ld d, a
	dec hl; hl = current char struct + 7
	ld e, (hl)
	ex de, hl; de = curr char struct + 7, hl = sprite bitdef
	add hl, bc; add animate + vertical rotate displacement
	ex de, hl; hl = curr char struct + 7, de = new bitdef
	ld (hl), e
	inc hl
	ld (hl), d; store new bitdef
skip1:
	dec hl
	dec hl; hl = current char struct + 6
	ld a, (hl)
	cp #>SPNullSprPtr
	jr z, skip2
	.if COMPRESS
	cp #>SPCompNullSprPtr
	jr z, skip2
	.endif
	ld d, a
	dec hl; hl = current char struct + 5
	ld e, (hl); de = sprite bitdef left
	ex de, hl
	add hl, bc; add animate + vert rot disp
	ex de, hl; de = new bitdef left, hl = current char struct + 5
	ld (hl), e
	inc hl
	ld (hl), d; store new bitdef left
skip2:
	pop de; restore d
	exx
	ret
