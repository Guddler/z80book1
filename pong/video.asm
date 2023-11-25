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
!checkBottom_bottom:
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
;
;
; Input: A -> Vertical limit (TTLL LSSS)
;	 HL -> Current position (010T TSSS LLLC CCCC)
; Output: Z = Reached
;	  NZ = Not reached
; AF, and BC changed on exit (and obviously the flags)
;------------------------------------------------------------------------------
!checkVerticalLimit:
	; Store A (vertical limit) in B for safe keeping
	LD	B, A
	; Load 1st byte of HL (010TTSSS) in A
	LD	A, H
	; Keep only the third (TT)
	AND	$18
	; Rotate A to the left 3 times so TT is now in bits 6 & 7
	; This matches out limit value stored in A
	RLCA
	RLCA
	RLCA
	; Keep the value so far in C
	LD	C, A

	; Now repeat for the scan line portion of H (bits 0-2)
	; Reload H into A
	LD	A, H
	; Keep the first 3 bits
	AND	$07
	; Add the scanline portion from C
	OR	C
	; And store back in C so now C contains TTxxxSSS
	LD	C, A

	; Now repeat for the line portion of L (bits 5-7)
	LD	A, L
	; Keep the left 3 bits
	AND	$E0
	; Shift right twice so LLL is in bits 5 to 3
	RRCA
	RRCA
	; Merge this portion with C
	OR	C

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
	; 4100 = Third 0, line 0, scanline 1, column 0
	LD	HL, $4100	; 0100 0001 0000 0000
	; 56E0 = Third 2, line 7, scanline 6, column 0
	LD	DE, $56E0	; 0101 0110 1110 0000
	; 20 = 32 columns
	LD	B, $20
	; FILL is a solid square
	LD	A, FILL

!printBorder_loop:
	LD	(HL), A
	LD	(DE), A
	INC	L
	INC	E
	DJNZ	printBorder_loop
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
	; We will loop over all 24 lines of the screen
	LD	B, $18
	; We start at line 0 ($4000), column 16 ($0010)
	LD	HL, $4010

!printLine_loop:
	; Print a blank in the first scanline
	LD	(HL), ZERO
	; Advance to the next line
	INC	H
	; Save BC for the next time through the loop (we reuse B as the count)
	PUSH	BC

	; We will now print 6 scanlines
	LD	B, $06
!printLine_loop2:
	; This time we print a line
	LD 	(HL), LINE
	; We increment to the next scanline
	INC	H
	; Keep looping until B = 0
	DJNZ	printLine_loop2
	; Restore B before repating this entire loop
	POP	BC

	; Print a blank as the last scanline
	LD	(HL), ZERO
	; Get the next scanline
	CALL	NextScan
	; Rinse and repeat until our outer B is 0 (24 lines)
	DJNZ	printLine_loop

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
;    	010T TSSS LLLC CCCC
;	T: Third 	- 0 top, 2 bottom
;	S: Scan Line 	- 0 top, 7 bottom (line in 8x8 block)
;	L: Line		- 0 top, 7 bottom (8x8 blocks, 8 per third, 24 total)
;	C: Column	- 0 left, 31 right (8x8 blocks, 32 total)
;------------------------------------------------------------------------------


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
	JP	P, printBall_right
	; Otherwise we proceed to print left

!printBall_left:
	; Store the address of the ball bytes in HL
	LD	HL, ballLeft
	SUB	C
	ADD	A, A
	LD	C, A
	SBC	HL, BC
	JR	printBall_continue

!printBall_right:
	LD	HL, ballRight
	ADD	A, C
	ADD	A, A
	LD	C, A
	ADD	HL, BC

!printBall_continue:
	EX	DE, HL
	LD	HL, (ballPos)

	LD	(HL), ZERO
	INC	L

	LD	(HL), ZERO
	DEC	L
	CALL	NextScan

	LD	B, $04
!printBall_loop:
	LD	A, (DE)
	LD	(HL), A
	INC	DE
	INC	L
	LD	A, (DE)
	LD	(HL), A
	DEC	DE
	DEC	L
	CALL	NextScan
	DJNZ	printBall_loop

	LD	(HL), ZERO
	INC	L
	LD	(HL), ZERO
	RET

	ENDMODULE
