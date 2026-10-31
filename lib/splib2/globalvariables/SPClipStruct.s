
	.include "SPconfig.inc"
	.module SPClipStruct
	.globl SPClipStruct

SPClipStruct:
	.db 0,SP_ROWEND-SP_ROWSTART
	.if DISP_HIRES
	.db 0,64
	.else
	.db 0,32
	.endif
