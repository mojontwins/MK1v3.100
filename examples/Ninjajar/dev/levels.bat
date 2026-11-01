@echo off
rem levels.bat de Ninjajar: construye los niveles (bundles.bat), los
rem tilesets, los spritesets, los scripts y las pantallas (equivalente de levels.sh). Lo
rem llama comp-zx.bat (despues de msc4 y antes de librarian). Ver
rem docs/formato-niveles.md.
if "%U%"=="" set "U=..\utils"

call bundles.bat || exit /b 1

for %%t in (0 1 2 3 4 5 8 9 A B C X Y Z) do (
	"%U%\ts2bin" nofont ..\gfx\work%%t.png ts%%t.bin 7 > nul || exit /b 1
	call :z ts%%t.bin ts%%tc.bin || exit /b 1
)
for %%s in (0 1 2 4) do (
	"%U%\sprcnv" ..\gfx\sprites%%s.png ss%%s.bin > nul || exit /b 1
	call :z ss%%s.bin ss%%sc.bin || exit /b 1
)

rem Los scripts de los niveles (msc4 ya ha dejado los .spt.bin)
for %%s in (4 5 8 9 A B C D X Y Z) do call :z ..\script\script%%s.spt.bin script%%sc.bin || exit /b 1

rem Pantallas completas
for %%s in (title marco ending ending1 ending2 ending3 ending4 dedicado level) do (
	"%U%\png2scr" ..\gfx\%%s.png %%s.scr > nul || exit /b 1
	call :z %%s.scr %%s.bin || exit /b 1
)

rem Los creditos van tal cual (lineas de 32 caracteres), como los textos
copy /y ..\texts\credits.bin credits.bin > nul
exit /b 0

:z
if exist %2 del %2
"%U%\zx0" %1 %2 > nul
exit /b
