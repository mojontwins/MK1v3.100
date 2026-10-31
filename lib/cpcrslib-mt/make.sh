#!/bin/bash
# Construye cpcrslib.lib (variante normal) y cpcrslib_fg.lib (variante fg,
# con PASARPORDETRAS) con sdasz80 y sdar (de GBDK-2020) a partir de los
# módulos de cpcrslib.lst, y las deja, junto con cpcrslib_mt.h, en
# src/dev/cpc, que es donde las busca comp-cpc.
set -e
cd "$(dirname "$0")"
B="${GBDK_HOME:+$GBDK_HOME/bin/}"
L=../../src/dev/cpc
for v in normal fg; do
	O=obj; rm -rf $O; mkdir -p $O
	p=0; lib=cpcrslib.lib
	[ $v = fg ] && { p=1; lib=cpcrslib_fg.lib; }
	sed "s/^\tPASARPORDETRAS = .*/\tPASARPORDETRAS = $p/" CPCconfig.inc > $O/CPCconfig.inc
	while read m; do m=${m%$'\r'}; [ -z "$m" ] && continue
		"${B}sdasz80" -I$O -o $O/$m.rel $m.s
	done < cpcrslib.lst
	rm -f $L/$lib; "${B}sdar" -rc $L/$lib $O/*.rel; rm -rf $O
	echo "$lib listo"
done
cp cpcrslib_mt.h $L/
