;
; Key Translation table
; Alvin Albrecht 2002
;

	.module SPkeytranstbl
	.globl SPkeytranstbl

; This table translates key presses into ascii codes.
; Used by 'GetKey' and 'LookupKey'.  An effort has been made for this
; key translation table to emulate a PC keyboard with the 'CTRL' key represented
; by CAPS SHIFT + SYM SHIFT.

SPkeytranstbl:
	.db 255,"z","x","c","v"; CAPS SHIFT, Z, X, C, V
	.db "a","s","d","f","g"; A, S, D, F, G
	.db "q","w","e","r","t"; Q, W, E, R, T
	.db "1","2","3","4","5"; 1, 2, 3, 4, 5
	.db "0","9","8","7","6"; 0, 9, 8, 7, 6
	.db "p","o","i","u","y"; P, O, I, U, Y
	.db 13,"l","k","j","h"; ENTER, L, K, J, H
	.db " ",255,"m","n","b"; SPACE, SYM SHIFT, M, N, B

   ; the following are CAPS SHIFTed

	.db 255,"Z","X","C","V"; CAPS SHIFT, Z, X, C, V
	.db "A","S","D","F","G"; A, S, D, F, G
	.db "Q","W","E","R","T"; Q, W, E, R, T
	.db 7,0,128,129,8; 1, 2, 3, 4, 5
	.db 12,8,9,11,10; 0, 9, 8, 7, 6
	.db "P","O","I","U","Y"; P, O, I, U, Y
	.db 13,"L","K","J","H"; ENTER, L, K, J, H
	.db " ",255,"M","N","B"; SPACE, SYM SHIFT, M, N, B

   ; the following are SYM SHIFTed

	.db 255,":",96,"?","/"; CAPS SHIFT, Z, X, C, V
	.db "&","|",92,"{","}"; A, S, D, F, G
	.db 131,132,133,"<",">"; Q, W, E, R, T
	.db "!","@","#","$","%"; 1, 2, 3, 4, 5
	.db "_",")","(",39,"&"; 0, 9, 8, 7, 6
	.db 34,";',130,']','['       ; P, O, I, U, Y
	.db 13,"=","+","-","^"; ENTER, L, K, J, H
	.db " ",255,".",",","*"; SPACE, SYM SHIFT, M, N, B

   ; the following are CAPS SHIFTed and SYM SHIFTed ("CTRL" key)

	.db 255,26,24,3,22; CAPS SHIFT, Z, X, C, V
	.db 1,19,4,6,7; A, S, D, F, G
	.db 17,23,5,18,20; Q, W, E, R, T
	.db 27,28,29,30,31; 1, 2, 3, 4, 5
	.db 127,255,134,"`",135; 0, 9, 8, 7, 6
	.db 16,15,9,21,25; P, O, I, U, Y
	.db 13,12,11,10,8; ENTER, L, K, J, H
	.db " ",255,13,14,2; SPACE, SYM SHIFT, M, N, B
