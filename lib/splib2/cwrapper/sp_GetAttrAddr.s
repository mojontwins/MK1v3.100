; sp_GetAttrAddr (envoltorio __smallc para SDCC)
; void * sp_GetAttrAddr (void *scrnaddr)

	.module sp_GetAttrAddr
	.globl _sp_GetAttrAddr
	.globl __sp_ixsave

	.area _CODE

_sp_GetAttrAddr::
	ld (__sp_ixsave), ix

	.globl SPGetAttrAddr

	ld hl, #2
	add hl, sp
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex de, hl
	call SPGetAttrAddr
	ex de, hl

__sp_GetAttrAddr_ret:
	ld ix, (__sp_ixsave)
	ret
