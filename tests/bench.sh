#!/bin/bash
# Mide tamaño y velocidad del motor: compila varias configuraciones y cuenta
# los ciclos de reloj por frame de juego (entre llamadas a _move) durante
# 1000 frames con la misma secuencia de teclas.
# Uso: tests/bench.sh [etiqueta]
REPO="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$REPO/tests/out/bench"; mkdir -p "$OUT"
FIRE="PLAYER_CAN_FIRE PLAYER_BULLET_SPEED=8 MAX_BULLETS=3 PLAYER_BULLET_Y_OFFSET=6 PLAYER_BULLET_X_OFFSET=0 ENEMS_LIFE_GAUGE=4 PLAYER_HAS_JUMP -PLAYER_BOOTEE"
K="130:1+,134:1-,200:p+,320:p-,330:o+,420:o-,430:p+,600:p-,610:o+,800:o-,810:p+,1000:p-,1010:spc+,1020:spc-,1100:spc+,1110:spc-"
printf "%-10s %8s %14s\n" config bytes "ciclos/frame"
for c in "bootee|" "fire|$FIRE" "moggy|PLAYER_MOGGY_STYLE -PLAYER_BOOTEE -PLAYER_STOMPS_ON_ENEMIES"; do
	n=${c%%|*}; d=${c#*|}
	T="$(mktemp -d)"; cp -r "$REPO/src" "$T/src"
	"$REPO/tests/build.sh" zx "$OUT/$n.bin" $d > /dev/null || { echo "$n: no compila"; continue; }
	# map: compilamos otra vez en la copia para tener el .map (build.sh no lo guarda)
	(cd "$T/src/dev" && cp "$OUT/$n.bin.config.h" config.h && ./comp-zx.sh noclean > /dev/null 2>&1)
	a=$(grep -m1 -E "^_MOVE\b" "$T/src/dev/bootee.map" | sed -E 's/.*= ([0-9A-F]+),.*/\1/')
	r=$("$REPO/tests/zxrun/zxrun" "$OUT/$n.bin" -f 1200 -k "$K" -count 0x$a 150 | grep count)
	printf "%-10s %8d %14s\n" $n $(stat -c%s "$OUT/$n.bin") "$(echo $r | sed -E 's/count ([0-9]+), ([0-9]+).*/\2  (\1 frames)/')"
	rm -rf "$T"
done | tee "$OUT/${1:-ultimo}.txt"
