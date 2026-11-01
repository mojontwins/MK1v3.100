; La Churrera Engine 3.100 - Game Boy
; Copyleft 2026 the Mojon Twins
;
; gb/vram.s
; Escribir en la VRAM con la pantalla encendida: antes de cada escritura se
; espera a que la pantalla esté en el modo 0 (hblank) o 1 (vblank). Después
; quedan al menos 20 ciclos (el modo 2) en los que se puede escribir, así que
; caben dos escrituras seguidas.
;
; Convención de SDCC (sdcccall 1): puntero en DE, byte en A.

	.module vram
	.area _HOME

STAT = 0x41

; void gb_vram_put (uint8_t *addr, uint8_t v)
_gb_vram_put::
	ld	b, a
1$:
	ldh	a, (STAT)
	and	#0x02
	jr	nz, 1$
	ld	a, b
	ld	(de), a
	ret

; void gb_vram_tile2x2 (uint8_t *addr, uint8_t t)
; Un tile de 16x16: t y t + 1 en addr, t + 2 y t + 3 en la fila de abajo.
_gb_vram_tile2x2::
	ld	b, a
	ld	h, d
	ld	l, e
1$:
	ldh	a, (STAT)
	and	#0x02
	jr	nz, 1$
	ld	a, b
	ld	(hl+), a
	inc	a
	ld	(hl), a
	inc	a
	ld	b, a
	ld	de, #31
	add	hl, de
2$:
	ldh	a, (STAT)
	and	#0x02
	jr	nz, 2$
	ld	a, b
	ld	(hl+), a
	inc	a
	ld	(hl), a
	ret
