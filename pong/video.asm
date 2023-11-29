	MODULE video

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
	LD	(HL), ZERO
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
	LD	(HL), ZERO
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
	; Load just the line and column
	LD	A, L
	; Mask to keep just the line
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
	JR	C, .loopZero
	CP	$07
	JR	Z, .loopZero
	LD	C, LINE
	JR	.loopCont

.loopZero:
	LD	C, ZERO

.loopCont:
	LD	A, (HL)
	OR	C
	LD	(HL), A
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
; CLS
; Clears the screen and sets all attributes to white on black
;
;------------------------------------------------------------------------------
@Cls:
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

	; Set attribute memory
	;
	; Same as above, load HL with start of attribute ram
	LD	HL, $5800	;     BG  FG
	; Set attributes for that byte
	LD 	(HL), $07	; 0 0 000 111
	; Set DE to the next address for use by LDIR
	LD	DE, $5801
	; Set BC to the number of addresses to clear ((24 * 32) - 1 = $2FF)
	LD	BC, $2FF
	; Loop until they're all set
	LDIR

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

	LD	(HL), ZERO
	INC	L

	LD	(HL), ZERO
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

	LD	(HL), ZERO
	INC	L
	LD	(HL), ZERO
	RET

	ENDMODULE
