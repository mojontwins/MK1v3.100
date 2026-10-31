; sp_MoveSprAbsC (envoltorio __smallc para SDCC)
; void sp_MoveSprAbsC (struct sp_SS *sprite, struct sp_Rect *clip, int animate, uchar row, uchar col, uchar hpix, uchar vpix)

	.module sp_MoveSprAbsC
	.globl _sp_MoveSprAbsC
	.globl __sp_ixsave

	.area _CODE

_sp_MoveSprAbsC::
	ld (__sp_ixsave), ix

	.globl sp_moveabshelp
	.globl SPMoveSprAbs
	.globl SPMoveSprAbsC

	call sp_moveabshelp; parse parameters
	call SPMoveSprAbsC
	pop hl; deallocate 4-byte clip struct on stack
	pop hl; that was allocated by sp_moveabshelp

__sp_MoveSprAbsC_ret:
	ld ix, (__sp_ixsave)
	ret
