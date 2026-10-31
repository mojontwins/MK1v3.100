// La Churrera Engine 3.100
// Copyleft 2010-2014 the Mojon Twins

// Extrasprites.h
// Contiene sprites extra para el modo de matar enemigos de la churrera
// Sólo se incluirá (tras los sprites) si se define PLAYER_KILLS_ENEMIES
// Copyleft 2010 The Mojon Twins

// Frames extra por si se pueden eliminar los enemigos:

#ifdef NEEDS_EXPLOSION_SPRITE
    extern const unsigned char sprite_17_a []; 
#endif

extern const unsigned char sprite_18_a []; 

#ifdef NEEDS_BULLET_SPRITE
    extern const unsigned char sprite_19_a [];
    extern const unsigned char sprite_19_b [];
#endif

#ifdef NEEDS_EXPLOSION_SPRITE
    void sprite_17_data (void) __naked {
    	__asm
	    	_sprite_17_a:
	    	.db 0, 128
	    	.db 56, 0
	    	.db 117, 0
	    	.db 123, 0
	    	.db 127, 0
	    	.db 57, 0
	    	.db 0, 0
	    	.db 96, 0
	    	.db 238, 0
	    	.db 95, 0
	    	.db 31, 0
	    	.db 62, 0
	    	.db 53, 128
	    	.db 42, 128
	    	.db 20, 128
	    	.db 0, 192
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255

	    	_sprite_17_b:
	    	.db 0, 3
	    	.db 240, 1
	    	.db 248, 0
	    	.db 236, 0
	    	.db 212, 0
	    	.db 248, 0
	    	.db 224, 1
	    	.db 24, 0
	    	.db 124, 0
	    	.db 120, 0
	    	.db 244, 0
	    	.db 168, 0
	    	.db 0, 1
	    	.db 0, 3
	    	.db 0, 63
	    	.db 0, 127
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255

	    	_sprite_17_c:
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
    	__endasm;
    }
#endif

void sprite_18_data (void) __naked {
	__asm
		_sprite_18_a:
		.db 0, 255, 0, 255, 0, 255, 0, 255
		.db 0, 255, 0, 255, 0, 255, 0, 255
		.db 0, 255, 0, 255, 0, 255, 0, 255
		.db 0, 255, 0, 255, 0, 255, 0, 255
		.db 0, 255, 0, 255, 0, 255, 0, 255
		.db 0, 255, 0, 255, 0, 255, 0, 255

		_sprite_18_b:
		.db 0, 255, 0, 255, 0, 255, 0, 255
		.db 0, 255, 0, 255, 0, 255, 0, 255
		.db 0, 255, 0, 255, 0, 255, 0, 255
		.db 0, 255, 0, 255, 0, 255, 0, 255
		.db 0, 255, 0, 255, 0, 255, 0, 255
		.db 0, 255, 0, 255, 0, 255, 0, 255

		_sprite_18_c:
		.db 0, 255, 0, 255, 0, 255, 0, 255
		.db 0, 255, 0, 255, 0, 255, 0, 255
		.db 0, 255, 0, 255, 0, 255, 0, 255
		.db 0, 255, 0, 255, 0, 255, 0, 255
		.db 0, 255, 0, 255, 0, 255, 0, 255
		.db 0, 255, 0, 255, 0, 255, 0, 255
	__endasm;
}

#ifdef NEEDS_BULLET_SPRITE
    void sprite_19_data (void) __naked {
    	__asm
	    	_sprite_19_a:
	    	.db 0, 255
	    	.db 0, 195
	    	.db 24, 129
	    	.db 60, 0
	    	.db 60, 0
	    	.db 24, 129
	    	.db 0, 195
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255

	    	_sprite_19_b:
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
	    	.db 0, 255
    	__endasm;
    }
#endif

// Final de los gráficos de sprites. En 128K comp-zx.sh comprueba que queda
// por debajo de 0xC000 (los niveles pueden cargar sprites encima).
void sprites_end_mark (void) __naked {
	__asm
		_sprites_end:
	__endasm;
}
