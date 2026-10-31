; Código o datos extra para el WYZ player de ZX 128K (en RAM1). Este está
; vacío; un juego puede poner su extra.asm en su carpeta de música.
;
; Si define la etiqueta PLAY_SAMPLE, comp-zx la pasa al motor y el juego
; puede llamar a wyz_play_sample (n): PLAY_SAMPLE recibe n en A y se llama
; con las interrupciones deshabilitadas (para un sample por el beeper, como
; el "¡ay!" de Ninjajar).
