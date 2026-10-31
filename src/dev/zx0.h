// La Churrera Engine 3.100
// Copyleft 2010-2013, 2020-2025 by The Mojon Twins

// zx0.h
// Cointains the ZX0 decompressor.

void zx0_depack (void) __naked {
	__asm
		; -----------------------------------------------------------------------------
		; ZX0 decoder by Einar Saukas & Urusergi
		; "Standard" version (68 bytes only)
		; -----------------------------------------------------------------------------
		; .Parameters
		;   .HL source address (compressed data)
		;   .DE destination address (decompressing)
		; -----------------------------------------------------------------------------
		depack::
		dzx0_standard:
		ld bc, #0xffff; preserve default offset 1
		push bc
		inc bc
		ld a, #0x80
		dzx0s_literals:
		call dzx0s_elias; obtain length
		ldir; copy literals
		add a, a; copy from last offset or new offset?
		jr c, dzx0s_new_offset
		call dzx0s_elias; obtain length
		dzx0s_copy:
		ex (sp), hl; preserve source, restore offset
		push hl; preserve offset
		add hl, de; calculate destination - offset
		ldir; copy from offset
		pop hl; restore offset
		ex (sp), hl; preserve offset, restore source
		add a, a; copy from literals or new offset?
		jr nc, dzx0s_literals
		dzx0s_new_offset:
		pop bc; discard last offset
		ld c, #0xfe; prepare negative offset
		call dzx0s_elias_loop; obtain offset MSB
		inc c
		ret z; check end marker
		ld b, c
		ld c, (hl); obtain offset LSB
		inc hl
		rr b; last offset bit becomes first length bit
		rr c
		push bc; preserve new offset
		ld bc, #1; obtain length
		call nc, dzx0s_elias_backtrack
		inc bc
		jr dzx0s_copy
		dzx0s_elias:
		inc c; interlaced Elias gamma coding
		dzx0s_elias_loop:
		add a, a
		jr nz, dzx0s_elias_skip
		ld a, (hl); load another group of 8 bits
		inc hl
		rla
		dzx0s_elias_skip:
		ret c
		dzx0s_elias_backtrack:
		add a, a
		rl c
		rl b
		jr dzx0s_elias_loop
		; -----------------------------------------------------------------------------
	__endasm;
}

#ifdef MODE_128K
	// Descomprime src (en la página de RAM n) a dest. Las direcciones van en
	// address y destination porque la página se cambia por debajo de la pila.
	void unpack_ram_do (void) __naked {
		__asm
			di
			ld a, (_ram_page)
			ld b, a
			call SetRAMBank
			ld hl, (_address)
			ld de, (_destination)
			call depack
			ld b, #0
			call SetRAMBank
			ei
			ret
		__endasm;
	}

	void unpack_RAMn (unsigned char n, unsigned char *src, unsigned char *dest) {
		address = src;
		destination = dest;
		ram_page = n;
		unpack_ram_do ();
	}
#endif

// Descomprime de src a dest (los dos en la RAM visible). SDCC pasa src en HL
// y dest en DE, que es lo que espera depack. src = 0 no hace nada.
void unpack (const unsigned char *src, unsigned char *dest) __naked {
	(void) src; (void) dest;
	__asm
		ld a, h
		or l
		ret z
		jp depack
	__endasm;
}
