' wyzTrackerParser v3.100
' Copyleft 2020, 2026 by The Mojon Twins
'
' Convierte los instrumentos y efectos de ritmo que exporta WYZ Tracker 2.0
' (el .mus.asm) en un módulo de sdasz80 para el WYZ player de CPC:
'  * "ETIQUETA:" se queda; DB / DW pasan a .db / .dw;
'  * exporta TABLA_PAUTAS y TABLA_SONIDOS, que usa el reproductor;
'  * se para en DATOS_NOTAS (la tabla de notas ya la lleva el reproductor).
'
' Uso: wyzTrackerParser entrada.mus.asm salida.s

Dim As Integer fIn, fOut, p
Dim As String linea, code, comment, w, rest

If Command (2) = "" Then
	Print "Uso: wyzTrackerParser entrada.mus.asm salida.s"
	End 1
End If

fIn = FreeFile
If Open (Command (1) For Input As #fIn) Then
	Print "No puedo abrir " & Command (1)
	End 1
End If
fOut = FreeFile
Open Command (2) For Output As #fOut

Print #fOut, "; Instrumentos y efectos de ritmo del WYZ player"
Print #fOut, "; Generado por wyzTrackerParser a partir de " & Command (1)
Print #fOut, ""
Print #fOut, !"\t.module instrumentos"
Print #fOut, !"\t.globl TABLA_PAUTAS"
Print #fOut, !"\t.globl TABLA_SONIDOS"
Print #fOut, !"\t.area _CODE"
Print #fOut, ""

While Not Eof (fIn)
	Line Input #fIn, linea
	linea = RTrim (linea, Any !" \t\r")

	' Código y comentario
	p = InStr (linea, ";")
	If p Then code = Left (linea, p - 1): comment = Mid (linea, p) Else code = linea: comment = ""
	code = Trim (code, Any !" \t")

	If Left (code, 12) = "DATOS_NOTAS:" Then Exit While

	If code = "" Then
		Print #fOut, comment
		Continue While
	End If

	' Etiqueta
	w = ""
	p = InStr (code, ":")
	If p Then w = Left (code, p) : code = Trim (Mid (code, p + 1), Any !" \t")

	' DB / DW y sus datos
	rest = ""
	If code <> "" Then
		p = InStr (code, Any !" \t")
		If p = 0 Then p = Len (code) + 1
		Select Case UCase (Left (code, p - 1))
			Case "DB", "DEFB": rest = !"\t.db " & Trim (Mid (code, p), Any !" \t")
			Case "DW", "DEFW": rest = !"\t.dw " & Trim (Mid (code, p), Any !" \t")
			Case Else: rest = !"\t" & code
		End Select
	End If

	Print #fOut, w & rest & IIf (comment <> "", !"\t" & comment, "")
Wend

Close
Print Command (2) & " listo"
