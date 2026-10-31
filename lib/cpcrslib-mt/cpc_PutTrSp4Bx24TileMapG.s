; ******************************************************
; **       Librería de rutinas para Amstrad CPC       **
; **	   Raúl Simarro, 	  Artaburu 2007           **
; ******************************************************

; [na_th_an] Modificada por Mojon Twins - eliminamos la "cabecera" de los sprites.
; [na_th_an] Esta versión utiliza OR para mezclar con lo que ya haya. No necesita LUT.

	.module cpc_PutTrSp4Bx24TileMapG
	.globl cpc_PutTrSp4Bx24TileMapG
	.include "CPCconfig.inc"
	.area _CODE

	.globl posiciones_super_buffer
	.globl tiles

cpc_PutTrSp4Bx24TileMapG:

	;según las coordenadas x,y que tenga el sprite, se dibuja en el buffer
	ex de, hl;4
	.db 0xdd
	ld h, d;9
	.db 0xdd
	ld l, e;9 

	;lo cambio para la rutina de multiplicar
	ld e, 8(ix);x
	ld h, 9(ix);y

pasa_bloque_a_sbuffer:

transferir_sprite:
	ld d, #0

	; Multiplico HL = H * 64, offset "Y"
	ld l, #0
	srl h
	rr l
	srl h
	rr l

	add hl, de; sumo offset "X"

	ld de, #posicion_inicial_superbuffer
	add hl, de

	;hl apunta a la posición en buffer (destino)

	ld e, 0(ix)
	ld d, 1(ix);HL apunta al sprite

sp_buffer_mask:
	.db 0xdd
	ld h, #24

loop_alto_map_sbuffer:

	; El ancho está desenrollado: Hay que procesar y copiar 4 bytes.

	ld a, (de); Get sprite
	or (hl); Get bg + draw pixels
	ld (hl), a; save BG+sprite
	inc de
	inc hl

	ld a, (de); Get sprite
	or (hl); Get bg + draw pixels
	ld (hl), a; save BG+sprite
	inc de
	inc hl

	ld a, (de); Get sprite
	or (hl); Get bg + draw pixels
	ld (hl), a; save BG+sprite
	inc de
	inc hl

	ld a, (de); Get sprite
	or (hl); Get bg + draw pixels
	ld (hl), a; save BG+sprite
	inc de

	;*************************************************

	.db 0xdd
	dec h
	ret z

	; de += 61 (next line in bg)
	ld bc, #61
	add hl, bc

	jp loop_alto_map_sbuffer


; Entrada desde C: guarda IX, que la rutina usa y SDCC necesita
_cpc_PutTrSp4Bx24TileMapG::
	push ix
	call cpc_PutTrSp4Bx24TileMapG
	pop ix
	ret
