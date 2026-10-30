; Canciones de Goku Mal para el WYZ proPLAYER de ZX 128K.
; El orden es el número que se pasa a wyz_play_music:
;   0 título, 1 intro (cinemáticas), 2 presentación de zona, 3 fase 1,
;   4 fase 2, 5 fase 3, 6 zona superada, 7 fase 5, 8 game over, 9 final.

SONG_0:         INCBIN "00_title.mus"
SONG_1:         INCBIN "01_intro.mus"
SONG_2:         INCBIN "02_zone123.mus"
SONG_3:         INCBIN "03_fase1.mus"
SONG_4:         INCBIN "04_fase2.mus"
SONG_5:         INCBIN "05_fase3.mus"
SONG_6:         INCBIN "06_zone5.mus"
SONG_7:         INCBIN "07_fase5.mus"
SONG_8:         INCBIN "08_game_over.mus"
SONG_9:         INCBIN "09_ending.mus"

TABLA_SONG:     DW      SONG_0, SONG_1, SONG_2, SONG_3, SONG_4, SONG_5, SONG_6, SONG_7, SONG_8, SONG_9
