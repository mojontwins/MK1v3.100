; sp_Initialize (envoltorio __smallc para SDCC)
; void sp_Initialize (uchar colour, uchar graphic)

	.module sp_Initialize
	.globl _sp_Initialize
	.globl __sp_ixsave

	.area _CODE

_sp_Initialize::
	ld (__sp_ixsave), ix

	.globl SPInitialize

	ld hl, #2
	add hl, sp
	ld e, (hl)
	inc hl
	inc hl
	ld d, (hl)
	call SPInitialize

__sp_Initialize_ret:
	ld ix, (__sp_ixsave)
	ret
