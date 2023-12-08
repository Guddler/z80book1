;
; Sound effects. These are standard notes and octaves. The frequency given
; would make the note last for one second (higher the note, the shorter it is
; so the longer the frequency required for one second)
;

; C3 used for score update
SND_SCORE:	EQU	1
C3:		EQU	$0D07
C3_FQ:		EQU	$0082 / $10
; C4 used for paddle hit
SND_PADDLE:	EQU	2
C4:		EQU	$066E
C4_FQ:		EQU	$0105 / $10
; C5 used for border hit
SND_BORDER:	EQU	3
C5:		EQU	$0326
C5_FQ:		EQU	$020B / $10

; Address of beeper routine in ROM
BEEPER:		EQU	$03B5
; Beeper routine requires the following and trashes just about everything!
;
; HL -> Note to play
; DE -> Duration to play for

	MODULE sound
;------------------------------------------------------------------------------
; PlaySound
; Set up a call to the beeper routine and calls it
;
; Input:	A -> Type of sound to play (1:score, 2:paddle or 3:border)
;
; Output: 	None
; Nothing is changed on exit
;------------------------------------------------------------------------------
@PlaySound:
	PUSH	DE
	PUSH	HL
	; Is the sound to be played the score sound?
	CP	1
	JR	Z, .score
	; Is it the paddle?
	CP	2
	JR	Z, .paddle
	; No? must be the border
.border:
	LD	HL, C5
	LD	DE, C5_FQ
	JR 	.beep
.score:
	LD	HL, C3
	LD	DE, C3_FQ
	JR	.beep
.paddle:
	LD	HL, C4
	LD	DE, C4_FQ
.beep:
	PUSH	AF
	PUSH	BC
	PUSH	IX
	CALL	BEEPER
	POP	IX
	POP	BC
	POP	AF
	POP	HL
	POP	DE
	RET

	ENDMODULE
