// La Churrera Engine 3.100
// Copyleft 2010-2014 the Mojon Twins

// Extrasprites.h
// Contiene sprites extra para el modo de matar enemigos de la churrera
// Sólo se incluirá (tras los sprites) si se define PLAYER_KILLS_ENEMIES
// Copyleft 2010 The Mojon Twins

// Sprites extra: la explosión (17), el sprite vacío (18) y la bala (19), en
// un solo array. Cada sprite tiene sus columnas (a, b, c) una tras otra y del
// mismo tamaño, como los de sprites.h, para que la animación funcione.

const unsigned char extrasprites [] = {
#ifdef NEEDS_EXPLOSION_SPRITE
	// sprite_17_a
	0, 128, 56, 0, 117, 0, 123, 0, 127, 0, 57, 0, 0, 0, 96, 0,
	238, 0, 95, 0, 31, 0, 62, 0, 53, 128, 42, 128, 20, 128, 0, 192,
	0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255,
	// sprite_17_b
	0, 3, 240, 1, 248, 0, 236, 0, 212, 0, 248, 0, 224, 1, 24, 0,
	124, 0, 120, 0, 244, 0, 168, 0, 0, 1, 0, 3, 0, 63, 0, 127,
	0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255,
	// sprite_17_c
	0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255,
	0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255,
	0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255,
#endif
	// sprite_18_a
	0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255,
	0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255,
	0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255,
	// sprite_18_b
	0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255,
	0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255,
	0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255,
	// sprite_18_c
	0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255,
	0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255,
	0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255,
#ifdef NEEDS_BULLET_SPRITE
	// sprite_19_a
	0, 255, 0, 195, 24, 129, 60, 0, 60, 0, 24, 129, 0, 195, 0, 255,
	0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255,
	// sprite_19_b
	0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255,
	0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255,
#endif
};

#ifdef NEEDS_EXPLOSION_SPRITE
	#define sprite_17_a     (extrasprites)
	#define sprite_17_b     (extrasprites + 48)
	#define sprite_17_c     (extrasprites + 96)
	#define EXTRA_17_END	(144)
#else
	#define EXTRA_17_END	0
#endif
#define sprite_18_a     (extrasprites + EXTRA_17_END + 0)
#define sprite_18_b     (extrasprites + EXTRA_17_END + 48)
#define sprite_18_c     (extrasprites + EXTRA_17_END + 96)
#define EXTRA_18_END	(EXTRA_17_END + 144)
#ifdef NEEDS_BULLET_SPRITE
	#define sprite_19_a     (extrasprites + EXTRA_18_END + 0)
	#define sprite_19_b     (extrasprites + EXTRA_18_END + 32)
	#define EXTRA_19_END	(EXTRA_18_END + 64)
#else
	#define EXTRA_19_END	EXTRA_18_END
#endif
