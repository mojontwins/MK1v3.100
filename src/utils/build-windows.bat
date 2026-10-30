@echo off
rem Compila las utilidades de src\utils para Windows en src\utils\win\
rem (equivalente de build-linux.sh).
rem
rem Requiere:
rem  * FreeBASIC 1.10 de 32 bits (win32) en el PATH: libfbpng.a es de 32 bits.
rem    Las utilidades que leen PNG enlazan ademas con zlib (#inclib "z"): si el
rem    fbc no trae libz, deja libz.a o libz.dll.a en src\utils. zlib1.dll se
rem    copia junto a los .exe.
rem  * Opcional: gcc y g++ en el PATH (MinGW, w64devkit...). Con ellos se
rem    compilan las herramientas en C/C++ (zx0, zx7, bas2tap, bin2tap,
rem    cpc2cdt, cpctbin2sna, apultra, pasmo); sin ellos se copian los .exe que
rem    ya trae src\utils (apultra no esta precompilado).
rem
rem Uso: build-windows.bat

setlocal EnableDelayedExpansion
set "U=%~dp0"
set "U=%U:~0,-1%"
set "OUT=%U%\win"
set "M=%U%\..\..\msc4"
set "S=%U%\src"
if not exist "%OUT%" mkdir "%OUT%"

where fbc > nul 2>&1
if errorlevel 1 (echo No encuentro fbc en el PATH. Ver env\setup-windows.bat& exit /b 1)

rem Utilidades en FreeBASIC. ponedor (GUI) se copia ya compilado; gui, bmp y
rem los parsers son modulos que se enlazan con las que los usan.
for %%f in ("%U%\*.bas") do (
	call :fb %%~nf
	if errorlevel 1 exit /b 1
)
copy /y "%U%\ponedor.exe" "%OUT%\" > nul
copy /y "%U%\zlib1.dll" "%OUT%\" > nul

rem msc4 (compilador de scripts) vive en msc4\, con sus pruebas y plantillas
fbc -p "%U%" -x "%OUT%\msc4.exe" "%M%\msc4.bas" "%M%\mtparser.bas" "%M%\cmdlineparser.bas" "%M%\mt5bitEsc.bas" > "%OUT%\msc4.log" 2>&1
if errorlevel 1 (echo FALLO msc4& type "%OUT%\msc4.log"& exit /b 1)
del "%OUT%\msc4.log"
rem Plantillas de los interpretes en ensamblador
xcopy /e /i /y /q "%M%\targets" "%OUT%\targets" > nul
echo   ok  msc4

rem Herramientas externas (C/C++)
where gcc > nul 2>&1
if errorlevel 1 goto :prebuilt
gcc -O2 -w -o "%OUT%\zx0.exe" "%S%\ZX0\src\zx0.c" "%S%\ZX0\src\optimize.c" "%S%\ZX0\src\compress.c" "%S%\ZX0\src\memory.c" && echo   ok  zx0
gcc -O2 -w -o "%OUT%\zx7.exe" "%S%\zx7\zx7.c" "%S%\zx7\optimize.c" "%S%\zx7\compress.c" && echo   ok  zx7
gcc -O2 -w -o "%OUT%\bas2tap.exe" "%S%\bas2tap\bas2tap.c" -lm && echo   ok  bas2tap
gcc -O2 -o "%OUT%\bin2tap.exe" "%S%\bin2tap-c\bin2tap.c" && echo   ok  bin2tap
gcc -O2 -w -fcommon -o "%OUT%\cpc2cdt.exe" "%S%\cpc2cdt\src\cpc2cdt.c" "%S%\cpc2cdt\src\tinytape.c" && echo   ok  cpc2cdt
g++ -O2 -w -o "%OUT%\cpctbin2sna.exe" "%S%\cpctbin2sna\main.cpp" "%S%\cpctbin2sna\mem_imgs.cpp" && echo   ok  cpctbin2sna
set "AP="
for %%c in ("%S%\apultra\src\*.c" "%S%\apultra\src\libdivsufsort\lib\*.c") do set "AP=!AP! "%%~c""
gcc -O2 -w -I"%S%\apultra\src\libdivsufsort\include" -o "%OUT%\apultra.exe" !AP! && echo   ok  apultra
set "PS=%S%\pasmo\pasmo"
g++ -O2 -std=c++14 -w -DNDEBUG -DVERSION=0.5.5.paged -o "%OUT%\pasmo.exe" ^
	"%PS%\asm.cxx" "%PS%\cpc.cxx" "%PS%\pasmo.cxx" "%PS%\tap.cxx" "%PS%\asmerror.cxx" ^
	"%PS%\macro.cxx" "%PS%\pasmotypes.cxx" "%PS%\token.cxx" "%PS%\asmfile.cxx" ^
	"%PS%\nullstream.cxx" "%PS%\spectrum.cxx" "%PS%\tzx.cxx" "%PS%\memmap.cxx" && echo   ok  pasmo
goto :end

:prebuilt
echo No hay gcc: se copian las herramientas en C ya compiladas de src\utils
for %%t in (zx0 zx7 bas2tap bin2tap cpc2cdt cpctbin2sna pasmo) do (
	copy /y "%U%\%%t.exe" "%OUT%\" > nul && echo   ok  %%t ^(precompilado^)
)

:end
echo Utilidades en %OUT%
exit /b 0

rem :fb NOMBRE  -> compila NOMBRE.bas con los modulos que incluya
:fb
for %%x in (ponedor gui bmp cmdlineparser mtparser mt5bitEsc) do if /i "%1"=="%%x" exit /b 0
set "extra="
for %%m in (mtparser cmdlineparser mt5bitEsc) do (
	findstr /C:"%%m.bi" "%U%\%1.bas" > nul && set "extra=!extra! "%U%\%%m.bas""
)
fbc -p "%U%" -x "%OUT%\%1.exe" "%U%\%1.bas" !extra! > "%OUT%\%1.log" 2>&1
if errorlevel 1 (echo FALLO %1& type "%OUT%\%1.log"& exit /b 1)
del "%OUT%\%1.log"
echo   ok  %1
exit /b 0
