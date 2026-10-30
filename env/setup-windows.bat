@echo off
rem Prepara el entorno de MK1 v3.100 en Windows (equivalente de setup-linux.sh).
rem
rem Antes hay que tener:
rem  * z88dk 1.10 para Windows descomprimido en TOOLS_DIR\z88dk (la version
rem    precompilada para win32 de sourceforge, carpeta z88dk/1.10; tiene que
rem    quedar TOOLS_DIR\z88dk\bin\zcc.exe);
rem  * FreeBASIC 1.10.1 de 32 bits (win32) en el PATH, para compilar las
rem    utilidades (src\utils\build-windows.bat);
rem  * opcional: gcc/g++ (MinGW, w64devkit...) en el PATH.
rem
rem Este script:
rem  * pone el crt0 recortado de MK1 (solo coloca la pila y salta a main) para
rem    ZX y CPC, guardando los de serie como *.stock;
rem  * copia splib2 y cpcrslib a las librerias de z88dk;
rem  * genera TOOLS_DIR\z88env.bat, que hay que llamar antes de compilar.
rem
rem Uso: env\setup-windows.bat [TOOLS_DIR]   (por defecto %USERPROFILE%\mk1tools)

setlocal
set "ENV_DIR=%~dp0"
set "REPO=%ENV_DIR%.."
set "TOOLS=%~1"
if "%TOOLS%"=="" set "TOOLS=%USERPROFILE%\mk1tools"
set "Z=%TOOLS%\z88dk"

if not exist "%Z%\bin\zcc.exe" (
	echo No encuentro %Z%\bin\zcc.exe
	echo Descomprime ahi z88dk 1.10 para Windows y vuelve a ejecutar este script.
	exit /b 1
)

where fbc > nul 2>&1
if errorlevel 1 echo Aviso: fbc no esta en el PATH; hace falta para src\utils\build-windows.bat

rem crt0 recortado de MK1, para ZX y CPC. El de serie de CPC guarda el estado
rem del firmware y baja la pila 6,5K, lo que choca con el mapa de MK1.
if not exist "%Z%\lib\spec_crt0.asm.stock" copy "%Z%\lib\spec_crt0.asm" "%Z%\lib\spec_crt0.asm.stock" > nul
copy /y "%REPO%\lib\spec_crt0.asm" "%Z%\lib\spec_crt0.asm" > nul
if not exist "%Z%\lib\cpc_crt0.asm.stock" copy "%Z%\lib\cpc_crt0.asm" "%Z%\lib\cpc_crt0.asm.stock" > nul
powershell -NoProfile -Command "(Get-Content -Raw '%REPO%\lib\spec_crt0.asm') -replace 'MODULE  zx82_crt0','MODULE  cpc_crt0' | Set-Content -NoNewline '%Z%\lib\cpc_crt0.asm'"

rem Librerias de los backends
copy /y "%REPO%\lib\splib2\splib2f.lib" "%Z%\lib\clibs\splib2f.lib" > nul
copy /y "%REPO%\lib\splib2\splib2f.lib" "%Z%\lib\clibs\splib2.lib" > nul
copy /y "%REPO%\lib\splib2\spritepack.h" "%Z%\include\" > nul
copy /y "%REPO%\lib\cpcrslib-mt\*.lib" "%Z%\lib\clibs\" > nul
copy /y "%REPO%\lib\cpcrslib-mt\cpcrslib_mt.h" "%Z%\include\" > nul

> "%TOOLS%\z88env.bat" (
	echo @echo off
	echo set "Z88DK=%Z%"
	echo set "PATH=%Z%\bin;%%PATH%%"
	echo set "Z80_OZFILES=%Z%\lib\"
	echo set "ZCCCFG=%Z%\lib\config\"
)

echo Listo. Ahora:  call "%TOOLS%\z88env.bat"  y  src\utils\build-windows.bat
exit /b 0
