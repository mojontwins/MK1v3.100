; ******************************************************
; **       Librería de rutinas para Amstrad CPC       **
; **	   Raúl Simarro, 	  Artaburu 2007           **
; ******************************************************

; [na_th_an] Modificada por Mojon Twins - eliminamos la "cabecera" de los sprites.
; [na_th_an] Esta versión utiliza OR para mezclar con lo que ya haya. No necesita LUT.

; Esta versión de la rutina asume coordenadas "de celda"
; x = 0-31; y = 0-23.

; El sprite es de 3x3 celdas, o 12x24 ladrillos.

	.module cpc_PutTrSp12x24TileMapGCA
	.globl cpc_PutTrSp12x24TileMapGCA
	.include "CPCconfig.inc"
	.area _CODE

	.globl posiciones_super_buffer
	.globl tiles

cpc_PutTrSp12x24TileMapGCA:

	;según las coordenadas x,y que tenga el sprite, se dibuja en el buffer
	ex de, hl;4
	.db 0xdd
	ld h, d;9
	.db 0xdd
	ld l, e;9 

	;lo cambio para la rutina de multiplicar
	ld e, 8(ix);x
	ld h, 9(ix);y

	sla e; X de rejilla a bytes (x2)

pasa_bloque_a_sbuffer:

transferir_sprite:
	ld d, #0

	; h contiene Y en coordenadas de celda.
	; Para pasar a pixel hay que multiplicar por 512.
	; como H es y al parte alta del registro de 8 bits,
	; es como si ya viniese multiplicada por 256 "de regalo".
	; por tanto:

	ld l, #0
	sla h; x512

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

	; El ancho está desenrollado: Hay que procesar y copiar 6 bytes.

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

	; de += 59 (next line in bg)
	ld bc, #59
	add hl, bc

	jp loop_alto_map_sbuffer


; Entrada desde C: guarda IX, que la rutina usa y SDCC necesita
_cpc_PutTrSp12x24TileMapGCA::
	push ix
	call cpc_PutTrSp12x24TileMapGCA
	pop ix
	ret
