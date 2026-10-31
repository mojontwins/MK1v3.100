; sp_MoveSprRelC (envoltorio __smallc para SDCC)
; void sp_MoveSprRelC (struct sp_SS *sprite, struct sp_Rect *clip, int animate, char rel_row, char rel_col, char rel_hpix, char rel_vpix)

	.module sp_MoveSprRelC
	.globl _sp_MoveSprRelC
	.globl __sp_ixsave

	.area _CODE

_sp_MoveSprRelC::
	ld (__sp_ixsave), ix

	.globl sp_moveabshelp
	.globl SPMoveSprRel
	.globl SPMoveSprRelC

	call sp_moveabshelp; parse parameters -- cheat: same parameter types as MoveSprAbs
	call SPMoveSprRelC
	pop hl; deallocate 4-byte clip struct on stack
	pop hl; that was allocated by sp_moveabshelp

__sp_MoveSprRelC_ret:
	ld ix, (__sp_ixsave)
	ret
