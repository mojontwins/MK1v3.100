' defb2bin.bas
' MK1 v3.100 - Extrae los bytes de las líneas "defb" de un .h / .asm a un binario.
' Copyleft 2026 The Mojon Twins
'
' Sirve para convertir en recurso binario lo que otras herramientas generan
' como código (p.ej. el spriteset de sprcnv en formato splib2), sin duplicar
' su lógica. Acepta valores decimales, $FF, 0xFF, #FF y FFh.
'
' Uso: defb2bin entrada.h salida.bin

Function parseValue (v As String) As Integer
	v = Trim (v)
	If v = "" Then Return -1
	If Left (v, 1) = "$" Or Left (v, 1) = "#" Then Return Val ("&h" & Mid (v, 2))
	If Lcase (Left (v, 2)) = "0x" Then Return Val ("&h" & Mid (v, 3))
	If Lcase (Right (v, 1)) = "h" Then Return Val ("&h" & Left (v, Len (v) - 1))
	Return Val (v)
End Function

Dim As Integer fIn, fOut, p, q, n, v
Dim As String linea, rest, item
Dim As uByte d

If Command (2) = "" Then Print "uso: defb2bin entrada.h salida.bin": End 1

fIn = FreeFile
If Open (Command (1) For Input As #fIn) Then Print "no puedo abrir " & Command (1): End 1
fOut = FreeFile
Kill Command (2)
Open Command (2) For Binary Access Write As #fOut

While Not Eof (fIn)
	Line Input #fIn, linea
	' Quita comentarios ; y //
	p = Instr (linea, ";"): If p Then linea = Left (linea, p - 1)
	p = Instr (linea, "//"): If p Then linea = Left (linea, p - 1)
	p = Instr (Lcase (linea), "defb")
	If p Then
		rest = Mid (linea, p + 4) & ","
		Do
			q = Instr (rest, ",")
			If q = 0 Then Exit Do
			item = Left (rest, q - 1): rest = Mid (rest, q + 1)
			v = parseValue (item)
			If v >= 0 Then d = v And 255: Put #fOut, , d: n = n + 1
		Loop
	End If
Wend

Close fIn, fOut
Print "defb2bin: " & n & " bytes -> " & Command (2)
