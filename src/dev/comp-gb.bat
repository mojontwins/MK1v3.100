@echo off
rem Compila el juego para Game Boy (DMG, cartucho MBC1) en Windows
rem (equivalente de comp-gb.sh).
rem Uso: comp-gb.bat [justcompile] [noclean]
rem Necesita GBDK-2020 en C:\gbdk, o donde diga GBDK_HOME. Las utilidades
rem estan en ..\utils.
rem
rem  * Convierte los graficos de ..\gfx\gb (mkts_om platform=gb). Un juego
rem    puede traer un convert_gb.bat propio.
rem  * Reparte los recursos de librarian_gb.txt (o los de bootee) en bancos de
rem    ROM desde el 3 con librarian platform=gb.
rem  * Compila el banco 0 (gb\crt.c, gb\home.c, gb\zx0.s) y el motor (banco 1),
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
rem Lo que sale de mkts_om va a X_raw.bin y comprimido a X.bin (el recurso)
"%U%\mkts_om" platform=gb silent mode=chars in=..\gfx\gb\font.png out=font_raw.bin max=64 > nul || exit /b 1
for %%s in (title ending) do "%U%\mkts_om" platform=gb silent mode=scr in=..\gfx\gb\%%s.png out=%%s_raw.bin > nul || exit /b 1
rem zx0 no sobrescribe: se borra antes la salida
for %%s in (font title ending) do (
	if exist %%s.bin del %%s.bin
	"%U%\zx0" %%s_raw.bin %%s.bin > nul
)

:resources
echo ### RECURSOS EN BANCOS DE ROM ###
set "lst=librarian_gb.txt"
if not exist librarian_gb.txt (
	set "lst=librarian_gb.default.txt"
	(echo font.bin& echo title.bin& echo ending.bin) > librarian_gb.default.txt
)
del res_bank*.s > nul 2>&1
"%U%\librarian" platform=gb list=%lst% out=librarian.h firstbank=3 || exit /b 1

echo ### COMPILANDO GUEGO ###
set "F=-msm83:gb -I. -Wf--opt-code-speed"
if not exist obj_gb mkdir obj_gb
del obj_gb\*.o > nul 2>&1
for %%c in (crt home main) do (
	"%LCC%" %F% -c -o obj_gb\%%c.o gb\%%c.c
	if errorlevel 1 (echo ERROR en gb\%%c.c& exit /b 1)
)
"%LCC%" %F% -c -o obj_gb\zx0.o gb\zx0.s || exit /b 1
for %%r in (res_bank*.s) do (
	"%LCC%" %F% -c -o obj_gb\%%~nr.o %%r
	if errorlevel 1 exit /b 1
)

rem MBC1 (-yt 0x01), los bancos que hagan falta (-yoA)
"%LCC%" %F% -Wl-yt0x01 -Wm-yoA -Wm-yn"%game%" -Wl-m -o obj_gb\%game%.gb obj_gb\*.o
if errorlevel 1 (echo ERROR enlazando& exit /b 1)
copy /y obj_gb\%game%.gb . > nul

rem ¿Cabe todo? (bancos de ROM y los 8K de RAM con la pila)
"%U%\gbcheck" obj_gb\%game%.map || exit /b 1

if %noclean%==1 goto :done
echo ### LIMPIANDO ###
rmdir /s /q obj_gb
del res_bank*.s *_raw.bin font.bin title.bin ending.bin librarian.h librarian_gb.default.txt > nul 2>&1

:done
echo ### DONE ###
