;
; JoyFuller
; Alvin Albrecht 2002
;
; Reads Fuller Box joystick.
;

	.module SPJoyFuller
	.globl SPJoyFuller

; JoyFuller
;
; Reads Fuller Box joystick.
; You must make sure the relevant hardware is present
; or you may get false readings.
;
; exit:   a = F111RLDU active low
; uses:   af

SPJoyFuller:
	in a, (#0x7f); FXXXRLDU active low
	or #0x70
	ret
