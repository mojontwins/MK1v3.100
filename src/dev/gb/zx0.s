; zx0 para el Game Boy (SM83)
; Copyleft 2026 The Mojon Twins
;
; El descompresor "standard" de ZX0 de Einar Saukas, pasado del Z80 al SM83:
; sin ldir ni ex (sp), hl, el último desplazamiento va en una variable y las
; copias guardan A (el acumulador de bits) en la pila.
;
; void zx0_unpack (const unsigned char *src, unsigned char *dst);
;   src en DE, dst en BC (convención de SDCC). Puede escribir en la VRAM si
;   la pantalla está apagada (ZX0 vuelve a leer lo ya escrito).

	.module zx0
	.globl _zx0_unpack

	.area _DATA
zx0_ofs:	.ds 2

	.area _HOME

_zx0_unpack::
	ld	h, d					; HL = origen
	ld	l, e
	ld	d, b					; DE = destino
	ld	e, c
	ld	a, #0xff				; Último desplazamiento: -1
	ld	(zx0_ofs), a
	ld	(zx0_ofs + 1), a
	ld	bc, #0
	ld	a, #0x80
zx0_literals:
	call	zx0_elias				; Longitud
	push	af
	call	zx0_copy				; Literales: de HL a DE
	pop	af
	add	a, a					; ¿Último desplazamiento o uno nuevo?
	jr	c, zx0_new_offset
	call	zx0_elias				; Longitud
zx0_copy_offset:
	push	af
	push	hl
	ld	a, (zx0_ofs)			; HL = DE + desplazamiento (negativo)
	ld	l, a
	ld	a, (zx0_ofs + 1)
	ld	h, a
	add	hl, de
	call	zx0_copy
	pop	hl
	pop	af
	add	a, a					; ¿Literales o desplazamiento nuevo?
	jr	nc, zx0_literals
zx0_new_offset:
	ld	c, #0xfe				; Desplazamiento negativo
	call	zx0_elias_loop			; Byte alto
	inc	c
	ret	z						; Fin
	ld	b, c
	ld	c, (hl)					; Byte bajo
	inc	hl
	rr	b						; El último bit es el primero de la longitud
	rr	c
	push	af
	ld	a, c
	ld	(zx0_ofs), a
	ld	a, b
	ld	(zx0_ofs + 1), a
	pop	af						; (con el acarreo de rr c)
	ld	bc, #1
	call	nc, zx0_elias_backtrack
	inc	bc
	jr	zx0_copy_offset

zx0_elias:
	inc	c						; Elias gamma entrelazado
zx0_elias_loop:
	add	a, a
	jr	nz, zx0_elias_skip
	ld	a, (hl+)				; Otros 8 bits
	rla
zx0_elias_skip:
	ret	c
zx0_elias_backtrack:
	add	a, a
	rl	c
	rl	b
	jr	zx0_elias_loop

; Copia BC bytes (BC > 0) de HL a DE. Estropea A.
zx0_copy:
	ld	a, (hl+)
	ld	(de), a
	inc	de
	dec	bc
	ld	a, b
	or	a, c
	jr	nz, zx0_copy
	ret
