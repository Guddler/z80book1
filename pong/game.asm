	MODULE game

;------------------------------------------------------------------------------
; Wait
; Waits on VSync. Changing the CP instruction will change the target FPS as
; follows:
;	1 = 50fps, 2 = 25fps, 3 = 17fps
;
; We do not use this wait routine in this game as we want to vary the speed of
; the ball travel but it is here for reference.
;
; Input: None
; Output: None
; AF and HL changed on exit
;------------------------------------------------------------------------------
	IFUSED

@Wait:	LD	HL, pTime	; previous time setting
	LD	A, (23672)	; current timer setting.
        SUB	(HL)		; difference between the two.
	CP	1		; have two frames elapsed yet?
	JR	NC, .wait0	; yes, no more delay.
        JR	Wait
.wait0:	LD	A, (23672)	; current timer.
	LD	(HL),  A	; store this setting.
	RET
pTime:	DB	$00

	ENDIF

;------------------------------------------------------------------------------
; CheckBallCross
; Check for a collision between ball and paddle (both X & Y checks)
;
; NB: 	The whole 'return if there's no collision' and keep going to the end if
; 	there is seems a little backwards to me!?!
;
; Input:
; Output:
; AF, C and HL changed on exit
;------------------------------------------------------------------------------
@CheckBallCross:
	; Get the current ball setting
	LD	A, (ballSetting)
	; And mask just the direction bit (bit 6)
	AND	$40
	; 1 means the ball is travelling left so we need to check paddle 1
	JR	NZ, .left

	; Check against paddle 2 as the ball is travelling right
.right:
	; Load the right collision check value
	LD	C, CROSS_RIGHT
	; Check for X collision
	CALL	CheckCrossX
	; If there is no collision, stop here and exit
	RET	NZ
	; If not, load the paddle position
	LD	HL, (paddle2pos)
	; And check for Y collision
	CALL	CheckCrossY
	; If there is no collision, return
	RET	NZ

	; If we get here, there was a collision
	;
	; Get ball properties
	LD	A, (ballSetting)
	; Set direction to left
	OR	$40
	; And store
	LD	(ballSetting), A
	; Set the ball offset to $FF
	LD	A, CROSS_LEFT_ROT
	LD	(ballRotation), A

	; And we're done
	RET

	; Check against paddle 1 as the ball is travelling left
.left:
	; Load the lft collision check value
	LD	C, CROSS_LEFT
	; Check for X collision
	CALL	CheckCrossX
	; If there is no collision exit
	RET	NZ
	; Otherwise load the paddle position
	LD	HL, (paddle1pos)
	; Check for Y collision
	CALL	CheckCrossY
	; Again, if no collision, exit
	RET	NZ

	; As before, we got here so there was a collision
	;
	; Get ball properties
	LD	A, (ballSetting)
	; Set direction to right (by ignoring bit 6 and storing back to A)
	AND	$BF
	; And store the result
	LD	(ballSetting), A
	; Set the ball offset to $01
	LD	A, CROSS_RIGHT_ROT
	LD	(ballRotation), A

	; And again, we're done
	RET

;------------------------------------------------------------------------------
; CheckCrossX
; Check for a collision on the X axis
;
; Input: C -> Collision column (CROSS_LEFT or CROSS_RIGHT)
; Output: Z -> Collision, NZ -> No collision
; AF changed on exit
;------------------------------------------------------------------------------
@CheckCrossX:
	; Get the Column of the ball
	LD	A, (ballPos)
	AND	$1F
	; Compare to C. Z will be set on exit if there was a collision
	CP	C
	RET

;------------------------------------------------------------------------------
; CheckCrossY
; Check for a collision on the Y axis and adjust the ball speed and direction
; accordingly
;
; Input: HL -> Position of paddle (used by GetPtrY call)
; 	 C -> Collision column (CROSS_LEFT or CROSS_RIGHT)
; Output: Z -> Collision, NZ -> No collision
; AF, BC and HL changed on exit
;------------------------------------------------------------------------------
@CheckCrossY:
	CALL	GetPtrY
	; Skip the first scanline since it's not filled
	INC	A
	; Load into C
	LD	C, A
	; Get Y scanline of the ball
	LD	HL, (ballPos)
	CALL	GetPtrY
	; Store it in B
	LD	B, A
	; We move to the penultimate scanline of the ball
	ADD	A, $04
	; Subtract the Y coordinate of the paddle (in C)
	SUB	C
	; In this case a carry means the ball passed over the top of the paddle
	; so we exit with Z not set (NZ = Collision false)
	RET	C

	; Still here so load Y pos of paddle into A again
	LD	A, C
	; Add $16 to move to the penultimate scanline so we can repeat the check
	ADD	A, $16
	; Store in C
	LD	C, A
	; Pull back the Y pos of the ball (previously stored in B)
	LD	A, B
	; This time we look to the first non blank line from the top of the ball
	INC	A
	; And repeat the same check as before
	SUB	C
	; No carry means the ball passed through the first scanline which is OK
	; (NZ = COllision False)
	RET	NC

	; From here we know there was a collision with the paddle so we now
	; proceed to determine which zone it hit and set the ball properties
	; accordingly

	; We currently have the last non-blank line of the paddle in C, grab it
	LD	A, C
	; Get back to the top of the paddle
	SUB	$15
	; And sore back in C
	LD	C, A
	; B contains the position of the ball
	LD	A, B
	; Position to the bottom of the ball
	ADD	A, $04
	; Store back in B
	LD	B, A

	; We're now ready to work our way down the paddle determining where the
	; ball hit (since we've already established that it did). See PrintPaddle
	; in sprite.asm for a description of the 5 zones.
.zone1:
	; Get the top of the paddle
	LD	A, C
	; First zone is 4 lines, so add 4
	ADD	A, $04
	; Compare to the position of the ball
	CP	B
	; If there was a carry then the ball hit lower than this zone, continue
	JR	C, .zone2
	; Otherwise set ball confiig and jump to the end
	LD	A, (ballSetting)
	; Mask / keep just X direction, bit 6
	AND	$40
	; And we set 00 101 001 - Y dir up (0), speed 5, diagonal tilt
	OR	$29
	; We're done
	JR	.end
.zone2:
	; Get the top of the paddle again
	LD	A, C
	; Zone 2 is lines 5-9, so add 9
	ADD	A, $09
	; Compare to the position of the ball
	CP	B
	; If there was a carry then the ball hit lower than this zone, continue
	JR	C, .zone3
	; Otherwise set ball confiig and jump to the end
	LD	A, (ballSetting)
	; Mask / keep just X direction, bit 6
	AND	$40
	; And we set 00 100 010 - Y dir up (0), speed 4, semi-diagonal tilt
	OR	$22
	; We're done
	JR	.end
.zone3:
	; Get the top of the paddle again
	LD	A, C
	; Zone 3 is lines 10-13, so add 13
	ADD	A, $0D
	; Compare to the position of the ball
	CP	B
	; If there was a carry then the ball hit lower than this zone, continue
	JR	C, .zone4
	; Otherwise set ball confiig and jump to the end
	LD	A, (ballSetting)
	; Mask / keep X & Y direction, bits 7 & 6
	AND	$C0
	; And we set 00 011 111 - speed 3, semi-flat tilt
	OR	$1F
	; We're done
	JR	.end
.zone4:
	; Get the top of the paddle again
	LD	A, C
	; Zone 4 is lines 14-18, so add 18
	ADD	A, $12	; Book has this set to $11 but I disagree - we'll see.
	; Compare to the position of the ball
	CP	B
	; If there was a carry then the ball hit lower than this zone, continue
	JR	C, .zone5
	; Otherwise set ball confiig and jump to the end
	LD	A, (ballSetting)
	; Mask / keep just Y direction, bit 6
	AND	$40
	; And we set 10 100 010 - Y down, speed 4, semi-diagonal tilt
	OR	$92
	; We're done
	JR	.end
.zone5:
	; We don't need any further checks since we didn't collide with any of
	; the other zones, but we know it collided, so set the ball and end
	LD	A, (ballSetting)
	; Mask / keep just Y direction, bit 6
	AND	$40
	; And we set 10 101 001 - Y down, speed 5, diagonal tilt
	OR	$99
	; We're done
	JR	.end
.end:
	; Save the ball setting that was worked out over the zone checks
	LD	(ballSetting), A
	; Clear A, thus setting Z (Z = Collision True)
	XOR	A
	; Reset the ball movement counter to 0
	LD	(ballMoveCount), A
	; Return
	RET


;------------------------------------------------------------------------------
; MovePaddles
; Move the paddles location according to which keys have been pressed.
;
; Input: None
; Output: None
; AF and HL changed on exit
;------------------------------------------------------------------------------
@MovePaddles:
	; TODO: Make generic and pass in the paddle address. That will involve
	;	conditionally reading different input keys though so is that
	; 	a case where it's more efficient to have more code and less logic?

	; Before we do anything, check if our loop counter has expired
	;
	; Load and increment ball loop count
	LD	A, (countLoopPaddles)
	INC	A
	; Save the loop count
	LD	(countLoopPaddles), A
	; If we've not reached our delay limit carry on waiting
	CP	$03
	JR	NZ, .end

	; Finished waiting? Reset delay and proceed to move ball
	LD	A, $00
	LD	(countLoopPaddles), A

.p1_up:
	BIT	$00, D
	JR	Z, .p1_down
	LD	HL, (paddle1pos)
	LD	A, PADDLE_TOP
	CALL	CheckTop
	JR	Z, .p2_up
	CALL	PreviousScan
	LD	(paddle1pos), HL
	JR	.p2_up

.p1_down:
	BIT	$01, D
	JR	Z, .p2_up
	LD	HL, (paddle1pos)
	LD	A, PADDLE_BOTTOM
	CALL	CheckBottom
	JR	Z, .p2_up
	CALL	NextScan
	LD	(paddle1pos), HL

.p2_up:
	BIT	$02, D
	JR	Z, .p2_down
	LD	HL, (paddle2pos)
	LD	A, PADDLE_TOP
	CALL	CheckTop
	JR	Z, .end
	CALL	PreviousScan
	LD	(paddle2pos), HL
	JR	.end

.p2_down:
	BIT	$03, D
	JR	Z, .end
	LD	HL, (paddle2pos)
	LD	A, PADDLE_BOTTOM
	CALL	CheckBottom
	JR	Z, .end
	CALL	NextScan
	LD	(paddle2pos), HL

.end
	RET

;------------------------------------------------------------------------------
; MoveBall
; Rather complex routine that does what it says on the tin! It takes into account
; the change of direction when hitting the borders of the screen.
;
; Input: None
; Output: None
; AF and HL changed on exit
;------------------------------------------------------------------------------
@MoveBall:
	; Before we do anything, check if our loop counter has expired
	;
	; We now get our ball speed (and thus the loop limit from ball setting)
	LD	A, (ballSetting)
	; We rotate bits 5-3 to bits 2-0
	RRCA
	RRCA
	RRCA
	; Keep just the 3 bits we want
	AND	$07
	; And store in B
	LD	B, A

	; Load and increment ball loop count
	LD	A, (countLoopBall)
	INC	A
	; Save the loop count
	LD	(countLoopBall), A
	; If we've not reached our delay limit carry on waiting
	CP	B
	JP	NZ, .end

	; Finished waiting? Reset delay and proceed to move ball
	LD	A, $00
	LD	(countLoopBall), A

	; Load current ball settings
	LD	A, (ballSetting)
	; We only want bit 7 which tells us if the ball is moving up or down
	AND	$80
	; if bit 7 = 1, ball is moving down
	JR	NZ, .down

.up:
	; Get current ball position
	LD	HL, (ballPos)
	; And ball upper limit
	LD	A, BALL_TOP
	; Check if we've reached the top limit
	CALL	CheckTop
	; If we have, we need to change direction
	JR	Z, .upChg
	; Check if we are due to move the ball yet
	CALL	MoveBallY
	; And skip moving the ball if we are not ready to yet
	JR	NZ, .x
	; Otherwise get the scanline at Y - 1
	CALL	PreviousScan
	; Store the new ball position
	LD	(ballPos), HL
	; Deal with horizontal movement
	JR	.x

; Here we have reached the upper vertical direction so we need to flip the vertical direction
.upChg:
	; Get current settings
	LD	A, (ballSetting)
	; Set bit 7 to indicate we now go down
	OR	$80
	; Put the setting back
	LD	(ballSetting), A
	; Get the next scanline down
	CALL	NextScan
	; And store it
	LD	(ballPos), HL
	; We're done with UP, move on to horizontal
	JR	.x

.down:
	LD	HL, (ballPos)
	LD	A, BALL_BOTTOM
	CALL	CheckBottom
	JR	Z, .downChg
	CALL	MoveBallY
	JR	NZ, .x
	CALL	NextScan
	LD	(ballPos), HL
	JR	.x

.downChg:
	; Get current settings value
	LD	A, (ballSetting)
	; And set vertical direction to down (0) by clearing the bit with AND
	AND	$7F
	; Store it again
	LD	(ballSetting),  A
	; Get our new scanline
	CALL	PreviousScan
	; And store the new ball position
	LD	(ballPos), HL

.x:
	; Get current settings and check bit 6
	LD	A, (ballSetting)
	AND	$40
	; If it's 1 then move to the LEFT
	JR	NZ, .left

	; Otherwise continue to move to the right
.right:
	; Load ball offset and see if it is the last
	LD	A, (ballRotation)
	CP	$08
	; If so jump to deal with that
	JR 	Z, .rightLast
	; If not, increment, store and jumpt to the end
	INC	A
	LD	(ballRotation), A
	JR	.end

	; If we were on the last offset but not the right border, we move to the
	; next column, otherwise we need to change direction
.rightLast:
	; Load ball position
	LD	A, (ballPos)
	; Mask just the column
	AND	$1F
	; Check if we need to change direction because we're at the edge
	CP	MARGIN_RIGHT
	; Jump if we do
	JR	Z, .rightChg
	; Otherwise load the current position
	LD	HL, ballPos
	; Increment will move to the next column
	INC	(HL)
	; And set us back to the first offset
	LD	A, $01			; FIXME: Shouldn't this be 0 ?
	LD	(ballRotation), A
	; We're done
	JR	.end

.rightChg:
	; Load p1 score
	LD	HL, p1Score
	; Add one (NB: INC the value at the address pointed to by HL, not HL)
	INC	(HL)
	; And print the new score, clear the ball and set the new direction
	CALL	PrintScores
	CALL	ClearBall
	CALL	SetBallLeft

	; And we're done
	JR	.end

.left:
	; Load offset
	LD	A, (ballRotation)
	; Are we on the last offset?
	CP	$F8
	; We are so we need to change column. Jump to it
	JR	Z, .leftLast
	; We're not on the last offset so just decrement it
	DEC	A
	; Store it
	LD	(ballRotation), A
	; And we're done
	JR	.end

.leftLast:
	; Load ball position
	LD	A, (ballPos)	; We can just load A since this will only load the least significant byte
	; Mask just the column
	AND	$1F
	; Decide if we're at the left edge of the screen
	CP	MARGIN_LEFT
	; If we are, we need to change direction
	JR	Z, .leftChg
	; Otherwise, then the whole position to HL
	LD	HL, ballPos
	; Decrement the value which will move column left by one
	DEC	(HL)
	; Set the new offset to -1
	LD	A, $FF			; FIXME: Shouldn't this be 0?
	; Store it
	LD	(ballRotation), A
	; And we're done
	JR	.end

.leftChg:
	; Load p2 score
	LD	HL, p2Score
	; Add one (NB: INC the value at the address pointed to by HL, not HL)
	INC	(HL)
	; And print the new score
	CALL	PrintScores
	CALL	ClearBall
	CALL	SetBallRight

.end:
	RET

@MoveBallY:
	; Load current ball setting
	LD	A, (ballSetting)
	; Keep just the tilt portion
	AND	$07
	; Store in D
	LD	D, A

	; Increment the ball move coutner
	LD	A, (ballMoveCount)
	INC	A
	LD	(ballMoveCount), A
	; Compare to the tilt value
	CP	D
	; Do nothing and return if we haven't reached the tilt yet
	RET	NZ

	; Zero out the ball move count
	XOR	A
	LD	(ballMoveCount), A
	RET

;------------------------------------------------------------------------------
; SetBallLeft
;
;
; Input: None
; Output: None
; AF and HL changed on exit
;------------------------------------------------------------------------------
@SetBallLeft:
	; Force the ball position to the left
	LD	HL, $4D62
	LD	(ballPos), HL
	; We set the ball offset to the first left offset
	LD	A, $01
	LD	(ballRotation), A
	; We get the ball setting and set the direction to right
	LD	A, (ballSetting)
	; Keep the Y direction
	AND	$80
	; Set X to Right, speed to 4 and diagonal tilt  00 10 1 001
	OR	$29
	; Save setting
	LD	(ballSetting), A
	; Also zero the ball move counter
	XOR	A
	LD	(ballMoveCount), A

	RET

;------------------------------------------------------------------------------
; SetBallRight
;
;
; Input: None
; Output: None
; AF and HL changed on exit
;------------------------------------------------------------------------------
@SetBallRight:
	; Force the ball position to the right
	LD	HL, $4D7E
	LD	(ballPos), HL
	; We set the ball offset to the first right offset
	LD	A, $FF
	LD	(ballRotation), A
	; We get the ball setting and set the direction to left
	LD	A, (ballSetting)
	; Keep Y direction
	AND	$80
	; Set X to left, speed to 5 and diagonal tilt (01 101 001)
	OR	$69
	; Save ball settings
	LD	(ballSetting), A
	; Also zero ball move coutner
	XOR	A
	LD	(ballMoveCount), A

	RET
	ENDMODULE
