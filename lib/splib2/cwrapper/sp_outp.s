; sp_outp (envoltorio __smallc para SDCC)
; void sp_outp (uint port, uchar value)

	.module sp_outp
	.globl _sp_outp
	.globl __sp_ixsave

	.area _CODE

_sp_outp::
	ld (__sp_ixsave), ix

	ld hl, #2
	add hl, sp
	ld a, (hl)
	inc hl
	inc hl
	ld c, (hl)
	inc hl
	ld b, (hl)
	out (c), a

__sp_outp_ret:
	ld ix, (__sp_ixsave)
	ret
