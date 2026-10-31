; La Churrera Engine 3.100
; crt0.s: arranque del programa en ZX Spectrum 48K (SDCC).
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
