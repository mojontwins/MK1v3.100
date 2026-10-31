// La Churrera Engine 3.100
// Copyleft 2010-2014 the Mojon Twins

// play_title_music () toca la canción del título una vez (hasta que se pulse
// una tecla), sin interrupciones: es todo temporización. Beepola usa IX.
void play_title_music (void) __naked {
	__asm
		push ix
		di
		call musicstart
		ei
		pop ix
		ret
	__endasm;
}

void music_asm1 (void) __naked {
	__asm
		; *****************************************************************************
		; * Phaser1 Engine, with synthesised drums
		; *
		; * Original code by Shiru - .http;shiru.untergrund.net/
		; * Modified by Chris Cowley
		; *
		; * Produced by Beepola v1.05.01
		; ******************************************************************************

		musicstart:
		ld hl, #musicdata;  <- Pointer to Music Data. Change
		                                        ;     this to play a different song
		ld a, (hl); Get the loop start pointer
		ld (pattern_loop_begin), a
		inc hl
		ld a, (hl); Get the song end pointer
		ld (pattern_loop_end), a
		inc hl
		ld e, (hl)
		inc hl
		ld d, (hl)
		inc hl
		ld (instrum_tbl), hl
		ld (current_inst), hl
		add hl, de
		ld (pattern_addr), hl
		xor a
		ld (pattern_ptr), a; Set the pattern pointer to zero
		ld h, a
		ld l, a
		ld (note_ptr), hl; Set the note offset (within this pattern) to 0

		player:
		             ;DI
		push iy
		             ;LD   A,BORDER_COL
		xor a
		ld h, #0x00
		ld l, a
		ld (cnt_1a), hl
		ld (cnt_1b), hl
		ld (div_1a), hl
		ld (div_1b), hl
		ld (cnt_2), hl
		ld (div_2), hl
		ld (out_1), a
		ld (out_2), a
		jr main_loop

		; ********************************************************************************************************
		; * NEXT_PATTERN
		; *
		; * Select the next pattern in sequence (and handle looping if weve reached PATTERN_LOOP_END
		; * Execution falls through to PLAYNOTE to play the first note from our next pattern
		; ********************************************************************************************************
		next_pattern:
		ld a, (pattern_ptr)
		inc a
		inc a
		.db 0xFE; CP n
		pattern_loop_end:	.db 0
		jr nz, no_pattern_loop
		                          ; Handle Pattern Looping at and of song
		.db 0x3E; LD A,n
		pattern_loop_begin:	.db 0
		no_pattern_loop:	ld (pattern_ptr), a
		ld hl, #0x0000
		ld (note_ptr), hl; Start of pattern (NOTE_PTR = 0)

		main_loop:
		.db 0xfd
		ld l, #0; Set channel = 0

		read_loop:
		ld hl, (pattern_addr)
		ld a, (pattern_ptr)
		ld e, a
		ld d, #0
		add hl, de
		ld e, (hl)
		inc hl
		ld d, (hl); Now DE = Start of Pattern data
		ld hl, (note_ptr)
		inc hl; Increment the note pointer and...
		ld (note_ptr), hl; ..store it
		dec hl
		add hl, de; Now HL = address of note data
		ld a, (hl)
		or a
		jr z, next_pattern; select next pattern

		bit 7, a
		jp z, render; Play the currently defined note(S) and drum
		.db 0xfd
		ld h, a
		and #0x3F
		cp #0x3C
		jp nc, other; Other parameters
		add a, a
		ld b, #0
		ld c, a
		ld hl, #freq_table
		add hl, bc
		ld e, (hl)
		inc hl
		ld d, (hl)
		.db 0xfd
		ld a, l; IYL = 0 for channel 1, or = 1 for channel 2
		or a
		jr nz, set_note2
		ld (div_1a), de
		ex de, hl

		.db 0xDD,0x21; LD IX,nn
		current_inst:
		.dw 0x0000

		ld a, 0x00(ix)
		or a
		jr z, l809b; Original code jumps into byte 2 of the DJNZ (invalid opcode FD)
		ld b, a
		l8098:	add hl, hl
		djnz l8098
		l809b:	ld e, 0x01(ix)
		ld d, 0x02(ix)
		add hl, de
		ld (div_1b), hl
		.db 0xfd
		ld l, #1; Set channel = 1
		.db 0xfd
		ld a, h
		and #0x40
		jr z, read_loop; No phase reset

		ld hl, #out_1; Reset phaser
		res 4, (hl)
		ld hl, #0x0000
		ld (cnt_1a), hl
		ld h, 0x03(ix)
		ld (cnt_1b), hl
		jr read_loop

		set_note2:
		ld (div_2), de
		.db 0xfd
		ld a, h
		ld hl, #out_2
		res 4, (hl)
		ld hl, #0x0000
		ld (cnt_2), hl
		jp read_loop

		set_stop:
		ld hl, #0x0000
		.db 0xfd
		ld a, l
		or a
		jr nz, set_stop2
		             ; Stop channel 1 note
		ld (div_1a), hl
		ld (div_1b), hl
		ld hl, #out_1
		res 4, (hl)
		.db 0xfd
		ld l, #1
		jp read_loop
		set_stop2:
		             ; Stop channel 2 note
		ld (div_2), hl
		ld hl, #out_2
		res 4, (hl)
		jp read_loop

		other:	cp #0x3C
		jr z, set_stop; Stop note
		cp #0x3E
		jr z, skip_ch1; No changes to channel 1
		inc hl; Instrument change
		ld l, (hl)
		ld h, #0x00
		add hl, hl
		ld de, (note_ptr)
		inc de
		ld (note_ptr), de; Increment the note pointer

		.db 0x01; LD BC,nn
		instrum_tbl:
		.dw 0x0000

		add hl, bc
		ld (current_inst), hl
		jp read_loop

		skip_ch1:
		.db 0xfd
		ld l, #0x01
		jp read_loop

		exit_player:
		ld hl, #0x2758
		exx
		pop iy
		             ;EI
		ret

		render:
		and #0x7F; L813A
		cp #0x76
		jp nc, drums
		ld d, a
		exx
		.db 0x21; LD HL,nn
		cnt_1a:	.dw 0x0000
		.db 0xDD,0x21; LD IX,nn
		cnt_1b:	.dw 0x0000
		.db 0x01; LD BC,nn
		div_1a:	.dw 0x0000
		.db 0x11; LD DE,nn
		div_1b:	.dw 0x0000
		.db 0x3E; LD A,n
		out_1:	.db 0x0
		exx
		ex af, af; beware!
		.db 0x21; LD HL,nn
		cnt_2:	.dw 0x0000
		.db 0x01; LD BC,nn
		div_2:	.dw 0x0000
		.db 0x3E; LD A,n
		out_2:	.db 0x00

		play_note:
		             ; Read keyboard
		ld e, a
		xor a
		in a, (#0xFE)
		or #0xE0
		inc a

		player_wait_key:
		jr nz, exit_player
		ld a, e
		ld e, #0

		l8168:	exx
		ex af, af; beware!
		add hl, bc
		out (#0xFE), a
		jr c, l8171
		jr l8173
		l8171:	xor #0x10
		l8173:	add ix, de
		jr c, l8179
		jr l817b
		l8179:	xor #0x10
		l817b:	ex af, af; beware!
		out (#0xFE), a
		exx
		add hl, bc
		jr c, l8184
		jr l8186
		l8184:	xor #0x10
		l8186:	nop
		jp l818a

		l818a:	exx
		ex af, af; beware!
		add hl, bc
		out (#0xFE), a
		jr c, l8193
		jr l8195
		l8193:	xor #0x10
		l8195:	add ix, de
		jr c, l819b
		jr l819d
		l819b:	xor #0x10
		l819d:	ex af, af; beware!
		out (#0xFE), a
		exx
		add hl, bc
		jr c, l81a6
		jr l81a8
		l81a6:	xor #0x10
		l81a8:	nop
		jp l81ac

		l81ac:	exx
		ex af, af; beware!
		add hl, bc
		out (#0xFE), a
		jr c, l81b5
		jr l81b7
		l81b5:	xor #0x10
		l81b7:	add ix, de
		jr c, l81bd
		jr l81bf
		l81bd:	xor #0x10
		l81bf:	ex af, af; beware!
		out (#0xFE), a
		exx
		add hl, bc
		jr c, l81c8
		jr l81ca
		l81c8:	xor #0x10
		l81ca:	nop
		jp l81ce

		l81ce:	exx
		ex af, af; beware!
		add hl, bc
		out (#0xFE), a
		jr c, l81d7
		jr l81d9
		l81d7:	xor #0x10
		l81d9:	add ix, de
		jr c, l81df
		jr l81e1
		l81df:	xor #0x10
		l81e1:	ex af, af; beware!
		out (#0xFE), a
		exx
		add hl, bc
		jr c, l81ea
		jr l81ec
		l81ea:	xor #0x10

		l81ec:	dec e
		jp nz, l8168

		exx
		ex af, af; beware!
		add hl, bc
		out (#0xFE), a
		jr c, l81f9
		jr l81fb
		l81f9:	xor #0x10
		l81fb:	add ix, de
		jr c, l8201
		jr l8203
		l8201:	xor #0x10
		l8203:	ex af, af; beware!
		out (#0xFE), a
		exx
		add hl, bc
		jr c, l820c
		jr l820e
		l820c:	xor #0x10

		l820e:	dec d
		jp nz, play_note

		ld (cnt_2), hl
		ld (out_2), a
		exx
		ex af, af; beware!
		ld (cnt_1a), hl
		ld (cnt_1b), ix
		ld (out_1), a
		jp main_loop

		; ************************************************************
		; * DRUMS - Synthesised
		; ************************************************************
		drums:
		add a, a; On entry A=$75+Drum number (i.e. $76 to $7E)
		ld b, #0
		ld c, a
		ld hl, #drum_table - 236
		add hl, bc
		ld e, (hl)
		inc hl
		ld d, (hl)
		ex de, hl
		jp (hl)

		drum_tone1:	ld l, #16
		jr drum_tone
		drum_tone2:	ld l, #12
		jr drum_tone
		drum_tone3:	ld l, #8
		jr drum_tone
		drum_tone4:	ld l, #6
		jr drum_tone
		drum_tone5:	ld l, #4
		jr drum_tone
		drum_tone6:	ld l, #2
		drum_tone:
		ld de, #3700
		ld bc, #0x0101
		             ;LD   A,BORDER_COL
		xor a
		dt_loop0:	out (#0xFE), a
		dec b
		jr nz, dt_loop1
		xor #16
		ld b, c
		ex af, af; beware!
		ld a, c
		add a, l
		ld c, a
		ex af, af; beware!
		dt_loop1:	dec e
		jr nz, dt_loop0
		dec d
		jr nz, dt_loop0
		jp main_loop

		drum_noise1:	ld de, #2480
		.db 0xdd
		ld l, #1
		jr drum_noise
		drum_noise2:	ld de, #1070
		.db 0xdd
		ld l, #10
		jr drum_noise
		drum_noise3:	ld de, #365
		.db 0xdd
		ld l, #101
		drum_noise:
		ld h, d
		ld l, e
		             ;LD   A,BORDER_COL
		xor a
		ld c, a
		dn_loop0:	ld a, (hl)
		and #16
		or c
		out (#0xFE), a
		.db 0xdd
		ld b, l
		dn_loop1:	djnz dn_loop1
		inc hl
		dec e
		jr nz, dn_loop0
		dec d
		jr nz, dn_loop0
		jp main_loop

		pattern_addr:	.dw 0x0000
		pattern_ptr:	.db 0
		note_ptr:	.dw 0x0000

		; **************************************************************
		; * Frequency Table
		; **************************************************************
		freq_table:
		.dw 178,189,200,212,225,238,252,267,283,300,318,337
		.dw 357,378,401,425,450,477,505,535,567,601,637,675
		.dw 715,757,802,850,901,954,1011,1071,1135,1202,1274,1350
		.dw 1430,1515,1605,1701,1802,1909,2023,2143,2270,2405,2548,2700
		.dw 2860,3030,3211,3402,3604,3818,4046,4286,4541,4811,5097,5400

		; *****************************************************************
		; * Synth Drum Lookup Table
		; *****************************************************************
		drum_table:
		.dw drum_tone1,drum_tone2,drum_tone3,drum_tone4,drum_tone5,drum_tone6
		.dw drum_noise1,drum_noise2,drum_noise3


		musicdata:
		.db 0; Pattern loop begin * 2
		.db 2; Song length * 2
		.dw 4; Offset to start of song (length of instrument table)
		.db 2; Multiple
		.dw 0; Detune
		.db 0; Phase

		PATTERNDATA:	.dw PAT0

		; *** Pattern data - $00 marks the end of a pattern ***
		PAT0:
		.db 0xBD,0
		.db 232
		.db 156
		.db 118
		.db 21
		.db 168
		.db 124
		.db 10
		.db 169
		.db 11
		.db 168
		.db 122
		.db 10
		.db 166
		.db 122
		.db 10
		.db 164
		.db 124
		.db 10
		.db 168
		.db 124
		.db 10
		.db 164
		.db 152
		.db 118
		.db 21
		.db 164
		.db 124
		.db 10
		.db 166
		.db 11
		.db 168
		.db 122
		.db 10
		.db 166
		.db 123
		.db 10
		.db 164
		.db 124
		.db 10
		.db 163
		.db 118
		.db 10
		.db 161
		.db 154
		.db 118
		.db 21
		.db 166
		.db 124
		.db 10
		.db 164
		.db 11
		.db 163
		.db 123
		.db 10
		.db 161
		.db 11
		.db 163
		.db 125
		.db 10
		.db 159
		.db 11
		.db 156
		.db 151
		.db 118
		.db 21
		.db 156
		.db 125
		.db 10
		.db 159
		.db 125
		.db 10
		.db 163
		.db 122
		.db 10
		.db 164
		.db 124
		.db 10
		.db 163
		.db 124
		.db 10
		.db 159
		.db 11
		.db 168
		.db 156
		.db 118
		.db 21
		.db 171
		.db 124
		.db 10
		.db 169
		.db 124
		.db 10
		.db 168
		.db 123
		.db 10
		.db 166
		.db 124
		.db 10
		.db 164
		.db 124
		.db 10
		.db 168
		.db 124
		.db 10
		.db 171
		.db 152
		.db 118
		.db 21
		.db 171
		.db 124
		.db 10
		.db 173
		.db 124
		.db 10
		.db 176
		.db 122
		.db 10
		.db 171
		.db 124
		.db 10
		.db 176
		.db 125
		.db 10
		.db 180
		.db 124
		.db 10
		.db 178
		.db 154
		.db 118
		.db 21
		.db 178
		.db 124
		.db 10
		.db 173
		.db 11
		.db 175
		.db 123
		.db 10
		.db 176
		.db 11
		.db 178
		.db 125
		.db 10
		.db 180
		.db 125
		.db 10
		.db 180
		.db 151
		.db 118
		.db 21
		.db 178
		.db 124
		.db 10
		.db 176
		.db 124
		.db 10
		.db 181
		.db 118
		.db 10
		.db 180
		.db 124
		.db 10
		.db 178
		.db 124
		.db 10
		.db 175
		.db 123
		.db 10
		.db 0x00

	__endasm;
}
