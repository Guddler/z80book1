	SLDOPT COMMENT WPMEM, LOGPOINT, ASSERTION
	device	zxspectrum128

	ORG	$8000

; start is used by the compiler to create the SNA so has to be first
start:
	; Temporary ball test

	EI
	; Set the border to red
	LD	A, $02
	OUT	($FE), A
	; Set an initial ball rotation of 0
	; LD	A, $00
	; LD	(ballRotation), A
	CALL	Cls
	CALL	PrintLine
	CALL	PrintBorder

Loop:
	; Load an increment out loop count
	LD	A, (countLoopBall)
	INC	A
	; Save the loop count
	LD	(countLoopBall), A
	; If we've not reached our delay limit carry on waiting
	CP	$2F
	JR	NZ, loop_continue

	; Finished waiting? Move ball and reset delay
	CALL	MoveBall
	LD	A, $00
	LD	(countLoopBall), A

loop_continue:
	; Print ball and loop
	CALL 	PrintBall
	CALL	ReprintLine
	
	JR	Loop

countLoopBall:	DB	$00

loop_cont:
	LD	B, $08
loopRight:
	EXX
	LD	A, (ballRotation)
	INC	A
	LD 	(ballRotation), A
	CALL	PrintBall
	EXX
	DJNZ	loopRight

	LD	A, $00
	LD	(ballRotation), A
	LD	B, $08
loopLeft:
	EXX
	LD	A, (ballRotation)
	DEC	A
	LD 	(ballRotation), A
	CALL	PrintBall
	EXX
	; HALT
	DJNZ	loopLeft

	LD	A, $00
	LD	(ballRotation), A

	JR	loop_cont


; 	; Set the border to red
; 	LD	A, $02
; 	OUT	($FE), A
; 	; Set an initial ball rotation of 0
; 	LD	A, $00
; 	LD	(ballRotation), A
; 	; Clear screen and print our centre line
; 	CALL 	Cls
; 	CALL	PrintLine

; loop:
; 	CALL	ScanKeys

; 	; Paddle movement
; MovePaddle1Up:
; 	BIT	$00, D
; 	JR	Z, MovePaddle1Down
; 	LD	HL, (paddle1pos)
; 	LD	A, PADDLE_TOP
; 	CALL	CheckTop
; 	JR	Z, MovePaddle2Up
; 	CALL	PreviousScan
; 	LD	(paddle1pos), HL
; 	JR	MovePaddle2Up

; MovePaddle1Down:
; 	BIT	$01, D
; 	JR	Z, MovePaddle2Up
; 	LD	HL, (paddle1pos)
; 	LD	A, PADDLE_BOTTOM
; 	CALL	CheckBottom
; 	JR	Z, MovePaddle2Up
; 	CALL	NextScan
; 	LD	(paddle1pos), HL


; MovePaddle2Up:
; 	BIT	$02, D
; 	JR	Z, MovePaddle2Down
; 	LD	HL, (paddle2pos)
; 	LD	A, PADDLE_TOP
; 	CALL	CheckTop
; 	JR	Z, drawPaddles
; 	CALL	PreviousScan
; 	LD	(paddle2pos), HL
; 	JR	drawPaddles

; MovePaddle2Down:
; 	BIT	$03, D
; 	JR	Z, drawPaddles
; 	LD	HL, (paddle2pos)
; 	LD	A, PADDLE_BOTTOM
; 	CALL	CheckBottom
; 	JR	Z, drawPaddles
; 	CALL	NextScan
; 	LD	(paddle2pos), HL



; drawPaddles:
; 	LD 	HL, (paddle1pos)
; 	CALL	PrintPaddle

; 	LD	HL, (paddle2pos)
; 	CALL	PrintPaddle

; 	JR	loop

	include "video.asm"
	include "controls.asm"
	include "sprite.asm"
	include "game.asm"

	SAVESNA "build/pong.sna", start
