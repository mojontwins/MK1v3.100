#!/bin/bash
# levels.sh de Goku Mal: construye los cinco niveles. Lo llama comp-zx.sh antes
# de librarian. Ver docs/formato-niveles.md.
#
# Cada nivel: bundle (mapa, enemigos, hotspots, comportamientos) + tileset +
# spriteset, todo comprimido con zx0. Los números de nivel van en el orden
# del juego: el nivel 4 es el mapa 5 (5x5, las flores) y el 5 el mapa 4.
set -e
U=../utils/linux

# nivel  mapa  scr_ini ini_x ini_y max_objs vida
build () {
	n=$1; m=$2
	$U/buildlevel map=../map/mapa$m.MAP ene=../enems/enems$m.ene behs=../levels/behs$m.txt \
		out=level$n.bin maxpant=25 scr_ini=$3 ini_x=$4 ini_y=$5 max_objs=$6 life=$7 lock=99 2bytes > /dev/null
	$U/ts2bin ../gfx/font.png ../gfx/work$m.png ts$n.bin 7 > /dev/null
	$U/sprcnv ../gfx/sprites$m.png spr$n.h > /dev/null
	$U/defb2bin spr$n.h spr$n.bin > /dev/null
	for f in level ts spr; do rm -f $f${n}c.bin; $U/zx0 $f$n.bin $f${n}c.bin > /dev/null; done
}

build 1 1 24  2 7 99 3		# 1x25, de abajo arriba
build 2 2  0  4 1 99 4		# 25x1, de izquierda a derecha
build 3 3 24 12 1 99 5		# 25x1, de derecha a izquierda
build 4 5 10  1 7  6 5		# 5x5, coger las 6 flores
build 5 4  0  4 1 99 5		# 1x25, de arriba abajo
