; ******************************************************
; **       Librería de rutinas para Amstrad CPC       **
; **	   Raúl Simarro, 	  Artaburu 2009           **
; ******************************************************

; Modified by na_th_an with WASD MN ESC ENTER so I don't need
; cpc_AssignKey at all nor initialization, shaving 144 bytes

	.module cpc_KeysData
	.globl cpc_KeysData
	.area _CODE

	.globl tabla_teclas0

cpc_KeysData:

keymap0:	.ds 10

tecla_0:	.dw 0x0204

tabla_teclas0:

	.dw 0x4404; LEFT     O
	.dw 0x4308; RIGHT    P
	.dw 0x4808; UP       Q
	.dw 0x4820; DOWN     A

	.dw 0x4580; BUTTON_A SPACE
	.dw 0x4808; BUTTON_B Q

	.dw 0x4801; KEY_AUX3 1
	.dw 0x4802; KEY_AUX4 2

	.dw 0x4880; KEY_AUX1 Z
	.dw 0x4780; KEY_AUX2 X

	.dw 0x4204; KEY_ENTER
	.dw 0x4804; KEY_ESC	

	.db 0

