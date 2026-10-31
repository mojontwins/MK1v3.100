; sp_ListTrim (envoltorio __smallc para SDCC)
; void * sp_ListTrim (struct sp_List *list)

	.module sp_ListTrim
	.globl _sp_ListTrim
	.globl __sp_ixsave

	.area _CODE

_sp_ListTrim::
	ld (__sp_ixsave), ix

	.globl SPListTrim

	pop bc
	pop hl
	push hl
	push bc
	call SPListTrim
	ccf
	ex de, hl
	jp nc, __sp_ListTrim_ret
	ld hl, #0

__sp_ListTrim_ret:
	ld ix, (__sp_ixsave)
	ret
