; Copia de IX para los envoltorios: SDCC usa IX como puntero de marco y una
; función tiene que devolverlo intacto; las rutinas de splib2 lo usan.
	.module sp_ixsave
	.globl __sp_ixsave
	.area _DATA
__sp_ixsave::
	.ds 2
