;
; void ListInsert(LIST *list, void *item, uchar nodeQueue)
; Alvin Albrecht 02.2003
;

	.module SPListInsert
	.globl SPListInsert
	.globl SPListAdd
	.globl SPListPrev

; enter: de = LIST *
;        bc = item *
;        hl = address of new sp_ListNode container
; exit : new item inserted before current, current points at new item
; uses : af, bc, de, hl

SPListInsert:
	push de
	push bc
	push hl
	call SPListPrev; move current pointer to previous item   
	pop hl
	pop bc
	pop de
	jp SPListAdd
