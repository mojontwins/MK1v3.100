; sp_CharLeft (envoltorio __smallc para SDCC)
; void * sp_CharLeft (void *scrnaddr)

	.module sp_CharLeft
	.globl _sp_CharLeft
	.globl __sp_ixsave

	.area _CODE

_sp_CharLeft::
	ld (__sp_ixsave), ix

	.globl SPCharLeft

	ld hl, #2
	add hl, sp
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex de, hl
	or a
	call SPCharLeft

__sp_CharLeft_ret:
	ld ix, (__sp_ixsave)
	ret
