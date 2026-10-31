
;
;      Sprite Pack V2.0
;
;      Spectrum and Timex Computers Game Engine
;      Visit http://justme895.tripod.com/main.htm
;
;      Alvin Albrecht 01.2003
;

	.module sp_fixcliprect
	.globl sp_fixcliprect

; Converts a sp_Rect pointed at by de into a ClipStruct point at by iy,
; the latter is expected by the assembly API.

sp_fixcliprect:
	ld a, (de)
	ld 0(iy), a
	inc de
	ld a, (de)
	ld 2(iy), a
	inc de
	ld a, (de)
	add a, 0(iy)
	ld 1(iy), a
	inc de
	ld a, (de)
	add a, 2(iy)
	ld 3(iy), a
	ret

