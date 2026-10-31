
	.include "SPconfig.inc"

	.module SPDirtyChars
	; Variables: van en _DATA (no ocupan sitio en el binario; crt0 las pone a 0)
	.area _DATA
	.globl SPDirtyChars

SPDirtyChars:
	.if DISP_HIRES
	.ds 64/8*(SP_ROWEND-SP_ROWSTART)
	.else
	.if DISP_TMXDUAL
	.ds 32/8*(SP_ROWEND-SP_ROWSTART)*2 + 256
	.else
	.ds 32/8*(SP_ROWEND-SP_ROWSTART)
	.endif
	.endif
