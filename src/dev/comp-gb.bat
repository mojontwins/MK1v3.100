@echo off
rem Compila el juego para Game Boy (DMG, cartucho MBC1) en Windows
rem (equivalente de comp-gb.sh).
rem Uso: comp-gb.bat [justcompile] [noclean]
rem Necesita GBDK-2020 en C:\gbdk, o donde diga GBDK_HOME. Las utilidades
rem estan en ..\utils.
rem
rem  * Convierte el mapa, los enemigos y los graficos de ..\gfx\gb (mkts_om
rem    platform=gb). Un juego puede traer un convert_gb.bat propio.
rem  * Con scripting, compila los scripts (msc4, con los textos en lineas de
rem    GB_TEXT_WIDTH caracteres) y, si el juego trae levels_gb.bat, construye
rem    sus niveles.
rem  * Reparte los recursos de librarian_gb.txt (o los de bootee) en bancos de
rem    ROM desde el 3 con librarian platform=gb.
rem  * Compila el banco 0 (gb\home.c, gb\zx0.s, gb\vram.s) y el motor
rem    (gb\churromain.c, banco 1),
rem    enlaza con lcc (MBC1), comprueba con gbcheck que los bancos y la RAM no
rem    se desbordan y deja %game%.gb.

setlocal EnableDelayedExpansion

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
rem (mkts_om avisa si una pantalla tiene mas de 192 patrones)
for %%s in (title ending) do (
	"%U%\mkts_om" platform=gb mode=scr in=..\gfx\gb\%%s.png out=%%s_raw.bin > mkts.log || exit /b 1
	findstr /I "WARNING" mkts.log
)
rem zx0 no sobrescribe: se borra antes la salida
for %%s in (font tileset sprites title ending) do (
	if exist %%s.bin del %%s.bin
	"%U%\zx0" %%s_raw.bin %%s.bin > nul
)

:resources
call :hasdef ACTIVATE_SCRIPTING
if errorlevel 1 goto :levels
echo ### COMPILANDO SCRIPT ###
rem Como en comp-zx.bat, pero con los textos partidos en lineas de
rem GB_TEXT_WIDTH caracteres (18 si config.h no dice otra cosa): la pantalla
rem del Game Boy tiene 20 de ancho.
call :scriptlist
call :getdef MAP_W mw
call :getdef MAP_H mh
set /a rooms=mw*mh
call :getdef GB_TEXT_WIDTH tw
if "!tw!"=="0" set tw=18
set "textres="
call :hasdef SCRIPT_TEXTS_AS_RESOURCE
if not errorlevel 1 set "textres=textres"
"%U%\msc4" in=!scripts! v=3_100 output=c rooms=!rooms! textwidth=!tw! !textres! > msc4.log
if errorlevel 1 (type msc4.log& echo ERROR en el script& exit /b 1)
findstr /I /C:"warning" msc4.log
findstr /I /C:"error" /C:"wrong" /C:"unexpected" /C:"unknown" /C:"expecting" /C:"too long" msc4.log && (echo ERROR en el script& exit /b 1)

:levels
rem Paso propio del juego para construir sus niveles y sus graficos de Game
rem Boy (bundles, tilesets, spritesets, scripts, pantallas). Ver
rem docs/formato-niveles.md. Se ejecuta antes de librarian.
if %justcompile%==1 goto :librarian
if exist levels_gb.bat (
	echo ### CONSTRUYENDO NIVELES ###
	call levels_gb.bat
	if errorlevel 1 (echo ERROR en levels_gb.bat& exit /b 1)
)

:librarian
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
del res_bank*.s *_raw.bin *.bin librarian.h librarian_gb.default.txt msc4.log mkts.log > nul 2>&1

:done
echo ### DONE ###
exit /b 0

rem :hasdef NOMBRE  -> errorlevel 0 si config.h tiene "#define NOMBRE" activo
:hasdef
for /f "tokens=1,2" %%a in ('findstr /R /C:"^[ 	]*#define" config.h') do if "%%a"=="#define" if "%%b"=="%1" exit /b 0
exit /b 1

rem :getdef NOMBRE VAR  -> VAR = valor de "#define NOMBRE valor" en config.h
:getdef
set "%2=0"
for /f "tokens=1,2,3" %%a in ('findstr /R /C:"^[ 	]*#define" config.h') do if "%%a"=="#define" if "%%b"=="%1" set "%2=%%c"
exit /b 0

rem :scriptlist  -> scripts = script.spt o las lineas de scripts.txt separadas
rem por comas (sin las que empiezan por #)
:scriptlist
set "scripts=../script/script.spt"
if not exist scripts.txt exit /b 0
set "scripts="
for /f "usebackq eol=# delims=" %%l in ("scripts.txt") do set "scripts=!scripts!,%%l"
set "scripts=!scripts:~1!"
exit /b 0
