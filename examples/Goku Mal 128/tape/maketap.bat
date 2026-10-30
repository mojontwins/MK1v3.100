@echo off
..\utils\pasmo loader.asm loader.bin
..\utils\GenTape gokumal.tap			^
	basic 'Goku_Mal' 10	loader.bin		^
	data				loading.bin		^
	data				ram1.bin		^
	data				ram3.bin		^
	data				ram4.bin		^
	data				ram6.bin		^
	data				gokumal.bin
