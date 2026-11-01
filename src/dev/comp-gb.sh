#!/bin/bash
# Compila el güego para Game Boy (DMG, cartucho MBC1). Equivalente Linux de
# comp-gb.bat.
# Uso: ./comp-gb.sh [justcompile] [noclean]
# Requiere GBDK-2020: GBDK_HOME apuntando a donde esté instalado.
#
#  * Convierte el mapa, los enemigos y los gráficos de ../gfx/gb (mkts_om
#    platform=gb). Un juego puede traer en su game.sh una convert_assets_gb
#    propia.
#  * Reparte los recursos de librarian_gb.txt (o los de bootee) en bancos de
#    ROM desde el 3 con librarian platform=gb, que genera librarian.h y un
#    res_bankN.s por banco.
#  * Compila: el banco 0 (gb/home.c, gb/zx0.s, gb/vram.s) y el motor
#    (gb/churromain.c, banco 1).
#  * Enlaza con lcc (MBC1), comprueba con gbcheck que los bancos y la RAM
#    no se desbordan y deja $game.gb.

# Cambia "game" por el nombre de tu güego.
game=bootee

cd "$(dirname "$0")"
: "${GBDK_HOME:?Pon en GBDK_HOME la carpeta de GBDK-2020}"
U=../utils/linux
LCC="$GBDK_HOME/bin/lcc"

[ -f game.sh ] && . ./game.sh

justcompile=0; noclean=0
for a in "$@"; do
	[ "$a" = "justcompile" ] && justcompile=1
	[ "$a" = "noclean" ] && noclean=1
done

z () { rm -f $2; $U/zx0 $1 $2 > /dev/null; }

if [ $justcompile = 0 ]; then
	echo "### CONVIRTIENDO COSAS QUE HAY QUE CONVERTIR ###"
	if type convert_assets_gb > /dev/null 2>&1; then
		convert_assets_gb || { echo "ERROR convirtiendo"; exit 1; }
	else
		$U/mapcnv ../map/mapa.map mapa.h 6 5 15 10 15 packed > /dev/null
		$U/ene2h ../enems/enems.ene enems.h 2bytes > /dev/null

		G="platform=gb silent"
		# Lo que sale de mkts_om va a X_raw.bin y comprimido a X.bin (el recurso)
		$U/mkts_om $G mode=chars in=../gfx/gb/font.png out=font_raw.bin max=64 > /dev/null || exit 1
		$U/mkts_om $G mode=strait2x2 in=../gfx/gb/work.png out=tileset_raw.bin max=48 > /dev/null || exit 1
		$U/mkts_om $G mode=sprites in=../gfx/gb/sprites.png out=sprites_raw.bin max=32 > /dev/null || exit 1
		for s in title ending; do
			$U/mkts_om $G mode=scr in=../gfx/gb/$s.png out=${s}_raw.bin > /dev/null || exit 1
		done
		for s in font tileset sprites title ending; do z ${s}_raw.bin $s.bin; done
	fi
fi

echo "### RECURSOS EN BANCOS DE ROM ###"
if [ -f librarian_gb.txt ]; then lst=librarian_gb.txt; else
	lst=librarian_gb.default.txt; printf "font.bin\ntileset.bin\nsprites.bin\ntitle.bin\nending.bin\n" > $lst
fi
rm -f res_bank*.s
$U/librarian platform=gb list=$lst out=librarian.h firstbank=3 || exit 1

echo "### COMPILANDO GUEGO ###"
# Banco 0: gb/home.c, gb/zx0.s, gb/vram.s y GBDK. Banco 1: el motor
# (gb/churromain.c), que está siempre puesto.
F="-msm83:gb -I. -Wf--opt-code-speed"
mkdir -p obj_gb
rm -f obj_gb/*.o
"$LCC" $F -c -o obj_gb/home.o gb/home.c || { echo "ERROR en gb/home.c"; exit 1; }
"$LCC" $F -DGB -Wf-bo1 -c -o obj_gb/churromain.o gb/churromain.c || { echo "ERROR en el motor"; exit 1; }
for s in zx0 vram; do "$LCC" $F -c -o obj_gb/$s.o gb/$s.s || exit 1; done
for r in res_bank*.s; do "$LCC" $F -c -o obj_gb/${r%.s}.o $r || exit 1; done

# MBC1 (-yt 0x01), los bancos que hagan falta (-yoA)
"$LCC" $F -Wl-yt0x01 -Wm-yoA -Wm-yn"$(echo $game | tr a-z A-Z | cut -c1-15)" -Wl-m -Wl-j -o obj_gb/$game.gb obj_gb/*.o || { echo "ERROR enlazando"; exit 1; }
cp obj_gb/$game.gb .
# ¿Cabe todo? (bancos de ROM y los 8K de RAM con la pila)
$U/gbcheck obj_gb/$game.map || exit 1

if [ $noclean = 0 ]; then
	echo "### LIMPIANDO ###"
	rm -rf obj_gb res_bank*.s *_raw.bin font.bin tileset.bin sprites.bin title.bin ending.bin librarian.h librarian_gb.default.txt
fi
echo "### DONE ###"
