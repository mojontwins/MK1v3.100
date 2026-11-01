@echo off
rem levels_gb.bat de Ninjajar: lo mismo que levels.bat para Game Boy
rem (equivalente de levels_gb.sh). Lo llama comp-gb.bat (despues de msc4 y
rem antes de librarian).
rem
rem Los bundles son los mismos (bundles.bat). Los graficos salen de gfx\gb
rem con mkts_om: un tileset de 192 patrones por nivel, los spritesets (16
rem sprites) y las pantallas fijas de 160x144. Los scripts, los textos y los
rem creditos van sin comprimir (se leen directamente de la ROM), pero con los
rem mismos nombres que en ZX para que levelset.h y librarian sirvan igual.
if "%U%"=="" set "U=..\utils"

call bundles.bat || exit /b 1

for %%t in (0 1 2 3 4 5 8 9 A B C X Y Z) do (
	"%U%\mkts_om" platform=gb silent mode=strait2x2 in=..\gfx\gb\work%%t.png out=ts%%t.bin max=48 > nul || exit /b 1
	call :z ts%%t.bin ts%%tc.bin || exit /b 1
)
for %%s in (0 1 2 4) do (
	"%U%\mkts_om" platform=gb silent mode=sprites in=..\gfx\gb\sprites%%s.png out=ss%%s.bin max=16 > nul || exit /b 1
	call :z ss%%s.bin ss%%sc.bin || exit /b 1
)

rem Los scripts de los niveles (msc4 ya ha dejado los .spt.bin), tal cual
for %%s in (4 5 8 9 A B C D X Y Z) do copy /y ..\script\script%%s.spt.bin script%%sc.bin > nul

rem Pantallas fijas
for %%s in (title ending ending1 ending2 ending3 ending4 dedicado level) do (
	rem (mkts_om avisa si la pantalla tiene mas de 192 patrones)
	"%U%\mkts_om" platform=gb mode=scr in=..\gfx\gb\%%s.png out=%%s_raw.bin > mkts.log || exit /b 1
	findstr /I "WARNING" mkts.log
	call :z %%s_raw.bin %%s.bin || exit /b 1
)

rem Los creditos van tal cual (lineas de 32 caracteres), como los textos
copy /y ..\texts\credits.bin credits.bin > nul
exit /b 0

:z
if exist %2 del %2
"%U%\zx0" %1 %2 > nul
exit /b
