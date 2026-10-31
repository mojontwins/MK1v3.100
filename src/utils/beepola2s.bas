' beepola2s
' Copyleft 2026 The Mojon Twins
'
' Convierte el listado en ensamblador que exporta Beepola (sintaxis de pasmo:
' "ETIQUETA:", EQU, DEFB, $hex...) a un módulo de sdasz80 listo para enlazar
' con el juego de 48K. Añade la función de C play_title_music (), que llama a
' la etiqueta de entrada (START) con las interrupciones desactivadas y
' conservando IX, que el reproductor usa y SDCC necesita intacto.
'
' Uso: beepola2s entrada.asm salida.s [etiqueta]
'      (etiqueta: la de entrada, si no es START)

Dim Shared As String outLines ()
Dim Shared As Integer nOut

Sub emit (s As String)
	ReDim Preserve outLines (nOut)
	outLines (nOut) = s
	nOut += 1
End Sub

' ¿Es c una letra, cifra o _ (un carácter de identificador)?
Function isId (c As String) As Integer
	Return (c >= "a" And c <= "z") Or (c >= "A" And c <= "Z") Or (c >= "0" And c <= "9") Or c = "_"
End Function

Function isHex (c As String) As Integer
	Return (c >= "0" And c <= "9") Or (c >= "a" And c <= "f") Or (c >= "A" And c <= "F")
End Function

' Pasa a minúsculas todo lo que no esté entre comillas
Function lowerCode (s As String) As String
	Dim As String res, c, q
	Dim As Integer i
	For i = 1 To Len (s)
		c = Mid (s, i, 1)
		If q <> "" Then
			If c = q Then q = ""
			res &= c
		ElseIf c = """" Or (c = "'" And i > 1 And LCase (Mid (s, i - 2, 2)) <> "af") Then
			q = c: res &= c
		Else
			res &= LCase (c)
		End If
	Next i
	Return res
End Function

' Números de pasmo a sdasz80: $1F, #1F, &1F y 1Fh -> 0x1F; %101 -> 0b101;
' un $ suelto (la dirección actual) -> "."
Function convNumbers (s As String) As String
	Dim As String res, c, w
	Dim As Integer i, j
	i = 1
	While i <= Len (s)
		c = Mid (s, i, 1)
		If (c = "$" Or c = "#" Or c = "&") And isHex (Mid (s, i + 1, 1)) Then
			j = i + 1
			While isHex (Mid (s, j, 1)): j += 1: Wend
			res &= "0x" & Mid (s, i + 1, j - i - 1): i = j
		ElseIf c = "$" Then
			res &= ".": i += 1
		ElseIf c = "%" And (Mid (s, i + 1, 1) = "0" Or Mid (s, i + 1, 1) = "1") Then
			j = i + 1
			While Mid (s, j, 1) = "0" Or Mid (s, j, 1) = "1": j += 1: Wend
			res &= "0b" & Mid (s, i + 1, j - i - 1): i = j
		ElseIf isId (c) And (i = 1 OrElse Not isId (Mid (s, i - 1, 1))) Then
			' Una palabra entera: si es un número hexadecimal acabado en h, se cambia
			j = i
			While isId (Mid (s, j, 1)): j += 1: Wend
			w = Mid (s, i, j - i)
			If Len (w) > 1 AndAlso Right (w, 1) = "h" AndAlso Left (w, 1) >= "0" AndAlso Left (w, 1) <= "9" Then
				w = "0x" & Left (w, Len (w) - 1)
			End If
			res &= w: i = j
		Else
			res &= c: i += 1
		End If
	Wend
	Return res
End Function

' Parte los operandos por las comas que no estén entre paréntesis o comillas
Function splitOps (s As String, ops () As String) As Integer
	Dim As Integer i, depth, n
	Dim As String c, q, cur
	For i = 1 To Len (s)
		c = Mid (s, i, 1)
		If q <> "" Then
			If c = q Then q = ""
			cur &= c
		ElseIf c = """" Then
			q = c: cur &= c
		ElseIf c = "(" Then
			depth += 1: cur &= c
		ElseIf c = ")" Then
			depth -= 1: cur &= c
		ElseIf c = "," And depth = 0 Then
			ReDim Preserve ops (n): ops (n) = Trim (cur): n += 1: cur = ""
		Else
			cur &= c
		End If
	Next i
	If Trim (cur) <> "" Then ReDim Preserve ops (n): ops (n) = Trim (cur): n += 1
	Return n
End Function

Function isReg (o As String) As Integer
	Select Case o
		Case "a", "b", "c", "d", "e", "h", "l", "i", "r", "af", "af'", "bc", "de", "hl", "sp", "ix", "iy"
			Return -1
	End Select
	Return 0
End Function

Function isCond (o As String) As Integer
	Select Case o
		Case "nz", "z", "nc", "c", "po", "pe", "p", "m"
			Return -1
	End Select
	Return 0
End Function

' Un operando a la sintaxis de sdasz80. prefix recibe el prefijo (0xdd o
' 0xfd) si el operando es una mitad de IX o IY, que sdasz80 no conoce.
Function convOperand (o As String, mnem As String, idx As Integer, ByRef prefix As String) As String
	Dim As String inner, reg, offs
	Dim As Integer p

	' Mitades de IX/IY: se pone el prefijo a mano y se usa H o L
	Select Case o
		Case "ixh": prefix = "0xdd": Return "h"
		Case "ixl": prefix = "0xdd": Return "l"
		Case "iyh": prefix = "0xfd": Return "h"
		Case "iyl": prefix = "0xfd": Return "l"
	End Select

	If isReg (o) Then Return o
	If (mnem = "jp" Or mnem = "jr" Or mnem = "call" Or mnem = "ret") And idx = 0 And isCond (o) Then Return o

	If Left (o, 1) = "(" And Right (o, 1) = ")" Then
		inner = Trim (Mid (o, 2, Len (o) - 2))
		' (ix+n), (iy-n), (ix) -> n(ix)
		reg = Left (inner, 2)
		If (reg = "ix" Or reg = "iy") And (Len (inner) = 2 OrElse Not isId (Mid (inner, 3, 1))) Then
			offs = Trim (Mid (inner, 3))
			If offs = "" Then Return "0(" & reg & ")"
			If Left (offs, 1) = "+" Then offs = Trim (Mid (offs, 2))
			' Un número o un nombre va tal cual; una expresión, entre paréntesis
			For p = 1 To Len (offs)
				If Not isId (Mid (offs, p, 1)) And Not (p = 1 And Mid (offs, p, 1) = "-") Then Return "(" & offs & ")(" & reg & ")"
			Next p
			Return offs & "(" & reg & ")"
		End If
		' in a, (n) / out (n), a: el puerto es un inmediato
		If (mnem = "in" Or mnem = "out") And inner <> "c" Then Return "(#" & inner & ")"
		Return o
	End If

	Select Case mnem
		Case "jp", "jr", "call", "djnz", "rst", "im", "bit", "set", "res"
			Return o
	End Select
	Return "#" & o
End Function

' ---------------------------------------------------------------------------

Dim As String fileIn, fileOut, entry, linea, code, comment, lbl, mnem, rest, c, q, prefix, s, st
Dim As String ops ()
Dim As Integer fIn, fOut, i, n, p

fileIn = Command (1): fileOut = Command (2): entry = LCase (Command (3))
If fileIn = "" Or fileOut = "" Then
	Print "Uso: beepola2s entrada.asm salida.s [etiqueta]"
	End 1
End If
If entry = "" Then entry = "start"

fIn = FreeFile
If Open (fileIn For Input As #fIn) Then
	Print "No puedo abrir " & fileIn
	End 1
End If

emit "; Música del título (48K), generado por beepola2s a partir de " & fileIn
emit "; Se toca con play_title_music (): suena hasta que se pulse una tecla."
emit ""
emit !"\t.module music"
emit !"\t.globl _play_title_music"
emit !"\t.area _CODE"
emit ""
emit "_play_title_music::"
emit !"\tpush ix"
emit !"\tdi"
emit !"\tcall " & entry
emit !"\tei"
emit !"\tpop ix"
emit !"\tret"
emit ""

While Not Eof (fIn)
	Line Input #fIn, linea
	linea = RTrim (linea, Any !" \t\r")

	' Código y comentario (el ; que no esté entre comillas)
	code = linea: comment = "": q = ""
	For i = 1 To Len (linea)
		c = Mid (linea, i, 1)
		If q <> "" Then
			If c = q Then q = ""
		ElseIf c = """" Then
			q = c
		ElseIf c = ";" Then
			code = Left (linea, i - 1): comment = Mid (linea, i)
			Exit For
		End If
	Next i
	If comment <> "" Then comment = !"\t" & comment

	st = Trim (lowerCode (code), Any !" \t")
	If st = "" Then emit RTrim (comment, Any !"\t"): Continue While

	' Etiqueta: "nombre:" o ".nombre" al principio
	lbl = ""
	If Left (st, 1) = "." Then
		p = 2
		While isId (Mid (st, p, 1)): p += 1: Wend
		lbl = Mid (st, 2, p - 2): st = Trim (Mid (st, p), Any !" \t")
	Else
		p = 1
		While isId (Mid (st, p, 1)): p += 1: Wend
		If p > 1 And Mid (st, p, 1) = ":" Then
			lbl = Left (st, p - 1): st = Trim (Mid (st, p + 1), Any !" \t")
		ElseIf p > 1 And Left (code, 1) <> " " And Left (code, 1) <> !"\t" Then
			' En la columna 0 sin dos puntos también es una etiqueta (pasmo)
			Dim As String w = Left (st, p - 1)
			If w <> "org" And w <> "end" Then lbl = w: st = Trim (Mid (st, p), Any !" \t")
		End If
	End If

	' Instrucción o directiva
	p = 1
	While isId (Mid (st, p, 1)): p += 1: Wend
	mnem = Left (st, p - 1): rest = convNumbers (Trim (Mid (st, p), Any !" \t"))

	Select Case mnem
		Case "org", "end"
			' La dirección la pone el enlazador
			If lbl <> "" Then emit lbl & ":"
		Case "equ"
			emit !"\t" & lbl & " = " & rest & comment
		Case "defb", "db", "defm"
			emit lbl & IIf (lbl <> "", ":", "") & !"\t.db " & rest & comment
		Case "defw", "dw"
			emit lbl & IIf (lbl <> "", ":", "") & !"\t.dw " & rest & comment
		Case "defs", "ds"
			emit lbl & IIf (lbl <> "", ":", "") & !"\t.ds " & rest & comment
		Case ""
			emit lbl & ":" & comment
		Case Else
			n = splitOps (rest, ops ())
			prefix = "": s = ""
			For i = 0 To n - 1
				If i > 0 Then s &= ", "
				s &= convOperand (ops (i), mnem, i, prefix)
			Next i
			If prefix <> "" Then
				emit lbl & IIf (lbl <> "", ":", "") & !"\t.db " & prefix
				lbl = ""
			End If
			emit lbl & IIf (lbl <> "", ":", "") & !"\t" & mnem & IIf (s <> "", " " & s, "") & comment
	End Select
Wend
Close #fIn

fOut = FreeFile
Open fileOut For Output As #fOut
For i = 0 To nOut - 1
	Print #fOut, outLines (i)
Next i
Close #fOut
Print fileOut & ": " & nOut & " líneas"
