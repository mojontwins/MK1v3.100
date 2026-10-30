# MTE MK1 v3.100 — Manual

Copyleft 2010-2014, 2026 by The Mojon Twins

## Qué es este documento

Es el manual de **MTE MK1 v3.100** ("la Churrera"), el motor de juegos para
ZX Spectrum 48K / 128K y Amstrad CPC que vive en este repositorio. Está
escrito a partir del tutorial de MK1 (`docs/MK1.pdf`), del histórico de
cambios de la rama 3.99 (`docs/whatsnew.txt`) y, sobre todo, del código: si
algo de aquí no coincide con `src/dev`, **manda el código**.

El tutorial de `MK1.pdf` es de una versión posterior (MK1 5.0, 2020): muchos
conceptos son los mismos, pero los nombres de fichero, varias directivas, el
scripting (MSC3) y los *code injection points* no lo son. Este manual cuenta
cómo es la v3.100 tal y como está ahora.

| Capítulo | Qué cuenta |
|---|---|
| [0](#capítulo-0---antes-de-empezar) | Instalar el entorno, la estructura del repositorio, hacer un güego nuevo. |
| [1](#capítulo-1---el-tileset) | El tileset y el comportamiento de los tiles. |
| [2](#capítulo-2---el-mapa) | El mapa. |
| [3](#capítulo-3---los-sprites) | Los sprites. |
| [4](#capítulo-4---las-pantallas-fijas) | Título, marco, final y pantalla de carga. |
| [5](#capítulo-5---enemigos-y-hotspots) | Enemigos y *hotspots*. |
| [6](#capítulo-6---configurando-el-güego) | `config.h`, directiva por directiva. |
| [7](#capítulo-7---música-y-sonido) | Música y efectos. |
| [8](#capítulo-8---el-scripting-msc4) | El scripting (MSC4). |
| [9](#capítulo-9---código-propio-customh-y-externh) | Código propio: `custom.h` y `extern.h`. |
| [10](#capítulo-10---zx-spectrum-128k-y-juegos-con-niveles) | 128K y juegos de varios niveles. |
| [11](#capítulo-11---amstrad-cpc) | Amstrad CPC. |
| [12](#capítulo-12---las-herramientas) | Referencia de las herramientas. |
| [13](#capítulo-13---probar-el-motor) | Probar el motor (emuladores y pruebas). |
| [A](#apéndice-a---qué-cambia-la-v3100) | Qué cambia la v3.100 respecto a la 3.99. |
| [B](#apéndice-b---mapa-de-memoria) | Mapa de memoria. |

Otros documentos:

* [`msc4.md`](msc4.md): la especificación completa del lenguaje de scripts
  (el [§19](msc4.md#19-mk1-v3100-el-intérprete-en-c) es lo propio de v3.100).
* [`formato-niveles.md`](formato-niveles.md): el formato de los niveles.
* [`lib-splib2.md`](lib-splib2.md), [`lib-cprslib.md`](lib-cprslib.md): las
  librerías gráficas de ZX y CPC.
* `examples/Goku Mal 128/README.md`: un juego de 128K con cinco niveles.

---

# Capítulo 0 - Antes de empezar

## Qué es MK1

MK1 es un *framework* para hacer juegos de habitaciones fijas (*flick
screen*) de 15x10 tiles de 16x16: plataformas (vista lateral) o aventuras
vistas desde arriba (la "vista genital"). Se compone de:

1. **El motor**, en C (z88dk) con algo de ensamblador. Se gobierna con un
   archivo, `config.h`, en el que se dice qué partes del motor usa el güego y
   cómo se comportan.
2. **Las herramientas de conversión**, que convierten los gráficos (png), el
   mapa (Mappy), los enemigos (el `ponedor`) y los scripts en datos del güego.
3. **El scripting** (MSC4), para lo que no se puede hacer sólo configurando.
4. **El código propio** (`custom.h`, `extern.h`), para lo que no se puede
   hacer ni con lo anterior.

Lo que el motor sabe hacer sin tocar nada: movimiento con inercia
configurable; vista lateral (saltar, saltar siempre a lo Bootee, jetpac) o
vista genital; llaves y cerrojos; bloques empujables; disparos (en vista
lateral, también hacia arriba y en diagonal); muros rompibles; enemigos
lineales, plataformas móviles, voladores (*fanties*), perseguidores y un tipo
"custom" de ejemplo; tiles que matan y tiles que esconden; objetos
coleccionables, recargas de vida, de munición y de tiempo; temporizador;
puntos de control (*checkpoints*); tiles animados; sombras automáticas; pausa;
y, en 128K, música AY y varios niveles.

## Instalar el entorno (Linux)

```sh
env/setup-linux.sh [directorio]     # FreeBASIC, z88dk 1.10, librerías, crt0
source ~/mk1tools/z88env.sh         # (o el directorio que le hayas dado)
src/utils/build-linux.sh            # compila todas las utilidades en src/utils/linux
```

`env/setup-linux.sh` instala FreeBASIC 1.10, compila z88dk 1.10 (el compilador
`sccz80` con el que se hizo la Churrera), instala `splib2` (ZX) y
`cpcrslib_mt` (CPC) y el `crt0` mínimo del motor (`ld sp,$FFFF : jp _main`), y
escribe `z88env.sh` con las variables de entorno.

`src/utils/build-linux.sh` compila las utilidades de FreeBASIC (`mapcnv`,
`ene2h`, `ts2bin`, `sprcnv`, `png2scr`, `buildlevel`, `librarian`,
`mkts_om`…), el compilador de scripts `msc4` (desde `msc4/`) y las externas en
C (`zx0`, `zx7`, `apultra`, `pasmo`, `bas2tap`, `bin2tap`, `cpc2cdt`,
`cpctbin2sna`). Todo queda en `src/utils/linux/`.

En Windows siguen estando los `.exe` y los `comp-zx.bat` / `comp-cpc.bat`
originales, pero el camino mantenido es el de Linux (`comp-zx.sh`,
`comp-cpc.sh`): los `.bat` no compilan los scripts, ni los niveles, ni el
modo 128K.

## La estructura del repositorio

```
src/                 <- el esqueleto de un güego (el ejemplo es Bootee)
  dev/               <- el motor y la configuración del güego
    config.h         <- la configuración (capítulo 6)
    custom.h         <- tu código: ganchos del motor (capítulo 9)
    extern.h         <- tu código: EXTERN, TEXT BOX y DIALOG del script
    comp-zx.sh       <- compila para ZX Spectrum
    comp-cpc.sh      <- compila para Amstrad CPC
    churromain.c     <- el programa principal (incluye todo lo demás)
    engine.h         <- el motor
    mainloop.h       <- el bucle principal
    msc.h            <- el intérprete de scripts
    levels.h         <- el sistema de niveles
    speccy/          <- lo específico de ZX (impresión, sprites, beeper...)
    speccy_128/      <- lo específico de ZX 128K (paginación, WYZ player)
    cpc/             <- lo específico de CPC
  gfx/speccy/        <- gráficos de ZX (png)
  gfx/cpc/           <- gráficos de CPC (png)
  map/               <- el mapa (mapa.fmp de Mappy y mapa.map exportado)
  enems/             <- los enemigos y hotspots (enems.ene)
  ogt/               <- la música (CPC, y zx128/ para ZX 128K)
  script/            <- el script (script.spt), si lo hay
  utils/             <- las herramientas (linux/ las compiladas para Linux)
msc4/                <- el compilador de scripts
examples/            <- juegos de ejemplo (Goku Mal 128)
tests/               <- pruebas: emuladores, matriz de configuraciones...
env/                 <- instalación del entorno
docs/                <- la documentación
```

## Compilar el ejemplo

```sh
cd src/dev
./comp-zx.sh        # bootee.tap
./comp-cpc.sh       # bootee.sna y bootee.cdt
```

`comp-zx.sh` convierte los gráficos, el mapa y los enemigos, compila el
script (si `config.h` define `ACTIVATE_SCRIPTING`), construye los niveles (si
hay un `levels.sh`), en 128K ensambla el reproductor de música y reparte los
recursos en las páginas de RAM, compila con `zcc` y monta la cinta. Opciones:
`justcompile` (sólo compilar, sin convertir) y `noclean` (deja los
intermedios). `comp-cpc.sh` hace lo mismo para CPC.

## Hacer un güego nuevo

1. Copia `src/` entero con el nombre de tu güego.
2. Sustituye los recursos: `gfx/`, `map/`, `enems/`, `ogt/`, `script/`.
3. En `dev/comp-zx.sh` (y `comp-cpc.sh`) cambia `game=bootee` por el nombre
   de tu güego y ajusta las llamadas a los conversores a tu mapa (el tamaño
   del mapa va en la llamada a `mapcnv`). O, mejor, deja el script como está
   y crea un `dev/game.sh` (ver más abajo).
4. Configura `dev/config.h` (capítulo 6).
5. Si hace falta, escribe tu código en `dev/custom.h` y `dev/extern.h`.
6. `./comp-zx.sh`.

### `game.sh`

Si en `dev/` hay un `game.sh`, `comp-zx.sh` lo lee al principio. Puede
cambiar el nombre del güego y definir una función `convert_assets` que
sustituye a la conversión de Bootee (la de los gráficos, mapa y enemigos):

```sh
game=gokumal

convert_assets () {
	$U/ts2bin ../gfx/font.png ../gfx/work1.png ts.bin 7 > /dev/null || return 1
	$U/sprcnv ../gfx/sprites1.png speccy/sprites.h > /dev/null || return 1
	$U/png2scr ../gfx/loading.png loading.scr > /dev/null || return 1
	...
}
```

Así un güego no tiene que tocar `comp-zx.sh`, y se puede actualizar el motor
copiando los ficheros nuevos de `src/dev` sin perder nada. Es lo que hace el
ejemplo de Goku Mal, que ni siquiera tiene una copia del motor: su `make.sh`
copia `src/dev`, pone encima los ficheros del güego y compila.

---

# Capítulo 1 - El tileset

El tileset es la colección de tiles de 16x16 con los que se dibujan las
pantallas. Se dibuja en un png de 256x48 (16 tiles por fila, 3 filas: 48
tiles), siguiendo las restricciones de color del Spectrum (dos colores por
cada cuadro de 8x8). En ZX va en `gfx/speccy/work.png`; en CPC, en
`gfx/cpc/work.png`.

Para la paleta del Spectrum usa valores de R, G, B de 200 para los colores
sin BRIGHT y de 255 para los de BRIGHT.

## 16 o 48 tiles

* **16 tiles** (mapa *packed*, lo normal): el mapa guarda cada tile en 4
  bits, así que ocupa la mitad. Los tiles 0-15 son los del mapa. Permite las
  sombras automáticas y el tile alternativo de fondo.
* **48 tiles** (`UNPACKED_MAP`): el mapa guarda un byte por tile y se pueden
  usar los 48. Sin sombras automáticas ni tile alternativo.

## Los tiles especiales

| Tile | Uso |
|---|---|
| 0 | El fondo principal (por convención). |
| 14 | El bloque empujable, con `PLAYER_PUSH_BOXES`. Su comportamiento debe ser 10. |
| 15 | El cerrojo, si hay llaves. Comportamiento 10. |
| 16 | Recarga de vida (*hotspot* de tipo 3). |
| 17 | Objeto (*hotspot* de tipo 1). |
| 18 | Llave (*hotspot* de tipo 2). |
| 19 | Fondo alternativo: en mapas *packed* el motor pinta a veces el 19 en lugar del 0 (`NO_ALT_TILE` lo desactiva). |
| 20 | Recarga de munición (*hotspot* de tipo 4, `MAX_AMMO`). |
| 21 | Recarga de tiempo (*hotspot* de tipo 5, `TIMER_ENABLE`). |
| 22 | Punto de control (*hotspot* de tipo 6, `ENABLE_CHECKPOINTS`). |
| 32-47 | Con `USE_AUTO_TILE_SHADOWS`: la versión sombreada de los tiles 0-15. |
| 47 | Lo usa `clear_gamearea_tiles ()` para borrar la zona de juego. |

El *hotspot* se pinta con el tile `16 + tipo` (salvo el de tipo 3, que es
el 16).

## El comportamiento de los tiles

Cada tile tiene un comportamiento. Sin niveles se define en
`comportamiento_tiles`, al final de `config.h`; con niveles, en un fichero
`behs.txt` por nivel (capítulo 10).

| Valor | Significado |
|---|---|
| 0 | Traspasable. |
| 1 | Traspasable y **mata** (quita vida al tocarlo). |
| 2 | Traspasable y **esconde**: quieto detrás de él, el jugador está escondido (los fanties le pierden la pista). |
| 4 | **Plataforma**: sólo para al jugador si cae encima (vista lateral). |
| 8 | **Obstáculo**: para al jugador por todos lados. |
| 10 | **Interactuable**: obstáculo especial; los cerrojos (tile 15) y el bloque empujable (tile 14). |
| 16 | **Rompible** con los disparos (`BREAKABLE_WALLS`). Súmale 8 (24) para que además sea obstáculo. |
| 128 | **Especial**: lanza la sección `SPECIAL TILE TOUCHED` del script cuando el centro del jugador está sobre él. Se puede sumar a los demás (132 = especial y plataforma). |

Los valores se suman: el motor comprueba los bits. Un 9 (obstáculo que mata)
no tiene sentido porque no se puede tocar; un 24 (obstáculo rompible) sí.

## Las sombras

* `USE_AUTO_TILE_SHADOWS`: las sombras se dibujan a mano. La fila de abajo
  del tileset (tiles 32-47) tiene la versión "sombreada" de los tiles 0-15, y
  el motor usa esa versión en los tiles que quedan a la sombra de un
  obstáculo.
* `USE_AUTO_SHADOWS`: sombras automáticas oscureciendo los atributos. No
  ocupan tiles, pero se ven peor.

Sólo una de las dos, y sólo con mapas *packed*.

## La fuente y la conversión (ZX)

El motor usa 256 "caracteres" de 8x8: los 64 primeros son la fuente (ASCII
32-95) y los 192 siguientes los trozos de los 48 tiles. La fuente es un png de
256x16 (`gfx/speccy/font.png`). `ts2bin` junta las dos cosas en `ts.bin` (2304
bytes: 2048 de gráficos y 256 de atributos):

```sh
ts2bin ../gfx/speccy/font.png ../gfx/speccy/work.png ts.bin 7
```

El último parámetro es la tinta que se usa cuando un cuadro de 8x8 tiene un
solo color. `ts.bin` lo incluye `speccy/tileset.h`.

En CPC la conversión es con `mkts_om` (capítulo 11).

## El tileset para Mappy

Mappy quiere que el primer tile sea negro. Si tu tile 0 no lo es, Mappy añade
uno y desplaza todos los demás: en ese caso hay que convertir el mapa con
`fixmappy` (capítulo 2). Otra opción es hacer un png aparte para Mappy con un
tile negro delante.

---

# Capítulo 2 - El mapa

El mapa es un rectángulo de `MAP_W` x `MAP_H` pantallas de 15x10 tiles. Se
hace con **Mappy** (la versión modificada de `env/`): tiles de 16x16, un mapa
de `MAP_W * 15` x `MAP_H * 10` tiles. Se guarda en dos formatos:

* `.fmp`: el formato de trabajo de Mappy. Es el que se abre para editar.
* `.map`: el formato que se convierte. Una ristra de bytes, un tile por
  byte, por filas. Guarda siempre los dos.

Cuánto puede ocupar el mapa depende de lo que ocupe todo lo demás. Un mapa
*packed* ocupa 75 bytes por pantalla; uno *unpacked*, 150. Con
`COMPRESSED_LEVELS` el mapa va comprimido en el nivel y en memoria sólo está
el del nivel actual.

## La conversión: `mapcnv`

```sh
mapcnv ../map/mapa.map mapa.h 6 5 15 10 15 packed
```

| Parámetro | Significado |
|---|---|
| `mapa.map` | El mapa exportado de Mappy. |
| `mapa.h` | La salida. |
| `6 5` | `MAP_W` y `MAP_H`: el tamaño del mapa en pantallas. |
| `15 10` | El tamaño de cada pantalla en tiles (siempre 15x10). |
| `15` | El tile de los cerrojos (15; pon uno que no exista, como 99, si no hay llaves). Los cerrojos se guardan aparte, en la tabla `cerrojos`. |
| `packed` | Mapa de 16 tiles (4 bits por tile). Sin `packed`, un byte por tile (`UNPACKED_MAP` en `config.h`). |
| `fixmappy` | Resta 1 a cada tile (si Mappy añadió un tile negro al principio). |

`comp-zx.sh` y `comp-cpc.sh` traen la llamada con los valores de Bootee
(6x5): cámbialos (o usa `game.sh`). `MAP_W` y `MAP_H` en `config.h` tienen que
coincidir.

Como máximo 85 pantallas (`MAP_W * MAP_H <= 85`; el motor usa índices de un
byte para los enemigos, 3 por pantalla).

---

# Capítulo 3 - Los sprites

El motor maneja cuatro sprites de 16x16 (el jugador y tres enemigos) y, si hay
disparos, hasta `MAX_BULLETS` sprites de 8x8 para las balas. Los gráficos están
en el *spriteset*: un png de 256x32 con 16 gráficos de 16x16, cada uno con su
máscara al lado (cada gráfico ocupa 32x16: el sprite y su máscara).

## El orden de los gráficos

**Vista lateral:**

| # | Gráfico |
|---|---|
| 0, 1, 2 | Jugador mirando a la derecha: andando (frames 1, 2, 3); el 1 es también "parado" |
| 3 | Jugador mirando a la derecha, saltando |
| 4, 5, 6 | Jugador mirando a la izquierda: andando |
| 7 | Jugador mirando a la izquierda, saltando |
| 8, 9 | Enemigo de tipo 1 (dos frames) |
| 10, 11 | Enemigo de tipo 2 |
| 12, 13 | Enemigo de tipo 3 |
| 14, 15 | Plataforma móvil (tipo 4) |

La animación de andar es 1, 2, 3, 2, 1… (con
`PLAYER_ALTERNATE_ANIMATION`, 1, 2, 3, 1, 2, 3…). Con `PLAYER_BOOTEE` los
frames son otros: ver `move ()` en `engine.h`.

**Vista genital:**

| # | Gráfico |
|---|---|
| 0, 1 | Jugador mirando a la derecha (dos frames) |
| 2, 3 | Izquierda |
| 4, 5 | Arriba |
| 6, 7 | Abajo |
| 8-15 | Cuatro tipos de enemigos, dos frames cada uno |

## La conversión

```sh
sprcnv ../gfx/speccy/sprites.png speccy/sprites.h [nomask]
```

genera `speccy/sprites.h` (`sprite_1_a` … `sprite_16_c`). `nomask` genera los
sprites sin máscara (para `NO_MASKS`, que los pinta con OR).

## Los sprites extra

La explosión (el sprite 17, cuando muere un enemigo), el sprite vacío (18) y
la bala (19, de 8x8) están en `speccy/extrasprites.h`, escritos como datos
(`defb gráfico, máscara`). Un güego que quiera los suyos sustituye ese fichero
(Goku Mal lo hace). En CPC son pngs: `gfx/cpc/sprites_extra.png` y
`sprites_bullet.png`.

---

# Capítulo 4 - Las pantallas fijas

* **La pantalla de carga** (`loading.png`): sólo se usa en la cinta.
* **El título** (`title.png`): con el menú de control (1 teclado, 2 Kempston,
  3 Sinclair).
* **El marco** (`marco.png`): la pantalla en la que se juega, con la zona de
  juego (30x20 caracteres a partir de `VIEWPORT_X`, `VIEWPORT_Y`) y los
  marcadores.
* **El final** (`ending.png`).

Son pngs de 256x192 que se convierten a pantallas de Spectrum (`png2scr`) y
se comprimen (`zx0`). Con `DIRECT_TO_PLAY` el título **es** el marco: el
juego empieza sobre la pantalla de título y no hay `marco.png`, lo que ahorra
una pantalla comprimida. Bootee lo hace así.

```sh
png2scr ../gfx/speccy/title.png title.scr
zx0 title.scr title.bin
```

En 48K las pantallas comprimidas van dentro del binario (`pantallas.h`). En
128K son recursos en las páginas de RAM (`RES_TITLE`, `RES_MARCO`,
`RES_ENDING`, capítulo 10).

## Los marcadores

Se colocan con coordenadas de **carácter** en `config.h` (sección III):

| Directivas | Qué muestra |
|---|---|
| `LIFE_X`, `LIFE_Y` | La vida. |
| `OBJECTS_X`, `OBJECTS_Y` | Los objetos (si no `DEACTIVATE_OBJECTS`). Con `ONLY_ONE_OBJECT` y scripting, `OBJECTS_ICON_X/Y` dibuja un icono. |
| `KEYS_X`, `KEYS_Y` | Las llaves (si no `DEACTIVATE_KEYS`). |
| `KILLED_X`, `KILLED_Y` | Los enemigos muertos (`PLAYER_SHOW_KILLS`). |
| `AMMO_X`, `AMMO_Y` | La munición (`MAX_AMMO`). |
| `TIMER_X`, `TIMER_Y` | El temporizador (`PLAYER_SHOW_TIMER`). |
| `ITEM_X`, `ITEM_Y` | El objeto que se lleva (`GET ITEM SET` del script). |
| `LINE_OF_TEXT`, `LINE_OF_TEXT_X` | La línea de `TEXT "..."` del script. |

Un marcador con la X a 99 no se pinta: es la forma de tener un contador sin
mostrarlo (por ejemplo, objetos que cuentan para ganar pero que no se ven).

---

# Capítulo 5 - Enemigos y *hotspots*

En cada pantalla puede haber hasta **tres enemigos** y **un *hotspot***. Para
MK1, las plataformas móviles también son enemigos (cuentan para el máximo de
tres).

## Los tipos de enemigos

| Tipo | Comportamiento | Gráfico |
|---|---|---|
| 1, 2, 3 | **Lineal**: va de un punto a otro y vuelve. Si los dos puntos no están en la misma fila o columna, se mueve en diagonal rebotando dentro del rectángulo que forman. | Sprites 8-9, 10-11, 12-13 |
| 4 | Vista lateral: **plataforma móvil** (horizontal o vertical; el jugador se sube y le arrastra). Vista genital: un cuarto enemigo lineal. | 14-15 |
| 5 | **Fanty** (`ENABLE_RANDOM_RESPAWN`): enemigo volador que persigue al jugador acelerando y atraviesa el escenario. Normalmente no se colocan: aparecen solos en lugar de los enemigos muertos (1 de cada 32 frames por enemigo muerto). | El del tipo 3 |
| 6 | **Custom** (`ENABLE_CUSTOM_TYPE_6`): el ejemplo es un volador que, si el jugador está a menos de `SIGHT_DISTANCE` píxeles, le persigue, y si no, vuelve a su sitio (los murciélagos de Cheril the Goddess, los cerebros de Goku Mal). | `TYPE_6_FIXED_SPRITE` (el número del enemigo menos 1) |
| 7 | **Perseguidor** (`ENABLE_PURSUERS`): sale de su sitio y va a por el jugador sin atravesar el escenario; si muere, vuelve a salir al rato (`DEATH_COUNT_EXPRESSION` frames). | Al azar, o `TYPE_7_FIXED_SPRITE` |

La velocidad de los lineales y las plataformas va en píxeles por frame: 1, 2 o
4 (potencias de dos; otros valores dan problemas). Los fanties y los de tipo 6
usan `FANTY_MAX_V` y `FANTY_A` (en 1/256 de píxel por frame).

Los enemigos se pueden matar pisándolos (`PLAYER_KILLS_ENEMIES`) o
disparándoles (`PLAYER_CAN_FIRE`). Con `ENEMS_LIFE_GAUGE` aguantan varios
disparos. `PLAYER_MIN_KILLABLE` / `FIRE_MIN_KILLABLE` limitan qué tipos se
pueden matar.

Con `WALLS_STOP_ENEMIES`, los lineales se paran contra los obstáculos (y
contra todo lo que no sea traspasable con `EVERYTHING_IS_A_WALL`).

## Los *hotspots*

Una casilla por pantalla donde hay algo que coger:

| Tipo | Tile | Qué es |
|---|---|---|
| 1 | 17 | Objeto: suma 1 a `player.objs`. |
| 2 | 18 | Llave: suma 1 a `player.keys`. Con llaves, tocar un cerrojo (tile 15) gasta una y lo abre. |
| 3 | 16 | Recarga de vida (`PLAYER_REFILL`). |
| 4 | 20 | Recarga de munición (`MAX_AMMO`, `AMMO_REFILL`). |
| 5 | 21 | Recarga de tiempo (`TIMER_REFILL`). |
| 6 | 22 | Punto de control (`ENABLE_CHECKPOINTS`). |

Las recargas de vida tienen dos lógicas:

* Por defecto, una vez cogido el objeto o la llave de una pantalla, cada vez
  que se vuelve a entrar en ella hay una posibilidad entre cuatro de que
  aparezca una recarga de vida en su lugar.
* Con `USE_HOTSPOTS_TYPE_3`, las recargas aparecen sólo donde las pongas
  (*hotspots* de tipo 3).

Como sólo hay un *hotspot* por pantalla, el total de objetos y llaves no
puede pasar del número de pantallas. Planea cuántos cerrojos vas a poner.

Con `ONLY_ONE_OBJECT` sólo se puede llevar un objeto: si ya se lleva uno, el
*hotspot* no desaparece.

## El `ponedor`

Los enemigos y *hotspots* se colocan con el `ponedor` (`src/utils/ponedor.exe`,
Windows), que lee el mapa y el tileset:

```
ponedor.exe enems.ene                       # editar
ponedor.exe new out=enems.ene map=mapa.map tiles=work.png size=6,5 scrsize=15,10 [adjust=1]
```

`scrsize=15,10` es obligatorio para MK1 (por defecto son 16x12). `adjust=1`
si Mappy añadió un tile negro. Un clic en una casilla empieza un enemigo
(pide el tipo); otro clic, donde acaba su trayectoria (pide la velocidad en
`Attr`). Para los tipos 5, 6 y 7 sólo importa la casilla de inicio. Los
*hotspots* se ponen con el botón derecho. La parte de arriba de la ventana
dice `2b` o `3b`: el formato de los *hotspots* en el `.ene` (2 o 3 bytes); la
tecla `L` lo cambia.

## La conversión: `ene2h`

```sh
ene2h ../enems/enems.ene enems.h 2bytes
```

genera `enems.h` con las tablas `malotes []` (los enemigos) y `hotspots []`.
`2bytes` es para los `.ene` con *hotspots* de 2 bytes (los de Bootee). Con
niveles, los enemigos y *hotspots* van en el bundle del nivel
(`buildlevel`, capítulo 10).

---

# Capítulo 6 - Configurando el güego

Todo el comportamiento del motor se elige en `dev/config.h` con directivas
`#define`. Las que no se usan se dejan comentadas (`//#define`). Además hay un
`config_derived.h` que calcula, a partir de `config.h`, las "banderas" que
usa el motor por dentro (`ENEMIES_CAN_DIE`, `HAS_AY_MUSIC`…); no hay que
tocarlo.

## I. Configuración general

| Directiva | Qué es |
|---|---|
| `MODE_128K` | Compila para ZX Spectrum 128K (capítulo 10). Se ignora en CPC. |
| `MAP_W`, `MAP_H` | Tamaño del mapa en pantallas. Con niveles, el máximo de pantallas de un nivel es `MAP_W * MAP_H`. |
| `SCR_INICIO` | Pantalla de inicio. |
| `PLAYER_INI_X`, `PLAYER_INI_Y` | Casilla de inicio. |
| `SCR_FIN` | Pantalla final (99 = no hay). |
| `PLAYER_FIN_X`, `PLAYER_FIN_Y` | Casilla a la que hay que llegar en la pantalla final. |
| `PLAYER_NUM_OBJETOS` | Objetos que hay que recoger para terminar. |
| `PLAYER_LIFE` | Vida inicial y máxima. |
| `PLAYER_REFILL` | Vida que da cada recarga. |
| `GAME_FRAME_TICKS` | Interrupciones (1/50 s) por frame de juego: 2 = 25 fps fijos. 0 = sin sincronizar, lo más rápido posible (como la 3.99 en 48K). En CPC, el equivalente `MIN_FAPS_PER_FRAME` sale de aquí. |
| `COMPRESSED_LEVELS` | Varios niveles (sólo con `MODE_128K`, capítulo 10). |
| `MAX_LEVELS` | Número de niveles. |
| `REFILL_ME` | Con niveles: recarga la vida al empezar cada nivel. |

**Cómo se gana:** cuando se han recogido `PLAYER_NUM_OBJETOS` objetos (con
niveles, los `max_objs` del nivel) y, si hay pantalla final, se está en su
casilla. El script puede ganar con `WIN GAME`, y un güego puede poner su
propia condición con `HOOK_WIN_CONDITION` (capítulo 9). **Se pierde** al
quedarse sin vida, con `GAME OVER` del script o, con `TIMER_GAMEOVER_0`, al
acabarse el tiempo.

## II. Tipo de motor

### Caja de colisión

| Directiva | Qué es |
|---|---|
| `BOUNDING_BOX_8_BOTTOM` | Caja de 8x8 abajo y centrada en el sprite (lo normal en vista lateral). |
| `BOUNDING_BOX_8_CENTERED` | Caja de 8x8 en el centro (para vista genital). |
| *(ninguna)* | Caja de 16x16. |
| `SMALL_COLLISION` | Colisión con enemigos de 8x8 en lugar de 12x12. |

### Directivas generales

| Directiva | Qué es |
|---|---|
| `PLAYER_CHECK_MAP_BOUNDARIES` | No deja salirse del mapa (si el mapa no tiene paredes en los bordes). |
| `DIRECT_TO_PLAY` | El título es también el marco del juego. |
| `DEACTIVATE_KEYS` | Sin llaves ni cerrojos. |
| `DEACTIVATE_OBJECTS` | Sin objetos. |
| `ONLY_ONE_OBJECT` | Sólo se puede llevar un objeto a la vez. |
| `OBJECT_COUNT` | Con scripting: el flag que cuenta los objetos (en vez de `player.objs`). |
| `DEACTIVATE_EVIL_TILE` | Los tiles de comportamiento 1 no matan. |
| `FULL_BOUNCE` | Al tocar algo que mata, el rebote es de `PLAYER_MAX_VX` (si no, la mitad de la velocidad). |
| `PLAYER_BOUNCES` | Al tocar algo que mata, el jugador rebota. |
| `SLOW_DRAIN` | Con `PLAYER_BOUNCES`: la vida baja 4 veces más despacio. |
| `PLAYER_FLICKERS` | Al tocar algo que mata, el jugador parpadea un rato y es invulnerable (en lugar de rebotar). |
| `MAP_BOTTOM_KILLS` | Salirse del mapa por abajo mata. |
| `WALLS_STOP_ENEMIES` | Los enemigos chocan con el escenario. |
| `EVERYTHING_IS_A_WALL` | Con lo anterior: cualquier tile que no sea 0 es pared (si no, sólo los 8). |
| `ENABLE_PURSUERS` | Enemigos de tipo 7. |
| `DEATH_COUNT_EXPRESSION` | Frames que tarda en volver un perseguidor muerto (p. ej. `20+(rand()&15)`). |
| `TYPE_7_FIXED_SPRITE` | Gráfico fijo para los de tipo 7. |
| `ENABLE_CUSTOM_TYPE_6` | Enemigos de tipo 6. |
| `TYPE_6_FIXED_SPRITE` | Su gráfico (número de enemigo menos 1). |
| `SIGHT_DISTANCE` | Distancia, en píxeles, a la que ven al jugador. |
| `USE_TWO_BUTTONS` | Teclado de dos botones: W A S D, N salta, M dispara. |
| `USE_HOTSPOTS_TYPE_3` | Las recargas de vida sólo salen donde se ponen. |

### Bloques empujables

| Directiva | Qué es |
|---|---|
| `PLAYER_PUSH_BOXES` | El tile 14 (comportamiento 10) se empuja. En vista lateral sólo en horizontal. |
| `FIRE_TO_PUSH` | Hay que pulsar FIRE además de la dirección. |

Con scripting, empujar un bloque lanza la sección `TILE PUSHED`.

### Disparos

| Directiva | Qué es |
|---|---|
| `PLAYER_CAN_FIRE` | Activa los disparos. |
| `PLAYER_CAN_FIRE_FLAG` | Con scripting: sólo se dispara si este flag vale 1. |
| `PLAYER_BULLET_SPEED` | Velocidad de las balas (píxeles por frame). |
| `MAX_BULLETS` | Balas en pantalla a la vez. Cada una gasta memoria de sprites. |
| `PLAYER_BULLET_Y_OFFSET`, `PLAYER_BULLET_X_OFFSET` | Desde dónde salen. |
| `ENEMS_LIFE_GAUGE` | Disparos que aguanta un enemigo. |
| `LIMITED_BULLETS` | Las balas desaparecen tras unos frames: `LB_FRAMES` fijos, o los que diga el flag `LB_FRAMES_FLAG`. |
| `RESPAWN_ON_ENTER` | Los enemigos muertos resucitan al volver a entrar en la pantalla. |
| `FIRE_MIN_KILLABLE` | Sólo se pueden matar a tiros los enemigos de tipo >= N. |
| `CAN_FIRE_UP` | Vista lateral: disparar hacia arriba (con ARRIBA) y en diagonal. Mejor con `USE_TWO_BUTTONS`. |
| `MAX_AMMO` | Munición limitada (y su marcador). `AMMO_REFILL`: lo que da cada recarga; `INITIAL_AMMO`: con cuánta se empieza. |
| `BREAKABLE_WALLS` | Los tiles de comportamiento 16 se rompen a tiros; `BREAKABLE_WALLS_LIFE`: cuántos aguantan. |
| `ENABLE_RANDOM_RESPAWN` | Fanties en lugar de los enemigos muertos. `FANTY_MAX_V`, `FANTY_A` (también para el tipo 6) y `FANTIES_LIFE_GAUGE`. |

En vista lateral, sin disparos se salta con FIRE; con disparos, con ARRIBA (o
con N si `USE_TWO_BUTTONS`).

### Scripting

| Directiva | Qué es |
|---|---|
| `ACTIVATE_SCRIPTING` | Activa el scripting (capítulo 8). |
| `SCRIPTING_DOWN` | La tecla de acción es ABAJO. |
| `SCRIPTING_KEY_M` | La tecla de acción es M. Sin ninguna de las dos, FIRE. |
| `MAX_FLAGS` | Más flags de los que usa el script. |
| `ITEM_X`, `ITEM_Y` | Dónde se pinta el objeto que se lleva (`GET ITEM SET`). |

Lo demás (`EXTERN`, la zona de fuego, `TIMER ZERO`…) se activa solo según lo
que use el script.

### Temporizador

| Directiva | Qué es |
|---|---|
| `TIMER_ENABLE` | Activa el temporizador. |
| `TIMER_INITIAL` | Valor inicial (máximo 99). |
| `TIMER_REFILL` | Lo que dan las recargas de tiempo (*hotspot* 5). |
| `TIMER_LAPSE` | Frames entre cada decremento. |
| `TIMER_START` | Empieza en marcha. |
| `TIMER_GAMEOVER_0` | Al llegar a 0, fin de la partida. |
| `TIMER_KILL_0` | Al llegar a 0, se pierde una vida. Con `TIMER_WARP_TO` (y `TIMER_WARP_TO_X`, `_Y`), además se va a esa pantalla. |
| `TIMER_AUTO_RESET` | Vuelve a empezar tras llegar a 0. |
| `SHOW_TIMER_OVER` | Cartel "TIME'S UP!". |

Con scripting, al llegar a 0 se lanza la sección `TIMER ZERO` si el script la
tiene, y la variable `TIMER` del script es el temporizador.

### Puntos de control

| Directiva | Qué es |
|---|---|
| `ENABLE_CHECKPOINTS` | Los *hotspots* de tipo 6 guardan el estado (pantalla, posición, flags, munición, tiempo). Al acabar la partida, el menú ofrece "1 START / 2 CONTINUE". |
| `CP_RESET_WHEN_DYING` | Al perder una vida, se vuelve al último punto de control. |
| `CP_RESET_ALSO_FLAGS` | Y se restauran los flags. |

Las llaves y los objetos no se guardan: está pensado para güegos llevados por
el script.

### Vista genital

| Directiva | Qué es |
|---|---|
| `PLAYER_MOGGY_STYLE` | Vista desde arriba. |
| `TOP_OVER_SIDE` | En diagonal, manda ARRIBA/ABAJO. |
| `PLAYER_BOUNCE_WITH_WALLS` | Rebota contra las paredes. |

### Vista lateral

| Directiva | Qué es |
|---|---|
| `PLAYER_HAS_JUMP` | Salta. |
| `PLAYER_HAS_JETPAC` | Vuela con un jetpac (`PLAYER_INCR_JETPAC`, `PLAYER_MAX_VY_JETPAC`). |
| `PLAYER_BOOTEE` | Salta siempre, como Bootee (no uses también `PLAYER_HAS_JUMP` ni `PLAYER_HAS_JETPAC`). ABAJO hace más corto el salto (`PLAYER_BOOTEE_CROUCH`). |
| `PLAYER_CUMULATIVE_JUMP` | Con `PLAYER_HAS_JUMP`: manteniendo el salto se salta más alto en cada rebote. |
| `PLAYER_KILLS_ENEMIES` | Pisar a un enemigo lo mata. |
| `PLAYER_STOMPS_ON_ENEMIES` | Pisar a un enemigo hace rebotar sin matarlo. |
| `PLAYER_CAN_KILL_FLAG` | Con scripting: sólo se mata pisando si este flag vale 1. |
| `PLAYER_MIN_KILLABLE` | Sólo se pueden pisar los de tipo >= N. |
| `PLAYER_STEP_SOUND` | Ruido de pasos (no en Bootee). |

## III. Configuración de la pantalla

`VIEWPORT_X`, `VIEWPORT_Y`: la esquina de la zona de juego (30x20
caracteres), y las coordenadas de los marcadores (capítulo 4). Además:

| Directiva | Qué es |
|---|---|
| `PLAYER_SHOW_KILLS`, `PLAYER_SHOW_TIMER` | Mostrar esos contadores. |
| `LINE_OF_TEXT`, `LINE_OF_TEXT_X`, `LINE_OF_TEXT_ATTR` | Fila, columna y color del `TEXT` del script. |
| `USE_AUTO_SHADOWS` | Sombras por atributos. |
| `USE_AUTO_TILE_SHADOWS` | Sombras con los tiles 32-47. |
| `UNPACKED_MAP` | Mapa de 48 tiles, un byte por tile. |
| `NO_MASKS` | Sprites sin máscara (OR). Más rápido; feo sobre fondos con mucho dibujo. |
| `NO_ALT_TILE` | No sale el tile 19 en lugar del 0. |
| `PLAYER_ALTERNATE_ANIMATION` | Animación de andar 1, 2, 3, 1, 2, 3… |
| `MASKED_BULLETS` | Balas con máscara. |
| `ENABLE_TILANIMS` | Tiles animados: el valor es el primer tile animado. Van por parejas (40-41, 42-43…); en el mapa se pone el primero de la pareja y el motor va cambiando al azar entre los dos. Como mucho 64 por pantalla. |
| `PAUSE_ABORT` | H pausa, Y abandona la partida. |
| `GET_X_MORE` | Al coger un objeto, un cartel con los que faltan. |

## IV. El movimiento del jugador

Las posiciones van en coma fija **8.8**: 256 unidades son un píxel. Así que
las velocidades están en 1/256 de píxel por frame, y las aceleraciones en
1/256 de píxel por frame². En vista genital sólo se usan los valores
horizontales (para los dos ejes).

| Directiva | Ejemplo | Qué es |
|---|---|---|
| `PLAYER_MAX_VY_CAYENDO` | 2048 | Velocidad máxima de caída (8 píxeles/frame). |
| `PLAYER_G` | 128 | Gravedad (0,5 píxeles/frame²). |
| `PLAYER_VY_INICIAL_SALTO` | 256 | Velocidad al empezar el salto. |
| `PLAYER_MAX_VY_SALTANDO` | 1280 | Velocidad máxima de subida. |
| `PLAYER_INCR_SALTO` | 192 | Aceleración mientras se mantiene el salto. |
| `PLAYER_INCR_JETPAC` | 192 | Empuje del jetpac (mayor que `PLAYER_G`). |
| `PLAYER_MAX_VY_JETPAC` | 1024 | Velocidad máxima del jetpac. |
| `PLAYER_BOOTEE_CROUCH` | 512 | Bootee: lo que se suma a la velocidad al pulsar ABAJO. |
| `PLAYER_MAX_VX` | 1024 | Velocidad horizontal máxima. |
| `PLAYER_AX` | 192 | Aceleración horizontal. |
| `PLAYER_RX` | 256 | Rozamiento (frenada al soltar). |

Las versiones anteriores (3.99) usaban 10.6 (64 = un píxel): para pasar un
güego viejo a la v3.100 hay que **multiplicar estos valores por 4** (y
`FANTY_MAX_V` y `FANTY_A` también).

## V. El comportamiento de los tiles

`comportamiento_tiles []`, 48 valores (ver el capítulo 1). Con
`COMPRESSED_LEVELS` no se usa: cada nivel trae los suyos.

---

# Capítulo 7 - Música y sonido

Los efectos se tocan con `PLAY_SFX (n)`. Los números son los mismos en todas
las versiones:

| n | Efecto | Lo usa el motor para |
|---|---|---|
| 0 | Enemigo destruido | |
| 1 | Enemigo tocado | Pausa (128K) |
| 2 | "Algo" | Menús, pantalla de nivel, checkpoints, game over |
| 3 | Salto | Saltos, pisar sin matar |
| 4 | Jugador tocado | Tocar a un enemigo |
| 5 | Enemigo destruido 2 | Pisar y matar |
| 6 | Disparo | |
| 7 | Objeto | Objetos, recargas de munición y tiempo |
| 8 | Llave | |
| 9 | Vida | Recargas de vida |
| 10 | Puñetazo | Tiles que matan |
| 11 | Moneda | |
| 12, 13 | Hablar | |
| 14 | Cerrojo | Abrir un cerrojo |

## ZX Spectrum 48K: beeper

`speccy/beeper.h` tiene los efectos (de Shiru). La música del título es de
Beepola (`speccy/music.h`). Mientras suena un efecto el juego se para (el
beeper usa la CPU entera), así que los efectos se tocan entre `di` y `ei`.

## ZX Spectrum 128K: WYZ player

La música y los efectos los toca el WYZ proPLAYER desde la interrupción, en la
página 1 de RAM. `comp-zx.sh` lo ensambla (`speccy_128/wyz/wyzplayer.asm`) con
los datos del güego, que se buscan en `../ogt/zx128/` (o en `../ogt/`):

| Fichero | Qué es |
|---|---|
| `instrumentos.asm` | Instrumentos y pautas (de WYZTracker). |
| `canciones.asm` | `SONG_0`… (con `INCBIN` de los `.mus`) y `TABLA_SONG`. |
| `efectos.asm` | Opcional: `EFECTO0`… y `TABLA_EFECTOS`. Si no está, los 15 efectos de MK1 de `speccy_128/wyz/efectos.asm`. |
| `*.mus` | Las canciones exportadas de WYZTracker. |

Las canciones se tocan con `wyz_play_music (n)` (n es su posición en
`TABLA_SONG`): 0 en el título, 1 en el juego (con niveles, la del nivel) y 2
en el game over. `wyz_stop_sound ()` para la música. Un güego con sus propios
efectos debe hacer que su `TABLA_EFECTOS` tenga las 15 entradas en el orden de
la tabla de arriba (el ejemplo de Goku Mal hace corresponder sus 9 efectos
con los números de MK1 así).

Las canciones tienen que ser del formato del proPLAYER 0.2 de ZX: los `.mus`
del WYZ player nuevo del CPC no valen (el reproductor se cuelga).

## Amstrad CPC

También el WYZ player (`cpc/wyz_player.h`), con los datos en `../ogt/`:
`instrumentos.asm` (que `wyzTrackerParser` convierte en `cpc/instrumentos.h`),
`cpc/efectos.h` y las canciones comprimidas que lista `cpc/songs.h` (0
título, 1 juego, 2 game over).

---

# Capítulo 8 - El scripting (MSC4)

Cuando configurar no basta, tenemos el script. Es un lenguaje de *reacción*: el motor
lanza una **sección** del script cuando pasa algo (se entra en una pantalla,
se pulsa la tecla de acción, se coge un objeto, se mata a un enemigo…) y la
sección comprueba condiciones y ejecuta acciones:

```
ENTERING SCREEN 3
	IF %PUERTA_ABIERTA = 0
	THEN
		SET TILE (7, 4) = 13
	END
END

PRESS FIRE AT SCREEN 3
	IF PLAYER TOUCHES 6, 4
	IF OBJS >= 5
	THEN
		SET TILE (7, 4) = 0
		%PUERTA_ABIERTA = 1
		SOUND 7
	END
END
```

La especificación completa del lenguaje está en [`msc4.md`](msc4.md); lo que
toca a la v3.100 (cómo se compila, qué secciones lanza el motor y cuándo, las
variables especiales, `extern.h`, los niveles) en su
[§19](msc4.md#19-mk1-v3100-el-intérprete-en-c). Aquí va lo justo para empezar.

## Ponerlo en marcha

1. En `config.h`: `#define ACTIVATE_SCRIPTING` (y, si quieres,
   `SCRIPTING_DOWN` o `SCRIPTING_KEY_M` para la tecla de acción).
2. Escribe el script en `script/script.spt`.
3. `./comp-zx.sh`. El script se compila solo con `msc4 ... v=3_100 output=c`,
   que genera el bytecode, `msc-config.h` (lo que necesita el intérprete) y
   `msc-scripts.h`. El intérprete es `dev/msc.h`, en C, y sólo se compila lo
   que el script usa.

Si el script tiene errores, `comp-zx.sh` se para y muestra el log de msc4.

## Las secciones

| Sección | Cuándo |
|---|---|
| `ENTERING GAME` | Al empezar la partida (con niveles, cada nivel). |
| `ENTERING ANY` | Al entrar en cualquier pantalla. |
| `ENTERING SCREEN n` | Al entrar en la pantalla `n` (después de `ENTERING ANY`). |
| `PRESS FIRE AT ANY` | Al pulsar la tecla de acción (o dentro de la zona de fuego). |
| `PRESS FIRE AT SCREEN n` | Lo mismo, en la pantalla `n`. |
| `PLAYER GOT SOMETHING` | Al coger un *hotspot* (`HOTSPOT` dice de qué tipo). |
| `PLAYER KILLS ENEMY` | Al morir un enemigo. |
| `ENEMY TOUCHED` | Al tocar a un enemigo. |
| `SPECIAL TILE TOUCHED` | Cada frame que el jugador está en un tile de comportamiento 128. |
| `TILE PUSHED` | Al empujar un bloque. |
| `TILE DESTROYED` | Al romper un tile. |
| `TIMER ZERO` | Cuando el temporizador llega a 0. |

## Flags

El estado del script son los **flags**: `$0`, `$1`… (bytes de 0 a 255). Con
`ALIAS %NOMBRE = n` se les pone nombre. Los flags se ponen a 0 al empezar la
partida; con niveles, al empezar cada nivel. Desde C se leen como `flags [n]`.

## Texto y diálogos

* `TEXT "..."` escribe una línea en `LINE_OF_TEXT` (configurable en
  `config.h`).
* `TEXT BOX "..."` y `$F = DIALOG "A", "B", "C"` los muestra el güego: el
  intérprete descodifica el texto y llama a `text_box ()` o `dialog_box ()` de
  `extern.h` (capítulo 9). `tests/script/extern.h` tiene un ejemplo.

## Varios scripts

Con niveles, cada nivel tiene el suyo (capítulo 10). Se compilan todos juntos
listándolos en `dev/scripts.txt`, para que el intérprete tenga lo que
necesitan todos.

---

# Capítulo 9 - Código propio: `custom.h` y `extern.h`

Dos ficheros son del güego, no del motor:

* **`custom.h`**: los *ganchos* (hooks) del bucle principal, y cualquier
  código o dato propio del güego.
* **`extern.h`**: lo que el script llama (`EXTERN`, `TEXT BOX`, `DIALOG`).

## Los ganchos de `custom.h`

Un gancho es una función que el motor llama en un momento concreto si se
define su `HOOK_*`. Un gancho que no se define no ocupa nada.

| Gancho | Función | Cuándo |
|---|---|---|
| `HOOK_GAME_INIT` | `void hook_game_init (void)` | Una vez, al arrancar. Logos, idioma… |
| `HOOK_AFTER_TITLE` | `unsigned char hook_after_title (void)` | Tras la pantalla de título. Con niveles devuelve el nivel inicial (menús, contraseñas). |
| `HOOK_LEVEL_INTRO` | `void hook_level_intro (void)` | Con niveles, sustituye a la pantalla "LEVEL XX" antes de cada nivel. Va antes de cargar el nivel: puede usar la pantalla y el tileset. |
| `HOOK_LEVEL_START` | `void hook_level_start (void)` | Con el nivel cargado, justo antes de jugar. |
| `HOOK_ENTERING_SCREEN` | `void hook_entering_screen (void)` | Al entrar en cada pantalla, ya pintada. |
| `HOOK_WIN_CONDITION` | `unsigned char hook_win_condition (void)` | Cada frame: distinto de 0 si se ha superado el nivel. Sustituye a la condición normal (`WIN GAME` del script sigue valiendo). |
| `HOOK_LEVEL_END` | `void hook_level_end (void)` | Al superar un nivel (o el juego, sin niveles). |
| `HOOK_GAME_OVER` | `void hook_game_over (void)` | Sustituye a `game_over ()`. |
| `HOOK_GAME_ENDING` | `void hook_game_ending (void)` | Sustituye a `game_ending ()`. |

Ejemplo:

```c
#define HOOK_LEVEL_START
void hook_level_start (void) {
	print_str (VIEWPORT_X + 9, VIEWPORT_Y + 9, 71, "GET READY!");
	sp_UpdateNow ();
	espera_activa (50);
}
```

`custom.h` se incluye después del motor, así que se puede usar todo lo del
motor. El ejemplo completo es `examples/Goku Mal 128/dev/custom.h`, que hace
con estos ganchos todo lo que el Goku Mal original cambiaba dentro del motor.

## `extern.h`

Sólo se incluye si algún script usa `EXTERN`, `TEXT BOX` o `DIALOG`:

```c
void do_extern_action (unsigned char n, unsigned char m);   // EXTERN n, m
void text_box (void);              // TEXT BOX: el texto en msc_text_buf
unsigned char dialog_box (void);   // DIALOG: msc_options [0..2], msc_n_options;
                                   // devuelve 1, 2 o 3
```

## Lo que se puede usar del motor

Las variables y funciones más útiles:

| Qué | Qué es |
|---|---|
| `player` | El jugador: `x`, `y` (8.8), `vx`, `vy`, `life`, `objs`, `keys`, `killed`, `ammo`, `estado`… |
| `gpx`, `gpy` | Posición del jugador en píxeles (se calculan cada frame de `player.x`, `player.y`). |
| `set_player_at (x, y)` | Pone al jugador en (x, y) píxeles. |
| `n_pant`, `o_pant` | Pantalla actual y anterior. Cambiar `n_pant` cambia de pantalla. |
| `level` | Nivel actual (con niveles). |
| `LEVEL_MAP_W`, `LEVEL_MAX_OBJS`… | Datos del nivel actual (ver capítulo 10). |
| `flags []` | Los flags del script. |
| `qtile (x, y)`, `attr (x, y)` | Tile y comportamiento de la casilla (x, y) de la pantalla. |
| `set_map_tile (x, y, tile, comportamiento)` | Cambia una casilla (y la pinta). |
| `draw_coloured_tile (x, y, tile)` | Pinta un tile en coordenadas de carácter. |
| `print_str (x, y, color, cadena)` | Escribe un texto. |
| `print_number2 (x, y, n)` | Escribe un número de dos cifras. |
| `sp_UpdateNow ()` | Vuelca a pantalla lo pintado. |
| `espera_activa (frames)` | Espera, o hasta que se pulse una tecla. |
| `sp_WaitForNoKey ()`, `sp_KeyPressed (tecla)` | Teclado. |
| `PLAY_SFX (n)` | Efecto de sonido. |
| `redraw_scr ()` | Repinta la pantalla actual sin reiniciarla (con `PAUSE_ABORT`, `GET_X_MORE` o textos del script). |
| `clear_gamearea_tiles ()` | Borra la zona de juego (existe con niveles o con `ENABLE_CHECKPOINTS`). |
| `get_resource (RES_X, dirección)` | 128K: descomprime un recurso. |
| `wyz_play_music (n)`, `wyz_stop_sound ()` | 128K y CPC: música. |
| `gpit`, `gpjt`, `gpaux`, `rdx`, `rdy`… | Variables auxiliares globales (el motor las usa también: no confíes en su valor entre llamadas). |

Ojo con `sccz80`, el compilador de z88dk 1.10:

* las variables globales son más rápidas que las locales y que los punteros a
  estructuras;
* los desplazamientos por una constante (`x >> 4`) llaman a una rutina; sólo
  `>> 8` y sacar un byte se hacen en línea;
* `(unsigned int *) p` y `&(variable)` tras un cast no los entiende: usa
  `(unsigned char *) (&variable)`;
* los literales decimales de más de 32767 son `long`: escribe los números
  grandes en hexadecimal.

---

# Capítulo 10 - ZX Spectrum 128K y juegos con niveles

## El modo 128K

Con `#define MODE_128K`:

* la música y los efectos los toca el WYZ player (capítulo 7);
* las pantallas fijas y los niveles van **comprimidos en las páginas 3, 4, 6
  y 7** de RAM y se descomprimen cuando hacen falta con
  `get_resource (RES_X, dirección)`;
* la cinta lleva un cargador que coloca cada página en su sitio.

`comp-zx.sh` lo hace todo: ensambla el WYZ player en `RAM1.bin` y genera
`wyz_addrs.h`; reparte con `librarian` los recursos de `dev/librarian.txt`
(si no hay, `title.bin`, `marco.bin` y `ending.bin`) en `RAM3.bin`… y genera
`librarian.h` con un `#define RES_<NOMBRE>` por recurso (el nombre del
archivo sin extensión: `level1c.bin` → `RES_LEVEL1C`); comprueba que lo que se
usa con otra página puesta queda por debajo de 0xC000; y monta la cinta.

En 128K la pila va por debajo del programa (24200) y nada que se use con otra
página en 0xC000 (la pila, el descompresor, la interrupción, los buffers de
nivel, el tileset y los sprites) puede estar en 0xC000-0xFFFF. Si el programa
crece tanto que algo de eso pasa de 0xC000, `comp-zx.sh` da un error.

## Juegos con niveles

Con `MODE_128K`, `COMPRESSED_LEVELS` y `MAX_LEVELS`, el güego tiene varios
niveles. Cada nivel tiene:

* un **bundle** con los datos de juego (cabecera, comportamientos, cerrojos,
  *hotspots*, enemigos y mapa), que genera `buildlevel`;
* opcionalmente, su **tileset** y su **spriteset**, como recursos aparte (que
  pueden compartir varios niveles);
* su **música** (el número de canción);
* opcionalmente, su **script**.

Cada nivel puede tener un mapa de distinto tamaño. `MAP_W * MAP_H` de
`config.h` es el máximo de pantallas (y fija el tamaño de los buffers).

El formato está descrito en [`formato-niveles.md`](formato-niveles.md).

### Construir los niveles: `levels.sh`

Si en `dev/` hay un `levels.sh` ejecutable, `comp-zx.sh` lo llama antes de
`librarian`. Es donde se construyen los niveles:

```sh
U=../utils/linux
$U/buildlevel map=../map/mapa1.map ene=../enems/enems1.ene behs=behs1.txt \
	out=level1.bin maxpant=25 scr_ini=0 ini_x=2 ini_y=7 max_objs=10 life=3 2bytes
$U/zx0 level1.bin level1c.bin
$U/ts2bin ../gfx/font.png ../gfx/work1.png ts1.bin 7
$U/zx0 ts1.bin ts1c.bin
$U/sprcnv ../gfx/sprites1.png spr1.h && $U/defb2bin spr1.h spr1.bin
$U/zx0 spr1.bin spr1c.bin
```

`behs1.txt` tiene los 48 comportamientos separados por comas. Los parámetros
de `buildlevel` están en el capítulo 12.

### La tabla de niveles: `levelset.h`

```c
LEVEL levels [MAX_LEVELS] = {
	// bundle      tileset   spriteset  música  script
	{ RES_LEVEL1C, RES_TS1C, RES_SPR1C, 3,      NO_RESOURCE },
	{ RES_LEVEL2C, RES_TS2C, RES_SPR2C, 4,      NO_RESOURCE },
};
```

`NO_RESOURCE` en el tileset o el spriteset deja los que haya (los del nivel
anterior o los del binario); ojo si se puede volver a un nivel anterior (al
volver a empezar la partida, por ejemplo): entonces cada nivel debe decir los
suyos.

### Los datos del nivel

El motor usa siempre `LEVEL_MAP_W`, `LEVEL_MAP_H`, `LEVEL_SCR_INI`,
`LEVEL_INI_X`, `LEVEL_INI_Y`, `LEVEL_MAX_OBJS`, `LEVEL_ENEMS_LIFE`,
`LEVEL_SCR_FIN`, `LEVEL_FIN_X` y `LEVEL_FIN_Y`: con niveles salen de la
cabecera del nivel; sin niveles, de `config.h`.

### El flujo de una partida con niveles

1. Título; `HOOK_AFTER_TITLE` elige el nivel inicial (por defecto el 0).
2. Para cada nivel: `HOOK_LEVEL_INTRO` (o la pantalla "LEVEL XX"),
   `prepare_level ()` (descomprime el bundle, el tileset, el spriteset y el
   script), se colocan jugador, enemigos y objetos, `ENTERING GAME` del
   script, la música del nivel, `HOOK_LEVEL_START`, y a jugar.
3. Al superarlo, `HOOK_LEVEL_END` y el siguiente nivel; tras el último,
   `HOOK_GAME_ENDING` (o `game_ending ()`). Al perder, `HOOK_GAME_OVER` (o
   `game_over ()`).

### Ejemplos

* `tests/levels/`: Bootee partido en dos niveles de distinto tamaño, con y
  sin scripts (`tests/levels/run.sh`).
* `examples/Goku Mal 128/`: un juego completo de cinco niveles, con
  cinemáticas, contraseñas y su propia música y efectos.

---

# Capítulo 11 - Amstrad CPC

El mismo motor compila para CPC (`comp-cpc.sh`) con la librería `cpcrslib`
(versión de los Mojon Twins) en lugar de `splib2`. Lo propio del CPC está en
`dev/cpc/`. Las diferencias:

* Los gráficos son pngs con la paleta del CPC (`gfx/cpc/pal.png`, modo 0 por
  defecto: `mode=0` en `comp-cpc.sh`). Se convierten con `mkts_om`:

  ```sh
  P="platform=cpc cpcmode=0 pal=../gfx/cpc/pal.png"
  mkts_om $P mode=chars greyordered in=../gfx/cpc/font.png out=font.bin
  mkts_om $P mode=strait2x2 greyordered in=../gfx/cpc/work.png out=work.bin
  mkts_om $P mode=sprites in=../gfx/cpc/sprites.png out=sprites.bin max=16
  mkts_om $P mode=superbuffer in=../gfx/cpc/title.png out=title.scr
  mkts_om platform=cpc mode=palsasassembly in=../gfx/cpc/pal.png prefix=my_inks out=cpc/pal.h
  ```

* La música es del WYZ player (capítulo 7).
* La sincronía de frames la hace `sp_UpdateNow ()` (`MIN_FAPS_PER_FRAME`, que
  sale de `GAME_FRAME_TICKS`).
* La salida es `bootee.sna` (para emuladores) y una cinta `bootee.cdt` con
  cargador.
* No hay modo 128K ni niveles en CPC (`MODE_128K` se ignora).
* Los buffers del motor viven en los huecos de la memoria de vídeo
  (`cpc/sysvars.h`).

---

# Capítulo 12 - Las herramientas

Todas están en `src/utils/linux/` tras `build-linux.sh` (y los `.exe` de
Windows en `src/utils/`).

| Herramienta | Uso |
|---|---|
| `ts2bin font.png work.png ts.bin tinta` | Tileset de ZX (2304 bytes). `nofont`, `notiles` o `blank` en lugar de un png. |
| `mapcnv mapa.map mapa.h W H 15 10 cerrojo [packed] [fixmappy]` | Mapa a `mapa.h`. |
| `ene2h enems.ene enems.h [2bytes]` | Enemigos y *hotspots* a `enems.h`. |
| `sprcnv sprites.png sprites.h [nomask]` | Spriteset de ZX. |
| `defb2bin sprites.h sprites.bin` | Los `defb` de un `.h` a binario (spritesets por nivel). |
| `png2scr imagen.png imagen.scr` | Pantalla de 256x192 a formato Spectrum. |
| `zx0 entrada salida` | Compresor (el descompresor está en `dev/zx0.h`). |
| `buildlevel map= ene= behs= out= maxpant= scr_ini= ini_x= ini_y= [max_objs=] [life=] [scr_fin= fin_x= fin_y=] [mapw= maph=] [unpacked] [lock=15] [2bytes] [fixmappy] [noswap]` | Bundle de un nivel. `maxpant` es `MAP_W * MAP_H`; el tamaño del mapa sale del `.ene` (o de `mapw`/`maph`); `lock=99` si no hay cerrojos. |
| `librarian list=lista.txt out=librarian.h [dir=salida] [pages=3,4,6,7]` | Reparte recursos en páginas de RAM de 128K. |
| `msc4 in=a.spt[,b.spt] v=3_100 output=c [rooms=N]` | Compila los scripts (ver `msc4.md`). |
| `mkts_om platform=cpc ...` | Conversor de gráficos de CPC. |
| `pasmo` | Ensamblador (el WYZ player, el cargador de 128K). |
| `bin2tap`, `bas2tap` | Cintas de ZX. |
| `cpctbin2sna`, `cpc2cdt` | Instantáneas y cintas de CPC. |
| `printsize binario` | Tamaño del binario. |
| `ponedor.exe` | El editor de enemigos (Windows). |

---

# Capítulo 13 - Probar el motor

En `tests/` hay herramientas para probar el motor sin un emulador con
pantalla:

| Herramienta | Qué hace |
|---|---|
| `tests/zxrun/zxrun juego.bin [-128 -page n RAMn.bin ...] -f frames -k teclas -s frames -o prefijo` | Emulador de ZX 48K/128K (con las librerías chips): ejecuta N frames pulsando teclas (`-k "130:1+,134:1-"`: tecla abajo en el frame 130, arriba en el 134) y guarda capturas png. Además: `-d dir,len` vuelca memoria, `-h` hash de pantalla, `-rt` detecta saltos a la ROM, `-prof` perfil. |
| `tests/cpcrun/cpcrun juego.sna ...` | Lo mismo para CPC (`-pc` y `-low` para depurar cuelgues). |
| `tests/build.sh zx\|cpc salida.bin [DEF[=valor]] [-UNDEF] [@script.spt]` | Compila en una copia limpia de `src/` cambiando directivas de `config.h`. |
| `tests/matrix.sh [zx\|cpc\|all] [filtro]` | Compila unas cien configuraciones distintas del motor. |
| `tests/bench.sh` | Mide ciclos por frame y por pintado de pantalla. |
| `tests/levels/run.sh [nivel]` | La prueba de niveles (`SCRIPTED=1` con scripts). |
| `tests/script/` | Scripts de prueba del intérprete. |

---

# Apéndice A - Qué cambia la v3.100

Respecto a la rama 3.99 (`docs/whatsnew.txt`):

* **Linux**: todo el toolchain se compila en Linux (`env/setup-linux.sh`,
  `src/utils/build-linux.sh`) y hay `comp-zx.sh` y `comp-cpc.sh`.
* **Coma fija 8.8** en lugar de 10.6: las constantes de movimiento son 4 veces
  las de antes.
* **Sincronía de frames** fija (`GAME_FRAME_TICKS`, 25 fps por defecto) también
  en 48K.
* **Niveles** nuevos: el bundle sólo lleva datos de juego, independientes de
  la plataforma; tileset, spriteset y script son recursos aparte; cada nivel
  puede tener su tamaño de mapa (`formato-niveles.md`). `librarian` genera
  `#define RES_*` y lo llama `comp-zx.sh`. Los niveles de 48K comprimidos
  desaparecen.
* **128K**: el WYZ player y los recursos se montan solos; la pila va por
  debajo del programa; comprobación de lo que tiene que quedar por debajo de
  0xC000.
* **Ganchos** en `custom.h` para personalizar el flujo del juego sin tocar el
  motor.
* **Scripting MSC4** con un intérprete en C (sustituye a MSC3): secciones
  nuevas (`TIMER ZERO`, `TILE PUSHED`, `TILE DESTROYED`), un script por nivel,
  `TEXT BOX` y `DIALOG`. Ya no existen `ENABLE_EXTERN_CODE`,
  `ENABLE_FIRE_ZONE`, `TIMER_SCRIPT_0`, `ENABLE_PUSHED_SCRIPTING`,
  `MOVED_*_FLAG` ni el inventario de MSC3 (`ITEMSET`, `MSC_MAXITEMS`).
* Un montón de errores corregidos y el motor más rápido (el pintado de
  pantalla, un 13 % menos de tiempo).

---

# Apéndice B - Mapa de memoria

**ZX 48K**

| Zona | Qué hay |
|---|---|
| 23300-23599 (`BASE_ROOM_BUFFERS`) | `map_attr` y `map_buff` de la pantalla actual. |
| 23600-23727 (`BASE_ARRAYS`) | Arrays de enemigos y balas. |
| 23728-23877 (`BASE_BRK_BUFF`) | Golpes de los muros rompibles. |
| 24200 | El programa. |
| `AD_FREE` (0xF000 - bloques) - 0xF000 | Bloques de memoria de los sprites (`NUMBLOCKS`). |
| 0xF000-0xF100 | Tabla de vectores IM2. |
| 0xF1F0 hacia abajo | La pila (64 bytes). |
| 0xF1F1 | La interrupción (ISR). |
| 0xF200-0xFFFF | Tablas de rotación de splib2. |

**ZX 128K**: igual, salvo que la pila empieza en 24200 y crece hacia abajo, y
que las páginas 1 (WYZ player), 3, 4, 6 y 7 (recursos) se ponen en
0xC000-0xFFFF cuando hacen falta.

**CPC**: el programa en 0x400; los buffers del motor en los huecos de la
memoria de vídeo (0xC600…, ver `cpc/sysvars.h`).
