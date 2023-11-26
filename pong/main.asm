	SLDOPT COMMENT WPMEM, LOGPOINT, ASSERTION
	device	ZXSPECTRUM48

	ORG	$8000

; start is used by the compiler to create the SNA so has to be first
codeStart:
	; Setup

	; We need to explicitly enable interrupts for SNA since the snapshot
	; loader code disables interrupts so we are working from a known clean
	; slate but it's not a bad idea for TAP too...
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


	INCLUDE 	"video.asm"
	INCLUDE 	"controls.asm"
	INCLUDE 	"sprite.asm"
	INCLUDE 	"game.asm"

codeLen	= $-codeStart

	; Snapshot for ZSim
	SAVESNA 	"build/pong.sna", codeStart

	; Tap file using loader from sjasmplus example lib
	INCLUDE 	"loader.asm"
	MakeTape	ZXSPECTRUM48, "build/pong.tap", "PONG", codeStart, codeLen, codeStart
