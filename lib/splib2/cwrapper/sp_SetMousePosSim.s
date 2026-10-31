; sp_SetMousePosSim (envoltorio __smallc para SDCC)
; void sp_SetMousePosSim (struct sp_UDM *m, uint xcoord, uchar ycoord)

	.module sp_SetMousePosSim
	.globl _sp_SetMousePosSim
	.globl __sp_ixsave

	.area _CODE

_sp_SetMousePosSim::
	ld (__sp_ixsave), ix

	.include "SPconfig.inc"
	.globl SPSetMousePosSim

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
	inc hl
	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a
	ex de, hl
	call SPSetMousePosSim

__sp_SetMousePosSim_ret:
	ld ix, (__sp_ixsave)
	ret
