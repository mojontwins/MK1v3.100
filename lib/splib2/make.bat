@echo off
rem Construye splib2.lib con sdasz80 y sdar (de GBDK-2020) a partir de los
rem modulos de sp.lst, y la deja, junto con spritepack.h, en src\dev\speccy,
rem que es donde la busca comp-zx.
rem Necesita GBDK_HOME (por defecto C:\gbdk).

cd /d "%~dp0"
if not defined GBDK_HOME set "GBDK_HOME=C:\gbdk"
set "B=%GBDK_HOME%\bin"
if exist obj rmdir /s /q obj
mkdir obj
rem sdar no expande *.rel en Windows: cada modulo se anade al ensamblarlo
set "L=..\..\src\dev\speccy"
if exist %L%\splib2.lib del %L%\splib2.lib
for /f "usebackq delims=" %%m in ("sp.lst") do (
	"%B%\sdasz80" -I. -o obj\%%~nm.rel %%m.s
	if errorlevel 1 exit /b 1
	"%B%\sdar" -rc %L%\splib2.lib obj\%%~nm.rel
	if errorlevel 1 exit /b 1
)
rmdir /s /q obj
copy /y spritepack.h %L%\ > nul
echo splib2.lib listo
