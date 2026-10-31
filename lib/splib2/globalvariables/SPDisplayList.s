
	.include "SPconfig.inc"

	.module SPDisplayList
	; Variables: van en _BSS, al final (no ocupan sitio en el binario; crt0 las pone a 0)
	.area _BSS
	.globl SPDisplayList

SPDisplayList:
	.if DISP_HIRES
	.ds 4*64*(SP_ROWEND-SP_ROWSTART)
	.else
	.ds 4*32*(SP_ROWEND-SP_ROWSTART)
	.endif
