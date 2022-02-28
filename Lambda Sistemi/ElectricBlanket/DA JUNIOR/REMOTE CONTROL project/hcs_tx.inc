
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;TRASMISSIONE HCS

#DEFINE	TMR_HCS_ON	_TMR1ON

;****************************************************************
	CBLOCK	

FLAGS_HCS

; BUFFER DI TRASMISSIONE HCS
HCS1			;ROLLING CODE
HCS2			;ROLLING CODE
HCS3			;DISCRIMINANTE (LSB)
HCS4			;7:4 CHANNELS, 3:2 OVERFLOW BITS (UNUSED), DISCRIMINANTE (LSB)
HCS5			;SERIAL NUMBER (LSB)
HCS6			;SERIAL NUMBER
HCS7			;SERIAL NUMBER (MSB)
HCS8			;7:4 CHANNELS CODE (S2, S1, S0, S3)
HCS9			;1 REPEAT, 0 LOW BATT

FASE_TX_HCS

CARICA_TIMER_HCS_HI
CARICA_TIMER_HCS_LO

PUNTA_HCS

COUNT_BIT

TEMP_ROTATE

COUNT_PREAMBOLO
	ENDC


;-- ALIAS -------------------------------------------------------------
TMR_HCS	EQU	TMR0

COUNT_HEADER	EQU	COUNT_PREAMBOLO
COUNT_DATA	EQU	COUNT_PREAMBOLO


;----------------------------------------------------------------
;
; CODE COMPOSITION INTO TRASMISSION BUFFER
;
;HCS1	BIT 7÷5		0	RESERVED, FORCED TO ZERO
;HCS1	BIT 4		0÷1	LEFT/RIGHT SIDE
;HCS1	BIT 3÷0		0÷F	SERIAL NUMBER HIGH

;HCS2	BIT 7÷0		00÷FF	SERIAL NUMBER

;HCS3	BIT 7÷0		00÷FF	SERIAL NUMBER

;HCS4	BIT 7÷0		00÷FF	SERIAL NUMBER LOW

;HCS5	BIT 7÷3		00÷0A	LEVEL CODE
;HCS5	BIT 2		0÷1	BEEPER
;HCS5	BIT 1		0-1	LEARN MODE ON/OFF
;HCS5	BIT 0		0	PADDING

;HCS6	BIT 7÷0		00÷FF	CHECKSUM


;MESSGE FOR LEARNING: BIT LEARN =1, SERIAL MUST BE VALID, LEFT/RIGHT, BEEPER ON, THE REST = DON'T CARE
;



; DURATA DI UN TE (TEMPO TIPICO)	400 MICROSECONDI
; DURATA DEL PREAMBOLO			 23 TE ALTERNATI HIGH-LOW-HIGH
; DURATA DEL HEADER			 10 TE LOW (4 MILLISECONDI DI PAUSA)
; DURATA DEL SINGOLO BIT		  3 TE: IL 1° HIGH, IL 3° LOW, IL 2° INVERTITO
;						DETERMINA IL DATO

;****** RE-DEFINE PORTA *****************************************
#DEFINE	PWM_HCS		PORTA,3	;PIN DI TRASMISSIONE HCS


;****** FLAGS_HCS *****************************************
#DEFINE	TRASMISSIONE_HCS	FLAGS_HCS,0	;
#DEFINE	ALTO1_BASSO0		FLAGS_HCS,1	;FLAG DA INVERTIRE CHE DETERMINA TE2

	IFDEF	NO_COMMENT
#DEFINE			FLAGS_HCS,2	;
#DEFINE			FLAGS_HCS,3	;
#DEFINE			FLAGS_HCS,4	;
#DEFINE			FLAGS_HCS,5	;
#DEFINE		FLAGS_HCS,6	;
#DEFINE		FLAGS_HCS,7	;

;****** FLAGS_HCS2 *************************************
;#DEFINE		FLAGS_HCS2,0	;
#DEFINE		FLAGS_HCS2,1	;
	ENDIF

;*******************************************************


;*******************************************************
INIZIO_TX_HCS

;*** CARICARE BUFFER HCS
	RAM1


	CLRF	FASE_TX_HCS
	MOVLW	.23
	MOVWF	COUNT_PREAMBOLO

	LW	HCS1
	WF	PUNTA_HCS

	FW	HCS1
	WF	TEMP_ROTATE

	LW	.8
	WF	COUNT_BIT

	;LW	0BH		;COMPARE MODE, TRIGGER SPECIAL EVENT (CCP1 RESETS TMR1)
	;WF	CCP1CON

	CALL	SET_TMR_XT
	SET	TRASMISSIONE_HCS

ITH_X	RETURN
;*******************************************************


;*******************************************************
FASE_PREAMBOLO
	MOVLW	08H		;1	;TRASMISSIONE PREAMBOLO
	XORWF	PORTA,F		;2

	DECFSZ	COUNT_PREAMBOLO,F
	B	FP_X

	MOVLW	.10
	MOVWF	COUNT_HEADER
	INCF	FASE_TX_HCS,F

FP_X	B	GTH_X
;*******************************************************


;*******************************************************
FASE_HEADER
	NOP			;1
	CANC	PWM_HCS		;2	;TRASMISSIONE HEADER

	DECFSZ	COUNT_HEADER,F
	B	FH_X

	MOVLW	MESSAGE_LENGTH		;48 BITS...
	MOVWF	COUNT_DATA
	INCF	FASE_TX_HCS,F

FH_X	B	GTH_X
;*******************************************************


;*******************************************************
FASE_PWM_HI
	NOP			;1
	SET	PWM_HCS		;2

	CALL	CALCOLA_PIN
	INCF	FASE_TX_HCS,F	;1

FPH_X	B	GTH_X
;*******************************************************


;*******************************************************
FASE_PWM_DATA			;IL PIN ARRIVA ALTO...
	IFSET	ALTO1_BASSO0	;1	;...SE DEVO TRASMETTERE 1... 
	CANC	PWM_HCS		;2	;...LO INVERTO,...
				;...SE DEVO TRASMETTERE 0 LO LASCIO ALTO
	INCF	FASE_TX_HCS,F
	B	GTH_X
;*******************************************************


;*******************************************************
FASE_PWM_LO
	NOP			;1
	CANC	PWM_HCS		;2

	DECF	FASE_TX_HCS,F
	DECF	FASE_TX_HCS,F

	DECFSZ	COUNT_DATA,F
	B	FPL_X

	CANC	TRASMISSIONE_HCS

	CALL	CANC_TMR_TX

FPL_X	B	GTH_X
;*******************************************************


;*******************************************************
CALCOLA_PIN
	CANC	ALTO1_BASSO0
	RRF	TEMP_ROTATE,F
	SKPNC
	SET	ALTO1_BASSO0
	
	DECFSZ	COUNT_BIT,F
	B	CP_X

	INCF	PUNTA_HCS,F
	FW	PUNTA_HCS
	WF	FSR
	FW	INDF
	WF	TEMP_ROTATE

	MOVLW	.8
	MOVWF	COUNT_BIT

CP_X	RETURN
;*******************************************************


;*******************************************************
SET_TMR_TX
	LW	-.200  <----- CAMBIA PRESCALE A *2 PER 400uS
	WF	TMR_HCS

	CANC	_T0IF
	SET	_T0IE

	RETURN
;*******************************************************


;*******************************************************
CANC_TMR_TX

	CANC	_T0IE
	CANC	TRASMISSIONE_HCS

	RETURN
;*******************************************************


;*******************************************************
GESTIONE_TMR_HCS
	LW	HIGH	TAB_FASE_HCS
	WF	PCLATH
	;ORG
	FW	FASE_TX_HCS
	ADDWF	PCL,F

TAB_FASE_HCS
	B	FASE_PREAMBOLO	;0
	B	FASE_HEADER	;1
	B	FASE_PWM_HI	;2
	B	FASE_PWM_DATA	;3
END_TAB_FASE_HCS
	B	FASE_PWM_LO	;4

	IF HIGH(TAB_FASE_HCS) != HIGH(END_TAB_FASE_HCS)
	ERROR "TAB_COMANDO: OVERFLOW del PCL"
	ENDIF

GTH_X	RETURN			;A INTERRUPT
;*******************************************************

