; ******************************************************
; **       Librería de rutinas para Amstrad CPC       **
; **	   Raúl Simarro, 	  Artaburu 2007           **
; ******************************************************

; [na_th_an] Modificada por Mojon Twins - eliminamos la "cabecera" de los sprites.
; [na_th_an] Gracias a Fran Gallego y al código de la CPCTelera, rescrito para usar LUTs
; Necesita una LUT en $FE00

	.module cpc_PutTrSp2Bx8TileMap
	.globl cpc_PutTrSp2Bx8TileMap
	.include "CPCconfig.inc"
	.area _CODE

	.globl posiciones_super_buffer
	.globl tiles

cpc_PutTrSp2Bx8TileMap:

	;según las coordenadas x,y que tenga el sprite, se dibuja en el buffer
	ex de, hl;4
	.db 0xdd
	ld h, d;9
	.db 0xdd
	ld l, e;9 

	;lo cambio para la rutina de multiplicar
	ld e, 8(ix);X en bytes! (0-63)
	ld h, 9(ix);Y

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
	ld d, 1(ix);de apunta al sprite

sp_buffer_mask:
	.db 0xdd
	ld h, #8
	ex de, hl; de -> bg
	ld b, h
	ld c, l; bc -> sprite

loop_alto_map_sbuffer:
	ld h, #0xFE; hl -> LUT

	; El ancho está desenrollado: Hay que procesar y copiar 2 bytes.

	ld a, (bc); Get sprite
	ld l, a; copy to L to index LUT
	ld a, (de); Get bg
	and (hl); make a hole
	or l; draw pixels
	ld (de), a; save BG
	inc de
	inc bc

	ld a, (bc); Get sprite
	ld l, a; copy to L to index LUT
	ld a, (de); Get bg
	and (hl); make a hole
	or l; draw pixels
	ld (de), a; save BG
	inc de
	inc bc

	;*************************************************

	.db 0xdd
	dec h
	ret z

	; de += 62 (next line in bg)
	ld hl, #62
	add hl, de
	ex de, hl

	jp loop_alto_map_sbuffer


; Entrada desde C: guarda IX, que la rutina usa y SDCC necesita
_cpc_PutTrSp2Bx8TileMap::
	push ix
	call cpc_PutTrSp2Bx8TileMap
	pop ix
	ret
