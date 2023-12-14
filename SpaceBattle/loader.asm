;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Basic loader from here:
;; https://github.com/Threetwosevensixseven/sj-tapbas/blob/main/sjasmplus/sjasmplus.asm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	include "../common/basiclib.asm"

	ORG $5CCB

Basic
	LINE : db clear:NUM codeStart - 1	: LEND
	LINE : db poke:NUM 23610:db ',':NUM 255 : LEND
	LINE : db poke:NUM 23624:db ',':NUM 0 	: LEND
	LINE : db poke:NUM 23693:db ',':NUM 0 	: LEND
	LINE : db cls				: LEND
	; LINE : db load,'""',screen		: LEND
	; LINE : db poke:NUM 23739:db ',':NUM 111	: LEND
	LINE : db load,'""',code 	     	: LEND
	LINE : db pause:NUM 150			: LEND
	LINE : db rand,usr:NUM codeStart	: LEND
BasEnd

	ORG	$4000
	; Loading screen (we ain't got one yet)
	; INCBIN "PongScr.bin"

 	EMPTYTAP "build/sbattle.tap"
 	SAVETAP  "build/sbattle.tap", BASIC, "SpaceBattle",	Basic, BasEnd-Basic, 10
 	; SAVETAP  "build/sbattle.tap", CODE,  "BattleScr",	$4000, $1AFF
 	SAVETAP  "build/sbattle.tap", CODE,  "battle", 		codeStart, codeLen
