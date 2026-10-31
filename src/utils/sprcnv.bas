#include "fbpng.bi"
#include "fbgfx.bi"
#include once "crt.bi"

#define RGBA_R( c ) ( CUInt( c ) Shr 16 And 255 )
#define RGBA_G( c ) ( CUInt( c ) Shr  8 And 255 )
#define RGBA_B( c ) ( CUInt( c )        And 255 )
#define RGBA_A( c ) ( CUInt( c ) Shr 24         )

Dim Shared As Any Ptr img 			' will contain the image loaded from the PNG

Sub Usage () 
	Print "** USO **"
	Print "   sprcnv archivo.png salida.h [nomask]"
	Print "   sprcnv archivo.png salida.bin [nomask]"
	Print
	Print "Convierte un spriteset de 16 sprites de ZX Spectrum. Con salida .h"
	Print "escribe un array de C (const) y un #define sprite_N_a/b/c por columna;"
	Print "con salida .bin, los mismos bytes en binario (spritesets de los niveles,"
	Print "que se cargan en sprite_1_a - 16)."
End Sub

Function ReadBinValue (x As Integer, y As Integer) As Integer
	Dim As Integer ac, xx, p1
	ac = 0
	for xx = 0 to 7
		p1 = point (x + xx, y, img)
		if RGBA_R (p1) <> 0 Or RGBA_G (p1) <> 0 Or RGBA_B (p1) <> 0 Then
			ac = ac + 2 ^ (7 - xx)
		end if
	next xx
	Return ac
End Function

' Los bytes se acumulan en buf y las etiquetas (sprite_N_a...) apuntan a un
' desplazamiento dentro de buf.
Dim Shared As Integer buf (8191), nbuf
Dim Shared As String labName (63)
Dim Shared As Integer labOffs (63), nlab

Sub B (v As Integer)
	buf (nbuf) = v: nbuf = nbuf + 1
End Sub

Sub L (nombre As String)
	labName (nlab) = nombre: labOffs (nlab) = nbuf: nlab = nlab + 1
End Sub

'
'
'

Dim as String filename, o
Dim as integer i, j, f, sprite, x, y, xx, yy, ac, nomask
Dim as unsigned long p1, p2

If Len (Command (1)) = 0 Or Len (Command (2)) = 0 Then 
	Usage
	End
End If

If lcase(Command (3)) = "nomask" Then nomask = -1 else nomask = 0

' Primero cargo el archivo de imagen
screenres 640, 480, 32, , -1

filename = Command (1)
img = png_load ( filename )

if img then
'	put( 0, 0 ), img
'	deallocate( img )
else
	print "Failed to load"
end if

' Ahora lo recorro y voy generando el código con sus etiquetas y
' sus mascaritas y toda la pesca

x = 0
y = 0



If nomask Then
	for i = 0 to 7: B 0: B 0: next i
	For sprite = 1 To 16 Step 2

		' Interleaved stuff
		
		' Sprite L: c1, c2
		For yy = 0 To 15
			If yy = 0 Then L "sprite_" & sprite & "_a"
			B ReadBinValue (x, y+yy)
			If yy = 0 Then L "sprite_" & (sprite+1) & "_a"
			B ReadBinValue (x + 16, y+yy)
		Next yy
		For yy = 0 To 7
			B 0: B 0
		Next yy

		' Sprite L: c3, L+1: c1
		For yy = 0 To 15
			If yy = 0 Then L "sprite_" & sprite & "_b"
			B ReadBinValue (x + 8, y+yy)
			If yy = 0 Then L "sprite_" & (sprite+1) & "_b"
			B ReadBinValue (x + 24, y+yy)
		Next yy
		For yy = 0 To 7
			B 0: B 0
		Next yy

		' Sprite L+1: c2, c3
		For yy = 0 To 15
			If yy = 0 Then L "sprite_" & sprite & "_c"
			B 0
			If yy = 0 Then L "sprite_" & (sprite+1) & "_c"
			B 0
		Next yy
		For yy = 0 To 7
			B 0: B 0
		Next yy

		x = x + 32
		if x = 256 then
			y = y + 16
			x = 0
		end if
	Next
Else
	for i = 0 to 7: B 0: B 255: next i
	For sprite = 1 to 16

		' Primera columna 
		
		L "sprite_" & sprite & "_a"
		for yy = 0 to 15
			B ReadBinValue (x, y+yy): B ReadBinValue (x + 16, y+yy)
		next yy
		for yy = 0 to 7: B 0: B 255: next yy
		
		' Segunda columna 
		
		L "sprite_" & sprite & "_b"
		for yy = 0 to 15
			B ReadBinValue (x + 8, y+yy): B ReadBinValue (x + 24, y+yy)
		next yy
		for yy = 0 to 7: B 0: B 255: next yy
		
		' Tercera columna
		
		L "sprite_" & sprite & "_c"
		for yy = 0 to 23: B 0: B 255: next yy
		
		x = x + 32
		if x = 256 then
			y = y + 16
			x = 0
		end if
	Next sprite
End If

' Salida
f = FreeFile
If LCase (Right (Command (2), 4)) = ".bin" Then
	Open Command (2) For Binary As f
	For i = 0 To nbuf - 1: Put #f, , CUByte (buf (i)): Next i
Else
	Open Command (2) For Output As f
	Print #f, "// La Churrera Engine 3.100"
	Print #f, "// sprites.h: generado por sprcnv a partir de " & Command (1)
	If nomask Then Print #f, "// Sin mascaras"
	Print #f, ""
	Print #f, "// Cada sprite son tres columnas (a, b, c) de 24 lineas, con 8 lineas de"
	Print #f, "// relleno delante del primero; todas ocupan lo mismo, asi que la"
	Print #f, "// diferencia entre dos frames vale para las tres columnas."
	Print #f, "const unsigned char sprite_data [] = {"
	For i = 0 To nbuf - 1
		If (i Mod 16) = 0 Then o = Chr (9)
		o = o & buf (i)
		If i < nbuf - 1 Then o = o & ", "
		If (i Mod 16) = 15 Or i = nbuf - 1 Then Print #f, RTrim (o)
	Next i
	Print #f, "};"
	Print #f, ""
	For i = 0 To nlab - 1
		Print #f, "#define " & labName (i) & Chr (9) & "(sprite_data + " & labOffs (i) & ")"
	Next i
End If
Close f

puts "¡Todo correcto!"