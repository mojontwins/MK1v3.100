; sp_CharDown (envoltorio __smallc para SDCC)
; void * sp_CharDown (void *scrnaddr)

	.module sp_CharDown
	.globl _sp_CharDown
	.globl __sp_ixsave

	.area _CODE

_sp_CharDown::
	ld (__sp_ixsave), ix

	.globl SPCharDown

	ld hl, #2
	add hl, sp
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex de, hl
	call SPCharDown

__sp_CharDown_ret:
	ld ix, (__sp_ixsave)
	ret
