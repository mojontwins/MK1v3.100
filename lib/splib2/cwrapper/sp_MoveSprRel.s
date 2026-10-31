; sp_MoveSprRel (envoltorio __smallc para SDCC)
; void sp_MoveSprRel (struct sp_SS *sprite, struct sp_Rect *clip, int animate, char rel_row, char rel_col, char rel_hpix, char rel_vpix)

	.module sp_MoveSprRel
	.globl _sp_MoveSprRel
	.globl __sp_ixsave

	.area _CODE

_sp_MoveSprRel::
	ld (__sp_ixsave), ix

	.globl sp_moveabshelp
	.globl SPMoveSprRel

	call sp_moveabshelp; parse parameters -- cheat: same parameter order as MoveSprAbs
	call SPMoveSprRel
	pop hl; deallocate 4-byte clip struct on stack
	pop hl; that was allocated by sp_moveabshelp

__sp_MoveSprRel_ret:
	ld ix, (__sp_ixsave)
	ret
