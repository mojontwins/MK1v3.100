; loader.asm
; loads the game
; by na_th_an - Thanks to Antonio Villena for his tutorials and utilities.

; this file is to be processed by 'addlens.exe' to setup correct block lengths.

	org $5ccb
	ld sp, 24199
	di
	db	$de, $c0, $37, $0e, $8f, $39, $96 ;OVER USR 7 ($5ccb)
	
; screen 0
	ld	hl, $5800
	ld	de, $5801
	ld	(hl), l
	ldir

; load screen ;;; CHANGE
	scf
	ld	a, $ff
	ld	ix, $8000
	ld	de, 4834
	call $0556
	call $8000
	di

; load RAM1
	ld	a, 16+1
	ld	bc, $7ffd
	out (c), a
	scf
	ld	a, $ff
	ld	ix, $c000
	; Change here
	ld	de, 14729
	call $0556

; load RAM3
	ld	a, 16+3
	ld	bc, $7ffd
	out (c), a
	scf
	ld	a, $ff
	ld	ix, $c000
	; Change here
	ld	de, 14819
	call $0556

; load RAM4
	ld	a, 16+4
	ld	bc, $7ffd
	out (c), a
	scf
	ld	a, $ff
	ld	ix, $c000
	; Change here
	ld	de, 14555
	call $0556

; load RAM6
	ld	a, 16+6
	ld	bc, $7ffd
	out (c), a
	scf
	ld	a, $ff
	ld	ix, $c000
	; Change here
	ld	de, 9497
	call $0556

; restore RAM0 and load binary
	ld	a, 16
	ld	bc, $7ffd
	out (c), a
	scf
	ld	a, $ff
	ld	ix, 24200
	; Change here
	ld	de, 35182
	call $0556
	ei
	
; run game!
	jp 24200
	