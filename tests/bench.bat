@echo off
rem Mide tamano y velocidad del motor en ZX 48K (equivalente de bench.sh), sin
rem sincronia de frames, para medir trabajo y no esperas: GAME_FRAME_TICKS 0.
rem
rem  * reposo: ciclos de reloj por frame de juego (entre llamadas a _move) sin
rem    tocar nada tras empezar. Es determinista: el trabajo de cada frame no
rem    depende de la velocidad, asi que se puede comparar entre versiones.
rem  * pantalla: ciclos por llamada a draw_scr (pintar una pantalla al entrar,
rem    incluido todo lo que llama), con un recorrido por varias pantallas.
rem
rem Necesita tests\zxrun\zxrun.exe (zxrun.c compilado con gcc).
rem Uso: tests\bench.bat [etiqueta]

setlocal EnableDelayedExpansion
for %%r in ("%~dp0..") do set "REPO=%%~fr"
set "OUT=%REPO%\tests\out\bench"
if not exist "%OUT%" mkdir "%OUT%"
set "label=%~1"
if "%label%"=="" set label=ultimo
set "ZXRUN=%REPO%\tests\zxrun\zxrun.exe"
set "FIRE=PLAYER_CAN_FIRE PLAYER_BULLET_SPEED=8 MAX_BULLETS=3 PLAYER_BULLET_Y_OFFSET=6 PLAYER_BULLET_X_OFFSET=0 ENEMS_LIFE_GAUGE=4 PLAYER_HAS_JUMP -PLAYER_BOOTEE"
set "IDLE=130:1+,134:1-"
set "WALK=130:1+,134:1-,200:p+,320:p-,330:o+,420:o-,430:p+,600:p-,610:o+,800:o-,810:p+,1000:p-"
set "RES=%OUT%\%label%.txt"

> "%RES%" echo config     bytes   reposo c/frame   pantalla c/draw_scr
rem Los defines van en la variable defs: como argumentos de call, el = los partiria
set "defs="
call :bench bootee
set "defs=%FIRE%"
call :bench fire
set "defs=PLAYER_MOGGY_STYLE -PLAYER_BOOTEE -PLAYER_STOMPS_ON_ENEMIES"
call :bench moggy
type "%RES%"
exit /b 0

rem :bench NOMBRE  (con los defines en defs)
:bench
set "n=%1"
call "%REPO%\tests\build.bat" zx "%OUT%\%n%.bin" !defs! GAME_FRAME_TICKS=0 > nul
if errorlevel 1 (>> "%RES%" echo %n%: no compila& exit /b 0)
rem El .map sale de compilar otra vez con el mismo config.h
set "T=%TEMP%\mk1bench%RANDOM%%RANDOM%"
xcopy /e /i /q /y "%REPO%\src" "%T%\src" > nul
copy /y "%OUT%\%n%.bin.config.h" "%T%\src\dev\config.h" > nul
pushd "%T%\src\dev"
call comp-zx.bat noclean > nul 2>&1
popd
set "M=%T%\src\dev\bootee.map"
call :addr _MOVE
set "amove=!a!"
call :addr _DRAW_SCR
set "adraw=!a!"
rem zxrun -count escribe "count N, CICLOS ..." y -incl "incl N llamadas, CICLOS ..."
set "idle=?"
for /f "tokens=1,3 delims=, " %%b in ('call "%ZXRUN%" "%OUT%\%n%.bin" -f 1200 -k %IDLE% -count 0x!amove! 300') do if "%%b"=="count" set "idle=%%c"
set "draw=?"
for /f "tokens=1,2,4 delims=, " %%b in ('call "%ZXRUN%" "%OUT%\%n%.bin" -f 1100 -k %WALK% -incl 0x!adraw! 140') do if "%%b"=="incl" set "draw=%%d (%%c)"
for %%f in ("%OUT%\%n%.bin") do set "size=%%~zf"
>> "%RES%" echo %n%     !size!   !idle!   !draw!
rmdir /s /q "%T%"
exit /b 0

rem :addr SIMBOLO  -> a = direccion hexadecimal de SIMBOLO en el .map
:addr
set "a="
for /f "usebackq tokens=1,3 delims=	 ," %%a in ("%M%") do if not defined a if /i "%%a"=="%1" set "a=%%b"
exit /b 0
