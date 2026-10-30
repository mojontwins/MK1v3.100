@echo off
rem Compila el juego para Amstrad CPC en Windows.
rem Uso: comp-cpc.bat [justcompile] [noclean]
rem Antes, en la misma ventana: C:\z88dk10-orig\setenv.bat (z88dk 1.10, ver
rem env\z88dk10-orig.zip). Las utilidades estan en ..\utils.
rem
rem Sin expansion retardada: imanol recibe argumentos con "!" (loading_palette=!...).

setlocal

rem Cambia "game" por el nombre de tu güego.
set game=bootee
set mode=0

cd /d "%~dp0"
set "U=%~dp0..\utils"
set "P=platform=cpc cpcmode=%mode% pal=..\gfx\cpc\pal.png"

set justcompile=0
set noclean=0
for %%a in (%*) do (
	if /i "%%a"=="justcompile" set justcompile=1
	if /i "%%a"=="noclean" set noclean=1
)

if %justcompile%==1 goto :script
echo ### CONVIRTIENDO COSAS QUE HAY QUE CONVERTIR ###
"%U%\mapcnv" ..\map\mapa.map mapa.h 6 5 15 10 15 packed > nul
"%U%\ene2h" ..\enems\enems.ene enems.h 2bytes > nul

"%U%\mkts_om" %P% mode=chars greyordered in=..\gfx\cpc\font.png out=font.bin silent > nul
"%U%\mkts_om" %P% mode=strait2x2 greyordered in=..\gfx\cpc\work.png out=work.bin silent > nul
"%U%\mkts_om" %P% mode=sprites in=..\gfx\cpc\sprites.png out=sprites.bin max=16 silent > nul
"%U%\mkts_om" %P% mode=sprites in=..\gfx\cpc\sprites_extra.png out=sprites_extra.bin max=2 silent > nul
"%U%\mkts_om" %P% mode=sprites in=..\gfx\cpc\sprites_bullet.png out=sprites_bullet.bin metasize=1,1 max=1 silent > nul
"%U%\mkts_om" %P% mode=sprites in=..\gfx\cpc\sprites_sword.png out=sprites_sword.bin metasize=1,1 max=4 silent > nul
"%U%\mkts_om" platform=cpc mode=palsasassembly in=..\gfx\cpc\pal.png prefix=my_inks out=cpc\pal.h silent > nul

for %%s in (marco ending title) do "%U%\mkts_om" %P% mode=superbuffer in=..\gfx\cpc\%%s.png out=%%s.scr silent > nul
rem zx0 no sobrescribe: se borra antes la salida
for %%s in (title marco ending) do (
	if exist %%s.bin del %%s.bin
	"%U%\zx0" %%s.scr.bin %%s.bin > nul
)

:script
call :hasdef ACTIVATE_SCRIPTING
if errorlevel 1 goto :compile
echo ### COMPILANDO SCRIPT ###
rem Todos los scripts del juego juntos (uno por nivel, si hay niveles): un
rem solo msc-config.h para el interprete (msc.h) y un .bin por script.
rem rooms= es el valor por defecto; cada script puede poner ROOMS = n.
call :scriptlist
call :getdef MAP_W mw
call :getdef MAP_H mh
set /a rooms=mw*mh
"%U%\msc4" in=%scripts% v=3_100 output=c rooms=%rooms% > msc4.log
if errorlevel 1 (type msc4.log& echo ERROR en el script& exit /b 1)
findstr /I /C:"warning" msc4.log
findstr /I /C:"error" /C:"wrong" /C:"unexpected" /C:"unknown" /C:"expecting" /C:"too long" msc4.log && (echo ERROR en el script& exit /b 1)

:compile
echo ### COMPILANDO GUEGO ###
"%U%\pasmo" cpc\cpc_TrPixLutM%mode%.asm trpixlut.bin
if exist trpixlutc.bin del trpixlutc.bin
"%U%\zx0" trpixlut.bin trpixlutc.bin > nul
"%U%\wyzTrackerParser" ..\ogt\instrumentos.asm cpc\instrumentos.h > nul

if exist zcc_opt.def del zcc_opt.def
zcc +cpc -a -vn -zorg=1024 -lcpcrslib_mt -o %game%.asm cpc\tilemap_conf.asm churromain.c -DCPC -DMODE_%mode% > nul 2>&1
if exist zcc_opt.def del zcc_opt.def
zcc +cpc -m -vn -zorg=1024 -lcpcrslib_mt -o %game%.bin cpc\tilemap_conf.asm churromain.c -DCPC -DMODE_%mode%
if errorlevel 1 (echo ERROR& exit /b 1)
"%U%\printsize" %game%.bin

echo ### CONSTRUYENDO SNA Y CDT ###
if exist %game%.sna del %game%.sna
"%U%\cpctbin2sna" %game%.bin 0x400 -pc 0x400 -o %game%.sna
echo Output: %game%.sna

"%U%\mkts_om" platform=cpc cpcmode=%mode% pal=..\gfx\cpc\pal_loading.png mode=scr in=..\gfx\cpc\loading.png out=loading.bin silent > nul
if exist loading.c.bin del loading.c.bin
if exist %game%.c.bin del %game%.c.bin
"%U%\zx7" loading.bin loading.c.bin > nul
"%U%\zx7" %game%.bin %game%.c.bin > nul

"%U%\imanol" in=cpc\loadercpc.asm-orig out=cpc\loadercpc.asm ^
	scrc_size=?loading.c.bin ^
	mainbin_size=?%game%.c.bin ^
	loading_palette=!..\gfx\cpc\pal_loading.png ^
	loader_mode=0 > nul
"%U%\pasmo" cpc\loadercpc.asm loader.bin > nul

"%U%\imanol" in=cpc\preloadercpc.asm-orig out=cpc\preloadercpc.asm ^
	loader_size=?loader.bin ^
	loader_mode=0 > nul
"%U%\pasmo" cpc\preloadercpc.asm preloader.bin > nul

if exist %game%.cdt del %game%.cdt
"%U%\cpc2cdt" -r %game% -m cpc -l 1024 -x 1024 -p 2000 preloader.bin %game%.cdt > nul
"%U%\cpc2cdt" -r LOADER -m raw1full -rl 740 -p 2000 loader.bin %game%.cdt > nul
"%U%\cpc2cdt" -r SCR -m raw1full -rl 740 -p 2000 loading.c.bin %game%.cdt > nul
"%U%\cpc2cdt" -r MAIN -m raw1full -rl 740 -p 2000 %game%.c.bin %game%.cdt > nul
echo Output: %game%.cdt

if %noclean%==1 goto :done
echo ### LIMPIANDO ###
for %%f in (*.scr *.bin zcc_opt.def) do del "%%f" > nul 2>&1

:done
echo ### DONE ###
exit /b 0

rem ---------------------------------------------------------------------------
rem Subrutinas

rem :hasdef NOMBRE  -> errorlevel 0 si config.h tiene "#define NOMBRE" activo
:hasdef
findstr /R /C:"^[^/]*#define[^A-Za-z0-9_]*%1\>" config.h > nul
exit /b %errorlevel%

rem :getdef NOMBRE VAR  -> VAR = valor de "#define NOMBRE valor" en config.h
:getdef
set "%2=0"
for /f "tokens=3" %%v in ('findstr /R /C:"^#define[^A-Za-z0-9_]*%1\>" config.h') do set "%2=%%v"
exit /b 0

rem :scriptlist  -> scripts = script.spt o las lineas de scripts.txt separadas
rem por comas (sin las que empiezan por #)
:scriptlist
setlocal EnableDelayedExpansion
set "s=../script/script.spt"
if exist scripts.txt (
	set "s="
	for /f "usebackq eol=# delims=" %%l in ("scripts.txt") do set "s=!s!,%%l"
	set "s=!s:~1!"
)
endlocal & set "scripts=%s%"
exit /b 0
