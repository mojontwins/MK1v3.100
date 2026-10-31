;
; Initialize Sprite Pack's Background Tile & Sprite Module
; Alvin Albrecht 06.2003
;

	.include "SPconfig.inc"
	.module SPInitialize
	.globl SPInitialize
	.globl SProtatetblInitialize
	.globl SPDisplayList
	.globl SPDirtyChars
	.globl SPTileArray

; Initialize
;
; Performs the following sequence:
;
; 1. Clears display list to the "default background tile"
; 2. Marks the entire display list dirty so that it
;    will be redrawn on the next update.
; 3. Creates the horizontal rotation tables.

;
; enter:  e = default background tile # (graphic)
;         d = default background pallette # (colour)
;

SPInitialize:

   ; initialize display list

	ld hl, #SPDisplayList
	ld (hl), d
	inc hl
	ld (hl), e
	inc hl
	ld (hl), #0
	inc hl
	ld (hl), #0
	ld hl, #SPDisplayList
	ld de, #SPDisplayList+4
	.if DISP_HIRES
	ld bc, #4*(64*(SP_ROWEND-SP_ROWSTART)-1)
	.else
	ld bc, #4*(32*(SP_ROWEND-SP_ROWSTART)-1)
	.endif
	ldir

   ; mark entire screen dirty

	ld hl, #SPDirtyChars
	ld de, #SPDirtyChars+1
	ld (hl), #0xff
	.if DISP_HIRES
	ld bc, #8*(SP_ROWEND-SP_ROWSTART)-1
	.else
	ld bc, #4*(SP_ROWEND-SP_ROWSTART)-1
	.endif
	ldir

   ; set up horizontal rotate table

SProtatetblInitialize:

	ld c, #7; rotate by C
rottbllp:
	ld a, c
	add a, a
	or #>SProtatetbl
	ld h, a
	ld l, #0
entrylp:
	ld b, c
	ld e, l
	xor a
rotlp:
	srl e
	rra
	djnz rotlp
	ld (hl), e
	inc h
	ld (hl), a
	dec h
	inc l
	jp nz, entrylp
	dec c
	jp nz, rottbllp

   ; set display mode

	.if DISP_HIRES
	ld a, #0x86
	out (#0xff), a; video mode 512x192, black on white, int enable
	.endif
	.if DISP_HICOLOUR
	ld a, #0x82
	out (#0xff), a; hi-colour video mode, int enable
	.endif

	ret


	.if DISP_HICOLOUR
BONW:
	.db 56,56,56,56,56,56,56,56
	.endif
