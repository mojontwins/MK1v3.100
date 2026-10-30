@echo off
rem convert.bat de Goku Mal: lo llama comp-zx.bat en lugar de la conversion de
rem bootee (equivale a convert_assets de game.sh). U es la carpeta de las
rem utilidades, que pone comp-zx.bat.
rem
rem Graficos que no van en los niveles. El tileset y los sprites del binario
rem son los del nivel 1; cada nivel carga los suyos como recursos (levels.bat).
if "%U%"=="" set "U=..\utils"

"%U%\ts2bin" ..\gfx\font.png ..\gfx\work1.png ts.bin 7 > nul || exit /b 1
"%U%\sprcnv" ..\gfx\sprites1.png speccy\sprites.h > nul || exit /b 1
"%U%\png2scr" ..\gfx\loading.png loading.scr > nul || exit /b 1
rem Pantallas completas (title, final, zonas, cinematicas, logos)
for %%s in (title ending zoneA zoneB intro1 intro2 intro3 intro4 intro5 intro6 intro7 logo controls dedicado) do (
	"%U%\png2scr" ..\gfx\%%s.png %%s.scr > nul || exit /b 1
	if exist %%s.bin del %%s.bin
	"%U%\zx0" %%s.scr %%s.bin > nul || exit /b 1
)
rem Tileset con los numeros grandes de la pantalla de zona
if exist leveltsc.bin del leveltsc.bin
"%U%\zx0" ..\gfx\levelts.bin leveltsc.bin > nul
exit /b 0
