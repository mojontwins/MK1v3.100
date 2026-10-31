; sp_Random32 (envoltorio __smallc para SDCC)
; uint sp_Random32 (uint *hi)

	.module sp_Random32
	.globl _sp_Random32
	.globl __sp_ixsave

	.area _CODE

_sp_Random32::
	ld (__sp_ixsave), ix

	.globl SPRandom32

	ld hl, #2
	add hl, sp
	ld e, (hl)
	inc hl
	ld d, (hl)
	push de
	call SPRandom32
	ex (sp), hl
	ld (hl), e
	inc hl
	ld (hl), d
	pop hl

__sp_Random32_ret:
	ld ix, (__sp_ixsave)
	ret
