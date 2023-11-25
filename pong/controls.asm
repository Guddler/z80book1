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

	ENDMODULE
