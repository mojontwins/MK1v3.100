#!/bin/bash
# Compila splib2.lib (splib2 para SDCC) con sdasz80 y sdar.
# Uso: lib/splib2/make.sh      (GBDK-2020 en $GBDK_HOME, o en el PATH)
set -e
cd "$(dirname "$0")"
B="${GBDK_HOME:+$GBDK_HOME/bin/}"
O=obj; rm -rf $O; mkdir -p $O
while read m; do
	m=${m%$'\r'}; [ -z "$m" ] && continue
	"${B}sdasz80" -I. -o $O/$(basename $m).rel $m.s
done < sp.lst
rm -f splib2.lib
"${B}sdar" -rc splib2.lib $O/*.rel
rm -rf $O
echo "splib2.lib listo"
