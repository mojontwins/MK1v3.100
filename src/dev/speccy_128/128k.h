// La Churrera Engine 3.100
// Copyleft 2010-2014 the Mojon Twins

// 128K stuff

// SetRAMBank: pone en 0xC000 la página de RAM que diga B. Se llama desde
// ensamblador (call SetRAMBank).
void set_ram_bank (void) __naked {
	__asm
	SetRAMBank::
		ld a, #16
		or b
		ld bc, #0x7ffd
		out (c), a
		ret
	__endasm;
}

// Copia ram_copy_len bytes de address (en la página de RAM ram_page) a
// destination, que tiene que estar por debajo de 0xC000. Lo usan los textos
// de los scripts cuando van como recurso (MSC_TEXTS_RES).
unsigned int ram_copy_len;
void copy_from_RAMn (void) __naked {
	__asm
		di
		ld a, (_ram_page)
		ld b, a
		call SetRAMBank
		ld hl, (_address)
		ld de, (_destination)
		ld bc, (_ram_copy_len)
		ldir
		ld b, #0
		call SetRAMBank
		ei
		ret
	__endasm;
}
