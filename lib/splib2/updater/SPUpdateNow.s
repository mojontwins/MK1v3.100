;
; Update Now
; Alvin Albrecht 07.2003
;
; Sprite Pack's screen updater.  The updater supports four different
; screen modes with one chosen by defining the corresponding variable
; true and the others false:
;
; DISP_SPECTRUM
;   256x192 pixel, 32x24 colour Spectrum resolution
; DISP_HICOLOUR
;   256x192 pixel, 32x192 colour Timex hi-colour resolution
; DISP_HIRES
;   512x192 monochrome Timex hi-res resolution
; DISP_TMXDUAL
;   uses second display file as spectrum resolution double buffer (Timex only)
;   (also define DISP_SPECTRUM for this mode)
;
; The updater manages a portion of the screen defined by the row range.
; Sprite Pack will not touch the area outside this row range.
;
; SP_ROWSTART
;   Starting row 0..23
; SP_ROWEND
;   Last row, non-inclusive.
;
; The updater performs a differential screen refresh.  It divides the
; screen into character size tiles and only redraws those chars that
; have changed from the previous update.  Keeping track of which chars
; change is a cooperative effort with Sprite Pack's drawing functions.
; The "Dirty Chars Array" stores this information: one bit is reserved
; per char with a set bit indicating the char is changed.  As changes
; are made to the screen, Sprite Pack's functions set these bits and
; as the updater draws the screen, it resets the bits.  The dirty chars
; array is mapped to the screen characters in left to right, top to
; bottom order.  Each byte stores the status of 8 character tiles.
;
; Sprite Pack keeps track of what's on screen in a "Display List Array".
; Each character on screen is composed of a single background tile (first
; byte is attribute (spec) / pallette # (hi-colour) / ignored (hi-res),
; second byte is tile #) and a linked list of sprite char structures
; (a 2-byte pointer).  Each character therefore needs a 4-byte entry in
; this array.  Each character's 4-byte struct is mapped into the display
; list array in left to right, top to bottom order.
;
; Two additional modes are available: NOFLICKER mode and SCROLLER mode.
; You can turn either or both on by defining them true.  NOFLICKER mode
; causes each screen character to be completely drawn in a background
; buffer before being copied to the screen.  The penalty is a slower
; update rate.  SCROLLER mode causes the first sprite in each character
; to be drawn as load-type regardless of the sprite's actual designated
; type.
;
; By defining COMPRESS true, or/xor/load sprite graphic definitions
; have their mask bytes removed, halving the space they occupy in memory.
; Doing this means that mask sprite graphic definitions will no longer
; be useable as or/xor/load sprite definitions.

	.include "SPconfig.inc"
	.module SPUpdateNow
	.globl SPUpdateNow
	.globl SPDisplayList
	.globl SPDirtyChars
	.globl SPTileArray

	.if DISP_TMXDUAL
	.globl SPScreen
SPScreen:
	.db 0x20; indicates which display file to draw into ($20=secondary, 0=primary)
	.endif

;
; Private Static Variables
;

	.if NOFLICKER
tempgraphic:
	.if DISP_HICOLOUR
	.ds 16
	.else
	.ds 8
	.endif
	.endif

	.if DISP_SPECTRUM
tempcolour:
	.db 0
	.endif

;
; The screen draw subroutine.
;

SPUpdateNow:
	ld de, #0x4000 + (256 * (SP_ROWSTART & 0x18)) + (32 * (SP_ROWSTART & 7)); de = screen address
	.if DISP_TMXDUAL
	ld a, (SPScreen)
	add a, d
	ld d, a
	ld bc, #SPDisplayList; start of display list
	ld hl, #SPDirtyChars; start of dirty chars array
	.else
	ld hl, #SPDisplayList
	ld bc, #SPDirtyChars
	.endif

dirtyloop:
	.if DISP_TMXDUAL
	ld a, (hl); examine dirty byte, one bit per 8 chars
	inc h
	or (hl); or in old dirty byte
	dec h
	.else
	ld a, (bc)
	or a
	.endif
	jp nz, dirtyarea; if one of the chars is dirty, need to redraw
	.if DISP_HIRES
	ld a, #4
	.else
	ld a, #8; otherwise advance screen address 8 chars to right
	.endif
	add a, e
	ld e, a
	jp nz, notacrossblk1; check if a screen block is crossed
	ld a, #8; and adjust if necessary
	add a, d
	ld d, a

notacrossblk1:
	ld a, #32; advance display list 8 chars (32 bytes)
	.if DISP_TMXDUAL
	add a, c
	ld c, a
	jp nc, noinc1
	inc b
	.else
	add a, l
	ld l, a
	jp nc, noinc1
	inc h
	.endif

noinc1:
reenter:
	.if DISP_TMXDUAL
	inc hl; advance dirty chars pointer
	ld a, h; are we done yet?
	.else
	inc bc
	ld a, b
	.endif
	.if DISP_HIRES
	cp #>(SPDirtyChars + 8 * (SP_ROWEND - SP_ROWSTART))
	.else
	cp #>(SPDirtyChars + 4 * (SP_ROWEND - SP_ROWSTART))
	.endif
	jp c, dirtyloop
	.if DISP_TMXDUAL
	ld a, l
	.else
	ld a, c
	.endif
	.if DISP_HIRES
	cp #<(SPDirtyChars + 8 * (SP_ROWEND - SP_ROWSTART))
	.else
	cp #<(SPDirtyChars + 4 * (SP_ROWEND - SP_ROWSTART))
	.endif
	jp c, dirtyloop
	.if DISP_TMXDUAL
	ld a, (SPScreen)
	xor #0x20
	ld (SPScreen), a; draw into other display file next time
	.endif
	ret


dirtyarea:
	.if DISP_TMXDUAL
	push hl
	ld l, c
	ld h, b; hl = display list
	.else
	push bc
	.endif
	ld bc, #4
	rrca; now must check each of the 8 chars in dirty byte
	call c, drawchar; if first char is dirty, redraw
	.if DISP_HIRES
	set 5, d
	.else
	inc e; move screen address right one char
	.endif
	add hl, bc; advance display list one char (4 bytes)
	rrca; repeat a total of 8 times
	call c, drawchar
	.if DISP_HIRES
	res 5, d
	.endif
	inc e
	add hl, bc
	rrca; repeat
	call c, drawchar
	.if DISP_HIRES
	set 5, d
	.else
	inc e
	.endif
	add hl, bc
	rrca; repeat
	call c, drawchar
	.if DISP_HIRES
	res 5, d
	.endif
	inc e
	add hl, bc
	rrca; repeat
	call c, drawchar
	.if DISP_HIRES
	set 5, d
	.else
	inc e
	.endif
	add hl, bc
	rrca; repeat
	call c, drawchar
	.if DISP_HIRES
	res 5, d
	.endif
	inc e
	add hl, bc
	rrca; repeat
	call c, drawchar
	.if DISP_HIRES
	set 5, d
	.else
	inc e
	.endif
	add hl, bc
	rrca; repeat
	call c, drawchar
	.if DISP_HIRES
	res 5, d
	.endif
	inc e; move screen address right one char --
	jp nz, notacrossblk2; might cross a screen block here
	ld a, #8; adjust screen address if necessary
	add a, d
	ld d, a

notacrossblk2:
	add hl, bc; advance display list one char (4 bytes)
	.if DISP_TMXDUAL
	ld c, l
	ld b, h; bc = display list
	pop hl; hl = dirty chars array
	ld a, (hl)
	inc h
	ld (hl), a; copy new dirty chars byte to old dirty chars byte
	dec h
	ld (hl), #0; clear new dirty byte
	.else
	pop bc
	xor a
	ld (bc), a
	.endif
	jp reenter; check the next dirty byte


tileonly:
	.if NOFLICKER
	pop de; pop screen address
	.if DISP_HICOLOUR
	ld a, #0x27
	add a, d
	ld d, a
	.endif
	.endif

	.if DISP_HICOLOUR
	ld a, (bc); copy tile colour to screen
	ld (de), a
	inc bc
	dec d
	ld a, (bc)
	ld (de), a
	inc bc
	dec d
	ld a, (bc)
	ld (de), a
	inc bc
	dec d
	ld a, (bc)
	ld (de), a
	inc bc
	dec d
	ld a, (bc)
	ld (de), a
	inc bc
	dec d
	ld a, (bc)
	ld (de), a
	inc bc
	dec d
	ld a, (bc)
	ld (de), a
	inc bc
	dec d
	ld a, (bc)
	ld (de), a
	res 5, d
	.endif

	ex af, af'; a = tile #
	add a, #<SPTileArray
	ld l, a
	ld h, #>SPTileArray
	jp nc, noinc11
	inc h
noinc11:
	ld c, (hl)
	inc h
	ld b, (hl); bc = tile graphic

	ld a, (bc); copy background tile graphics to screen
	ld (de), a
	inc bc
	inc d
	ld a, (bc); repeat 8 times total for entire char
	ld (de), a
	inc bc
	inc d
	ld a, (bc); repeat
	ld (de), a
	inc bc
	inc d
	ld a, (bc); repeat
	ld (de), a
	inc bc
	inc d
	ld a, (bc); repeat
	ld (de), a
	inc bc
	inc d
	ld a, (bc); repeat
	ld (de), a
	inc bc
	inc d
	ld a, (bc); repeat
	ld (de), a
	inc bc
	inc d
	ld a, (bc); repeat
	ld (de), a
	jp nomoresprites; do colour


drawchar:
	push af; save dirty byte
	push de; store screen address
	push hl; store display list pointer
	exx
	pop hl
	.if NOFLICKER
	.if DISP_HICOLOUR
	ld de, #tempgraphic+8
	.else
	ld de, #tempgraphic; write graphics to temporary buffer
	.endif
	.else
	pop de
	.if DISP_HICOLOUR
	ld a, #0x27
	add a, d
	ld d, a; move to bottom of char in colour memory
	.endif
	.endif

	.if DISP_SPECTRUM
	ld a, (hl); a = background colour
	ld (tempcolour), a; store colour of background tile
	inc hl; point at graphic tile
	.endif
	.if DISP_HIRES
	inc hl; point at graphic tile
	.endif
	.if DISP_HICOLOUR
	push hl; save DLIST
	ld a, (hl)
	add a, #<SPTileArray
	ld l, a
	ld a, #0
	adc a, #>SPTileArray + 2
	ld h, a; hl = address of pallette entry
	ld c, (hl)
	inc h
	ld b, (hl); bc = colour address
	pop hl
	inc hl; point at graphic tile
	.endif

	ld a, (hl)
	ex af, af'; a' = graphic tile #
	inc hl; point at MSB sprite list
	ld a, (hl)
	or a
	jr z, tileonly

	.if DISP_HICOLOUR; copy tile colour to screen, bottom up
	.if NOFLICKER
	push hl
	ld l, c
	ld h, b
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	pop hl
	ld de, #tempgraphic
	.else
	ld a, (bc); copy tile colour to screen, bottom up
	ld (de), a
	inc bc
	dec d
	ld a, (bc)
	ld (de), a
	inc bc
	dec d
	ld a, (bc)
	ld (de), a
	inc bc
	dec d
	ld a, (bc)
	ld (de), a
	inc bc
	dec d
	ld a, (bc)
	ld (de), a
	inc bc
	dec d
	ld a, (bc)
	ld (de), a
	inc bc
	dec d
	ld a, (bc)
	ld (de), a
	inc bc
	dec d
	ld a, (bc); bc = last colour byte in background tile
	ld (de), a
	ld a, (hl)
	res 5, d; de = top of char screen address
	.endif
	.endif

	inc hl
	ld l, (hl)
	ld h, a; hl = first sprite = char struct + 4

	.ifeq SCROLLER
	ld a, (hl)
	cp #0xc0; is this first sprite a load sprite?
	jr c, notload; if so don't bother drawing background tile
	.endif

	inc hl; hl = char struct + 5
	ld c, (hl)
	inc hl
	ld b, (hl)
	inc hl
	.db 0xdd
	ld l, c
	.db 0xdd
	ld h, b; ix = sprite graphic left
	ld c, (hl)
	inc hl
	ld b, (hl); bc = sprite graphic
	inc hl

	push hl; save char struct + 9
	ld h, (hl); h = msb of horizontal rotation table to use
	jp loadtype

	.ifeq SCROLLER
notload:
	push hl; save char struct + 4
	ex af, af'; a = tile #
	add a, #<SPTileArray
	ld l, a
	ld h, #>SPTileArray
	jp nc, noinc10
	inc h
noinc10:
	ld a, (hl)
	inc h
	ld h, (hl)
	ld l, a; hl = graphic tile address

	.if NOFLICKER
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ldi
	ld a, (hl)
	ld (de), a
	.else
	ld a, (hl); copy background tile graphics to screen
	ld (de), a
	inc hl
	inc d
	ld a, (hl); repeat 8 times total for entire char
	ld (de), a
	inc hl
	inc d
	ld a, (hl); repeat
	ld (de), a
	inc hl
	inc d
	ld a, (hl); repeat
	ld (de), a
	inc hl
	inc d
	ld a, (hl); repeat
	ld (de), a
	inc hl
	inc d
	ld a, (hl); repeat
	ld (de), a
	inc hl
	inc d
	ld a, (hl); repeat
	ld (de), a
	inc hl
	inc d
	ld a, (hl); repeat
	ld (de), a
	.endif
	pop hl; hl = char struct + 4
	.endif

spriteloop:
	.if NOFLICKER
	ld de, #tempgraphic
	.else
	ld a, d; move screen address back to top of char
	.if DISP_TMXDUAL
	and #0xf8
	.else
	and #0xd8
	.endif
	ld d, a
	.endif
	ld a, (hl); get sprite attribute (type | plane)

dosprite:
	inc hl; hl = char struct + 5
	ld c, (hl)
	inc hl
	ld b, (hl)
	inc hl
	.db 0xdd
	ld l, c
	.db 0xdd
	ld h, b; ix = sprite graphic left
	ld c, (hl)
	inc hl
	ld b, (hl); bc = sprite graphic
	inc hl

	push hl; save char struct + 9

   ;; na_th_an
	.if FLASHASFG
   ; Check if we must skip sprite rendering based upon cell attribute (bit 7 set = no sprites)

	ld iy, #tempcolour
	bit 7, 0(iy)

	jp nz, coloursprite
	.endif

	ld h, (hl); h = msb of horizontal rotation table to use
	cp #0xc0; what kind of sprite is this?
	jp nc, loadtype
	cp #0x80
	jp nc, xortype
	cp #0x40
	jp nc, ortype

   ; this must be a mask sprite

	ld a, h; have a look at the rotation being used
	and #0x0e
	jp z, masknorotate; if no rotation draw the fast way

	ld a, (bc); a = graphic
	ld l, a
	ld a, (hl); a = graphic rotated right
	inc h
	ld l, 0(ix); l = graphic left side
	or (hl); a = graphic rotated right | graphic from left side
	ex af, af'; a' = final graphic
	inc bc; advance to mask
	dec h
	ld a, (bc); a = mask
	ld l, a
	ld a, (hl); a = mask rotated right
	inc h
	ld l, 1(ix); l = mask left side
	or (hl); a = mask rotated right | mask from left side
	ex de, hl; hl = screen address, d = msb hor rotate table
	and (hl); a = existing screen & mask
	ld e, a
	ex af, af'; a = sprite graphic
	or e; a = sprite graphic | remaining portion of screen
	ld (hl), a; update screen
	ex de, hl; de = screen address, h = msb hor rotate table
	.if NOFLICKER
	inc de
	.else
	inc d; next scan line in char
	.endif
	dec h
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc; next sprite scan line

	ld a, (bc); repeat 8 times total for entire char
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	ld l, 3(ix)
	.else
	ld l, 2(ix)
	.endif
	or (hl)
	ex af, af'
	inc bc
	dec h
	ld a, (bc)
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	ld l, 4(ix)
	.else
	ld l, 3(ix)
	.endif
	or (hl)
	ex de, hl
	and (hl)
	ld e, a
	ex af, af'
	or e
	ld (hl), a
	ex de, hl
	.if NOFLICKER
	inc de
	.else
	inc d
	.endif
	dec h
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	ld l, 6(ix)
	.else
	ld l, 4(ix)
	.endif
	or (hl)
	ex af, af'
	inc bc
	dec h
	ld a, (bc)
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	ld l, 7(ix)
	.else
	ld l, 5(ix)
	.endif
	or (hl)
	ex de, hl
	and (hl)
	ld e, a
	ex af, af'
	or e
	ld (hl), a
	ex de, hl
	.if NOFLICKER
	inc de
	.else
	inc d
	.endif
	dec h
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	ld l, 9(ix)
	.else
	ld l, 6(ix)
	.endif
	or (hl)
	ex af, af'
	inc bc
	dec h
	ld a, (bc)
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	ld l, 10(ix)
	.else
	ld l, 7(ix)
	.endif
	or (hl)
	ex de, hl
	and (hl)
	ld e, a
	ex af, af'
	or e
	ld (hl), a
	ex de, hl
	.if NOFLICKER
	inc de
	.else
	inc d
	.endif
	dec h
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	ld l, 12(ix)
	.else
	ld l, 8(ix)
	.endif
	or (hl)
	ex af, af'
	inc bc
	dec h
	ld a, (bc)
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	ld l, 13(ix)
	.else
	ld l, 9(ix)
	.endif
	or (hl)
	ex de, hl
	and (hl)
	ld e, a
	ex af, af'
	or e
	ld (hl), a
	ex de, hl
	.if NOFLICKER
	inc de
	.else
	inc d
	.endif
	dec h
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	ld l, 15(ix)
	.else
	ld l, 10(ix)
	.endif
	or (hl)
	ex af, af'
	inc bc
	dec h
	ld a, (bc)
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	ld l, 16(ix)
	.else
	ld l, 11(ix)
	.endif
	or (hl)
	ex de, hl
	and (hl)
	ld e, a
	ex af, af'
	or e
	ld (hl), a
	ex de, hl
	.if NOFLICKER
	inc de
	.else
	inc d
	.endif
	dec h
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	ld l, 18(ix)
	.else
	ld l, 12(ix)
	.endif
	or (hl)
	ex af, af'
	inc bc
	dec h
	ld a, (bc)
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	ld l, 19(ix)
	.else
	ld l, 13(ix)
	.endif
	or (hl)
	ex de, hl
	and (hl)
	ld e, a
	ex af, af'
	or e
	ld (hl), a
	ex de, hl
	.if NOFLICKER
	inc de
	.else
	inc d
	.endif
	dec h
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	ld l, 21(ix)
	.else
	ld l, 14(ix)
	.endif
	or (hl)
	ex af, af'
	inc bc
	dec h
	ld a, (bc)
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	ld l, 22(ix)
	.else
	ld l, 15(ix)
	.endif
	or (hl)
	ex de, hl
	and (hl)
	ld e, a
	ex af, af'
	or e
	ld (hl), a
	ex de, hl; de points at last scan line in char
	dec h

	.if DISP_HICOLOUR
	.if COMPRESS

   ; unfortunately, because I've used ix with fixed offsets to get colour,
   ; the colour code needs to be duplicated for masked sprites in COMPRESS
   ; mode to get correct offsets.  i don't like this it all and may change
   ; this in the future.

DUPcoloursprite:
	ld a, h; have a look at the rotation
	dec a
	pop hl; hl = char struct + 9
	inc hl; point at colour threshold
	cp (hl)
	jp nc, DUPclrrotate; if rotation > threshold, rotate colour
DUPnoclrrotate:
	ld ix, #-22
	add ix, bc; ix = sprite graphic

DUPclrrotate:; now do colours bottom up
	ld c, #0x80; the transparent colour
	.if NOFLICKER
	inc de
	.else
	set 5, d
	.endif

	ld a, 23(ix)
	cp c; if transparent colour, do not colour
	jr z, DUPclear0
	ld (de), a

DUPclear0:
	.if NOFLICKER
	inc de
	.else
	dec d; move up scan line
	.endif
	ld a, 20(ix)
	cp c
	jr z, DUPclear1
	ld (de), a

DUPclear1:
	.if NOFLICKER
	inc de
	.else
	dec d
	.endif
	ld a, 17(ix)
	cp c
	jr z, DUPclear2
	ld (de), a

DUPclear2:
	.if NOFLICKER
	inc de
	.else
	dec d
	.endif
	ld a, 14(ix)
	cp c
	jr z, DUPclear3
	ld (de), a

DUPclear3:
	.if NOFLICKER
	inc de
	.else
	dec d
	.endif
	ld a, 11(ix)
	cp c
	jr z, DUPclear4
	ld (de), a

DUPclear4:
	.if NOFLICKER
	inc de
	.else
	dec d
	.endif
	ld a, 8(ix)
	cp c
	jr z, DUPclear5
	ld (de), a

DUPclear5:
	.if NOFLICKER
	inc de
	.else
	dec d
	.endif
	ld a, 5(ix)
	cp c
	jr z, DUPclear6
	ld (de), a

DUPclear6:
	.if NOFLICKER
	inc de
	.else
	dec d
	.endif
	ld a, 2(ix)
	cp c
	jp z, clear7
	ld (de), a; de back to top of char again (colour map)
	jp clear7
	.endif

coloursprite:
	ld a, h; have a look at the rotation
	dec a
	pop hl; hl = char struct + 9
	inc hl; point at colour threshold
	cp (hl)
	jp nc, clrrotate; if rotation > threshold, rotate colour
noclrrotate:
	.ifeq COMPRESS
	ld ix, #-22
	.else
	ld ix, #-14
	.endif
	add ix, bc; ix = sprite graphic

clrrotate:; now do colours bottom up
	ld c, #0x80; the transparent colour
	.if NOFLICKER
	inc de
	.else
	set 5, d
	.endif

	.ifeq COMPRESS
	ld a, 23(ix)
	.else
	ld a, 15(ix)
	.endif
	cp c; if transparent colour, do not colour
	jr z, clear0
	ld (de), a

clear0:
	.if NOFLICKER
	inc de
	.else
	dec d; move up scan line
	.endif
	.ifeq COMPRESS
	ld a, 20(ix)
	.else
	ld a, 13(ix)
	.endif
	cp c
	jr z, clear1
	ld (de), a

clear1:
	.if NOFLICKER
	inc de
	.else
	dec d
	.endif
	.ifeq COMPRESS
	ld a, 17(ix)
	.else
	ld a, 11(ix)
	.endif
	cp c
	jr z, clear2
	ld (de), a

clear2:
	.if NOFLICKER
	inc de
	.else
	dec d
	.endif
	.ifeq COMPRESS
	ld a, 14(ix)
	.else
	ld a, 9(ix)
	.endif
	cp c
	jr z, clear3
	ld (de), a

clear3:
	.if NOFLICKER
	inc de
	.else
	dec d
	.endif
	.ifeq COMPRESS
	ld a, 11(ix)
	.else
	ld a, 7(ix)
	.endif
	cp c
	jr z, clear4
	ld (de), a

clear4:
	.if NOFLICKER
	inc de
	.else
	dec d
	.endif
	.ifeq COMPRESS
	ld a, 8(ix)
	.else
	ld a, 5(ix)
	.endif
	cp c
	jr z, clear5
	ld (de), a

clear5:
	.if NOFLICKER
	inc de
	.else
	dec d
	.endif
	.ifeq COMPRESS
	ld a, 5(ix)
	.else
	ld a, 3(ix)
	.endif
	cp c
	jr z, clear6
	ld (de), a

clear6:
	.if NOFLICKER
	inc de
	.else
	dec d
	.endif
	.ifeq COMPRESS
	ld a, 2(ix)
	.else
	ld a, 1(ix)
	.endif
	cp c
	jr z, clear7
	ld (de), a; de back to top of char again (colour map)

clear7:

	.else; not DISP_HICOLOUR

coloursprite:
	pop hl; hl = char struct + 9
	inc hl
	.if DISP_SPECTRUM
;; na_th_an
;   ld a,(hl)                     ; colour
;   cp $80                        ; special transparent colour
;   jr z, clear
;   ld (tempcolour),a

clear:
	.endif
	.endif

	inc hl; hl = char struct + 11
	ld a, (hl)
	or a
	.if NOFLICKER
	jr z, copybuffer
	.else
	jr z, nomoresprites
	.endif
	inc hl
	ld l, (hl)
	ld h, a; hl = char struct + 4 of next sprite
	jp spriteloop

	.if NOFLICKER
copybuffer:
	pop de; de = screen address of top of char
	ld hl, #tempgraphic
	ld a, (hl); copy buffered tempgraphic to screen
	ld (de), a
	inc d
	inc hl
	ld a, (hl)
	ld (de), a
	inc d
	inc hl
	ld a, (hl)
	ld (de), a
	inc d
	inc hl
	ld a, (hl)
	ld (de), a
	inc d
	inc hl
	ld a, (hl)
	ld (de), a
	inc d
	inc hl
	ld a, (hl)
	ld (de), a
	inc d
	inc hl
	ld a, (hl)
	ld (de), a
	inc d
	inc hl
	ld a, (hl)
	ld (de), a

	.if DISP_HICOLOUR
	inc hl; copy colour to screen
	set 5, d
	ld a, (hl)
	ld (de), a
	inc hl
	dec d
	ld a, (hl)
	ld (de), a
	inc hl
	dec d
	ld a, (hl)
	ld (de), a
	inc hl
	dec d
	ld a, (hl)
	ld (de), a
	inc hl
	dec d
	ld a, (hl)
	ld (de), a
	inc hl
	dec d
	ld a, (hl)
	ld (de), a
	inc hl
	dec d
	ld a, (hl)
	ld (de), a
	inc hl
	dec d
	ld a, (hl)
	ld (de), a
	.endif
	.endif

nomoresprites:
	.if DISP_SPECTRUM
	.if DISP_TMXDUAL
	ld a, d
	and #0x20
	ld l, a
	xor d
	.else
	ld a, d; de = screen address of last scan line in char
	.endif
	xor #0x85; find corresponding attribute address
	rrca
	rrca
	rrca
	.if DISP_TMXDUAL
	or l
	.endif
	ld d, a
	ld a, (tempcolour); what's the final colour of this square?

	.if FLASHASFG
   ;; na_th_an
	and #127
	.endif

	ld (de), a
	.endif

	exx
	pop af
	ret


masknorotate:
	ex de, hl; hl = screen address
	ld a, (bc)
	ld e, a; e = graphic
	inc bc
	ld a, (bc); a = mask
	and (hl); portion of screen remaining
	or e; or in sprite graphic
	ld (hl), a; write to screen
	.if NOFLICKER
	inc hl
	.else
	inc h; next scan line
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat 8 times in total for whole char
	ld e, a
	inc bc
	ld a, (bc)
	and (hl)
	or e
	ld (hl), a
	.if NOFLICKER
	inc hl
	.else
	inc h
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld e, a
	inc bc
	ld a, (bc)
	and (hl)
	or e
	ld (hl), a
	.if NOFLICKER
	inc hl
	.else
	inc h
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld e, a
	inc bc
	ld a, (bc)
	and (hl)
	or e
	ld (hl), a
	.if NOFLICKER
	inc hl
	.else
	inc h
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld e, a
	inc bc
	ld a, (bc)
	and (hl)
	or e
	ld (hl), a
	.if NOFLICKER
	inc hl
	.else
	inc h
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld e, a
	inc bc
	ld a, (bc)
	and (hl)
	or e
	ld (hl), a
	.if NOFLICKER
	inc hl
	.else
	inc h
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld e, a
	inc bc
	ld a, (bc)
	and (hl)
	or e
	ld (hl), a
	.if NOFLICKER
	inc hl
	.else
	inc h
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld e, a
	inc bc
	ld a, (bc)
	and (hl)
	or e
	ld (hl), a
	ex de, hl
	.if DISP_HICOLOUR
	pop hl
	inc hl
	.ifeq COMPRESS
	jp noclrrotate
	.else
	jp DUPnoclrrotate
	.endif
	.else
	jp coloursprite; back to colour the sprite
	.endif


loadtype:
	ld a, h; have a look at the rotation being used
	and #0x0e
	jp z, loadnorotate; if no rotation draw the fast way

	ld a, (bc); sprite graphic
	ld l, a
	ld a, (hl); rotated right
	inc h
	ld l, 0(ix); get graphic on the left
	or (hl); a = graphic rotated right | graphic rot. right from left
	dec h
	ld (de), a; write to screen
	.if NOFLICKER
	inc de
	.else
	inc d; next scan line
	.endif
	.ifeq COMPRESS
	inc bc; skip mask
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat 8 times total for entire char
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	.ifeq COMPRESS
	ld l, 3(ix)
	.else
	ld l, 2(ix)
	.endif
	.else
	.ifeq COMPRESS
	ld l, 2(ix)
	.else
	ld l, 1(ix)
	.endif
	.endif
	or (hl)
	dec h
	ld (de), a
	.if NOFLICKER
	inc de
	.else
	inc d
	.endif
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	.ifeq COMPRESS
	ld l, 6(ix)
	.else
	ld l, 4(ix)
	.endif
	.else
	.ifeq COMPRESS
	ld l, 4(ix)
	.else
	ld l, 2(ix)
	.endif
	.endif
	or (hl)
	dec h
	ld (de), a
	.if NOFLICKER
	inc de
	.else
	inc d
	.endif
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	.ifeq COMPRESS
	ld l, 9(ix)
	.else
	ld l, 6(ix)
	.endif
	.else
	.ifeq COMPRESS
	ld l, 6(ix)
	.else
	ld l, 3(ix)
	.endif
	.endif
	or (hl)
	dec h
	ld (de), a
	.if NOFLICKER
	inc de
	.else
	inc d
	.endif
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	.ifeq COMPRESS
	ld l, 12(ix)
	.else
	ld l, 8(ix)
	.endif
	.else
	.ifeq COMPRESS
	ld l, 8(ix)
	.else
	ld l, 4(ix)
	.endif
	.endif
	or (hl)
	dec h
	ld (de), a
	.if NOFLICKER
	inc de
	.else
	inc d
	.endif
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	.ifeq COMPRESS
	ld l, 15(ix)
	.else
	ld l, 10(ix)
	.endif
	.else
	.ifeq COMPRESS
	ld l, 10(ix)
	.else
	ld l, 5(ix)
	.endif
	.endif
	or (hl)
	dec h
	ld (de), a
	.if NOFLICKER
	inc de
	.else
	inc d
	.endif
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	.ifeq COMPRESS
	ld l, 18(ix)
	.else
	ld l, 12(ix)
	.endif
	.else
	.ifeq COMPRESS
	ld l, 12(ix)
	.else
	ld l, 6(ix)
	.endif
	.endif
	or (hl)
	dec h
	ld (de), a
	.if NOFLICKER
	inc de
	.else
	inc d
	.endif
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	.ifeq COMPRESS
	ld l, 21(ix)
	.else
	ld l, 14(ix)
	.endif
	.else
	.ifeq COMPRESS
	ld l, 14(ix)
	.else
	ld l, 7(ix)
	.endif
	.endif
	or (hl)
	dec h
	ld (de), a
	.ifeq COMPRESS
	.if DISP_HICOLOUR
	inc bc
	.endif
	.endif
	jp coloursprite


loadnorotate:
	.if NOFLICKER
	ld l, c
	ld h, b; hl = sprite graphic
	ldi; copy graphic to temp buffer
	.ifeq COMPRESS
	inc hl; skip mask
	.endif
	.if DISP_HICOLOUR
	inc hl; skip colour for now
	.endif
	ldi; repeat
	.ifeq COMPRESS
	inc hl
	.endif
	.if DISP_HICOLOUR
	inc hl
	.endif
	ldi; repeat
	.ifeq COMPRESS
	inc hl
	.endif
	.if DISP_HICOLOUR
	inc hl
	.endif
	ldi; repeat
	.ifeq COMPRESS
	inc hl
	.endif
	.if DISP_HICOLOUR
	inc hl
	.endif
	ldi; repeat
	.ifeq COMPRESS
	inc hl
	.endif
	.if DISP_HICOLOUR
	inc hl
	.endif
	ldi; repeat
	.ifeq COMPRESS
	inc hl
	.endif
	.if DISP_HICOLOUR
	inc hl
	.endif
	ldi; repeat
	.ifeq COMPRESS
	inc hl
	.endif
	.if DISP_HICOLOUR
	inc hl
	.endif
	ldi; repeat
	.if COMPRESS
	dec hl
	.endif
	dec de
	ld c, l
	ld b, h

	.else

	ld a, (bc); graphic
	ld (de), a; write to screen
	inc d; next scan line
	.ifeq COMPRESS
	inc bc; skip mask
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat 8 times total for entire char
	ld (de), a
	inc d
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld (de), a
	inc d
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld (de), a
	inc d
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld (de), a
	inc d
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld (de), a
	inc d
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld (de), a
	inc d
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld (de), a
	.ifeq COMPRESS
	.if DISP_HICOLOUR
	inc bc
	.endif
	.endif
	.endif

	.if DISP_HICOLOUR
	pop hl
	inc hl
	jp noclrrotate
	.else
	jp coloursprite
	.endif

xortype:
	ld a, h; have a look at the rotation applied
	and #0x0e
	jp z, xornorotate; if no rotation draw the fast way

	ld a, (bc); graphic
	ld l, a
	ld a, (hl); graphic rotated right
	inc h
	ld l, 0(ix); graphic from left
	or (hl); a = final graphic
	dec h
	ex de, hl; hl = screen address
	xor (hl); xor graphic onto screen
	ld (hl), a
	ex de, hl
	.if NOFLICKER
	inc de
	.else
	inc d; next scan line
	.endif
	.ifeq COMPRESS
	inc bc; ignore mask
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat 8 times in total for entire char
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	ld l, 3(ix)
	.else
	ld l, 2(ix)
	.endif
	or (hl)
	dec h
	ex de, hl
	xor (hl)
	ld (hl), a
	ex de, hl
	.if NOFLICKER
	inc de
	.else
	inc d
	.endif
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	ld l, 6(ix)
	.else
	ld l, 4(ix)
	.endif
	or (hl)
	dec h
	ex de, hl
	xor (hl)
	ld (hl), a
	ex de, hl
	.if NOFLICKER
	inc de
	.else
	inc d
	.endif
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	ld l, 9(ix)
	.else
	ld l, 6(ix)
	.endif
	or (hl)
	dec h
	ex de, hl
	xor (hl)
	ld (hl), a
	ex de, hl
	.if NOFLICKER
	inc de
	.else
	inc d
	.endif
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	ld l, 12(ix)
	.else
	ld l, 8(ix)
	.endif
	or (hl)
	dec h
	ex de, hl
	xor (hl)
	ld (hl), a
	ex de, hl
	.if NOFLICKER
	inc de
	.else
	inc d
	.endif
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	ld l, 15(ix)
	.else
	ld l, 10(ix)
	.endif
	or (hl)
	dec h
	ex de, hl
	xor (hl)
	ld (hl), a
	ex de, hl
	.if NOFLICKER
	inc de
	.else
	inc d
	.endif
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	ld l, 18(ix)
	.else
	ld l, 12(ix)
	.endif
	or (hl)
	dec h
	ex de, hl
	xor (hl)
	ld (hl), a
	ex de, hl
	.if NOFLICKER
	inc de
	.else
	inc d
	.endif
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	ld l, 21(ix)
	.else
	ld l, 14(ix)
	.endif
	or (hl)
	dec h
	ex de, hl
	xor (hl)
	ld (hl), a
	ex de, hl
	.ifeq COMPRESS
	.if DISP_HICOLOUR
	inc bc
	.endif
	.endif
	jp coloursprite


xornorotate:
	ex de, hl; hl = screen address
	ld a, (bc); graphic
	xor (hl); xor onto screen
	ld (hl), a
	.if NOFLICKER
	inc hl
	.else
	inc h; next scan line
	.endif
	.ifeq COMPRESS
	inc bc; skip mask
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat total of 8 times for entire char
	xor (hl)
	ld (hl), a
	.if NOFLICKER
	inc hl
	.else
	inc h
	.endif
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	xor (hl)
	ld (hl), a
	.if NOFLICKER
	inc hl
	.else
	inc h
	.endif
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	xor (hl)
	ld (hl), a
	.if NOFLICKER
	inc hl
	.else
	inc h
	.endif
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	xor (hl)
	ld (hl), a
	.if NOFLICKER
	inc hl
	.else
	inc h
	.endif
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	xor (hl)
	ld (hl), a
	.if NOFLICKER
	inc hl
	.else
	inc h
	.endif
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	xor (hl)
	ld (hl), a
	.if NOFLICKER
	inc hl
	.else
	inc h
	.endif
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	xor (hl)
	ld (hl), a
	ex de, hl; de = screen address
	.if DISP_HICOLOUR
	.ifeq COMPRESS
	inc bc
	.endif
	pop hl
	inc hl
	jp noclrrotate
	.else
	jp coloursprite
	.endif

ortype:
	ld a, h; have a look at the rotation applied
	and #0x0e
	jp z, ornorotate; if no rotation draw the fast way

	ld a, (bc); graphic
	ld l, a
	ld a, (hl); graphic rotated right
	inc h
	ld l, 0(ix); graphic from left
	or (hl); a = final graphic
	dec h
	ex de, hl; hl = screen address
	or (hl); or graphic onto screen
	ld (hl), a
	ex de, hl
	.if NOFLICKER
	inc de
	.else
	inc d; next scan line
	.endif
	.ifeq COMPRESS
	inc bc; ignore mask
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat 8 times in total for entire char
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	ld l, 3(ix)
	.else
	ld l, 2(ix)
	.endif
	or (hl)
	dec h
	ex de, hl
	or (hl)
	ld (hl), a
	ex de, hl
	.if NOFLICKER
	inc de
	.else
	inc d
	.endif
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	ld l, 6(ix)
	.else
	ld l, 4(ix)
	.endif
	or (hl)
	dec h
	ex de, hl
	or (hl)
	ld (hl), a
	ex de, hl
	.if NOFLICKER
	inc de
	.else
	inc d
	.endif
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	ld l, 9(ix)
	.else
	ld l, 6(ix)
	.endif
	or (hl)
	dec h
	ex de, hl
	or (hl)
	ld (hl), a
	ex de, hl
	.if NOFLICKER
	inc de
	.else
	inc d
	.endif
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	ld l, 12(ix)
	.else
	ld l, 8(ix)
	.endif
	or (hl)
	dec h
	ex de, hl
	or (hl)
	ld (hl), a
	ex de, hl
	.if NOFLICKER
	inc de
	.else
	inc d
	.endif
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	ld l, 15(ix)
	.else
	ld l, 10(ix)
	.endif
	or (hl)
	dec h
	ex de, hl
	or (hl)
	ld (hl), a
	ex de, hl
	.if NOFLICKER
	inc de
	.else
	inc d
	.endif
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	ld l, 18(ix)
	.else
	ld l, 12(ix)
	.endif
	or (hl)
	dec h
	ex de, hl
	or (hl)
	ld (hl), a
	ex de, hl
	.if NOFLICKER
	inc de
	.else
	inc d
	.endif
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	ld l, a
	ld a, (hl)
	inc h
	.if DISP_HICOLOUR
	ld l, 21(ix)
	.else
	ld l, 14(ix)
	.endif
	or (hl)
	dec h
	ex de, hl
	or (hl)
	ld (hl), a
	ex de, hl
	.ifeq COMPRESS
	.if DISP_HICOLOUR
	inc bc
	.endif
	.endif
	jp coloursprite


ornorotate:
	ex de, hl; hl = screen address
	ld a, (bc); graphic
	or (hl); or onto screen
	ld (hl), a
	.if NOFLICKER
	inc hl
	.else
	inc h; next scan line
	.endif
	.ifeq COMPRESS
	inc bc; skip mask
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat total of 8 times for entire char
	or (hl)
	ld (hl), a
	.if NOFLICKER
	inc hl
	.else
	inc h
	.endif
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	or (hl)
	ld (hl), a
	.if NOFLICKER
	inc hl
	.else
	inc h
	.endif
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	or (hl)
	ld (hl), a
	.if NOFLICKER
	inc hl
	.else
	inc h
	.endif
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	or (hl)
	ld (hl), a
	.if NOFLICKER
	inc hl
	.else
	inc h
	.endif
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	or (hl)
	ld (hl), a
	.if NOFLICKER
	inc hl
	.else
	inc h
	.endif
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	or (hl)
	ld (hl), a
	.if NOFLICKER
	inc hl
	.else
	inc h
	.endif
	.ifeq COMPRESS
	inc bc
	.endif
	.if DISP_HICOLOUR
	inc bc; skip colour for now
	.endif
	inc bc

	ld a, (bc); repeat
	or (hl)
	ld (hl), a
	ex de, hl; de = screen address
	.if DISP_HICOLOUR
	.ifeq COMPRESS
	inc bc
	.endif
	pop hl
	inc hl
	jp noclrrotate
	.else
	jp coloursprite
	.endif
