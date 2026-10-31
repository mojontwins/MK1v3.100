; sp_SetMousePosKempston (envoltorio __smallc para SDCC)
; void sp_SetMousePosKempston (uint xcoord, uchar ycoord)

	.module sp_SetMousePosKempston
	.globl _sp_SetMousePosKempston
	.globl __sp_ixsave

	.area _CODE

_sp_SetMousePosKempston::
	ld (__sp_ixsave), ix

	.include "SPconfig.inc"
	.globl SPSetMousePosKempston

	ld hl, #2
	add hl, sp
	ld d, (hl)
	inc hl
	inc hl
	ld e, (hl)
	inc hl
	.if DISP_HIRES
	ld a, (hl)
	rra
	.endif
	ex de, hl
	call SPSetMousePosKempston

__sp_SetMousePosKempston_ret:
	ld ix, (__sp_ixsave)
	ret
