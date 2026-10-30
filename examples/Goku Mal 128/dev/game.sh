# game.sh de Goku Mal: lo lee comp-zx.sh (ver src/dev/comp-zx.sh).
game=gokumal

# Gráficos que no van en los niveles. El tileset y los sprites del binario
# son los del nivel 1; cada nivel carga los suyos como recursos (levels.sh).
convert_assets () {
	$U/ts2bin ../gfx/font.png ../gfx/work1.png ts.bin 7 > /dev/null || return 1
	$U/sprcnv ../gfx/sprites1.png speccy/sprites.h > /dev/null || return 1
	$U/png2scr ../gfx/loading.png loading.scr > /dev/null || return 1
	# Pantallas completas (title, final, zonas, cinemáticas, logos)
	for s in title ending zoneA zoneB intro1 intro2 intro3 intro4 intro5 intro6 intro7 logo controls dedicado; do
		$U/png2scr ../gfx/$s.png $s.scr > /dev/null || return 1
		rm -f $s.bin; $U/zx0 $s.scr $s.bin > /dev/null || return 1
	done
	# Tileset con los números grandes de la pantalla de zona
	rm -f leveltsc.bin; $U/zx0 ../gfx/levelts.bin leveltsc.bin > /dev/null
}
