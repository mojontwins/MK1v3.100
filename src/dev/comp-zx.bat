@echo off
rem Compila el juego para ZX Spectrum en Windows (equivalente de comp-zx.sh).
rem Uso: comp-zx.bat [justcompile] [noclean]
rem Requiere z88dk 1.10 en el PATH (z88env.bat, ver env\setup-windows.bat) y
rem las utilidades en ..\utils\win (src\utils\build-windows.bat).
rem
rem Con ACTIVATE_SCRIPTING compila los scripts con msc4 (..\script\script.spt
rem o la lista de scripts.txt).
rem
rem Si config.h define MODE_128K, ademas:
rem  * ensambla el WYZ player (speccy_128\wyz\wyzplayer.asm) con las canciones,
rem    instrumentos y efectos del juego (..\ogt\zx128 o ..\ogt) en RAM1 y genera
rem    wyz_addrs.h;
rem  * reparte los recursos de librarian.txt (o title/marco/ending si no existe)
rem    en las paginas 3, 4, 6 y 7 con librarian, que genera librarian.h;
rem  * comprueba que lo que se usa con otra pagina puesta queda bajo 0xC000;
rem  * hace una cinta con un cargador que coloca cada pagina en su sitio.

setlocal EnableDelayedExpansion

rem Cambia "game" por el nombre de tu güego.
set game=bootee

cd /d "%~dp0"
set "U=%~dp0..\utils\win"

rem Un juego puede traer un game.bat que cambie "game" y un convert.bat con la
rem conversion de sus graficos (en lugar de la de bootee de mas abajo).
if exist game.bat call game.bat

set justcompile=0
set noclean=0
for %%a in (%*) do (
	if /i "%%a"=="justcompile" set justcompile=1
	if /i "%%a"=="noclean" set noclean=1
)

set mode128=0
call :hasdef MODE_128K
if not errorlevel 1 set mode128=1

if %justcompile%==1 goto :script
echo ### CONVIRTIENDO COSAS QUE HAY QUE CONVERTIR ###
if exist convert.bat (
	call convert.bat
	if errorlevel 1 (echo ERROR convirtiendo& exit /b 1)
	goto :script
)
"%U%\mapcnv" ..\map\mapa.map mapa.h 6 5 15 10 15 packed > nul
"%U%\ene2h" ..\enems\enems.ene enems.h 2bytes > nul

"%U%\ts2bin" ..\gfx\speccy\font.png ..\gfx\speccy\work.png ts.bin 7 > nul
"%U%\sprcnv" ..\gfx\speccy\sprites.png speccy\sprites.h > nul
for %%s in (title marco ending loading) do "%U%\png2scr" ..\gfx\speccy\%%s.png %%s.scr > nul
rem zx0 no sobrescribe: se borra antes la salida
for %%s in (title marco ending) do (
	if exist %%s.bin del %%s.bin
	"%U%\zx0" %%s.scr %%s.bin > nul
)

:script
call :hasdef ACTIVATE_SCRIPTING
if errorlevel 1 goto :levels
echo ### COMPILANDO SCRIPT ###
rem Todos los scripts del juego juntos (uno por nivel, si hay niveles): un
rem solo msc-config.h para el interprete (msc.h) y un .bin por script.
rem rooms= es el valor por defecto; cada script puede poner ROOMS = n.
call :scriptlist
call :getdef MAP_W mw
call :getdef MAP_H mh
set /a rooms=mw*mh
"%U%\msc4" in=!scripts! v=3_100 output=c rooms=!rooms! > msc4.log
if errorlevel 1 (type msc4.log& echo ERROR en el script& exit /b 1)
findstr /I /C:"warning" msc4.log
findstr /I /C:"error" /C:"wrong" /C:"unexpected" /C:"unknown" /C:"expecting" /C:"too long" msc4.log && (echo ERROR en el script& exit /b 1)

:levels
rem Paso propio del juego para construir niveles (bundles, tilesets...). Ver
rem docs/formato-niveles.md. Se ejecuta antes de librarian.
if exist levels.bat (
	echo ### CONSTRUYENDO NIVELES ###
	call levels.bat
	if errorlevel 1 (echo ERROR en levels.bat& exit /b 1)
)

if %mode128%==0 goto :compile
echo ### 128K: WYZ PLAYER Y RECURSOS ###
rem Reproductor + datos del juego: instrumentos.asm, canciones.asm, los .mus
rem y, opcionalmente, efectos.asm (si no, los 15 de MK1 por defecto). Se
rem toman de ..\ogt\zx128 si existe; si no, de ..\ogt.
set "OGT=..\ogt"
if exist ..\ogt\zx128\ set "OGT=..\ogt\zx128"
set "W=%TEMP%\mk1wyz%RANDOM%%RANDOM%"
mkdir "%W%"
copy /y speccy_128\wyz\wyzplayer.asm "%W%\" > nul
copy /y speccy_128\wyz\efectos.asm "%W%\" > nul
copy /y "%OGT%\*.asm" "%W%\" > nul 2>&1
copy /y "%OGT%\*.mus" "%W%\" > nul 2>&1
pushd "%W%"
"%U%\pasmo" wyzplayer.asm ram1.bin ram1.sym > nul 2>&1
if errorlevel 1 (
	echo ERROR ensamblando el WYZ player
	"%U%\pasmo" wyzplayer.asm ram1.bin ram1.sym
	popd
	rmdir /s /q "%W%"
	exit /b 1
)
popd
copy /y "%W%\ram1.bin" RAM1.bin > nul
for %%s in (INICIO INIT_BUFFERS CARGA_CANCION PLAYER_OFF INICIA_EFECTO) do call :sym %%s
> wyz_addrs.h (
	echo // Generado por comp-zx.bat a partir de la tabla de simbolos del WYZ player
	echo #define WYZPLAYERISR		!sym_INICIO!
	echo #define WYZPLAYERINIT		!sym_INIT_BUFFERS!
	echo #define CARGA_CANCION		!sym_CARGA_CANCION!
	echo #define SILENCIA_PLAYER		!sym_PLAYER_OFF!
	echo #define INICIAEFECTO		!sym_INICIA_EFECTO!
)
rmdir /s /q "%W%"
for %%f in (RAM1.bin) do echo RAM1.bin: %%~zf bytes

rem Recursos en paginas de RAM
if exist librarian.txt (
	set "lst=librarian.txt"
) else (
	set "lst=librarian.default.txt"
	(echo title.bin& echo marco.bin& echo ending.bin) > librarian.default.txt
)
for %%r in (3 4 6 7) do if exist RAM%%r.bin del RAM%%r.bin
"%U%\librarian" list=!lst! out=librarian.h
if errorlevel 1 exit /b 1

:compile
echo ### COMPILANDO GUEGO ###
if exist zcc_opt.def del zcc_opt.def
zcc +zx -a -vn churromain.c -o %game%.asm -lsplib2 -zorg=24200 > nul 2>&1
if exist zcc_opt.def del zcc_opt.def
zcc +zx -m -vn churromain.c -o %game%.bin -lsplib2 -zorg=24200
if errorlevel 1 (echo ERROR& exit /b 1)
"%U%\printsize" %game%.bin

if %mode128%==0 goto :tape
rem Todo lo que se usa con otra pagina de RAM en 0xC000 tiene que estar por debajo.
set bad=0
for %%s in (DEPACK _UNPACK_RAMN SETRAMBANK _ISR _TILESET _SPRITES_END _LEVEL_DATA_END _MSC_BUFFER) do call :checkaddr %%s
if %bad%==1 exit /b 1

:tape
echo ### CONSTRUYENDO CINTA ###
"%U%\bin2tap" -o screen.tap -a 16384 loading.scr
"%U%\bin2tap" -o main.tap -a 24200 %game%.bin
rem El nombre en Program: es el del juego en mayusculas
set "GAMEUP=%game%"
for %%L in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do set "GAMEUP=!GAMEUP:%%L=%%L!"
if %mode128%==1 goto :tape128
"%U%\bas2tap" -a10 -s!GAMEUP! speccy\loader.bas loader.tap > nul
copy /b loader.tap + screen.tap + main.tap %game%.tap > nul
goto :clean

:tape128
rem Cargador 128K: cada pagina se carga en 32768 y reubica la copia a su
rem banco (POKE 25000, pagina: RANDOMIZE USR 25002).
"%U%\pasmo" speccy_128\reubica.asm reubica.bin > nul
"%U%\bin2tap" -o reubica.tap -a 25000 reubica.bin
set "pages="
set "tapes=screen.tap + reubica.tap"
for %%p in (1 3 4 6 7) do if exist RAM%%p.bin (
	"%U%\bin2tap" -o ram%%p.tap -a 32768 RAM%%p.bin
	set "pages=!pages!:LOAD ""CODE:POKE VAL "25000",VAL "%%p":RANDOMIZE USR VAL "25002""
	set "tapes=!tapes! + ram%%p.tap"
)
echo 10 BORDER NOT PI:PAPER NOT PI:INK VAL "6":CLS:CLEAR VAL "24199":LOAD ""SCREEN$:LOAD ""CODE!pages!:LOAD ""CODE:RANDOMIZE USR VAL "24200"> loader128.bas
"%U%\bas2tap" -a10 -s!GAMEUP! loader128.bas loader.tap > nul
copy /b loader.tap + !tapes! + main.tap %game%.tap > nul

:clean
if %noclean%==1 goto :done
echo ### LIMPIANDO ###
for %%f in (loader.tap screen.tap main.tap reubica.tap ram?.tap *.scr *.bin zcc_opt.def loader128.bas librarian.default.txt) do del "%%f" > nul 2>&1

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
set "scripts=../script/script.spt"
if not exist scripts.txt exit /b 0
set "scripts="
for /f "usebackq eol=# delims=" %%l in ("scripts.txt") do set "scripts=!scripts!,%%l"
set "scripts=!scripts:~1!"
exit /b 0

rem :sym NOMBRE  -> sym_NOMBRE = direccion (0xHHHH) de NOMBRE en ram1.sym
rem (pasmo escribe "NOMBRE  EQU 0C000H")
:sym
set "a="
for /f "usebackq tokens=1,3" %%a in ("%W%\ram1.sym") do if "%%a"=="%1" set "a=%%b"
if not defined a (echo ERROR: falta %1 en el WYZ player& exit /b 1)
set "a=!a:H=!"
if not "!a:~4,1!"=="" set "a=!a:~1!"
set "sym_%1=0x!a!"
exit /b 0

rem :checkaddr SIMBOLO  -> bad=1 si SIMBOLO esta en 0xC000 o mas en el .map
rem (z88dk escribe "SIMBOLO   = 5F3E, L: CHURROMAIN")
:checkaddr
set "a="
for /f "usebackq tokens=1,3 delims=	 ," %%a in ("%game%.map") do if not defined a if "%%a"=="%1" set "a=%%b"
if not defined a exit /b 0
set /a v=0x!a!
if !v! GEQ 49152 (
	echo ERROR 128K: %1 esta en $!a!, por encima de 0xC000
	set bad=1
)
exit /b 0
