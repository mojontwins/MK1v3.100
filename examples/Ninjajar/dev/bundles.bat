@echo off
rem bundles.bat de Ninjajar: los bundles de los niveles (datos de juego,
rem iguales en todas las maquinas). Lo llaman levels.bat (ZX) y levels_gb.bat
rem (Game Boy). Ver docs/formato-niveles.md.
if "%U%"=="" set "U=..\utils"

rem          mapa scr_ini ini_x ini_y ancho alto max_objs vida behs motor mira
call :build 5  8  7 7  7  3 99  1 5  0 1 || exit /b 1
call :build 0  0  2 2  1 12  1  1 0  0 0 || exit /b 1
call :build 2  9 12 2 10  1  1  1 2  1 1 || exit /b 1
call :build 4  0  3 2 12  1  1  1 4  0 0 || exit /b 1
call :build 6  0  1 1  4  3  1  1 2  1 0 || exit /b 1
call :build 8 13 10 6  7  3 99  1 8  0 1 || exit /b 1
call :build 7  0  2 2 10  2  1  1 4  0 0 || exit /b 1
call :build 3  0  3 2 10  2  1  1 3  0 0 || exit /b 1
call :build 1  0  2 2 12  1  1  1 1  0 0 || exit /b 1
call :build A  0  1 1  7  2 99  1 A  1 0 || exit /b 1
call :build 9  9  1 6  4  4  1  1 9  0 0 || exit /b 1
call :build B  0  1 3  2  6  1  1 B  0 0 || exit /b 1
call :build D  0  4 2 10  1  1  1 1  0 0 || exit /b 1
call :build C  9 12 5  1 10  1  1 C  0 1 || exit /b 1
call :build E  0  1 1  8  2  1  1 3  0 0 || exit /b 1
call :build F  0  7 1  1 12  1  1 0  0 0 || exit /b 1
call :build Z 15  7 7  4  5 99  1 Z  0 1 || exit /b 1
call :build Y  0  1 1 20  1  1  1 Y  0 0 || exit /b 1
call :build X  0 12 8  3  1 99  1 X  0 1 || exit /b 1
exit /b 0

:build
rem (los parametros 10 y 11 se leen tras dos shift: pasan a ser %8 y %9)
set "bm=%1" & set "bs=%2" & set "bx=%3" & set "by=%4" & set "bw=%5" & set "bh=%6" & set "bo=%7" & set "bl=%8" & set "bb=%9"
shift
shift
"%U%\buildlevel" map=..\map\mapa%bm%.map ene=..\enems\enems%bm%.ene behs=..\levels\behs%bb%.txt ^
	out=level%bm%.bin maxpant=21 scr_ini=%bs% ini_x=%bx% ini_y=%by% mapw=%bw% maph=%bh% ^
	max_objs=%bo% life=%bl% engine=%8 facing=%9 lock=99 > nul || exit /b 1
call :z level%bm%.bin level%bm%c.bin
exit /b

:z
if exist %2 del %2
"%U%\zx0" %1 %2 > nul
exit /b
