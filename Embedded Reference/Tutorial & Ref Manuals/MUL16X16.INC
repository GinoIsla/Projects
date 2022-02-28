;	RCS Header $Id: fxm66.a16 2.3 1996/10/16 14:23:23 F.J.Testa Exp $

;	$Revision: 2.3 $

;       16x16 PIC16 FIXED POINT MULTIPLY ROUTINES
;
;       Input:  fixed point arguments in AARG and BARG
;
;       Output: product AARGxBARG in AARG
;
;       All timings are worst case cycle counts
;
;       It is useful to note that the additional unsigned routines requiring a non-power of two
;       argument can be called in a signed multiply application where it is known that the
;       respective argument is nonnegative, thereby offering some improvement in
;       performance.
;
;         Routine            Clocks     Function
;
;       FXM1616U     256        16x16 -> 32 bit unsigned fixed point multiply
;
;       The above timings are based on the looped macros. If space permits,
;       approximately 64-73 clocks can be saved by using the unrolled macros.
;

;**********************************************************************************************
UMUL1616L	MACRO

;       Max Timing:     2+13+6*15+14+2+7*16+15 = 248 clks

;       Min Timing:     2+7*6+5+1+7*6+5+4 = 101 clks

;       PM: 51            DM: 9

	MOVLW	0x08
	MOVWF	LOOPCOUNT

LOOPUM1616A
	RRF	BARGB1,F
	BTFSC	_C
	GOTO	ALUM1616NAP

	DECFSZ	LOOPCOUNT,F
	GOTO	LOOPUM1616A

	MOVWF	LOOPCOUNT

LOOPUM1616B
	RRF	BARGB0,F
	BTFSC	_C
	GOTO	BLUM1616NAP

	DECFSZ	LOOPCOUNT,F
	GOTO	LOOPUM1616B

	CLRF	AARGB0
	CLRF	AARGB1
	RETLW	0x00

BLUM1616NAP
	BCF	_C
	GOTO	BLUM1616NA

ALUM1616NAP
	BCF	_C
	GOTO	ALUM1616NA

ALOOPUM1616
	RRF	BARGB1,F
	BTFSS	_C
	GOTO	ALUM1616NA

	MOVFW	TEMPB1
	ADDWF	AARGB1,F
	MOVFW	TEMPB0
	BTFSC	_C
	INCFSZ	TEMPB0,W

	ADDWF	AARGB0,F

ALUM1616NA
	RRF	AARGB0,F
	RRF	AARGB1,F
	RRF	AARGB2,F
	DECFSZ  LOOPCOUNT, F
	GOTO	ALOOPUM1616

	MOVLW	0x08
	MOVWF	LOOPCOUNT

BLOOPUM1616
	RRF	BARGB0,F
        BTFSS	_C
	GOTO	BLUM1616NA

	MOVFW   TEMPB1
	ADDWF	AARGB1,F
	MOVFW	TEMPB0
	BTFSC	_C
	INCFSZ	TEMPB0,W

	ADDWF	AARGB0,F

BLUM1616NA
	RRF	AARGB0,F
	RRF	AARGB1,F
	RRF	AARGB2,F
	RRF	AARGB3,F
	DECFSZ  LOOPCOUNT,F
	GOTO	BLOOPUM1616

	ENDM
;**********************************************************************************************


;**********************************************************************************************
;       16x16 Bit Unsigned Fixed Point Multiply 16x16 -> 32

;	Input:	16 bit unsigned fixed point multiplicand in AARGB0
;		16 bit unsigned fixed point multiplier in BARGB0

;       Use:    CALL    FXM1616U

;       Output: 32 bit unsigned fixed point product in AARGB0

;       Result: AARG  <--  AARG x BARG

;       Max Timing:     6+248+2 = 256 clks

;       Min Timing:     6+101 = 107 clks

;       PM: 6+51+1 = 58              DM: 9
MULTIPLY
FXM1616U
	CLRF	AARGB2		; clear partial product
	CLRF	AARGB3
	MOVFW	AARGB0
	MOVWF	TEMPB0
	MOVFW	AARGB1
	MOVWF	TEMPB1

	UMUL1616L

	RETLW	0x00
;**********************************************************************************************

