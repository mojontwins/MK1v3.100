@echo off
rem convert_gb.bat de Ninjajar: lo llama comp-gb.bat en lugar de la
rem conversion de bootee (equivale a convert_assets_gb de game.sh): la fuente
rem y los sprites de siempre (los del nivel 1 y los extras). Lo demas lo
rem hace levels_gb.bat.
if "%U%"=="" set "U=..\utils"

"%U%\mkts_om" platform=gb silent mode=chars in=..\gfx\gb\font.png out=font_raw.bin max=64 > nul || exit /b 1
"%U%\mkts_om" platform=gb silent mode=sprites in=..\gfx\gb\sprites.png out=sprites_raw.bin max=32 > nul || exit /b 1
for %%s in (font sprites) do (
	if exist %%s.bin del %%s.bin
	"%U%\zx0" %%s_raw.bin %%s.bin > nul
)
exit /b 0
