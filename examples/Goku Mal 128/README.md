# Goku Mal (ZX Spectrum 128K)

Goku Mal (The Mojon Twins, 2013) portado a MK1 v3.100 como ejemplo de juego
con varios niveles (`COMPRESSED_LEVELS`), recursos en páginas de RAM y código
propio enganchado al motor con los ganchos de `custom.h`.

## Compilar

```
./make.sh
```

Necesita las utilidades compiladas (`src/utils/build-linux.sh`) y z88dk
(`env/setup-linux.sh`). Deja `gokumal.tap`.

En Windows: `make.bat` (con `src\utils\build-windows.bat` y
`env\setup-windows.bat`). Enlaza las carpetas del juego con `mklink /J`, que
no necesita permisos de administrador.

El ejemplo no lleva una copia del motor: `make.sh` copia `src/dev` a
`build/dev`, pone encima los archivos de `dev/` y llama a `comp-zx.sh`. Así
siempre se compila con el motor actual y aquí solo está lo que es del juego.

## Qué hay aquí

| | |
|---|---|
| `dev/config.h` | La configuración del motor para Goku Mal. |
| `dev/custom.h` | Todo el código propio (ver abajo). |
| `dev/levelset.h` | La tabla de niveles: bundle, tileset, spriteset y música de cada uno. |
| `dev/levels.sh`, `dev/levels.bat` | Construye los cinco niveles con `buildlevel`, `ts2bin` y `sprcnv`. |
| `dev/librarian.txt` | Los recursos que van en las páginas de RAM. |
| `dev/game.sh` | El nombre del juego y la conversión de las pantallas (la lee `comp-zx.sh`). |
| `dev/game.bat`, `dev/convert.bat` | Lo mismo para `comp-zx.bat`: el nombre, y la conversión aparte. |
| `dev/speccy/extrasprites.h` | Explosión y bala propias. |
| `gfx/`, `map/`, `enems/`, `levels/` | Gráficos, mapas (Mappy), enemigos (`.ene`) y comportamientos de cada nivel. |
| `ogt/zx128/` | Canciones, instrumentos y efectos para el WYZ player. `ogt/wyz/` son los fuentes de WYZTracker. |

## Niveles

| Nivel | Mapa | Tamaño | Cómo se supera |
|---|---|---|---|
| 1 | `mapa1` | 1x25 | llegar arriba (pantalla 0) |
| 2 | `mapa2` | 25x1 | llegar a la derecha (pantalla 24) |
| 3 | `mapa3` | 25x1 | llegar a la izquierda (pantalla 0) |
| 4 | `mapa5` | 5x5 | coger las 6 flores |
| 5 | `mapa4` | 1x25 | llegar abajo (pantalla 24) |

Cada nivel tiene su tileset y su spriteset, que se cargan como recursos
(`levels [n].tileset`, `levels [n].spriteset`).

## Código propio (`custom.h`)

Todo lo que el Goku Mal original cambiaba dentro del motor va ahora en
ganchos:

* `HOOK_GAME_INIT`: los logos del principio y la elección de idioma.
* `HOOK_AFTER_TITLE`: el menú JUGAR / PASSWORD; devuelve el nivel inicial.
* `HOOK_LEVEL_INTRO`: las cinemáticas (antes de los niveles 1 y 4) y la
  pantalla de zona con el número del nivel en grande y su contraseña.
* `HOOK_WIN_CONDITION`: la condición de cada nivel (tabla de arriba).
* `HOOK_LEVEL_END`: "ZONE CLEAR".
* `HOOK_GAME_ENDING`: la cinemática final.
* `HOOK_GAME_OVER`: el game over con su música.

## Sonido

El motor pide los efectos con los números estándar de MK1 (`PLAY_SFX`).
Goku Mal tiene sus propios 9 efectos, así que `ogt/zx128/efectos.asm` termina
con una `TABLA_EFECTOS` que hace corresponder cada número de MK1 con el efecto
de Goku Mal que toca.

## Cambios respecto al original

* La física está en coma fija 8.8 (las constantes del original x4).
* El juego va a 25 fps fijos (`GAME_FRAME_TICKS`).
* Los niveles usan el formato de bundles de v3.100 y se comprimen con zx0.
* El nivel 4 tiene `max_objs = 6` en su bundle (las flores): así "GET X MORE"
  cuenta bien y la condición de victoria usa `LEVEL_MAX_OBJS`.
