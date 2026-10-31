; sp_MoveSprRelNC (envoltorio __smallc para SDCC)
; void sp_MoveSprRelNC (struct sp_SS *sprite, struct sp_Rect *clip, int animate, char rel_row, char rel_col, char rel_hpix, char rel_vpix)

	.module sp_MoveSprRelNC
	.globl _sp_MoveSprRelNC
	.globl __sp_ixsave

	.area _CODE

_sp_MoveSprRelNC::
	ld (__sp_ixsave), ix

	.globl sp_moveabshelp
	.globl SPMoveSprRel
	.globl SPMoveSprRelNC

	call sp_moveabshelp; parse parameters -- cheat: same parameter types as MoveSprAbs
	call SPMoveSprRelNC
	pop hl; deallocate 4-byte clip struct on stack
	pop hl; that was allocated by sp_moveabshelp

__sp_MoveSprRelNC_ret:
	ld ix, (__sp_ixsave)
	ret
