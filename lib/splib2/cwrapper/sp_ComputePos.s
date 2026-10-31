; sp_ComputePos (envoltorio __smallc para SDCC)
; void sp_ComputePos (struct sp_PSS *ps, uchar x, uchar y)

	.module sp_ComputePos
	.globl _sp_ComputePos
	.globl __sp_ixsave

	.area _CODE

_sp_ComputePos::
	ld (__sp_ixsave), ix

	.globl SPPrintString
	.globl sp_pssread
	.globl sp_psswrite

	ld hl, #2
	add hl, sp
	ld d, (hl)
	ld e, #22
	inc hl
	inc hl
	ld c, (hl)
	ld b, #0
	inc hl
	inc hl
	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a
	push hl
	push bc
	push de
	call sp_pssread
	ld hl, #0
	add hl, sp
	call SPPrintString
	pop hl
	pop hl
	pop hl
	call sp_psswrite

__sp_ComputePos_ret:
	ld ix, (__sp_ixsave)
	ret
