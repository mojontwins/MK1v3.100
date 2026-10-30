# Formato de niveles de MK1 v3.100

Con `COMPRESSED_LEVELS` cada nivel se compone de:

- **Un bundle** con los datos de juego, que genera `utils/buildlevel`. Es igual
  en todas las plataformas: no contiene nada gráfico.
- **Recursos gráficos** (tileset, spriteset) convertidos con las herramientas
  de cada plataforma. Son recursos aparte y varios niveles pueden compartirlos.

Separar ambas cosas permite trocear los datos en recursos pequeños (que se
reparten mejor en páginas de RAM o bancos de ROM) y aísla lo que depende de la
plataforma de lo que no.

## Tamaño de los mapas

Cada nivel puede tener un mapa de tamaño distinto. `MAP_W` y `MAP_H` de
`config.h` pasan a ser el **máximo**: `MAX_PANT = MAP_W * MAP_H` fija el tamaño
de los buffers y de cada sección del bundle. El motor usa siempre
`LEVEL_MAP_W` / `LEVEL_MAP_H`, que salen de la cabecera del nivel.

`MAX_PANT` no puede pasar de 85 (los índices de enemigos son de 8 bits).

## Estructura del bundle

Todas las secciones tienen tamaño fijo (dependiente de `MAX_PANT`), para que
el motor lo descomprima de una vez en `level_data` y cada sección quede en su
etiqueta (ver `src/dev/levels.h`).

| Desplazamiento | Tamaño | Contenido |
|---|---|---|
| 0 | 16 | Cabecera |
| 16 | 48 | Comportamiento de los 48 tiles (`comportamiento_tiles`) |
| 64 | 32 × 4 | Cerrojos: `np, x, y, st` (`np = 255`: entrada vacía) |
| 192 | MAX_PANT × 3 | Hotspots: `xy, tipo, act` (`act = 1` al empezar) |
| 192 + 3·MAX_PANT | MAX_PANT × 3 × 10 | Enemigos: `x, y, x1, y1, x2, y2, mx, my, t, life` |
| 192 + 33·MAX_PANT | MAX_PANT × 75 ó × 150 | Mapa: 4 bits por tile (packed) o 1 byte (`UNPACKED_MAP`) |

### Cabecera

| Byte | Campo | Macro en el motor |
|---|---|---|
| 0 | ancho del mapa en pantallas | `LEVEL_MAP_W` |
| 1 | alto del mapa en pantallas | `LEVEL_MAP_H` |
| 2 | pantalla inicial | `LEVEL_SCR_INI` |
| 3, 4 | tile inicial x, y | `LEVEL_INI_X`, `LEVEL_INI_Y` |
| 5 | objetos para terminar | `LEVEL_MAX_OBJS` |
| 6 | vida de los enemigos | `LEVEL_ENEMS_LIFE` |
| 7 | pantalla final (99 = sin final por posición) | `LEVEL_SCR_FIN` |
| 8, 9 | tile final x, y | `LEVEL_FIN_X`, `LEVEL_FIN_Y` |
| 10 | número de cerrojos | — |
| 11 | flags (bit 0: mapa unpacked) | — |
| 12 | versión del formato (1) | — |
| 13–15 | reservado (0) | — |

Sin `COMPRESSED_LEVELS` las mismas macros toman sus valores de `config.h`, así
que el motor no distingue entre los dos casos.

## Tabla de niveles

Cada juego la define en `levelset.h` con los recursos que genera `librarian`:

```c
LEVEL levels [MAX_LEVELS] = {
	// bundle      tileset        spriteset      música  script
	{ RES_LEVEL1C, RES_TILESET1C, RES_SPRITES1C, 3,      RES_SCRIPT1C },
	{ RES_LEVEL2C, NO_RESOURCE,   NO_RESOURCE,   4,      NO_RESOURCE },	// reutiliza los gráficos, sin script
};
```

`prepare_level ()` descomprime el bundle en `level_data` y, si el nivel los
define, el tileset en `tileset` y el spriteset sobre los sprites actuales.

Con `ACTIVATE_SCRIPTING`, el script del nivel se descomprime en `msc_buffer`
(sin script, el índice queda vacío y no se ejecuta nada). Los scripts de todos
los niveles se compilan juntos para que el intérprete tenga todo lo que usa
cualquiera de ellos: `comp-zx.bat` le pasa a msc4 la lista de `scripts.txt`
(una ruta por línea). msc4 deja un `.spt.bin` junto a cada script, que
`levels.bat` comprime y `librarian.txt` reparte como los demás recursos:

```
# scripts.txt
../script/nivel1.spt
../script/nivel2.spt

rem levels.bat
"%U%\zx0" ..\script\nivel1.spt.bin script1c.bin > nul || exit /b 1
"%U%\zx0" ..\script\nivel2.spt.bin script2c.bin > nul || exit /b 1
```

Cada script indica sus pantallas con `ROOMS = n` (el tamaño de su mapa).

## Herramientas

```
buildlevel map=mapa1.map ene=enems1.ene behs=behs1.txt out=level1.bin maxpant=25 ^
           scr_ini=0 ini_x=2 ini_y=7 max_objs=99 life=3 [scr_fin=N fin_x=X fin_y=Y] ^
           [mapw=W maph=H] [unpacked] [lock=15] [2bytes] [fixmappy] [noswap]
zx0 level1.bin level1c.bin

rem tileset ZX (2304 bytes)
ts2bin font.png work1.png tileset1.bin 7
rem spriteset ZX
sprcnv sprites1.png sprites1.h
defb2bin sprites1.h sprites1.bin
```

`behs1.txt` contiene los 48 comportamientos separados por comas. El tamaño del
mapa se toma de la cabecera del `.ene` (se puede forzar con `mapw`/`maph`).

## ZX Spectrum 128K

Los recursos comprimidos se listan en `src/dev/librarian.txt`; `comp-zx.bat`
llama a `librarian`, que los reparte por las páginas 3, 4, 6 y 7 y genera
`librarian.h` con un `#define RES_<NOMBRE>` por recurso. La página 1 es del
WYZ player.

Todo lo que se usa con otra página puesta en 0xC000 tiene que estar por debajo
de esa dirección: la pila, el descompresor, la ISR y los destinos de
`get_resource` (`level_data`, `tileset` y los sprites). `comp-zx.bat` lo
comprueba con el `.map` del enlazador.
