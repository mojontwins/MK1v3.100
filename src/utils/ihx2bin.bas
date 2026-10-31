' ihx2bin
' Copyleft 2026 The Mojon Twins
'
' Pasa el .ihx que genera el enlazador de SDCC (sdldz80) a un binario que
' empieza en la dirección de carga y acaba en el último byte con datos. Lo que
' no está en el .ihx (las variables del final) no se escribe; los huecos de en
' medio (las variables de delante del código en 128K) van a cero.
'
' Con el .map del enlazador (sdldz80 -m -w) comprueba además el mapa de
' memoria del programa:
'  * que no hay variables con valor inicial (área _INITIALIZER vacía): el
'    motor no las copia al arrancar, tienen que ser const o tomar su valor en
'    el código;
'  * que el programa con sus variables acaba antes de __mem_limit (los bloques
'    de memoria de los sprites en ZX, los buffers fijos en CPC);
'  * con "128k", que _low_end queda por debajo de 0xC000: lo que va antes se
'    usa con otra página de RAM puesta.
'
' Uso: ihx2bin entrada.ihx salida.bin dirección [mapa.map [128k]]
'      (la dirección en decimal o con 0x delante)

Dim Shared As UByte mem (65535)
Dim Shared As String symNames (), symAddrs ()
Dim Shared As Integer nSyms

' Dirección de un símbolo del .map, o -1 si no está
Function symAddr (s As String) As Integer
	Dim As Integer i
	For i = 0 To nSyms - 1
		If symNames (i) = s Then Return Val ("&H" & symAddrs (i))
	Next i
	Return -1
End Function

Function hex4 (n As Integer) As String
	Return "$" & Hex (n, 4)
End Function

Function isHexStr (s As String) As Integer
	Dim As Integer i
	Dim As String c
	For i = 1 To Len (s)
		c = UCase (Mid (s, i, 1))
		If Not ((c >= "0" And c <= "9") Or (c >= "A" And c <= "F")) Then Return 0
	Next i
	Return -1
End Function

Dim As String linea, fileIn, fileOut, fileMap, a, b
Dim As Integer fIn, fOut, n, i, addr, typ, org, hiAddr, p, errors, heap, memLimit, lowEnd

fileIn = Command (1): fileOut = Command (2): fileMap = Command (4)
If fileIn = "" Or fileOut = "" Or Command (3) = "" Then
	Print "Uso: ihx2bin entrada.ihx salida.bin dirección [mapa.map [128k]]"
	End 1
End If
If LCase (Left (Command (3), 2)) = "0x" Then org = Val ("&H" & Mid (Command (3), 3)) Else org = Val (Command (3))

fIn = FreeFile
If Open (fileIn For Input As #fIn) Then
	Print "No puedo abrir " & fileIn
	End 1
End If
hiAddr = -1
While Not Eof (fIn)
	Line Input #fIn, linea
	linea = Trim (linea)
	If Left (linea, 1) = ":" Then
		n = Val ("&H" & Mid (linea, 2, 2))
		addr = Val ("&H" & Mid (linea, 4, 4))
		typ = Val ("&H" & Mid (linea, 8, 2))
		' Tipo 0: datos (el 1, fin de fichero, no trae nada)
		If typ = 0 Then
			For i = 0 To n - 1
				mem (addr + i) = Val ("&H" & Mid (linea, 10 + i * 2, 2))
			Next i
			If addr + n - 1 > hiAddr Then hiAddr = addr + n - 1
		End If
	End If
Wend
Close #fIn

If hiAddr < org Then
	Print "No hay datos a partir de " & org
	End 1
End If

fOut = FreeFile
Kill fileOut
Open fileOut For Binary As #fOut
For i = org To hiAddr
	Put #fOut, , mem (i)
Next i
Close #fOut
Print fileOut & ": " & (hiAddr - org + 1) & " bytes"

If fileMap = "" Then End 0

' Símbolos del .map: líneas "     0000B0E4  nombre   módulo"
fIn = FreeFile
If Open (fileMap For Input As #fIn) Then
	Print "No puedo abrir " & fileMap
	End 1
End If
While Not Eof (fIn)
	Line Input #fIn, linea
	linea = Trim (linea, Any !" \t\r")
	a = Left (linea, 8)
	If Len (linea) > 10 And Mid (linea, 9, 1) = " " And isHexStr (a) Then
		b = Trim (Mid (linea, 10), Any !" \t")
		p = InStr (b, " ")
		If p Then b = Left (b, p - 1)
		ReDim Preserve symNames (nSyms), symAddrs (nSyms)
		symNames (nSyms) = b: symAddrs (nSyms) = a
		nSyms += 1
	End If
Wend
Close #fIn

If symAddr ("l__INITIALIZER") > 0 Then
	Print "ERROR: hay variables globales con valor inicial (" & symAddr ("l__INITIALIZER") & " bytes)."
	Print "       Hazlas const o dales su valor en el código."
	errors += 1
End If

heap = symAddr ("s__HEAP"): memLimit = symAddr ("__mem_limit")
If heap >= 0 And memLimit >= 0 Then
	Print "Programa y variables hasta " & hex4 (heap) & ", libre hasta " & hex4 (memLimit) & ": " & (memLimit - heap) & " bytes"
	If heap > memLimit Then
		Print "ERROR: el programa y sus variables pasan de " & hex4 (memLimit) & " (MEM_LIMIT, churromain.c)."
		errors += 1
	End If
End If

If LCase (Command (5)) = "128k" Then
	lowEnd = symAddr ("_low_end")
	If lowEnd < 0 Then
		Print "ERROR: falta _low_end en " & fileMap
		errors += 1
	ElseIf lowEnd > &HC000 Then
		Print "ERROR 128K: lo que se usa con otra página de RAM puesta acaba en " & hex4 (lowEnd) & ", por encima de $C000."
		errors += 1
	End If
End If

If errors Then End 1
