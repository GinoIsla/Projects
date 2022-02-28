;REL 1.51 limitazione delta I '7F' E 'E0'
			list	p=12f675
			;list	p=16f676

;-----------------------------------------------
; DEFINIZIONI DEGLI I/O
;	 	 ______  ______
;		-| 1 VDD\/VSS 8 |-
; LED		-| 2 GP5  GP0 7 |- TASTO
; GATE_HEAT	-| 3 GP4  GP1 6 |- ZCV_RETE
; NC		-| 4 GP3  GP2 5 |- NTC
;		 +--------------+
;-----------------------------------------------
;UPDATES:
;gi:		11-01-06	New LED behavior: blink LED during the new TEMPO_Z, when TEMPO_Y is reached turn off the LED.
;


#DEFINE PIC12F675
;#DEFINE PIC16F676
#DEFINE FREERUN
;#DEFINE FIXED


	IFDEF		PIC12F675
	INCLUDE		<p12f675.inc>
	__CONFIG	_CPD_ON & _CP_ON & _BODEN_ON & _MCLRE_OFF & _PWRTE_ON & _WDT_ON & _INTRC_OSC_NOCLKOUT
	__IDLOCS	0133	;1.3.3
	ENDIF


	IFDEF		PIC16F676
	INCLUDE		<p16f676.inc>
	__CONFIG	_CPD & _CP & _BODEN & _MCLRE_OFF & _PWRTE_ON & _WDT_ON & _INTRC_OSC_NOCLKOUT
	__IDLOCS	0133	;1.3.3
	ENDIF


	INCLUDE		<EQUIVALENZE.INC>
;;;;	INCLUDE		<UTENZA.INC>		;****11-01-06 THIS INCLUDE FILE OBSOLETE
	INCLUDE		<UTENZA_PP.INC>		;****11-01-06 THIS INCLUDE FILE DEFINED BY THE CUSTOMER
	INCLUDE		<Macros.inc>
	

	ERRORLEVEL -302

#DEFINE	SKPB	SKPNC
#DEFINE	SKPNB	SKPC



#define Fosc 			.4000000	;(4MHz)
#define Millisec 		.1000


MASK_T1CON				EQU	30H		;TMR1: prescale 1:8, OFF
#define T1_PreScale 	.8
#define Timer1tick_ms	0 - ((Fosc)/(4*T1_PreScale*Millisec))

#define T0_PreScale 	.16
#define Timer0tick_ms	0 - ((Fosc)/(4*T0_PreScale*Millisec))

#define	NUMBER_OF_CYCLES	.255			;256 periods of 6ms per heat cycle
#define	PERIOD_SIZE			.8				;.6

;Constatnts for PID calculation
;================================
Kp	EQU	H'190'
Ki	EQU	H'0D'
Kd	EQU	H'C00'

MAX_DIF_PREC	EQU			.100	;.144
MAX_DIF_NEG	EQU			.100	;.144
MAX_DIF_POS	EQU			.50
PRECARICA_PID	EQU			H'600'	;H'300'

;****** MICRO MACRO *******************************************
#DEFINE	RAM0	BCF	STATUS,RP0
#DEFINE	RAM1	BSF	STATUS,RP0


	IFDEF		PIC16F676
GPIO	EQU	PORTA
TRISIO	EQU	TRISA
	ENDIF

;****** GPIO *****************************************
#DEFINE	TASTO		GPIO,0	;IN  - TASTO
#DEFINE	ZCV_RETE	GPIO,1	;IN  - COMPARATOR - IN DELLO ZC DI V
#DEFINE	NTC		GPIO,2	;IN  - AD CONVERTER - RILEVAZIONE TEMPERATURA
#DEFINE	GATE_HEAT	GPIO,4	;OUT - TRIAC RESISTENZA TEMPERATURA
#DEFINE	LED		GPIO,5	;OUT - LED

;******* STATUS *************************************************
#DEFINE	_C		STATUS,C	;0) CARRY

;******* INTCON *************************************************
#DEFINE	_T0IF		INTCON,T0IF	;2) TMR0 INTERRUPT FLAG
#DEFINE	_T0IE		INTCON,T0IE	;5) TMR0 INTERRUPT ENABLE
#DEFINE	_INTF		INTCON,INTF	;1) RB0 INTERRUPT FLAG
#DEFINE	_GPIF		INTCON,GPIF	;0) CHANGE PORTB0 INTERRUPT FLAG
#DEFINE	_PEIE		INTCON,PEIE	;6) PERIPHERAL INTERRUPT ENABLE
#DEFINE	_GIE		INTCON,GIE	;7) GLOBAL INTERRUPT ENABLE

;******* PIR1 *************************************************
#DEFINE	BASE_TEMPI	PIR1,TMR1IF	;1) TMR1 INTERRUPT FLAG
#DEFINE	_CMIF		PIR1,CMIF	;3) COMPARATOR INTERRUPT FLAG

;******* PIE1 *************************************************
#DEFINE	_TMR1IE		PIE1,TMR1IE	;1) TMR1 INTERRUPT ENABLE	;NOT USED
#DEFINE	_CMIE		PIE1,CMIE	;3) COMPARATOR INTERRUPT ENABLE

;******* ADCON0 *************************************************
#DEFINE	GO_DONE		ADCON0,1	;1)	1 = CONVERSION IN PROGRESS
					;	0 = CONVERSION DONE
;******* T1CON *************************************************
#DEFINE	_TMR1ON		T1CON,TMR1ON	;1) TMR1 ON

;******* CMCON *************************************************
#DEFINE	_COUT		CMCON,COUT	;6) COMPARATOR OUTPUT BIT

;***** FLAGS ***************************************************
#define	PERIOD_TICK		FLAGS,0
#define	HALF_SECONDS_TICK	FLAGS,1
#define	SECONDS_TICK		FLAGS,2
#define	MINUTES_TICK		FLAGS,3
#DEFINE	NO_COMP_INT		FLAGS,4
#DEFINE	CYCLE_OVER		FLAGS,5
;***** FLAGS2 ********************************
#DEFINE	PHASE_PR		FLAGS2,0
#DEFINE	PHASE_1			FLAGS2,1
#DEFINE	PHASE_2			FLAGS2,2
#DEFINE	PHASE_3			FLAGS2,3
#DEFINE	PHASE_4			FLAGS2,4
#DEFINE	TEMPO_Z_ON		FLAGS2,5	;new requirement
#DEFINE	CYCLE_ENDED		FLAGS2,6
#DEFINE	EQUAL			DIFF_HI,6
#DEFINE	NEGATIVE		DIFF_HI,7
;*********************************************
;***** FLAGS_SEBA ********************************
#DEFINE	FORZA_MAX				FLAGS_SEBA,0
;#DEFINE	PHASE_1				FLAGS_SEBA,1
;#DEFINE	PHASE_2				FLAGS_SEBA,2
;#DEFINE	PHASE_3				FLAGS_SEBA,3
;#DEFINE	PHASE_4				FLAGS_SEBA,4
;#DEFINE	CYCLE_ENDED			FLAGS_SEBA,5


B_WREG	EQU	05FH

		CBLOCK	020H
;GLOBALI
FLAGS						;
FLAGS2						;
STAY_ON_PERIOD					;number of cycles to stay on
CYCLE_CNTR					;
PERIOD_COUNT					;6MS
HLF_SECONDS_L0					;
HLF_SECONDS_HI					;
SECONDS						;
MINUTE						;
PHASE_PR_TIMER					;
PHASE_1_TIMER_HI				;
PHASE_1_TIMER_LO				;
PHASE_2_TIMER					;
PHASE_3_TIMER					;
COUNT_TASTO_PREMUTO				;
MASTER_SHUTDOWN					;counter for timer_y
TIMER_Z_H					;****11-01-06
TIMER_Z_L					;
TM_HI						;MeasuredTemperature HIgh
TM_LO						;
TT_HI						;TargetTemperature HIgh
TT_LO						;
PT_HI						;Previous Temperature HIgh
PT_LO						;
SIGMA_HI					;Accumulated for I calculation HIgh
SIGMA_LO					;
DIFF_HI						;TT_HI - TM_HI
DIFF_LO						;TT_LO - TM_LO
T_SUM0						;Resulting sum of the PID
T_SUM1						;
T_SUM2						;
T_SUM3						;
DIFF_DEB_HI					;
DIFF_DEB_LO					;
LINE_DEBOUNCE					;
DEBUG						;
B_STATUS					;
B_FSR						;
AARGB0						;Variables for signed 16X16
AARGB1						;"
AARGB2						;"
AARGB3						;"
TEMPB0						;"
TEMPB1						;"
BARGB0						;"
BARGB1						;"
LOOPCOUNT					;"
SIGN						;"
B_PCLATH					;
FLAGS_SEBA					;
	ENDC					;
;************************************************
FINE_RAM		EQU	B_PCLATH

	IF	FINE_RAM > 05EH
	ERROR	'**FINE RAM: NON DISPONIBILE**'
	ENDIF

;******* COSTANTI DI PROGRAMMA **********************
MASK_TRISIO		EQU	0FH			;GP0/1/2/3 IN INGRESSO, GP4/5 IN USCITA
MASK_VRCON		EQU	088H			;VREF ENABLED, HIGH RANGE, VALUE 8
MASK_VRCON_INIT		EQU	080H			;VREF ENABLED, HIGH RANGE, VALUE DON'T CARE
MASK_VRCON_UP_TO_DOWN	EQU	08FH			;VREF ENABLED, HIGH RANGE, VALUE 15
MASK_VRCON_DOWN_TO_UP	EQU	080H			;VREF ENABLED, HIGH RANGE, VALUE 0
MASK_ANSEL		EQU	014H			;FOSC/32, AN2 --> FOSC/8
MASK_ADCON		EQU	89H			;RIGHT JUSTIFIED,CHAN2,ON
MASK_CMCON		EQU 	04H			;CM0÷CM2 = 100 (GP0:D, GP1:A) = NO OUTPUT, INTERNAL REF
MASK_CMCON_OFF		EQU 	07H			;CM0÷CM2 = 111 comparator off
MASK_OPTION_WDT		EQU	b'10001111'		;PULL-UPS DISABILITATI,PS=WDT,1:128
MASK_OPTION_TMR0	EQU	b'10000011'		;PULL-UPS DISABILITATI,PS=TIMER0,1:16
;****************************************************************

;******* ORIGINE **********************************************
	ORG	0x00
		GOTO	START
;****************************************************************

	ORG	0x04
;	GOTO	SERVICE_INTERRUPT
SERVICE_INTERRUPT					;
		MOVWF	B_WREG				;
		SWAPF	STATUS,W			;
		RAM0					;
		MOVWF	B_STATUS			;
		MOVFW	PCLATH				;
		MOVWF	B_PCLATH			;
		MOVFW	FSR				;
		MOVWF	B_FSR				;
							;
		CLRWDT					;
		RAM1					;
		BTFSS	_CMIE				; ZC?
		GOTO	_TMR0_INT			;
							;
		RAM0					;
		BTFSS	_CMIF				;check interrupt type
		GOTO	_TMR0_INT			;
		;GOTO	_ZERO_CROSS_V			;ZC interrrupt
							;
;=======================================================;
							;
  ;ZCV - COMPARATOR INTERRUPT				;
_ZERO_CROSS_V						;
		MOVF	STAY_ON_PERIOD,F		;if STAY_ON_PERIOD <> 0
		BTFSS	STATUS,Z			;
		BSF	GATE_HEAT			; turn-on the heat, start T0 for 1ms

		CALL	COMPARATOR_OFF			;avoid false interrupts from the comparator (2 ZC/cycle)
		BSF	NO_COMP_INT			;disable these ints for 6ms (line voltage debounce)
		MOVLW	.6				;
		MOVWF	LINE_DEBOUNCE			;
							;
		MOVF	STAY_ON_PERIOD,F		;if STAY_ON_PERIOD <> 0
		BTFSC	STATUS,Z			;
		GOTO	_EXIT_INTERRUPT			;
							;
		;BSF	GATE_HEAT			; turn-on the heat, start T0 for 1ms
		RAM1					;
		BCF	_CMIE				;don't move this
		RAM0					;
		GOTO	_RESET_TMR0			;
;=======================================================;
_TMR0_INT						;
		RAM0					;
		BTFSC	_T0IF				;
		GOTO	_SERV_TMR0			;1ms TMR0 interrupt
		GOTO	_EXIT_INTERRUPT			;FALSE INTERRUPT
							;
_SERV_TMR0						;service timer 0 interrupt
		BCF	GATE_HEAT			;turn-off the heat
		BTFSS	NO_COMP_INT			;did we clear comp ints?
		GOTO	_RESET_TMR0			;
		DECFSZ	LINE_DEBOUNCE,F			;
		GOTO	_RESET_TMR0			;
		CALL	COMPARATOR_ON			;re-enable interrupts from the comparator
		MOVFW	CMCON				;...have to read CMCON to clear CMIF (see manual)
		BCF	_CMIF				;
		BCF	NO_COMP_INT			;
;=======================================================;
_RESET_TMR0						;
		MOVLW	Timer0tick_ms			;
		MOVWF	TMR0				;
		BCF	_T0IF				;
							;
_EXIT_INTERRUPT						;
POP		RAM0					;
		MOVFW	B_FSR				;
	 	MOVWF	FSR				;
	 	MOVFW	B_PCLATH			;
	 	MOVWF	PCLATH				;
	 	SWAPF	B_STATUS,W			;
	 	MOVWF	STATUS				;
	 	SWAPF	B_WREG,F			;
	 	SWAPF	B_WREG,W			;
		RETFIE					;
;********************************************************

;****************************************************************
;****************************************************************
;****************************************************************
;START EXECUTION
;****************************************************************
;****************************************************************
;****************************************************************
START
	IFDEF		PIC16F676
		CLRF	PORTC				;
	ENDIF						;
							;
		CALL	03FFH				;ATTENZIONE!!!	RICORDARSI DI INSERIRE LA CHIAMATA X IL VALORE DI
							;	CALIBRAZIONE
		RAM1					;
		MOVWF	OSCCAL				;
							;
		MOVLW	MASK_OPTION_TMR0		;USE PS FOR TMR0
		MOVWF	OPTION_REG			;
		CLRF	WPU				;weak pullup
		MOVLW	MASK_TRISIO			;
		MOVWF	TRISIO				;GP0/1/2 IN INGRESSO, GP4/5 IN USCITA
		BCF	GATE_HEAT			;be sure heat is off
	
	IFDEF		PIC16F676			;
		CLRF	TRISC				;RC0/1/2/3/4/5 IN USCITA
	ENDIF						;
							;
		RAM0					;
	IFDEF		PIC16F676			;
		CLRF	PORTC				;
	ENDIF						;

		MOVLW	MASK_T1CON			;
		MOVWF	T1CON				;
							;
		CLRF	GPIO				;
							;
		BCF	BASE_TEMPI			;
		CALL	CLEAR_RAM			;
							;
	 	MOVLW	0E0H				;
		MOVWF	INTCON				;SET T0IE, GIE & PEIE 
							;
		CALL	COMPARATOR_ON			;
		CALL	CONVERTER_ON			;
							;
		BSF	_TMR1ON				;START TMR1
							;
_WAIT_START						;
		CALL	CHECK_TASTO			;
		BSF	LED				;
							;
		MOVLW	PERIOD_SIZE			;6ms
		MOVWF	PERIOD_COUNT			;
							;
		MOVLW	H'F5'				;
		MOVWF	HLF_SECONDS_L0			;
		MOVLW	2				; H'2F5 -> empiricaly measured
		MOVWF	HLF_SECONDS_HI			;
		MOVLW	2				;2 perds of 30"
		MOVWF	SECONDS				;
		MOVLW	.60				;
		MOVWF	MINUTE				;
							;
		BSF	PHASE_PR			;
		MOVLW	HIGH T_PR			;
		MOVWF	TT_HI				;
		MOVLW	LOW T_PR			;
		MOVWF	TT_LO				;
		CALL	CALCULATE_PID			;Loads value of TIME1
							;
		MOVLW	TIME2				;
		MOVWF	PHASE_2_TIMER			;
							;
		MOVLW	TIME3				;
		MOVWF	PHASE_3_TIMER			;
							;
		MOVLW	HIGH TEMPO_Z			;****11-01-06
		MOVWF	TIMER_Z_H			;
		MOVLW	LOW TEMPO_Z			;
		MOVWF	TIMER_Z_L			;
		INCF	TIMER_Z_H,F			;makes the double precision algorithm easier
							;
		MOVLW	TEMPO_Y				;
		MOVWF	MASTER_SHUTDOWN			;
							;
		BSF	NO_COMP_INT			;prime comparator
		MOVLW	.6				;
		MOVWF	LINE_DEBOUNCE			;
							;
		RAM1					;
		BSF	_CMIE				;Now, allow ZC compartor interrupts
		RAM0					;
							;
;********************************************************
MAIN_LOOP						;
		CLRWDT					;
							;
		BTFSS	PIR1,TMR1IF			;T1 EXPIRE?
		GOTO	_IDLE				;
		BCF	PIR1,TMR1IF			;
		MOVLW	-1				;
		MOVWF	TMR1H				;
		MOVLW	Timer1tick_ms			;reload timer1
		MOVWF	TMR1L				;
		CALL	ADJUST_REDUCED_TIMERS		;
							;
_PERIOD_TIME						;
		BTFSS	PERIOD_TICK			;
		GOTO	_HALF_SECOND_TASKS		;
		BCF		PERIOD_TICK		;
		MOVF	STAY_ON_PERIOD,F		;
		BTFSC	STATUS,Z			;decrement STAY_ON_PERIOD only when non zero
		GOTO	$+2				;
		DECF	STAY_ON_PERIOD,F		;this get calculated in CALCULATE_PID
		DECFSZ	CYCLE_CNTR,F			;256
		GOTO	_HALF_SECOND_TASKS		;
		CALL	CALCULATE_PID			;
		MOVLW	NUMBER_OF_CYCLES		;reset the cycle
		MOVWF	CYCLE_CNTR			;
							;
_HALF_SECOND_TASKS					;
		BTFSS	HALF_SECONDS_TICK		;
		GOTO	_SECONDS_TASKS			;
		BCF	HALF_SECONDS_TICK		;
		CALL	LED_BLINKER			;
							;
_SECONDS_TASKS						;
		BTFSS	SECONDS_TICK			;
		GOTO	_MINUTE_TASKS			;
		BCF	SECONDS_TICK			;
		CALL	CHECK_TIMER_Z			;****11-01-06
		CALL	CHECK_PHASE_TIMERS		;
							;
_MINUTE_TASKS						;
		BTFSS	MINUTES_TICK			;
		GOTO	_IDLE				;
		BCF		MINUTES_TICK		;
		CALL 	CHECK_TIMER_Y			;
		CALL	CHECK_X_INIT			;
							;
_IDLE	GOTO	MAIN_LOOP				;
;***************************************************************
;Blocks all processes until a valid START is received
;***************************************************************
CHECK_TASTO						;
		MOVLW	-TP				;
		MOVWF	COUNT_TASTO_PREMUTO		;
							;
		MOVLW	-1				;
		MOVWF	TMR1H				;
		MOVLW	Timer1tick_ms			;
		MOVWF	TMR1L				;
		BCF	PIR1,TMR1IF			;
							;
_WAIT_TASTO						;
		CLRWDT					;
		BTFSS	PIR1,TMR1IF			;check every milisecond
		GOTO	_WAIT_TASTO			;
							;
		BTFSC	TASTO				;NORMALLY 1 GOES TO 0 WHEN PRESSED
		GOTO	CHECK_TASTO			;reset
							;
		INCFSZ	COUNT_TASTO_PREMUTO,F 		;
		GOTO	_WAIT_TASTO			;
							;
		RETURN					;
;***************************************************************
;Mod 11-01-06: New timer for blinking the LED
;***************************************************************
CHECK_TIMER_Z						;
		BTFSC	CYCLE_ENDED			;count only if we're not in general shutoff
		GOTO	_TIMR_Z_END			; or
		BTFSC	TEMPO_Z_ON			; already in TEMPO_Z
		GOTO	_TIMR_Z_END			;
							;
		DECFSZ	TIMER_Z_L,F			;
		GOTO	_TIMR_Z_END			;
		DECFSZ	TIMER_Z_H,F			;
		GOTO	_TIMR_Z_END			;
							;
		BSF	TEMPO_Z_ON			;TEMPO_Z reached
							;
_TIMR_Z_END	RETURN					;
;***************************************************************
;EXECUTES EVERY MINUTE
;***************************************************************
CHECK_TIMER_Y						;
		BTFSC	CYCLE_ENDED			;are we in general shutoff?
		GOTO	_ENDED				;
							;
		DECFSZ	MASTER_SHUTDOWN,F		;
		GOTO	_END_Y				;
_ENDED		CLRF	STAY_ON_PERIOD			;GENERAL SHUT OFF
		CLRF	TT_HI				;
		CLRF	TT_LO				;
		MOVLW	b'01000000'			;shuts down all phases, LED, raises CYCLE_ENDED
		MOVWF	FLAGS2				;
		BCF	LED				;***11-01-06
_END_Y	RETURN						;
;***************************************************************
;IF WE ARE AT THE END OF PERIOD_Y, BLINK THE LED
;***************************************************************
LED_BLINKER						;modify ****11-01-06:
;		BTFSS	CYCLE_ENDED			;OUT: are we in general shutoff?
		BTFSS	TEMPO_Z_ON			;IN: are we in TEMPO_Z?
		GOTO	_LED_END			;
							;
		BTFSS	LED				;
		GOTO	_BLINK_ON			;
		BCF	LED				;
		GOTO	_LED_END			;
_BLINK_ON	BSF	LED				;
							;
_LED_END	RETURN					;
;***************************************************************
;Step through all phases
;***************************************************************
CHECK_PHASE_TIMERS					;
		BTFSS	CYCLE_ENDED			;
		GOTO	_PHASE_1			;
		CLRF	STAY_ON_PERIOD			;if we are in general shutoff make sure everything is OFF
		GOTO	_END_PHASE			;and do nothing
							;
_PHASE_1						;
		BTFSS	PHASE_1				;
		GOTO	_PHASE_2			;
		DECFSZ	PHASE_1_TIMER_LO,F		;
		GOTO	_END_PHASE			;
		DECFSZ	PHASE_1_TIMER_HI,F		;
		GOTO	_END_PHASE			;timer 1 running
							;
		BCF	PHASE_1				;timer 1 ended
		MOVLW	HIGH T2				;
		MOVWF	TT_HI				;
		MOVLW	LOW T2				;
		MOVWF	TT_LO				;
		BSF	PHASE_2				;
		GOTO	_END_PHASE			;
							;
_PHASE_2						;
		BTFSS	PHASE_2				;
		GOTO	_PHASE_3			;
		DECFSZ	PHASE_2_TIMER,F			;timer 2 running
		GOTO	_END_PHASE			;
							;
		BCF	PHASE_2				;timer 2 ended
		MOVLW	HIGH T3				;
		MOVWF	TT_HI				;
		MOVLW	LOW T3				;
		MOVWF	TT_LO				;
		BSF	PHASE_3				;
		GOTO	_END_PHASE			;
							;
_PHASE_3						;
		BTFSS	PHASE_3				;
		GOTO	_PHASE_4			;
		DECFSZ	PHASE_3_TIMER,F			;timer 3 running
		GOTO	_END_PHASE			;
							;
		BCF	PHASE_3				;timer 3 ended
		MOVLW	HIGH T4				;
		MOVWF	TT_HI				;
		MOVLW	LOW T4				;
		MOVWF	TT_LO				;
		BSF	PHASE_4				;
		GOTO	_END_PHASE			;
							;
_PHASE_4						;
		NOP					;DO NOTHING
_END_PHASE						;
		RETURN					;
;***************************************************************
;TT_HI and TT_HI are the preset temperatures
;***************************************************************
CALCULATE_PID						;
		CLRWDT					;
		BTFSC	CYCLE_ENDED			;are we in general shutoff?
		GOTO	_SHUT_OFF			;
							;
		BSF	GO_DONE				;start a/d acquisition
		BTFSC	GO_DONE				;
		GOTO	$-1				;
							;
		MOVFW	ADRESH				;
		MOVWF	TM_HI				;
		RAM1					;
		MOVFW	ADRESL				;
		RAM0					;
		MOVWF	TM_LO				;
;Calculate the difference between measured and target temperatures
		MOVFW	TM_HI				;
		SUBWF	TT_HI,W				;
		MOVWF	DIFF_HI				;save difference HI		
		MOVFW	TM_LO				;
		SUBWF	TT_LO,W				;
		MOVWF	DIFF_LO				;save difference HI		
		SKPNB					;
		DECF	DIFF_HI,F			;
							;
		MOVFW	DIFF_HI				;see below...
		MOVWF	DIFF_DEB_HI			;
		MOVFW	DIFF_LO				;
		MOVWF	DIFF_DEB_LO			;
							;
		BTFSS	PHASE_PR			;special case of PR
		GOTO	_CALC_P				;If we are abovr T_PR 
		BTFSS	NEGATIVE			;
		GOTO	_T1_NORMAL			;
									;then
		MOVLW	LOW REDUCED_TIME1		;load reduced TIME1 value
		MOVWF	PHASE_1_TIMER_LO		;
		MOVLW	HIGH REDUCED_TIME1		;
		MOVWF	PHASE_1_TIMER_HI		;
		INCF	PHASE_1_TIMER_HI,F		;MAKE SURE NOT 0!
		GOTO	_SET_T1_TEMP			;
_T1_NORMAL						;
		MOVLW	LOW	TIME1			;else
		MOVWF	PHASE_1_TIMER_LO		; load full TIME1 value
		MOVLW	HIGH TIME1			;
		MOVWF	PHASE_1_TIMER_HI		;endif
		INCF	PHASE_1_TIMER_HI,F		;MAKE SURE NOT 0!
_SET_T1_TEMP						;
		BCF	PHASE_PR			;
		BSF	PHASE_1				;
		MOVLW	HIGH T1				;
		MOVWF	TT_HI				;
		MOVLW	LOW T1				;
		MOVWF	TT_LO				;
							;
		MOVFW	TM_HI				;
		MOVWF	PT_HI				;initialize previous temperature
		MOVFW	TM_LO				;
		MOVWF	PT_LO				;
		GOTO	_CALC_END			;
							;
_CALC_P							;NORMAL RUNNING CONDITIONS
;		MOVFW	DIFF_HI				;safety checks for over-the-target:
;		ANDLW	H'F0'				;First check for negative numbers
;		BTFSC	STATUS,Z			;(DIFF_HI = H'FXXX)
;		GOTO	_CHK_MAX			;
;		M_CMPL_JL	DIFF_HI,H'FF',_EMERGENCY_OFF ;safety check 1: if the difference with the target
;		M_CMPL_JE	DIFF_LO,0,_EMERGENCY_OFF; temperature is > 256, then temperature runaway
_CHK_MAX						;
;		M_CMPL_JG	TM_HI,(HIGH T_200),_EMERGENCY_OFF;safety check 2: if the measured temperature
;		M_CMPL_JL	TM_HI,(HIGH T_200),_PID_CONT;
;		M_CMPL_JG	TM_LO,(LOW T_200),_EMERGENCY_OFF; is > 200 degreess
_PID_CONT						;
		BCF	FORZA_MAX			;
		MOVFW	DIFF_HI				;Calculate Proportional
		MOVWF	AARGB0				;
		MOVFW	DIFF_LO				;
		MOVWF	AARGB1				;
		MOVLW	HIGH Kp				;
		MOVWF	BARGB0				;
		MOVLW	LOW Kp				;
		MOVWF	BARGB1				;
		CALL	FXM1616S			;
 		MOVFW	AARGB0				;
		MOVWF	T_SUM0				;
		MOVFW	AARGB1				;
		MOVWF	T_SUM1				;
		MOVFW	AARGB2				;
		MOVWF	T_SUM2				;
		MOVFW	AARGB3				;
		MOVWF	T_SUM3				;
							;Calculate Integral 
_LAB		BTFSS	DIFF_HI,.7			;check sign bit
		GOTO	_POS_I				;
							;
	IFDEF	FREERUN					;
		MOVLW	H'FF'				;Reduce the negative growth of the integral part
		MOVWF	DIFF_HI				;
		MOVLW	H'E0'				;
		IORWF	DIFF_LO,F			;
							;
		COMF	DIFF_HI,F			;negative difference
		COMF	DIFF_LO,F			; use 2's complement
		INCF	DIFF_LO,F			;
		SKPNZ					;
		INCF	DIFF_HI,F			;
	ENDIF						;

	IFDEF FIXED					;
		MOVLW	.5				;subtract a fixed number
		MOVWF	DIFF_LO				;
		CLRF	DIFF_HI				;
	ENDIF						;

		MOVFW	DIFF_LO				;
		SUBWF	SIGMA_LO,F			;
		SKPNB					;borrow?
		DECF	SIGMA_HI,F			;
		BTFSS	SIGMA_HI,7

		;MOVFW	DIFF_HI				;
		;SUBWF	SIGMA_HI,F			;
		;SKPB					;
		GOTO	_CALC_I				;
							;
		CLRF	SIGMA_HI			;
		CLRF	SIGMA_LO			;
		GOTO	_CALC_I				;
							;
_POS_I	
		MOVLW	HIGH	MAX_DIF_PREC		;
		SUBWF	DIFF_HI,W			;
		SKPZ					;
		B	PI1				;
							;
		MOVLW	LOW	MAX_DIF_PREC		;
		SUBWF	DIFF_LO,W			;
							;
PI1		SKPNB					;
		B	PI2				;
		MOVLW	LOW	PRECARICA_PID		;
		MOVWF	SIGMA_LO			;Precarico SIGMA
		MOVLW	HIGH	PRECARICA_PID		;
		MOVWF	SIGMA_HI			;Precarico SIGMA
		BSF	FORZA_MAX			;
		GOTO	_CALC_I				;
							;
PI2		CLRF	DIFF_HI				;Reduce positive growth
		MOVLW	H'7F'				;
		ANDWF	DIFF_LO,F			;
							;
		MOVFW	DIFF_LO				;positive number
		ADDWF	SIGMA_LO,F			;
		SKPNC					;
		INCFSZ	SIGMA_HI,F			;
		GOTO	_SKP1				;
		GOTO	_SIGMA_OVFL			;
							;
_SKP1	BTFSC	SIGMA_HI,.7				;
		GOTO	_SIGMA_OVFL			;
							;
		MOVFW	DIFF_HI				;
		ADDWF	SIGMA_HI,F			;
		SKPC					;
		GOTO	_CALC_I				;
							;
_SIGMA_OVFL						;
		MOVLW	H'7F'				;overflow on sigma counter
		MOVWF	SIGMA_HI			;
		MOVLW	H'FF'				;
		MOVWF	SIGMA_LO			;
;		CLRF	SIGMA_HI			;overflow on sigma counter
;		MOVLW	H'1F'				;
;		MOVWF	SIGMA_LO			;
							;
_CALC_I		MOVFW	SIGMA_HI			;
		MOVWF	AARGB0				;
		MOVFW	SIGMA_LO			;
		MOVWF	AARGB1				;
		MOVLW	HIGH Ki				;
		MOVWF	BARGB0				;
		MOVLW	LOW Ki				;
		MOVWF	BARGB1				;
		CALL	FXM1616S			;
		CALL	ADD32S				;
							;
		MOVFW	TM_LO				;Calculate derivative
		SUBWF	PT_LO,W				;note: subtract current from previous temperature (PT - TM)
		MOVWF	DIFF_LO				;		so the difference is negative if temp is rising and
		BTFSC	STATUS,C			;		positive if falling
		GOTO	$+3				;
		INCF	TM_HI,W				;
		GOTO	$+2				;
		MOVFW	TM_HI				;
		SUBWF	PT_HI,W				;
		MOVWF	DIFF_HI				;
							;
		MOVFW	TM_HI				;
		MOVWF	PT_HI				;update previous temperature
		MOVFW	TM_LO				;
		MOVWF	PT_LO				;
							;
		MOVFW	DIFF_HI				;
		MOVWF	AARGB0				;
		MOVFW	DIFF_LO				;
		MOVWF	AARGB1				;
		MOVLW	HIGH Kd				;
		MOVWF	BARGB0				;
		MOVLW	LOW Kd				;
		MOVWF	BARGB1				;
		CALL	FXM1616S			;
		CALL	ADD32S				;
							;Check the result

;		BTFSC	DIFF_DEB_HI,7			;shutoff if we're negative anyways...
;		GOTO	_SHUT_OFF			;

		BTFSS	FORZA_MAX			;forza ff se differenza (negativa) > MAX_DIF_NEG ******************
		GOTO	_CON2				;
							;Differenza negativa Verifico se precaricare FF
		;MOVLW	HIGH	MAX_DIF_NEG
		;SUBWF	DIFF_HI,W
		;SKPZ
		;B		PI1S

		;MOVLW	LOW		MAX_DIF_NEG
		;SUBWF	DIFF_LO,W

PI1S	;SKPNB
		;B	_CON1

		;CLRF	SIGMA_HI			;
		;CLRF	SIGMA_LO			;
		MOVLW	H'FF'
		MOVWF	T_SUM2				;Precarico SIGMA
		B	_CON1

_CON2								;forza 00 se Differenza (positiva) > MAX_DIF_POS
		;MOVLW	HIGH	MAX_DIF_POS
		;SUBWF	DIFF_HI,W
		;SKPZ
		;B		PI2S

		;MOVLW	LOW		MAX_DIF_POS
		;SUBWF	DIFF_LO,W

PI2S	;SKPNB
		;B	_CON1

		;CLRF	SIGMA_HI			;
		;CLRF	SIGMA_LO			;
		NOP							;MOVLW	H'00'
		NOP							;MOVWF	T_SUM2				;Precarico SIGMA

									;++++++++++++++++++++++++++++++ FINE MODIFICA
_CON1	BTFSC	T_SUM0,7			;
		GOTO	_SHUT_OFF			;
		MOVFW	T_SUM0				;If higher order bytes set, 
		IORWF	T_SUM1,W			;
		SKPZ					;
		GOTO	_SATURATE			;
		GOTO	_TURN_ON			;
							;
_SATURATE						;
		MOVLW	NUMBER_OF_CYCLES	;MAXIMUM NUMBER OF CYCLES		
		MOVWF	T_SUM2				;
_TURN_ON						;PARTIAL PERIOD
		MOVFW	T_SUM2				;
		MOVWF	STAY_ON_PERIOD			;
		GOTO	_CALC_END			;
_EMERGENCY_OFF						;
		CLRF	TT_HI				;TOTAL SHUTDOWN
		CLRF	TT_LO				;
		MOVLW	b'01000000'			;
		MOVWF	FLAGS2				;
_SHUT_OFF						;
		CLRF	STAY_ON_PERIOD			;ZERO PERIODS
							;
_CALC_END						;
		MOVFW	STAY_ON_PERIOD			;
		MOVWF	DEBUG				;
		RETURN					;
;***************************************************************
;Add cuadruple precision
;***************************************************************
ADD32S							;
		MOVFW	AARGB3				;
		ADDWF	T_SUM3,F			;Propagate carry bit
		SKPC					;
		GOTO	_ARG2				;
		INCFSZ	AARGB2,F			;
		GOTO	_ARG2				;
		INCFSZ	AARGB1,F			;
		GOTO	_ARG2				;
		INCF	AARGB0,F			;
							;
_ARG2	MOVFW	AARGB2					;
		ADDWF	T_SUM2,F			;
		SKPC					;
		GOTO	_ARG1				;
		INCFSZ	AARGB1,F			;
		GOTO	_ARG1				;
		INCF	AARGB0,F			;
							;
_ARG1	MOVFW	AARGB1					;
		ADDWF	T_SUM1,F			;
		SKPC					;
		GOTO	_ARG0				;
		INCF	AARGB0,F			;
							;
_ARG0	MOVFW	AARGB0					;
		ADDWF	T_SUM0,F			;
							;
		RETURN					;
;***************************************************************
ADJUST_REDUCED_TIMERS					;
		DECFSZ	PERIOD_COUNT,F			;6 ms counter
		GOTO	_CHECK_HALF_SEC			;
		BSF		PERIOD_TICK		;TICK...
		MOVLW	PERIOD_SIZE			;
		MOVWF	PERIOD_COUNT			;
							;
_CHECK_HALF_SEC						;1/2 second counter
		DECFSZ	HLF_SECONDS_L0,F		;
		GOTO	_END_RED			;
		DECFSZ	HLF_SECONDS_HI,F		;
		GOTO	_END_RED			;
		BSF	HALF_SECONDS_TICK		;TICK...
		MOVLW	H'F5'				;
		MOVWF	HLF_SECONDS_L0			;
		MOVLW	2				; H'2F5 -> empiricaly measured
		MOVWF	HLF_SECONDS_HI			;
							;
		DECFSZ	SECONDS,F			;seconds counters
		GOTO	_END_RED			;
		BSF	SECONDS_TICK			;
		MOVLW	2				;2 perds of 30"
		MOVWF	SECONDS				;
							;
		DECFSZ	MINUTE,F			;minute counters
		GOTO	_END_RED			;
		BSF	MINUTES_TICK			;...TOCK
		MOVLW	.60				;
		MOVWF	MINUTE				;
							;
_END_RED						;
		RETURN					;
;************* PULIZIA RAM BANK0 ************************
CLEAR_RAM						;
		MOVLW	01FH				;INIZIO RAM -1
		MOVWF	FSR				;
							;
PURA0	INCF	FSR,F					;
		CLRF	INDF				;
		MOVLW	05FH				;FINE RAM
		XORWF	FSR,W				;
		SKPZ					;
		GOTO	PURA0				;
		RETURN					;
;**********************************************************
;Turn the comparator on but do not allow interruopts yet.
;**********************************************************
COMPARATOR_ON						;
		MOVLW	MASK_CMCON			;CM0÷CM2 = 100 (GP0:D, GP1:A) = NO OUTPUT, INTERNAL REF
		MOVWF	CMCON				;
		BCF	_CMIF				;COMPARATOR INT FLAG
							;
		MOVLW	MASK_VRCON_UP_TO_DOWN		;
		BTFSC	_COUT				;
		MOVLW	MASK_VRCON_DOWN_TO_UP		;
							;
		RAM1					;
		MOVWF	VRCON				;
		BSF	_CMIE				;allow ZC ints
		RAM0					;
							;
		RETURN					;
;***************************************************************
COMPARATOR_OFF						;
		MOVFW	CMCON				;...have to read CMCON to clear CMIF (see manual)
		BCF	_CMIF				;
		RAM1					;
		BCF	_CMIE				;
		MOVLW	0				;
		MOVWF	VRCON				;
		RAM0					;
		MOVLW	MASK_CMCON_OFF			;CM0÷CM2 = 111 OFF
		MOVWF	CMCON				;
		RETURN					;
;***************************************************************
CONVERTER_ON						;
		MOVLW	MASK_ADCON			;
		MOVWF	ADCON0				;
							;
		RAM1					;
		MOVLW	MASK_ANSEL			;
		MOVWF	ANSEL				;
		RAM0					;
		RETURN					;
;***************************************************************
CHECK_X_INIT
	RAM1

  ;OSCCAL
	CALL	03FFH
	XORWF	OSCCAL,W
	SKPNZ
	GOTO	CXI2

	CALL	03FFH
	MOVWF	OSCCAL
;;CXI1
; ;OPTION_REG
;	MOVFW	OPTION_REG		option reg changes for gait time measurement
;	XORLW	MASK_OPTION
;	SKPNZ
;	GOTO	CXI2
;
;	MOVLW	MASK_OPTION
;	MOVWF	OPTION_REG
;
;  ;WPU
CXI2	MOVFW	WPU
	SKPZ
	CLRF	WPU

  ;TRISIO
	MOVFW	TRISIO
	XORLW	MASK_TRISIO
	SKPNZ
	GOTO	CXI3

	MOVLW	MASK_TRISIO
	MOVWF	TRISIO

  ;T1CON
CXI3	RAM0
	MOVFW	T1CON
	XORLW	MASK_T1CON
	SKPZ
	BSF	_TMR1ON

  ;INTCON
	MOVFW	INTCON
	ANDLW	0C0H
	XORLW	0C0H
	SKPNZ
	GOTO	CXI5

	MOVLW	0C0H
	IORWF	INTCON,F

  ;CMCON
CXI5	MOVFW	CMCON
	ANDLW	0BFH
	XORLW	MASK_CMCON
	SKPNZ
	GOTO	CXI6

	MOVLW	MASK_CMCON
	IORWF	CMCON,F

  ;VRCON
CXI6	RAM1
	MOVFW	VRCON
	ANDLW	0F0H
	XORLW	MASK_VRCON_INIT
	SKPNZ
	GOTO	CXI4

	MOVLW	MASK_VRCON_INIT
	ANDLW	08FH
	IORWF	VRCON,F

  ;ADCON0
CXI4	RAM0
	MOVFW	ADCON0
	ANDLW	0FDH
	XORLW	MASK_ADCON
	SKPNZ
	GOTO	CXI7

	MOVLW	MASK_ADCON
	IORWF	ADCON0,F

  ;ANSEL
CXI7	RAM1
	MOVFW	ANSEL
	XORLW	MASK_ANSEL
	SKPNZ
	GOTO	CXI8

	MOVLW	MASK_ANSEL
	MOVWF	ANSEL

CXI8
CXI_X	RAM0
	RETURN
;***************************************************************

	INCLUDE <MUL16X16SIGNED.INC>


;*** CALIBRATION ***
	ORG	0x3FF
	RETLW	080H


;***************************************************************
	org 0x2100
 de 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00

	org 0x2110
 de 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00

	org 0x2120
 de 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00

	org 0x2130
 de 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00

	org 0x2140
 de 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00

	org 0x2150
 de 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00

	org 0x2160
 de 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00

	org 0x2170
 de 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
 ;***************************************************************


	END
