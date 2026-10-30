Dim b as uByte
Dim i as Integer

Sub usage
	Print "$ expBehaviours behaviours.txt behaviours.bin"
End Sub

If Command (1) = "" Or Command (2) = "" Then
	usage
	System
End If

Open Command (1) for Input as #1
Open Command (2) for Binary as #2

For i = 1 To 48
	Input #1, b
	Put #2, , b
Next i

Close 1, 2
