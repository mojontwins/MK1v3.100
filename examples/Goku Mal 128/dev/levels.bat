@echo off
rem levels.bat de Goku Mal: construye los cinco niveles (equivalente de
rem levels.sh). Lo llama comp-zx.bat antes de librarian. Ver
rem docs/formato-niveles.md.
rem
rem Cada nivel: bundle (mapa, enemigos, hotspots, comportamientos) + tileset +
rem spriteset, todo comprimido con zx0. Los numeros de nivel van en el orden
rem del juego: el nivel 4 es el mapa 5 (5x5, las flores) y el 5 el mapa 4.
if "%U%"=="" set "U=..\utils\win"

rem         nivel mapa scr_ini ini_x ini_y max_objs vida
rem 1x25, de abajo arriba
call :build 1 1 24  2 7 99 3 || exit /b 1
rem 25x1, de izquierda a derecha
call :build 2 2  0  4 1 99 4 || exit /b 1
rem 25x1, de derecha a izquierda
call :build 3 3 24 12 1 99 5 || exit /b 1
rem 5x5, coger las 6 flores
call :build 4 5 10  1 7  6 5 || exit /b 1
rem 1x25, de arriba abajo
call :build 5 4  0  4 1 99 5 || exit /b 1
exit /b 0

:build
"%U%\buildlevel" map=..\map\mapa%2.MAP ene=..\enems\enems%2.ene behs=..\levels\behs%2.txt ^
	out=level%1.bin maxpant=25 scr_ini=%3 ini_x=%4 ini_y=%5 max_objs=%6 life=%7 lock=99 2bytes > nul || exit /b 1
"%U%\ts2bin" ..\gfx\font.png ..\gfx\work%2.png ts%1.bin 7 > nul || exit /b 1
"%U%\sprcnv" ..\gfx\sprites%2.png spr%1.h > nul || exit /b 1
"%U%\defb2bin" spr%1.h spr%1.bin > nul || exit /b 1
for %%f in (level ts spr) do (
	if exist %%f%1c.bin del %%f%1c.bin
	"%U%\zx0" %%f%1.bin %%f%1c.bin > nul || exit /b 1
)
exit /b 0
