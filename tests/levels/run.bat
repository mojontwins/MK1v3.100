@echo off
rem Prueba del sistema de niveles (equivalente de run.sh): compila bootee con
rem COMPRESSED_LEVELS (dos niveles, ver levels.bat) empezando por el nivel %1
rem y deja el binario y las paginas de RAM para ejecutarlo en zxrun.
rem Uso: [set SCRIPTED=1] tests\levels\run.bat [nivel] [salida]
rem Con SCRIPTED=1 cada nivel lleva su script (nivel1.spt, nivel2.spt).
rem Necesita Python 3 en el PATH.

setlocal EnableDelayedExpansion
set "L=%~1"
if "%L%"=="" set L=0
set "OUTP=%~f2"
if "%~2"=="" set "OUTP=%TEMP%\mk1-levels"
for %%r in ("%~dp0..\..") do set "REPO=%%~fr"
set "T=%TEMP%\mk1levels%RANDOM%%RANDOM%"
xcopy /e /i /q /y "%REPO%\src" "%T%\src" > nul
xcopy /e /i /q /y "%REPO%\tests\levels" "%T%\tests\levels" > nul
set "D=%T%\src\dev"
for %%f in (levels.bat levelset.h librarian.txt custom.h) do copy /y "%REPO%\tests\levels\%%f" "%D%\" > nul

rem behs.txt sale de config.h antes de quitarle la tabla
python -c "import re,sys;s=open(sys.argv[1]).read();m=re.search(r'comportamiento_tiles \[\] = \{(.*?)\};',s,re.S);open(sys.argv[2],'w').write(','.join(v.strip() for v in m.group(1).split(',') if v.strip()))" "%D%\config.h" "%D%\behs.txt"
if errorlevel 1 goto :fail

set "PS=powershell -NoProfile -Command"
if "%SCRIPTED%"=="1" (
	rem Un script por nivel (scripts.txt) como recursos de librarian
	copy /y "%REPO%\tests\levels\scripts.txt" "%D%\" > nul
	(echo script1c.bin& echo script2c.bin) >> "%D%\librarian.txt"
	%PS% "$f='%D%\config.h'; $s=[IO.File]::ReadAllText($f) -replace '(?m)^//#define ACTIVATE_SCRIPTING','#define ACTIVATE_SCRIPTING'; [IO.File]::WriteAllText($f,$s)"
)
%PS% "$f='%D%\config.h'; $s=[IO.File]::ReadAllText($f); $s=$s -replace '(?m)^//#define MODE_128K[^\r\n]*','#define MODE_128K' -replace '(?m)^//#define COMPRESSED_LEVELS[^\r\n]*','#define COMPRESSED_LEVELS' -replace '(?m)^//#define MAX_LEVELS[^\r\n]*','#define MAX_LEVELS 2'; [IO.File]::WriteAllText($f, \"#define TEST_START_LEVEL %L%`n#define PLAYER_CHECK_MAP_BOUNDARIES`n\" + $s)"

pushd "%D%"
call comp-zx.bat noclean > "%OUTP%.log" 2>&1
if errorlevel 1 (
	popd
	powershell -NoProfile -Command "Get-Content -Tail 20 '%OUTP%.log'"
	goto :fail
)
copy /y bootee.bin "%OUTP%.bin" > nul
copy /y bootee.map "%OUTP%.map" > nul
set "args="
for %%r in (RAM?.bin) do (
	copy /y %%r "%OUTP%.%%r" > nul
	set "p=%%~nr"
	set "args=!args! -page !p:~3! %OUTP%.%%r"
)
> "%OUTP%.pages" echo !args!
popd
rmdir /s /q "%T%"
exit /b 0

:fail
rmdir /s /q "%T%"
exit /b 1
