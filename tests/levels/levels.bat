@echo off
rem levels.bat de la prueba de niveles (tests\levels), equivalente de
rem levels.sh: dos niveles con los datos de bootee. Se copia a src\dev en una
rem copia limpia (ver run.bat).
rem  * Nivel 1: el mapa entero (6x5), tileset por defecto.
rem  * Nivel 2: un trozo de 3x2 pantallas (columnas 3-5, filas 0-1) con su
rem    propio recurso de tileset, para probar mapas de distinto tamano y la
rem    carga de graficos por nivel.
rem Necesita Python 3 (crop.py) en el PATH.
if "%U%"=="" set "U=..\utils\win"

rem behs.txt (los 48 comportamientos) lo deja run.bat, sacado de config.h.
"%U%\buildlevel" map=..\map\mapa.map ene=..\enems\enems.ene behs=behs.txt out=level1.bin maxpant=30 ^
	scr_ini=1 ini_x=5 ini_y=1 max_objs=25 life=1 2bytes || exit /b 1
python ..\..\tests\levels\crop.py ..\map\mapa.map ..\enems\enems.ene 3 0 3 2 crop.map crop.ene 2bytes || exit /b 1
"%U%\buildlevel" map=crop.map ene=crop.ene behs=behs.txt out=level2.bin maxpant=30 ^
	scr_ini=0 ini_x=3 ini_y=2 max_objs=4 life=1 2bytes || exit /b 1
for %%f in (level1 level2) do (
	if exist %%fc.bin del %%fc.bin
	"%U%\zx0" %%f.bin %%fc.bin > nul || exit /b 1
)
if exist ts2c.bin del ts2c.bin
"%U%\zx0" ts.bin ts2c.bin > nul || exit /b 1

rem Con scripting (SCRIPTED=1 en run.bat): los .bin de msc4 comprimidos, como recursos
if not exist ..\..\tests\levels\nivel1.spt.bin exit /b 0
for %%n in (1 2) do (
	if exist script%%nc.bin del script%%nc.bin
	"%U%\zx0" ..\..\tests\levels\nivel%%n.spt.bin script%%nc.bin > nul || exit /b 1
)
exit /b 0
