; Efectos de sonido por defecto de MK1 v3.100 para el WYZ proPLAYER de ZX 128K.
; Son los 15 efectos estándar de MK1 (los mismos números que PLAY_SFX):
; convertidos desde cpc/efectos.h quitando el tercer byte de cada paso
; (envolvente/ruido), que el reproductor de ZX no usa.
; Un juego puede poner su propio efectos.asm en su carpeta de música.

; [0] Enemy destroyed
EFECTO0:
		DB	$E8, $1B
		DB	$5F, $0F
		DB	$E2, $0F
		DB	$56, $0F
		DB	$F6, $0F
		DB	$14, $0E
		DB	$64, $0E
		DB	$62, $0D
		DB	$D0, $0D
		DB	$F1, $0C
		DB	$FF
; [1] Enemy hit
EFECTO1:
		DB	$E8, $1B
		DB	$5F, $0F
		DB	$A6, $0F
		DB	$00, $00
		DB	$80, $0F
		DB	$FF
; [2] Something
EFECTO2:
		DB	$C3, $0E
		DB	$5F, $0F
		DB	$A6, $0F
		DB	$E8, $1B
		DB	$80, $2B
		DB	$FF
; [3] Jump
EFECTO3:
		DB	$E8, $1B
		DB	$B4, $0F
		DB	$A0, $0E
		DB	$90, $0D
		DB	$87, $0D
		DB	$78, $0C
		DB	$6C, $0B
		DB	$60, $0A
		DB	$5A, $09
		DB	$FF
; [4] Player hit
EFECTO4:
		DB	$C3, $0E
		DB	$5F, $1F
		DB	$A6, $2F
		DB	$E8, $1B
		DB	$80, $2B
		DB	$FF
; [5] Enemy destroyed 2
EFECTO5:
		DB	$E8, $1B
		DB	$5F, $1F
		DB	$E2, $0F
		DB	$56, $3F
		DB	$F6, $1F
		DB	$14, $1E
		DB	$64, $0E
		DB	$62, $3D
		DB	$D0, $1D
		DB	$F1, $2C
		DB	$FF
; [6] Shot
EFECTO6:
		DB	$03, $2f
		DB	$ea, $1f
		DB	$dd, $1c
		DB	$d0, $1c
		DB	$c4, $19
		DB	$b7, $19
		DB	$b7, $18
		DB	$b7, $18
		DB	$b7, $15
		DB	$b7, $15
		DB	$FF
; [7] Item #1		(item)
EFECTO7:
		DB	$1F, $0B
		DB	$5A, $0F
		DB	$3C, $0F
		DB	$1E, $0A
		DB	$2D, $0A
		DB	$5A, $05
		DB	$3C, $05
		DB	$1E, $04
		DB	$2D, $02
		DB	$B4, $01
		DB	$FF
; [8] Item #2		(key)
EFECTO8:
		DB	$1F, $0B
		DB	$AF, $0F
		DB	$8A, $0F
		DB	$71, $0F
		DB	$64, $0F
		DB	$3E, $0C
		DB	$25, $0C
		DB	$25, $0C
		DB	$25, $0C
		DB	$25, $0A
		DB	$4B, $0A
		DB	$4B, $0A
		DB	$4B, $0A
		DB	$3E, $08
		DB	$3E, $08
		DB	$3E, $08
		DB	$71, $08
		DB	$3E, $07
		DB	$25, $05
		DB	$25, $02
		DB	$FF
; [9] Item #3		(life)
EFECTO9:
		DB	$1A, $0E
		DB	$B4, $0E
		DB	$B4, $0E
		DB	$B4, $0E
		DB	$B4, $0E
		DB	$B4, $0E
		DB	$B4, $0E
		DB	$B4, $0E
		DB	$B4, $0E
		DB	$A0, $0E
		DB	$A0, $0E
		DB	$A0, $0E
		DB	$A0, $0E
		DB	$A0, $0E
		DB	$A0, $0E
		DB	$A0, $0E
		DB	$87, $0E
		DB	$87, $0E
		DB	$87, $0E
		DB	$87, $0E
		DB	$87, $0E
		DB	$87, $0E
		DB	$87, $0E
		DB	$87, $0E
		DB	$87, $0E
		DB	$78, $0E
		DB	$78, $0E
		DB	$78, $0D
		DB	$78, $0D
		DB	$78, $0D
		DB	$78, $0D
		DB	$78, $0D
		DB	$78, $0D
		DB	$78, $0C
		DB	$78, $09
		DB	$78, $06
		DB	$78, $05
		DB	$FF
; [10] Puncho
EFECTO10:
		DB	$E8, $1B
		DB	$5F, $1F
		DB	$A6, $2F
		DB	$00, $00
		DB	$80, $0F
		DB	$FF
; [11] Coin
EFECTO11:
		DB	$1F, $0B
		DB	$5A, $0F
		DB	$3C, $0F
		DB	$1E, $0A
		DB	$2D, $0A
		DB	$5A, $05
		DB	$3C, $05
		DB	$1E, $04
		DB	$2D, $02
		DB	$B4, $01
		DB	$FF
; [12] Talk1
EFECTO12:
		DB	$1F, $0B
		DB	$5A, $0F
		DB	$3C, $0F
		DB	$1E, $0A
		DB	$2D, $0A
		DB	$5A, $05
		DB	$3C, $05
		DB	$1E, $04
		DB	$2D, $02
		DB	$B4, $01
		DB	$FF
; [13] Talk2
EFECTO13:
		DB	$E8, $1B
		DB	$5F, $0F
		DB	$E2, $0F
		DB	$56, $0F
		DB	$F6, $0F
		DB	$14, $0E
		DB	$64, $0E
		DB	$62, $0D
		DB	$D0, $0D
		DB	$F1, $0C
		DB	$FF
; [14] Lock
EFECTO14:
		DB	$E8, $1B
		DB	$5F, $0F
		DB	$A6, $0F
		DB	$00, $00
		DB	$80, $0F
		DB	$FF

TABLA_EFECTOS:	DW	EFECTO0, EFECTO1, EFECTO2, EFECTO3, EFECTO4, EFECTO5, EFECTO6, EFECTO7, EFECTO8, EFECTO9, EFECTO10, EFECTO11, EFECTO12, EFECTO13, EFECTO14
