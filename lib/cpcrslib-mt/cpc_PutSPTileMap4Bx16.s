; ******************************************************
; **       Librería de rutinas para Amstrad CPC       **
; **       Raúl Simarro,      Artaburu 2007           **
; ******************************************************

; [na_th_an] Nueva versión reescrita por Mojon Twins
; - eliminamos la "cabecera" de los sprites.
; - la función marca por separado los tiles "anteriores" (ox,oy)
;   y los tiles "actuales" (cx, cy).
; - Intenta "podar" los casos en los que los rectángulos
;   sean iguales.
; - Intenta "afinar" y marcar solo 2 de long. en vez de 3
;   cuando sea posible.
; - Prescinde de bucles y otros cálculos al ser un caso muy concreto

	.module cpc_PutSPTileMap4Bx16
	.globl cpc_PutSPTileMap4Bx16
	.area _CODE

	.globl posiciones_super_buffer
	.globl tiles

	.globl cpc_UpdTileTableClp

cpc_PutSPTileMap4Bx16:
	ex de, hl
	.db 0xdd
	ld h, d
	.db 0xdd
	ld l, e

    ; Tendré que marcar 4, 6 o 9 cuadros dependiendo de las alineaciones.

	ld e, 10(ix); ox
	ld d, 11(ix); oy

    ; Marcar OX, OY

	call do_update

	ld e, 8(ix); cx
	ld d, 9(ix); cy

    ; Copiamos (cx,cy) -> (ox,oy)

	ld 10(ix), e
	ld 11(ix), d

    ; Marcar CX, CY

do_update:
    ; X está en bytes. Estará alineado a rejilla si es par.
	ld a, e
	and #1
	.db 0xfd
	ld l, a

    ; Y está en pixeles. Estará alineado si AND 7 == 0
	ld a, d
	and #7
	.db 0xfd
	ld h, a

    ; Convertir a coordenadas de rejilla
	srl e; E = X / 2
	srl d
	srl d
	srl d; D = Y / 8

	push de; Lo guardamos

    ; Marco el tile origen
	call cpc_UpdTileTableClp; Marca el tile en DE

    ; Y el de su derecha
	inc e
	call cpc_UpdTileTableClp; Marca el tile en DE

    ; Marcar el siguiente?
	.db 0xfd
	ld a, l
	or a
	jr z, origin_next_row

	inc e
	call cpc_UpdTileTableClp; Marca el tile en DE

origin_next_row:
	pop de; Recuperamos   
	inc d; Y = Y + 1
	push de; Guardamos

    ; Marco el primer tile
	call cpc_UpdTileTableClp; Marca el tile en DE

    ; Y el de su derecha
	inc e
	call cpc_UpdTileTableClp; Marca el tile en DE

    ; Marcar el siguiente?
	.db 0xfd
	ld a, l
	or a
	jr z, origin_last_row

	inc e
	call cpc_UpdTileTableClp; Marca el tile en DE

origin_last_row:
	pop de; Recuperamos   

    ; Marcar esta fila?
	.db 0xfd
	ld a, h
	or a
	jr z, fin

	inc d; Y = Y + 1

    ; Marco el primer tile
	call cpc_UpdTileTableClp; Marca el tile en DE

    ; Y el de su derecha
	inc e
	call cpc_UpdTileTableClp; Marca el tile en DE

    ; Marcar el siguiente?
	.db 0xfd
	ld a, l
	or a
	jr z, fin

	inc e
	call cpc_UpdTileTableClp; Marca el tile en DE

fin:
	ret


; Entrada desde C: guarda IX, que la rutina usa y SDCC necesita
_cpc_PutSPTileMap4Bx16::
	push ix
	call cpc_PutSPTileMap4Bx16
	pop ix
	ret
