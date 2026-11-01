#!/bin/bash
# Compila el güego para Game Boy (DMG, cartucho MBC1). Equivalente Linux de
# comp-gb.bat.
# Uso: ./comp-gb.sh [justcompile] [noclean]
# Requiere GBDK-2020: GBDK_HOME apuntando a donde esté instalado.
#
#  * Convierte el mapa, los enemigos y los gráficos de ../gfx/gb (mkts_om
#    platform=gb). Un juego puede traer en su game.sh una convert_assets_gb
#    propia.
#  * Con scripting, compila los scripts (msc4, con los textos en líneas de
#    GB_TEXT_WIDTH caracteres) y, si el juego trae levels_gb.sh, construye
#    sus niveles.
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
		# (mkts_om avisa si una pantalla tiene más de 192 patrones)
		for s in title ending; do
			$U/mkts_om $G mode=scr in=../gfx/gb/$s.png out=${s}_raw.bin > mkts.log || exit 1
			grep -i warning mkts.log
		done
		for s in font tileset sprites title ending; do z ${s}_raw.bin $s.bin; done
	fi
fi

if grep -qE '^[[:space:]]*#define[[:space:]]+ACTIVATE_SCRIPTING\b' config.h; then
	echo "### COMPILANDO SCRIPT ###"
	# Como en comp-zx.sh, pero con los textos partidos en líneas de
	# GB_TEXT_WIDTH caracteres (18 si config.h no dice otra cosa): la
	# pantalla del Game Boy tiene 20 de ancho.
	scripts=../script/script.spt
	[ -f scripts.txt ] && scripts=$(grep -v '^#' scripts.txt | tr '\n' ',' | sed 's/,*$//')
	mw=$(grep -E '^#define[[:space:]]+MAP_W\b' config.h | awk '{print $3}')
	mh=$(grep -E '^#define[[:space:]]+MAP_H\b' config.h | awk '{print $3}')
	tw=$(grep -E '^#define[[:space:]]+GB_TEXT_WIDTH\b' config.h | awk '{print $3}')
	textres=""; grep -qE '^[[:space:]]*#define[[:space:]]+SCRIPT_TEXTS_AS_RESOURCE\b' config.h && textres=textres
	$U/msc4 in=$scripts v=3_100 output=c rooms=$((mw * mh)) textwidth=${tw:-18} $textres > msc4.log || { cat msc4.log; echo "ERROR en el script"; exit 1; }
	grep -iE "warning" msc4.log; grep -iE "error|wrong|unexpected|unknown|expecting|too long" msc4.log && { echo "ERROR en el script"; exit 1; }
fi

# Paso propio del juego para construir sus niveles y sus gráficos de Game
# Boy (bundles, tilesets, spritesets, scripts, pantallas). Ver
# docs/formato-niveles.md. Se ejecuta antes de librarian.
if [ $justcompile = 0 ] && [ -x ./levels_gb.sh ]; then
	echo "### CONSTRUYENDO NIVELES ###"
	./levels_gb.sh || { echo "ERROR en levels_gb.sh"; exit 1; }
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
	rm -rf obj_gb res_bank*.s *_raw.bin *.bin librarian.h librarian_gb.default.txt msc4.log mkts.log
fi
echo "### DONE ###"
