; sp_MoveSprAbsNC (envoltorio __smallc para SDCC)
; void sp_MoveSprAbsNC (struct sp_SS *sprite, struct sp_Rect *clip, int animate, uchar row, uchar col, uchar hpix, uchar vpix)

	.module sp_MoveSprAbsNC
	.globl _sp_MoveSprAbsNC
	.globl __sp_ixsave

	.area _CODE

_sp_MoveSprAbsNC::
	ld (__sp_ixsave), ix

	.globl sp_moveabshelp
	.globl SPMoveSprAbs
	.globl SPMoveSprAbsNC

	call sp_moveabshelp; parse parameters
	call SPMoveSprAbsNC
	pop hl; deallocate 4-byte clip struct on stack
	pop hl; that was allocated by sp_moveabshelp

__sp_MoveSprAbsNC_ret:
	ld ix, (__sp_ixsave)
	ret
