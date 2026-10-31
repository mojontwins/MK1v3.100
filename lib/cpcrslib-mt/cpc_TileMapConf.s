; Tablas del tilemap (antes en el tilemap_conf.asm del juego): dirección
; de cada fila de tiles en la pantalla y en el superbuffer. Las constantes
; están en CPCconfig.inc.

	.module cpc_TileMapConf
	.include "CPCconfig.inc"
	.globl posiciones_pantalla
	.globl posiciones_super_buffer
	.area _CODE

; Dónde empieza cada fila de tiles en la pantalla
posiciones_pantalla:
	.dw posicion_inicial_area_visible + 0x40 * 0
	.dw posicion_inicial_area_visible + 0x40 * 1
	.dw posicion_inicial_area_visible + 0x40 * 2
	.dw posicion_inicial_area_visible + 0x40 * 3
	.dw posicion_inicial_area_visible + 0x40 * 4
	.dw posicion_inicial_area_visible + 0x40 * 5
	.dw posicion_inicial_area_visible + 0x40 * 6
	.dw posicion_inicial_area_visible + 0x40 * 7
	.dw posicion_inicial_area_visible + 0x40 * 8
	.dw posicion_inicial_area_visible + 0x40 * 9
	.dw posicion_inicial_area_visible + 0x40 * 10
	.dw posicion_inicial_area_visible + 0x40 * 11
	.dw posicion_inicial_area_visible + 0x40 * 12
	.dw posicion_inicial_area_visible + 0x40 * 13
	.dw posicion_inicial_area_visible + 0x40 * 14
	.dw posicion_inicial_area_visible + 0x40 * 15
	.dw posicion_inicial_area_visible + 0x40 * 16
	.dw posicion_inicial_area_visible + 0x40 * 17
	.dw posicion_inicial_area_visible + 0x40 * 18
	.dw posicion_inicial_area_visible + 0x40 * 19
	.dw posicion_inicial_area_visible + 0x40 * 20
	.dw posicion_inicial_area_visible + 0x40 * 21
	.dw posicion_inicial_area_visible + 0x40 * 22
	.dw posicion_inicial_area_visible + 0x40 * 23

; Dónde empieza cada fila de tiles en el superbuffer
posiciones_super_buffer:
	.dw posicion_inicial_superbuffer + 8 * ancho_pantalla_bytes * 0
	.dw posicion_inicial_superbuffer + 8 * ancho_pantalla_bytes * 1
	.dw posicion_inicial_superbuffer + 8 * ancho_pantalla_bytes * 2
	.dw posicion_inicial_superbuffer + 8 * ancho_pantalla_bytes * 3
	.dw posicion_inicial_superbuffer + 8 * ancho_pantalla_bytes * 4
	.dw posicion_inicial_superbuffer + 8 * ancho_pantalla_bytes * 5
	.dw posicion_inicial_superbuffer + 8 * ancho_pantalla_bytes * 6
	.dw posicion_inicial_superbuffer + 8 * ancho_pantalla_bytes * 7
	.dw posicion_inicial_superbuffer + 8 * ancho_pantalla_bytes * 8
	.dw posicion_inicial_superbuffer + 8 * ancho_pantalla_bytes * 9
	.dw posicion_inicial_superbuffer + 8 * ancho_pantalla_bytes * 10
	.dw posicion_inicial_superbuffer + 8 * ancho_pantalla_bytes * 11
	.dw posicion_inicial_superbuffer + 8 * ancho_pantalla_bytes * 12
	.dw posicion_inicial_superbuffer + 8 * ancho_pantalla_bytes * 13
	.dw posicion_inicial_superbuffer + 8 * ancho_pantalla_bytes * 14
	.dw posicion_inicial_superbuffer + 8 * ancho_pantalla_bytes * 15
	.dw posicion_inicial_superbuffer + 8 * ancho_pantalla_bytes * 16
	.dw posicion_inicial_superbuffer + 8 * ancho_pantalla_bytes * 17
	.dw posicion_inicial_superbuffer + 8 * ancho_pantalla_bytes * 18
	.dw posicion_inicial_superbuffer + 8 * ancho_pantalla_bytes * 19
	.dw posicion_inicial_superbuffer + 8 * ancho_pantalla_bytes * 20
	.dw posicion_inicial_superbuffer + 8 * ancho_pantalla_bytes * 21
	.dw posicion_inicial_superbuffer + 8 * ancho_pantalla_bytes * 22
	.dw posicion_inicial_superbuffer + 8 * ancho_pantalla_bytes * 23
