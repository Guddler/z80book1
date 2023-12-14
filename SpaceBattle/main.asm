	SLDOPT COMMENT WPMEM, LOGPOINT, ASSERTION

	;; Comment out to build 48K
	; define ZXNEXT

	ifdef ZXNEXT
		opt --zxnext
		device	ZXSPECTRUMNEXT
	else
		device	ZXSPECTRUM48
	endif

	org	$5dad	; Compatible with 16K Spectrum

codeStart:
	ei
	; Load the location of our UDG graphics
	ld	hl, udgsCommon
	; Load that to the start of UDGs
	ld	(UDG),  hl
	; Specify which charater will start with
	ld	a, $90
	; And how many we will print
	ld	b, $f
.loop1:
	; Save A
	push	af
	; ROM routine to print character pointed to by A
	rst	$10
	; Restore A
	pop	af
	; Incrment A
	inc	a
	; Rinse and repeat unti B = 0
	djnz	.loop1

	; newline
	ld	a, 13
	rst	$10

	; Level one
	ld	a, 1
	; 30 levels altogether
	ld	b, $1e
.loop2:
	; Store the level (A) and the number of enemies (B)
	push	af
	push 	bc

	; Load the level gfx into the UDGs
	call	LoadUdgsEnemies
	; Then just print the enemies 1 by 1
	ld	a, $9f
	rst	$10
	ld	a, $a0
	rst	$10
	ld	a, $a1
	rst	$10
	ld	a, $a2
	rst	$10
	DUP 12
		ld	a, $20
		rst 	$10
	EDUP
	; Restore A * B
	pop	bc
	pop	af
	; Move to the next level
	inc	a
	; rinse and repeat
	djnz	.loop2
.wait:
	jr	.wait
	ret

	include "consts.asm"
	include "vars.asm"
	include "graphics.asm"


codeLen	= $-codeStart

	ifdef ZXNEXT
		SAVENEX OPEN "build/sbattle.nex", codeStart
		SAVENEX CORE 2,0,0
		SAVENEX CFG 0
		SAVENEX AUTO
		SAVENEX CLOSE
	else
		; Snapshot for ZSim
		SAVESNA 	"build/sbattle.sna", codeStart
		; Tap file using loader from sjasmplus example lib
		; INCLUDE 	"loader.asm"
	endif
