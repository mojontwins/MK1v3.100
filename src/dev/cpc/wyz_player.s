; WYZ player de CPC (CPC PSG proPLAYER V 0.47c - WYZ 19.03.2016, para WYZ
; Tracker 2.0), adaptado al motor por na_th_an.
;
; Lo que se llama desde C (convención de SDCC, el argumento de 8 bits en A):
;   wyz_init ()              inicializa el reproductor (todo parado)
;   wyz_play_music (n)       descomprime la canción n de wyz_songs en el
;                            buffer y la toca (la ISR llama a WYZ_PLAYER_ISR)
;   wyz_play_sound (n)       toca el efecto n por el canal WYZ_FX_CHANNEL
;   wyz_stop_sound ()        para la música y los efectos
; Todas guardan IX, que el reproductor usa y SDCC necesita intacto.
;
; Necesita: TABLA_PAUTAS y TABLA_SONIDOS (instrumentos.s, de
; wyzTrackerParser), TABLA_EFECTOS (efectos.s) y, del motor, wyz_songs,
; isr_player_on, wyz_beat_ct, depack (zx0.h) y las direcciones de los
; buffers (__wyz_song_buffer, __base_wyz: churromain.c).

	.module wyz_player
	.globl _wyz_init
	.globl _wyz_play_music
	.globl _wyz_play_sound
	.globl _wyz_stop_sound
	.globl WYZ_PLAYER_ISR
	.globl TABLA_PAUTAS
	.globl TABLA_SONIDOS
	.globl TABLA_EFECTOS
	.globl _wyz_songs
	.globl _isr_player_on
	.globl _wyz_beat_ct
	.globl depack
	.globl __wyz_song_buffer
	.globl __base_wyz

	; Canal de los efectos de sonido
	WYZ_FX_CHANNEL = 1

	.area _CODE

_wyz_init::
	push ix
	xor a
	ld (_isr_player_on), a
	call WYZPLAYER_INIT
	pop ix
	ret

_wyz_play_music::
	push ix
	; Dirección de la canción A (comprimida) en wyz_songs
	ld l, a
	ld h, #0
	add hl, hl
	ld de, #_wyz_songs
	add hl, de
	ld a, (hl)
	inc hl
	ld h, (hl)
	ld l, a
	; Se descomprime en el buffer y se carga
	ld de, #__wyz_song_buffer
	call depack
	xor a
	call CARGA_CANCION
	ld a, #1
	ld (_isr_player_on), a
	pop ix
	ret

_wyz_play_sound::
	push ix
	ld b, #WYZ_FX_CHANNEL
	call INICIA_EFECTO
	pop ix
	ret

_wyz_stop_sound::
	push ix
	call PLAYER_OFF
	xor a
	ld (_isr_player_on), a
	pop ix
	ret

	; CPC PSG proPLAYER V 0.47c - WYZ 19.03.2016
	; (WYZTracker 2.0 o superior)

WYZPLAYER_INIT:
	call PLAYER_OFF

	ld DE, #0x0020; No. BYTES RESERVADOS POR CANAL

	ld HL, #__base_wyz;* RESERVAR MEMORIA PARA BUFFER DE SONIDO!!!!!
	ld (CANAL_A), HL
	add HL, DE
	ld (CANAL_B), HL
	add HL, DE
	ld (CANAL_C), HL
	add HL, DE
	ld (CANAL_P), HL
	ret

INICIO:
WYZ_PLAYER_ISR:
	call ROUT
	ld HL, #PSG_REG
	ld DE, #PSG_REG_SEC
	ld BC, #14
	ldir

	call REPRODUCE_SONIDO
	call PLAY
	jp REPRODUCE_EFECTO

	; REPRODUCE UN SONIDO POR EL CANAL ESPECIFICADO
	; IN
	; A = NUMERO DE SONIDO
	; B = CANAL
INICIA_SONIDO:
	ld HL, #TABLA_SONIDOS
	call EXT_WORD
	ld (PUNTERO_SONIDO), DE
	ld HL, #INTERR
	set 2, (HL)
		; na_th_an :: Percussion channel is fixed to 1
		;LD A, 1
		;LD HL, TABLA_DATOS_CANAL_SFX
		;CALL EXT_WORD
		;LD (SONIDO_REGS), DE
	ret

	; REPRODUCE UN FX POR EL CANAL ESPECIFICADO
	; IN
	; A = NUMERO DE SONIDO
	; B = CANAL
INICIA_EFECTO:
	ld HL, #TABLA_EFECTOS
	call EXT_WORD
	ld (PUNTERO_EFECTO), DE
	ld HL, #INTERR
	set 3, (HL)
	ld A, B
	ld HL, #TABLA_DATOS_CANAL_SFX
	call EXT_WORD
	ld (EFECTO_REGS), DE
	ret

	;REPRODUCE EFECTOS DE SONIDO
REPRODUCE_SONIDO:
	ld HL, #INTERR
	bit 2, (HL);ESTA ACTIVADO EL EFECTO?
	ret Z
	ld HL, (SONIDO_REGS)
	push HL
	pop IX
	ld HL, (PUNTERO_SONIDO)
	call REPRODUCE_SONIDO_O_EFECTO
	or A
	jr Z, REPRODUCE_SONIDO_LIMPIA_BIT
	ld (PUNTERO_SONIDO), HL
	ret
REPRODUCE_SONIDO_LIMPIA_BIT:
	ld HL, #INTERR
	res 2, (HL)
	ret

REPRODUCE_EFECTO:
	ld HL, #INTERR
	bit 3, (HL)
	ret Z
	ld HL, (EFECTO_REGS)
	push HL
	pop IX
	ld HL, (PUNTERO_EFECTO)
	call REPRODUCE_SONIDO_O_EFECTO
	or A
	jr Z, REPRODUCE_EFECTO_LIMPIA_BIT
	ld (PUNTERO_EFECTO), HL
	ret
REPRODUCE_EFECTO_LIMPIA_BIT:
	ld HL, #INTERR
	res 3, (HL)
	ret

REPRODUCE_SONIDO_O_EFECTO:
	ld A, (HL)
	cp #0xFF
	jr Z, FIN_SONIDO
	ld E, 0(ix); IX+0 -> SFX_L LO
	ld D, 1(ix); IX+1 -> SFX_L HI
	ld (DE), A
	inc HL
	ld A, (HL)
	rrca
	rrca
	rrca
	rrca
	and #0b00001111
	ld E, 2(ix); IX+2 -> SFX_H LO
	ld D, 3(ix); IX+3 -> SFX_H HI
	ld (DE), A
	ld A, (HL)
	and #0b00001111
	ld E, 4(ix); IX+4 -> SFX_V LO
	ld D, 5(ix); IX+5 -> SFX_V HI
	ld (DE), A

	inc HL
	ld A, (HL)
	ld B, A
	bit 7, A;09.08.13 BIT MAS SIGINIFICATIVO ACTIVA ENVOLVENTES
	jr Z, NO_ENVOLVENTES_SONIDO
	ld A, #0x12
	ld (DE), A
	inc HL
	ld A, (HL)
	ld (PSG_REG_SEC+11), A
	inc HL
	ld A, (HL)
	ld (PSG_REG_SEC+12), A
	inc HL
	ld A, (HL)
	cp #1
	jr Z, NO_ENVOLVENTES_SONIDO;NO ESCRIBE LA ENVOLVENTE SI SU VALOR ES 1
	ld (PSG_REG_SEC+13), A

NO_ENVOLVENTES_SONIDO:
	ld A, B
	and #0x7F; RES 7,A ; AND A
	jr Z, NO_RUIDO
	ld (PSG_REG_SEC+6), A
	ld A, 6(ix); IX+6 -> SFX_MIX
	jr SI_RUIDO
NO_RUIDO:	xor A
	ld (PSG_REG_SEC+6), A
	ld A, #0b10111000
SI_RUIDO:	ld (PSG_REG_SEC+7), A
	inc HL
	ld A, #1
	ret
FIN_SONIDO:
	ld A, (ENVOLVENTE_BACK);NO RESTAURA LA ENVOLVENTE SI ES 0
	and A
	jr Z, FIN_NOPLAYER
		;xor a ; ***
	ld (PSG_REG_SEC+13), A;08.13 RESTAURA LA ENVOLVENTE TRAS EL SFX

FIN_NOPLAYER:
	ld A, #0b10111000
	ld (PSG_REG_SEC+7), A
	xor A
	ret

	;VUELCA BUFFER DE SONIDO AL PSG
ROUT:
	ld A, (PSG_REG+13)
	and A;ES CERO?
	jr Z, NO_BACKUP_ENVOLVENTE
	ld (ENVOLVENTE_BACK), A;08.13 / GUARDA LA ENVOLVENTE EN EL BACKUP
	xor A

NO_BACKUP_ENVOLVENTE:
	;VUELCA BUFFER DE SONIDO AL PSG
	ld HL, #PSG_REG_SEC
LOUT:
	call WRITEPSGHL
	inc A
	cp #13
	jr NZ, LOUT
	ld A, (HL)
	and A
	ret Z
	ld A, #13
	call WRITEPSGHL
	xor A
	ld (PSG_REG+13), A
	ld (PSG_REG_SEC+13), A
	ret

	;; A = REGISTER
	;; (HL) = VALUE
WRITEPSGHL:
	ld B, #0xF4
	out (C), A
	ld BC, #0xF6C0
	out (C), C
	.db 0xED
	.db 0x71
	ld B, #0xF5
	outi
	ld BC, #0xF680
	out (C), C
	.db 0xED
	.db 0x71
	ret

	;PLAYER OFF
PLAYER_OFF:
	xor A;***** IMPORTANTE SI NO HAY MUSICA ****
	ld (INTERR), A
		;LD (FADE),A ;solo si hay fade out

CLEAR_PSG_BUFFER:
	ld HL, #PSG_REG
	ld DE, #PSG_REG+1
	ld BC, #14
	ld (HL), A
	ldir

	ld A, #0b10111000; **** POR SI ACASO ****
	ld (PSG_REG+7), A

	ld HL, #PSG_REG
	ld DE, #PSG_REG_SEC
	ld BC, #14
	ldir

	jp ROUT

	;CARGA UNA CANCION
	;.IN(A)=Nº DE CANCION
CARGA_CANCION:
	ld HL, #INTERR;CARGA CANCION 
	set 1, (HL);REPRODUCE CANCION
	ld HL, #SONG
	ld (HL), A;Nº A

	;DECODIFICAR
	;IN-> INTERR 0 ON
	; SONG
	;CARGA CANCION SI/NO
DECODE_SONG:
	ld A, (SONG)

	;LEE CABECERA DE LA CANCION
	;BYTE 0=TEMPO

	ld HL, #TABLA_SONG
	call EXT_WORD
	ld A, (DE)
	ld (TEMPO), A
	dec A
	ld (TTEMPO), A

	;HEADER BYTE 1
	;[-|-|-|-| 3-1 | 0 ]
	;[-|-|-|-|FX CHN|LOOP]

	inc DE;LOOP 1=ON/0=OFF?
	ld A, (DE)
	bit 0, A
	jr Z, NPTJP0
	ld HL, #INTERR
	set 4, (HL)

	;SELECCION DEL CANAL DE EFECTOS DE RITMO
NPTJP0:
	and #0b00000110
	rra
		;LD (SELECT_CANAL_P),A

	push DE
		; na_th_an :: Percussion channel is fixed to 1
		;LD HL, TABLA_DATOS_CANAL_SFX
		;CALL EXT_WORD
		;LD (SONIDO_REGS), DE
	pop HL

	inc HL;2 BYTES RESERVADOS
	inc HL
	inc HL

	;BUSCA Y GUARDA INICIO DE LOS CANALES EN EL MODULO MUS (OPTIMIZAR****************)
	;AÑADE OFFSET DEL LOOP

	push HL;IX INICIO OFFSETS LOOP POR CANAL
	pop IX

	ld DE, #0x0008;HASTA INICIO DEL CANAL A
	add HL, DE


	ld (PUNTERO_P_DECA), HL;GUARDA PUNTERO INICIO CANAL
	ld E, 0(ix)
	ld D, 1(ix)
	add HL, DE
	ld (PUNTERO_L_DECA), HL;GUARDA PUNTERO INICIO LOOP

	call BGICMODBC1
	ld (PUNTERO_P_DECB), HL
	ld E, 2(ix)
	ld D, 3(ix)
	add HL, DE
	ld (PUNTERO_L_DECB), HL

	call BGICMODBC1
	ld (PUNTERO_P_DECC), HL
	ld E, 4(ix)
	ld D, 5(ix)
	add HL, DE
	ld (PUNTERO_L_DECC), HL

	call BGICMODBC1
	ld (PUNTERO_P_DECP), HL
	ld E, 6(ix)
	ld D, 7(ix)
	add HL, DE
	ld (PUNTERO_L_DECP), HL


	;LEE DATOS DE LAS NOTAS
	;[|][|||||] LONGITUD\NOTA

INIT_DECODER:
	ld DE, (CANAL_A)
	ld (PUNTERO_A), DE
	ld HL, (PUNTERO_P_DECA)
	call DECODE_CANAL;CANAL A
	ld (PUNTERO_DECA), HL

	ld DE, (CANAL_B)
	ld (PUNTERO_B), DE
	ld HL, (PUNTERO_P_DECB)
	call DECODE_CANAL;CANAL B
	ld (PUNTERO_DECB), HL

	ld DE, (CANAL_C)
	ld (PUNTERO_C), DE
	ld HL, (PUNTERO_P_DECC)
	call DECODE_CANAL;CANAL C
	ld (PUNTERO_DECC), HL

	ld DE, (CANAL_P)
	ld (PUNTERO_P), DE
	ld HL, (PUNTERO_P_DECP)
	call DECODE_CANAL;CANAL P
	ld (PUNTERO_DECP), HL

	ret

	;BUSCA INICIO DEL CANAL

BGICMODBC1:
	ld E, #0x3F;CODIGO INSTRUMENTO 0
BGICMODBC2:
	xor A;BUSCA EL BYTE 0
	ld B, #0xFF;EL MODULO DEBE TENER UNA LONGITUD MENOR DE 0xFF00 ... o_O!
	cpir

	dec HL
	dec HL
	ld A, E;ES EL INSTRUMENTO 0??
	cp (HL)
	inc HL
	inc HL
	jr Z, BGICMODBC2

	dec HL
	dec HL
	dec HL
	ld A, E;ES VOLUMEN 0??
	cp (HL)
	inc HL
	inc HL
	inc HL
	jr Z, BGICMODBC2
	ret

	;DECODIFICA NOTAS DE UN CANAL
	;IN (DE)=DIRECCION DESTINO
	;NOTA=0 FIN CANAL
	;NOTA=1 SILENCIO
	;NOTA=2 PUNTILLO
	;NOTA=3 COMANDO I

DECODE_CANAL:
	ld A, (HL)
	and A;FIN DEL CANAL?
	jr Z, FIN_DEC_CANAL
	call GETLEN

	cp #0b00000001;ES SILENCIO?
	jr NZ, NO_SILENCIO
	or #0x40; SET 6,A
	jr NO_MODIFICA

NO_SILENCIO:
	cp #0b00111110;ES PUNTILLO?
	jr NZ, NO_PUNTILLO
	or A
	rrc B
	xor A
	jr NO_MODIFICA

NO_PUNTILLO:
	cp #0b00111111;ES COMANDO?
	jr NZ, NO_MODIFICA
	bit 0, B;COMADO=INSTRUMENTO?
	jr Z, NO_INSTRUMENTO
	ld A, #0b11000001;CODIGO DE INSTRUMENTO 
	ld (DE), A
	inc HL
	inc DE
	ldi;Nº DE INSTRUMENTO
		; LD A,(HL)
		; LD (DE),A
		; INC DE
		; INC HL
	ldi;VOLUMEN RELATIVO DEL INSTRUMENTO
		; LD A,(HL)
		; LD (DE),A
		; INC DE
		; INC HL
	jr DECODE_CANAL

NO_INSTRUMENTO:
	bit 2, B
	jr Z, NO_ENVOLVENTE
	ld A, #0b11000100;CODIGO ENVOLVENTE
	ld (DE), A
	inc DE
	inc HL
	ldi
		; LD A,(HL)
		; LD (DE),A
		; INC DE
		; INC HL
	jr DECODE_CANAL

NO_ENVOLVENTE:
	bit 1, B
	jr Z, NO_MODIFICA
	ld A, #0b11000010;CODIGO EFECTO
	ld (DE), A
	inc HL
	inc DE
	ld A, (HL)
	call GETLEN

NO_MODIFICA:
	ld (DE), A
	inc DE
	xor A
	djnz NO_MODIFICA
	or #0x81; SET 7,A ; SET 0,A
	ld (DE), A
	inc DE
	inc HL
	ret;** JR DECODE_CANAL

FIN_DEC_CANAL:
	or #0x80; SET 7,A
	ld (DE), A
	inc DE
	ret

GETLEN:
	ld B, A
	and #0b00111111
	push AF
	ld A, B
	and #0b11000000
	rlca
	rlca
	inc A
	ld B, A
	ld A, #0b10000000
DCBC0:
	rlca
	djnz DCBC0
	ld B, A
	pop AF
	ret

	;PLAY __________________________________________________
PLAY:
	ld HL, #INTERR;PLAY BIT 1 ON?
	bit 1, (HL)
	ret Z
	;TEMPO
	ld HL, #TTEMPO;CONTADOR TEMPO
	inc (HL)
	ld A, (TEMPO)
	cp (HL)
	jr NZ, PAUTAS
	ld (HL), #0

	;INTERPRETA
		; Lee una nueva linea. Yo voy a incrementar dos contadores:
		; uno de lineas. Otro se incrementará cada 4 lineas. Éste lo "reflejaré" en low ram.
	ld a, (LINE_COUNTER)
	inc a
	cp #4
	jr nz, nonewblack

		; Incrementamos esto en low RAM
	ld hl, #_wyz_beat_ct
	inc (hl)

	xor a

nonewblack:
	ld (LINE_COUNTER), a

	ld IY, #PSG_REG
	ld IX, #PUNTERO_A
	ld BC, #PSG_REG+8
	call LOCALIZA_NOTA
	ld IY, #PSG_REG+2
	ld IX, #PUNTERO_B
	ld BC, #PSG_REG+9
	call LOCALIZA_NOTA
	ld IY, #PSG_REG+4
	ld IX, #PUNTERO_C
	ld BC, #PSG_REG+10
	call LOCALIZA_NOTA
	ld IX, #PUNTERO_P;EL CANAL DE EFECTOS ENMASCARA OTRO CANAL
	call LOCALIZA_EFECTO

	;PAUTAS

PAUTAS:
	ld IY, #PSG_REG+0
	ld IX, #PUNTERO_P_A
	ld HL, #PSG_REG+8
	call PAUTA;PAUTA CANAL A
	ld IY, #PSG_REG+2
	ld IX, #PUNTERO_P_B
	ld HL, #PSG_REG+9
	call PAUTA;PAUTA CANAL B
	ld IY, #PSG_REG+4
	ld IX, #PUNTERO_P_C
	ld HL, #PSG_REG+10
	jp PAUTA;PAUTA CANAL C 





	;LOCALIZA NOTA CANAL A
	;IN (PUNTERO_A)

	;LOCALIZA NOTA CANAL A
	;IN (PUNTERO_A)

LOCALIZA_NOTA:
	ld L, PUNTERO_A-PUNTERO_A(ix);HL=(PUNTERO_A_C_B)
	ld H, PUNTERO_A-PUNTERO_A+1(ix)
	ld A, (HL)
	and #0b11000000;COMANDO?
	cp #0b11000000
	jr NZ, LNJP0

	;BIT(0)=INSTRUMENTO

COMANDOS:
	ld A, (HL)
	bit 0, A;INSTRUMENTO
	jr Z, COM_EFECTO

	inc HL
	ld A, (HL);Nº DE PAUTA
	inc HL
	ld E, (HL)

	push HL;;TEMPO ******************
	ld HL, #TEMPO
	bit 5, E
	jr Z, NO_DEC_TEMPO
	dec (HL)
NO_DEC_TEMPO:
	bit 6, E
	jr Z, NO_INC_TEMPO
	inc (HL)
NO_INC_TEMPO:
	res 5, E;SIEMPRE RESETEA LOS BITS DE TEMPO 
	res 6, E
	pop HL

	ld VOL_INST_A-PUNTERO_A(ix), E;REGISTRO DEL VOLUMEN RELATIVO
	inc HL
	ld PUNTERO_A-PUNTERO_A(ix), L
	ld PUNTERO_A-PUNTERO_A+1(ix), H
	ld HL, #TABLA_PAUTAS
	call EXT_WORD
	ld PUNTERO_P_A0-PUNTERO_A(ix), E
	ld PUNTERO_P_A0-PUNTERO_A+1(ix), D
	ld PUNTERO_P_A-PUNTERO_A(ix), E
	ld PUNTERO_P_A-PUNTERO_A+1(ix), D
	ld L, C
	ld H, B
	res 4, (HL);APAGA EFECTO ENVOLVENTE
	xor A
	ld (PSG_REG_SEC+13), A
	ld (PSG_REG+13), A
		;LD (ENVOLVENTE_BACK),A ;08.13 / RESETEA EL BACKUP DE LA ENVOLVENTE
	jr LOCALIZA_NOTA

COM_EFECTO:
	bit 1, A;EFECTO DE SONIDO
	jr Z, COM_ENVOLVENTE

	inc HL
	ld A, (HL)
	inc HL
	ld PUNTERO_A-PUNTERO_A(ix), L
	ld PUNTERO_A-PUNTERO_A+1(ix), H

	jp INICIA_SONIDO

COM_ENVOLVENTE:
	bit 2, A
	ret Z;IGNORA - ERROR 

	inc HL
	ld A, (HL);CARGA CODIGO DE ENVOLVENTE
	ld (ENVOLVENTE), A
	inc HL
	ld PUNTERO_A-PUNTERO_A(ix), L
	ld PUNTERO_A-PUNTERO_A+1(ix), H
	ld L, C
	ld H, B
	ld (HL), #0b00010000;ENCIENDE EFECTO ENVOLVENTE
	jr LOCALIZA_NOTA


LNJP0:
	ld A, (HL)
	inc HL
	bit 7, A
	jr Z, NO_FIN_CANAL_A;
	bit 0, A
	jr Z, FIN_CANAL_A

FIN_NOTA_A:
	ld E, CANAL_A-PUNTERO_A(ix)
	ld D, CANAL_A-PUNTERO_A+1(ix);PUNTERO BUFFER AL INICIO
	ld PUNTERO_A-PUNTERO_A(ix), E
	ld PUNTERO_A-PUNTERO_A+1(ix), D
	ld L, PUNTERO_DECA-PUNTERO_A(ix);CARGA PUNTERO DECODER
	ld H, PUNTERO_DECA-PUNTERO_A+1(ix)
	push BC
	call DECODE_CANAL;DECODIFICA CANAL
	pop BC
	ld PUNTERO_DECA-PUNTERO_A(ix), L;GUARDA PUNTERO DECODER
	ld PUNTERO_DECA-PUNTERO_A+1(ix), H
	jp LOCALIZA_NOTA

FIN_CANAL_A:
	ld HL, #INTERR;LOOP?
	bit 4, (HL)
	jr NZ, FCA_CONT
	pop AF
	jp PLAYER_OFF


FCA_CONT:
	ld L, PUNTERO_L_DECA-PUNTERO_A(ix);CARGA PUNTERO INICIAL DECODER
	ld H, PUNTERO_L_DECA-PUNTERO_A+1(ix)
	ld PUNTERO_DECA-PUNTERO_A(ix), L
	ld PUNTERO_DECA-PUNTERO_A+1(ix), H
	jr FIN_NOTA_A

NO_FIN_CANAL_A:
	ld PUNTERO_A-PUNTERO_A(ix), L;(PUNTERO_A_B_C)=HL GUARDA PUNTERO
	ld PUNTERO_A-PUNTERO_A+1(ix), H
	and A;NO REPRODUCE NOTA SI NOTA=0
	jr Z, FIN_RUTINA
	bit 6, A;SILENCIO?
	jr Z, NO_SILENCIO_A
	ld A, (BC)
	and #0b00010000
	jr NZ, SILENCIO_ENVOLVENTE

	xor A
	ld (BC), A;RESET VOLUMEN DEL CORRESPODIENTE CHIP
	ld 0(iy), A
	ld 1(iy), A
	ret

SILENCIO_ENVOLVENTE:
	ld A, #0xFF
	ld (PSG_REG+11), A
	ld (PSG_REG+12), A
	xor A
	ld (PSG_REG+13), A
	ld 0(iy), A
	ld 1(iy), A
	ret

NO_SILENCIO_A:
	ld REG_NOTA_A-PUNTERO_A(ix), A;REGISTRO DE LA NOTA DEL CANAL 
	call NOTA;REPRODUCE NOTA
	ld L, PUNTERO_P_A0-PUNTERO_A(ix);HL=(PUNTERO_P_A0) RESETEA PAUTA 
	ld H, PUNTERO_P_A0-PUNTERO_A+1(ix)
	ld PUNTERO_P_A-PUNTERO_A(ix), L;(PUNTERO_P_A)=HL
	ld PUNTERO_P_A-PUNTERO_A+1(ix), H
FIN_RUTINA:
	ret


	;LOCALIZA EFECTO
	;IN HL=(PUNTERO_P)

LOCALIZA_EFECTO:
	ld L, 0(ix);HL=(PUNTERO_P)
	ld H, 1(ix)
	ld A, (HL)
	cp #0b11000010
	jr NZ, LEJP0

	inc HL
	ld A, (HL)
	inc HL
	ld 00(ix), L
	ld 01(ix), H

	jp INICIA_SONIDO


LEJP0:
	inc HL
	bit 7, A
	jr Z, NO_FIN_CANAL_P;
	bit 0, A
	jr Z, FIN_CANAL_P
FIN_NOTA_P:
	ld DE, (CANAL_P)
	ld 0(ix), E
	ld 1(ix), D
	ld HL, (PUNTERO_DECP);CARGA PUNTERO DECODER
	push BC
	call DECODE_CANAL;DECODIFICA CANAL
	pop BC
	ld (PUNTERO_DECP), HL;GUARDA PUNTERO DECODER
	jp LOCALIZA_EFECTO

FIN_CANAL_P:
	ld HL, (PUNTERO_L_DECP);CARGA PUNTERO INICIAL DECODER
	ld (PUNTERO_DECP), HL
	jr FIN_NOTA_P

NO_FIN_CANAL_P:
	ld 0(ix), L;(PUNTERO_A_B_C)=HL GUARDA PUNTERO
	ld 1(ix), H
	ret

	; PAUTA DE LOS 3 CANALES
	; .IN(IX):PUNTERO DE LA PAUTA
	; (HL):REGISTRO DE VOLUMEN
	; (IY):REGISTROS DE FRECUENCIA

	; FORMATO PAUTA
	; 7 6 5 4 3-0 3-0
	; BYTE 1 [LOOP|OCT-1|OCT+1|ORNMT|VOL] - BYTE 2 [ | | | |PITCH/NOTA]

PAUTA:
	bit 4, (HL);SI LA ENVOLVENTE ESTA ACTIVADA NO ACTUA PAUTA
	ret NZ

	ld A, 0(iy)
	ld B, 1(iy)
	or B
	ret Z


	push HL

PCAJP4:
	ld L, 0(ix)
	ld H, 1(ix)
	ld A, (HL)

	bit 7, A;LOOP / EL RESTO DE BITS NO AFECTAN
	jr Z, PCAJP0
	and #0b00011111;MÁXIMO LOOP PAUTA (0,32)X2!!!-> PARA ORNAMENTOS
	rlca;X2
	ld D, #0
	ld E, A
	sbc HL, DE
	ld A, (HL)

PCAJP0:
	bit 6, A;OCTAVA -1
	jr Z, PCAJP1
	ld E, 0(iy)
	ld D, 1(iy)

	and A
	rrc D
	rr E
	ld 0(iy), E
	ld 1(iy), D
	jr PCAJP2

PCAJP1:
	bit 5, A;OCTAVA +1
	jr Z, PCAJP2
	ld E, 0(iy)
	ld D, 1(iy)

	and A
	rlc E
	rl D
	ld 0(iy), E
	ld 1(iy), D




PCAJP2:
	ld A, (HL)
	bit 4, A
	jr NZ, PCAJP6;ORNAMENTOS SELECCIONADOS

	inc HL;______________________ FUNCION PITCH DE FRECUENCIA__________________ 
	push HL
	ld E, A
	ld A, (HL);PITCH DE FRECUENCIA
	ld L, A
	and A
	ld A, E
	jr Z, ORNMJP1

	ld A, 0(iy);SI LA FRECUENCIA ES 0 NO HAY PITCH
	add A, 1(iy)
	and A
	ld A, E
	jr Z, ORNMJP1


	bit 7, L
	jr Z, ORNNEG
	ld H, #0xFF
	jr PCAJP3
ORNNEG:
	ld H, #0

PCAJP3:
	ld E, 0(iy)
	ld D, 1(iy)
	adc HL, DE
	ld 0(iy), L
	ld 1(iy), H
	jr ORNMJP1


PCAJP6:
	inc HL;______________________ FUNCION ORNAMENTOS__________________ 

	push HL
	push AF
	ld A, REG_NOTA_A-PUNTERO_P_A(ix);RECUPERA REGISTRO DE NOTA EN EL CANAL
	ld E, (HL);
	adc E;+- NOTA 
	call TABLA_NOTAS
	pop AF


ORNMJP1:
	pop HL

	inc HL
	ld 0(ix), L
	ld 1(ix), H
PCAJP5:
	pop HL
	ld B, VOL_INST_A-PUNTERO_P_A(ix);VOLUMEN RELATIVO
	add B
	jp P, PCAJP7
	ld A, #1;NO SE EXTIGUE EL VOLUMEN
PCAJP7:
	and #0b00001111;VOLUMEN FINAL MODULADO
	ld (HL), A
	ret



	;NOTA -  REPRODUCE UNA NOTA
	;IN (A)=CODIGO DE LA NOTA
	; (IY)=REGISTROS DE FRECUENCIA


NOTA:
	ld L, C
	ld H, B
	bit 4, (HL)
	ld B, A
	jr NZ, EVOLVENTES
	ld A, B
TABLA_NOTAS:
	ld HL, #DATOS_NOTAS;BUSCA FRECUENCIA
	call EXT_WORD
	ld 0(iy), E
	ld 1(iy), D
	ret




	;IN (A)=CODIGO DE LA ENVOLVENTE
	; (IY)=REGISTRO DE FRECUENCIA

EVOLVENTES:
	ld HL, #DATOS_NOTAS
		;SUB 12
	rlca;X2
	ld D, #0
	ld E, A
	add HL, DE
	ld E, (HL)
	inc HL
	ld D, (HL)

	push DE
	ld A, (ENVOLVENTE);FRECUENCIA DEL CANAL ON/OFF
	rra
	jr NC, FRECUENCIA_OFF
	ld 0(iy), E
	ld 1(iy), D
	jr CONT_ENV

FRECUENCIA_OFF:
	ld DE, #0x0000
	ld 0(iy), E
	ld 1(iy), D
		;CALCULO DEL RATIO (OCTAVA ARRIBA)
CONT_ENV:
	pop DE
	push AF
	push BC
	and #0b00000011
	ld B, A
		;INC B

		;AND A ;1/2
	rr D
	rr E
CRTBC0:
		;AND A ;1/4 - 1/8 - 1/16
	rr D
	rr E
	djnz CRTBC0
	ld A, E
	ld (PSG_REG+11), A
	ld A, D
	and #0b00000011
	ld (PSG_REG+12), A
	pop BC
	pop AF;SELECCION FORMA DE ENVOLVENTE

	rra
	and #0b00000110;0x08,0x0A,0x0C,0x0E
	add #8
	ld (PSG_REG+13), A
	ld (ENVOLVENTE_BACK), A
	ret


	;EXTRAE UN WORD DE UNA TABLA
	;.IN(HL)=DIRECCION TABLA
	; (A)= POSICION
	;OUT(DE)=WORD

EXT_WORD:
	ld D, #0
	rlca
	ld E, A
	add HL, DE
	ld E, (HL)
	inc HL
	ld D, (HL)
	ret

	;TABLA DE DATOS DEL SELECTOR DEL CANAL DE EFECTOS DE RITMO

TABLA_DATOS_CANAL_SFX:
	.dw SELECT_CANAL_A,SELECT_CANAL_B,SELECT_CANAL_C


	;BYTE 0:SFX_L
	;BYTE 1:SFX_H
	;BYTE 2:SFX_V
	;BYTE 3:SFX_MIX

SELECT_CANAL_A:
	.dw PSG_REG_SEC+0, PSG_REG_SEC+1, PSG_REG_SEC+8
	.db 0b10110001

SELECT_CANAL_B:
	.dw PSG_REG_SEC+2, PSG_REG_SEC+3, PSG_REG_SEC+9
	.db 0b10101010

SELECT_CANAL_C:
	.dw PSG_REG_SEC+4, PSG_REG_SEC+5, PSG_REG_SEC+10
	.db 0b10011100


	;____________________________________


INTERR:
	.db 0;INTERRUPTORES 1=ON 0=OFF
				;BIT 0=CARGA CANCION ON/OFF
				;BIT 1=PLAYER ON/OFF
				;BIT 2=EFECTOS ON/OFF
				;BIT 3=SFX ON/OFF
				;BIT 4=LOOP

	;MUSICA **** EL ORDEN DE LAS VARIABLES ES FIJO ******

SONG:	.db 0;DBNº DE CANCION
TEMPO:	.db 0;DB TEMPO
TTEMPO:	.db 0;DB CONTADOR TEMPO

PUNTERO_A:	.dw 0;DW PUNTERO DEL CANAL A
PUNTERO_B:	.dw 0;DW PUNTERO DEL CANAL B
PUNTERO_C:	.dw 0;DW PUNTERO DEL CANAL C

CANAL_A:	.dw 0;DW DIRECION DE INICIO DE LA MUSICA A
CANAL_B:	.dw 0;DW DIRECION DE INICIO DE LA MUSICA B
CANAL_C:	.dw 0;DW DIRECION DE INICIO DE LA MUSICA C

PUNTERO_P_A:	.dw 0;DW PUNTERO PAUTA CANAL A
PUNTERO_P_B:	.dw 0;DW PUNTERO PAUTA CANAL B
PUNTERO_P_C:	.dw 0;DW PUNTERO PAUTA CANAL C

PUNTERO_P_A0:	.dw 0;DW INI PUNTERO PAUTA CANAL A
PUNTERO_P_B0:	.dw 0;DW INI PUNTERO PAUTA CANAL B
PUNTERO_P_C0:	.dw 0;DW INI PUNTERO PAUTA CANAL C

PUNTERO_P_DECA:	.dw 0;DW PUNTERO DE INICIO DEL DECODER CANAL A
PUNTERO_P_DECB:	.dw 0;DW PUNTERO DE INICIO DEL DECODER CANAL B
PUNTERO_P_DECC:	.dw 0;DW PUNTERO DE INICIO DEL DECODER CANAL C

PUNTERO_DECA:	.dw 0;DW PUNTERO DECODER CANAL A
PUNTERO_DECB:	.dw 0;DW PUNTERO DECODER CANAL B
PUNTERO_DECC:	.dw 0;DW PUNTERO DECODER CANAL C 

PUNTERO_EFECTO:	.dw 0;DW PUNTERO DEL SONIDO QUE SE REPRODUCE

REG_NOTA_A:	.db 0;DB REGISTRO DE LA NOTA EN EL CANAL A
VOL_INST_A:	.db 0;DB VOLUMEN RELATIVO DEL INSTRUMENTO DEL CANAL A
REG_NOTA_B:	.db 0;DB REGISTRO DE LA NOTA EN EL CANAL B
VOL_INST_B:	.db 0;DB VOLUMEN RELATIVO DEL INSTRUMENTO DEL CANAL B ;VACIO
REG_NOTA_C:	.db 0;DB REGISTRO DE LA NOTA EN EL CANAL C
VOL_INST_C:	.db 0;DB VOLUMEN RELATIVO DEL INSTRUMENTO DEL CANAL C

PUNTERO_L_DECA:	.dw 0;DW PUNTERO DE INICIO DEL LOOP DEL DECODER CANAL A
PUNTERO_L_DECB:	.dw 0;DW PUNTERO DE INICIO DEL LOOP DEL DECODER CANAL B
PUNTERO_L_DECC:	.dw 0;DW PUNTERO DE INICIO DEL LOOP DEL DECODER CANAL C

	;CANAL DE EFECTOS DE RITMO - ENMASCARA OTRO CANAL

PUNTERO_P:	.dw 0;DW PUNTERO DEL CANAL EFECTOS
CANAL_P:	.dw 0;DW DIRECION DE INICIO DE LOS EFECTOS
PUNTERO_P_DECP:	.dw 0;DW PUNTERO DE INICIO DEL DECODER CANAL P
PUNTERO_DECP:	.dw 0;DW PUNTERO DECODER CANAL P
PUNTERO_L_DECP:	.dw 0;DW PUNTERO DE INICIO DEL LOOP DEL DECODER CANAL P
	;SELECT_CANAL_P defb INTERR+0x36 ;DB SELECCION DE CANAL DE EFECTOS DE RITMO

SFX_L:	.dw 0;DW DIRECCION BUFFER EFECTOS DE RITMO REGISTRO BAJO
SFX_H:	.dw 0;DW DIRECCION BUFFER EFECTOS DE RITMO REGISTRO ALTO
SFX_V:	.dw 0;DW DIRECCION BUFFER EFECTOS DE RITMO REGISTRO VOLUMEN
SFX_MIX:	.dw 0;DW DIRECCION BUFFER EFECTOS DE RITMO REGISTRO MIXER

	;EFECTOS DE SONIDO

N_SONIDO:	.db 0;DB : NUMERO DE SONIDO
PUNTERO_SONIDO:	.dw 0;DW : PUNTERO DEL SONIDO QUE SE REPRODUCE

EFECTO_REGS:	.dw 0
SONIDO_REGS:	.dw SELECT_CANAL_B; na_th_an :: Percussion channel is fixed to 1


	;DB (13) BUFFERs DE REGISTROS DEL PSG

PSG_REG:	.ds 16
PSG_REG_SEC:	.ds 16
ENVOLVENTE:
	.db 0;DB : FORMA DE LA ENVOLVENTE
				;BIT 0 : FRECUENCIA CANAL ON/OFF
				;BIT 1-2 : RATIO
				;BIT 3-3 : FORMA
ENVOLVENTE_BACK:	.db 0;.defb BACKUP DE LA FORMA DE LA ENVOLENTE	

DATOS_NOTAS:
	.dw 0x0000, 0x0000
	.dw 964,910,859,811,766,722,682,644,608,573
	.dw 541,511,482,455,430,405,383,361,341,322
	.dw 304,287,271,255,241,228,215,203,191,180
	.dw 170,161,152,143,135,128,121,114,107,101
	.dw 96,90,85,81,76,72,68,64,60,57
	.dw 54,51,48,45,43,40,38,36,34,32

TABLA_SONG:
	.dw __wyz_song_buffer


LINE_COUNTER:
	.db 0
