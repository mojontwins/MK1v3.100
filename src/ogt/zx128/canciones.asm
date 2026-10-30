; Canciones para el WYZ proPLAYER de ZX 128K (speccy_128/wyz/wyzplayer.asm)
;
; OJO: bootee es un juego de 48K/CPC y sus .mus (../bootee_*.mus) están en el
; formato del WYZ player nuevo del CPC, que el proPLAYER 0.2 de ZX no entiende
; (se queda colgado en la interrupción). Estas tres canciones son de Goku Mal
; y están aquí solo para poder compilar y probar bootee en modo MODE_128K.
;
; El orden es el número que se pasa a wyz_play_music:
;   0 = título, 1 = juego, 2 = game over

SONG_0:         INCBIN "title.mus"
SONG_1:         INCBIN "ingame.mus"
SONG_2:         INCBIN "gameover.mus"

TABLA_SONG:     DW      SONG_0, SONG_1, SONG_2
