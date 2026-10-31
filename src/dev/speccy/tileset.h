// La Churrera Engine 3.100
// Copyleft 2010-2013, 2020-2025 by The Mojon Twins

extern unsigned char tileset [0];
void tileset_asm1 (void) __naked {
	__asm
		_tileset:
		.incbin "ts.bin"
	__endasm;
}
