; ******************************************************
; **       Librería de rutinas para Amstrad CPC       **
; **	   Raúl Simarro, 	  Artaburu 2007       **
; ******************************************************

	.module cpc_TestKey
	.globl cpc_TestKey
	.area _CODE

	.globl cpc_TestKeyboard
;XREF linea_a_buscar

	.globl cpc_KeysData
	.globl tabla_teclas0

_cpc_TestKey::
cpc_TestKey:

	sla L
	inc l
	ld h, #0
	ld de, #tabla_teclas0		; tabla de teclas (cpc_KeysData + 12)

	add hl, de

	ld a, (HL)
	call cpc_TestKeyboard; esta rutina lee la línea del teclado correspondiente 
	dec hl; pero sólo nos interesa una de las teclas.
	and (HL);para filtrar por el bit de la tecla (puede haber varias pulsadas)
	cp (hl);comprueba si el byte coincide
	ld h, #0
	jp z, pulsado
	ld l, h
	ret
pulsado:
	ld l, #1
	ret
