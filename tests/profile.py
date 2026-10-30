#!/usr/bin/env python3
# Resume un perfil de zxrun (-prof) por símbolos del .map.
# Uso: tests/profile.py perfil.bin juego.map [N]
import sys, re, struct, bisect
prof = struct.unpack('<65536I', open(sys.argv[1], 'rb').read())
syms = sorted(set((int(m.group(2), 16), m.group(1)) for l in open(sys.argv[2])
	for m in [re.match(r'(\S+)\s*= ([0-9A-F]+), [GL]', l)] if m))
addrs = [a for a, _ in syms]
tot = {}
for a, c in enumerate(prof):
	if not c: continue
	if a < 0x4000: name = '(ROM)'
	else:
		i = bisect.bisect_right(addrs, a) - 1; name = syms[i][1] if i >= 0 else '?'
		if not name.startswith('_') and not name.isupper(): name = name
	tot[name] = tot.get(name, 0) + c
T = sum(tot.values())
for name, c in sorted(tot.items(), key=lambda x: -x[1])[:int(sys.argv[3]) if len(sys.argv) > 3 else 30]:
	print('%6.2f%%  %-28s %d' % (100.0 * c / T, name, c))
