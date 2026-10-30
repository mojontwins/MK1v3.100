#!/bin/bash
# Compila todas las utilidades de src/utils para Linux en src/utils/linux/
# Requiere fbc (FreeBASIC 1.10), gcc, g++ y cmake. Ver env/setup-linux.sh.

set -e
U="$(cd "$(dirname "$0")" && pwd)"
OUT="$U/linux"
TMP="$(mktemp -d)"
mkdir -p "$OUT"
trap 'rm -rf "$TMP"' EXIT

# libfbpng: sustituto Linux de la libfbpng.a de Windows (misma ABI que fbpng.bi)
gcc -O2 -c "$U/src/fbpng-linux/fbpng_shim.c" -o "$TMP/fbpng.o"
ar rcs "$TMP/libfbpng.a" "$TMP/fbpng.o"

# Utilidades en FreeBASIC. ponedor y gui son GUI de Windows: no se compilan.
for bas in "$U"/*.bas; do
	f=$(basename "$bas" .bas)
	case "$f" in
		ponedor|gui|bmp|cmdlineparser|mtparser|mt5bitEsc) continue ;;
	esac
	extra=""
	for m in mtparser cmdlineparser mt5bitEsc; do
		grep -q "$m.bi" "$bas" && extra="$extra $U/$m.bas"
	done
	if fbc -p "$TMP" -x "$OUT/$f" "$bas" $extra > "$TMP/$f.log" 2>&1; then
		echo "  ok  $f"
	else
		echo "FALLO $f"; cat "$TMP/$f.log"; exit 1
	fi
done

# Herramientas externas (C/C++)
S="$U/src"
gcc -O2 -w -o "$OUT/zx0" "$S/ZX0/src/zx0.c" "$S/ZX0/src/optimize.c" "$S/ZX0/src/compress.c" "$S/ZX0/src/memory.c" && echo "  ok  zx0"
gcc -O2 -w -o "$OUT/zx7" "$S/zx7/zx7.c" "$S/zx7/optimize.c" "$S/zx7/compress.c" && echo "  ok  zx7"
gcc -O2 -w -o "$OUT/bas2tap" "$S/bas2tap/bas2tap.c" -lm && echo "  ok  bas2tap"
gcc -O2 -o "$OUT/bin2tap" "$S/bin2tap-c/bin2tap.c" && echo "  ok  bin2tap"
gcc -O2 -w -fcommon -o "$OUT/cpc2cdt" "$S/cpc2cdt/src/cpc2cdt.c" "$S/cpc2cdt/src/tinytape.c" && echo "  ok  cpc2cdt"
g++ -O2 -w -o "$OUT/cpctbin2sna" "$S/cpctbin2sna/main.cpp" "$S/cpctbin2sna/mem_imgs.cpp" && echo "  ok  cpctbin2sna"
gcc -O2 -w -I"$S/apultra/src/libdivsufsort/include" -o "$OUT/apultra" \
	$(ls "$S"/apultra/src/*.c "$S"/apultra/src/libdivsufsort/lib/*.c) && echo "  ok  apultra"
cp -r "$S/pasmo/pasmo" "$TMP/pasmo"
(cd "$TMP/pasmo" && cmake -S . -B build -DCMAKE_BUILD_TYPE=Release >/dev/null && cmake --build build -j"$(nproc)" >/dev/null)
cp "$TMP/pasmo/build/pasmo" "$OUT/pasmo" && echo "  ok  pasmo"

echo "Utilidades en $OUT"
