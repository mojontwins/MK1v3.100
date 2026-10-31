;
; uint ListCount(LIST *list)
; Alvin Albrecht 02.2003
;

	.module SPListCount
	.globl SPListCount

; enter: hl = LIST *
; exit : de = # items in list
; uses : af, de

SPListCount:
	ld e, (hl)
	inc hl
	ld d, (hl)
	dec hl
	ret
