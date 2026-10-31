;
; WaitForKey
; Alvin Albrecht 2002
;
; Return when a key is pressed.
;
; uses: af

	.module SPWaitForKey
	.globl SPWaitForKey

SPWaitForKey:
	xor a
	in a, (#0xfe)
	and #31
	cp #31
	jr z, SPWaitForKey
	ret
