' ihx2bin
' Copyleft 2026 The Mojon Twins
'
' Pasa el .ihx que genera el enlazador de SDCC (sdldz80) a un binario que
' empieza en la dirección de carga y acaba en el último byte con datos. Lo que
' no está en el .ihx (las variables, que van después del código) no se escribe.
'
' Uso: ihx2bin entrada.ihx salida.bin dirección
'      (la dirección en decimal o con 0x delante)

Dim Shared As UByte mem (65535)
Dim As String linea, fileIn, fileOut
Dim As Integer fIn, fOut, n, i, addr, typ, org, hiAddr

fileIn = Command (1): fileOut = Command (2)
If fileIn = "" Or fileOut = "" Or Command (3) = "" Then
	Print "Uso: ihx2bin entrada.ihx salida.bin dirección"
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
