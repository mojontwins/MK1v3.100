; sp_LookupKey (envoltorio __smallc para SDCC)
; uint sp_LookupKey (uchar c)

	.module sp_LookupKey
	.globl _sp_LookupKey
	.globl __sp_ixsave

	.area _CODE

_sp_LookupKey::
	ld (__sp_ixsave), ix

	.globl SPLookupKey

	ld hl, #2
	add hl, sp
	ld a, (hl)
	call SPLookupKey
	jr nc, sp_LookupKey_notfound
	ld l, c
	ld h, b
	or a
	jp __sp_LookupKey_ret

sp_LookupKey_notfound:
	scf

__sp_LookupKey_ret:
	ld ix, (__sp_ixsave)
	ret
