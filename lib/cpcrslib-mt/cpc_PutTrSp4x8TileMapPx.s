; ******************************************************
; **       Librería de rutinas para Amstrad CPC       **
; **	   Raúl Simarro, 	  Artaburu 2007           **
; ******************************************************

; [na_th_an] Modificada por Mojon Twins - eliminamos la "cabecera" de los sprites.
; [na_th_an] Gracias a Fran Gallego y al código de la CPCTelera, rescrito para usar LUTs
; [na_th_an] Esta nueva vesión de la rutina imprime al pixel en m0
; Necesita una LUT en $FE00

	.module cpc_PutTrSp4x8TileMapPx
	.globl cpc_PutTrSp4x8TileMapPx
	.include "CPCconfig.inc"
	.area _CODE

	.globl posiciones_super_buffer
	.globl tiles

cpc_PutTrSp4x8TileMapPx:

	;según las coordenadas x,y que tenga el sprite, se dibuja en el buffer
	ex de, hl;4
	.db 0xdd
	ld h, d;9
	.db 0xdd
	ld l, e;9 

	;lo cambio para la rutina de multiplicar
	ld e, 8(ix);x
	ld a, e; Save for later!
	srl e; X a bytes
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
	ld d, 1(ix);de apunta al sprite

sp_buffer_mask:
	.db 0xdd
	ld h, #8
	ex de, hl; de -> bg
	ld b, h
	ld c, l; bc -> sprite

	; Remember A = X in pixels
	and #1
	jr nz, loop_alto_map_sbuffer_shifted

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

loop_alto_map_sbuffer_shifted:
	ld h, #0xFE; 	; hl -> LUT

	; El ancho está desenrollado. Procesamos 4 bytes que copiamos en 3:
	; 1. AB -> BA, byte 1 = BA And 0x55                    = 0A
	; 2. CD -> DC, byte 2 = (BA And 0xAA) OR (DC And 0x55) = BC
	; 3.         , byte 5 = (DC And 0xAA)                  = D0

	;; Byte 1 :
	;; AB -> BA, byte 1 = BA And 0x55                    = 0A

	ld a, (bc); Get sprite byte AB

	;; swap pixels in byte
	ld l, a
	rlca
	rlca
	xor l
	and #0x55; 01010101
	xor l
	rrca; A = BA
	.db 0xdd
	ld l, a; Save for next byte

	and #0x55

	ld l, a; copy to L to index LUT
	ld a, (de); Get bg
	and (hl); make a hole
	or l; draw pixels
	ld (de), a; save bg + masked sprite
	inc de
	inc bc

	;; Byte 2
	;; CD -> DC, byte 2 = (BA And 0xAA) OR (DC And 0x55) = BC

	.db 0xdd
	ld a, l; BA
	and #0xAA; B0
	.db 0xfd
	ld l, a; IYL = B0

	ld a, (bc); Get sprite byte CD

	;; swap pixels in byte
	ld l, a
	rlca
	rlca
	xor l
	and #0x55; 01010101
	xor l
	rrca; A = DC
	.db 0xdd
	ld l, a; IXL = DC

	and #0x55; A = 0C
	.db 0xfd
	or l; A = BC

	ld l, a; copy to L to index LUT
	ld a, (de); Get bg
	and (hl); make a hole
	or l; draw pixels
	ld (de), a; save BG
	inc de
	inc bc

	;; Byte 3
	;; byte 5 = (DC And 0xAA) = D0

	.db 0xdd
	ld a, l; DC
	and #0xaa; H0

	ld l, a; copy to L to index LUT
	ld a, (de); Get bg
	and (hl); make a hole
	or l; draw pixels
	ld (de), a; save BG

	;*************************************************

	.db 0xdd
	dec h
	ret z

	; de += 62 (next line in bg)
	ld hl, #62
	add hl, de
	ex de, hl

	jp loop_alto_map_sbuffer_shifted


; Entrada desde C: guarda IX, que la rutina usa y SDCC necesita
_cpc_PutTrSp4x8TileMapPx::
	push ix
	call cpc_PutTrSp4x8TileMapPx
	pop ix
	ret
