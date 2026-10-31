; La Churrera Engine 3.100
; crt0.s: arranque del programa en ZX Spectrum (SDCC).
;
; El programa se carga en 24200 y empieza aquí: pone la pila, borra las
; variables sin inicializar (_DATA), copia las inicializadas (si las hay;
; el motor deja sus tablas como const para que no haga falta) y salta a main.
; __stack_top lo define churromain.c a partir de STACK_ADDR.

	.module crt0
	.globl _main
	.globl __stack_top

	.area _CODE
init:
	di
	ld sp, #__stack_top
	ld hl, #s__DATA
	ld bc, #l__DATA
	ld a, b
	or c
	jr z, init_data_done
	ld (hl), #0
	dec bc
	ld a, b
	or c
	jr z, init_data_done
	ld d, h
	ld e, l
	inc de
	ldir
init_data_done:
	ld bc, #l__INITIALIZER
	ld a, b
	or c
	jr z, init_copy_done
	ld de, #s__INITIALIZED
	ld hl, #s__INITIALIZER
	ldir
init_copy_done:
	jp _main

	; Orden de las áreas: código y datos constantes (en el binario), luego
	; las variables (después del binario, no ocupan cinta).
	.area _INITIALIZER
	.area _GSINIT
	.area _GSFINAL
	.area _DATA
	.area _INITIALIZED
	.area _BSEG
	.area _BSS
	.area _HEAP
