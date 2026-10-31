#!/bin/bash
# Construye splib2.lib con sdasz80 y sdar (de GBDK-2020) a partir de los
# módulos de sp.lst, y la deja, junto con spritepack.h, en src/dev/speccy,
# que es donde la busca comp-zx.
set -e
cd "$(dirname "$0")"
B="${GBDK_HOME:+$GBDK_HOME/bin/}"
O=obj; rm -rf $O; mkdir -p $O
while read m; do m=${m%$'\r'}; [ -z "$m" ] && continue
	"${B}sdasz80" -I. -o $O/$(basename $m).rel $m.s
done < sp.lst
L=../../src/dev/speccy
rm -f $L/splib2.lib; "${B}sdar" -rc $L/splib2.lib $O/*.rel; rm -rf $O
cp spritepack.h $L/
echo "splib2.lib listo"
