#!/usr/bin/env python3
# Recorta un mapa de Mappy (.map) y su .ene a una ventana de pantallas.
# Uso: crop.py mapa.map enems.ene x0 y0 w h salida.map salida.ene [2bytes]
import sys
mp, ene, x0, y0, w, h, omp, oene = sys.argv[1:9]
x0, y0, w, h = map(int, (x0, y0, w, h))
two = len(sys.argv) > 9 and sys.argv[9] == '2bytes'
e = open(ene, 'rb').read()
W, H, n = e[256], e[257], e[260]
m = open(mp, 'rb').read()
out = bytearray()
for y in range(y0 * 10, (y0 + h) * 10):
	out += m[y * W * 15 + x0 * 15: y * W * 15 + (x0 + w) * 15]
open(omp, 'wb').write(out)
hdr = bytearray(e[:261]); hdr[256] = w; hdr[257] = h
enems = e[261:261 + W * H * n * 8]; hs = e[261 + W * H * n * 8:]
hsz = 2 if two else 3
o = bytearray(hdr)
for yy in range(y0, y0 + h):
	for xx in range(x0, x0 + w):
		p = yy * W + xx; o += enems[p * n * 8:(p + 1) * n * 8]
for yy in range(y0, y0 + h):
	for xx in range(x0, x0 + w):
		p = yy * W + xx; o += hs[p * hsz:(p + 1) * hsz]
open(oene, 'wb').write(o)
