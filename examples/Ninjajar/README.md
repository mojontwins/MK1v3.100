# Ninjajar (ZX Spectrum 128K)

Ninjajar (The Mojon Twins, 2014) portado a MK1 v3.100. Es el juego más grande
hecho con este motor: 24 niveles (19 mapas, algunos repetidos, como la
tienda), scripts con cientos de diálogos, un mapa del mundo, contraseñas,
niveles nadando, lava que sube, cinemáticas y créditos.

El original era un fork de la Churrera 3.99 con muchas cosas hechas a mano.
Para portarlo, el motor y msc4 han ganado lo que hacía falta (ver
`docs/manual.md`, capítulos 6, 9 y 10, y `docs/msc4.md`) y aquí solo queda lo
que es del juego.

## Compilar

Con GBDK-2020 en `C:\gbdk` (ver el capítulo 0 del manual), en una ventana de
comandos:

```bat
cd "C:\ruta\al\repositorio\examples\Ninjajar"
make.bat
```

Deja `ninjajar.tap`, para un Spectrum 128K. `make.bat noclean` deja los
ficheros intermedios en `build\dev`. (En Linux: `./make.sh`.)

## Controles

M D A S N (fuego, derecha, izquierda, abajo, arriba); W también sube nadando.
O un joystick Kempston o Sinclair. FIRE da puñetazos, ARRIBA salta y ABAJO
habla con los personajes y usa las cosas. H pausa, Y abandona.

## Qué hay aquí

| | |
|---|---|
| `dev/config.h` | La configuración del motor para Ninjajar (la física del original por 4: el motor va en 1/256 de píxel y el original en 1/64). |
| `dev/custom.h` | El código propio: dedicatoria, menú y contraseñas, mapa del mundo, lava, el "¡ay!" al morir, "zone clear", "game over", final y créditos. |
| `dev/extern.h` | Lo que llaman los scripts: el recuadro de los diálogos (`TEXT BOX`), la cortina y las cinemáticas. |
| `dev/levelset.h` | La secuencia de niveles: bundle, tileset, spriteset, música y script de cada uno. |
| `dev/levels.bat` (`levels.sh`) | Construye los niveles, tilesets, spritesets, scripts y pantallas. |
| `dev/scripts.txt` | Los scripts, que msc4 compila juntos. |
| `dev/librarian.txt` | Los recursos que van en las páginas de RAM. |
| `dev/game.bat`, `dev/convert.bat` | El nombre del juego y la conversión del tileset base, los sprites y la pantalla de carga (en Linux, `game.sh`). |
| `script/` | Un script por nivel (los que tienen). |
| `texts/credits.bin` | Los créditos, en líneas de 32 caracteres (`credits.txt` es el texto). |
| `gfx/`, `map/`, `enems/`, `levels/` | Gráficos, mapas (Mappy), enemigos (`.ene`) y comportamientos de cada mapa. |
| `ogt/zx128/` | El WYZ player del original (con las canciones comprimidas con aPLib y el sample del "¡ay!"), las canciones, los instrumentos y los efectos. |

## Cómo está hecho

* **Niveles.** `levels.sh` construye un bundle por mapa con `buildlevel`,
  que lleva también el motor del nivel (`engine=1` en los que se nada) y
  hacia dónde mira el ninja al empezar. Los tilesets de los niveles no
  llevan la fuente (`ts2bin nofont`, `LEVEL_TILESETS_NO_FONT`). `levelset.h`
  es la secuencia del original: `level` (y `LEVEL` en los scripts, `WARP TO
  LEVEL` y las contraseñas) es la posición en ella.
* **Scripts.** El script original (un solo fichero para MSC3, con los
  textos aparte) se pasó una vez a msc4: un `.spt` por nivel con los textos
  dentro (`TEXT BOX`). Los textos van en un recurso sin comprimir
  (`SCRIPT_TEXTS_AS_RESOURCE`, `text.bin` en `librarian.txt`): son 11 KB que
  no caben en la RAM. En la fuente, la Ñ es `<` y las comillas `;` (están
  dibujadas ahí).
* **Música y efectos.** El juego trae su propio `wyzplayer.asm` (el del
  original) y comp-zx lo usa en lugar del del motor. Su tabla de efectos
  hace que los números de MK1 suenen con los efectos de Ninjajar; los de
  Ninjajar tal cual son los 15 a 24 (`SOUND n` del script original es `SOUND
  15 + n`).
* **Las cinemáticas del final** las hace el script (una `SUB ENDING` antes
  de `GAME ENDING`) con `EXTERN 1`, `EXTERN 2, n` y `TEXT BOX`.
