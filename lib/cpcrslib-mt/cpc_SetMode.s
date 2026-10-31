; ******************************************************
; **       Librería de rutinas para Amstrad CPC       **
; **	                                              **
; ******************************************************

	.module cpc_SetMode
	.globl cpc_SetMode
	.area _CODE

_cpc_SetMode::
cpc_SetMode:
	ld a, l
	ld BC, #0x7F00;Gate array port
	ld D, #0b10001100;Mode  and  rom  selection  (and Gate Array function)
	add D
	out (C), A
	ret
