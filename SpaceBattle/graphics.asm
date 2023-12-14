	module graphics

;------------------------------------------------------------------------------
; LoadUdgsEnemies
; Loads the graphics for the enemies into the level enemies memory region
;
; Input:	A -> Level from 1 to 30
; Output: 	None
;
; A, BC, DE & HL altered on exit
;------------------------------------------------------------------------------
@LoadUdgsEnemies:
	dec	a
	; Load the level number into HL
	ld	h, 0
	ld	l, a
	; Multiply HL by 32 ((((HL * 2) * 4) * 8) * 16) * 32)
	.5	add	hl, hl
	; We now have our offset from level 1 of the set we actually want

	; load the location of level 1 enemies
	ld	de, udgsEnemiesLevel1
	; apply the offset to the level we really want
	add	hl, de
	; load the start of our level enemies store to DE
	ld	de, udgsExtension
	; set the loop to 32 bytes
	ld	bc, $20
	; and copy the data
	ldir

	ret

	endmodule
