#!/bin/bash
# levels.sh de Ninjajar: construye los niveles, los tilesets, los spritesets,
# los scripts y las pantallas. Lo llama comp-zx.sh (después de msc4 y antes
# de librarian). Ver docs/formato-niveles.md.
#
# Los niveles van por mapa (0..9, A..F, X, Y, Z, como en el original); la
# tabla de levelset.h dice en qué orden se juegan y qué gráficos usa cada
# uno. Los tilesets no llevan la fuente (LEVEL_TILESETS_NO_FONT): se cargan
# encima de los tiles del tileset base.
set -e
U=../utils/linux
z () { rm -f $2; $U/zx0 $1 $2 > /dev/null; }

# mapa scr_ini ini_x ini_y ancho alto max_objs vida behs motor (0 salto,
# 1 nado) mira (0 derecha, 1 izquierda)
build () {
	m=$1
	$U/buildlevel map=../map/mapa$m.map ene=../enems/enems$m.ene behs=../levels/behs$9.txt \
		out=level$m.bin maxpant=21 scr_ini=$2 ini_x=$3 ini_y=$4 mapw=$5 maph=$6 \
		max_objs=$7 life=$8 engine=${10} facing=${11} lock=99 > /dev/null
	z level$m.bin level${m}c.bin
}

build 5  8  7 7  7  3 99  1 5  0 1		# Intro
build 0  0  2 2  1 12  1  1 0  0 0		# Montaña
build 2  9 12 2 10  1  1  1 2  1 1		# Lago verde (nadando)
build 4  0  3 2 12  1  1  1 4  0 0		# Llanos del marrano
build 6  0  1 1  4  3  1  1 2  1 0		# Pozo poroso (nadando)
build 8 13 10 6  7  3 99  1 8  0 1		# Isla de la bruja
build 7  0  2 2 10  2  1  1 4  0 0		# Llanos 2
build 3  0  3 2 10  2  1  1 3  0 0		# Cueva Kave
build 1  0  2 2 12  1  1  1 1  0 0		# Bosque de los monos
build A  0  1 1  7  2 99  1 A  1 0		# Lago oscuro (nadando)
build 9  9  1 6  4  4  1  1 9  0 0		# Castillo de la carne de membrillo
build B  0  1 3  2  6  1  1 B  0 0		# Tienda
build D  0  4 2 10  1  1  1 1  0 0		# Tutorial
build C  9 12 5  1 10  1  1 C  0 1		# Lava
build E  0  1 1  8  2  1  1 3  0 0		# Cueva de Anju
build F  0  7 1  1 12  1  1 0  0 0		# Pozo de Zenman
build Z 15  7 7  4  5 99  1 Z  0 1		# Castillo de Gonzalo
build Y  0  1 1 20  1  1  1 Y  0 0		# Final malo
build X  0 12 8  3  1 99  1 X  0 1		# Final bueno

for t in 0 1 2 3 4 5 8 9 A B C X Y Z; do
	$U/ts2bin nofont ../gfx/work$t.png ts$t.bin 7 > /dev/null
	z ts$t.bin ts${t}c.bin
done
for s in 0 1 2 4; do
	$U/sprcnv ../gfx/sprites$s.png ss$s.bin > /dev/null
	z ss$s.bin ss${s}c.bin
done

# Los scripts de los niveles (msc4 ya ha dejado los .spt.bin)
for s in 4 5 8 9 A B C D X Y Z; do
	z ../script/script$s.spt.bin script${s}c.bin
done

# Pantallas completas
for s in title marco ending ending1 ending2 ending3 ending4 dedicado level; do
	$U/png2scr ../gfx/$s.png $s.scr > /dev/null
	z $s.scr $s.bin
done

# Los créditos van tal cual (líneas de 32 caracteres), como los textos
cp ../texts/credits.bin credits.bin
