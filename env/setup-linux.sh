#!/bin/bash
# Instala el entorno de MK1 v3.100 en Linux (x86_64):
#   * FreeBASIC 1.10.1  -> /usr/local (necesita root)
#   * GBDK-2020 4.3.0   -> $TOOLS/gbdk (su SDCC compila el motor)
# y genera $TOOLS/mk1env.sh, que hay que "source"-ar antes de compilar.
#
# Uso: env/setup-linux.sh [TOOLS_DIR]   (por defecto ~/mk1tools)

set -e
ENV_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOLS="${1:-$HOME/mk1tools}"
mkdir -p "$TOOLS"

# --- FreeBASIC ---------------------------------------------------------------
if ! command -v fbc >/dev/null; then
	tar xf "$ENV_DIR/FreeBASIC-1.10.1-linux-x86_64.tar.xz" -C "$TOOLS"
	(cd "$TOOLS/FreeBASIC-1.10.1-linux-x86_64" && ./install.sh -i /usr/local)
fi

# fbc 1.10.1 se enlazó contra libtinfo.so.5, que las distros modernas ya no traen.
# Si falta, compilamos ncurses con ABI 5 (solo libtinfo).
if ! ldconfig -p | grep -q 'libtinfo.so.5 '; then
	echo "* libtinfo.so.5 no encontrada: compilando ncurses (ABI 5)"
	git clone --depth 1 https://github.com/mirror/ncurses "$TOOLS/ncurses"
	(cd "$TOOLS/ncurses" && ./configure --with-abi-version=5 --with-shared --with-termlib \
		--with-versioned-syms --without-ada --without-cxx --without-tests --without-progs \
		--without-manpages >/dev/null && make -j"$(nproc)" libs >/dev/null)
	cp -P "$TOOLS"/ncurses/lib/libtinfo.so.5* /usr/local/lib/ && ldconfig
fi

# Las librerías X de fbgfx: basta con que existan los .so (el modo gráfico que
# usan las utilidades es el driver nulo, pero fbc enlaza con ellas igualmente).
for l in Xpm Xrandr GL; do
	so=$(ls /usr/lib/x86_64-linux-gnu/lib$l.so.* 2>/dev/null | head -1)
	[ -n "$so" ] && [ ! -e /usr/lib/x86_64-linux-gnu/lib$l.so ] && ln -s "$so" /usr/lib/x86_64-linux-gnu/lib$l.so
done

# --- GBDK-2020 -----------------------------------------------------------------
[ -x "$TOOLS/gbdk/bin/sdcc" ] || tar xzf "$ENV_DIR/gbdk-linux64.tar.gz" -C "$TOOLS"

echo "export GBDK_HOME=\"$TOOLS/gbdk\"" > "$TOOLS/mk1env.sh"

echo "Listo. Ahora:  source $TOOLS/mk1env.sh  &&  src/utils/build-linux.sh"
