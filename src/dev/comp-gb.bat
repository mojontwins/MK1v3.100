@echo off
rem Compila el juego para Game Boy (DMG, cartucho MBC1) en Windows
rem (equivalente de comp-gb.sh).
rem Uso: comp-gb.bat [justcompile] [noclean]
rem Necesita GBDK-2020 en C:\gbdk, o donde diga GBDK_HOME. Las utilidades
rem estan en ..\utils.
rem
rem  * Convierte el mapa, los enemigos y los graficos de ..\gfx\gb (mkts_om
rem    platform=gb). Un juego puede traer un convert_gb.bat propio.
rem  * Reparte los recursos de librarian_gb.txt (o los de bootee) en bancos de
rem    ROM desde el 3 con librarian platform=gb.
rem  * Compila el banco 0 (gb\home.c, gb\zx0.s, gb\vram.s) y el motor
rem    (gb\churromain.c, banco 1),
rem    enlaza con lcc (MBC1), comprueba con gbcheck que los bancos y la RAM no
rem    se desbordan y deja %game%.gb.

setlocal

rem Cambia "game" por el nombre de tu güego.
set game=bootee

cd /d "%~dp0"
set "U=%~dp0..\utils"
if not defined GBDK_HOME set "GBDK_HOME=C:\gbdk"
set "LCC=%GBDK_HOME%\bin\lcc"

rem Un juego puede traer un game.bat que cambie "game"
if exist game.bat call game.bat

set justcompile=0
set noclean=0
for %%a in (%*) do (
	if /i "%%a"=="justcompile" set justcompile=1
	if /i "%%a"=="noclean" set noclean=1
)

if %justcompile%==1 goto :resources
echo ### CONVIRTIENDO COSAS QUE HAY QUE CONVERTIR ###
if exist convert_gb.bat (
	call convert_gb.bat
	if errorlevel 1 (echo ERROR convirtiendo& exit /b 1)
	goto :resources
)
"%U%\mapcnv" ..\map\mapa.map mapa.h 6 5 15 10 15 packed > nul
"%U%\ene2h" ..\enems\enems.ene enems.h 2bytes > nul
rem Lo que sale de mkts_om va a X_raw.bin y comprimido a X.bin (el recurso)
"%U%\mkts_om" platform=gb silent mode=chars in=..\gfx\gb\font.png out=font_raw.bin max=64 > nul || exit /b 1
"%U%\mkts_om" platform=gb silent mode=strait2x2 in=..\gfx\gb\work.png out=tileset_raw.bin max=48 > nul || exit /b 1
"%U%\mkts_om" platform=gb silent mode=sprites in=..\gfx\gb\sprites.png out=sprites_raw.bin max=32 > nul || exit /b 1
for %%s in (title ending) do "%U%\mkts_om" platform=gb silent mode=scr in=..\gfx\gb\%%s.png out=%%s_raw.bin > nul || exit /b 1
rem zx0 no sobrescribe: se borra antes la salida
for %%s in (font tileset sprites title ending) do (
	if exist %%s.bin del %%s.bin
	"%U%\zx0" %%s_raw.bin %%s.bin > nul
)

:resources
echo ### RECURSOS EN BANCOS DE ROM ###
set "lst=librarian_gb.txt"
if not exist librarian_gb.txt (
	set "lst=librarian_gb.default.txt"
	(echo font.bin& echo tileset.bin& echo sprites.bin& echo title.bin& echo ending.bin) > librarian_gb.default.txt
)
del res_bank*.s > nul 2>&1
"%U%\librarian" platform=gb list=%lst% out=librarian.h firstbank=3 || exit /b 1

echo ### COMPILANDO GUEGO ###
set "F=-msm83:gb -I. -Wf--opt-code-speed"
if not exist obj_gb mkdir obj_gb
del obj_gb\*.o > nul 2>&1
rem Banco 0: gb\home.c, gb\zx0.s, gb\vram.s y GBDK. Banco 1: el motor
rem (gb\churromain.c), que esta siempre puesto.
"%LCC%" %F% -c -o obj_gb\home.o gb\home.c
if errorlevel 1 (echo ERROR en gb\home.c& exit /b 1)
"%LCC%" %F% -DGB -Wf-bo1 -c -o obj_gb\churromain.o gb\churromain.c
if errorlevel 1 (echo ERROR en el motor& exit /b 1)
for %%s in (zx0 vram) do (
	"%LCC%" %F% -c -o obj_gb\%%s.o gb\%%s.s
	if errorlevel 1 exit /b 1
)
for %%r in (res_bank*.s) do (
	"%LCC%" %F% -c -o obj_gb\%%~nr.o %%r
	if errorlevel 1 exit /b 1
)

rem MBC1 (-yt 0x01), los bancos que hagan falta (-yoA)
"%LCC%" %F% -Wl-yt0x01 -Wm-yoA -Wm-yn"%game%" -Wl-m -Wl-j -o obj_gb\%game%.gb obj_gb\*.o
if errorlevel 1 (echo ERROR enlazando& exit /b 1)
copy /y obj_gb\%game%.gb . > nul

rem ¿Cabe todo? (bancos de ROM y los 8K de RAM con la pila)
"%U%\gbcheck" obj_gb\%game%.map || exit /b 1

if %noclean%==1 goto :done
echo ### LIMPIANDO ###
rmdir /s /q obj_gb
del res_bank*.s *_raw.bin font.bin tileset.bin sprites.bin title.bin ending.bin librarian.h librarian_gb.default.txt > nul 2>&1

:done
echo ### DONE ###
