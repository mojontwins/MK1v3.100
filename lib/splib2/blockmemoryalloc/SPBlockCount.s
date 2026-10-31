;
; Dynamic Block Memory Allocator
; Alvin Albrecht 03.2003
;
; Comprised of:
;   InitAlloc, AddMemory, BlockFit, BlockAlloc, BlockCount, FreeBlock
;
; Symbol "NUMQUEUES", indicating number of memory queues,
; needs to be defined externally prior to compilation.
;


	.module SPBlockCount
	.globl SPBlockCount
	.globl SPqueuetable

; BlockCount
;
; Enter:  A     = Queue #
; Exit :  BC    = Number of Available Blocks in Queue
; Uses :  AF, BC, HL, DE
;

SPBlockCount:
	ld bc, #0
	add a, a
	add a, #<SPqueuetable
	ld l, a
	ld h, #>SPqueuetable
	jp nc, loop
	inc h

loop:
	ld e, (hl)
	inc hl
	ld d, (hl)
	ld a, d
	or e
	ret z
	inc bc
	ex de, hl
	jp loop
