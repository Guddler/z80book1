	MODULE video

; We need a way to know the border colour because certain routines trash it
; it is stored at that address
BORDERCR:	EQU	$5C48

;------------------------------------------------------------------------------
; CheckBottom
;
;
; Input:
; Output:
; AF, BC and HL changed on exit
;------------------------------------------------------------------------------
@CheckBottom:
	CALL 	checkVerticalLimit
	RET	C
.bottom:
	XOR	A
	RET

;------------------------------------------------------------------------------
; CheckTop
;
;
; Input:
; Output:
; AF, BC and HL changed on exit
;------------------------------------------------------------------------------
@CheckTop:
	CALL checkVerticalLimit
	RET

;------------------------------------------------------------------------------
; checkVerticalLimit
; Evaluates whether the vertical limit has been reached.
;
; Input: A -> Vertical limit (TTRR RSSS)
;	 HL -> Current position (010T TSSS RRRC CCCC)
; Output: Z = Reached
;	  NZ = Not reached
; AF, and BC changed on exit (and obviously the flags)
;------------------------------------------------------------------------------
checkVerticalLimit:
	; Store A (vertical limit) in B for safe keeping
	LD	B, A
	; Get Y-Coordinate (TTRRRSSS) of the current position
	CALL	GetPtrY

	; Now for the actual vertical limit check...
	; Compare to B
	CP	B
	RET

;------------------------------------------------------------------------------
; PrintBorder
; Paints the of the game
;
; Input: None
; Output: None
; AF, B and HL changed on exit
;------------------------------------------------------------------------------
@PrintBorder:
	; Setup
	;
	; 4100 = Third 0, scanline 1, row 0, column 0
	LD	HL, $4100	; 0100 0001 0000 0000
	; 56E0 = Third 2, scanline 6, row 7, column 0
	LD	DE, $56E0	; 0101 0110 1110 0000
	; 20 = 32 columns
	LD	B, $20
	; FILL is a solid square
	LD	A, FILL

.loop:
	LD	(HL), A
	LD	(DE), A
	INC	L
	INC	E
	DJNZ	.loop
	RET


;------------------------------------------------------------------------------
; PrintLine
; Paints the centre line for the game
;
; Input: None
; Output: None
; AF, B and HL changed on exit
;------------------------------------------------------------------------------
@PrintLine:
	; We will loop over all 24 rows of the screen
	LD	B, $18
	; We start at row 0 ($4000), column 16 ($0010)
	LD	HL, $4010

.loop:
	; Print a blank in the first scanline
	LD	(HL), BLANK
	; Advance to the next row
	INC	H
	; Save BC for the next time through the loop (we reuse B as the count)
	PUSH	BC

	; We will now print 6 scanlines
	LD	B, $06
.loop2:
	; This time we print a line
	LD 	(HL), LINE
	; We increment to the next scanline
	INC	H
	; Keep looping until B = 0
	DJNZ	.loop2
	; Restore B before repating this entire loop
	POP	BC

	; Print a blank as the last scanline
	LD	(HL), BLANK
	; Get the next scanline
	CALL	NextScan
	; Rinse and repeat until our outer B is 0 (24 lines)
	DJNZ	.loop

	RET

;------------------------------------------------------------------------------
; ReprintLine
; Repaint the centre line when the ball passes over it. This is not optimal and
; will be improved later.
;
; Input: None
; Output: None
; AF, BC and HL changed on exit
;------------------------------------------------------------------------------

;
;	TODO : Understand this better !!
;
@ReprintLine:
	; Load ball position
	LD	HL, (ballPos)
	; Load just the row and column
	LD	A, L
	; Mask to keep just the row
	AND	$E0
	; Set the column to 16
	OR	$10
	; Store it back to L
	LD	L, A

	; Number of scanlines to be printed
	LD	B, $06
.loop:
	LD	A, H
	AND	$07
	CP	$01
	JR	C, .loopCont
	CP	$07
	JR	Z, .loopCont

	LD	A, (HL)
	OR	LINE
	LD	(HL), A
.loopCont:
	CALL	NextScan
	DJNZ	.loop

	RET

;------------------------------------------------------------------------------
; Attribute addressing:
;	Attribute Bits:				Colours:
;	7 - Blink (0 steady, 1 blink)		7 - White
;	6 - Bright (0 normal, 1 bright)		6 - Yellow
;	5 \					5 - Cyan
;	4 - Background Colour (0 to 7)		4 - Green
;	3 /					3 - Magenta
;	2 \					2 - Red
;	1 - Forground Colour (0 to 7)		1 - Blue
;	0 /					0 - Black;
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; ClearBall
; By calling this routine when the ball has reached a border we can know who
; won that point and therefore who 'serves' next, before also rasing the ball
;
; Input: None
; Output: Carry if ball was on the left, No Carry if on right
; AF, B and HL changed on exit
;------------------------------------------------------------------------------
@ClearBall:
	; Load position of ball into HL
	LD	HL, (ballPos)
	; Load row and column specifically into A
	LD	A, L
	; Mask . keep just the column
	AND	$1F
	; And compare it with the centre of the screen
	CP	$10
	; If we have a carry then the ball must be at the left border
	JR	C, .clear
	; If we got here then the ball is on the right border but we need to
	; add 1 to the column since the ball is printed 1 column to the right
	INC	L

.clear:
	; Clear the ball
	LD	B, $06	; six lines
.loop:
	; Erase the ball line
	LD	(HL), $0
	; Get the next scanline
	CALL	NextScan
	; And loop 6 times
	DJNZ	.loop

	;Done
	RET

;------------------------------------------------------------------------------
; CLS
; Clears the screen and sets all attributes to white on black
;
;------------------------------------------------------------------------------
@Cls:
	; LDIR : Repeats 'LD (DE),(HL)', increments DE, HL, and decrements BC
	; until BC = 0. If BC = 0 on entry it will loop and repeat 255 times
	;
	; This is why below we load 0 to HL, then prime DE with 4001 as we're
	; always copying the value at the previous address into the current one
	;
	; This routine is not fast but as long as you don't call it every frame
	; it really doesn't need to be.

	; Clear video memory
	;
	; Load HL with start of screen ram
	LD	HL, $4000
	; Clear that address
	LD	(HL), $00
	; Set DE to next address for use by LDIR
	LD	DE, $4001
	; Set BC to the number of addresses we need to clear ($1800 - 1)
	LD	BC, $17FF
	; Loop until they're all clear
	LDIR

	LD	A, $07	; 0 0 000 111
	; Set attribute memory
	;
	; Following the above HL will contain $57FF and we need one more. We
	; could use LD HL, $5800 but that consumes 3 bytes and takes 10 cycles.
	; If we just INC HL instead it comes down to 2 bytes and 6 cycles.
	INC	HL
	; Set attributes for that byte
	LD 	(HL), A
	; Set DE to the next address for use by LDIR
	INC	DE		; As above use INC instead of LD
	; Set BC to the number of addresses to clear ((24 * 32) - 1 = $2FF)
	LD	BC, $2FF
	; Loop until they're all set
	LDIR

	; Store the border colour
	LD	(BORDERCR),  A

	RET


;------------------------------------------------------------------------------
; Screen addressing:
;    	010T TSSS RRRC CCCC
;	T: Third 	- 0 top, 2 bottom
;	S: Scan Line 	- 0 top, 7 bottom (line in 8x8 block)
;	R: Row		- 0 top, 7 bottom (8x8 blocks, 8 per third, 24 total)
;	C: Column	- 0 left, 31 right (8x8 blocks, 32 total)
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
; GetPtrY
; Get Y position of screen location in TTRRRSSS format
;
; Input: HL -> Screen location (memory address) [H:010T TSSS L:RRRC CCCC]
; Output: A -> Y position (TTRRRSSS)
; AF, and E changed on exit
;------------------------------------------------------------------------------
@GetPtrY:
	; Load most significan byte (3rd and Scanline)
	LD	A, H
	; Keep just the third
	AND	$18
	; Rotate into position
	RLCA
	RLCA
	RLCA
	; And store in E for safe keeping
	LD	E, A

	; Repeat for the scanline
	LD	A, H
	; Keep just the scanline
	AND	$07
	; Add what we have already stored in E to what we now have in A
	OR	E
	; and update our stored value back to E
	LD	E, A

	; Repeat for the row
	LD	A, L
	; Mask off the ROW
	AND	$E0
	; Rotate into place (>>2)
	RRCA
	RRCA
	; Again, add existing E
	OR	E
	; We don't need to store it this time, just return what we have in A
	RET

;------------------------------------------------------------------------------
; GetScoreSprite
; Gets the memory location of the sprite for the given score. We have modified
; this so that it takes the same amount of time regardless of the score by not
; using a loop. Bear in mind that although the score can be up to 99, we haven't
; defined any more score sprites than 16 so after that it will start to print
; rubbish. That just needs the extra sprite references to be added.
;
; Input: A -> Score
; Output: HL -> Address of sprite to draw
; AF and HL changed on exit
;------------------------------------------------------------------------------
@GetScoreSprite:
	; To optimise for a max score of 99 we use the 16bit register HL
	;
	; Store points in HL by putting 0 in the high byte and A in the low
	LD	H, $0
	LD	L, A

	; Each score sprite is 4 bytes from the previous one so we multiply
	; the score by 4 to get the offset to the sprite we want
	ADD	HL, HL	; HL + HL = HL * 2
	ADD	HL, HL	; Do it again and it becomes the original HL * 4

	; Load the address of sprite Zero into BC
	LD	BC, Zero
	; Now we just add BC to HL to get the position of the sprite
	ADD	HL, BC
	RET

;------------------------------------------------------------------------------
; NextScan
; Gets the memory location of the next scanline to the one given
;
; Input: HL -> Current scanline
; Output: HL -> Next scanline
; AF and HL changed on exit
;------------------------------------------------------------------------------
@NextScan:
	INC	H
	LD	A, H
	AND	$07
	RET	NZ

	LD	A, L
	ADD	A, $20
	LD 	L, A
	RET	C

	LD	A, H
	SUB 	$08
	LD	H, A
	RET

;------------------------------------------------------------------------------
; PreviousScan
; Gets the memory location of the previous scanline to the one given
;
; Input: HL -> Current scanline
; Output: HL -> Previous scanline
; AF, BC and HL changed on exit
;------------------------------------------------------------------------------
@PreviousScan:
	; Load current value into A
	LD	A, H
	; Decrement H to decrement the scanline
	DEC	H
	; Keep only the scanline bits
	AND	$07
	; If not at 0 then we have the required return value
	RET	NZ
	; Otherwise calculate the previous line...
	;
	; Load the value of L into A
	LD	A, L
	; Subtract one line
	SUB	$20
	; Put the new value back in L
	LD	L, A
	; If there was a carry, we have our value
	RET	C
	; If we get here then we are on scanline 7 of the previous line
	; and subtracted a third, so we need to add that back again
	;
	; Load the valud or H into A
	LD	A, H
	; Returns the third back to how it was
	ADD	A, $08
	; Put back in H
	LD	H, A
	; Our work here is done
	RET

;------------------------------------------------------------------------------
; PrintBall
; Prints the ball (duh!)
;
; Input:
; Output:
; AF, BC, DE and HL changed on exit
;------------------------------------------------------------------------------
@PrintBall:
	; Ensure clean slate of  B
	LD	B, $00
	; Get ball rotation and store it in C for later use. We go via A because
	; we compare to ZERO to know if rotation is left or right. Rotation just
	; means, which frame of the sprite animation really.
	LD	A, (ballRotation)
	LD	C, A
	; Check rotation by comparing A to zero
	CP	$00
	; If result is positive, we zero A and jump to print right
	LD	A, $00
	JP	P, .right
	; Otherwise we proceed to print left

.left:
	; Store the address of the ball bytes in HL
	LD	HL, ballLeft
	SUB	C
	ADD	A, A
	LD	C, A
	SBC	HL, BC
	JR	.continue

.right:
	LD	HL, ballRight
	ADD	A, C
	ADD	A, A
	LD	C, A
	ADD	HL, BC

.continue:
	EX	DE, HL
	LD	HL, (ballPos)

	LD	(HL), BLANK
	INC	L

	LD	(HL), BLANK
	DEC	L
	CALL	NextScan

	LD	B, $04
.loop:
	LD	A, (DE)
	LD	(HL), A
	INC	DE
	INC	L
	LD	A, (DE)
	LD	(HL), A
	DEC	DE
	DEC	L
	CALL	NextScan
	DJNZ	.loop

	LD	(HL), BLANK
	INC	L
	LD	(HL), BLANK
	RET

;------------------------------------------------------------------------------
; PrintScoresNext:
; Prints the player scores in the top border using ZXNext specific sprites
; This way we don't need to worry about reprinting the scores when the ball
; passes over them and should gain performance.
;
; Sprites 0 & 1: P1 Score. Sprites 2 & 3: P2 Score
;
; Input:
; Output:
; Everything changed on exit
;------------------------------------------------------------------------------
@PrintScoresNext
	OR	A
	LD	A, (p1Score)
	DAA
.digit1:
	AND	$F0
	.4	SRL	A
	LD	H, 126	; X
	LD	L, 2	; Y
	LD	D, 0
	JR	Z, .hideDigit1
	OR	A, SPRITE_VISIBLE
.hideDigit1:
	LD	E, A
	LD	A, 0
	CALL	spriteLib.DrawSprite

.digit2:
	OR	A
	LD	A, (p1Score)
	DAA
	AND	$0F

	LD	H, 134	; X
	LD	L, 2	; Y
	LD	D, 0
	OR	A, SPRITE_VISIBLE
	LD	E, A
	LD	A, 1
	CALL	spriteLib.DrawSprite
; P2 Score
	OR	A
	LD	A, (p2Score)
	DAA
.digit3:
	AND	$F0
	.4	SRL	A
	LD	H, 160	; X
	LD	L, 2	; Y
	LD	D, 0
	JR	Z, .hideDigit3
	OR	A, SPRITE_VISIBLE
.hideDigit3:
	LD	E, A
	LD	A, 2
	CALL	spriteLib.DrawSprite

.digit4:
	OR	A
	LD	A, (p2Score)
	DAA
	AND	$0F

	LD	H, 168	; X
	LD	L, 2	; Y
	LD	D, 0
	OR	A, SPRITE_VISIBLE
	LD	E, A
	LD	A, 3
	CALL	spriteLib.DrawSprite

	RET

;------------------------------------------------------------------------------
; PrintScores:
; Prints the player scores
;
; Input:
; Output:
; AF, BC, DE and HL changed on exit
;------------------------------------------------------------------------------
@PrintScores:
	; Prints P1 score
	CALL	p1print
	; Prints P2 score
	JR	p2print

p1print:
	; Load player 1 score into A
	LD	A, (p1Score)
	; And get the sprite pair we need to print
	CALL	GetScoreSprite

	; After a call to GetScoreSprite, HL contains the address of the first
	; sprite and HL + 1 the address of the second. Z80 is little endian so
	; the addresses are LS, MS. SO for example if the location of the sprite
	; for ONE is $9060 then H = 60, L = 90

	; Load the Least siginificant bit into E
	LD	E, (HL)
	; Increment and add the most significant bit into D
	INC	HL
	LD	D, (HL)
	; Push the result onto the stack to preserve it for the second digit
	PUSH	HL
	; Now we get the screen location to print P1 score into HL
	LD	HL, POINTS_P1
	; And we print the digit
	CALL	PrintScore

	; Now for the second digit of P1 score
	;
	; Retrieve our saved HL
	POP	HL
	; INC to get the address of digit 2 since it points to digit 1
	; (we already did one of the INCs before pushing HL to the stack)
	INC	HL

	; This is a bit of a repeat of above so can probably be optimised
	;
	; Load LSB into E
	LD	E, (HL)
	; Increment and add the most significant bit into D
	INC	HL
	LD	D, (HL)
	; Now we get the screen location to print P1 score into HL
	; Unlike last time we increment to the next position
	LD	HL, POINTS_P1 + 1

	; And we print the digit
	CALL	PrintScore
	RET

p2print:
	; Player 2 score - this is basically a repeat of eveything above

	; Load player 2 score into A
	LD	A, (p2Score)
	; And get the sprite pair we need to print
	CALL	GetScoreSprite

	; Load the Least siginificant bit into E
	LD	E, (HL)
	; Increment and add the most significant bit into D
	INC	HL
	LD	D, (HL)
	; Push the result onto the stack to preserve it for the second digit
	PUSH	HL
	; Now we get the screen location to print P1 score into HL
	LD	HL, POINTS_P2
	; And we print the digit
	CALL	PrintScore

	; Now for the second digit of P1 score
	;
	; Retrieve our saved HL
	POP	HL
	; INC to get the address of digit 2 since it points to digit 1
	INC	HL

	; This is a bit of a repeat of above so can probably be optimised
	;
	; Load LSB into E
	LD	E, (HL)
	; Increment and add the most significant bit into D
	INC	HL
	LD	D, (HL)
	; Now we get the screen location to print P1 score into HL
	; Unlike last time we increment to the next position
	LD	HL, POINTS_P2 + 1

@PrintScore:
	; Each time we get here HL is the location to print the sprite and DE
	; points to the sprite itself

	; Each digit is 16 scan lines
	LD	B, $10
	; Save the sprite address and the print address
.loop:
	; Load the byte we need to paint
	LD	A, (DE)
	; And copy it to the required screen location
	LD	(HL), A
	; Move to the next byte
	INC	DE
	; Get the next scanline into HL
	CALL	NextScan
	; Repeat for all 16 lines (B = 0)
	DJNZ	.loop

	; Restore our saved values in reverse order (important!)
	; And return. For either internally or completely out when we're done
	RET

;------------------------------------------------------------------------------
; ReprintScores:
; Reprints the player scores, ensuring that they aren't erased by the ball
;
; Input:
; Output:
; AF, BC, DE and HL changed on exit
;------------------------------------------------------------------------------
@ReprintScores:
	; Load ball position and test it's Y position for collision with score
	LD	HL, (ballPos)
	; Get the Y position
	CALL	GetPtrY
	; Is the ball within the score area vertically?
	CP	POINTS_Y_B
	; No? No need to reprint so return
	RET	NC

	; Load only the row and column of the balls position
	LD	A, L
	; And keep only the column (the're both 1 column wide)
	AND	$1F
.checkP1L
	; Check the position of the ball against the left edge of P1 score
	CP	POINTS_X1_L
	; If there's a carry then we are to the left of it, don't repaint
	RET	C
	; If the columns equal (zero flag set) we need to reprint P1 score
	JR	Z, p1print
.checkP2R:
	; Since we didn't jump, continue checks, right edge of S2 next
	CP	POINTS_X2_R
	; Same deal, if we're in the score, we need to reprint it
	JR	Z, p2print
	; If we have no carry, we are to the right and can again exit
	RET	NC
.checkP1R:
	; Didn't jump so check right edge of score 1
	CP	POINTS_X1_R
	JR	Z, p1print
	JR	C, p1print
.checkP2L:
	CP	POINTS_X2_L
	RET	C
	JR	NZ, p2print

	; Compoare A to left edge of P2 score and if there's a carry we're
	; in the gap between the two scores so we don't need to reprint
	CP	POINTS_X2_L
	RET	C
	JR	p2print

	ifdef ZXNEXT
;------------------------------------------------------------------------------
; DrawNextBorder:
; For the ZXNext version of the game we draw a border around the
;
; Input:
; Output:
; AF, BC, DE and HL changed on exit
;------------------------------------------------------------------------------
;
; This is mostly just a bunch of sprite draw calls and their setups. The border
; does loop though and that code is probably really inneficient
;
pos		DB	0
@DrawNextBorder:
	; Top Left
	LD	H, 16	; X
	LD	L, 16	; Y
	LD	D, 0
	LD	E, SPRITE_VISIBLE | PATTERN_CORNER
	LD	A, 10
	CALL	spriteLib.DrawSprite
	; Top Right
	LD	H, 32	; X
	LD	L, 16	; Y
	LD	D, SPRITE_MIRROR_X | SPRITE_HIGH_X
	LD	E, SPRITE_VISIBLE | PATTERN_CORNER
	LD	A, 11
	CALL	spriteLib.DrawSprite
	; Bottom Left
	LD	H, 16	; X
	LD	L, 224	; Y
	LD	D, SPRITE_MIRROR_Y
	LD	E, SPRITE_VISIBLE | PATTERN_CORNER
	LD	A, 12
	CALL	spriteLib.DrawSprite
	; Bottom Right
	LD	H, 32	; X
	LD	L, 224	; Y
	LD	D, SPRITE_MIRROR_X | SPRITE_MIRROR_Y | SPRITE_HIGH_X
	LD	E, SPRITE_VISIBLE | PATTERN_CORNER
	LD	A, 13
	CALL	spriteLib.DrawSprite

	LD	B, 12
	LD	A, 32
	LD	(pos), A

	; Left Border
.loopL:
	LD	H, 16		; X
	LD	A, (pos)
	LD	L, A		; Y
	LD	D, SPRITE_MIRROR_X | SPRITE_ROTATE
	LD	E, SPRITE_VISIBLE | PATTERN_BORDER
	LD	A, B
	ADD	13
	CALL	spriteLib.DrawSprite
	LD	A, (pos)
	ADD	16
	LD	(pos), A
	DJNZ	.loopL

	LD	A, 32
	LD	(pos), A
	LD	B, 12
	; Right Border
.loopR:
	LD	H, 32		; X
	LD	A, (pos)
	LD	L, A		; Y
	LD	D, SPRITE_ROTATE | SPRITE_HIGH_X
	LD	E, SPRITE_VISIBLE | PATTERN_BORDER
	LD	A, B
	ADD	25
	CALL	spriteLib.DrawSprite
	LD	A, (pos)
	ADD	16
	LD	(pos), A
	DJNZ	.loopR

	LD	A, 16	; In this case, X
	LD	(pos), A
	LD	B, 16	; Num sprites
	; Top Border
.loopT:
	LD	A, (pos)
	LD	H, A		; X
	LD	L, 16		; Y
	LD	D, 0

	LD	A, B
	SUB	15
	JR	C, .nohbit1

	LD	D, SPRITE_HIGH_X
.nohbit1:
	LD	E, SPRITE_VISIBLE | PATTERN_BORDER
	LD	A, B
	ADD	37
	CALL	spriteLib.DrawSprite
	LD	A, (pos)
	SUB	16
	LD	(pos), A
	DJNZ	.loopT

	LD	A, 16	; In this case, X
	LD	(pos), A
	LD	B, 16	; Num sprites
	; Bottom border
.loopB:
	LD	A, (pos)
	LD	H, A		; X
	LD	L, 224		; Y
	LD	D, SPRITE_MIRROR_Y

	LD	A, B
	SUB	15
	JR	C, .nohbit2

	LD	D, SPRITE_MIRROR_Y | SPRITE_HIGH_X
.nohbit2:
	LD	E, SPRITE_VISIBLE | PATTERN_BORDER
	LD	A, B
	ADD	53
	CALL	spriteLib.DrawSprite
	LD	A, (pos)
	SUB	16
	LD	(pos), A
	DJNZ	.loopB

	RET

	endif

	ENDMODULE
