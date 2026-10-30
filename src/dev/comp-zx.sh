#!/bin/bash
# Equivalente Linux de comp-zx.bat
# Uso: ./comp-zx.sh [justcompile] [noclean]
# Requiere z88dk 1.10 en el PATH (source z88env.sh, ver env/setup-linux.sh)
#
# Si config.h define MODE_128K, además:
#  * ensambla el WYZ player (speccy_128/wyz/wyzplayer.asm) con las canciones,
#    instrumentos y efectos del juego (../ogt/zx128 o ../ogt) en RAM1 y genera
#    wyz_addrs.h;
#  * reparte los recursos de librarian.txt (o title/marco/ending si no existe)
#    en las páginas 3, 4, 6 y 7 con librarian, que genera librarian.h;
#  * comprueba que lo que se usa con otra página puesta queda bajo 0xC000;
#  * hace una cinta con un cargador que coloca cada página en su sitio.

# Cambia "game" por el nombre de tu güego.
game=bootee

cd "$(dirname "$0")"
U=../utils/linux

justcompile=0; noclean=0
for a in "$@"; do
	[ "$a" = "justcompile" ] && justcompile=1
	[ "$a" = "noclean" ] && noclean=1
done

mode128=0
grep -qE '^[[:space:]]*#define[[:space:]]+MODE_128K\b' config.h && mode128=1

if [ $justcompile = 0 ]; then
	echo "### CONVIRTIENDO COSAS QUE HAY QUE CONVERTIR ###"
	$U/mapcnv ../map/mapa.map mapa.h 6 5 15 10 15 packed > /dev/null
	$U/ene2h ../enems/enems.ene enems.h 2bytes > /dev/null

	$U/ts2bin ../gfx/speccy/font.png ../gfx/speccy/work.png ts.bin 7 > /dev/null
	$U/sprcnv ../gfx/speccy/sprites.png speccy/sprites.h > /dev/null
	for s in title marco ending loading; do
		$U/png2scr ../gfx/speccy/$s.png $s.scr > /dev/null
	done
	for s in title marco ending; do
		rm -f $s.bin; $U/zx0 $s.scr $s.bin > /dev/null
	done
fi

echo "### COMPILANDO SCRIPT ###"
# no olvides cambiar NPANT por el nº de pantallas
# $U/msc ../script/script.spt msc.h 30

if [ $mode128 = 1 ]; then
	echo "### 128K: WYZ PLAYER Y RECURSOS ###"
	# Reproductor + datos del juego: instrumentos.asm, canciones.asm, los .mus
	# y, opcionalmente, efectos.asm (si no, los 15 de MK1 por defecto). Se
	# toman de ../ogt/zx128 si existe; si no, de ../ogt.
	OGT=../ogt; [ -d ../ogt/zx128 ] && OGT=../ogt/zx128
	W=$(mktemp -d)
	cp speccy_128/wyz/wyzplayer.asm speccy_128/wyz/efectos.asm "$W/"
	cp $OGT/*.asm $OGT/*.mus "$W/" 2>/dev/null
	if ! (cd "$W" && "$OLDPWD/$U/pasmo" wyzplayer.asm ram1.bin ram1.sym > /dev/null 2>&1); then
		echo "ERROR ensamblando el WYZ player"; (cd "$W" && "$OLDPWD/$U/pasmo" wyzplayer.asm ram1.bin ram1.sym); rm -rf "$W"; exit 1
	fi
	cp "$W/ram1.bin" RAM1.bin
	sym () { grep -E "^$1[[:space:]]" "$W/ram1.sym" | sed -E 's/.*EQU 0?([0-9A-F]+)H/0x\1/'; }
	cat > wyz_addrs.h <<-EOF
		// Generado por comp-zx.sh a partir de la tabla de símbolos del WYZ player
		#define WYZPLAYERISR		$(sym INICIO)
		#define WYZPLAYERINIT		$(sym INIT_BUFFERS)
		#define CARGA_CANCION		$(sym CARGA_CANCION)
		#define SILENCIA_PLAYER		$(sym PLAYER_OFF)
		#define INICIAEFECTO		$(sym INICIA_EFECTO)
	EOF
	rm -rf "$W"
	echo "RAM1.bin: $(stat -c%s RAM1.bin) bytes"

	# Recursos en páginas de RAM
	if [ -f librarian.txt ]; then lst=librarian.txt; else
		lst=librarian.default.txt; printf "title.bin\nmarco.bin\nending.bin\n" > $lst
	fi
	rm -f RAM3.bin RAM4.bin RAM6.bin RAM7.bin
	$U/librarian list=$lst out=librarian.h || exit 1
fi

echo "### COMPILANDO GUEGO ###"
rm -f zcc_opt.def
zcc +zx -a -vn churromain.c -o $game.asm -lsplib2 -zorg=24200 > /dev/null 2>&1
rm -f zcc_opt.def
if ! zcc +zx -m -vn churromain.c -o $game.bin -lsplib2 -zorg=24200; then
	echo "ERROR"; exit 1
fi
$U/printsize $game.bin

if [ $mode128 = 1 ]; then
	# Todo lo que se usa con otra página de RAM en 0xC000 tiene que estar por debajo.
	bad=0
	for s in DEPACK _UNPACK_RAMN SETRAMBANK _ISR _TILESET _SPRITES_END _LEVEL_DATA_END; do
		a=$(grep -m1 -E "^$s[[:space:]]" $game.map | sed -E 's/.*= ([0-9A-F]+),.*/\1/')
		[ -z "$a" ] && continue
		if [ $((16#$a)) -ge $((0xC000)) ]; then
			echo "ERROR 128K: $s está en \$$a, por encima de 0xC000"; bad=1
		fi
	done
	[ $bad = 1 ] && exit 1
fi

echo "### CONSTRUYENDO CINTA ###"
$U/bin2tap -o screen.tap -a 16384 loading.scr
$U/bin2tap -o main.tap -a 24200 $game.bin
if [ $mode128 = 0 ]; then
	# cambia BOOTEE por el nombre que quieres que salga en Program:
	$U/bas2tap -a10 -sBOOTEE speccy/loader.bas loader.tap > /dev/null
	cat loader.tap screen.tap main.tap > $game.tap
else
	# Cargador 128K: cada página se carga en 32768 y reubica la copia a su
	# banco (POKE 25000, página: RANDOMIZE USR 25002).
	$U/pasmo speccy_128/reubica.asm reubica.bin > /dev/null
	$U/bin2tap -o reubica.tap -a 25000 reubica.bin
	pages=""; tapes="screen.tap reubica.tap"
	for p in 1 3 4 6 7; do
		[ -f RAM$p.bin ] || continue
		$U/bin2tap -o ram$p.tap -a 32768 RAM$p.bin
		pages="$pages:LOAD \"\"CODE:POKE VAL \"25000\",VAL \"$p\":RANDOMIZE USR VAL \"25002\""
		tapes="$tapes ram$p.tap"
	done
	echo "10 BORDER NOT PI:PAPER NOT PI:INK VAL \"6\":CLS:CLEAR VAL \"24199\":LOAD \"\"SCREEN\$:LOAD \"\"CODE$pages:LOAD \"\"CODE:RANDOMIZE USR VAL \"24200\"" > loader128.bas
	$U/bas2tap -a10 -sBOOTEE loader128.bas loader.tap > /dev/null
	cat loader.tap $tapes main.tap > $game.tap
fi

if [ $noclean = 0 ]; then
	echo "### LIMPIANDO ###"
	rm -f loader.tap screen.tap main.tap reubica.tap ram?.tap *.scr *.bin zcc_opt.def loader128.bas librarian.default.txt
fi

echo "### DONE ###"
