
	.include "SPconfig.inc"

	.module SPCClipStruct
	.globl SPCClipStruct

SPCClipStruct:
	.db 0, 0, SP_ROWEND-SP_ROWSTART
	.if DISP_HIRES
	.db 64
	.else
	.db 32
	.endif
