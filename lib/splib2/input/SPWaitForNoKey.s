;
; WaitForNoKey
; Alvin Albrecht 2002
;
; Return when no keys are pressed.
;
; uses: af

	.module SPWaitForNoKey
	.globl SPWaitForNoKey

SPWaitForNoKey:
	xor a
	in a, (#0xfe)
	and #0x1f
	cp #31
	jr nz, SPWaitForNoKey
	ret
