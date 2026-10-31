; sp_CharUp (envoltorio __smallc para SDCC)
; void * sp_CharUp (void *scrnaddr)

	.module sp_CharUp
	.globl _sp_CharUp
	.globl __sp_ixsave

	.area _CODE

_sp_CharUp::
	ld (__sp_ixsave), ix

	.globl SPCharUp

	ld hl, #2
	add hl, sp
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex de, hl
	call SPCharUp

__sp_CharUp_ret:
	ld ix, (__sp_ixsave)
	ret
