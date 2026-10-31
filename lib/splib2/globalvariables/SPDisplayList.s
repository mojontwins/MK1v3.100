
	.include "SPconfig.inc"

	.module SPDisplayList
	; Variables: van en _DATA (no ocupan sitio en el binario; crt0 las pone a 0)
	.area _DATA
	.globl SPDisplayList

SPDisplayList:
	.if DISP_HIRES
	.ds 4*64*(SP_ROWEND-SP_ROWSTART)
	.else
	.ds 4*32*(SP_ROWEND-SP_ROWSTART)
	.endif
