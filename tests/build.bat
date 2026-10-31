@echo off
rem Compila el juego en una copia limpia de src\ (no toca el arbol de trabajo).
rem Equivalente de build.sh; los cambios en config.h los hace defs.ps1.
rem
rem Uso: tests\build.bat zx|cpc SALIDA.bin [DEF[=valor] ...] [-UNDEF ...] [@script.spt]
rem   DEF        activa (o anade) "#define DEF valor" en config.h
rem   -UNDEF     comenta "#define UNDEF"
rem   @archivo   usa ese script (src\script\script.spt) y activa ACTIVATE_SCRIPTING
rem Un valor con & o parentesis va entre comillas: "DEF=20+(rand()&15)".
rem Escribe el log del compilador en SALIDA.log. Devuelve 0 si compila.

setlocal
for %%r in ("%~dp0..") do set "REPO=%%~fr"
set "target=%~1"
set "out=%~f2"

set "T=%TEMP%\mk1build%RANDOM%%RANDOM%"
xcopy /e /i /q /y "%REPO%\src" "%T%\src" > nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%REPO%\tests\defs.ps1" "%T%\src" %*
if errorlevel 1 (rmdir /s /q "%T%"& exit /b 1)

pushd "%T%\src\dev"
set ok=0
call comp-%target%.bat noclean > "%out%.log" 2>&1
if not errorlevel 1 if exist bootee.bin set ok=1
copy /y config.h "%out%.config.h" > nul
if %ok%==1 (
	copy /y bootee.bin "%out%" > nul
	if exist bootee.map copy /y bootee.map "%~dpn2.map" > nul
	rem CPC: el .sna, para tests\cpcrun
	if exist bootee.sna copy /y bootee.sna "%~dpn2.sna" > nul
	rem 128K: paginas de RAM
	for %%r in (RAM?.bin) do copy /y %%r "%~dpn2.%%r" > nul
)
popd
rmdir /s /q "%T%"
if %ok%==1 exit /b 0
exit /b 1
