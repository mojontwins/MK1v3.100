#!/bin/bash
# Prueba del sistema de niveles: compila bootee con COMPRESSED_LEVELS (dos
# niveles, ver levels.sh) empezando por el nivel $1 y lo ejecuta en zxrun.
# Uso: [SCRIPTED=1] tests/levels/run.sh [nivel] [salida]
# Con SCRIPTED=1 cada nivel lleva su script (nivel1.spt, nivel2.spt).
set -e
L=${1:-0}; OUTP=${2:-/tmp/mk1-levels}
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
cp -r "$REPO/src" "$T/src"; mkdir -p "$T/tests"; cp -r "$REPO/tests/levels" "$T/tests/"
D="$T/src/dev"
cp "$REPO/tests/levels/levels.sh" "$REPO/tests/levels/levelset.h" "$REPO/tests/levels/librarian.txt" "$REPO/tests/levels/custom.h" "$D/"
# behs.txt sale de config.h antes de quitarle la tabla
python3 - "$D/config.h" "$D/behs.txt" <<'PY'
import re,sys
s=open(sys.argv[1]).read(); m=re.search(r'comportamiento_tiles \[\] = \{(.*?)\};',s,re.S)
open(sys.argv[2],'w').write(','.join(v.strip() for v in m.group(1).split(',') if v.strip()))
PY
if [ "$SCRIPTED" = 1 ]; then
	# Un script por nivel (scripts.txt) como recursos de librarian
	cp "$REPO/tests/levels/scripts.txt" "$D/"
	printf "script1c.bin\nscript2c.bin\n" >> "$D/librarian.txt"
	sed -i 's@^//#define ACTIVATE_SCRIPTING@#define ACTIVATE_SCRIPTING@' "$D/config.h"
fi
cd "$D"
sed -i 's@^//#define MODE_128K.*@#define MODE_128K@; s@^//#define COMPRESSED_LEVELS.*@#define COMPRESSED_LEVELS@; s@^//#define MAX_LEVELS.*@#define MAX_LEVELS 2@' config.h
sed -i "1i #define TEST_START_LEVEL $L\n#define PLAYER_CHECK_MAP_BOUNDARIES" config.h
./comp-zx.sh noclean > "$OUTP.log" 2>&1 || { tail -20 "$OUTP.log"; exit 1; }
cp bootee.bin "$OUTP.bin"; for r in RAM?.bin; do cp $r "$OUTP.$r"; done; cp bootee.map "$OUTP.map"
args=""; for r in RAM?.bin; do p=${r#RAM}; args="$args -page ${p%.bin} $OUTP.$r"; done
echo "$args" > "$OUTP.pages"
