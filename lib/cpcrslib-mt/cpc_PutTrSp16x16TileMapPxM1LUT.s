; ******************************************************
; **       Librería de rutinas para Amstrad CPC       **
; **	   Raúl Simarro, 	  Artaburu 2007           **
; ******************************************************

; [na_th_an] Modificada por Mojon Twins - eliminamos la "cabecera" de los sprites.
; [na_th_an] Gracias a Fran Gallego y al código de la CPCTelera, rescrito para usar LUTs
; [na_th_an] Esta nueva vesión de la rutina imprime al pixel en m1
; Necesita una LUT en $FE00

	.include "CPCconfig.inc"

	.module cpc_PutTrSp16x16TileMapPxM1LUT
	.globl cpc_PutTrSp16x16TileMapPxM1LUT
	.area _CODE

	.globl posiciones_super_buffer

cpc_PutTrSp16x16TileMapPxM1LUT:

	;según las coordenadas x,y que tenga el sprite, se dibuja en el buffer
	ex de, hl;4
	.db 0xdd
	ld h, d;9
	.db 0xdd
	ld l, e;9 

	;lo cambio para la rutina de multiplicar
	ld e, 8(ix); X - Cuidado ! va a pixel (0-255)
	ld a, e; Save for later!
	srl e
	srl e; X a bytes
	ld h, 9(ix); Y

pasa_bloque_a_sbuffer:

transferir_sprite:
	ld d, #0

	; Multiplico HL = H * 64, offset "Y"
	ld l, d
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
	ld h, #16
	ex de, hl; de -> bg
	ld b, h
	ld c, l; bc -> sprite

	; Remember A = X in pixels
	; Select routine based upon number of rotations
	; would write self-modifying code for short but too complicated
	and #3
	jr z, loop_alto_map_sbuffer
	cp #1
	jr z, loop_alto_map_sbuffer_shift1
	cp #2
	jp z, loop_alto_map_sbuffer_shift2
	jp loop_alto_map_sbuffer_shift3

loop_alto_map_sbuffer:
	ld h, #0xFE; hl -> LUT

	; El ancho está desenrollado: Hay que procesar y copiar 4 bytes.

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

	; de += 60 (next line in bg)
	ld hl, #60
	add hl, de
	ex de, hl

	jp loop_alto_map_sbuffer

loop_alto_map_sbuffer_shift1:
	; El ancho está desenrollado. Procesamos 4 bytes que copiamos en 5:
	; 1: -> A'A; byte 1 = A'A AND 0x77 = 0A
	; 2: -> B'B; byte 2 = (B'B AND 0x77) OR (A'A AND 0x88) = A'B
	; 3: -> C'C; byte 3 = (C'C AND 0x77) OR (B'B AND 0x88) = B'C
	; 4: -> D'D; byte 4 = (D'D AND 0x77) OR (C'C AND 0x88) = C'D
	; 5:       ; byte 5 = D'D AND 0x88

	; 1: -> A'A; byte 1 = A'A AND 0x77 = 0A

	ld a, (bc); Get Sprite byte in A

	; Now rotate nibbles right once 76543210 -> 47650321
	; Using LUT!

	ld h, #>M1LUTR1
	ld l, a
	ld a, (hl); A now has been rotated once!

	.db 0xdd
	ld l, a; Save for next byte

	and #0x77; Mask

	ld h, #0xFE; 	; hl -> automask LUT
	ld l, a; copy to L to index LUT
	ld a, (de); Get bg
	and (hl); make a hole
	or l; draw pixels
	ld (de), a; save bg + masked sprite
	inc de
	inc bc

	; 2: -> B'B; byte 2 = (B'B AND 0x77) OR (A'A AND 0x88) = A'B

	.db 0xdd
	ld a, l; A'A
	and #0x88; A'
	.db 0xfd
	ld l, a; IYL = A'0

	ld a, (bc); Get Sprite byte in A

	; Now rotate nibbles right once 76543210 -> 47650321
	; Using LUT!

	ld h, #>M1LUTR1
	ld l, a
	ld a, (hl); A now has been rotated once!

	.db 0xdd
	ld l, a; Save for next byte
	and #0x77; Mask
	.db 0xfd
	or l; Combine

	ld h, #0xFE; 	; hl -> automask LUT
	ld l, a; copy to L to index LUT
	ld a, (de); Get bg
	and (hl); make a hole
	or l; draw pixels
	ld (de), a; save BG
	inc de
	inc bc

	; 3: -> C'C; byte 3 = (C'C AND 0x77) OR (B'B AND 0x88) = B'C

	.db 0xdd
	ld a, l; B'B
	and #0x88; B'
	.db 0xfd
	ld l, a; IYL = B'0

	ld a, (bc); Get Sprite byte in A

	; Now rotate nibbles right once 76543210 -> 47650321
	; Using LUT!

	ld h, #>M1LUTR1
	ld l, a
	ld a, (hl); A now has been rotated once!

	.db 0xdd
	ld l, a; Save for next byte

	and #0x77; Mask
	.db 0xfd
	or l; Combine

	ld h, #0xFE; 	; hl -> automask LUT
	ld l, a; copy to L to index LUT
	ld a, (de); Get bg
	and (hl); make a hole
	or l; draw pixels
	ld (de), a; save BG
	inc de
	inc bc

	; 4: -> D'D; byte 4 = (D'D AND 0x77) OR (C'C AND 0x88) = C'D

	.db 0xdd
	ld a, l; C'C
	and #0x88; C'
	.db 0xfd
	ld l, a; IYL = C'0

	ld a, (bc); Get Sprite byte in A

	; Now rotate nibbles right once 76543210 -> 47650321
	; Using LUT!

	ld h, #>M1LUTR1
	ld l, a
	ld a, (hl); A now has been rotated once!

	.db 0xdd
	ld l, a; Save for next byte

	and #0x77; Mask
	.db 0xfd
	or l; Combine

	ld h, #0xFE; 	; hl -> automask LUT
	ld l, a; copy to L to index LUT
	ld a, (de); Get bg
	and (hl); make a hole
	or l; draw pixels
	ld (de), a; save BG
	inc de
	inc bc

	; 5:       ; byte 5 = D'D AND 0x88

	.db 0xdd
	ld a, l; D'D
	and #0x88; D'

	ld l, a; copy to L to index LUT
	ld a, (de); Get bg
	and (hl); make a hole
	or l; draw pixels
	ld (de), a; save BG	

	.db 0xdd
	dec h
	ret z

	; de += 60 (next line in bg)
	ld hl, #60
	add hl, de
	ex de, hl

	jp loop_alto_map_sbuffer_shift1

loop_alto_map_sbuffer_shift2:
	ld h, #0xFE; 	; hl -> LUT

	; El ancho está desenrollado. Procesamos 4 bytes que copiamos en 5:
	; 1: -> A'A; byte 1 = A'A AND 0x33 = 0A
	; 2: -> B'B; byte 2 = (B'B AND 0x33) OR (A'A AND 0xCC) = A'B
	; 3: -> C'C; byte 3 = (C'C AND 0x33) OR (B'B AND 0xCC) = B'C
	; 4: -> D'D; byte 4 = (D'D AND 0x33) OR (C'C AND 0xCC) = C'D
	; 5:       ; byte 5 = D'D AND 0xCC

	; 1: -> A'A; byte 1 = A'A AND 0x33 = 0A

	ld a, (bc); Get Sprite byte in A

	; Now rotate nibbles right twice 76543210 -> 54761032
	; Using LUT!

	ld h, #>M1LUTR2
	ld l, a
	ld a, (hl); A now has been rotated twice!

	.db 0xdd
	ld l, a; Save for next byte

	and #0x33; Mask

	ld h, #0xFE; 	; hl -> automask LUT
	ld l, a; copy to L to index LUT
	ld a, (de); Get bg
	and (hl); make a hole
	or l; draw pixels
	ld (de), a; save bg + masked sprite
	inc de
	inc bc

	; 2: -> B'B; byte 2 = (B'B AND 0x33) OR (A'A AND 0xCC) = A'B

	.db 0xdd
	ld a, l; A'A
	and #0xCC; A'
	.db 0xfd
	ld l, a; IYL = A'0

	ld a, (bc); Get Sprite byte in A

	; Now rotate nibbles right twice 76543210 -> 54761032
	; Using LUT!

	ld h, #>M1LUTR2
	ld l, a
	ld a, (hl); A now has been rotated twice!

	.db 0xdd
	ld l, a; Save for next byte

	and #0x33; Mask
	.db 0xfd
	or l; Combine

	ld h, #0xFE; 	; hl -> automask LUT
	ld l, a; copy to L to index LUT
	ld a, (de); Get bg
	and (hl); make a hole
	or l; draw pixels
	ld (de), a; save BG
	inc de
	inc bc

	; 3: -> C'C; byte 3 = (C'C AND 0x33) OR (B'B AND 0xCC) = B'C

	.db 0xdd
	ld a, l; B'B
	and #0xCC; B'
	.db 0xfd
	ld l, a; IYL = B'0

	ld a, (bc); Get Sprite byte in A

	; Now rotate nibbles right twice 76543210 -> 54761032
	; Using LUT!

	ld h, #>M1LUTR2
	ld l, a
	ld a, (hl); A now has been rotated twice!

	.db 0xdd
	ld l, a; Save for next byte

	and #0x33; Mask
	.db 0xfd
	or l; Combine

	ld h, #0xFE; 	; hl -> automask LUT
	ld l, a; copy to L to index LUT
	ld a, (de); Get bg
	and (hl); make a hole
	or l; draw pixels
	ld (de), a; save BG
	inc de
	inc bc

	; 4: -> D'D; byte 4 = (D'D AND 0x33) OR (C'C AND 0xCC) = C'D

	.db 0xdd
	ld a, l; C'C
	and #0xCC; C'
	.db 0xfd
	ld l, a; IYL = C'0

	ld a, (bc); Get Sprite byte in A

	; Now rotate nibbles right twice 76543210 -> 54761032
	; Using LUT!

	ld h, #>M1LUTR2
	ld l, a
	ld a, (hl); A now has been rotated twice!

	.db 0xdd
	ld l, a; Save for next byte

	and #0x33; Mask
	.db 0xfd
	or l; Combine

	ld h, #0xFE; 	; hl -> automask LUT
	ld l, a; copy to L to index LUT
	ld a, (de); Get bg
	and (hl); make a hole
	or l; draw pixels
	ld (de), a; save BG
	inc de
	inc bc

	; 5:       ; byte 5 = D'D AND 0xCC

	.db 0xdd
	ld a, l; D'D
	and #0xCC; D'

	ld l, a; copy to L to index LUT
	ld a, (de); Get bg
	and (hl); make a hole
	or l; draw pixels
	ld (de), a; save BG	

	.db 0xdd
	dec h
	ret z

	; de += 60 (next line in bg)
	ld hl, #60
	add hl, de
	ex de, hl

	jp loop_alto_map_sbuffer_shift2


loop_alto_map_sbuffer_shift3:
	ld h, #0xFE; 	; hl -> LUT

	; El ancho está desenrollado. Procesamos 4 bytes que copiamos en 5:
	; 1: -> A'A; byte 1 = A'A AND 0x11 = 0A
	; 2: -> B'B; byte 2 = (B'B AND 0x11) OR (A'A AND 0xEE) = A'B
	; 3: -> C'C; byte 3 = (C'C AND 0x11) OR (B'B AND 0xEE) = B'C
	; 4: -> D'D; byte 4 = (D'D AND 0x11) OR (C'C AND 0xEE) = C'D
	; 5:       ; byte 5 = D'D AND 0xEE

	; 1: -> A'A; byte 1 = A'A AND 0x11 = 0A

	ld a, (bc); Get Sprite byte in A

	; Now rotate nibbles right thrice 76543210 -> 65472103
	; Using LUT!

	ld h, #>M1LUTR3
	ld l, a
	ld a, (hl); A now has been rotated thrice!

	.db 0xdd
	ld l, a; Save for next byte

	and #0x11; Mask

	ld h, #0xFE; 	; hl -> automask LUT
	ld l, a; copy to L to index LUT
	ld a, (de); Get bg
	and (hl); make a hole
	or l; draw pixels
	ld (de), a; save bg + masked sprite
	inc de
	inc bc

	; 2: -> B'B; byte 2 = (B'B AND 0x11) OR (A'A AND 0xEE) = A'B

	.db 0xdd
	ld a, l; A'A
	and #0xEE; A'
	.db 0xfd
	ld l, a; IYL = A'0

	ld a, (bc); Get Sprite byte in A

	; Now rotate nibbles right thrice 76543210 -> 65472103
	; Using LUT!

	ld h, #>M1LUTR3
	ld l, a
	ld a, (hl); A now has been rotated twice!

	.db 0xdd
	ld l, a; Save for next byte

	and #0x11; Mask
	.db 0xfd
	or l; Combine

	ld h, #0xFE; 	; hl -> automask LUT
	ld l, a; copy to L to index LUT
	ld a, (de); Get bg
	and (hl); make a hole
	or l; draw pixels
	ld (de), a; save BG
	inc de
	inc bc

	; 3: -> C'C; byte 3 = (C'C AND 0x33) OR (B'B AND 0xCC) = B'C

	.db 0xdd
	ld a, l; B'B
	and #0xEE; B'
	.db 0xfd
	ld l, a; IYL = B'0

	ld a, (bc); Get Sprite byte in A

	; Now rotate nibbles right thrice 76543210 -> 65472103
	; Using LUT!

	ld h, #>M1LUTR3
	ld l, a
	ld a, (hl); A now has been rotated twice!

	.db 0xdd
	ld l, a; Save for next byte

	and #0x11; Mask
	.db 0xfd
	or l; Combine

	ld h, #0xFE; 	; hl -> automask LUT	
	ld l, a; copy to L to index LUT
	ld a, (de); Get bg
	and (hl); make a hole
	or l; draw pixels
	ld (de), a; save BG
	inc de
	inc bc

	; 4: -> D'D; byte 4 = (D'D AND 0x33) OR (C'C AND 0xCC) = C'D

	.db 0xdd
	ld a, l; C'C
	and #0xEE; C'
	.db 0xfd
	ld l, a; IYL = C'0

	ld a, (bc); Get Sprite byte in A

	; Now rotate nibbles right thrice 76543210 -> 65472103
	; Using LUT!

	ld h, #>M1LUTR3
	ld l, a
	ld a, (hl); A now has been rotated twice!

	.db 0xdd
	ld l, a; Save for next byte

	and #0x11; Mask
	.db 0xfd
	or l; Combine

	ld h, #0xFE; 	; hl -> automask LUT	
	ld l, a; copy to L to index LUT
	ld a, (de); Get bg
	and (hl); make a hole
	or l; draw pixels
	ld (de), a; save BG
	inc de
	inc bc

	; 5:       ; byte 5 = D'D AND 0xCC

	.db 0xdd
	ld a, l; D'D
	and #0xEE; D'

	ld l, a; copy to L to index LUT
	ld a, (de); Get bg
	and (hl); make a hole
	or l; draw pixels
	ld (de), a; save BG	

	.db 0xdd
	dec h
	ret z

	; de += 60 (next line in bg)
	ld hl, #60
	add hl, de
	ex de, hl

	jp loop_alto_map_sbuffer_shift3


; Entrada desde C: guarda IX, que la rutina usa y SDCC necesita
_cpc_PutTrSp16x16TileMapPxM1LUT::
	push ix
	call cpc_PutTrSp16x16TileMapPxM1LUT
	pop ix
	ret
