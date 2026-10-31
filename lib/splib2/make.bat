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
for /f "usebackq delims=" %%m in ("sp.lst") do (
	"%B%\sdasz80" -I. -o obj\%%~nm.rel %%m.s
	if errorlevel 1 exit /b 1
)
set "L=..\..\src\dev\speccy"
if exist %L%\splib2.lib del %L%\splib2.lib
"%B%\sdar" -rc %L%\splib2.lib obj\*.rel
rmdir /s /q obj
copy /y spritepack.h %L%\ > nul
echo splib2.lib listo
