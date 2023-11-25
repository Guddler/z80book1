	SLDOPT COMMENT WPMEM, LOGPOINT, ASSERTION
	device	zxspectrum128

	ORG	$8000

; start is used by the compiler to create the SNA so has to be first
start:
	; Setup
	EI
	; Set the border to red
	LD	A, $02
	OUT	($FE), A
	; Set an initial ball rotation of 0
	LD	A, $00
	LD	(ballRotation), A
	; Initial screen draw
	CALL	Cls
	CALL	PrintLine
	CALL	PrintBorder

Loop:
	CALL	MoveBall

	; Print ball and loop
	CALL 	PrintBall
	CALL	ReprintLine

	; Read player input and move paddles
	CALL	ScanKeys
	CALL	MovePaddles

	; Draw paddles
	LD 	HL, (paddle1pos)
	CALL	PrintPaddle
	LD	HL, (paddle2pos)
	CALL	PrintPaddle

	JR	Loop

	; End main game loop

	; VARs
countLoopBall:		DB	$00
countLoopPaddles:	DB	$00


	include "video.asm"
	include "controls.asm"
	include "sprite.asm"
	include "game.asm"

	SAVESNA "build/pong.sna", start
