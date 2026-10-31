// La Churrera Engine 3.100
// Copyleft 2010-2014, 2020 by the Mojon Twins

// Canciones del WYZ player (comprimidas). El número que se pasa a
// wyz_play_music es la posición en wyz_songs: 0 = título, 1 = juego,
// 2 = game over (pantallas.h).

extern const unsigned char song_00_title [];
extern const unsigned char song_01_ingame [];
extern const unsigned char song_02_gover [];
void songs_data (void) __naked {
	__asm
		_song_00_title:
		.incbin "../ogt/00_title.mus.bin"
		_song_01_ingame:
		.incbin "../ogt/01_ingame.mus.bin"
		_song_02_gover:
		.incbin "../ogt/02_gover.mus.bin"
	__endasm;
}

const unsigned char * const wyz_songs [] = {
	song_00_title, song_01_ingame, song_02_gover
};
