# MK1v3.100

Frozen version from early 2014, the last version of MK1 in pure C, preserved for posterity, and for educational purposes.


## Documentation (Spanish)

* [`docs/manual.md`](docs/manual.md): the MK1 v3.100 manual.
* [`docs/msc4.md`](docs/msc4.md): the MSC4 scripting language.
* [`docs/formato-niveles.md`](docs/formato-niveles.md): the level format.
* [`docs/tecnico.md`](docs/tecnico.md): technical notes (engine internals, tests).
* [`examples/Goku Mal 128`](examples/Goku%20Mal%20128): a 128K game with five levels.

The engine is built with SDCC, from GBDK-2020 (only its compiler, assembler
and linker are used).

Quick start (Windows): unzip `env/gbdk-win64.zip` to `C:\` (you get
`C:\gbdk`), open a command window, `cd src\dev` and run `comp-zx.bat` (or
`comp-cpc.bat`).

Linux: `env/setup-linux.sh`, `source ~/mk1tools/mk1env.sh`,
`src/utils/build-linux.sh`, then `cd src/dev && ./comp-zx.sh`.
