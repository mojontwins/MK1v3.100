
	.module SPtmxsetup
	.globl SPtmxsetup

SPtmxsetup:
	ld a, #7
	out (#0xf5), a; select R7 on AY chip
	in a, (#0xf6); read R7
	and #0xbf; bit 6 = 0 selects i/o port A read
	out (#0xf6), a
	ld a, #14
	out (#0xf5), a; select R14, attached to i/o port A
	ret
