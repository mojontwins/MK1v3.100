# CPCRSLIB "Mojon Tilemap" (cpcrslib-mt)

Versión recortada de CPCRSLIB, **orientada al motor MTE MK1 v3.100**. No es la
CPCRSLIB original: es sólo la porción que el motor usa de verdad.

Original version by Artaburu. Modificaciones para el tilemap y los *dirty
cells* (bitfield) por na_th_an.

## Alcance

Quedan 51 módulos (`cpcrslib.lst`):

* **Núcleo**: `cpc_ShowTileMap`, `cpc_UpdScr`, `cpc_ShowTouchedTiles`,
  `cpc_ResetTouchedTiles`, `cpc_UpdTileTable`, `cpc_InvalidateRect`,
  `cpc_KeysData`, `cpc_TestKeyboard`, `cpc_TestKey`, `cpc_SetMode`,
  `cpc_MakeM1RotationLUTs` y las tablas del tilemap (`cpc_TileMapConf`).
* **Dependencias internas** (no se declaran en la cabecera): `cpc_Bit2Mask`,
  `cpc_TblLookup`, `cpc_bitleft2mask`, `cpc_bitright2mask`.
* **Sprites**: la matriz completa de tamaños y formatos de pixel que el
  generador de assets (`mkts_om.exe mode=sprites`) puede pedir: 4x8, 8x8,
  8x16, 8x24, 16x16, 16x24, 12x24, 2Bx8, 4Bx16, 4Bx24, en sus variantes
  `Px` / `PxM1` / `GPx` / `G` / `LUT` / `CA`.

Se ha eliminado todo lo que no es tilemap ni *dirty cells*: gestión de teclado
(`cpc_AssignKey`, `cpc_DeleteKeys`, `cpc_RedefineKey`, `cpc_ScanKeyboard`,
`cpc_AnyKeyPressed`, `cpc_TestKeyF`), impresión de texto y gráficos
(`cpc_PrintStr`, `cpc_PrintGphStr*`, `cpc_PutTiles`, `cpc_GetTiles`,
`cpc_TouchTiles`, `cpc_GetScrAddress*`, `cpc_PutSp*` genéricos), el gestor de
tilemaps (`cpc_UpdateTileMap`), los actualizadores de pantalla alternativos
(`cpc_UpdScrM1P`, `cpc_UpdScrP`) y `cpc_SetColour`.

Las rutinas eliminadas siguen en el historial de git, por si hay que
resucitar alguna.

## Contrato con el motor

La librería no es autónoma: usa símbolos que le aporta el juego.

* El tileset, con el nombre `tiles` (`src/dev/cpc/tileset.h`).
* `viewport_x` y `viewport_y` (`src/dev/cpc/sysvars.h`), para el *clipping*
  (`CHURRERA_CLIPPING`).
* `behindtilemasks`, solo en la variante fg (ver más abajo).

Lo que antes ponía cada juego en `tilemap_conf.asm` es fijo en MK1 (pantalla
retocada de 32x24 tiles) y ahora está en la librería: las constantes en
`CPCconfig.inc` (`pantalla_juego`, `tiles_tocados`,
`posicion_inicial_area_visible`, `posicion_inicial_superbuffer`, los tamaños)
y las tablas `posiciones_pantalla` y `posiciones_super_buffer` en
`cpc_TileMapConf.s`.

## Llamadas desde C (SDCC)

`cpcrslib_mt.h` declara las funciones que usa el motor. Las que reciben un
argumento lo toman en HL (o L, si es de 8 bits): `__z88dk_fastcall`.
`cpc_TestKey` devuelve en L (`__sdcccall(0)`). Cada una tiene una entrada
`_nombre` para C; si la rutina usa IX, esa entrada lo guarda, porque SDCC lo
usa como puntero de marco. Las rutinas internas (`cpc_UpdTileTable`,
`cpc_InvalidateRect`, `cpc_TestKeyboard`...) se llaman desde ensamblador con
su nombre.

### `behindtilemasks` (variante FG)

Con `PASARPORDETRAS` (variante "fg"), la librería dibuja los sprites **por
detrás** de los tiles que el juego marque como "en primer plano". Para
saberlo, lee una tabla de **256 bytes, uno por tile**, en el símbolo
`behindtilemasks`:

* `0` → tile normal: el sprite va por delante.
* `1` → tile en primer plano: el sprite va por detrás.

La tabla la pone el juego, por ejemplo en una función contenedora:

```c
void behindtilemasks_data (void) __naked {
	__asm
		behindtilemasks::
		.db 0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,0
		; ... 256 bytes
	__endasm;
}
```

El motor enlaza con la variante normal y no la define.

## Variantes

* `cpcrslib.lib`: la normal (`PASARPORDETRAS = 0`).
* `cpcrslib_fg.lib`: la variante "fg" (`PASARPORDETRAS = 1`), para que los
  sprites puedan quedar detrás de ciertos tiles.

## Reconstruir

```
make.bat          (Windows; o ./make.sh)
```

Necesita GBDK-2020 (`GBDK_HOME`, por defecto `C:\gbdk`). Ensambla con
`sdasz80` todos los módulos de `cpcrslib.lst` dos veces (una por variante,
cambiando `PASARPORDETRAS` en una copia de `CPCconfig.inc`), crea las dos
librerías con `sdar` y las deja, con `cpcrslib_mt.h`, en `src/dev/cpc`, que
es donde las busca `comp-cpc`.
