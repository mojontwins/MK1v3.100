; sp_ListRemove (envoltorio __smallc para SDCC)
; void * sp_ListRemove (struct sp_List *list)

	.module sp_ListRemove
	.globl _sp_ListRemove
	.globl __sp_ixsave

	.area _CODE

_sp_ListRemove::
	ld (__sp_ixsave), ix

	.globl SPListRemove

	pop bc
	pop hl
	push hl
	push bc
	call SPListRemove
	ccf
	ex de, hl
	jp nc, __sp_ListRemove_ret
	ld hl, #0

__sp_ListRemove_ret:
	ld ix, (__sp_ixsave)
	ret
