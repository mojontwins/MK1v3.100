// La Churrera Engine 3.100
// Copyleft 2010-2014, 2020 by the Mojon Twins

// Sprites.h: los 16 frames de 16x16 (mkts_om, 64 bytes cada uno)
extern const unsigned char sprites [];
void sprites_data (void) __naked {
	__asm
		_sprites:
		.incbin "sprites.bin"
	__endasm;
}
