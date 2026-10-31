; sp_SetMousePosAMX (envoltorio __smallc para SDCC)
; void sp_SetMousePosAMX (uint xcoord, uchar ycoord)

	.module sp_SetMousePosAMX
	.globl _sp_SetMousePosAMX
	.globl __sp_ixsave

	.area _CODE

_sp_SetMousePosAMX::
	ld (__sp_ixsave), ix

	.include "SPconfig.inc"
	.globl SPSetMousePosAMX

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
	call SPSetMousePosAMX

__sp_SetMousePosAMX_ret:
	ld ix, (__sp_ixsave)
	ret
