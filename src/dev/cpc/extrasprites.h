// La Churrera Engine 3.100
// Copyleft 2010, 2011 by The Mojon Twins

// Extrasprites.h
// Sprites extra: la explosión (17), el sprite vacío (18) y la bala (19).

extern const unsigned char sprite_17_a [];
extern const unsigned char sprite_18_a [];
#ifdef PLAYER_CAN_FIRE
	extern const unsigned char sprite_19_a [];
#endif

void extrasprites_data (void) __naked {
	__asm
		_sprite_17_a:
		.incbin "sprites_extra.bin"
		_sprite_18_a:
		.ds 96
	#ifdef PLAYER_CAN_FIRE
		_sprite_19_a:
		.incbin "sprites_bullet.bin"
	#endif
	__endasm;
}

#define SPRFR_EXPL  sprite_17_a
#define SPRFR_EMPTY sprite_18_a
