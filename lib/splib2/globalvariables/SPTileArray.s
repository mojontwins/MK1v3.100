
	.include "SPconfig.inc"

	.module SPTileArray
	; Variables: van en _BSS, al final (no ocupan sitio en el binario; crt0 las pone a 0)
	.area _BSS
	.globl SPTileArray

SPTileArray:
	.ds 512; LSB Tile Graphic, MSB Tile Graphic
	.if DISP_HICOLOUR
	.ds 512; LSB Tile Pallette, MSB Tile Pallette
	.endif
