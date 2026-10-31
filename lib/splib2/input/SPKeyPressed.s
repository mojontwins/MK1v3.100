;
; Key Pressed?
; Alvin Albrecht 01.2003
;

	.module SPKeyPressed
	.globl SPKeyPressed

; Determines if a key is pressed using the scan code
; returned by "LookupKey".
;
; enter : c = scan row
;         b = key mask
; exit  : carry = key is pressed
; used  : af, b

SPKeyPressed:
	bit 7, b
	jp z, nocaps

	ld a, #0xfe; check on CAPS key
	in a, (#0xfe)
	and #0x01
	ret nz; CAPS not pressed, return no carry = fail

nocaps:
	bit 6, b
	jp z, nosym

	ld a, #0x7f; check on SYM SHIFT
	in a, (#0xfe)
	and #0x02
	ret nz; SYM not pressed, return no carry = fail

nosym:
	ld a, b
	and #0x1f
	ld b, c
	ld c, #0xfe
	in b, (c)
	and b
	ret nz; key not pressed, return no carry = fail
	scf
	ret
