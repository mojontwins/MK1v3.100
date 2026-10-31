; sp_RegisterHook (envoltorio __smallc para SDCC)
; void sp_RegisterHook (uchar vector, void *hook): es sp_RegisterHookLast.

	.module sp_RegisterHook
	.globl _sp_RegisterHook
	.globl _sp_RegisterHookLast

	.area _CODE

_sp_RegisterHook::
	jp _sp_RegisterHookLast
