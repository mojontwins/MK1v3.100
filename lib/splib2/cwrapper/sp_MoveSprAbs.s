; sp_MoveSprAbs (envoltorio __smallc para SDCC)
; void sp_MoveSprAbs (struct sp_SS *sprite, struct sp_Rect *clip, int animate, uchar row, uchar col, uchar hpix, uchar vpix)

	.module sp_MoveSprAbs
	.globl _sp_MoveSprAbs
	.globl __sp_ixsave

	.area _CODE

_sp_MoveSprAbs::
	ld (__sp_ixsave), ix

	.globl sp_moveabshelp
	.globl SPMoveSprAbs

	call sp_moveabshelp; parse parameters
	call SPMoveSprAbs
	pop hl; deallocate 4-byte clip struct on stack
	pop hl; that was allocated by sp_moveabshelp

__sp_MoveSprAbs_ret:
	ld ix, (__sp_ixsave)
	ret
