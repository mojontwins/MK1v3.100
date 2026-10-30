#!/bin/bash
# levels.sh de la prueba de niveles (tests/levels): dos niveles con los datos
# de bootee. Se copia a src/dev en una copia limpia (ver run.sh).
#  * Nivel 1: el mapa entero (6x5), tileset por defecto.
#  * Nivel 2: un trozo de 3x2 pantallas (columnas 3-5, filas 0-1) con su
#    propio recurso de tileset, para probar mapas de distinto tamaño y la
#    carga de gráficos por nivel.
set -e
U=../utils/linux
# behs.txt (los 48 comportamientos) lo deja run.sh, sacado de config.h.
$U/buildlevel map=../map/mapa.map ene=../enems/enems.ene behs=behs.txt out=level1.bin maxpant=30 \
	scr_ini=1 ini_x=5 ini_y=1 max_objs=25 life=1 2bytes
../../tests/levels/crop.py ../map/mapa.map ../enems/enems.ene 3 0 3 2 crop.map crop.ene 2bytes
$U/buildlevel map=crop.map ene=crop.ene behs=behs.txt out=level2.bin maxpant=30 \
	scr_ini=0 ini_x=3 ini_y=2 max_objs=4 life=1 2bytes
for f in level1 level2; do rm -f ${f}c.bin; $U/zx0 $f.bin ${f}c.bin > /dev/null; done
rm -f ts2c.bin; $U/zx0 ts.bin ts2c.bin > /dev/null

# Con scripting (SCRIPTED=1 en run.sh): los .bin de msc4 comprimidos, como recursos
if [ -f ../../tests/levels/nivel1.spt.bin ]; then
	for n in 1 2; do rm -f script${n}c.bin; $U/zx0 ../../tests/levels/nivel$n.spt.bin script${n}c.bin > /dev/null; done
fi
