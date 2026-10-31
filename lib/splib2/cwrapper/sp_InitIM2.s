; sp_InitIM2 (envoltorio __smallc para SDCC)
; void sp_InitIM2 (void *isr)

	.module sp_InitIM2
	.globl _sp_InitIM2
	.globl __sp_ixsave

	.area _CODE

_sp_InitIM2::
	ld (__sp_ixsave), ix

	.globl SPInitIM2

	ld hl, #2
	add hl, sp
	ld c, (hl)
	inc hl
	ld b, (hl)
	call SPInitIM2

__sp_InitIM2_ret:
	ld ix, (__sp_ixsave)
	ret
