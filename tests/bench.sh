#!/bin/bash
# Mide tamaño y velocidad del motor en ZX 48K (sin sincronía de frames, para
# medir trabajo y no esperas: GAME_FRAME_TICKS 0).
#
#  * reposo: ciclos de reloj por frame de juego (entre llamadas a _move) sin
#    tocar nada tras empezar. Es determinista: el trabajo de cada frame no
#    depende de la velocidad, así que se puede comparar entre versiones.
#  * pantalla: ciclos por llamada a draw_scr (pintar una pantalla al entrar,
#    incluido todo lo que llama), con un recorrido por varias pantallas.
#
# Uso: tests/bench.sh [etiqueta]
REPO="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$REPO/tests/out/bench"; mkdir -p "$OUT"
FIRE="PLAYER_CAN_FIRE PLAYER_BULLET_SPEED=8 MAX_BULLETS=3 PLAYER_BULLET_Y_OFFSET=6 PLAYER_BULLET_X_OFFSET=0 ENEMS_LIFE_GAUGE=4 PLAYER_HAS_JUMP -PLAYER_BOOTEE"
IDLE="130:1+,134:1-"
WALK="130:1+,134:1-,200:p+,320:p-,330:o+,420:o-,430:p+,600:p-,610:o+,800:o-,810:p+,1000:p-"

addr () { grep -m1 -E "^$1\b" "$2" | sed -E 's/.*= ([0-9A-F]+),.*/\1/'; }

printf "%-8s %7s %15s %22s\n" config bytes "reposo c/frame" "pantalla c/draw_scr"
for c in "bootee|" "fire|$FIRE" "moggy|PLAYER_MOGGY_STYLE -PLAYER_BOOTEE -PLAYER_STOMPS_ON_ENEMIES"; do
	n=${c%%|*}; d=${c#*|}
	"$REPO/tests/build.sh" zx "$OUT/$n.bin" $d GAME_FRAME_TICKS=0 > /dev/null || { echo "$n: no compila"; continue; }
	T="$(mktemp -d)"; cp -r "$REPO/src" "$T/src"
	(cd "$T/src/dev" && cp "$OUT/$n.bin.config.h" config.h && ./comp-zx.sh noclean > /dev/null 2>&1)
	M="$T/src/dev/bootee.map"
	idle=$("$REPO/tests/zxrun/zxrun" "$OUT/$n.bin" -f 1200 -k "$IDLE" -count 0x$(addr _MOVE $M) 300 | sed -E 's/count [0-9]+, ([0-9]+).*/\1/')
	draw=$("$REPO/tests/zxrun/zxrun" "$OUT/$n.bin" -f 1100 -k "$WALK" -incl 0x$(addr _DRAW_SCR $M) 140 | sed -E 's/incl ([0-9]+) llamadas, ([0-9]+).*/\2 (\1)/')
	printf "%-8s %7d %15s %22s\n" $n $(stat -c%s "$OUT/$n.bin") "$idle" "$draw"
	rm -rf "$T"
done | tee "$OUT/${1:-ultimo}.txt"
