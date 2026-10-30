' buildlevel.bas
' MK1 v3.100 - Construye un "bundle" de nivel independiente de la plataforma.
' Copyleft 2012, 2026 The Mojon Twins
'
' El bundle contiene solo datos de juego (mapa, cerrojos, comportamientos,
' enemigos y hotspots). Los gráficos (tileset, spriteset) son recursos aparte,
' convertidos con las herramientas de cada plataforma.
'
' Formato (ver docs/formato-niveles.md). N = maxpant (pantallas máximas, que
' en el motor es MAP_W * MAP_H de config.h). Todas las secciones tienen
' tamaño fijo para que el motor las descomprima en posiciones fijas:
'
'   +0              cabecera, 16 bytes
'   +16             comportamientos de los tiles, 48 bytes
'   +64             cerrojos, 32 * 4 (np, x, y, st)
'   +192            hotspots, N * 3 (xy, tipo, act)
'   +192 + 3N       enemigos, N * 3 * 10 (x, y, x1, y1, x2, y2, mx, my, t, life)
'   +192 + 33N      mapa, N * 75 (packed) o N * 150 (unpacked)
'
' Cabecera:
'   0 map_w   1 map_h   2 scr_ini   3 ini_x   4 ini_y   5 max_objs
'   6 enems_life   7 scr_fin   8 fin_x   9 fin_y   10 n_cerrojos
'   11 flags (bit 0: mapa unpacked)   12 versión del formato (1)   13-15 0

#include "cmdlineparser.bi"

Const FORMAT_VERSION = 1
Const MAX_CERROJOS = 32
Const HEADER_SIZE = 16

Sub usage
	Print "buildlevel v3.100 (formato " & FORMAT_VERSION & ")"
	Print
	Print "$ buildlevel map=mapa.map ene=enems.ene behs=behs.txt out=level.bin maxpant=N"
	Print "             scr_ini=N ini_x=X ini_y=Y [max_objs=N] [life=N]"
	Print "             [scr_fin=N fin_x=X fin_y=Y] [mapw=W maph=H] [unpacked]"
	Print "             [lock=15] [2bytes] [fixmappy] [noswap]"
	Print
	Print "  map       mapa de Mappy en bruto (.map, un byte por tile)"
	Print "  ene       enemigos y hotspots del colocador (.ene)"
	Print "  behs      48 comportamientos separados por comas"
	Print "  maxpant   pantallas máximas (MAP_W * MAP_H de config.h)"
	Print "  mapw/maph tamaño del mapa en pantallas (por defecto, el del .ene)"
	Print "  unpacked  mapa de 1 byte por tile (UNPACKED_MAP); por defecto 4 bits"
	Print "  lock      tile que hace de cerrojo (15); 99 = sin cerrojos"
	Print "  2bytes    .ene antiguos con hotspots de 2 bytes (xy, tipo)"
	Print "  fixmappy  resta 1 a cada tile leído (mapas de Mappy con offset)"
	Print "  noswap    no ordena x1 < x2, y1 < y2 en los enemigos"
	Print "  scr_fin, fin_x, fin_y: pantalla y tile de final (99 = desactivado)"
End Sub

Sub fail (msg As String)
	Print "** ERROR ** " & msg
	End 1
End Sub

Function numArg (key As String, default As Integer) As Integer
	If sclpGIsDef (key) Then numArg = Val (sclpGetValue (key)) Else numArg = default
End Function

Dim As Integer mapW, mapH, maxPant, unpacked, lockTile, use2bytes, fixmappy, noswap
Dim As Integer fIn, fOut, i, j, x, y, xx, yy, n, nPant, nBolts, nEnems
Dim As uByte d, t, ex, ey, exx, eyy, mn, s1, s2, xy
Dim As Byte sd
Dim As String dummy, linea
Dim As Integer life

sclpParseAttrs
If Not sclpGIsDef ("map") Or Not sclpGIsDef ("ene") Or Not sclpGIsDef ("behs") Or _
   Not sclpGIsDef ("out") Or Not sclpGIsDef ("maxpant") Then usage: End 1

maxPant = numArg ("maxpant", 0)
unpacked = sclpGIsDef ("unpacked")
lockTile = numArg ("lock", 15)
use2bytes = sclpGIsDef ("2bytes")
fixmappy = sclpGIsDef ("fixmappy")
noswap = sclpGIsDef ("noswap")
life = numArg ("life", 1)

' --- Enemigos: la cabecera del .ene trae el tamaño del mapa ---------------

fIn = FreeFile
If Open (sclpGetValue ("ene") For Binary Access Read As #fIn) Then fail "no puedo abrir " & sclpGetValue ("ene")
dummy = Input (256, fIn)
Get #fIn, , d: mapW = d
Get #fIn, , d: mapH = d
Get #fIn, , d: Get #fIn, , d
Get #fIn, , d: nEnems = d
If nEnems <> 3 Then fail "el .ene tiene " & nEnems & " enemigos por pantalla; MK1 v3.100 usa 3"

mapW = numArg ("mapw", mapW)
mapH = numArg ("maph", mapH)
nPant = mapW * mapH
If nPant > maxPant Then fail "el mapa tiene " & nPant & " pantallas y maxpant es " & maxPant
If mapW > 255 Or mapH > 255 Then fail "mapa demasiado grande"

Dim As uByte enems (maxPant * 3 * 10 - 1)
Dim As uByte hotspots (maxPant * 3 - 1)

For i = 0 To nPant * 3 - 1
	Get #fIn, , t: Get #fIn, , ex: Get #fIn, , ey
	Get #fIn, , exx: Get #fIn, , eyy: Get #fIn, , mn
	Get #fIn, , s1: Get #fIn, , s2

	' Igual que ene2h: velocidad con el signo del recorrido, y x1 < x2, y1 < y2
	Dim As Integer sx = Sgn (CInt (exx) - CInt (ex)), sy = Sgn (CInt (eyy) - CInt (ey))
	Dim As Integer outX = 16 * ex, outY = 16 * ey
	If Not noswap Then
		If ex > exx Then Swap ex, exx
		If ey > eyy Then Swap ey, eyy
	End If

	j = i * 10
	enems (j + 0) = outX: enems (j + 1) = outY
	enems (j + 2) = 16 * ex: enems (j + 3) = 16 * ey
	enems (j + 4) = 16 * exx: enems (j + 5) = 16 * eyy
	sd = mn * sx: enems (j + 6) = CUByte (sd And 255)
	sd = mn * sy: enems (j + 7) = CUByte (sd And 255)
	enems (j + 8) = t
	enems (j + 9) = life
Next i

For i = 0 To nPant - 1
	If use2bytes Then
		Get #fIn, , xy: Get #fIn, , t
	Else
		Get #fIn, , ex: Get #fIn, , ey: Get #fIn, , t
		xy = (ex Shl 4) Or (ey And 15)
	End If
	hotspots (i * 3) = xy: hotspots (i * 3 + 1) = t: hotspots (i * 3 + 2) = 1
Next i
Close #fIn

' --- Comportamientos ------------------------------------------------------

Dim As uByte behs (47)
fIn = FreeFile
If Open (sclpGetValue ("behs") For Input As #fIn) Then fail "no puedo abrir " & sclpGetValue ("behs")
n = 0
While Not Eof (fIn) And n < 48
	Input #fIn, linea
	linea = Trim (linea)
	If linea <> "" Then behs (n) = Val (linea): n = n + 1
Wend
Close #fIn
If n <> 48 Then fail "behs tiene " & n & " valores; hacen falta 48"

' --- Mapa y cerrojos --------------------------------------------------------

Dim As Integer bytesPerScreen = IIf (unpacked, 150, 75)
Dim As uByte mapBin (maxPant * bytesPerScreen - 1)
Dim As uByte bolts (MAX_CERROJOS * 4 - 1)
For i = 0 To MAX_CERROJOS - 1
	bolts (i * 4) = &hff		' np = 255: cerrojo vacío (no coincide con ninguna pantalla)
Next i

fIn = FreeFile
If Open (sclpGetValue ("map") For Binary Access Read As #fIn) Then fail "no puedo abrir " & sclpGetValue ("map")
If Lof (fIn) < nPant * 150 Then fail "el mapa ocupa " & Lof (fIn) & " bytes; se esperaban " & (nPant * 150)
Dim As uByte bigMap (mapH * 10 - 1, mapW * 15 - 1)
For y = 0 To mapH * 10 - 1
	For x = 0 To mapW * 15 - 1
		Get #fIn, , d
		If fixmappy Then d = d - 1
		If Not unpacked And d > 15 And d < 64 Then d = d And 15
		bigMap (y, x) = d
	Next x
Next y
Close #fIn

nBolts = 0
For yy = 0 To mapH - 1
	For xx = 0 To mapW - 1
		Dim As Integer np = yy * mapW + xx, k = 0, ac = 0
		For y = 0 To 9
			For x = 0 To 14
				d = bigMap (yy * 10 + y, xx * 15 + x)
				If d = lockTile Then
					If nBolts = MAX_CERROJOS Then fail "más de " & MAX_CERROJOS & " cerrojos"
					bolts (nBolts * 4 + 0) = np
					bolts (nBolts * 4 + 1) = x
					bolts (nBolts * 4 + 2) = y
					bolts (nBolts * 4 + 3) = 1
					nBolts = nBolts + 1
				End If
				If unpacked Then
					mapBin (np * 150 + y * 15 + x) = d
				Else
					If d > 15 Then fail "tile " & d & " en mapa packed (pantalla " & np & ")"
					If (k And 1) = 0 Then ac = d Shl 4 Else mapBin (np * 75 + (k Shr 1)) = ac Or d
					k = k + 1
				End If
			Next x
		Next y
	Next xx
Next yy

' --- Salida ----------------------------------------------------------------

Dim As uByte header (HEADER_SIZE - 1)
header (0) = mapW
header (1) = mapH
header (2) = numArg ("scr_ini", 0)
header (3) = numArg ("ini_x", 0)
header (4) = numArg ("ini_y", 0)
header (5) = numArg ("max_objs", 99)
header (6) = life
header (7) = numArg ("scr_fin", 99)
header (8) = numArg ("fin_x", 99)
header (9) = numArg ("fin_y", 99)
header (10) = nBolts
header (11) = IIf (unpacked, 1, 0)
header (12) = FORMAT_VERSION

fOut = FreeFile
Kill sclpGetValue ("out")
If Open (sclpGetValue ("out") For Binary Access Write As #fOut) Then fail "no puedo crear " & sclpGetValue ("out")
Put #fOut, , header ()
Put #fOut, , behs ()
Put #fOut, , bolts ()
Put #fOut, , hotspots ()
Put #fOut, , enems ()
Put #fOut, , mapBin ()
Print "buildlevel: " & sclpGetValue ("out") & " ~ " & mapW & "x" & mapH & " pantallas, " & _
	nBolts & " cerrojos, " & Lof (fOut) & " bytes (maxpant " & maxPant & ")"
Close #fOut
