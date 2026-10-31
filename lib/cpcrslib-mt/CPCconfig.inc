; Configuración de cpcrslib-mt. make.sh / make.bat la generan con
; PASARPORDETRAS = 0 (variante normal) o 1 (variante fg).

; PASARPORDETRAS = 1: los sprites pasan por detrás de los tiles marcados en
; behindtilemasks (256 bytes, uno por tile, que pone el juego).
	PASARPORDETRAS = 0

; El área de juego (viewport_x, viewport_y, que exporta el motor) es el
; rectángulo de clipping.
	CHURRERA_CLIPPING = 1

; Tablas de rotación de modo 1
	M1LUTR1 = 0xD700
	M1LUTR2 = 0xDE00
	M1LUTR3 = 0xE700

; El tilemap: pantalla de 32x24 tiles (modo retocado del CRTC). La pantalla
; está en 0xC000, el superbuffer en 0x9000, el nametable (un byte por tile)
; en 0x100 y el bitfield de tiles tocados en 0xCE00.
	pantalla_juego = 0x100
	tiles_tocados = 0xCE00
	posicion_inicial_area_visible = 0xC000
	posicion_inicial_superbuffer = 0x9000
	T_WIDTH = 32
	T_HEIGHT = 24
	ancho_pantalla_bytes = 2 * T_WIDTH
	alto_pantalla_bytes = 8 * T_HEIGHT
	ancho_pantalla_bytes_visible = 2 * T_WIDTH
	mascara1 = 0
	mascara2 = 0
