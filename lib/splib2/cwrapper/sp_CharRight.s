; sp_CharRight (envoltorio __smallc para SDCC)
; void * sp_CharRight (void *scrnaddr)

	.module sp_CharRight
	.globl _sp_CharRight
	.globl __sp_ixsave

	.area _CODE

_sp_CharRight::
	ld (__sp_ixsave), ix

	.globl SPCharRight

	ld hl, #2
	add hl, sp
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex de, hl
	or a
	call SPCharRight

__sp_CharRight_ret:
	ld ix, (__sp_ixsave)
	ret
