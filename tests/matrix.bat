@echo off
rem Compila el motor con distintas combinaciones de config.h (equivalente de
rem matrix.sh).
rem Uso: tests\matrix.bat [zx|cpc|all] [filtro]
rem   filtro: expresion de findstr que tiene que cumplir el nombre
rem Deja binarios y logs en tests\out\matrix\
rem
rem Las configuraciones son las lineas "::CFG nombre|defines" del final de este
rem archivo (las mismas que matrix.sh). Los defines pueden usar $FIRE,
rem $SIDE_JUMP, $TOP, $TEXT, $SCRIPT y $REPO, que se sustituyen por su valor.
rem Un valor con & o parentesis va entre comillas.

setlocal EnableDelayedExpansion
for %%r in ("%~dp0..") do set "REPO=%%~fr"
set "OUT=%REPO%\tests\out\matrix"
if not exist "%OUT%" mkdir "%OUT%"
set "targets=%~1"
if "%targets%"=="" set targets=all
if "%targets%"=="all" set "targets=zx cpc"
set "filter=%~2"
if "%filter%"=="" set "filter=."

set "FIRE=PLAYER_CAN_FIRE PLAYER_BULLET_SPEED=8 MAX_BULLETS=3 PLAYER_BULLET_Y_OFFSET=6 PLAYER_BULLET_X_OFFSET=0 ENEMS_LIFE_GAUGE=4"
set "SIDE_JUMP=PLAYER_HAS_JUMP -PLAYER_BOOTEE"
set "TOP=PLAYER_MOGGY_STYLE -PLAYER_BOOTEE -PLAYER_STOMPS_ON_ENEMIES"
set "TEXT=LINE_OF_TEXT=0 LINE_OF_TEXT_X=1 LINE_OF_TEXT_ATTR=71"
set "SCRIPT="@%REPO%\tests\script\script.spt" %TEXT% SCRIPTING_KEY_M"

set pass=0
set fail=0
for %%t in (%targets%) do (
	for /f "tokens=1,* delims=|" %%a in ('findstr /B /C:"::CFG " "%~f0"') do (
		set "name=%%a"
		set "name=!name:~6!"
		set "defs=%%b"
		if defined defs (
			set "defs=!defs:$SCRIPT=%SCRIPT%!"
			set "defs=!defs:$SIDE_JUMP=%SIDE_JUMP%!"
			set "defs=!defs:$FIRE=%FIRE%!"
			set "defs=!defs:$TOP=%TOP%!"
			set "defs=!defs:$TEXT=%TEXT%!"
			set "defs=!defs:$REPO=%REPO%!"
		)
		call :one %%t
	)
)
echo == %pass% ok, %fail% fallos
if %fail%==0 exit /b 0
exit /b 1

rem :one PLATAFORMA  -> compila la configuracion name/defs
:one
echo !name!| findstr /R /C:"%filter%" > nul || exit /b 0
rem 128K es solo ZX
if "%1"=="cpc" if "!name:~0,4!"=="128k" exit /b 0
set "bin=%OUT%\%1-!name!.bin"
call "%REPO%\tests\build.bat" %1 "!bin!" !defs!
if errorlevel 1 goto :onefail
for %%f in ("!bin!") do echo   ok   %1  !name!  %%~zf bytes
set /a pass+=1
exit /b 0
:onefail
set "err="
for /f "delims=" %%e in ('findstr /I /C:"error" "!bin!.log"') do if not defined err set "err=%%e"
if not defined err set "err=sin mensaje de error"
echo FALLO  %1  !name!  !err:~0,110!
set /a fail+=1
exit /b 0

rem Configuraciones: nombre|defines
::CFG bootee|
::CFG jump|$SIDE_JUMP
::CFG jetpac|PLAYER_HAS_JETPAC -PLAYER_BOOTEE
::CFG cumjump|$SIDE_JUMP PLAYER_CUMULATIVE_JUMP
::CFG kills|PLAYER_KILLS_ENEMIES -PLAYER_STOMPS_ON_ENEMIES PLAYER_SHOW_KILLS
::CFG minkill|PLAYER_KILLS_ENEMIES -PLAYER_STOMPS_ON_ENEMIES PLAYER_MIN_KILLABLE=2
::CFG flicker|PLAYER_FLICKERS -PLAYER_BOUNCES -SLOW_DRAIN
::CFG nokeys|DEACTIVATE_KEYS
::CFG noobjs|DEACTIVATE_OBJECTS
::CFG oneobj|ONLY_ONE_OBJECT
::CFG noevil|DEACTIVATE_EVIL_TILE
::CFG bbox16|-BOUNDING_BOX_8_BOTTOM -SMALL_COLLISION
::CFG bboxc|-BOUNDING_BOX_8_BOTTOM BOUNDING_BOX_8_CENTERED
::CFG hot3|USE_HOTSPOTS_TYPE_3
::CFG fire|$SIDE_JUMP $FIRE
::CFG fireup|$SIDE_JUMP $FIRE CAN_FIRE_UP
::CFG twobtn|$SIDE_JUMP $FIRE USE_TWO_BUTTONS
::CFG ammo|$SIDE_JUMP $FIRE MAX_AMMO=99 AMMO_REFILL=50 INITIAL_AMMO=0
::CFG lbullets|$SIDE_JUMP $FIRE LIMITED_BULLETS LB_FRAMES=4
::CFG respawn|$SIDE_JUMP $FIRE RESPAWN_ON_ENTER FIRE_MIN_KILLABLE=2
::CFG breakable|$SIDE_JUMP $FIRE BREAKABLE_WALLS BREAKABLE_WALLS_LIFE=1
::CFG rrespawn|$SIDE_JUMP $FIRE ENABLE_RANDOM_RESPAWN FANTY_MAX_V=1024 FANTY_A=64 FANTIES_LIFE_GAUGE=10
::CFG type6|ENABLE_CUSTOM_TYPE_6 TYPE_6_FIXED_SPRITE=2 SIGHT_DISTANCE=104 FANTY_MAX_V=1024 FANTY_A=64
::CFG pursuers|ENABLE_PURSUERS PLAYER_KILLS_ENEMIES -PLAYER_STOMPS_ON_ENEMIES "DEATH_COUNT_EXPRESSION=20+(rand()&15)"
::CFG moggy|$TOP
::CFG moggyfire|$TOP $FIRE
::CFG moggypush|$TOP PLAYER_PUSH_BOXES
::CFG push|PLAYER_PUSH_BOXES
::CFG firepush|$SIDE_JUMP $FIRE PLAYER_PUSH_BOXES FIRE_TO_PUSH
::CFG bouncewalls|$TOP PLAYER_BOUNCE_WITH_WALLS
::CFG pause|PAUSE_ABORT
::CFG timer|TIMER_ENABLE TIMER_INITIAL=99 TIMER_REFILL=30 TIMER_LAPSE=32 TIMER_START TIMER_KILL_0 TIMER_AUTO_RESET SHOW_TIMER_OVER PLAYER_SHOW_TIMER
::CFG timergo|TIMER_ENABLE TIMER_INITIAL=99 TIMER_LAPSE=32 TIMER_START TIMER_GAMEOVER_0 SHOW_TIMER_OVER
::CFG checkpts|ENABLE_CHECKPOINTS CP_RESET_WHEN_DYING
::CFG tilanims|ENABLE_TILANIMS=32
::CFG shadows|USE_AUTO_SHADOWS
::CFG tshadows|USE_AUTO_TILE_SHADOWS
::CFG unpacked|UNPACKED_MAP
::CFG nomasks|NO_MASKS
::CFG getxmore|GET_X_MORE
::CFG bounds|PLAYER_CHECK_MAP_BOUNDARIES MAP_BOTTOM_KILLS
::CFG notdirect|-DIRECT_TO_PLAY
::CFG stepsnd|$SIDE_JUMP PLAYER_STEP_SOUND
::CFG altanim|$SIDE_JUMP PLAYER_ALTERNATE_ANIMATION
::CFG script|$SCRIPT
::CFG scriptall|"@$REPO\msc4\tests\all\all.spt" $TEXT TIMER_ENABLE
::CFG scriptfull|"@$REPO\tests\script\full.spt" ITEM_X=28 ITEM_Y=1 TIMER_ENABLE TIMER_INITIAL=99 TIMER_LAPSE=32 TIMER_START $SIDE_JUMP $FIRE BREAKABLE_WALLS BREAKABLE_WALLS_LIFE=1 ENABLE_RANDOM_RESPAWN FANTY_MAX_V=1024 FANTY_A=64 FANTIES_LIFE_GAUGE=10 PLAYER_PUSH_BOXES
::CFG scriptmoggy|"@$REPO\tests\script\full.spt" TIMER_ENABLE TIMER_INITIAL=99 TIMER_LAPSE=32 $TOP PLAYER_PUSH_BOXES PLAYER_KILLS_ENEMIES
::CFG scriptcp|$SCRIPT ENABLE_CHECKPOINTS CP_RESET_WHEN_DYING
::CFG 128k|MODE_128K
::CFG 128kfire|MODE_128K $SIDE_JUMP $FIRE
::CFG 128kpause|MODE_128K PAUSE_ABORT
::CFG 128kscript|MODE_128K $SCRIPT
