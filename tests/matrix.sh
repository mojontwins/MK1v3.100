#!/bin/bash
# Compila el motor con distintas combinaciones de config.h.
# Uso: tests/matrix.sh [zx|cpc|all] [filtro]
# Deja binarios y logs en tests/out/matrix/

REPO="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$REPO/tests/out/matrix"
mkdir -p "$OUT"
targets=${1:-all}; [ "$targets" = all ] && targets="zx cpc"
filter=${2:-.}

FIRE="PLAYER_CAN_FIRE PLAYER_BULLET_SPEED=8 MAX_BULLETS=3 PLAYER_BULLET_Y_OFFSET=6 PLAYER_BULLET_X_OFFSET=0 ENEMS_LIFE_GAUGE=4"
SIDE_JUMP="PLAYER_HAS_JUMP -PLAYER_BOOTEE"
TOP="PLAYER_MOGGY_STYLE -PLAYER_BOOTEE -PLAYER_STOMPS_ON_ENEMIES"

# nombre|defines
CONFIGS=(
	"bootee|"
	"jump|$SIDE_JUMP"
	"jetpac|PLAYER_HAS_JETPAC -PLAYER_BOOTEE"
	"cumjump|$SIDE_JUMP PLAYER_CUMULATIVE_JUMP"
	"kills|PLAYER_KILLS_ENEMIES -PLAYER_STOMPS_ON_ENEMIES PLAYER_SHOW_KILLS"
	"minkill|PLAYER_KILLS_ENEMIES -PLAYER_STOMPS_ON_ENEMIES PLAYER_MIN_KILLABLE=2"
	"flicker|PLAYER_FLICKERS -PLAYER_BOUNCES -SLOW_DRAIN"
	"nokeys|DEACTIVATE_KEYS"
	"noobjs|DEACTIVATE_OBJECTS"
	"oneobj|ONLY_ONE_OBJECT"
	"noevil|DEACTIVATE_EVIL_TILE"
	"bbox16|-BOUNDING_BOX_8_BOTTOM -SMALL_COLLISION"
	"bboxc|-BOUNDING_BOX_8_BOTTOM BOUNDING_BOX_8_CENTERED"
	"hot3|USE_HOTSPOTS_TYPE_3"
	"fire|$SIDE_JUMP $FIRE"
	"fireup|$SIDE_JUMP $FIRE CAN_FIRE_UP"
	"twobtn|$SIDE_JUMP $FIRE USE_TWO_BUTTONS"
	"ammo|$SIDE_JUMP $FIRE MAX_AMMO=99 AMMO_REFILL=50 INITIAL_AMMO=0"
	"lbullets|$SIDE_JUMP $FIRE LIMITED_BULLETS LB_FRAMES=4"
	"respawn|$SIDE_JUMP $FIRE RESPAWN_ON_ENTER FIRE_MIN_KILLABLE=2"
	"breakable|$SIDE_JUMP $FIRE BREAKABLE_WALLS BREAKABLE_WALLS_LIFE=1"
	"rrespawn|$SIDE_JUMP $FIRE ENABLE_RANDOM_RESPAWN FANTY_MAX_V=1024 FANTY_A=64 FANTIES_LIFE_GAUGE=10"
	"type6|ENABLE_CUSTOM_TYPE_6 TYPE_6_FIXED_SPRITE=2 SIGHT_DISTANCE=104 FANTY_MAX_V=1024 FANTY_A=64"
	"pursuers|ENABLE_PURSUERS PLAYER_KILLS_ENEMIES -PLAYER_STOMPS_ON_ENEMIES DEATH_COUNT_EXPRESSION=20+(rand()&15)"
	"moggy|$TOP"
	"moggyfire|$TOP $FIRE"
	"moggypush|$TOP PLAYER_PUSH_BOXES"
	"push|PLAYER_PUSH_BOXES"
	"firepush|$SIDE_JUMP $FIRE PLAYER_PUSH_BOXES FIRE_TO_PUSH"
	"bouncewalls|$TOP PLAYER_BOUNCE_WITH_WALLS"
	"pause|PAUSE_ABORT"
	"timer|TIMER_ENABLE TIMER_INITIAL=99 TIMER_REFILL=30 TIMER_LAPSE=32 TIMER_START TIMER_KILL_0 TIMER_AUTO_RESET SHOW_TIMER_OVER PLAYER_SHOW_TIMER"
	"timergo|TIMER_ENABLE TIMER_INITIAL=99 TIMER_LAPSE=32 TIMER_START TIMER_GAMEOVER_0 SHOW_TIMER_OVER"
	"checkpts|ENABLE_CHECKPOINTS CP_RESET_WHEN_DYING"
	"tilanims|ENABLE_TILANIMS=32"
	"shadows|USE_AUTO_SHADOWS"
	"tshadows|USE_AUTO_TILE_SHADOWS"
	"unpacked|UNPACKED_MAP"
	"nomasks|NO_MASKS"
	"getxmore|GET_X_MORE"
	"bounds|PLAYER_CHECK_MAP_BOUNDARIES MAP_BOTTOM_KILLS"
	"notdirect|-DIRECT_TO_PLAY"
	"stepsnd|$SIDE_JUMP PLAYER_STEP_SOUND"
	"altanim|$SIDE_JUMP PLAYER_ALTERNATE_ANIMATION"
	"128k|MODE_128K"
	"128kfire|MODE_128K $SIDE_JUMP $FIRE"
	"128kpause|MODE_128K PAUSE_ABORT"
)

pass=0; fail=0
for t in $targets; do
	for c in "${CONFIGS[@]}"; do
		name=${c%%|*}; defs=${c#*|}
		[[ $name =~ $filter ]] || continue
		[[ $t == cpc && $name == 128k* ]] && continue		# 128K es solo ZX
		if "$REPO/tests/build.sh" $t "$OUT/$t-$name.bin" $defs; then
			printf "  ok   %-4s %-12s %6d bytes\n" $t $name $(stat -c%s "$OUT/$t-$name.bin")
			pass=$((pass+1))
		else
			err=$(grep -m1 -iE "error" "$OUT/$t-$name.bin.log" | cut -c1-110)
			printf "FALLO  %-4s %-12s %s\n" $t $name "$err"
			fail=$((fail+1))
		fi
	done
done
echo "== $pass ok, $fail fallos"
[ $fail = 0 ]
