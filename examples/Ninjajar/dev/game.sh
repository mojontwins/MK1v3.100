# game.sh de Ninjajar: lo lee comp-zx.sh (ver src/dev/comp-zx.sh).
game=ninjajar

# Gráficos que no van en los niveles: el tileset base (la fuente y los tiles
# comunes; cada nivel carga los suyos encima, sin la fuente), los sprites
# del binario (los del nivel 1) y la pantalla de carga. Las demás pantallas
# las hace levels.sh.
convert_assets () {
	$U/ts2bin ../gfx/font.png ../gfx/basework.png ts.bin 7 > /dev/null || return 1
	$U/sprcnv ../gfx/sprites0.png speccy/sprites.h > /dev/null || return 1
	$U/png2scr ../gfx/loading.png loading.scr > /dev/null || return 1
}
