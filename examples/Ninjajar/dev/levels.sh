#!/bin/bash
# levels.sh de Ninjajar: construye los niveles (bundles.sh), los tilesets, los
# spritesets, los scripts y las pantallas. Lo llama comp-zx.sh (después de msc4 y antes
# de librarian). Ver docs/formato-niveles.md.
#
# Los niveles van por mapa (0..9, A..F, X, Y, Z, como en el original); la
# tabla de levelset.h dice en qué orden se juegan y qué gráficos usa cada
# uno. Los tilesets no llevan la fuente (LEVEL_TILESETS_NO_FONT): se cargan
# encima de los tiles del tileset base.
set -e
U=../utils/linux
. ./bundles.sh

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
