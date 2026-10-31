; sp_CompDListAddr (envoltorio __smallc para SDCC)
; void * sp_CompDListAddr (uchar row, uchar col)

	.module sp_CompDListAddr
	.globl _sp_CompDListAddr
	.globl __sp_ixsave

	.area _CODE

_sp_CompDListAddr::
	ld (__sp_ixsave), ix

	.globl SPCompDListAddr

	ld hl, #2
	add hl, sp
	ld c, (hl)
	inc hl
	inc hl
	ld a, (hl)
	call SPCompDListAddr

__sp_CompDListAddr_ret:
	ld ix, (__sp_ixsave)
	ret
