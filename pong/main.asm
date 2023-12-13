	SLDOPT COMMENT WPMEM, LOGPOINT, ASSERTION

	;; Comment out to build 48K
	define ZXNEXT

	ifdef ZXNEXT
		opt --zxnext
		device	zxspectrumnext
	else
		device	ZXSPECTRUM48
	endif

; TODO: The book optimises the ball speed in chapter 10 to allow 3 bits for the
; speed and modifies the speed from 1-3 to 2-4. This was still too fast so I have
; changed it to 3-5 since we can now fit speeds from 1 to 7 into 3 bits.
;
; The issue now is that the ball noticably slows down when it passes over the
; score because we are back to reprinting the score every frame so we back to our
; original speed before we needed to slow things down.
;
; After optimising the print and reprint score routines the slowdown is not worth
; worrying about, but it is technically still there! A problem for a rainiy day.

; FIXME: I don't think the speeds are correct on paddle collision. In particular
; 	 the zone 5 collision seems like it's the spped of zone 3 but should be
;	 the same speed as zone 1

; FIXME: Sound effects are kind of sucky. Not that they're crap, but that they
; cause huge slowdown while they play. Maybe we can do something about this, or
; maybe it doesn't do it on real hardware? Need to check.

	ORG	$5E88
; start is used by the compiler to create the SNA so has to be first
codeStart:
	; Setup

	; We need to explicitly enable interrupts for SNA since the snapshot
	; loader code disables interrupts so we are working from a known clean
	; slate but it's not a bad idea for TAP too...
	EI

	ifdef	ZXNEXT
		; Load pallette
		LD	HL, palette
		LD	B, palette_count
		LD	C, PALETTE_1ST_SPRITE	;00100000
		CALL	spriteLib.LoadPalette
		; Setup sprites
		LD	HL, spriteStart
		LD	BC, 16 * 16 * sprite_count
		LD	A, 0
		CALL	spriteLib.LoadSpritesDMA
		; Enablesprites
		CALL	spriteLib.EnableSprites
		; Draw border
		CALL	DrawNextBorder
		; Set CPU speed to 3.5Mhz
		NEXTREG 7, 0
	endif

	; Set the border to red
	LD	A, $00
	OUT	($FE), A

newGame:
	; Set an initial ball rotation of 0
	LD	A, $00
	LD	(ballRotation), A
	; Initial screen draw
	CALL	Cls
	CALL	PrintLine
	CALL	PrintBorder
	ifndef ZXNEXT
		CALL	PrintScores
	else
		CALL	PrintScoresNext
	endif

	; Before main loop, wait for the someone to press 5 to start
	CALL	WaitStart
	; Reset scores from any previous game
	;
	; Clear A
	XOR	A
	; Set both scores to 0
	LD	(p1Score), A
	LD	(p2Score), A
	ifndef ZXNEXT
		; Print new score
		CALL	PrintScores
	else
		CALL	PrintScoresNext
	endif
	; Reset ball speed
	;
	; Load current ball setting
	LD	A, (ballSetting)
	; And clear bits 5 & 4 (ball speed)
	AND	$CF
	; Set bits 5 & 6 to 03
	OR	$30
	; And save the setting
	LD	(ballSetting), A

	; Reset ball position
	LD	HL, BALL_POS_INI
	LD	(ballPos), HL
	; And paddle positions
	LD	HL, PADDLE1POS_INI
	LD	(paddle1pos), HL
	LD	HL, PADDLE2POS_INI
	LD	(paddle2pos), HL

	LD	A, SND_BORDER
	CALL	PlaySound

Loop:
	CALL	MoveBall

	; Read player input and move paddles
	CALL	ScanKeys
	CALL	MovePaddles

	; Check for collisions
	CALL	CheckBallCross

	; Print ball and loop
	CALL 	PrintBall
	CALL	ReprintLine
	ifndef ZXNEXT
		CALL	ReprintScores
	endif

	; Draw paddles
	LD 	HL, (paddle1pos)
	LD	C, PADDLE1
	CALL	PrintPaddle

	LD	HL, (paddle2pos)
	LD	C, PADDLE2
	CALL	PrintPaddle

	; Check for a win
	LD	A, (p1Score)
	CP	$0F
	JP	Z, newGame

	LD	A, (p2Score)
	CP 	$0f
	JP	Z, newGame

	JP	Loop

	; End main game loop

	; VARs
countLoopBall:		DB	$00
countLoopPaddles:	DB	$00
p1Score:		DB	$00
p2Score:		DB	$00


	INCLUDE 	"video.asm"
	INCLUDE 	"controls.asm"
	INCLUDE 	"sprite.asm"
	INCLUDE 	"game.asm"
	INCLUDE 	"sound.asm"
	ifdef ZXNEXT
		INCLUDE		"../common/spritelib.asm"
	endif

codeLen	= $-codeStart

	ifdef ZXNEXT
		SAVENEX OPEN "build/pong.nex", codeStart
		SAVENEX CORE 2,0,0
		SAVENEX CFG 0
		SAVENEX AUTO
		SAVENEX CLOSE
	else
		; Snapshot for ZSim
		SAVESNA 	"build/pong.sna", codeStart
		; Tap file using loader from sjasmplus example lib
		INCLUDE 	"loader.asm"
	endif
