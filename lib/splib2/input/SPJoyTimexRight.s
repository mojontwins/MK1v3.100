;
; JoyTimexRight
; Alvin Albrecht 2002
;
; Reads right TS2068 joystick.
;

	.module SPJoyTimexRight
	.globl SPJoyTimexRight
	.globl SPtmxsetup

; JoyTimex1
;
; Reads left side joystick on TS2068.
; You must make sure the relevant hardware is present
; or you may get false readings.
;
; exit:   a = F111RLDU active low
; uses:   af

SPJoyTimexRight:
	di; can't allow writes to AY during an isr
	call SPtmxsetup
	ld a, #1; right joystick
	in a, (#0xf6); FXXXRLDU active low
	or #0x70
	ei
	ret
