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
;       FXM1616S     269        16x16 -> 32 bit signed fixed point multiply
;
;       The above timings are based on the looped macros. If space permits,
;       approximately 64-73 clocks can be saved by using the unrolled macros.
;
;**********************************************************************************************


#DEFINE	_Z	STATUS,Z
MSB	EQU	7


;**********************************************************************************************

;       16x16 Bit Multiplication Macros

SMUL1616L        macro

;       Max Timing:     2+11+6*16+15+2+6*17+16+5 = 249 clks

;       Min Timing:     2+7*6+5+2+6*6+5+4 = 96 clks

;       PM: 55            DM: 9


                MOVLW   0x8
                MOVWF   LOOPCOUNT

LOOPSM1616A
                RRF     BARGB1, F
                BTFSC   _C
                GOTO    ALSM1616NA
                DECFSZ  LOOPCOUNT, F
                GOTO    LOOPSM1616A

                MOVLW   0x7
                MOVWF   LOOPCOUNT

LOOPSM1616B
                RRF     BARGB0, F
                BTFSC   _C
                GOTO    BLSM1616NA
                DECFSZ  LOOPCOUNT, F
                GOTO    LOOPSM1616B

                CLRF    AARGB0
                CLRF    AARGB1
                RETLW   0x00

ALOOPSM1616
                RRF     BARGB1, F
                BTFSS   _C
                GOTO    ALSM1616NA
                MOVF   TEMPB1,W
                ADDWF   AARGB1, F
                MOVF            TEMPB0,W
                BTFSC           _C
                INCFSZ          TEMPB0,W
                ADDWF           AARGB0, F

ALSM1616NA      RLF    SIGN,W
                RRF    AARGB0, F
                RRF    AARGB1, F
                RRF    AARGB2, F
                DECFSZ  LOOPCOUNT, F
                GOTO    ALOOPSM1616

                MOVLW   0x7
                MOVWF   LOOPCOUNT

BLOOPSM1616
                RRF     BARGB0, F
                BTFSS   _C
                GOTO    BLSM1616NA
                MOVF   TEMPB1,W
                ADDWF   AARGB1, F
                MOVF            TEMPB0,W
                BTFSC           _C
                INCFSZ          TEMPB0,W
                ADDWF           AARGB0, F

BLSM1616NA      RLF    SIGN,W
                RRF    AARGB0, F
                RRF    AARGB1, F
                RRF    AARGB2, F
                RRF             AARGB3, F
                DECFSZ  LOOPCOUNT, F
                GOTO    BLOOPSM1616

                RLF    SIGN,W
                RRF    AARGB0, F
                RRF    AARGB1, F
                RRF    AARGB2, F
                RRF    AARGB3, F

                endm

;**********************************************************************************************
        
;       16x16 Bit Signed Fixed Point Multiply 16x16 -> 32

;       Input:  16 bit signed fixed point multiplicand in AARGB0
;                       16 bit signed fixed point multiplier in BARGB0

;       Use:    CALL    FXM1616S

;       Output: 32 bit signed fixed point product in AARGB0

;       Result: AARG  <--  AARG x BARG

;       Max Timing:     9+249+2 = 260 clks                B > 0
;                       18+249+2 = 269 clks               B < 0

;       Min Timing:     9+96 = 105 clks

;       PM: 18+55+1 = 74              DM: 9

FXM1616S	CLRF	AARGB2          ; clear partial product
		CLRF	AARGB3
		CLRF	SIGN
		MOVF	AARGB0,W
		IORWF	AARGB1,W
		BTFSC	_Z
		RETLW	0x00
		
		MOVF	AARGB0,W
		XORWF	BARGB0,W
		MOVWF	TEMPB0
		BTFSC	TEMPB0,MSB
		COMF	SIGN,F

		BTFSS   BARGB0,MSB
                GOTO    M1616SOK

                COMF            BARGB1, F
                COMF            BARGB0, F
                INCF            BARGB1, F
		BTFSC		_Z
		INCF		BARGB0, F

                COMF            AARGB1, F
                COMF            AARGB0, F
                INCF            AARGB1, F
		BTFSC		_Z
		INCF		AARGB0, F

		BTFSC	BARGB0,MSB
		GOTO	M1616SX

M1616SOK	MOVF   AARGB0,W
                MOVWF   TEMPB0
                MOVF   AARGB1,W
                MOVWF   TEMPB1

                SMUL1616L

                RETLW           0x00


M1616SX		CLRF	AARGB2
		CLRF	AARGB3
		RLF	SIGN,W
		RRF	AARGB0,F
		RRF	AARGB1,F
		RRF	AARGB2,F

		RETLW	0x00

;**********************************************************************************************
;**********************************************************************************************

