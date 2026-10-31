@echo off
rem convert.bat de Ninjajar: lo llama comp-zx.bat en lugar de la conversion de
rem bootee (equivale a convert_assets de game.sh). U es la carpeta de las
rem utilidades, que pone comp-zx.bat.
rem
rem Graficos que no van en los niveles: el tileset base (la fuente y los
rem tiles comunes; cada nivel carga los suyos encima, sin la fuente), los
rem sprites del binario y la pantalla de carga. Las demas pantallas las hace
rem levels.bat.
if "%U%"=="" set "U=..\utils"

"%U%\ts2bin" ..\gfx\font.png ..\gfx\basework.png ts.bin 7 > nul || exit /b 1
"%U%\sprcnv" ..\gfx\sprites0.png speccy\sprites.h > nul || exit /b 1
"%U%\png2scr" ..\gfx\loading.png loading.scr > nul || exit /b 1
exit /b 0
