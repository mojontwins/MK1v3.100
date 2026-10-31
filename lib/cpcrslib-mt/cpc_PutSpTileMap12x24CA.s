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
; - Intenta "afinar" y marcar solo 2/3 de long. en vez de 3/4
;   cuando sea posible.
; - Prescinde de bucles y otros cálculos al ser un caso muy concreto

; Esta versión de la rutina asume coordenadas "de celda"
; x = 0-31; y = 0-23.

; El sprite es de 3x3 celdas, o 12x24 ladrillos.

	.module cpc_PutSpTileMap12x24CA
	.globl cpc_PutSpTileMap12x24CA
	.area _CODE

	.globl posiciones_super_buffer
	.globl tiles

	.globl cpc_UpdTileTableClp

cpc_PutSpTileMap12x24CA:
	ex de, hl
	.db 0xdd
	ld h, d
	.db 0xdd
	ld l, e

    ; El sprite siempre está alineado, así que se marcará 9 celdas

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
    ; X e Y está ya en coordeadas de "rejilla

	push de; Guardamos coordenadas

    ; Marco el tile origen
	call cpc_UpdTileTableClp; Marca el tile en DE

    ; Y el de su derecha
	inc e
	call cpc_UpdTileTableClp; Marca el tile en DE

    ; Y el siguiente
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
    ; Y el siguiente

	inc e
	call cpc_UpdTileTableClp; Marca el tile en DE

origin_next_row2:
	pop de; Recuperamos   
	inc d; Y = Y + 1

    ; Marco el primer tile
	call cpc_UpdTileTableClp; Marca el tile en DE

    ; Y el de su derecha
	inc e
	call cpc_UpdTileTableClp; Marca el tile en DE

    ; Y el siguiente
	inc e
	call cpc_UpdTileTableClp; Marca el tile en DE    

fin:
	ret


; Entrada desde C: guarda IX, que la rutina usa y SDCC necesita
_cpc_PutSpTileMap12x24CA::
	push ix
	call cpc_PutSpTileMap12x24CA
	pop ix
	ret
