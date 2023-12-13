
; CONSTS
PADDLE_BOTTOM:	EQU	$A6	; TTRRRSSS
PADDLE_TOP:	EQU	$02	; TTRRRSSS
PADDLE1POS_INI:	EQU	$4861	; 010T TSSS RRRC CCCC
PADDLE2POS_INI:	EQU	$487E	; 010T TSSS RRRC CCCC
BALL_BOTTOM:	EQU	$B8	; TTRRRSSS
BALL_TOP:	EQU	$02	; TTRRRSSS
BALL_POS_INI:	EQU	$4850	; Initial ball position
MARGIN_LEFT:	EQU	$00
MARGIN_RIGHT:	EQU	$1E
CROSS_LEFT:	EQU	$01	; X collision column left
CROSS_RIGHT:	EQU	$1D	; X collision column right
				; Y collision is by 3rd + scanline + row
CROSS_LEFT_ROT:	EQU	$FF	; Rotation the ball should have when it
CROSS_RIGHT_ROT	EQU	$01	; collides with the paddle

POINTS_P1:	EQU	$450D	; 010T TSSS RRRC CCCC
POINTS_P2:	EQU	$4511	; 010T TSSS RRRC CCCC

				; These all define the edges of the score areas
				; we use them so allow us to only reprint the
				; score when the ball passes over it instead of
				; blindly doing it every time. Optimisation yay!
POINTS_X1_L:	EQU	$0C	; P1 Score, left edge	- TTRRRSSS
POINTS_X1_R:	EQU	$0F	; P1 Score, right edge 	- TTRRRSSS
POINTS_X2_L:	EQU	$10	; P2 Score, left edge	- TTRRRSSS
POINTS_X2_R:	EQU	$13	; P2 Score, right edge	- TTRRRSSS
POINTS_Y_B:	EQU	$14	; Score, bottom edge	- TTRRRSSS

; VARS
paddle1pos:	DW	$4861	; 010T TSSS RRRC CCCC
paddle2pos:	DW	$487E	; 010T TSSS RRRC CCCC
ballPos:	DW	$4870	; 010T TSSS RRRC CCCC
ballRotation:	DB	$F8	; Right rot: +ve, Left rot: -ve
ballMoveCount:	DB	$00	; Number of frames ball must take to change dir
ballSetting:	DB	$31	; Ball speed and direction:
				; 7	Y Dir (0 up, 1 down)
				; 6	X Dir (0 right, 1 left)
				; 5-3	Ball Speed
				;	2 - Stupid fast
				;	3 - Fast
				;	4 - Normal
				; 0-2	Movements of the ball to change the Y pos
				;	7 - Semi flat
				;	2 - Semi diagonal
				;	1 - Diagonal

; Sprite definitions (of sorts)
BLANK:		EQU	$00	; 00000000
LINE:		EQU	$80	; 00010000
;PADDLE:		EQU	$3C	; 00111100
PADDLE1:	EQU	$0F	; 00001111
PADDLE2:	EQU	$F0	; 11110000
FILL:		EQU	$FF	; 11111111

; Score digits 'sprites'
Zero:
	DW	whiteSprite, zeroSprite
One:
	DW	whiteSprite, oneSprite
Two:
	DW	whiteSprite, twoSprite
Three:
	DW	whiteSprite, threeSprite
Four:
	DW	whiteSprite, fourSprite
Five:
	DW	whiteSprite, fiveSprite
Six:
	DW	whiteSprite, sixSprite
Seven:
	DW	whiteSprite, sevenSprite
Eight:
	DW	whiteSprite, eightSprite
Nine:
	DW	whiteSprite, nineSprite
Ten:
	DW	oneSprite, zeroSprite
Eleven:
	DW	oneSprite, oneSprite
Twelve:
	DW	oneSprite, twoSprite
Thirteen:
	DW	oneSprite, threeSprite
Fourteen:
	DW	oneSprite, fourSprite
Fifteen:
	DW	oneSprite, fiveSprite


; Ball sprite. This is like Manic miner where you don't move the ball to the
; right by 1 pixel, you have 8 different sprites, each with the ball shifted 1
; pixel further right until eventually you have to increment the column of the
; ball position. This is just a shite oddity of what is basically a character
; based screen. The Next probably doesn't need this as it has true hardware
; pixels...

; 1 blank line, 4 white lines, 1 blank line

; Each line defines the visible part of the sphere, depending on how the pixels
; are positioned. We use two bytes poer position. The comment shows the rotation
; when the ball goes to the right and to the left
					; Right		Sprite		 Left
ballRight:	DB	$3C, $00	; +0|$00 00111100	00000000 -8|$F8
		DB	$1E, $00	; +1|$01 00011110	00000000 -7|$F9
		DB	$0F, $00	; +2|$02 00001111	00000000 -6|$FA
		DB	$07, $80	; +3|$03 00000111	10000000 -5|$FB
		DB	$03, $C0	; +4|$04 00000011	11000000 -4|$FC
		DB	$01, $E0	; +5|$05 00000001	11100000 -3|$FD
		DB	$00, $F0	; +6|$06 00000000	11110000 -2|$FE
		DB	$00, $78	; +7|$07 00000000	01111000 -1|$FF
ballLeft:	DB	$00, $3C	; +8|$08 00000000	00111100 +0|$00

; Score Digits
;
; Each digit is 8x16 high, so two bytes. The memory locations are defined above
;
	; Empty square (white)
whiteSprite:
	; DS $10 means 16 spaces
	DS	$10
zeroSprite:
	DB	$00, $7E, $7E, $66, $66, $66, $66, $66
	DB	$66, $66, $66, $66, $66, $7E, $7E, $00
oneSprite:
	DB	$00, $18, $18, $18, $18, $18, $18, $18
	DB	$18, $18, $18, $18, $18, $18, $18, $00
twoSprite:
	DB	$00, $7E, $7E, $06, $06, $06, $06, $7E
	DB	$7E, $60, $60, $60, $60, $7E, $7E, $00
threeSprite:
	DB	$00, $7E, $7E, $06, $06, $06, $06, $3E
	DB	$3E, $06, $06, $06, $06, $7E, $7E, $00
fourSprite:
	DB	$00, $66, $66, $66, $66, $66, $66, $7E
	DB	$7E, $06, $06, $06, $06, $06, $06, $00
fiveSprite:
	DB	$00, $7E, $7E, $60, $60, $60, $60, $7E
	DB	$7E, $06, $06, $06, $06, $7E, $7E, $00
sixSprite:
	DB	$00, $7E, $7E, $60, $60, $60, $60, $7E
	DB	$7E, $66, $66, $66, $66, $7E, $7E, $00
sevenSprite:
	DB	$00, $7E, $7E, $06, $06, $06, $06, $06
	DB	$06, $06, $06, $06, $06, $06, $06, $00
eightSprite:
	DB	$00, $7E, $7E, $66, $66, $66, $66, $7E
	DB	$7E, $66, $66, $66, $66, $7E, $7E, $00
nineSprite:
	DB	$00, $7E, $7E, $66, $66, $66, $66, $7E
	DB	$7E, $06, $06, $06, $06, $7E, $7E, $00

	ifdef ZXNEXT
;
; ZX Next Hardware sprites (digits 0-9, border & corner)
;
;
; Sprite data for Pong game
;

; Pattern numbers
PATTERN_BORDER		EQU 10
PATTERN_CORNER		EQU 11

sprite_count 		EQU 12

; Digits 0-9 in that order
spriteStart:
	; 0
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	; 1
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	; 2
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	; 3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	; 4
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	; 5
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	; 6
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	; 7
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	; 8
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	; 9
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	; Top Border (Mirror / Rotate for other borders)
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	DB $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	; Top Left Corner (Mirror / Rotate for other corners)
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $00, $00, $00
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $00, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $00, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $e3, $e3, $e3, $e3, $e3
	DB $e3, $e3, $e3, $e3, $e3, $e3, $e3, $00, $00, $e3, $e3, $e3, $e3, $e3, $e3, $e3

; 2 Colour palette (1: WHITE, 2: BLACK)
;
palette_count EQU 255
palette:
	DB $ff, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	DB $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	DB $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	DB $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	DB $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	DB $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	DB $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	DB $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	DB $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	DB $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	DB $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	DB $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	DB $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	DB $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	DB $00, $00, $00, $e3, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	DB $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

	endif	// ZXNEXT

	MODULE sprite

;------------------------------------------------------------------------------
; PrintPaddle
; Paints a paddle. Paddle is 22 scanlines high with a blank line above and
; below for a total of 24 scan lines or 3 rows.
;
; This is more relevant to collision detection, but the paddle is divided into
; 5 vertical zones. Where the ball hits determines the speed of the ball and
; also the
;	-	-
;	-	1	---
;	-	1	|	Speed
;	-	1	|	Slow
;	-	1	---
;	-	2	---
;	-	2	|
;	-	2	|	Speed
;	-	2	|	Normal
;	-	2	---
;	-	3	---
;	-	3	|	Speed
;	-	3	|	Fast
;	-	3	---
;	-	4	---
;	-	4	|
;	-	4	|	Speed
;	-	4	|	Normal
;	-	4	---
;	-	5	---
;	-	5	|	Speed
;	-	5	|	Slow
;	-	5	---
;	-	-
;
; Input: HL -> paddle position
;	 C -> sprite of paddle
; Output: None
; B and HL changed on exit
;------------------------------------------------------------------------------
@PrintPaddle:
	LD	(HL), BLANK
	CALL	NextScan

	LD	B, $16
.loop:
	LD	(HL), C
	CALL	NextScan
	DJNZ	.loop

	LD	(HL), BLANK
	RET

	ENDMODULE
