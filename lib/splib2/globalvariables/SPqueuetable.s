;
; Dynamic Block Memory Allocator
; Alvin Albrecht 2002
;
; Comprised of:
;   InitAlloc, AddMemory, BlockFit, BlockAlloc, FreeBlock
;
; Symbol "NUMQUEUES", indicating number of memory queues,
; needs to be defined externally prior to compilation.
;

	.include "SPconfig.inc"
	.module SPqueuetable
	; Variables: van en _DATA (no ocupan sitio en el binario; crt0 las pone a 0)
	.area _DATA
	.globl SPqueuetable

; Table holds one 2-byte entry per queue.  This is a pointer to
; a linked list of available memory queues.  It is zero if none
; are available.

SPqueuetable:
	.ds NUMQUEUES * 2
