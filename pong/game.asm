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
	CP	$04
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
	; Load and increment ball loop count
	LD	A, (countLoopBall)
	INC	A
	; Save the loop count
	LD	(countLoopBall), A
	; If we've not reached our delay limit carry on waiting
	CP	$06
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
	; Load current setting
	LD	A, (ballSetting)
	; Set the horizontal bit to left (1)
	OR	$40
	; Store back
	LD	(ballSetting), A
	; Set offset
	LD	A, $FF
	; And store
	LD	(ballRotation), A
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
	; Set offset
	LD	A, $01
	; And store
	LD	(ballRotation), A
	; Load current setting
	LD	A, (ballSetting)
	; Set the horizontal bit to right (0)
	AND	$BF
	; Store back
	LD	(ballSetting), A

.end:
	RET

	ENDMODULE
