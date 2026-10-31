// La Churrera Engine 3.100
// Copyleft 2010, 2011 by The Mojon Twins

// Extrasprites.h
// Sprites extra: la explosión (17), el sprite vacío (18), la bala (19) y el
// puño (20 hacia la derecha, 21 hacia la izquierda; 16 bytes cada uno).

extern const unsigned char sprite_17_a [];
extern const unsigned char sprite_18_a [];
#ifdef NEEDS_BULLET_SPRITE
	extern const unsigned char sprite_19_a [];
#endif
#ifdef NEEDS_PUNCH_SPRITES
	extern const unsigned char sprite_20_a [];
	#define sprite_21_a (sprite_20_a + 16)
#endif

void extrasprites_data (void) __naked {
	__asm
		_sprite_17_a:
		.incbin "sprites_extra.bin"
		_sprite_18_a:
		.ds 96
	#ifdef NEEDS_BULLET_SPRITE
		_sprite_19_a:
		.incbin "sprites_bullet.bin"
	#endif
	#ifdef NEEDS_PUNCH_SPRITES
		_sprite_20_a:
		.incbin "sprites_punch.bin"
	#endif
	__endasm;
}

#define SPRFR_EXPL  sprite_17_a
#define SPRFR_EMPTY sprite_18_a
