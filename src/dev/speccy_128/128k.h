// La Churrera Engine 3.100
// Copyleft 2010-2014 the Mojon Twins

// 128K stuff

void SetRAMBank(void) {
#asm
	.SetRAMBank
			ld	a, 16
			or	b
			ld	bc, $7ffd
			out (C), a
#endasm
}
