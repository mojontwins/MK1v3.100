#!/bin/bash
# Instala el entorno de MK1 v3.100 en Linux (x86_64):
#   * FreeBASIC 1.10.1  -> /usr/local (necesita root)
#   * z88dk 1.10        -> $TOOLS/z88dk (compilado desde fuente)
# y genera $TOOLS/z88env.sh, que hay que "source"-ar antes de compilar.
#
# Uso: env/setup-linux.sh [TOOLS_DIR]   (por defecto ~/mk1tools)

set -e
ENV_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="$(dirname "$ENV_DIR")"
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

# --- z88dk 1.10 --------------------------------------------------------------
Z="$TOOLS/z88dk"
if [ ! -x "$Z/bin/zcc" ]; then
	tar xzf "$ENV_DIR/z88dk-1.10.1.tgz" -C "$TOOLS"
	(
		cd "$Z" && mkdir -p bin
		export PATH="$Z/bin:$PATH" Z80_OZFILES="$Z/lib/" ZCCCFG="$Z/lib/config/"
		# Código C de 2009: hay que pedirle a gcc moderno que sea tolerante.
		export CC=gcc CFLAGS="-g -O2 -std=gnu89 -fcommon -w -fpermissive" CCOPT=-DUNIX
		make -e && make -C libsrc && make -C libsrc install
	)
fi

# crt0 recortado de MK1 (solo coloca la pila y salta a main), para ZX y CPC
[ -f "$Z/lib/spec_crt0.asm.stock" ] || cp "$Z/lib/spec_crt0.asm" "$Z/lib/spec_crt0.asm.stock"
cp "$REPO/lib/spec_crt0.asm" "$Z/lib/spec_crt0.asm"
# El de CPC es igual (ld sp, $FFFF / jp _main); el de serie de z88dk guarda
# el estado del firmware y baja la pila 6,5K, lo que choca con el mapa de MK1.
[ -f "$Z/lib/cpc_crt0.asm.stock" ] || cp "$Z/lib/cpc_crt0.asm" "$Z/lib/cpc_crt0.asm.stock"
sed 's/MODULE  zx82_crt0/MODULE  cpc_crt0/' "$REPO/lib/spec_crt0.asm" > "$Z/lib/cpc_crt0.asm"

# Librerías de los backends
cp "$REPO/lib/splib2/splib2f.lib" "$Z/lib/clibs/splib2f.lib"
cp "$REPO/lib/splib2/splib2f.lib" "$Z/lib/clibs/splib2.lib"
cp "$REPO/lib/splib2/spritepack.h" "$Z/include/"
cp "$REPO"/lib/cpcrslib-mt/*.lib "$Z/lib/clibs/"
cp "$REPO/lib/cpcrslib-mt/cpcrslib_mt.h" "$Z/include/"

cat > "$TOOLS/z88env.sh" <<EOF
export Z88DK="$Z"
export PATH="$Z/bin:\$PATH"
export Z80_OZFILES="$Z/lib/"
export ZCCCFG="$Z/lib/config/"
EOF

echo "Listo. Ahora:  source $TOOLS/z88env.sh  &&  src/utils/build-linux.sh"
