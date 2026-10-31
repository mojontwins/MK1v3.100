; sp_AddMemory (envoltorio __smallc para SDCC)
; void * sp_AddMemory (uchar queue, uchar number, uint size, void *addr)

	.module sp_AddMemory
	.globl _sp_AddMemory
	.globl __sp_ixsave

	.area _CODE

_sp_AddMemory::
	ld (__sp_ixsave), ix

	.globl SPAddMemory

	ld hl, #8
	add hl, sp
	ld a, (hl)
	dec hl
	dec hl
	ld b, (hl)
	dec hl
	ld d, (hl)
	dec hl
	ld e, (hl)
	dec hl
	ex af, af
	ld a, (hl)
	dec hl
	ld l, (hl)
	ld h, a
	ex af, af
	call SPAddMemory

__sp_AddMemory_ret:
	ld ix, (__sp_ixsave)
	ret
