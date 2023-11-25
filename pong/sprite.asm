
; CONSTS
PADDLE_BOTTOM:	EQU	$A6	; TTLLLSSS
PADDLE_TOP:	EQU	$02	; TTLLLSSS
BALL_BOTTOM:	EQU	$B8	; TTLLLSSS
BALL_TOP:	EQU	$02	; TTLLLSSS
MARGIN_LEFT:	EQU	$00
MARGIN_RIGHT:	EQU	$1e

; VARS
paddle1pos:	DW	$4861	; 010T TSSS LLLC CCCC
paddle2pos:	DW	$487E	; 010T TSSS LLLC CCCC
ballPos:	DW	$4870	; 010T TSSS LLLC CCCC
ballRotation:	DB	$F8	; Right rot: +ve, Left rot: -ve
ballSetting:	DB	$00	; 7	Y Dir (0 up, 1 down)
				; 6	X Dir (0 right, 1 left)
				; 5-4	Y Speed
				; 0-3	X Speedw

; Sprite definitions (of sorts)
ZERO:		EQU	$00	; 00000000
LINE:		EQU	$80	; 00010000
PADDLE:		EQU	$3C	; 00111100
FILL:		EQU	$FF	; 11111111

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

	MODULE sprite

;------------------------------------------------------------------------------
; PrintPaddle
; Paints a paddle
;
; Input: HL -> paddle position
; Output: None
; B and HL changed on exit
;------------------------------------------------------------------------------

@PrintPaddle:
	LD	(HL), ZERO
	CALL	NextScan

	LD	B, $16
!printPaddle_loop:
	LD	(HL), PADDLE
	CALL	NextScan
	DJNZ	printPaddle_loop

	LD	(HL), ZERO
	RET

	ENDMODULE
