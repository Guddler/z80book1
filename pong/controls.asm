;------------------------------------------------------------------------------
; ScanKeys
; Scans the control keys and returns the pressed keys.
;
; Input: None
; Output: D -> Keys pressed. 1 for pressed, 0 for not pressed.
;	Bit 0 -> A
;	Bit 1 -> Z
;	Bit 2 -> 0
;	Bit 3 -> O
; Alters: A, F and D registers
;------------------------------------------------------------------------------
	MODULE input

@ScanKeys:
	; Set key input range for keys 1-5
	LD	A, $F7
	; And read the keyboard port
	IN	A, ($FE)
	; Has key 1 been pressed?
	BIT	$00, A
	; No? skip to check key 2
	JR	NZ, .key_2

.key_1:
	; Load current ball setting
	LD	A, (ballSetting)
	; And clear bits 5 & 4 (ball speed)
	AND	$CF
	; Set bits 5 & 6 to 01
	OR	$10
	; And save the setting
	LD	(ballSetting), A
	; Jump forward to reset the speed
	JR	.speed

.key_2:
	; Has key 1 been pressed?
	BIT	$01, A
	; No? skip to check key 3
	JR	NZ, .key_3
	; Load current ball setting
	LD	A, (ballSetting)
	; And clear bits 5 & 4 (ball speed)
	AND	$CF
	; Set bits 5 & 6 to 01
	OR	$20
	; And save the setting
	LD	(ballSetting), A
	; Jump forward to reset the speed
	JR	.speed

.key_3:
	; Has key 1 been pressed?
	BIT	$02, A
	; No? skip to check key 3
	JR	NZ, .ctrl
	; Load current ball setting
	LD	A, (ballSetting)
	; And clear bits 5 & 4 (ball speed)
	AND	$CF
	; Set bits 5 & 6 to 01
	OR	$30
	; And save the setting
	LD	(ballSetting), A
	; Jump forward to reset the speed
	JR	.speed
.speed:
	; If one of the speed keys has been pressed reset loop counter so we
	; don't wait 254 frames for the ball to move again
	XOR	A
	LD	(countLoopBall), A

.ctrl:
	; Ensure D is cleared
	LD	D, $00

.key_A:
	LD	A, $FD
	IN	A, ($FE)
	BIT 	$00, A
	JR	NZ, .key_Z
	SET	$00, D

.key_Z:
	LD	A, $FE
	IN	A, ($FE)
	BIT 	$01, A
	JR	NZ, .key_0
	SET	$01, D

	; If both A & Z have been pressed behave as though neither has been
	; This is a bit weird, but we'll give it a go...
	;
	; Load our current flags
	LD	A, D
	; Are both keys pressed? (bits 1 & 2 = 3)
	SUB	$03
	; If A = 0 then yes, they were, otherwise skip to the next key pair
	JR	NZ, .key_0
	; Since A now contains 0, use it to zero out D (possible optimisation
	; here by copying the literal 0 instead of register A contents?)
	LD	D, A

.key_0:
	LD	A, $EF
	IN	A, ($FE)
	BIT 	$00, A
	JR	NZ, .key_O
	SET	$02, D

.key_O:
	LD	A, $DF
	IN	A, ($FE)
	BIT 	$01, A
	; If not set then we're done, exit
	RET	NZ
	SET	$03, D

	; As above, check to see if the O and 0 keys have both been pressed and
	; cancel them out accordingly
	LD	A, D
	AND	$0C	; bits 2 & 3 = 12 = 0c
	CP	$0C
	; No? We're done
	RET	NZ
	; Reload A with D
	LD	A, D
	; Get just the first two keys
	AND	$03
	; Restore these to D
	LD	D, A

	RET

;------------------------------------------------------------------------------
; WaitStart
; Waits for the 5 key to be pressed
;
; Input: None
; Output: None
; Alters: A and F registers
;------------------------------------------------------------------------------
@WaitStart:
	; Set half-row for keys 1-5 (F7)
	LD	A, $F7
	; Poll the keyboard
	IN	A, ($FE)
	; Check for bit 4
	BIT	$04, A
	; Not pressed?, loop
	JR	NZ, WaitStart
	; Done
	RET



	ENDMODULE
