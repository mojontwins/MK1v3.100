#!/bin/bash
# levels_gb.sh de Ninjajar: lo mismo que levels.sh para Game Boy. Lo llama
# comp-gb.sh (después de msc4 y antes de librarian).
#
# Los bundles son los mismos (bundles.sh). Los gráficos salen de gfx/gb con
# mkts_om: un tileset de 192 patrones por nivel, los spritesets (16 sprites)
# y las pantallas fijas de 160x144. Los scripts, los textos y los créditos
# van sin comprimir (se leen directamente de la ROM), pero con los mismos
# nombres que en ZX para que levelset.h y librarian sirvan igual.
set -e
U=../utils/linux
. ./bundles.sh
G="platform=gb silent"

for t in 0 1 2 3 4 5 8 9 A B C X Y Z; do
	$U/mkts_om $G mode=strait2x2 in=../gfx/gb/work$t.png out=ts$t.bin max=48 > /dev/null
	z ts$t.bin ts${t}c.bin
done
for s in 0 1 2 4; do
	$U/mkts_om $G mode=sprites in=../gfx/gb/sprites$s.png out=ss$s.bin max=16 > /dev/null
	z ss$s.bin ss${s}c.bin
done

# Los scripts de los niveles (msc4 ya ha dejado los .spt.bin), tal cual
for s in 4 5 8 9 A B C D X Y Z; do
	cp ../script/script$s.spt.bin script${s}c.bin
done

# Pantallas fijas
for s in title ending ending1 ending2 ending3 ending4 dedicado level; do
	# (mkts_om avisa si la pantalla tiene más de 192 patrones)
	$U/mkts_om $G mode=scr in=../gfx/gb/$s.png out=${s}_raw.bin > mkts.log
	grep -i warning mkts.log || true
	z ${s}_raw.bin $s.bin
done

# Los créditos van tal cual (líneas de 32 caracteres), como los textos
cp ../texts/credits.bin credits.bin
