@echo off
rem Compila las utilidades de FreeBASIC de src\utils (y msc4) en Windows.
rem Los .exe quedan aqui mismo, en src\utils, sustituyendo a los que hubiera.
rem Necesita fbc (FreeBASIC 1.10, 32 bits) en el PATH.
rem
rem pasmo, zx0, zx7, bas2tap, bin2tap, cpc2cdt, cpctbin2sna y ponedor no se
rem compilan aqui: sus .exe vienen ya hechos.

cd /d "%~dp0"

fbc buildlevel.bas cmdlineparser.bas
fbc librarian.bas cmdlineparser.bas
fbc beepola2s.bas
fbc ihx2bin.bas
fbc gbcheck.bas
fbc ene2h.bas mtparser.bas cmdlineparser.bas
fbc imanol.bas cmdlineparser.bas
fbc mapcnv.bas
fbc mkts_om.bas mtparser.bas cmdlineparser.bas
fbc png2scr.bas
fbc sprcnv.bas
fbc ts2bin.bas
fbc wyzTrackerParser.bas
fbc rle44map_sp.bas mtparser.bas cmdlineparser.bas
fbc rle53map_sp.bas mtparser.bas cmdlineparser.bas
fbc rle62map_sp.bas mtparser.bas cmdlineparser.bas

rem msc4, el compilador de scripts, vive en msc4\ con sus fuentes
fbc -x msc4.exe ..\..\msc4\msc4.bas ..\..\msc4\mtparser.bas ..\..\msc4\cmdlineparser.bas ..\..\msc4\mt5bitEsc.bas

echo Hecho.
