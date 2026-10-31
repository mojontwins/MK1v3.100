' gbcheck
' Copyleft 2026 The Mojon Twins
'
' Comprueba con el .map del enlazador (lcc -Wl-m) que un juego de Game Boy
' cabe:
'  * el banco 0 (0x0000-0x3FFF);
'  * cada banco de ROM (_CODE_n, 16K como mucho);
'  * la RAM (0xC000-0xDFFF): las variables y, encima, la pila, de la que se
'    reservan los bytes que diga stack= (por defecto 512).
' Escribe lo que ocupa cada cosa y sale con error si algo no cabe.
'
' Uso: gbcheck juego.map [stack=512]


Dim As String linea, nm, w ()
Dim As Integer f, i, st, sz, en, bank, errors, stack, ramEnd, bank0End
Dim As Integer bankUse (255)

stack = 512
For i = 2 To 9
	If Left (Command (i), 6) = "stack=" Then stack = Val (Mid (Command (i), 7))
Next i

f = FreeFile
If Command (1) = "" Or Open (Command (1) For Input As #f) Then
	Print "Uso: gbcheck juego.map [stack=512]"
	End 1
End If

ramEnd = &HC000: bank0End = 0
While Not Eof (f)
	Line Input #f, linea
	' "_CODE_1                00014000    0000001C =          28. bytes (REL,CON)"
	If Left (linea, 1) = "_" And Instr (linea, "bytes") > 0 Then
		nm = Trim (Left (linea, 23))
		st = Val ("&H" & Mid (linea, 24, 8))
		sz = Val ("&H" & Mid (linea, 36, 8))
		If sz > 0 And Instr (linea, "(REL") > 0 Then
			en = st + sz
			If Left (nm, 6) = "_CODE_" Then
				bank = Val (Mid (nm, 7))
				bankUse (bank) = bankUse (bank) + sz
			ElseIf st >= &HC000 And st < &HE000 Then
				If en > ramEnd Then ramEnd = en
			ElseIf st < &H4000 Then
				If en > bank0End Then bank0End = en
			End If
		End If
	End If
Wend
Close #f

Print "Banco 0: " & bank0End & " de 16384 bytes"
If bank0End > &H4000 Then Print "ERROR: el banco 0 no cabe (" & bank0End & " bytes)": errors += 1
For i = 1 To 255
	If bankUse (i) Then
		Print "Banco " & i & ": " & bankUse (i) & " de 16384 bytes"
		If bankUse (i) > 16384 Then Print "ERROR: el banco " & i & " no cabe": errors += 1
	End If
Next i
Print "RAM: variables hasta $" & Hex (ramEnd, 4) & ", " & (&HE000 - stack - ramEnd) & " bytes libres (con " & stack & " de pila)"
If ramEnd + stack > &HE000 Then Print "ERROR: las variables y la pila no caben en los 8K de RAM": errors += 1

If errors Then End 1
