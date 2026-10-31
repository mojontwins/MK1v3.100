#!/bin/bash
# Equivalente Linux de comp-cpc.bat
# Uso: ./comp-cpc.sh [justcompile] [noclean]
# Requiere GBDK-2020 (su SDCC): GBDK_HOME apuntando a donde esté instalado.

# Cambia "game" por el nombre de tu güego.
game=bootee
mode=0

cd "$(dirname "$0")"
: "${GBDK_HOME:?Pon en GBDK_HOME la carpeta de GBDK-2020}"
U=../utils/linux
P="platform=cpc cpcmode=$mode pal=../gfx/cpc/pal.png"

justcompile=0; noclean=0
for a in "$@"; do
	[ "$a" = "justcompile" ] && justcompile=1
	[ "$a" = "noclean" ] && noclean=1
done

if [ $justcompile = 0 ]; then
	echo "### CONVIRTIENDO COSAS QUE HAY QUE CONVERTIR ###"
	$U/mapcnv ../map/mapa.map mapa.h 6 5 15 10 15 packed > /dev/null
	$U/ene2h ../enems/enems.ene enems.h 2bytes > /dev/null

	$U/mkts_om $P mode=chars greyordered in=../gfx/cpc/font.png out=font.bin silent > /dev/null
	$U/mkts_om $P mode=strait2x2 greyordered in=../gfx/cpc/work.png out=work.bin silent > /dev/null
	$U/mkts_om $P mode=sprites in=../gfx/cpc/sprites.png out=sprites.bin max=16 silent > /dev/null
	$U/mkts_om $P mode=sprites in=../gfx/cpc/sprites_extra.png out=sprites_extra.bin max=2 silent > /dev/null
	$U/mkts_om $P mode=sprites in=../gfx/cpc/sprites_bullet.png out=sprites_bullet.bin metasize=1,1 max=1 silent > /dev/null
	$U/mkts_om $P mode=sprites in=../gfx/cpc/sprites_sword.png out=sprites_sword.bin metasize=1,1 max=4 silent > /dev/null
	$U/mkts_om platform=cpc mode=pals in=../gfx/cpc/pal.png prefix=my_inks out=cpc/pal.h silent > /dev/null

	for s in marco ending title; do
		$U/mkts_om $P mode=superbuffer in=../gfx/cpc/$s.png out=$s.scr silent > /dev/null
	done
	for s in title marco ending; do
		rm -f $s.bin; $U/zx0 $s.scr.bin $s.bin > /dev/null
	done
fi

if grep -qE '^[[:space:]]*#define[[:space:]]+ACTIVATE_SCRIPTING\b' config.h; then
	echo "### COMPILANDO SCRIPT ###"
	# Todos los scripts del juego juntos (uno por nivel, si hay niveles): un
	# solo msc-config.h para el intérprete (msc.h) y un .bin por script.
	# rooms= es el valor por defecto; cada script puede poner ROOMS = n.
	scripts=../script/script.spt
	[ -f scripts.txt ] && scripts=$(grep -v '^#' scripts.txt | tr '\n' ',' | sed 's/,*$//')
	mw=$(grep -E '^#define[[:space:]]+MAP_W\b' config.h | awk '{print $3}')
	mh=$(grep -E '^#define[[:space:]]+MAP_H\b' config.h | awk '{print $3}')
	$U/msc4 in=$scripts v=3_100 output=c rooms=$((mw * mh)) > msc4.log || { cat msc4.log; echo "ERROR en el script"; exit 1; }
	grep -iE "warning" msc4.log; grep -iE "error|wrong|unexpected|unknown|expecting|too long" msc4.log && { echo "ERROR en el script"; exit 1; }
fi

echo "### COMPILANDO GUEGO ###"
$U/pasmo cpc/cpc_TrPixLutM$mode.asm trpixlut.bin
rm -f trpixlutc.bin; $U/zx0 trpixlut.bin trpixlutc.bin > /dev/null
# Instrumentos del WYZ player (de la exportación de WYZ Tracker)
$U/wyzTrackerParser ../ogt/instrumentos.asm instrumentos.s > /dev/null || exit 1

# SDCC compila todo el motor de una vez (churromain.c incluye el resto); el
# WYZ player, sus efectos y los instrumentos son módulos aparte. El programa
# empieza en 0x400 con crt0 y sus variables van detrás del código. ihx2bin
# saca el binario y comprueba el mapa de memoria con el .map.
G="$GBDK_HOME/bin"
"$G/sdcc" -mz80 --no-std-crt0 -I. -DCPC -DMODE_$mode -c churromain.c || { echo "ERROR"; exit 1; }
for s in cpc/crt0 cpc/wyz_player cpc/efectos instrumentos; do
	"$G/sdasz80" -g -o $(basename $s).rel $s.s || { echo "ERROR"; exit 1; }
done
"$G/sdldz80" -n -m -w -i -b _CODE=0x400 $game.ihx crt0.rel churromain.rel wyz_player.rel efectos.rel instrumentos.rel \
	-k cpc -l cpcrslib.lib -k "$GBDK_HOME/lib/z80" -l z80.lib || { echo "ERROR"; exit 1; }
$U/ihx2bin $game.ihx $game.bin 0x400 $game.map || exit 1

echo "### CONSTRUYENDO SNA Y CDT ###"
rm -f $game.sna
$U/cpctbin2sna $game.bin 0x400 -pc 0x400 -o $game.sna
echo "Output: $game.sna"

$U/mkts_om platform=cpc cpcmode=$mode pal=../gfx/cpc/pal_loading.png mode=scr in=../gfx/cpc/loading.png out=loading.bin silent > /dev/null
rm -f loading.c.bin $game.c.bin
$U/zx7 loading.bin loading.c.bin > /dev/null
$U/zx7 $game.bin $game.c.bin > /dev/null

$U/imanol in=cpc/loadercpc.asm-orig out=cpc/loadercpc.asm \
	scrc_size=?loading.c.bin \
	mainbin_size=?$game.c.bin \
	loading_palette=!../gfx/cpc/pal_loading.png \
	loader_mode=0 > /dev/null
$U/pasmo cpc/loadercpc.asm loader.bin > /dev/null

$U/imanol in=cpc/preloadercpc.asm-orig out=cpc/preloadercpc.asm \
	loader_size=?loader.bin \
	loader_mode=0 > /dev/null
$U/pasmo cpc/preloadercpc.asm preloader.bin > /dev/null

rm -f $game.cdt
$U/cpc2cdt -r $game -m cpc -l 1024 -x 1024 -p 2000 preloader.bin $game.cdt > /dev/null
$U/cpc2cdt -r LOADER -m raw1full -rl 740 -p 2000 loader.bin $game.cdt > /dev/null
$U/cpc2cdt -r SCR -m raw1full -rl 740 -p 2000 loading.c.bin $game.cdt > /dev/null
$U/cpc2cdt -r MAIN -m raw1full -rl 740 -p 2000 $game.c.bin $game.cdt > /dev/null
echo "Output: $game.cdt"

if [ $noclean = 0 ]; then
	echo "### LIMPIANDO ###"
	rm -f *.scr *.bin *.rel *.ihx *.asm *.lst *.sym instrumentos.s
fi

echo "### DONE ###"
