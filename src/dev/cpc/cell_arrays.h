// La Churrera Engine 3.100
// Copyleft 2010-2014 the Mojon Twins

// Sprite cell arrays for the player

#ifdef PLAYER_MOGGY_STYLE
	// right: 0 + frame
	// left: 2 + frame
	// up: 4 + frame
	// down: 6 + frame
	const unsigned char * const player_frames [] = {
		SPRITE_00, SPRITE_01, SPRITE_02, SPRITE_03,
		SPRITE_04, SPRITE_05, SPRITE_06, SPRITE_07
	};

#elif defined PLAYER_BOOTEE
	// vy = 0: 0 + facing
	// vy < 0: 1 + facing
	// vy > 0: 2 + facing
	const unsigned char * const player_frames [] = {
		SPRITE_00, SPRITE_01, SPRITE_02, SPRITE_03,
		SPRITE_04, SPRITE_05, SPRITE_06, SPRITE_07
	};

#elif defined PLAYER_ALTERNATE_ANIMATION
	// Alternate animation:
	// 0 1 2 + facing = walk, 0 = stand, 3 = jump/fall
	const unsigned char * const player_frames [] = {
		SPRITE_00, SPRITE_01, SPRITE_02, SPRITE_03,
		SPRITE_04, SPRITE_05, SPRITE_06, SPRITE_07
	};

#else
	// Side view, normal
	// 0 1 2 3 + facing: walk, 1 = stand. 8 + facing = jump/fall
	const unsigned char * const player_frames [] = {
		SPRITE_00, SPRITE_01, SPRITE_02, SPRITE_01,
		SPRITE_04, SPRITE_05, SPRITE_06, SPRITE_05,
		SPRITE_03, SPRITE_07
	};
#endif

// Sprite cell arrays for the malotes

const unsigned char * const enem_frames [] = {
	SPRITE_08, SPRITE_09, SPRITE_0A, SPRITE_0B,
	SPRITE_0C, SPRITE_0D, SPRITE_0E, SPRITE_0F
};
