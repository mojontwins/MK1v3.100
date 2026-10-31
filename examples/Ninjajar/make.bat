@echo off
rem Compila Ninjajar con el motor de MK1 v3.100 de este repositorio en Windows
rem (equivalente de make.sh).
rem
rem El juego solo trae lo suyo (dev\: config.h, custom.h, levelset.h, ...;
rem y sus graficos, mapas, enemigos, scripts, textos y musica). make.bat copia src\dev a build\,
rem pone encima los archivos del juego y llama a comp-zx.bat, asi que el juego
rem usa siempre el motor actual. Deja ninjajar.tap aqui.
rem
rem Uso: make.bat [noclean]     (noclean deja los intermedios en build\dev)
rem Requiere las utilidades compiladas (src\utils\build-windows.bat) y GBDK-2020
rem en C:\gbdk (o donde diga GBDK_HOME).
rem
rem Las carpetas del juego y src\utils se enlazan con uniones de directorio
rem (mklink /J), que no necesitan permisos de administrador.

setlocal
set "HERE=%~dp0"
set "HERE=%HERE:~0,-1%"
for %%r in ("%HERE%\..\..") do set "REPO=%%~fr"
set "B=%HERE%\build"

rem Primero se quitan las uniones (rmdir sin /s no entra en ellas)
if exist "%B%" (
	for %%d in (utils gfx map enems levels ogt script texts) do if exist "%B%\%%d" rmdir "%B%\%%d"
	rmdir /s /q "%B%"
)
mkdir "%B%"
xcopy /e /i /q /y "%REPO%\src\dev" "%B%\dev" > nul
mklink /J "%B%\utils" "%REPO%\src\utils" > nul
for %%d in (gfx map enems levels ogt script texts) do mklink /J "%B%\%%d" "%HERE%\%%d" > nul
xcopy /e /q /y "%HERE%\dev\*" "%B%\dev\" > nul

call "%B%\dev\comp-zx.bat" %*
if errorlevel 1 exit /b 1
copy /y "%B%\dev\ninjajar.tap" "%HERE%\" > nul
echo ninjajar.tap listo
