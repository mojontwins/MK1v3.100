#!/bin/bash
# Compila Goku Mal con el motor de MK1 v3.100 de este repositorio.
#
# El juego solo trae lo suyo (dev/: config.h, custom.h, levelset.h, ...;
# y sus gráficos, mapas, enemigos y música). make.sh copia src/dev a build/,
# pone encima los archivos del juego y llama a comp-zx.sh, así que el juego
# usa siempre el motor actual. Deja gokumal.tap aquí.
#
# Uso: ./make.sh [noclean]     (noclean deja los intermedios en build/dev)
# Requiere las utilidades compiladas (src/utils/build-linux.sh) y GBDK_HOME
# (source ~/mk1tools/mk1env.sh).
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
B="$HERE/build"

rm -rf "$B"; mkdir -p "$B"
cp -r "$REPO/src/dev" "$B/dev"
ln -s "$REPO/src/utils" "$B/utils"
for d in gfx map enems levels ogt; do ln -s "$HERE/$d" "$B/$d"; done
cp -r "$HERE/dev/." "$B/dev/"

(cd "$B/dev" && ./comp-zx.sh "$@")
cp "$B/dev/gokumal.tap" "$HERE/"
echo "gokumal.tap listo"
