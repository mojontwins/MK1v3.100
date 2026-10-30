#!/bin/sh
# usage: matrix.sh <msc4 binary> <outdir> [extra msc4 args...]
# Runs msc4 over every shipped script + a synthetic "all opcodes" script with several option
# combinations; the outputs (.bin, interpreter, text) are what the regression test compares.
M=$1; OUT=$2; shift 2
HERE=$(cd "$(dirname "$0")" && pwd)
R=/home/claude/mojontwins/mk1v32/games
rm -rf "$OUT"; mkdir -p "$OUT"
run() {  # name script
  for t in zx cpc; do
    for mode in jt idx noidx jtall idxall; do
      case $mode in
        jt) opts="jumptable";;
        idx) opts="rooms=20";;
        noidx) opts="noindexed fastnpant";;
        jtall) opts="jumptable allopcodes";;
        idxall) opts="rooms=20 allopcodes fastnpant";;
      esac
      d="$OUT/$1-$t-$mode"; mkdir -p "$d"; cp "$2" "$d/script.spt"
      (cd "$d"; "$M" in=script.spt v=3 target=$t interpreter=msc4i.asm text=text.bin $opts "$@" >log.txt 2>&1; echo "exit=$?" >> log.txt)
    done
  done
}
for g in papaya ababol cosmonautic calavera perils tb; do run $g $R/$g/script/script.spt; done
run all "$HERE/all/all.spt"
