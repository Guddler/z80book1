
; Constants

REG_SPRITE_NUMBER	equ	$34
REG_SPRITE_ATTRIBUTE0	equ	$35	; LS 8 Bits of X Pos
REG_SPRITE_ATTRIBUTE1	equ	$36	; LS 8 Bits of Y Pos
REG_SPRITE_ATTRIBUTE2	equ	$37
REG_SPRITE_ATTRIBUTE3	equ	$38
REG_SPRITE_ATTRIBUTE4	equ	$39

; Attribute 2
SPRITE_MIRROR_X		equ	%00001000
SPRITE_MIRROR_Y		equ	%00000100
SPRITE_ROTATE		equ	%00000010
SPRITE_HIGH_X		equ	%00000001
; Attribute 3
SPRITE_VISIBLE		equ	%10000000
SPRITE_ATTR4_ENABLE	equ	%01000000
; ATTRIBUTE 4 - Type
SPRITE_8BIT		equ	%00000000
SPRITE_ANCHOR_4BITL	equ	%10000000	; 4Bit anchor, patterns 0-127
SPRITE_ANCHOR_4BITH	equ	%11000000	; 4Bit anchor, patterns 128-255
SPRITE_RELATIVE		equ	$01000000
SPRITE_UNIFIED		equ	%00100000	; If anchors relatives are unified (unset for composite)
; Attribute 4 - X Scale
SPRITE_XSCALE_1X	equ	%00000000
SPRITE_XSCALE_2X	equ	%00001000
SPRITE_XSCALE_4X	equ	%00010000
SPRITE_XSCALE_8X	equ	%00011000
; Attribute 4 - Y Scale
SPRITE_YSCALE_1X	equ	%00000000
SPRITE_YSCALE_2X	equ	%00000010
SPRITE_YSCALE_4X	equ	%00000100
SPRITE_YSCALE_8X	equ	%00000110
; Attribute 4 - Misc
SPRITE_PATTERN_REL	equ	$00000001
SPRITE_HIGH_Y		equ	$00000001

REG_PALETTE_INDEX	equ	$40
REG_PALETTE_COLOUR	equ	$41
REG_PALETTE_CONTROL	equ	$43

PALETTE_1ST_ULA		equ	$00000000
PALETTE_2ND_ULA		equ	$01000000
PALETTE_1ST_LAY2	equ	$00010000
PALETTE_2ND_LAY2	equ	$01010000
PALETTE_1ST_SPRITE	equ	%00100000
PALETTE_2ND_SPRITE	equ	%01100000
PALETTE_1ST_TILE1	equ	%00110000
PALETTE_2ND_TILE2	equ	%01110000

	module spriteLib

;------------------------------------------------------------------------------
; EnableSprites
; Load sprite data into FPGA memory using DMA
;
; Input: 	None
; Output:	None
; Alters: 	??
;------------------------------------------------------------------------------
EnableSprites:
	NEXTREG	$15, %01000011	; Sprite 0 on top, SLU, sprites visible
	RET

;------------------------------------------------------------------------------
; DrawSprite
; Load sprite data into FPGA memory using DMA
;
; Input:	A  -> Sprite number
;		H  -> X position LS8B
;		L  -> Y position LS8B
;		D  -> Attribute 2 data
;		E  -> Attribute 3 data
;		C  -> Attribute 4 data
;
; Output:	None
; Alters: 	A is trashed on exit
;------------------------------------------------------------------------------
DrawSprite:
	NEXTREG	REG_SPRITE_NUMBER, A
	LD	A, H
	NEXTREG	REG_SPRITE_ATTRIBUTE0, A
	LD	A, L
	NEXTREG REG_SPRITE_ATTRIBUTE1, A
	LD	A, D
	NEXTREG	REG_SPRITE_ATTRIBUTE2, A	; Palette offset, no mirror, no rotation
	LD	A, E
	NEXTREG REG_SPRITE_ATTRIBUTE3, A	; Visible, byte 4, pattern number 111111
	LD	A, C
	CP	$40
	RET	Z
	NEXTREG	REG_SPRITE_ATTRIBUTE4, A
	RET

;------------------------------------------------------------------------------
; LoadSprites
; Load sprite data into FPGA memory without using DMA
;
; Input: 	HL -> Source address of sprite data
;		D  -> Number of sprites to copy
;		A  -> Starting sprite number to copy
; Output:	None
; Alters: 	AF, BC & HL
;------------------------------------------------------------------------------
LoadSprites:
	LD	A, 0
	LD	BC, $303B
	OUT	(C), A

	LD	A, D
.loop:
	LD	C, $5B
	LD	B, 0
	OTIR

	DEC	A
	RET	Z
	JR .loop

;------------------------------------------------------------------------------
; LoadPalette
; Load palette data into FPGA memory
;
; Input: 	HL -> Source address of palette data
;		B  -> Number of colours in palette
;		C  -> Control register data
;		Bit 7 = Autoincrement (1) or not (0)
;		Bits 6-4 = Palette to load
;		Bits 3-1 = Set active palettes
;		Bit 0 = Set ULANext mode
; Output:	None
; Alters: 	AF, BC & HL
;------------------------------------------------------------------------------
LoadPalette:
	LD	A, C
	NEXTREG	REG_PALETTE_CONTROL, A
	NEXTREG	REG_PALETTE_INDEX, 0		; Start at index 0
.loop:
	LD	A, (HL)
	INC	(HL)
	NEXTREG	REG_PALETTE_COLOUR, A
	DJNZ	.loop
	RET

;------------------------------------------------------------------------------
; LoadSprites
; Load sprite data into FPGA memory using DMA
;
; Input: 	HL -> Source address of sprite data
;		BC -> Number of sprites to copy
;		A  -> Starting sprite number to copy
; Output:	None
; Alters: 	??
;------------------------------------------------------------------------------
LoadSpritesDMA:
	LD	BC, $303B
	OUT	(C), A
	LD	(.dmaSource), HL
	LD	(.dmaLength), BC
	LD	HL, .dmaProgram
	LD	B, .dmaProgramLength
	LD	C, $6B
	OTIR
	RET

.dmaProgram:
	DB	%10000011
	DB	%01111101
.dmaSource:
	DW	0
.dmaLength:
	DW	0
	DB	%00010100
	DB	%00101000
	DB	%10101101
	DW	$005B
	DB	%10000010
	DB	%11001111
	DB	%10000111

.dmaProgramLength = $-.dmaProgram

	endmodule
