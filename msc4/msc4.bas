' MSC4
' Copyleft 2025 by The Mojon Twins

#include "mtparser.bi"
#include "cmdlineparser.bi"
#include "mt5bitEsc.bi"

Const SPECCY = 0
Const CPC = 1
Const GB = 2

Const ENTERING_INDEX_OFFSET = 16
Const PRESS_FIRE_INDEX_OFFSET = 17

Type TypeSubroutineInfo
	subName As String 
	binAddress As Integer
End Type 

Dim Shared As Integer debug = -1
Dim Shared As Integer textDebug = 0

Dim Shared As String tokens (255)
Dim Shared As Integer curLineNo

Dim Shared As String aliases (128)
Dim Shared As Integer curAliasIndex = 0

Dim Shared As Integer AU (255), CU (255), LV (255), RV (255)

Dim Shared As Integer sectOffs (255)
Dim Shared As UByte sectBinary (16383)
Dim Shared As UByte mainBinary (18000)
Dim Shared As Integer sectBinIdx, mainBinIdx

Dim Shared As Integer outV = 3
Dim Shared AS Integer outT = SPECCY

Dim Shared As String interpreterFn
Dim Shared As Integer maxPants
Dim Shared As Integer noIndexed
Dim Shared As Integer fastNPant
Dim Shared As Integer jumptable
Dim Shared As String templateFile
Dim Shared As Integer allOpcodes

Dim Shared As Integer itemSlot
Dim Shared As Integer itemEmpty = 0

'' Salida en C (output=c, solo con v=3_100): un intérprete fijo en el motor
'' (src/dev/msc.h) y aquí solo se generan el bytecode y msc-config.h.
Const IDX_ROOMS = 15			' Entrada libre del índice: nº de pantallas (salida C)
Dim Shared As Integer outC
Dim Shared As Integer SV (255)	' Índices usados como flag ($n), para variables especiales
Dim Shared As Integer maxFlag = -1
Dim Shared As Integer sectUsed (15)
Dim Shared As Integer roomSectionsUsed
Dim Shared As Integer maxScriptSize
Dim Shared As Integer maxTextLen

'' CALL a SUBs: la dirección se resuelve al final del script, así se puede
'' llamar a una SUB definida más abajo.
Dim Shared As String pendingCallName
Dim Shared As String secFixName (255), fixName (1023)
Dim Shared As Integer secFixOff (255), fixPos (1023)
Dim Shared As Integer secFixCount, fixCount

Dim Shared As Integer textWidth
Dim Shared As Integer textPoolIndex
Dim Shared As Integer lastTextOffset 
Dim Shared As String textPool (16384)
Dim Shared As Integer textOffsets (16384)
Dim Shared As Integer lastCommandWasTerminator

Dim Shared As TypeSubroutineInfo subInfo (128)
Dim Shared As Integer subInfoIdx = 0

Sub addSubInfo (subName As String, binAddress As Integer)
	subInfo (subInfoIdx).subName = subName
	subInfo (subInfoIdx).binAddress = binAddress
	subInfoIdx = subInfoIdx + 1
	If subInfoIdx > 128 Then 
		Print "Warning! Too manu Subroutines!"
		subInfoIdx = 128
	End If
End Sub

Function getSubAddressByName (subName As String) As Integer
	Dim As Integer i
	subName = Lcase (subName)
	For i = 0 To subInfoIdx - 1
		If Lcase (subInfo (i).subName) = subName Then Return subInfo (i).binAddress
	Next i 
	Return -1
End Function

Sub shiftTokens (from As Integer)
	' Moves all tokens from `from` to last one step forward
	' Overwriting what's in `from`.
	Dim As Integer i
	For i = from To uBound (tokens) - 1
		tokens (i) = tokens (i + 1)
	Next i
End Sub

Sub debugPrintTokens
	Dim index As Integer = 0
	While index < 64 And tokens(index) <> ""
		Print "T" & index & "=[" & tokens(index) & "]"
		index = index + 1
	Wend
End Sub

Sub printBinStr (s As String)
	Dim As Integer i
	For i = 1 To Len (s) 
		Print Hex (Asc (Mid (s, i, 1)), 2) & " ";
	Next i
	Print
End Sub

Sub resetAliases () 
	Dim i As Integer

	For i = 0 To uBound (aliases)
		aliases (i) = ""
	Next i 
End Sub

Function encodeSpaces (b as String) As String
	Return replace (b, " ", "_")
End Function

Function decodeSpaces (b as String) As String
	Return replace (b, "_", " ")
End Function

Function addOrResolveAlias (salias As String) As Integer
	Dim i As Integer

	salias = lCase (salias)

	' Find
	For i = 0 To uBound (aliases)
		If aliases (i) = salias Then 
			'Print salias & " resolved to " & i
			Return i 
		End If 
	Next 

	' Not found, add to 1st unused slot
	For i = 0 To uBound (aliases)
		If aliases (i) = "" Then
			aliases (i) = salias 
			'Print salias & " resolved to " & i
			Return i 
		End If 
	Next 

	Print "Warning! Too many aliases, resolving to 0"
	
End Function

Sub debugPrintAliases ()
	Dim i As Integer
	For i = 0 To uBound(aliases)
		If aliases(i) <> "" Then Print "%" & aliases(i) & " -> $" & i
	Next i
End Sub 

Sub parseScriptLine (linea As String)
	Dim As Integer i
	Dim As Integer index
	Dim As Integer quotes
	Dim As String curToken, prefix, sufix
	Dim As String indirec
	Dim As String m
	Dim As String tokenAlias
	Dim As Integer aliasPos

	If debug Then Print "Parsing: " & linea

	' Preprocess so = <= >= < > != <> don't need whitespace.
	quotes = 0
	curToken = ""
	i = 1: While i <= Len (linea) 
		m = Mid (linea, i, 1)
		If quotes Then 
			' Ignore...
			If m = Chr(34) Then quotes = 0
		Else
			If m = Chr(34) Then 
				quotes = -1
			ElseIf Instr ("<>=!", m) Then
				If curToken = "" Then index = i
				curToken = curToken & m
			Else 
				If curToken <> "" Then
					'  12345679
					'     /---- i
					'  A!=B
					'   \------ index'
					prefix = "": If index >1 Then prefix = left (linea, index - 1)
					sufix = Right (linea, Len (linea) - i + 1)
					linea = prefix & " " & curToken & " " & sufix 
					i = i + 2

					curToken = ""
				End If
			End If
		End If
		i = i + 1
	Wend

	' Trim prepended ON

	If Len(linea) > 3 And Left (Ucase (linea), 3) = "ON " Then
		linea = Right (linea, Len (linea) - 3)
	End If

	' Tokenize

	parseTokenizeString linea, tokens (), ",()[]", "#"

	' Process to solve %ALIAS -> $n, even if it is prepended by an arbitrary amount of "$"
	' Also to solve &%ALIAS -> n
	' Also do special vars here
	i = 0: While i < uBound (tokens) And tokens (i) <> ""
		aliasPos = Instr(tokens(i), "%")

		If Len(tokens(i)) > 2 And Left (tokens(i), 2) = "&%" Then
			tokens(i) = Str (addOrResolveAlias (Right (tokens (i), Len (tokens (i)) - 2)))
		ElseIf aliasPos > 0 Then
			' Alias preprocessing
			tokenAlias = Right (tokens (i), Len (tokens(i)) - aliasPos)
			prefix = "": If aliasPos > 1 Then prefix = Left(tokens (i), aliasPos - 1)
			tokens (i) = prefix & "$" & addOrResolveAlias (tokenAlias)
		ElseIf Ucase(tokens(i)) = "NPANT" Or Ucase(tokens (i)) = "N_PANT" Then
			tokens (i) = "$254"
		ElseIf Ucase(tokens (i)) = "PX" Then 
			tokens (i) = "$253"
		ElseIf Ucase(tokens (i)) = "PY" Then 
			tokens (i) = "$252"
		ElseIf Ucase(tokens (i)) = "KILLED" Then 
			tokens (i) = "$251" 
		ElseIf Ucase(tokens (i)) = "OBJS" Then
			tokens (i) = "$250"
		ElseIf Ucase(tokens (i)) = "LIFE" Then
			tokens (i) = "$249"
		ElseIf Ucase(tokens (i)) = "TX" then 
			tokens (i) = "$248"
		ElseIf Ucase(tokens (i)) = "TY" Then 
			tokens (i) = "$247"
		ElseIf Ucase(tokens (i)) = "TN" Then 
			tokens (i) = "$246"
		ElseIf Ucase(tokens (i)) = "HOTSPOT" Then
			tokens (i) = "$245"
		ElseIf Ucase(tokens (i)) = "HIDE_HOTSPOTS" Then 
			tokens (i) = "$240"
		ElseIf Ucase(tokens (i)) = "DONT_MAKE_FANTIES" Then
			tokens (i) = "$239"
		ElseIf Ucase(tokens (i)) = "EN_T" Then
			tokens (i) = "$238"
		ElseIf Ucase(tokens (i)) = "EN_N" Then
			tokens (i) = "$237"
		ElseIf Ucase(tokens (i)) = "EN_X" Then
			tokens (i) = "$236"
		ElseIf Ucase(tokens (i)) = "EN_Y" Then
			tokens (i) = "$235"
		ElseIf Ucase(tokens (i)) = "OPANT" Or Ucase(tokens (i)) = "O_PANT" Then
			tokens (i) = "$234"
		ElseIf Ucase(tokens(i)) = "PARAM" Then
			tokens (i) = "$233"
		ElseIf Ucase(tokens(i)) = "TIMER" Then
			tokens (i) = "$241"
		ElseIf Ucase(tokens(i)) = "MOVED_TILE" Then
			tokens (i) = "$244"
		ElseIf Ucase(tokens(i)) = "MOVED_X" Then
			tokens (i) = "$243"
		ElseIf Ucase(tokens(i)) = "MOVED_Y" Then
			tokens (i) = "$242"
		End If

		' Static identifiers
		If Ucase(tokens (i)) = "EMPTY" Then 
			tokens (i) = Trim(Str(itemEmpty))
		End If

		i = i + 1
	Wend		

	' Process to encode expressions TILE AT and BEH AT
	' TILE AT A B -> =TILE=AT=A=B, shift tokens 3 times
	' DIALOG A B C -> =DIALOG=A=B=C, shift tokens 3 times'
	i = 0: While i < uBound (tokens) And tokens (i) <> ""
		If (Ucase (tokens (i)) = "TILE" Or Ucase (tokens (i)) = "BEH") And Ucase (tokens (i + 1)) = "AT" Then
			indirec = "=" & tokens (i) & "=" & tokens (i + 2) & "=" & tokens (i + 3)
			shiftTokens i
			shiftTokens i
			shiftTokens i
			tokens (i) = indirec
		ElseIf Ucase (tokens (i)) = "DIALOG" Then
			indirec = "=" & tokens (i) & "=" & encodeSpaces (tokens (i + 1)) & "=" & encodeSpaces (tokens (i + 2)) & "=" & encodeSpaces (tokens (i + 3))
			shiftTokens i
			shiftTokens i
			shiftTokens i
			tokens (i) = indirec
		End If

		i = i + 1
	Wend

	' Process to encode expressions DIALOG'

	' Process to solve FLAG n -> $n
	' This should be made recursively so FLAG FLAG FLAG n -> $$$n

	i = 0: While i < uBound (tokens) And tokens (i) <> "" 
		indirec = ""
		While Ucase (tokens (i)) = "FLAG" And i < uBound (tokens)
			indirec = indirec & "$"
			shiftTokens i
		Wend 
		If indirec <> "" Then tokens (i) = indirec & tokens (i)

		i = i + 1
	Wend

	If debug Then debugPrintTokens
End Sub

Function correctLvalue (s As String) As Integer
	Return s <> "" And Left (s, 1) = "$"
End Function

Function isNumber (s As String) As Integer
	' there're better ways but this is safe
	Dim As Integer i
	Dim As String m 
	
	For i = 1 To Len (s)
		m = Mid (s, i, 1)
		If m < "0" Or m > "9" Then return 0 
	Next i 

	Return -1
End Function

Function correctSuBExpresion (s As String) As Integer
	If Len (s) < 2 Then Return 0
	If Left (s, 1) <> "=" Then Return 0 

	' For now we accept anything.

	Return -1	

End Function

Function isNumberOrVar (s As String) As Integer

	If correctSubExpresion (s) Then Return -1
	If correctLvalue (s) Then Return -1 
	If isNumber (s) Then Return -1

	Return 0
End Function

Function isComp (s As String) As Integer
	return s = "=" Or s = "!=" Or s = "<>" Or s = "<" Or s =">" Or s = "<=" Or s =">="
End Function

Sub writeAssemblyString (fOut As Integer, s As String)
	Dim As Integer i, index 
	Dim As String m

	For i = lBound (tokens) To uBound (tokens)
		tokens (i) = ""
	Next i

	' Break by |
	s = s & "||[FIN]"

	index = 0: For i = 1 To Len (s) 
		m = Mid (s, i, 1) 
		If m = "|" Then 
			index = index + 1 
		Else 
			tokens (index) = tokens (index) & m 
		End If 
	Next i 

	i = 0: While i < uBound (tokens) And tokens (i) <> "[FIN]"
		If tokens (i) = "" Then 	
			If fOut = 0 Then  
				Print
			Else 
				Print #fOut, ""
			End If
		ElseIf Left (tokens (i), 1) = "." Or Left (tokens (i), 1) = ";" Or (Right (tokens (i), 1) = ":" And InStr (tokens (i), " ") = 0) Then
			If fOut = 0 Then
				Print tokens (i) 
			Else 
				Print #fOut, tokens (i)
			End If 
		Else 
			If fOut = 0 Then 
				Print "	" & tokens (i)
			Else 
				Print #fOut, "	" & tokens (i)
			End If 
		End if
		i = i + 1
	Wend
End Sub

Function readNewLine (fIn As Integer) As String
	Dim As String linea
	
	Line Input #fIn, linea 
	linea = Trim (linea, Any chr (32) + chr (9))
	curLineNo = curLineNo + 1

	'If debug Then Print curLineNo & ": " & linea

	Return linea
End Function

Function getTextOffset (text As String) As String
	Dim As String encodedText
	Dim As Integer offset, i

	' if text is empty, return &HFFFF
	If text = "" Then Return Chr(&HFF) & Chr (&HFF)

	' encode this text
	encodedText = encode5BitEsc (text, textWidth)

	' Para el buffer del intérprete C: caracteres + saltos de línea + fin
	If Len (text) + Len (text) \ textWidth + 2 > maxTextLen Then maxTextLen = Len (text) + Len (text) \ textWidth + 2

	' return offset
	offset = -1

	For i = 0 To textPoolIndex - 1
		If textPool (i) = encodedText Then 
			offset = textOffsets (i)
			Exit For
		End If
	Next i

	If offset = -1 Then
		' New text! store offset, add text, return offset 
		offset = lastTextOffset 
		textOffsets (textPoolIndex) = lastTextOffset 
		textPool (textPoolIndex) = encodedText

		If textdebug Then
			Print "Encoded text: " & encodedText
			Print "Pretty Print: "
			prettyPrintEncodedString encodedText
		End If

		lastTextOffset = lastTextOffset + Len (encodedText)
		textPoolIndex = textPoolIndex + 1
	End If 

	Return Chr (offset Mod 256) & Chr (offset \ 256)

End Function

' Anota que el script usa "$n" (el flag n o la variable especial n).
Sub markFlagUse (inner As String)
	Dim As Integer n
	If Not isNumber (inner) Then Exit Sub
	n = Val (inner)
	If n > 255 Then Exit Sub
	SV (n) = -1
	If n < &HE6 And n > maxFlag Then maxFlag = n
End Sub

Function pVal (expresion As String) As String
	Dim As String subTokens(16)
	Dim As Integer i
	Dim As String result

	If Len (expresion) > 1 And Left (expresion, 1) = "=" Then
		If debug Then Print "Parsing expresion "  & expresion
		' Special Complex Expresion
		' =BLA=BLA=BLA=...

		parseTokenizeString expresion & "=", subTokens (), "=", "#"'

		IF subTokens (0) = "DIALOG" Then 
			result = Chr (&HFF) & Chr (&HE6) & getTextOffset (decodeSpaces (subTokens (1))) & _
				getTextOffset (decodeSpaces (subTokens (2))) & _
				getTextOffset (decodeSpaces (subTokens (3)))
			RV (&HE6) = -1: SV (&HE6) = -1
		ElseIf subTokens (0) = "TILE" Then  
			result = Chr (&HFF) & Chr (&HE8) & pVal(subTokens (1)) & pVal (subTokens (2))
			RV (&HE8) = -1: SV (&HE8) = -1
		ElseIf subTokens (0) = "BEH" Then 
			result = Chr (&HFF) & Chr (&HE7) & pVal(subTokens (1)) & pVal (subTokens (2))
			RV (&HE7) = -1: SV (&HE7) = -1
		Else 
			Print "Wrong expresion @ " & curLineNo
			Return Chr (0)
		End If

		If debug Then Print "Result bytecode = ";: printBinStr result
		Return result

	ElseIf Len (expresion) > 1 And Left (expresion, 1) = "$" Then
		markFlagUse Right (expresion, Len (expresion) - 1)
		Return Chr (&HFF) & pVal (Right (expresion, Len (expresion) - 1))
	Else
		If Val (expresion) <= 254 Then
			RV (Val (expresion)) = -1
			Return Chr (Val (expresion)) 
		Else 
			Print "Wrong value @ " & curLineNo
			Return Chr (0)
		End If
	End If
End Function

Function lValR(expresion As String) As String 
	If Len (expresion) > 1 And Left (expresion, 1) = "$" Then 
		Return Chr (&HFF) & pVal (Right (expresion, Len (expresion) - 1)) 
	Else
		If Val (expresion) <= 254 Then 
			Return Chr (Val (expresion)) 
		Else 
			Print "Wrong value @ " & curLineNo
		End If
	End If
End Function

Function lVal (expresion As String) As String
	Dim As String value
	' Used for lValues such as $A = B, so first $ is ignored.
	If correctLvalue (expresion) Then
		markFlagUse Right (expresion, Len (expresion) - 1)
		value = lValR (Right (expresion, Len (expresion) - 1))
		LV (Asc (Right (value, 1))) = -1
		Return value
	Else
		Print "Expecting lValue @ " & curLineNo
	End If
End Function

Function makeFlag (encoded As String) As String
	Return Chr (&HFF) & encoded
End Function

Function buildCond (bytecode As String) As String
	If Len (bytecode) >= 1 Then
		CU (Asc (Left (bytecode, 1))) = -1
	End If

	Return byteCode
End Function


Function buildAction (bytecode As String) As String
	If Len (bytecode) >= 1 Then
		AU (Asc (Left (bytecode, 1))) = -1
	End If

	Return byteCode
End Function

Sub syntaxError 
	Print "Syntax error at " & curLineNo
End Sub

Function processIf (linea As String) As String
	Dim As String code = ""
	Dim As String cmd
	Dim As Integer v1, v2
	parseScriptLine linea	

	' First of all, override IF NPANT if desired
	If fastNPant And lCase (tokens (1)) = "$254" And tokens (2) = "=" Then 
		code = buildCond (Chr(&H05) & pVal (tokens (3)))

	' Detect numeric conditions IF a OP b 
	ElseIf isNumberOrVar (tokens (1)) And isComp (tokens(2)) And isNumberOrVar (tokens (3)) Then
		Select Case tokens (2)
			Case "=" 
				' $01 A B
				code = buildCond (Chr(&H01) & pVal (tokens (1)) & pVal (tokens (3)))

			Case "<":
				' $02 A B
				code = buildCond (Chr(&H02) & pVal (tokens (1)) & pVal (tokens (3)))

			Case ">" 
				' $02 B A 
				code = buildCond (Chr(&H02) & pVal (tokens (3)) & pVal (tokens (1)))

			Case ">="
				' $03 A B
				code = buildCond (Chr(&H03) & pVal (tokens (1)) & pVal (tokens (3)))

			Case "<="
				' $03 B A
				code = buildCond (Chr(&H03) & pVal (tokens (3)) & pVal (tokens (1)))

			Case "<>", "!="
				' $04 A B
				code = buildCond (Chr(&H04) & pVal (tokens (1)) & pVal (tokens (3)))
		End Select

	Else
		cmd = lCase (tokens (1))
		Select Case cmd
			Case "true"
				code = buildCond (Chr (&HF0))

			Case "player"
				' Detect player conditions

				Select Case lCase (tokens (2))

					Case "in_x"
						' $21 X Y
						' Otherwise use special OPCODE 20
						code = buildCond (Chr (&H21) & pVal (tokens (3)) & pVal (tokens (4)))
					
					Case "in_y"
						' $22 X Y
						code = buildCond (Chr (&H22) & pVal (tokens (3)) & pVal (tokens (4)))
					
					Case "touches", "at"
						' $23 X Y
						code = buildCond (Chr (&H23) & pVal (tokens (3)) & pVal (tokens (4)))
					
					Case "falling"
						' $24 X Y
						code = buildCond (Chr (&H24))
		
					Case "not_falling"
						' $25 X Y
						code = buildCond (Chr (&H25))
					
					Case "still"
						' $26 X Y
						code = buildCond (Chr (&H26))
				End Select

			Case "tile"

				Select Case lCase (tokens (2))
					Case "at"
						' $30 X Y T
						code = buildCond (Chr (&H30) & pVal (tokens (3)) & pVal (tokens (4)) & pVal (tokens (6)))

				End Select

			Case "beh"

				Select Case lCase (tokens (2))
					Case "at"
						' $31 X Y T
						code = buildCond (Chr (&H31) & pVal (tokens (3)) & pVal (tokens (4)) & pVal (tokens (6)))

				End Select

		End Select

	End If

	Return code 
End Function

Function processCommand (linea As String) As String
	Dim As String code = ""
	Dim As String cmd, scmd 
	Dim As Integer subBinIndex, indexSize

	parseScriptLine linea

	' Detect direct numeric asignation $A = B 
	If tokens (1) = "=" Then 
		If correctLvalue (tokens (0)) And isNumberOrVar (tokens (2)) Then
			code = buildAction (Chr(&H00) & lVal (tokens(0)) & pVal (tokens (2)))
		Else
			syntaxError
		End If
	End If

	cmd = lCase (tokens (0))
	scmd = lCase (tokens (1))

	lastCommandWasTerminator = 0

	Select Case cmd
		Case "inc"
			' INC $A B
			' $01 A B
			If correctLvalue (tokens(1)) And isNumberOrVar (tokens (2)) Then
				code = buildAction (Chr(&H01) & lVal (tokens (1)) & pVal (tokens (2)))
			Else
				syntaxError
			End If

		Case "dec"
			' DEC $A B
			' $02 A B 
			If correctLvalue (tokens(1)) And isNumberOrVar (tokens (2)) Then
				code = buildAction (Chr(&H02) & lVal (tokens (1)) & pVal (tokens (2)))
			Else
				syntaxError
			End If

		Case "add"
			' First deprecated construct add flags x y -> inc $X $Y 
			If scmd = "flags" Then 
				code = buildAction (Chr (&H01) & pVal (tokens (2)) & makeFlag (pVal (tokens (3))))

			ElseIf correctLvalue (tokens(1)) And isNumberOrVar (tokens (2)) Then
				' Alias for inc 
				code = buildAction (Chr(&H01) & lVal (tokens (1)) & pVal (tokens (2)))
			Else
				syntaxError
			End If 

		Case "sub"
			' First deprecated construct sub flags x y -> dec $X $Y 
			If scmd = "flags" Then 
				code = buildAction (Chr (&H02) & pVal (tokens (2)) & makeFlag (pVal (tokens (3))))

			ElseIf correctLvalue (tokens(1)) And isNumberOrVar (tokens (2)) Then
				' Alias for dec 
				code = buildAction (Chr(&H02) & lVal (tokens (1)) & pVal (tokens (2)))
			Else
				syntaxError
			End If '

		Case "set"
			If scmd = "tile" Then
				' SET TILE X Y = N
				code = buildAction (Chr (&H20) & pVal (tokens(2)) & pVal (tokens (3)) & pVal (tokens (5)))

			ElseIf scmd = "beh" Then
				' SET BEH X Y = N
				code = buildAction (Chr (&H21) & pVal (tokens(2)) & pVal (tokens (3)) & pVal (tokens (5)))

			ElseIf scmd = "fire" And lCase (tokens (2)) = "zone" Then
				If Not outC Then Print "SET FIRE ZONE needs v=3_100 output=c @ " & curLineNo
				If lCase (tokens (3)) = "tiles" Then
					' SET FIRE ZONE TILES X1, Y1, X2, Y2 (en tiles)
					' $52 X1 Y1 X2 Y2
					code = buildAction (Chr (&H52) & pVal (tokens (4)) & pVal (tokens (5)) & pVal (tokens (6)) & pVal (tokens (7)))
				Else
					' SET FIRE ZONE X1, Y1, X2, Y2 (en píxeles)
					' $51 X1 Y1 X2 Y2
					code = buildAction (Chr (&H51) & pVal (tokens (3)) & pVal (tokens (4)) & pVal (tokens (5)) & pVal (tokens (6)))
				End If

			ElseIf correctLvalue (tokens (1)) And tokens (2) = "=" And isNumberOrVar (tokens (3)) Then
				' SET $A = B
				code = buildAction (Chr(&H00) & lVal (tokens(1)) & pVal (tokens (3)))
			Else
				syntaxError
			End If

		Case "get"
			If scmd = "item" Then
				' GET ITEM SET f
				' $30 F (lvalue)
				code = buildAction (Chr (&H30) & lVal (tokens(3)))
			End If

		Case "print"
			If scmd = "tile" Then 
				' PRINT TILE X Y = T
				' $50 X Y T
				code = buildAction (Chr (&H50) & pVal (tokens (2)) & pVal (tokens (3)) & pVal (tokens (5)))
			End If

		Case "warp"
			If scmd = "to" And isNumberOrVar (tokens (2)) And isNumberOrVar (tokens (3))And isNumberOrVar (tokens (4)) Then
				' WARP TO N, X, Y
				' $6D N X Y
				code = buildAction (Chr (&H6D) & pVal (tokens (2)) & pVal (tokens (3)) & pVal (tokens (4)))
			Else
				syntaxError
			End If

		Case "sound"
			' SOUND N
			' $E0 N
			code = buildAction (Chr (&HE0) & pVal (tokens(1)))

		Case "show"
			' $E1
			code = buildAction (Chr (&HE1))

		Case "recharge"
			' $E2
			code = buildAction (Chr (&HE2))

		Case "text"

			If scmd = "box" Then
				' $E6 LSB MSB
				code = buildAction (Chr (&HE6)) & getTextOffset (tokens (2))

			Else
				' $E3 L <TEXT> 0
				code = buildAction (Chr (&HE3)) & Chr(1 + Len(tokens (1))) & tokens (1) & Chr (0)
			End If
				
		Case "extern"
			' EXTERN N M
			' $E4 N M'
			code = buildAction (Chr (&HE4) & pVal (tokens(1)) & pVal (tokens (2)))

		Case "pause"
			' PAUSE N
			' $E5 N
			code = buildAction (Chr (&HE5) & pVal (tokens(1)))

		Case "game"
			If scmd = "over" then 
				code = buildAction (Chr (&HF1))
				lastCommandWasTerminator = -1
			Else 
				syntaxError
			End If

		Case "win"
			If scmd = "game" Then  
				code = buildAction (Chr (&HF0))
				lastCommandWasTerminator = -1
			Else 
				syntaxError
			End If

		Case "break"
			' BREAK
			' $F2
			code = buildAction (Chr (&HF2))'
			lastCommandWasTerminator = -1

		Case "rerun"
			' RERUN
			' $F3 V
			If isNumberOrVar (tokens (1)) Then
				code = buildAction (Chr (&HF3) & pVal (tokens (1)))
				lastCommandWasTerminator = -1
			Else
				syntaxError
			End If

		Case "call"
			' CALL SUBRUTINE
			' $F4 LSB MSB 

			If jumptable Then
				' Don't index rooms in jumptable mode!
				indexSize = ENTERING_INDEX_OFFSET
			Else
				indexSize = ENTERING_INDEX_OFFSET + maxPants * 2
			End If
			' La dirección (LSB MSB) se rellena al final de processScript:
			' así se puede llamar a una SUB definida más abajo.
			If tokens (1) <> "" Then
				code = buildAction (Chr (&HF4) & Chr (0) & Chr (0))
				pendingCallName = tokens (1)
			Else
				syntaxError
			End If

	End Select 

	Return code 
End Function

Function processCurrentSection (fIn As Integer) As String 
	Dim sectionCode As String
	Dim clausule As String
	Dim As Integer terminado
	Dim As Integer wrong
	Dim As Integer state
	Dim As String linea, lineaLc
	Dim As Integer deco(255)

	terminado = 0
	wrong = 0
	state = 0 			' 0 = fetching, 1 = conditions, 2 = actions, 3 = decos

	While Not terminado And Not Eof (fIn)
		linea = readNewLine (fIn)
		lineaLc = lCase (linea)

		If linea = "" Then 
			' Skip 

		ElseIf lineaLc = "end" Then
			' If we are fetching -> this section has ended.
			' If we are reading conditions -> wrong
			' If we are reading actions -> this clausule has ended.
			' If we are reading decos -> decos ended.
			If state = 0 Then 
				terminado = -1
			ElseIf state = 1 Then 
				wrong = -1: terminado = -1
				Print "Unexpected END @ " & curLineNo
			ElseIf state = 3 Then 
				' End decos
				clausule = clausule & Chr (&HFF)

				' Back to read actions
				state = 2

				If debug Then Print "Stopped parsing decos"
			Else

				' Write  END to current clausule
				' New: Only add &HFF if last commaand was NOT a terminator
				If Not lastCommandWasTerminator Then
					clausule = clausule & Chr (&HFF)
				End If

				' Write current clausule
				' (el tamaño va en un byte y 0xFF marca el final de sección)
				If Len (clausule) + 1 >= 255 Then
					Print "Clausule too long (" & Len (clausule) & " bytes) @ " & curLineNo
					wrong = -1
				End If
				sectionCode = sectionCode & Chr (Len (clausule) + 1) & clausule
				
				' New clausule
				clausule = ""
				
				' Back to fetching
				state = 0
			End If 

		ElseIf lineaLc = "then" Then
			' If we are fetching or reading actions -> wrong
			' Else  change to state 2
			If state = 1 Then 
				' Write FF to signal "end of section" to the interpreter
				clausule = clausule & Chr (&HFF)

				state = 2
				lastCommandWasTerminator = 0
			Else 
				wrong = -1: terminado = -1
				Print "Unexpected THEN @ " & curLineNo
			End If

		ElseIf Len (lineaLc) > 3 And Left (lineaLc, 3) = "if " Then 
			' Only valid when fetching or reading conditions
			If state = 2 Then 
				wrong = -1: terminado = -1
				Print "Unexpected IF @ " & curLineNo
			Else 
				state = 1

				' Process IF
				clausule = clausule & processIf (linea)
			End If

		ElseIf lineaLc = "decos" Then
			' Only valid when reading actions
			If state = 2 Then 
				state = 3
				clausule = clausule & Chr (&H22)
				AU (&H22) = -1
				If debug Then Print "Began parsing decos"

			Else
				wrong = -1: terminado = -1
				Print "Unexpected DECOS @ " & curLineNo
			End If
		Else
			If state = 3 Then 
				' Read & add a decoration
				parseCoordinatesString linea, deco ()
				clausule = clausule & Chr (deco (2) And &HFF) & Chr ((deco(1) And &HF) * 16 + (deco (0) And &HF))
				If debug Then Print "Parsed deco " & deco (0) & " " & deco (1) & " " & deco (2)

			ElseIf state = 2 Then
				' Commands
				If lastCommandWasTerminator Then
					Print "Warning! unreachable code @ " & curLineNo
				End If
				pendingCallName = ""
				Dim As Integer before = Len (clausule)
				clausule = clausule & processCommand (linea)
				If pendingCallName <> "" Then
					' Posición de LSB dentro de la sección: tamaño + cláusula + opcode
					secFixName (secFixCount) = pendingCallName
					secFixOff (secFixCount) = Len (sectionCode) + 1 + before + 1
					secFixCount = secFixCount + 1
					pendingCallName = ""
				End If

			ElseIf Left (linea, 1) <> "#" Then 
				wrong = -1: terminado = -1
				Print "Unexpected command @ " & curLineNo

			Else 
				' ignoring comment

			End If
		End If
	Wend

	' End of section code.
	sectionCode = sectionCode & Chr (&HFF)

	Return sectionCode 
End Function

Function startsWith (haysTack () As String, spec As String) As Integer 
	Dim as String specTokens (uBound (tokens))
	Dim as Integer i 

	parseTokenizeString spec, specTokens (), "", ""

	While i < uBound(tokens) And specTokens (i) <> ""
		If tokens (i) <> specTokens (i) Then Return 0

		i = i + 1
	Wend

	Return -1
End Function 

Sub writeToSectBinary (section As String)
	Dim As Integer i 

	For i = 0 To secFixCount - 1
		fixName (fixCount) = secFixName (i)
		fixPos (fixCount) = sectBinIdx + secFixOff (i)
		fixCount = fixCount + 1
	Next i
	secFixCount = 0

	For i = 1 To Len (section) 	
		sectBinary (sectBinIdx) = Asc (Mid (section, i, 1))
		sectBinIdx = sectBinIdx + 1
	Next i
End Sub 

Sub WriteToMainBin (b As uByte)
	mainBinary (mainBinIdx) = b
	mainBinIdx = mainBinIdx + 1
End Sub

Sub processScript (fIn As Integer)
	Dim As String linea
	Dim As String sectionBytecode
	Dim As Integer section, i
	Dim As Integer listToken, cError
	Dim As Integer sectOffset
	Dim As String listRooms (127)
	Dim As Integer indexSize

	sectBinIdx = 0
	subInfoIdx = 0
	fixCount = 0: secFixCount = 0

	For i = 0 To uBound (sectOffs)
		sectOffs (i) = -1
	Next i

	While Not Eof (fIn) 
		linea = readNewLine (fIn)
		parseTokenizeString lcase (linea), tokens (), ",_()[]", "#"

		' "ON PLAYER KILLS ENEMY" = "PLAYER KILLS ENEMY"
		If tokens (0) = "on" Then shiftTokens 0

		If linea <> "" And tokens (0) <> "" Then
			If debug Then 
				Print "==========================================" 
				Print "LINEA " & linea
				debugPrintTokens
			End If

			For i = 0 To uBound (listRooms) 
				listRooms (i) = ""
			Next i
			cError = 0

			If tokens (0) = "rooms" Then 
				' ROOMS = N
				maxPants = Val(tokens (2))

			ElseIf tokens (0) = "alias" Then 
				' ALIAS %A = B
				' Needs reparsing
				parseTokenizeString lcase (linea), tokens (), ",()[]", "#"

				If Len (tokens (1)) > 0 And Left (tokens (1), 1) = "%" Then tokens (1) = Right (tokens (1), Len (tokens (1)) - 1)
				If Len (tokens (1)) > 0 And tokens (2) = "=" And isNumber (tokens (3)) Then
					aliases (Val (tokens (3))) = lCase (tokens (1))
					If debug Then Print "Set alias %" & tokens (1) & " for flag $" & tokens (3)
				Else
					Print "Wrong alias definition at " & curLineNo
				End If

			ElseIf tokens(0) = "noindexed" Then 
				noIndexed = -1
				If debug Then Print "No indexed script. Beware!"

			ElseIf tokens(0) = "fastnpant" Then 
				fastNPant = -1
				If debug Then Print "IF NPANT = N will generate its own opcode!"

			ElseIf startsWith (tokens (), "item slot") And tokens (2) = "=" And isNumber (tokens (3)) Then
				If debug Then Print "Item slot set to " & Val (tokens (3))
				itemSlot = Val (tokens (3))

			ElseIf startsWith (tokens (), "item empty") And tokens (2) = "=" And isNumber (tokens (3)) Then
				If debug Then Print "Item empty set to " & Val (tokens (3))
				itemEmpty = Val (tokens (3))

			ElseIf startsWith (tokens (), "text width") And tokens (2) = "=" And isNumber (tokens (3)) Then 
				If debug Then Print "Text width set to " & Val (tokens (3))
				textWidth = Val (tokens (3))

			ElseIf tokens (0) = "sub" Then

				' Subroutines are added to the main binary in order, 
				' their base address remembered and used in `call` commands.

				If tokens (1) <> "" Then

					Print "Adding Sub " & tokens (1) & " @ " & sectBinIdx
					addSubInfo tokens(1), sectBinIdx

					' Parse sub
					sectionBytecode = processCurrentSection (fIn)
					If debug Then Print "Sub Bytecode: ";: printBinStr sectionBytecode

					' Write to binary
					writeToSectBinary sectionBytecode

				Else
					Print "Nameless sub at " & curLineNo
				End If

			Else
				If startsWith (tokens (), "entering screen") Or startsWith (tokens (), "press fire at screen") Then 
					' Find comma separated list
					If tokens (0) = "entering" Then 
						listToken = 2 
						sectOffset = ENTERING_INDEX_OFFSET
					Else 
						listToken = 4
						sectOffset = PRESS_FIRE_INDEX_OFFSET
					End If

					roomSectionsUsed = -1

					' Now adjust.
					' Enter is ENTERING_INDEX_OFFSET + N * 2
					' Fire is PRESS_FIRE_INDEX_OFFSET + N * 2
					i = 0: While i + listToken < uBound (tokens) And tokens (i + listToken) <> ""
						listRooms (i) = tokens (i + listToken)
						If isNumber (listRooms (i)) Then 
							listRooms (i) = Str (Val (listRooms (i)) * 2 + sectOffset)
						End If
						i = i + 1
					Wend
				Else
					' Special sections
					section = -1

					If startsWith (tokens (), "entering game") Then
						section = 0

					ElseIf startsWith (tokens (), "entering any") Then 
						section = 1
					
					ElseIf startsWith (tokens (), "press fire at any") Then
						section = 2
					
					ElseIf startsWith (tokens (), "player got something") Then
						section = 3
					
					ElseIf startsWith (tokens (), "player kills enemy") Then 
						section = 4

					ElseIf startsWith (tokens (), "special tile touched") Then
						section = 5
					
					ElseIf startsWith (tokens (), "timer zero") Then
						section = 6

					ElseIf startsWith (tokens (), "tile pushed") Then
						section = 7

					ElseIf startsWith (tokens (), "enemy touched") Then
						section = 8

					ElseIf startsWith (tokens (), "tile destroyed") Then
						section = 9

					End If

					If section >= 0 Then sectUsed (section) = -1

					listRooms (0) = Str(section)
					listRooms (1) = ""
				End If

				' Write current binary address to index
				i = 0: While i < uBound (listRooms) And listRooms (i) <> ""
					If isNumber (listRooms (i)) Then
						section = Val (listRooms (i))
						If debug Then Print "Adding " & sectBinIdx & " @ sect " & section
						sectOffs (section) = sectBinIdx
					Else
						Print "Wrong section at " & curLineNo
						cError = -1
					End If

					i = i + 1
				Wend

				If Not cError Then 
					' Parse current section
					sectionBytecode = processCurrentSection (fIn)
					If debug Then Print "Bytecode: ";: printBinStr sectionBytecode

					' Write to binary
					writeToSectBinary sectionBytecode
				End If
			End If
		End If
	Wend

	' Output binary = index with adjusted offsets, then main binary 
	' Index size = 2 * (16 + max_pants). Also write index

	mainBinIdx = 0

	If maxPants = 0 And noIndexed = 0 Then Print "WARNING! undefined # of rooms! The script won't work!"

	If jumptable Then
		' Don't index rooms in jumptable mode!
		indexSize = ENTERING_INDEX_OFFSET
	Else
		indexSize = ENTERING_INDEX_OFFSET + maxPants * 2
	End If

	If Not jumptable Then
		For i = indexSize To uBound (sectOffs)
			If sectOffs (i) >= 0 Then
				Print "ERROR! section for screen " & ((i - ENTERING_INDEX_OFFSET) \ 2) & " but ROOMS = " & maxPants
				End 1
			End If
		Next i
	End If

	For i = 0 To indexSize - 1
		If sectOffs (i) < 0 Then
			sectOffs (i) = 0
		Else
			sectOffs (i) = sectOffs (i) + indexSize * 2
		End If
		' En la salida C la entrada libre 15 guarda el número de pantallas
		' del índice, para que el intérprete no lea fuera de él.
		If outC And i = IDX_ROOMS Then sectOffs (i) = maxPants
		WriteToMainBin sectOffs (i) Mod 256
		WriteToMainBin sectOffs (i) \ 256
	Next i 

	Print "Index section: " & mainBinIdx & " bytes"

	' Copy binary
	For i = 0 To sectBinIdx - 1
		WriteToMainBin sectBinary (i)
	Next i

	Print "Bytecode section: " & sectBinIdx & " bytes"

	' Resolver los CALL
	For i = 0 To fixCount - 1
		sectOffset = getSubAddressByName (fixName (i))
		If sectOffset < 0 Then
			Print "ERROR! Unknown SUB " & fixName (i)
			End 1
		End If
		sectOffset = sectOffset + indexSize * 2
		mainBinary (indexSize * 2 + fixPos (i)) = sectOffset And &HFF
		mainBinary (indexSize * 2 + fixPos (i) + 1) = sectOffset \ 256
	Next i

End Sub

Sub writeScript (fName As String)
	Dim As Integer i, fOut 

	fOut = FreeFile
	Kill fName
	Open fName For Binary As #fOut

	For i = 0 To mainBinIdx - 1
		Put #fOut, , mainBinary (i)
	Next i 

	Print "Wrote " & mainBinIdx & " bytes to " & fName
	Close fOut

	If mainBinIdx > maxScriptSize Then maxScriptSize = mainBinIdx
End Sub

'' ---------------------------------------------------------------------------
'' Salida C (output=c)
'' ---------------------------------------------------------------------------

' "script/level1.spt" -> "LEVEL1"
Function cName (fName As String) As String
	Dim As String b, r, c
	Dim As Integer i
	b = fName
	While Instr (b, "/"): b = Mid (b, Instr (b, "/") + 1): Wend
	While Instr (b, "\"): b = Mid (b, Instr (b, "\") + 1): Wend
	If Instr (b, ".") Then b = Left (b, Instr (b, ".") - 1)
	For i = 1 To Len (b)
		c = Ucase (Mid (b, i, 1))
		If (c >= "A" And c <= "Z") Or (c >= "0" And c <= "9") Then r = r & c Else r = r & "_"
	Next i
	Return r
End Function

Sub writeCArray (fOut As Integer, arrName As String, bytes () As uByte, size As Integer)
	Dim As Integer i
	Dim As String l
	Print #fOut, "unsigned char " & arrName & " [] = {"
	l = ""
	For i = 0 To size - 1
		l = l & Trim (Str (bytes (i)))
		If i < size - 1 Then l = l & ", "
		If (i Mod 16) = 15 Or i = size - 1 Then Print #fOut, "	" & l: l = ""
	Next i
	If size = 0 Then Print #fOut, "	0"
	Print #fOut, "};"
	Print #fOut, ""
End Sub

' Añade el script recién compilado (mainBinary) a msc-scripts.h
Sub writeCScript (fOut As Integer, fName As String)
	Print #fOut, "// " & fName & " (" & mainBinIdx & " bytes)"
	Print #fOut, "#ifndef MSC_SCRIPTS_AS_RESOURCES"
	writeCArray fOut, "script_" & LCase (cName (fName)), mainBinary (), mainBinIdx
	Print #fOut, "#endif"
	Print #fOut, ""
End Sub

Sub cDefine (fOut As Integer, nombre As String, valor As String, comentario As String)
	Dim As String l
	l = "#define " & nombre
	If valor <> "" Then l = l & Space (28 - Len (l)) & valor
	If comentario <> "" Then l = l & Space (36 - Len (l)) & "// " & comentario
	Print #fOut, l
End Sub

Function hex2 (n As Integer) As String
	Return Hex (n, 2)
End Function

Sub writeCConfig (fName As String, fileIns () As String, nScripts As Integer)
	Dim As Integer fOut, i
	Dim As String sectNames (15) = { "ENTERING_GAME", "ENTERING_ANY", "FIRE_ANY", "PLAYER_GOT_SOMETHING", _
		"PLAYER_KILLS_ENEMY", "SPECIAL_TILE", "TIMER_ZERO", "TILE_PUSHED", _
		"ENEMY_TOUCHED", "TILE_DESTROYED", "", "", "", "", "", "" }

	fOut = FreeFile
	Open fName For Output As #fOut
	Print #fOut, "// msc-config.h"
	Print #fOut, "// Generado por msc4 (v=3_100 output=c). No editar: se regenera al compilar los scripts."
	Print #fOut, "// Dice al intérprete (msc.h) qué partes necesitan los scripts del juego."
	Print #fOut, ""

	Print #fOut, "// Scripts: identificadores (índice de msc_scripts [] en msc-scripts.h)"
	For i = 0 To nScripts - 1
		cDefine fOut, "SCRIPT_" & cName (fileIns (i)), Trim (Str (i)), fileIns (i)
	Next i
	cDefine fOut, "MSC_N_SCRIPTS", Trim (Str (nScripts)), ""
	cDefine fOut, "MSC_SCRIPT_MAX_SIZE", Trim (Str (maxScriptSize)), "bytes del script más grande"
	Print #fOut, ""

	Print #fOut, "// Flags: del 0 al mayor que se usa"
	cDefine fOut, "MSC_FLAGS", Trim (Str (maxFlag + 1)), ""
	Print #fOut, ""

	Print #fOut, "// Secciones que existen en algún script"
	For i = 0 To 15
		If sectUsed (i) And sectNames (i) <> "" Then cDefine fOut, "MSC_SECT_" & sectNames (i), "", ""
	Next i
	If roomSectionsUsed Then cDefine fOut, "MSC_SECT_ROOMS", "", "ENTERING SCREEN n / PRESS FIRE AT SCREEN n"
	Print #fOut, ""

	Print #fOut, "// Condiciones (MSC_CU_xx) y acciones (MSC_AU_xx) que se usan"
	For i = 0 To 255
		If CU (i) Then cDefine fOut, "MSC_CU_" & hex2 (i), "", ""
	Next i
	For i = 0 To 255
		If AU (i) Then cDefine fOut, "MSC_AU_" & hex2 (i), "", ""
	Next i
	Print #fOut, ""

	Print #fOut, "// Variables especiales que se leen (MSC_RV_xx) o se escriben (MSC_LV_xx)"
	For i = &HE6 To &HFE
		If SV (i) Then cDefine fOut, "MSC_RV_" & hex2 (i), "", ""
	Next i
	For i = &HE6 To &HFE
		If LV (i) And SV (i) Then cDefine fOut, "MSC_LV_" & hex2 (i), "", ""
	Next i
	Print #fOut, ""

	Print #fOut, "// GET ITEM"
	cDefine fOut, "MSC_ITEM_SLOT", Trim (Str (itemSlot)), "flag con el objeto que se lleva"
	cDefine fOut, "MSC_ITEM_EMPTY", Trim (Str (itemEmpty)), "valor de ""no llevo nada"""
	Print #fOut, ""

	If textPoolIndex > 0 Then
		Print #fOut, "// Textos (TEXT BOX, DIALOG)"
		cDefine fOut, "MSC_TEXTS", "", ""
		cDefine fOut, "MSC_TEXT_MAX_LEN", Trim (Str (maxTextLen)), "caracteres del texto más largo"
		cDefine fOut, "MSC_TEXT_WIDTH", Trim (Str (textWidth)), ""
	End If

	Close #fOut
	Print "Wrote " & fName
End Sub

Sub writeTexts (fName As String)
	Dim As Integer i, j, fOut, adjustedOffset, binSize
	Dim As uByte d

	fOut = FreeFile
	Kill fName
	Open fName for Binary As #fOut 

	binSize = 0

	' Write index
	'For i = 0 To textPoolIndex - 1
	'	adjustedOffset = 2 * textPoolIndex + textOffsets (i)
	'	d = adjustedOffset Mod 256: Put #fOut, , d
	'	d = adjustedOffset \ 256: Put #fOut, , d
	'	binSize = binSize + 2
	'Next i

	' Write texts
	For i = 0 To textPoolIndex - 1
		For j = 1 To Len (textPool (i))
			d = Asc (Mid (textPool (i), j, 1)): Put #fOut, , d
		Next j
		binSize = binSize + Len (textPool (i))
	Next i 

	Print "Wrote " & binSize & " bytes to " & fName
	Close fOut
End Sub

'' ---------------------------------------------------------------------------
'' Interpreter templates.
'' The interpreter is NOT in this program any more: targets/<family>.tpl holds it as chunks
'' of assembly, each one guarded by an expression over what the script uses (see the header of
'' the template files).  msc4 only decides which chunks are written.
'' ---------------------------------------------------------------------------

Function tplAtom (a As String) As Integer
	Dim As Integer neg, ok, v
	Dim As String k

	a = LCase (Trim (a))
	neg = 0
	If Left (a, 1) = "!" Then neg = -1: a = Trim (Mid (a, 2))

	ok = 0
	If a = "always" Then
		ok = -1
	ElseIf a = "jumptable" Then
		ok = (jumptable <> 0)
	ElseIf a = "speccy" Then
		ok = (outT = SPECCY)
	ElseIf a = "cpc" Then
		ok = (outT = CPC)
	ElseIf a = "gb" Then
		ok = (outT = GB)
	ElseIf Len (a) > 3 And Mid (a, 3, 1) = ":" Then
		k = Left (a, 2)
		v = ValInt ("&H" & Mid (a, 4)) And 255
		If k = "cu" Then 
			ok = (CU (v) <> 0)
		ElseIf k = "au" Then 
			ok = (AU (v) <> 0)
		ElseIf k = "rv" Then 
			ok = (RV (v) <> 0)
		ElseIf k = "lv" Then 
			ok = (LV (v) <> 0)
		Else
			Print "Template: unknown atom " & a: End
		End If
	Else
		Print "Template: unknown atom " & a: End
	End If

	If neg Then ok = Not ok
	Return ok
End Function

' term := atom { "|" atom }       expr := term { "," term }
Function tplEval (expr As String) As Integer
	Dim As Integer i, result, termOk
	Dim As String m, atomS

	result = -1: termOk = 0: atomS = ""
	For i = 1 To Len (expr) + 1
		If i > Len (expr) Then m = "," Else m = Mid (expr, i, 1)
		If m = "|" Or m = "," Then
			If tplAtom (atomS) Then termOk = -1
			atomS = ""
			If m = "," Then
				If Not termOk Then result = 0
				termOk = 0
			End If
		Else
			atomS = atomS & m
		End If
	Next i

	Return result
End Function

Function tplReplace (s As String, key As String, value As String) As String
	Dim As Integer p
	Dim As String r
	r = s
	p = InStr (r, key)
	While p > 0
		r = Left (r, p - 1) & value & Mid (r, p + Len (key))
		p = InStr (p + Len (value), r, key)
	Wend
	Return r
End Function

Function tplGlobals (s As String) As String
	Dim As String r
	r = tplReplace (s, "{ENTERING_INDEX_OFFSET}", Trim (Str (ENTERING_INDEX_OFFSET)))
	r = tplReplace (r, "{ITEM_SLOT}", Trim (Str (itemSlot)))
	r = tplReplace (r, "{ITEM_EMPTY}", Trim (Str (itemEmpty)))
	Return r
End Function

Function tplFind (family As String) As String
	Dim As String c
	c = sclpGetValue ("template")
	If c <> "" Then Return c
	c = ExePath & "/targets/" & family & ".tpl"
	If Dir (c) <> "" Then Return c
	c = "targets/" & family & ".tpl"
	If Dir (c) <> "" Then Return c
	Print "Can't find interpreter template targets/" & family & ".tpl (use template=file)"
	End 1
End Function

Sub tplEmitEntries (fOut As Integer, feBody () As String, feCount As Integer)
	Dim As Integer i, k, isEnt, room
	Dim As String b

	isEnt = -1: room = 0
	For i = ENTERING_INDEX_OFFSET To ENTERING_INDEX_OFFSET + maxPants * 2 - 1
		If sectOffs (i) >= 0 Then
			For k = 0 To feCount - 1
				b = tplGlobals (feBody (k))
				If isEnt Then
					b = tplReplace (b, "{comment}", "ENTERING " & room)
				Else
					b = tplReplace (b, "{comment}", "FIRE @   " & room)
				End If
				b = tplReplace (b, "{offs4}", Hex (sectOffs (i) + ENTERING_INDEX_OFFSET * 2, 4))
				b = tplReplace (b, "{index}", Trim (Str (i)))
				writeAssemblyString fOut, b
			Next k
		End If
		isEnt = Not isEnt: If isEnt Then room = room + 1
	Next i
End Sub

Sub generateInterpreter (fOut As Integer, tplFile As String)
	Dim As Integer fT, chunkOpen, active, inFE, feActive, feCount, nLines
	Dim As String ln, dirv, body
	Dim As String feBody (31)

	fT = FreeFile
	If Open (tplFile For Input As #fT) <> 0 Then 
		Print "Can't open template " & tplFile
		End 1
	End If

	chunkOpen = 0: active = 0: inFE = 0: feActive = 0: feCount = 0: body = "": nLines = 0

	While Not Eof (fT)
		Line Input #fT, ln
		If Len (ln) > 0 And Right (ln, 1) = Chr (13) Then ln = Left (ln, Len (ln) - 1)

		If Left (ln, 2) = ";@" Then
			' Close the chunk being collected
			If chunkOpen Then
				If inFE Then
					feBody (feCount) = body: feCount = feCount + 1
				ElseIf active Then
					writeAssemblyString fOut, tplGlobals (body)
				End If
			End If
			chunkOpen = 0: body = "": nLines = 0

			dirv = Trim (Mid (ln, 3))
			If dirv = "always" Then
				chunkOpen = -1: active = -1
			ElseIf Left (dirv, 5) = "when " Then
				chunkOpen = -1: active = tplEval (Mid (dirv, 6))
			ElseIf Left (dirv, 8) = "foreach " Then
				' ";@ foreach jt when EXPR"
				inFE = -1: feCount = 0
				feActive = tplEval (Mid (dirv, InStr (dirv, " when ") + 6))
				chunkOpen = -1
			ElseIf dirv = "next" Then
				chunkOpen = -1
			ElseIf dirv = "end" Then
				If feActive Then tplEmitEntries fOut, feBody (), feCount
				inFE = 0: feActive = 0: feCount = 0
			ElseIf Left (dirv, 1) = "#" Then
				' comment
			Else
				Print "Template: unknown directive " & ln: End 1
			End If
		ElseIf chunkOpen Then
			ln = LTrim (ln, Any Chr (32) & Chr (9))
			If nLines > 0 Then body = body & "|"
			body = body & ln
			nLines = nLines + 1
		End If
	Wend

	If chunkOpen And active And Not inFE Then 
		writeAssemblyString fOut, tplGlobals (body)
	End If

	Close #fT
End Sub

Sub usage
	Print "usage:"
	Print ""
	Print "msc4.exe in=f1.spt[,f2.spt,...] v=3|4|5 target=cpc|zx|gb rooms=N [text=text.bin]"
	Print "         [interpreter=msci.asm] [noindexed] [fastnpant] [jumptable]"
	Print "         in is [a list of|the] input filename."
	Print "           msc4 will generate a f.bin per input,"
	Print "           but only one common interpreter."
	Print "         v is the MK1 base version, 3, 4, or 5"
	Print "         target: is the target OM (zx or cpc)"
	Print "         rooms: is the total of rooms in the map"
	Print "         interpreter: for custom interpreter filename"
	Print "         noindexed: if you are only using general sections (ANY, etc)"
	Print "         fastnpant: generates a (faster) special opcode for IF NPANT"
	Print "         jumptable: code based jump table rather than index"
	Print ""
	Print "msc4.exe in=f1.spt[,f2.spt,...] v=3_100 output=c [rooms=N]"
	Print "         [interpreter=msc-config.h] [scripts=msc-scripts.h]"
	Print "         MK1 v3.100: the interpreter is src/dev/msc.h (pure C). msc4 writes"
	Print "         f.spt.bin per input, msc-config.h (what the interpreter needs) and"
	Print "         msc-scripts.h (bytecode as C arrays + encoded texts)."
End Sub

'' Interfaz
'' in=f1,f2,f3 ... genera f1.bin, f2.bin... pero el mismo intérprete
'' v=3|4|5
'' target=cpc|zx


Dim As String mandatory (1) = { "in", "v" }
Dim As Integer fIn, fOut, i
Dim As String fileIns(127)
Dim As String fileText
Dim As Integer isEntering, room

Print "msc v4.7.20261030 ~ ";

sclpParseAttrs
If Not sclpCheck (mandatory ()) Then usage: End 

debug = (sclpGetValue ("debug") <> "")
textdebug = (sclpGetValue ("textdebug") <> "")
parseCommaSeparatedString sclpGetValue ("in"), fileIns ()

interpreterFn = sclpGetValue("interpreter")
If interpreterFn = "" Then interpreterFn = "msci.asm"

outV = Val(sclpGetValue("v"))
If sclpGetValue("v") = "3_100" Then outV = 3100
outT = SPECCY: If sclpGetValue("target") = "cpc" Then outT = CPC
If sclpGetValue("target") = "gb" Then outT = GB
noIndexed = (sclpGetValue("noindexed") <> "")
fastNPant = (sclpGetValue("fastnpant") <> "")
jumptable = (sclpGetValue("jumptable") <> "")

' output=c: bytecode + msc-config.h + msc-scripts.h para el intérprete C de
' MK1 v3.100 (src/dev/msc.h). El intérprete no se genera: ya está en el motor.
outC = (LCase (sclpGetValue("output")) = "c")
If outC Then
	If outV <> 3100 Then Print "output=c needs v=3_100": End 1
	If jumptable Then Print "jumptable makes no sense with output=c": End 1
	If interpreterFn = "msci.asm" Then interpreterFn = "msc-config.h"
ElseIf outV = 3100 Then
	Print "v=3_100 needs output=c": End 1
ElseIf sclpGetValue("target") = "" Then
	usage: End 1
End If

Dim As String scriptsFn
Dim As Integer fScripts
scriptsFn = sclpGetValue ("scripts")
If scriptsFn = "" Then scriptsFn = "msc-scripts.h"
If outC Then
	fScripts = FreeFile
	Open scriptsFn For Output As #fScripts
	Print #fScripts, "// msc-scripts.h"
	Print #fScripts, "// Generado por msc4 (v=3_100 output=c). No editar."
	Print #fScripts, "// Bytecode de los scripts y textos. Con MSC_SCRIPTS_AS_RESOURCES (niveles"
	Print #fScripts, "// en 128K) los scripts van como recursos y aquí solo quedan los textos."
	Print #fScripts, ""
End If

allOpcodes = (sclpGetValue ("allopcodes") <> "")

fileText = sclpGetValue ("text")
If fileText = "" Then fileText = "text.bin"

lastTextOffset = 0
textPoolIndex = 0
textWidth = 24

i = 0: While i < 127 And fileIns(i) <> ""
	curLineNo = 0
	resetAliases 
	maxPants = Val (sclpGetValue ("rooms"))

	fIn = FreeFile
	Open fileIns(i) For Input As #fIn
	Print "Processing " & fileIns(i)
	processScript (fIn)
	Close #fIn
	writeScript fileIns(i) & ".bin"
	If outC Then writeCScript fScripts, fileIns (i)
	If debug Then debugPrintAliases

	i = i + 1
Wend 

'' Export encoded texts (if any)
If textPoolIndex > 0 Then 
	Print "Exporting encoded text"
	writeTexts fileText
End If

If outC Then
	Dim As Integer nScripts, j, k
	nScripts = i

	' Índice de scripts: msc_scripts [SCRIPT_X] apunta al bytecode de X.
	Print #fScripts, "#ifndef MSC_SCRIPTS_AS_RESOURCES"
	Print #fScripts, "unsigned char *msc_scripts [] = {"
	For j = 0 To nScripts - 1
		Print #fScripts, "	script_" & LCase (cName (fileIns (j))) & IIf (j < nScripts - 1, ",", "")
	Next j
	Print #fScripts, "};"
	Print #fScripts, "#endif"
	Print #fScripts, ""

	' Textos codificados (5 bits por carácter), referenciados por offset.
	If textPoolIndex > 0 Then
		ReDim As uByte textBytes (lastTextOffset)
		k = 0
		For j = 0 To textPoolIndex - 1
			For i = 1 To Len (textPool (j))
				textBytes (k) = Asc (Mid (textPool (j), i, 1)): k = k + 1
			Next i
		Next j
		writeCArray fScripts, "msc_texts", textBytes (), k
	End If
	Close #fScripts
	Print "Wrote " & scriptsFn

	If allOpcodes Then
		For i = 0 To 255
			AU (i) = -1: CU (i) = -1: LV (i) = -1: RV (i) = -1: SV (i) = -1
		Next i
		For i = 0 To 15: sectUsed (i) = -1: Next i
		roomSectionsUsed = -1
	End If

	writeCConfig interpreterFn, fileIns (), nScripts
	Print "DONE!"
	End
End If

'' GENERATE INTERPRETER
'' Only output conditions & actios for opcodes in AU and CU.

If allOpcodes Then
	' Debug / "full" interpreter: every opcode the templates know about
	For i = 0 To 255
		AU (i) = -1: CU (i) = -1: LV (i) = -1: RV (i) = -1
	Next i
End If

Print "Writing interpreter"

If outT = GB Then templateFile = tplFind ("gb") Else templateFile = tplFind ("z80")

fOut = FreeFile
Open interpreterFn For Output As #fOut

generateInterpreter fOut, templateFile

Close #fOut

Print "DONE!"
