@echo off
rem Construye cpcrslib.lib (variante normal) y cpcrslib_fg.lib (variante fg,
rem con PASARPORDETRAS) con sdasz80 y sdar (de GBDK-2020) a partir de los
rem modulos de cpcrslib.lst, y las deja, junto con cpcrslib_mt.h, en
rem src\dev\cpc, que es donde las busca comp-cpc.
rem Necesita GBDK_HOME (por defecto C:\gbdk).

setlocal
cd /d "%~dp0"
if not defined GBDK_HOME set "GBDK_HOME=C:\gbdk"
set "B=%GBDK_HOME%\bin"
set "L=..\..\src\dev\cpc"
call :build 0 cpcrslib.lib
if errorlevel 1 exit /b 1
call :build 1 cpcrslib_fg.lib
if errorlevel 1 exit /b 1
copy /y cpcrslib_mt.h %L%\ > nul
exit /b 0

rem :build PASARPORDETRAS LIBRERIA
:build
if exist obj rmdir /s /q obj
mkdir obj
for /f "usebackq delims=" %%l in ("CPCconfig.inc") do (
	if "%%l"=="	PASARPORDETRAS = 0" (echo 	PASARPORDETRAS = %1) else (echo %%l)
) >> obj\CPCconfig.inc
rem sdar no expande *.rel en Windows: cada modulo se anade al ensamblarlo
if exist %L%\%2 del %L%\%2
for /f "usebackq delims=" %%m in ("cpcrslib.lst") do (
	"%B%\sdasz80" -Iobj -o obj\%%m.rel %%m.s
	if errorlevel 1 exit /b 1
	"%B%\sdar" -rc %L%\%2 obj\%%m.rel
	if errorlevel 1 exit /b 1
)
rmdir /s /q obj
echo %2 listo
exit /b 0
