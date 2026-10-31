; sp_MouseAMXInit (envoltorio __smallc para SDCC)
; void sp_MouseAMXInit (uchar xvector, uchar yvector)

	.module sp_MouseAMXInit
	.globl _sp_MouseAMXInit
	.globl __sp_ixsave

	.area _CODE

_sp_MouseAMXInit::
	ld (__sp_ixsave), ix

	.globl SPMouseAMXInit

	ld hl, #2
	add hl, sp
	ld c, (hl)
	inc hl
	inc hl
	ld b, (hl)
	call SPMouseAMXInit

__sp_MouseAMXInit_ret:
	ld ix, (__sp_ixsave)
	ret
