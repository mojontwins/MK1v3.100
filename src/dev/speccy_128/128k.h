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
// [v3.100] Eliminado el bloque MOVE_STUFF_TO_RAM_6, que estaba comentado y sin terminar.
