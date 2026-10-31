; La Churrera Engine 3.100
; crt0.s: arranque del programa en ZX Spectrum 128K (SDCC).
;
; El programa se carga en 24200 y empieza aquí: pone la pila, borra las
; variables (_DATA, las del motor, y _BSS, las de splib2) y salta a main.
; No hay variables con valor inicial (el motor usa tablas const y comp-zx
; da error si aparece alguna). __stack_top lo define churromain.c a partir
; de STACK_ADDR.

	.module crt0
	.globl _main
	.globl __stack_top

	.area _CODE
init:
	di
	ld sp, #__stack_top
	ld hl, #s__DATA
	ld bc, #l__DATA
	call clear
	ld hl, #s__BSS
	ld bc, #l__BSS
	call clear
	jp _main

; Pone a cero BC bytes desde HL
clear:
	ld a, b
	or c
	ret z
	ld (hl), #0
	dec bc
	ld a, b
	or c
	ret z
	ld d, h
	ld e, l
	inc de
	ldir
	ret

	; Orden de las áreas: el código de crt0 y de las librerías (_CODE), las
	; variables del motor y luego el código del motor (_MAIN: comp-zx compila
	; churromain.c con --codeseg MAIN). Así las variables quedan por debajo de
	; 0xC000 (ahí se descomprimen los niveles con otra página de RAM puesta)
	; aunque el código pase de esa dirección. Ocupan su sitio en la cinta.
	; Las variables de splib2 (_BSS) van al final.
	.area _DATA
	.area _INITIALIZED
	.area _BSEG
	.area _MAIN
	.area _INITIALIZER
	.area _GSINIT
	.area _GSFINAL
	.area _BSS
	.area _HEAP
