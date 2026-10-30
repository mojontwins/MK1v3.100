#!/bin/bash
# Equivalente Linux de comp-zx.bat
# Uso: ./comp-zx.sh [justcompile] [noclean]
# Requiere z88dk 1.10 en el PATH (source z88env.sh, ver env/setup-linux.sh)

# Cambia "game" por el nombre de tu güego.
game=bootee

cd "$(dirname "$0")"
U=../utils/linux

justcompile=0; noclean=0
for a in "$@"; do
	[ "$a" = "justcompile" ] && justcompile=1
	[ "$a" = "noclean" ] && noclean=1
done

if [ $justcompile = 0 ]; then
	echo "### CONVIRTIENDO COSAS QUE HAY QUE CONVERTIR ###"
	$U/mapcnv ../map/mapa.map mapa.h 6 5 15 10 15 packed > /dev/null
	$U/ene2h ../enems/enems.ene enems.h 2bytes > /dev/null

	$U/ts2bin ../gfx/speccy/font.png ../gfx/speccy/work.png ts.bin 7 > /dev/null
	$U/sprcnv ../gfx/speccy/sprites.png speccy/sprites.h > /dev/null
	for s in title marco ending loading; do
		$U/png2scr ../gfx/speccy/$s.png $s.scr > /dev/null
	done
	for s in title marco ending; do
		rm -f $s.bin; $U/zx0 $s.scr $s.bin > /dev/null
	done
fi

echo "### COMPILANDO SCRIPT ###"
# no olvides cambiar NPANT por el nº de pantallas
# $U/msc ../script/script.spt msc.h 30

echo "### COMPILANDO GUEGO ###"
rm -f zcc_opt.def
zcc +zx -a -vn churromain.c -o $game.asm -lsplib2 -zorg=24200 > /dev/null 2>&1
rm -f zcc_opt.def
if ! zcc +zx -m -vn churromain.c -o $game.bin -lsplib2 -zorg=24200; then
	echo "ERROR"; exit 1
fi
$U/printsize $game.bin

echo "### CONSTRUYENDO CINTA ###"
# cambia BOOTEE por el nombre que quieres que salga en Program:
$U/bas2tap -a10 -sBOOTEE speccy/loader.bas loader.tap > /dev/null
$U/bin2tap -o screen.tap -a 16384 loading.scr
$U/bin2tap -o main.tap -a 24200 $game.bin
cat loader.tap screen.tap main.tap > $game.tap

if [ $noclean = 0 ]; then
	echo "### LIMPIANDO ###"
	rm -f loader.tap screen.tap main.tap *.scr *.bin zcc_opt.def
fi

echo "### DONE ###"
