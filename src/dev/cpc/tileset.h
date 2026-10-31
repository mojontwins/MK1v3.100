// La Churrera Engine 3.100
// Copyleft 2010-2013, 2020-2025 by The Mojon Twins

// Tileset de CPC (mkts_om): la fuente (64 patrones) y los tiles (192
// patrones), seguidos. cpcrslib lo usa con el nombre "tiles".
extern const unsigned char tileset [];
extern const unsigned char tspatterns [];
void tileset_data (void) __naked {
	__asm
		_tileset::
		tiles::
		.incbin "font.bin"			; 1024 bytes, 64 patrones
		_tspatterns:
		.incbin "work.bin"			; 3072 bytes, 192 patrones
	__endasm;
}
