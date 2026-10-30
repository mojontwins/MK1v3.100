@echo off
rem Uso: matrix.bat <binario de msc4> <carpeta de salida> [argumentos extra de msc4...]
rem (equivalente de matrix.sh)
rem Pasa msc4 por los scripts de los juegos de MK1v32 y por un script sintetico
rem con todos los opcodes (all\all.spt), con varias combinaciones de opciones.
rem Las salidas (.bin, interprete, texto) son las que compara la prueba de
rem regresion. La carpeta de juegos de MK1v32 se toma de MK1V32_GAMES (por
rem defecto ..\..\..\mk1v32\games); los que no esten se saltan.
rem Un argumento extra con = va entre comillas ("rooms=20"): si no, cmd lo parte.

setlocal EnableDelayedExpansion
set "M=%~f1"
set "OUT=%~f2"
set "HERE=%~dp0"
set "HERE=%HERE:~0,-1%"
set "R=%MK1V32_GAMES%"
if "%R%"=="" set "R=%HERE%\..\..\..\mk1v32\games"

rem Argumentos extra: todo lo que va tras los dos primeros
set "EXTRA="
shift
shift
:args
if "%~1"=="" goto :argsdone
set "EXTRA=!EXTRA! %~1"
shift
goto :args
:argsdone

if exist "%OUT%" rmdir /s /q "%OUT%"
mkdir "%OUT%"
for %%g in (papaya ababol cosmonautic calavera perils tb) do (
	if exist "%R%\%%g\script\script.spt" call :run %%g "%R%\%%g\script\script.spt"
)
call :run all "%HERE%\all\all.spt"
exit /b 0

rem :run NOMBRE SCRIPT
:run
for %%t in (zx cpc) do for %%m in (jt idx noidx jtall idxall) do (
	if "%%m"=="jt" set "opts=jumptable"
	if "%%m"=="idx" set "opts=rooms=20"
	if "%%m"=="noidx" set "opts=noindexed fastnpant"
	if "%%m"=="jtall" set "opts=jumptable allopcodes"
	if "%%m"=="idxall" set "opts=rooms=20 allopcodes fastnpant"
	set "d=%OUT%\%~1-%%t-%%m"
	mkdir "!d!"
	copy /y "%~2" "!d!\script.spt" > nul
	pushd "!d!"
	"%M%" in=script.spt v=3 target=%%t interpreter=msc4i.asm text=text.bin !opts! !EXTRA! > log.txt 2>&1
	>> log.txt echo exit=!errorlevel!
	popd
)
exit /b 0
