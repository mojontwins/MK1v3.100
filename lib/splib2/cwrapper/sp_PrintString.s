; sp_PrintString (envoltorio __smallc para SDCC)
; void sp_PrintString (struct sp_PSS *ps, uchar *s)

	.module sp_PrintString
	.globl _sp_PrintString
	.globl __sp_ixsave

	.area _CODE

_sp_PrintString::
	ld (__sp_ixsave), ix

	.globl SPPrintString
	.globl sp_pssread
	.globl sp_psswrite

	ld hl, #2
	add hl, sp
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl
	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a
	push hl
	push de
	call sp_pssread
	pop hl
	call SPPrintString
	pop hl
	call sp_psswrite

__sp_PrintString_ret:
	ld ix, (__sp_ixsave)
	ret
