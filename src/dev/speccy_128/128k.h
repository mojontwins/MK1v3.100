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
