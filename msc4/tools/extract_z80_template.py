#!/usr/bin/env python3
"""One-off: derive targets/z80.tpl from the interpreter generator embedded in the ORIGINAL msc4.bas.

The generator was a run of `writeAssemblyString fOut, "..."` calls, many guarded by
`If CU(&H01) Then` and friends.  Each call becomes one *chunk* of the template, keeping the guard
as a `;@ when` expression.  Kept in the repo as provenance (and to regenerate the template if the
original generator is ever patched)."""
import re, sys

src = open(sys.argv[1], encoding='utf-8').read().split('\n')
start = next(i for i, l in enumerate(src) if 'writeAssemblyString fOut, "defc PLAYER_LIFE' in l)
end = next(i for i, l in enumerate(src) if l.strip() == 'Close #fOut' and i > start)

chunks = []          # (cond, text)  text uses '|' as the line separator
ctx = None           # None | 'jumptable' | '!jumptable'
i = start
GUARD = re.compile(r'^\s*[Ii][Ff]\s+(.*?)\s+[Tt]hen\s+writeAssemblyString fOut, (.*?)\s*$')
PLAIN = re.compile(r'^\s*writeAssemblyString fOut, (.*?)\s*$')
VARS = {'itemSlot': 'ITEM_SLOT', 'itemEmpty': 'ITEM_EMPTY', 'ENTERING_INDEX_OFFSET': 'ENTERING_INDEX_OFFSET'}


def literal(expr):
    """A FreeBASIC string expression made of literals and a few known variables -> template text."""
    out, pos = '', 0
    expr = expr.strip()
    while pos < len(expr):
        if expr[pos] == '"':
            end = expr.index('"', pos + 1)
            out += expr[pos + 1:end]; pos = end + 1
        elif expr[pos] == '&' or expr[pos].isspace():
            pos += 1
        else:
            m = re.match(r'\w+', expr[pos:])
            name = m.group(0)
            if name not in VARS:
                raise SystemExit('unknown variable in generator string: ' + name)
            out += '{%s}' % VARS[name]; pos += len(name)
    return out


def atom(s):
    m = re.match(r'(AU|CU|RV|LV)\s*\(&H([0-9A-Fa-f]+)\)', s.strip())
    return '%s:%s' % (m.group(1).lower(), m.group(2).upper())


def cond_expr(expr):
    parts = re.split(r'\s+[Oo]r\s+', expr)
    return '|'.join(atom(p) for p in parts)


def add(cond, text):
    conds = [c for c in (ctx, cond) if c]
    chunks.append((','.join(conds), text))


while i < end:
    l = src[i]
    s = l.strip()
    if s.startswith("'") or s == '' or s == "''":
        i += 1; continue
    if s == 'If jumptable Then':
        ctx = 'jumptable'; i += 1; continue
    if s == 'Else' and ctx == 'jumptable':
        ctx = '!jumptable'; i += 1; continue
    if s == 'End If' and ctx:
        ctx = None; i += 1; continue
    if s.startswith('isEntering = -1'):
        # the jump table loop: becomes a foreach construct (hand written below)
        chunks.append(('jumptable', '@FOREACH'))
        while not src[i].strip().startswith('Next i'):
            i += 1
        i += 1; continue
    if s.startswith('If AU(&HE1) Then') and not GUARD.match(l):
        # SHOW: two variants selected by target
        j = i + 1
        variants = []
        while src[j].strip() != 'End If' or len(variants) < 2:
            m = PLAIN.match(src[j])
            if m:
                variants.append(literal(m.group(1)))
            j += 1
            if len(variants) == 2 and src[j].strip() == 'End If':
                break
        chunks.append(('au:E1,speccy', variants[0]))
        chunks.append(('au:E1,cpc', variants[1]))
        while src[j].strip() != 'End If' or not src[j + 1].strip().startswith('If AU(&HE2)'):
            j += 1
        i = j + 1; continue
    if s.startswith('If outT = SPECCY Then'):
        m1 = PLAIN.match(src[i + 1]); m2 = PLAIN.match(src[i + 3])
        chunks.append(('speccy', literal(m1.group(1)))); chunks.append(('cpc', literal(m2.group(1))))
        assert src[i + 2].strip() == 'Else' and src[i + 4].strip() == 'End If'
        i += 5; continue
    m = GUARD.match(l)
    if m:
        add(cond_expr(m.group(1)), literal(m.group(2))); i += 1; continue
    m = PLAIN.match(l)
    if m:
        add('', literal(m.group(1))); i += 1; continue
    raise SystemExit('unhandled generator line %d: %s' % (i + 1, l))

out = ['; MSC4 interpreter template - target family: z80 (z88dk ZX Spectrum / Amstrad CPC)',
       ';',
       '; Generated once from the interpreter generator that used to be embedded in msc4.bas (see',
       '; tools/extract_z80_template.py); from now on THIS file is the source of the Z80 interpreter.',
       ';',
       '; Format: every chunk starts with a ";@" directive and ends at the next one.  A chunk is written',
       '; to the interpreter file only when its "when" expression holds.  Expression: terms separated',
       '; by "," (AND); inside a term, atoms separated by "|" (OR); "!" negates an atom.  Atoms:',
       ';   jumptable speccy cpc gb   - command line / target',
       ';   cu:XX au:XX rv:XX lv:XX   - the script uses condition/action/rvalue/lvalue opcode XX (hex)',
       '; Lines of a chunk are indented by msc4 itself (labels ".x" and comments ";" start in column 0).',
       '; {ENTERING_INDEX_OFFSET} {ITEM_SLOT} {ITEM_EMPTY} are substituted.  ";@ foreach jt" ... ";@ end" repeats its chunks',
       '; (separated by ";@ next") for each jump-table entry, with {comment} {offs4} {index} substituted.',
       '']


def emit_chunk(cond, text):
    out.append(';@ when ' + cond if cond else ';@ always')
    for ln in text.split('|'):
        out.append(ln if ln[:1] in ('.', ';') or ln == '' else '\t' + ln)


for cond, text in chunks:
    if text == '@FOREACH':
        out.append(';@ foreach jt when jumptable')
        out.append('; {comment}')
        out.append(';@ next')
        out.append('\tld  hl, 0x{offs4}')
        out.append('\tcp  {index}')
        out.append('\tret z')
        out.append(';@ end')
        continue
    emit_chunk(cond, text)
open(sys.argv[2], 'w', encoding='utf-8', newline='\n').write('\n'.join(out) + '\n')
print('chunks:', len(chunks))
