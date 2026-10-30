#!/bin/bash
# Compila el juego en una copia limpia de src/ (no toca el árbol de trabajo).
#
# Uso: tests/build.sh zx|cpc SALIDA.bin [DEF[=valor] ...] [-UNDEF ...]
#   DEF        activa (o añade) "#define DEF valor" en config.h
#   -UNDEF     comenta "#define UNDEF"
# Escribe el log del compilador en SALIDA.log. Devuelve 0 si compila.

set -e
REPO="$(cd "$(dirname "$0")/.." && pwd)"
target=$1; out=$(realpath -m "$2"); shift 2

T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
cp -r "$REPO/src" "$T/src"
cfg="$T/src/dev/config.h"

extra=""
for d in "$@"; do
	if [[ $d == -* ]]; then
		u=${d#-}
		sed -i -E "s@^([ \t]*)#define[ \t]+$u\b@\1//#define $u@" "$cfg"
	else
		k=${d%%=*}; v=""; [[ $d == *=* ]] && v=${d#*=}
		vs=${v//&/\\&}		# & es especial en el reemplazo de sed
		if grep -qE "^[ \t]*//[ \t]*#define[ \t]+$k\b" "$cfg"; then
			sed -i -E "0,/^[ \t]*\/\/[ \t]*#define[ \t]+$k\b.*/s@@#define $k $vs@" "$cfg"
		elif grep -qE "^[ \t]*#define[ \t]+$k\b" "$cfg"; then
			# Ya activo: se cambia el valor si se ha dado uno
			[[ $d == *=* ]] && sed -i -E "0,/^([ \t]*)#define[ \t]+$k\b[^/]*/s@@\1#define $k $vs\t@" "$cfg"
		else
			extra="$extra#define $k $v"$'\n'
		fi
	fi
done
if [ -n "$extra" ]; then printf '%s' "$extra" | cat - "$cfg" > "$cfg.new"; mv "$cfg.new" "$cfg"; fi

cd "$T/src/dev"
if ./comp-$target.sh noclean > "$out.log" 2>&1 && [ -f bootee.bin ]; then
	cp bootee.bin "$out"
	[ -f bootee.sna ] && cp bootee.sna "${out%.bin}.sna"	# CPC: para tests/cpcrun
	for r in RAM?.bin; do [ -f "$r" ] && cp "$r" "${out%.bin}.$r"; done	# 128K: páginas de RAM
	cp config.h "$out.config.h"
else
	cp config.h "$out.config.h"
	exit 1
fi
