// La Churrera Engine 3.100
// Copyleft 2010-2014 the Mojon Twins

// Beeper.h
// Rutinas de sonido para beeper por Shiru
// I removed di's and ei's, not needed here.
// Copyleft 2010 The Mojon Twins

void beeper_code (void) __naked {
	__asm
		playsfx:
		;di
		ld l, a
		ld h, #0
		add hl, hl
		ld de, #proclist
		add hl, de
		ld a, (hl)
		inc hl
		ld h, (hl)
		ld l, a
		ld de, #0
		jp (hl)

		sound1:;enemy destroyed
		ex de, hl
		ld bc, #500
		sound1l0:
		ld a, (hl)
		and #16
		out (#0xFE), a
		ld e, a
		inc a
		sla a
		sla a
		sound1l1:
		dec a
		jr nz, sound1l1
		out (#0xFE), a
		ld a, e
		inc a
		add a, a
		add a, a
		add a, a
		sound1l2:
		dec a
		jr nz, sound1l2
		ld a, b
		inc hl
		dec bc
		ld a, b
		or c
		jr nz, sound1l0
		;ei
		ret

		sound2:;enemy hit
		ex de, hl
		ld bc, #40*256+100
		sound2l0:
		ld a, (hl)
		and #16
		out (#0xFE), a
		inc hl
		ld a, c
		sound2l1:
		dec a
		jr nz, sound2l1
		out (#0xFE), a
		ld a, c
		sound2l2:
		dec a
		jr nz, sound2l2
		djnz sound2l0
		;ei
		ret

		sound3:;something
		ex de, hl
		ld b, #100
		ld de, #0x1020
		sound3l0:
		ld a, (hl)
		and d
		out (#0xFE), a
		inc hl
		ld a, e
		sound3l0a:
		dec a
		jr nz, sound3l0a
		djnz sound3l0
		ld b, #250
		sound3l1:
		ld a, (hl)
		and d
		out (#0xFE), a
		inc hl
		ld a, #2
		sound3l2:
		dec a
		jr nz, sound3l2
		xor a
		out (#0xFE), a
		ld a, e
		sound3l3:
		dec a
		jr nz, sound3l3
		djnz sound3l1
		;ei
		ret

		sound4:;jump
		ld bc, #20*256+250
		sound4l0:
		ld a, #16
		out (#0xFE), a
		ld a, #4
		sound4l1:
		dec a
		jr nz, sound4l1
		out (#0xFE), a
		ld a, c
		sound4l2:
		dec a
		jr nz, sound4l2
		dec c
		dec c
		djnz sound4l0
		;ei
		ret

		sound5:;player hit
		ex de, hl
		ld bc, #100*256+16
		sound5l0:
		ld a, (hl)
		and c
		out (#0xFE), a
		inc hl
		ld a, #110
		sub b
		ld e, a
		and c
		out (#0xFE), a
		sound5l1:
		dec e
		jr nz, sound5l1
		djnz sound5l0
		;ei
		ret

		sound6:;enemy destroyed 2
		ex de, hl
		ld bc, #20*256+16
		sound6l0:
		ld a, (hl)
		inc hl
		and c
		out (#0xFE), a
		xor a
		sound6l0a:
		dec a
		jr nz, sound6l0a
		djnz sound6l0
		sound6l1:
		ld a, (hl)
		inc hl
		and c
		out (#0xFE), a
		sound6l2:
		dec a
		jr nz, sound6l2
		djnz sound6l1
		;ei
		ret

		sound7:;shot
		ex de, hl
		ld bc, #100*256
		sound7l0:
		ld a, (hl)
		inc hl
		or c
		and #16
		out (#0xFE), a
		ld a, (hl)
		srl a
		srl a
		sound7l1:
		dec a
		jr nz, sound7l1
		ld a, c
		add a, #4
		ld c, a
		djnz sound7l0
		;ei
		ret

		sound8:;take item
		ld a, #200
		jr soundItem
		sound9:
		ld a, #175
		jr soundItem
		sound10:
		ld a, #100
		soundItem:
		ld (frq), a
		ld b, #4
		ld d, #128
		sound8l2:
		push bc
		;.frq=$+1
		;	ld bc,2*256+200
		.db #01;ld bc
		frq:
		.db 200;+200
		.db 2;2*256
		sound8l0:
		push bc
		ld b, #50
		sound8l1:
		xor #16
		and #16
		out (#0xFE), a
		ld e, a
		ld a, d
		sound8l2b:
		dec a
		jr nz, sound8l2b
		out (#0xFE), a
		ld a, #129
		sub d
		sound8l3:
		dec a
		jr nz, sound8l3
		ld a, e
		ld e, c
		sound8l4:
		dec e
		jr nz, sound8l4
		djnz sound8l1
		pop bc
		ld a, c
		sub #16
		ld c, a
		djnz sound8l0
		pop bc
		srl d
		srl d
		djnz sound8l2
		;ei
		ret

		proclist:
		.dw sound1; 0 Enemy destroyed
		.dw sound2; 1 Enemy Hit
		.dw sound3; 2 Something
		.dw sound4; 3 Jump
		.dw sound5; 4 Player hit
		.dw sound6; 5 Enemy destroyed 2
		.dw sound7; 6 Shot
		.dw sound8; 7 Item 1
		.dw sound9; 8 Item 2
		.dw sound10; 9 Item 3
		.dw sound4; 10 Puncho
		.dw sound8; 11 Coin
		.dw sound3; 12 Talk 1
		.dw sound7; 13 Talk 2
		.dw sound3; 14 Key in lock
	__endasm;
}

/*
	TABLA DE SONIDOS

	n	Sonido
	----------
	0	Enemy destroyed
	1	Enemy hit
	2	Something
	3	Jump
	4	Player hit
	5	Enemy destroyed 2
	6	Shot
	7	Item #1		(item)
	8	Item #2		(key)
	9	Item #3		(life)
	10 Puncho
	11 Coin
	12 Talk1
	13 Talk2
	14 Lock
*/

// Los efectos de beeper se tocan con las interrupciones deshabilitadas: la
// ISR rompería la temporización del sonido.
// El efecto llega en A (convención de SDCC para un argumento de 8 bits).
void peta_el_beeper (unsigned char n) __naked {
	(void) n;
	__asm
		di
		call playsfx
		ei
		ret
	__endasm;
}
