;----------------------------------------------------------------
;Tranmitter / Remote control for an electric blanket.  
;Funtions: Write to the LCD, al1low setting of parameters,....
;
; Programmer:	Gino Isla for Lambda Sistemi, Milano
; Created:		21-10-2005	Version 1.0
; Clock:		4Mhz normal operation or 32KHz external during PWM period
; IDE: 			MPLAB v7.20
;----------------------------------------------------------------
;	list		p=16f914		; list directive to define processor
;	#include	<p16f917.inc>	; processor specific variable definitions
	#include	<p16f914.inc>	; processor specific variable definitions
	#include	<Macros.inc>
	#include	<UTENZA.INC>
	#include	<TXHeader.h>

;********************** INCLUDE FOR TX HANDLING **************************
;	 #include   <hcs_tx.inc> AT THE BOTTOM OF THIS CODE
;********************** INCLUDE FOR TX HANDLING **************************

	
	__CONFIG _FCMEN_ON & _IESO_ON & _CP_OFF & _WDT_OFF & _BOD_OFF & _MCLRE_ON & _PWRTE_ON & _INTRC_OSC_NOCLKOUT
	__IDLOCS	0110	;1.1.0
	ERRORLEVEL -302


;******* INTERRUPT FLAGSS *************************************************
#DEFINE	TMR1_IF		PIR1,TMR1IF	;(0) TMR1 INTERRUPT OCCURRED
#DEFINE	LCD_IF		PIR2,LCDIF	;(4) LCD INTERRUPT OCCURRED
;******* ADCON0 *************************************************
#DEFINE	GO_DONE		ADCON0,1	;(1)	1 = CONVERSION IN PROGRESS								
								;		0 = CONVERSION DONE
;******* FOR INCLUDED CODE TX_HCS ******************************
#DEFINE	TMR_HCS_ON	_TMR1ON
;definitions for TX_HCS:
#DEFINE	BANK1	BSF	STATUS,RP0
#DEFINE	BANK0	BCF	STATUS,RP0
#DEFINE	RAM1	BSF	STATUS,RP0
#DEFINE	RAM0	BCF	STATUS,RP0
#DEFINE	RAM_1	BSF	STATUS,RP0
#DEFINE	RAM_0	BCF	STATUS,RP0
#DEFINE	SET	BSF
#DEFINE	CANC	BCF
#DEFINE	SC	BTFSC
#DEFINE	SS	BTFSS
#DEFINE	IFSET	BTFSC
#DEFINE	IFCANC	BTFSS
#DEFINE	SKPB	SKPNC
#DEFINE	SKPNB	SKPC
#DEFINE	FW	MOVFW
#DEFINE	WF	MOVWF
#DEFINE	LW	MOVLW
;*** INTCON ***
#DEFINE	_INTE	INTCON,INTE
#DEFINE	_INTF	INTCON,INTF
#DEFINE	_GIE	INTCON,GIE
#DEFINE	_T0IE	INTCON,T0IE
#DEFINE	_T0IF	INTCON,T0IF
#DEFINE	_PEIE	INTCON,PEIE

#DEFINE	TRASMISSIONE_HCS	FLAGS_HCS,0	;
#DEFINE	ALTO1_BASSO0		FLAGS_HCS,1	;FLAG DA INVERTIRE CHE DETERMINA TE2

;#DEFINE	PWM_HCS		PORTD,7	;PIN DI TRASMISSIONE HCS  <== new in electric blanket

;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;+++++++++++++++++++++++ DATA +++++++++++++++++++++++++++++++++++++++++
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

;BANK 0 VARIABLES *****************************************************
		CBLOCK	020H
TEMP_BYT0_B0					;general purpose for bank0
TEMP_BYT1_B0					;general purpose for bank0
LED1_CLOCK					;
RT_SECONDS					;real time seconds counter
RT_MINUTES					;	"		minutes   "
RT_HOURS					;	"		hours     "
DEBOUNCE_CNT					;debounce count
BACKLIGHT_CNT					;
BLINK_COUNT					;delay for blinking the display
NEW_BUTTON_CONFIG				;configuration of the buttons when they are read
OLD_BUTTON_CONFIG				;OLD configuration of the buttons
LCD_CHAR3					;all purpose flags
LCD_CHAR4					;more flags
ADJUST_CLK_PHASE				;
MAX_HOURS					;CLOCK turn over
RE_LOCK_TIME					;RE LOCK TIMER
AUTO_OFF_HOURS					;1, 3 or 12 hr AUTO SHUT-OFF timer
AUTO_OFF_MINUTES				;AUTO SHUT-OFF minutes count down
BOOST_MINUTES					;minutes, counter of PRE-HEAT minutes
SAVED_TEMPERATURE				;save the temp when AUTO-OFF timer is is turned off
PRE_MESSAGE_TIMER				;wait time before sending a HEAT message
REXMIT_COUNT					;
RESEND_OFF_COUNT				;counter for resending the OFF msg (15')
RESEND_ON_COUNT_L				;counter for resending the ON msg (15' -> 900secs)
RESEND_ON_COUNT_H				;
PAUSE_COUNT					;counter delays in
BATTERY_BLINK_COUNT				;counter blinks the battery segment
IDLE_BATT_COUNT					;number of hours after which the test message is sent when no other tranmissions
BAT_OFF_MSG_COUNT				;this is a stop to endless sends of the OFF msg on low battery.
TMR2_1SECOND					;one second counter with TMR2
;=====================================================
; BUFFER DI TRASMISSIONE HCS
HCS1						;reserved(7:5), left/right side (4),serial number high (3:0)
HCS2						;serial number(7:0)
HCS3						;serial number(7:0)
HCS4						;serial number(7:0) low
HCS5						;level(7:3),beep(2),learn(1), padding(0)
HCS6						;checksum
FLAGS_HCS
FASE_TX_HCS
CARICA_TIMER_HCS_HI
CARICA_TIMER_HCS_LO
PUNTA_HCS
COUNT_BIT
TEMP_ROTATE
COUNT_PREAMBOLO
BI_STATUS
BI_PCLATH
BI_FSR
		ENDC

;COMMON DATA		**************************************************
		CBLOCK	71H
LCD_CHAR1					;flags to discriminate characters in the display
LCD_CHAR2					;all purpose flags
LCD_CHAR5					;more flags (MISC, NOT USED)
MIN_VALUE					;minutes to write on the display [0:60]
HOUR_VALUE					;hours to write on the display [0:24]
TMPTR_VALUE					;temperature to write on the display [0:24]
BI_WREG						;save wreg in ISR
		ENDC

;BANK 2 VARIABLES 	**************************************************
		CBLOCK	0120H
WR_ERRORS					;
WR_NOERRORS					;
TOGGLE_LCD					;
TEMP_BYT0_B2					;general purpose for bank2
TEMP_BYT1_B2					;general purpose for bank2
		ENDC

;-- ALIAS HCS_TX -------------------------------------------------------------


TMR_HCS	EQU	TMR0
HEADER_COUNT	EQU	COUNT_PREAMBOLO
COUNT_DATA	EQU	COUNT_PREAMBOLO



;Uncomment to work with ICD2 +++++++++
;#DEFINE DEBUG
						;
	ORG     0x000				; processor reset vector
	clrf    PCLATH				; ensure page bits are cleared
  	goto    main				; go to beginning of program
						;
						;
	org	0x04				;
PUSH:						;
	WF	BI_WREG				;COPIA DEL WREG
	SWAPF	STATUS,W			;COPIA DELLO STATUS
	M_BANKSEL_0
	MOVWF	BI_STATUS
	FW	PCLATH
	WF	BI_PCLATH
	FW	FSR
	WF	BI_FSR
	B	INTERRUPT


;Begining of executable code	;
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Jump table for drawing a character in the LCD
;bit sequence is:  -gfedcba
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DIGIT_SELECT					;
	ADDWF	PCL,F				;
	RETLW	b'00111111'			;"0"		
	RETLW	b'00000110'			;"1"
	RETLW	b'01011011'			;"2"		
	RETLW	b'01001111'			;"3"
	RETLW	b'01100110'			;"4"
	RETLW	b'01101101'			;"5"
	RETLW	b'01111101'			;"6"
	RETLW	b'00000111'			;"7"
	RETLW	b'01111111'			;"8"
	RETLW	b'01101111'			;"9"
	RETLW	b'00111000'			;"L" (value=10)
	RETLW	b'01110110'			;"H" (value=11)

;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;++++++++++++++   Start of the Program   ++++++++++++++++++++++++++++++
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
main						;
	M_BANKSEL_0				;bank 0
	CLRWDT					;
						;
	MOVLW	b'00000000'			;gie off, peripherals off,tmr0 off,RB0 and RB changes off,flags off
	MOVWF	INTCON				;
	CLRF	PORTA				;
	CLRF	PORTB				;
	CLRF	PORTC				;
	CLRF	PORTD				;
	CLRF	PORTE				;
	CLRF	PIR1				;clear all interrupt flags
	CLRF	PIR2				;clear all interrupt flags .......including LCDPS,WA
						;
	MOVLW	b'00001111'			;gate off, 1:1 PS, no sync extr clock,tmr1 on
	MOVWF	T1CON				;
						;
	CALL	CLEAR_RAM_0			;
	CALL	CLEAR_RAM_1			;
						;	
	MOVLW	CLKP_HOUR_12			;
	MOVWF	MAX_HOURS			;
						;
;A/D CONVERTER					;
	MOVLW	b'00011100'			;LEFT justified,vref,read AN7,A/D powered OFF
	MOVWF	ADCON0				;
						;
	M_BANKSEL_1				;
	MOVLW	b'10000000'			;Select AN7 (RE2) analogue input for low battery detection
	MOVWF	ANSEL				;
						;
	MOVLW	b'01010000'			;fosc/16 for conversion
	MOVWF	ADCON1				;
						;
	MOVLW	.7				;
	MOVWF	CMCON0				;OFF
						;
	MOVLW	b'01100001'			;4MHz clock,dev is running from int clk,int osc for system clock
	MOVWF	OSCCON				;
	MOVLW	b'00000000'			;TMR1 interrupts DISABLED, TMR1IF flag will be polled for seconds roll-over
;interrupts and ports				;
	MOVWF	PIE1				;
	MOVLW	b'00000000'			;LCD interrupt disabled
	MOVWF	PIE2				;
	MOVLW	MASKTA				;
	MOVWF	TRISA				;
	MOVLW	MASKTB				;
	MOVWF	TRISB				;
	MOVLW	MASKTC				;
	MOVWF	TRISC				;
	MOVLW	MASKTD				;
	MOVWF	TRISD				;
	MOVLW	MASKTE				;
	MOVWF	TRISE				;
						;
	MOVLW	b'10000000'			;no pullups, tmr0 internal, prescale assigned to tmr0,<2:0>=PS tmr0 = 1:2
	MOVWF	OPTION_REG			;PortA pullups disabled
						;
;LCD control registers				;
	M_BANKSEL_2				;
	CLRF	WR_ERRORS			;
	CLRF	WR_NOERRORS			;
	CLRF	TOGGLE_LCD			;
	MOVLW	b'00010111'			;lcd off, on when sleep,no write error,VLCD enabled,TMR1 is source clk,1/4 common
	MOVWF	LCDCON 				; 
						;
	MOVLW	b'10000000'			;waveform B(1),bias 1/3 for 1/4 mux,
	IORLW	LCD_PRESCALE			;add the prescaler (see TXHeader.h)
	MOVWF	LCDPS				;  --- with 1:2 PS
						;
#IFDEF 	WAVE_TYPE_B				;
	MOVLW	WFT_B				;waveform B(1),bias 1/3 for 1/4 mux,
#ELSE						;
	MOVLW	WFT_A				;waveform A(0),bias 1/3 for 1/4 mux,
#ENDIF						;
	IORWF	LCDPS,F				;
						;
	MOVLW	b'11111111'			;Sements (7:0) all LCD segments enabled
	MOVWF	LCDSE0				;
#IFDEF DEBUG					;
	MOVLW	b'11101111'			; DEBUG - RB5 and RB6 for ICD2, seg15 <bit5> problems
#ELSE						;
	MOVLW	b'00001111'			;Sements (15:8)  THIS ARE THE REAL FLAGS !!!!!!!!!!
#ENDIF						;
	MOVWF	LCDSE1				;
	CLRF	LCDSE2				;Sements (23:16) all IO pins ********* LCDSE2 doesn't exist in 16F913 ***
						;
	MOVLW	b'00010010'			;WDT PS 1:16K, software enable off
	MOVWF	WDTCON				;
	CLRF	LCDDATA0			;all segments dark
	CLRF	LCDDATA1			;
	CLRF	LCDDATA3			;******** LCDDATA2,LCDDATA5, LCDDATA8 and LCDDATA11 don't exist in 6F913 ***
	CLRF	LCDDATA4			;
	CLRF	LCDDATA6			;
	CLRF	LCDDATA7			;
	CLRF	LCDDATA9			;
	CLRF	LCDDATA10			;
	BSF	LCDCON,LCDEN			;
						;
	M_BANKSEL_0				;
	MOVLW	PW_OFF_PERIOD			;LED1 initialized to OFF
	MOVWF	LED1_CLOCK			;
	BSF	KB0				;buttons disabled
	MOVLW	b'00000011'			;display hours, minutes
	MOVWF	LCD_CHAR1			;
	MOVLW	b'00000010'			;display device OFF
	MOVWF	LCD_CHAR2			;Initialize some more local data
	BSF	COLON				;display ":"
	BSF	LCD_UPD				;
						;
	BSF	SND_TEST_MSG			;Test the batery by sending a test message
	MOVLW	IDLE_BATTERY_TEST		; and reload the counter
	MOVWF	IDLE_BATT_COUNT			;
	MOVLW	1				;
	MOVWF	BAT_OFF_MSG_COUNT		;
	MOVLW	BLINK_2P_PERIOD			;
	MOVWF	TMR2_1SECOND			;
	MOVLW	b'00000110'			;start timer 2
	MOVWF	T2CON				;1 second blink of the ":", POSTSCALE 1:1, POSTCALE 1:16, TMR2 OFF
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;+++++++++++++++++++++   Main Loop ++++++++++++++++++++++++++++++++++++
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
_SNOOZE:					;
	M_BANKSEL_0				;
;	BCF	DEBUG_OUT			;
	BTFSC	TRASMISSIONE_HCS		;if TRASMISSIONE_HCS is set, we're still transmitting
	GOTO	_STAY_UP			;
	BTFSC	BTN_ACT_PDG			;if there is an on-going button action, don't sleep
	GOTO	_STAY_UP			;
						;
	NOP					;
	BCF	INTCON,GIE			;
	BSF	INTCON,PEIE			;
	BSF	STATUS,5			;BANK 1
	BSF	PIE2,LCDIE			;set LCD ints to wake up
	NOP					;
	NOP					;	
						;
	#IFNDEF DEBUG				;
	SLEEP					;
	ELSE					;
	NOP					;
	#ENDIF					;
	NOP					;
	NOP					;
	BCF	PIE2,LCDIE			;
	BCF	STATUS,5			;BANK 0
	BCF	INTCON,PEIE			;
_STAY_UP					;
	BTFSS	LCD_IF				;wait here for lcd interrupt flag
	GOTO	_STAY_UP			;
						;
	NOP					;
;	bsf	DEBUG_OUT			;
	NOP					;
	BTFSS	TRASMISSIONE_HCS		;if TRASMISSIONE_HCS is set, we're transmitting something, 
	CALL	SEND_MESSAGES			; so do other jobs
						;
	CALL	SECONDS_BLINK			;
	CALL	UPDATE_LCD			;finish any display that may be pending because of even/odd frames
	CALL	REAL_TIME_SERVICES		;see if TMR1 expired in the meantime
						;
	MOVLW	b'00111110'			;handle ALL ACTIONS which are in progress
	ANDWF	LCD_CHAR3,W			;
	BTFSS	STATUS,Z			;
	CALL	HANDLE_BUTTONS			;
						;
	BTFSC	BATTERY_LOW			;block all actions when the batteries are low
	GOTO	_SNOOZE				;
	BTFSS	BTN_ACT_PDG			;accept new jobs only if no other job is pending
	CALL	TEST_BUTTONS			;
						;
	CALL	DISPLAY_REAL_TIME		;Load Real Time variables for display in the LCD
	CALL	MANAGE_LED1			;
	CALL	TREAT_BATTERY_DISPLAY		;
	CALL	UPDATE_LCD			;
	GOTO	_SNOOZE				;
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Handles message sending to the BASE unit. 
;BEEPER bit must be in the correct state
;Message layout:
;HCS1	BIT 7÷5		0		RESERVED, FORCED TO ZERO
;HCS1	BIT 4		0÷1		LEFT/RIGHT SIDE
;HCS1	BIT 3÷0		0÷F		SERIAL NUMBER HIGH
;HCS2	BIT 7÷0		00÷FF		SERIAL NUMBER
;HCS3	BIT 7÷0		00÷FF		SERIAL NUMBER
;HCS4	BIT 7÷0		00÷FF		SERIAL NUMBER LOW
;HCS5	BIT 7÷3		00÷0A		LEVEL CODE
;HCS5	BIT 2		0÷1		BEEPER
;HCS5	BIT 1		0-1		LEARN MODE ON/OFF
;HCS5	BIT 0		0		PADDING
;HCS6	BIT 7÷0		00÷FF		CHECKSUM
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SEND_MESSAGES					;
	BTFSC	TRASMISSIONE_HCS		;If we are not finished xmitting, leave
	GOTO	_MSG_FIN			;don't start a new one
	MOVF	REXMIT_COUNT,F			;
	BTFSC	STATUS,Z			;If we are in the procees of retranmitting
	GOTO	_NEW_MSG			; go re-send the last message (already in HCSx)
	DECFSZ	PAUSE_COUNT,F			;
	GOTO	_MSG_FIN			;
	DECFSZ	REXMIT_COUNT,F			;
	GOTO	_RE_SEND			;
	GOTO	_MSG_FIN			;
						;
_NEW_MSG					; else
	BTFSS	SND_OFF_MSG			;check if there are NEW messages to send
	GOTO	_ON_MSG				;
	MOVLW	.0				;tempertature = 0
	BCF	SND_OFF_MSG			;
	GOTO	_MSG_CONT1			;
_ON_MSG						;
	BTFSS	SND_ON_MSG			;
	GOTO	_REFRESH_MSG			;
	MOVF	TMPTR_VALUE,W			;temperature = new temperature
	BCF	SND_ON_MSG			;
	GOTO	_MSG_CONT1			;
_REFRESH_MSG					;
	BTFSS	SND_REFRESH_MSG			;
	GOTO	_BOOST_ON_MSG			;temperature = real temperature
	MOVF	TMPTR_VALUE,W			;
	BCF	SND_REFRESH_MSG			;
	GOTO	_MSG_CONT2			;do 5 repetitions
_BOOST_ON_MSG					;
	BTFSS	SND_BOOSTON_MSG			;
	GOTO	_BOOST_OFF_MSG			;
	MOVLW	.10				;temperature = max temperature
	BCF	SND_BOOSTON_MSG			;
	GOTO	_MSG_CONT1			;
_BOOST_OFF_MSG					;
	BTFSS	SND_BOO_OFF_MSG			;
	GOTO	_SND_LEARN_MSG			;
	MOVF	TMPTR_VALUE,W			;temperature = real temperature
	BCF	SND_BOO_OFF_MSG			;
	GOTO	_MSG_CONT1			;
_SND_LEARN_MSG					;
	BTFSS	SND_LEARN_MSG			;
	GOTO	_SND_TEST_MSG			;we need the SND_LEARN_MSG flag down below
	MOVLW	.0				;temperature = 0 (don't care)
	GOTO	_MSG_CONT2			;5 repetitions
_SND_TEST_MSG					;
	BTFSS	SND_TEST_MSG			;if this is a test message, we will load all the
	GOTO	_MSG_FIN			; message parameters but corrupt the checksum to make
	MOVLW	.0				;
						; sure the test message is not used by the base
_MSG_CONT1					;
	MOVWF	TEMP_BYT0_B0			;save temperature level whiche is in WREG in temp_byt
	MOVLW	REXMIT_NORMAL			;new message is ready to send
	MOVWF	REXMIT_COUNT			;Load the repeat counter
	GOTO	_MSG_CONT3			;
						;
_MSG_CONT2					;
	MOVWF	TEMP_BYT0_B0			;save temperature level whiche is in WREG in temp_byt
	MOVLW	REXMIT_EXTEND			;new message is ready to send
	MOVWF	REXMIT_COUNT			;Load the repeat counter								;
						;
_MSG_CONT3					;
	RLF	TEMP_BYT0_B0,F			;now pack the temperature
	RLF	TEMP_BYT0_B0,F			;and
	RLF	TEMP_BYT0_B0,F			;
	MOVLW	0xF8				;clear padding bit
	ANDWF	TEMP_BYT0_B0,W			;
	MOVWF	HCS5				;and
	BTFSC	BEEPER				;
	BSF	HCS5,2				;load beeper
	BTFSC	SND_LEARN_MSG			;and
	BSF	HCS5,1				;learn bits
						;
	BCF	BEEPER				;
	BCF	SND_LEARN_MSG			;flags can now be cleared
						;
	CALL	GET_SERIAL_0			;msb
	MOVWF	TEMP_BYT0_B0			;
	MOVLW	0x0F				;msb is 1 nibble only
	ANDWF	TEMP_BYT0_B0,W			;
	IORWF	HCS1,F				;
						;
	CALL	GET_SERIAL_1			;next msb
	MOVWF	HCS2				;
	CALL	GET_SERIAL_2			;next msb
	MOVWF	HCS3				;
	CALL	GET_SERIAL_3			;lsb
	MOVWF	HCS4				;
	BCF	HCS1,4				;Future LEFT/RIGHT indication
						;
	CLRF	HCS6				;
	MOVLW	HCS1				;calculate checksum
	MOVWF	FSR				;
	MOVLW	.5				;
	MOVWF	TEMP_BYT0_B0			;
_CHKSUM_LOOP					;
	MOVF	INDF,W				;
	ADDWF	HCS6,F				;
	INCF	FSR,F				;
	DECFSZ	TEMP_BYT0_B0,F			;
	GOTO	_CHKSUM_LOOP			;
						;
	BTFSS	SND_TEST_MSG			;
	GOTO	_RE_SEND			;
	INCF	HCS6,F				;corrupt the checksum
	BCF	SND_TEST_MSG			;
	CLRF	REXMIT_COUNT			;send test message only once
						;
_RE_SEND					;
	BCF	TX_ENABLE			;
	BANK1					;TX_ENABLE should only be output when transmitting
	BCF	TXENBL_TRIS			;
	BANK0					;
	BCF	TX_ENABLE			;
	MOVLW	.60				;hard delay 120uS								
	MOVWF	TEMP_BYT0_B0			;
_LOOP_DELAY					;
	DECFSZ	TEMP_BYT0_B0,F			;
	GOTO	_LOOP_DELAY			;
	BSF	_GIE				;enable global ints
						;
	MOVLW	MSG_PAUSE_PERIOD		;
	MOVWF	PAUSE_COUNT			;
	CALL	INIZIO_TX_HCS			;
_MSG_FIN					;
	RETURN					;
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Decide which button procedure must handle this button
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
HANDLE_BUTTONS					;
	BTFSS	AUTOLOCK_ON			;
	GOTO	_NEXT_HANDLE			;if locked
						;  then
	MOVLW	b'00000100'			;
	XORWF	NEW_BUTTON_CONFIG,W		;
	BTFSS	STATUS,Z			;when in AUTOLOCK, the debounce timer is 2 seconds!
	GOTO	_AUTOLOCK_REJECT		; so on first detection of the MODE key, we
	BCF	AUTOLOCK_ON			; can remove the LOCK
	BSF	RELOCK_ON			; and 
	MOVLW	AUTOLOCK_OFF_TIME		; prepare the count to re-lock
	MOVWF	RE_LOCK_TIME			;
	BCF	BTN_ACT_PDG			;
	BCF	LOCKED				;
	GOTO	_DISPLAY_ADJUSTMENTS		;
						;
_AUTOLOCK_REJECT				;
	BSF	AUTOLOCK_ON			;
	BCF	BTN_ACT_PDG			;
	GOTO	_RESET_RELOCK			;
						;
_NEXT_HANDLE					;HANDLE BUTTON ACTIONS.........
	BTFSC	CLCKSET_ACT			;clock adjustments?
	GOTO	_HANDLE_CLK_SET			;
	BTFSC	HEAT_ACT			;check if an action has already been assigned
	GOTO	_HEAT_MSG_ACTION		;boost adjustments?
						;
_NEW_ACTIONS					;no task has been assigned yet, this may be a new action
;===================================== SEND LEARN MESSAGE ==========
	MOVLW	b'00000110'			;
	XORWF	NEW_BUTTON_CONFIG,W		;
	BTFSS	STATUS,Z			;
	GOTO	_PREHEAT			;
	BSF	BEEPER				;beep
	BSF	SND_LEARN_MSG			;
	BCF	BTN_ACT_PDG			;
	GOTO	_RESET_RELOCK			;
						;
_PREHEAT					;
	BTFSS	PREHEAT				;
	GOTO	_NEW_MODE			;
						;
;===================================== NEW BOOST ACTION ==============
	BTFSS	DEVON				;accept boost only if the device is on
	GOTO	_NO_MORE_ACTION			;
	BTFSC	BOOST_ACT			;If the device is already BOOSTing, don't start it again
	GOTO	_NO_MORE_ACTION			;
						;
	BSF	BOOST_ACT			;
	BSF	SND_BOOSTON_MSG			;
	BSF	TEMPETR				;turn on TEMP and BOOST icons
	BSF	BEEPER				;beep
	BSF	BOOST				;
	MOVLW	.10				;display "H"
	MOVWF	TMPTR_VALUE			;
	MOVLW	BOOST_PERIOD			;
	MOVWF	BOOST_MINUTES			;start BOOST timer
	BSF	LCD_UPD				;
	CALL	UPDATE_LCD			;
	CALL	UPDATE_LCD			;
	BCF	BTN_ACT_PDG			;
	GOTO	_RESET_RELOCK			;
						;
_NEW_MODE					;
	BTFSS	MODE				;
	GOTO	_NEW_CLKSET			;
;======================================= NEW ACTION FOR AUTO-OFF TIMER =====
	BTFSC	DEVOFF				;
	GOTO	_MODE1HR			;
	BTFSC	ONEHR				;
	GOTO	_MODE3HR			;
	BTFSC	THREEHR				;
	GOTO	_MODE12HR			;
	BTFSC	TWELVEHR			;
	GOTO	_MODE_OFF			;
	GOTO	_NO_MORE_ACTION			;
						;
_MODE1HR					;
	MOVLW	AUTO_OFF_1HR			;THIS IS HOW WE TURN ON THE DEVICE
	MOVWF	AUTO_OFF_HOURS			;Step through the different settings
						;
	MOVF	SAVED_TEMPERATURE,W		;
	MOVWF	TMPTR_VALUE			;
	BSF	DEVON				;
	BSF	TEMPETR				;
	BCF	DEVOFF				;
	BSF	ONEHR				;
	BCF	THREEHR				;
	BCF	TWELVEHR			;
	BSF	SND_ON_MSG			;Inform the base
	BSF	BEEPER				;(beep, unit is turned on)
	CALL	FILL_RESEND_PERIOD		;
	CLRF	RESEND_OFF_COUNT		;don't send off msg
	GOTO	_SAVE_MINUTES			;
_MODE3HR					;
	MOVLW	AUTO_OFF_3HR			;
	MOVWF	AUTO_OFF_HOURS			;
	BSF	DEVON				;
	BCF	DEVOFF				;Don't need to inform the base, we'll just keep sending the refresh msg longer
	BCF	ONEHR				;
	BSF	THREEHR				;
	BCF	TWELVEHR			;
	BSF	BEEPER				;
	BSF	SND_REFRESH_MSG			;
	GOTO	_SAVE_MINUTES			;
_MODE12HR					;
	MOVLW	AUTO_OFF_12HR			;
	MOVWF	AUTO_OFF_HOURS			;
	BSF	DEVON				;
	BCF	DEVOFF				;
	BCF	ONEHR				;
	BCF	THREEHR				;
	BSF	TWELVEHR			;(no beep)
	BSF	BEEPER				;
	BSF	SND_REFRESH_MSG			;
	GOTO	_SAVE_MINUTES			;
_MODE_OFF					;
	CALL	DEVICE_OFF			;
	BSF	BEEPER				;(beep, change is manual)
	GOTO	_DISP_AUTO_OFF			;
						;
_SAVE_MINUTES					;
	MOVLW	SIXTY_MINUTES			;
	MOVWF	AUTO_OFF_MINUTES		;minutes count down (hours already loaded in AUTO_OFF_HOURS)
_DISP_AUTO_OFF					;
	BSF	LCD_UPD				;
	CALL	UPDATE_LCD			;
	CALL	UPDATE_LCD			;
	BCF	BTN_ACT_PDG			;
	GOTO	_RESET_RELOCK			;
						;
_NEW_CLKSET					;
	BTFSS	CLOCK_SET			;
	GOTO	_NEW_TEMP_VARS			;
;=================================== NEW CLOCK ADJUSTMENTS ACTION ============
_NEW_CLK_ADJ					;
	BSF	CLCKSET_ACT			;start clock adjustment
	BSF	COLON				;
	MOVLW	CLKP_MIN_ADJ			;
	MOVWF	ADJUST_CLK_PHASE		;1st phase of clock adjustment
	MOVLW	BLINK_PERIOD			;
	MOVWF	BLINK_COUNT			;
	BSF	MINUTES				;
	BSF	LCD_UPD				;
	CALL	UPDATE_LCD			;
	CALL	UPDATE_LCD			;
	GOTO	_RESET_RELOCK			;
;===================================================================
_HANDLE_CLK_SET					;continue setting the clock according to the phase
	M_CMPL_JE	ADJUST_CLK_PHASE,CLKP_MIN_ADJ,_MIN_ADJUST
	M_CMPL_JE	ADJUST_CLK_PHASE,CLKP_HOUR_ADJ,_HR_ADJUST
	GOTO	_NO_MORE_ACTION			;resets flags, resets relock count and goes out
						;
_MIN_ADJUST					;ADJUST MINUTES
	DECFSZ	BLINK_COUNT,F			;
	GOTO	_NO_BLKMIN			;
	MOVLW	b'00000001'			;toggle MINUTES
	XORWF	LCD_CHAR1,F			;
	MOVLW	BLINK_PERIOD			;
	MOVWF	BLINK_COUNT			;
	BSF	LCD_UPD				;
	CALL	UPDATE_LCD			;blink the display
_NO_BLKMIN					;
	CALL	TEST_BUTTONS			;check for + - buttons
	BSF	BTN_ACT_PDG			;make sure we stay in this loop until debouncing is finished
	BTFSC	DEBOUNCING			;
	GOTO	_RESET_RELOCK			;
	CLRF	OLD_BUTTON_CONFIG		;
						;
_SKIPMIN					;button was pressed
	BTFSC	PLUS				;+ button
	GOTO	_ADD_MINUTE			;
	BTFSC	MINUS				;- button
	GOTO	_SUB_MINUTE			;
	GOTO	_MODE_MIN			;
_ADD_MINUTE					;
	INCF	RT_MINUTES,F			;
	M_CMPL_JL RT_MINUTES,.60,_GO1_MIN	;
	CLRF	RT_MINUTES			;
_GO1_MIN					;
	GOTO	_NEW_MINUTES			;
_SUB_MINUTE					;
	MOVF	RT_MINUTES,F			;
	BTFSS	STATUS,Z			;decrement if not zero
	GOTO	_DECMIN				;
	MOVLW	.59+.1				;
	MOVWF	RT_MINUTES			;
_DECMIN						;
	DECF	RT_MINUTES,F			;
_NEW_MINUTES					;
	BSF	LCD_UPD				;
	MOVF	RT_MINUTES,W			;
	CALL	Convert_to_BCD			;
	MOVWF	MIN_VALUE			;
	GOTO	_RESET_RELOCK			;
_MODE_MIN					;
	BTFSS	MODE				;MODE button pressed?
	GOTO	_HANDLE_FIN			;
	BSF	MINUTES				;
	MOVLW	BLINK_PERIOD			;stop blinking 12/24 hours
	MOVWF	BLINK_COUNT			;
	MOVLW	CLKP_HOUR_ADJ			;go to phase 3, adjust hours
	MOVWF	ADJUST_CLK_PHASE		;
	BSF	LCD_UPD				;
	CALL	UPDATE_LCD			;
	CALL	UPDATE_LCD			;
	BSF	HOURS				;
	GOTO	_RESET_RELOCK			;
						;
_HR_ADJUST					;ADJUST HOURS
	DECFSZ	BLINK_COUNT,F			;
	GOTO	_NO_BLKHR			;
	MOVLW	b'00000010'			;toggle HOURS bit for blinking
	XORWF	LCD_CHAR1,F			;
	MOVLW	BLINK_PERIOD			;
	MOVWF	BLINK_COUNT			;
	BSF	LCD_UPD				;
	CALL	UPDATE_LCD			;
_NO_BLKHR					;
	CALL	TEST_BUTTONS			;check for adjustments 
	BSF	BTN_ACT_PDG			;make sure we stay in this loop until debouncing is finished
	BTFSC	DEBOUNCING			; 
	GOTO	_RESET_RELOCK			;
	CLRF	OLD_BUTTON_CONFIG		;
						;
_SKIPHR						;button pressed was:
	BTFSC	PLUS				;+ button
	GOTO	_ADD_HOUR			;
	BTFSC	MINUS				;- button
	GOTO	_SUB_HOUR			;
	GOTO	_MODE_HOUR			;
_ADD_HOUR					;
	INCF	RT_HOURS,F			;
	M_CMP_JLE RT_HOURS,MAX_HOURS,_GO1_HR	;
	MOVLW	.1				;
	MOVWF	RT_HOURS			;
_GO1_HR						;
	GOTO	_NEW_HOURS			;
_SUB_HOUR					;
	M_CMPL_JG RT_HOURS,1,_DECHR		;
	MOVLW	CLKP_HOUR_12			;...2,1,12,11...
	MOVWF	RT_HOURS			;
	GOTO	_NEW_HOURS			;
_DECHR						;
	DECF	RT_HOURS,F			;
_NEW_HOURS					;
	BSF	HOURS				;
	BSF	LCD_UPD				;
	MOVF	RT_HOURS,W			;
	CALL	Convert_to_BCD			;
	MOVWF	HOUR_VALUE			;
	GOTO	_RESET_RELOCK			;
_MODE_HOUR					;
	BTFSS	MODE				;
	GOTO	_HANDLE_FIN			;
	BSF	MINUTES				;hour values is being confirmed
	BSF	HOURS				;
	BCF	BTN_ACT_PDG			;
	BCF	CLCKSET_ACT			;
	CLRF	ADJUST_CLK_PHASE		;ADJUST_CLK_PHASE = CLKP_NOTHING
	CLRF	RT_SECONDS			;
	MOVLW	BLINK_2P_PERIOD			;re-start toggle the COLON bit
	MOVWF	TMR2_1SECOND			;
	BSF	LCD_UPD				;
	CALL	UPDATE_LCD			;
	CALL	UPDATE_LCD			;
	GOTO	_RESET_RELOCK			;
						;
;===================================== NEW TEMPERATURES CHANGES ======
_NEW_TEMP_VARS					;
	BTFSS	DEVON				;accept heat changes only if the device is on 
	GOTO	_NO_MORE_ACTION			;
						;
	BTFSC	AUTOLOCK_ON			;
	GOTO	_NO_MORE_ACTION			;Temperature variations accepted only if unlocked
						;
	BTFSC	BOOST_ACT			;If the device is BOOSTing, don't accept temperature changes (new requirement)
	GOTO	_NO_MORE_ACTION			;
						;
	BTFSC	PLUS				;
	GOTO	_ACCEPT_HEAT_CHANGE		;
	BTFSS	MINUS				;
	GOTO	_NO_MORE_ACTION			;
_ACCEPT_HEAT_CHANGE				;
	BSF	HEAT_ACT			;make sure we come back to _HEAT_MSG_COUNTING below
	BSF	TEMPETR				;
	MOVLW	HEAT_MSG_COUNTDWN		;start the count down
	MOVWF	PRE_MESSAGE_TIMER		;
_HEAT_MSG_ACTION				;
	BTFSC	DEBOUNCING			;make sure we're finished debouncing
	GOTO	_NO_MORE_ACTION			;
						;
	BTFSC	PLUS				;
	GOTO	_TEMP_INCR			;
	BTFSC	MINUS				;
	GOTO	_TEMP_DECR			;
	GOTO	_HEAT_MSG_COUNTDOWN		;countdown if now button pressed
						;
_TEMP_INCR					;
	M_CMPL_JG TMPTR_VALUE,MAX_TEMP-1,_WRAP_ZERO ;wrap around if we're at min
	INCF	TMPTR_VALUE,F			;
	GOTO	_DELAY_MSG_SEND			;
_WRAP_ZERO					;
	CLRF	TMPTR_VALUE			;
	GOTO	_DELAY_MSG_SEND			;
						;
_TEMP_DECR					;"-" BUTTON?
	M_CMPL_JE	TMPTR_VALUE,0,_WRAP_HIGH ;wrap around if we're at max
	DECF	TMPTR_VALUE,F			;
	GOTO	_DELAY_MSG_SEND			;
_WRAP_HIGH					;
	MOVLW	MAX_TEMP			;
	MOVWF	TMPTR_VALUE			;
						;
_DELAY_MSG_SEND					;
	MOVF	TMPTR_VALUE,W			;
	MOVWF	SAVED_TEMPERATURE		;
	MOVLW	HEAT_MSG_COUNTDWN		;reload the count down
	MOVWF	PRE_MESSAGE_TIMER		;
	BSF	LCD_UPD				;
	CALL	UPDATE_LCD			;call twice
	CALL	UPDATE_LCD			;
	CLRF	OLD_BUTTON_CONFIG		;junior: elimina questa riga
;	CLRF	NEW_BUTTON_CONFIG		;
	GOTO	_NO_MORE_ACTION			;
						;
_HEAT_MSG_COUNTDOWN				;
	DECFSZ	PRE_MESSAGE_TIMER,F		;
	GOTO	_HANDLE_FIN			;
	BSF	SND_ON_MSG			;
	BSF	BEEPER				;(beep, on last increment)
	BCF	HEAT_ACT			;
	BCF	BTN_ACT_PDG			;
	CALL	FILL_RESEND_PERIOD		;
	CLRF	OLD_BUTTON_CONFIG		;
	GOTO	_RESET_RELOCK			;
;===================================================================
_DISPLAY_ADJUSTMENTS				;
	BSF	LCD_UPD				;
	CALL	UPDATE_LCD			;
	GOTO	_RESET_RELOCK			;
						;
_NO_MORE_ACTION					;
	BCF	BTN_ACT_PDG			;
						;
_RESET_RELOCK					;
	MOVLW	AUTOLOCK_OFF_TIME		; RESET THE RE-LOCK counters (even if we're not in autolock)
	MOVWF	RE_LOCK_TIME			;
_HANDLE_FIN					;
	RETURN					;
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Fill the RESEND_ON_COUNT with a pseudo random number with a spread that 
;goes from 12' to 15'.
;OUTPUT: RESEND_ON_COUNT_L,RESEND_ON_COUNT_H
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
FILL_RESEND_PERIOD				;
	MOVLW	HIGH (SEND_ON_PERIOD)		;
	MOVWF	TEMP_BYT1_B0			;
	MOVLW	0xBF				;xBF = mask to get a ramdom spread of 191secs (~3mins)
	ANDWF	TMR0,W				; randomize with value of TMR0
	MOVWF	TEMP_BYT0_B0			;
	MOVLW	LOW (SEND_ON_PERIOD)		;
	ADDWF	TEMP_BYT0_B0,F			;
	SKPNC					;
	INCF	TEMP_BYT1_B0,F			;	
	BCF	STATUS,C			;devide by 2 because the seconds timer expires each 2seconds
	RRF	TEMP_BYT1_B0,F			;
	RRF	TEMP_BYT0_B0,F			;
	MOVF	TEMP_BYT0_B0,W			;
	MOVWF	RESEND_ON_COUNT_L		;
	INCF	TEMP_BYT1_B0,W			;this INCF is to make the countdown algorithm work for the last FF period
	MOVWF	RESEND_ON_COUNT_H		;
	RETURN					;
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Turn this device off (adjust the LCD accordingly and send an OFF message to 
;the base
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DEVICE_OFF					;
	CLRF	AUTO_OFF_HOURS			;
	BCF	DEVON				;
	BCF	LED1_STATE			;
	BCF	LED1				;make sure LED1 is off when the device goes off
	MOVLW	PW_OFF_PERIOD			;
	MOVWF	LED1_CLOCK			;
	BCF	TEMPETR				;
	BCF	BOOST_ACT			;
	BCF	BOOST				;
	BSF	DEVOFF				;
	BCF	ONEHR				;
	BCF	THREEHR				;
	BCF	TWELVEHR			;
	BSF	SND_OFF_MSG			;
	MOVLW	SEND_OFF_PERIOD			;
	MOVWF	RESEND_OFF_COUNT		;
	RETURN					;
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Test and debounce push buttons
;NEW_BUTTON_CONFIG<0:7> are mapped as follows: KB7, KB1, KB2, KB3, KB4, KB5, KB6, KB8
;redefined as CLOCK_SET(5),........
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
TEST_BUTTONS					;
#IFDEF DEBUG					;
	M_BANKSEL_2				;
	BCF	LCDSE1,7			;SEG15 shared with KB0 (RA3)
	BCF	STATUS,6			;BANK 0
#ENDIF						;
	BCF	BTN_ACT_PDG			;
	BCF	KB0				;
	MOVLW	5				;
	MOVWF	TEMP_BYT0_B0			;
_TB_WAIT					;
	DECFSZ	TEMP_BYT0_B0,F			;forced delay 5us wait for push buttons
	GOTO	_TB_WAIT			;
						;
	MOVF	PORTD,W				;read buttons
	MOVWF	NEW_BUTTON_CONFIG		;
	BSF	NEW_BUTTON_CONFIG,6		;NOT_USED
	BSF	NEW_BUTTON_CONFIG,7		;NOT USED.......
	BSF	NEW_BUTTON_CONFIG,0		;NOT USED.......
						;
	BTFSC	UNLOCKING			;if the unlock/relock process is running
	GOTO	_TB_CONT			;	don't test the lock button
	BTFSC	RELOCK_ON			;
	GOTO	_TB_CONT			;
						;
	BTFSC	KB8				;else
	GOTO	_TB_UNLOCK			;set the lock/unlock 
_TB_LOCK					; 	according the current position 
	BTFSC	AUTOLOCK_ON			;	display if it has changed
	GOTO	_TB_CONT			;
	BSF	AUTOLOCK_ON			;
	BSF	LOCKED				;
	BSF	LCD_UPD				;
	GOTO	_TB_CONT			;
_TB_UNLOCK					;
	BTFSS	AUTOLOCK_ON			;
	GOTO	_TB_CONT			;
	BCF	AUTOLOCK_ON			;
	BCF	LOCKED				;
	BSF	LCD_UPD				;fi;
_TB_CONT					;
	BTFSS	F_BODY_GUARD			;
	BSF	KB0				;finished reading buttons
						;
	MOVLW	0xFF				;
	XORWF	NEW_BUTTON_CONFIG,F		;invert
						;
	BTFSS	DEBOUNCING			;are we debouncing?
	GOTO	_START_DEBOUNCING		;no
						;
_DEBOUNCING					;yes, waiting for a zero count
	M_CMP_JNE NEW_BUTTON_CONFIG,OLD_BUTTON_CONFIG,_CLEAR_DEBOUNCE	;we are debouncing, still the same?
	DECFSZ	DEBOUNCE_CNT,F			;
	GOTO	_BUTTON_END			;
	BSF	BACKLIGHT			;turn backlight on
	MOVLW	BACKLIGHT_PERIOD		;
	MOVWF	BACKLIGHT_CNT			;
	BSF	BTN_ACT_PDG			;
	GOTO	_CLEAR_DEBOUNCE			;finished debouncing
						;
_START_DEBOUNCING				;this would be a first change
	M_CMP_JE NEW_BUTTON_CONFIG,OLD_BUTTON_CONFIG,_CLEAR_DEBOUNCE ;not debouncing and no change
	BSF	DEBOUNCING			;start debouncing
	MOVF	NEW_BUTTON_CONFIG,W		;the button pressed or released is here
	MOVWF	OLD_BUTTON_CONFIG		;
						;
	BTFSS	AUTOLOCK_ON			;select debounce period
	GOTO	_HEAT_DEBOUNCE_PERIOD		;
						;
_AUTOLOCK_DEBOUNCE_PERIOD			;
	MOVLW	AUTOLOCK_DEBOUNCE		;extended debounce when in autolock
	MOVWF	DEBOUNCE_CNT			;
	GOTO	_BUTTON_END			;
						;
_HEAT_DEBOUNCE_PERIOD				;
	BTFSS	HEAT_ACT			;extended debounce to slow down continuous changes to heat level
	GOTO	_NORMAL_DEBOUNCE_PERIOD		;
	MOVLW	HEAT_ADJ_DEBOUNCE		;
	MOVWF	DEBOUNCE_CNT			;
	GOTO	_BUTTON_END			;
						;
_NORMAL_DEBOUNCE_PERIOD				;
	MOVLW	DEBOUNCE_PERIOD			;
	MOVWF	DEBOUNCE_CNT			;
	GOTO	_BUTTON_END			;
						;
_CLEAR_DEBOUNCE					;
	BCF	DEBOUNCING			;no more debounce
						;
_BUTTON_END					;
#IFDEF DEBUG					;
	BSF	STATUS,6			;BANK 2
	BSF	LCDSE1,7			;SEG15 shared with KB0 (RA3)
	BCF	STATUS,6			;BANK 0
#ENDIF						;
	RETURN					;
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Drive the ON/OFF cycle of LED1
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
MANAGE_LED1					;
	BTFSS	DEVON				;drive LED only when the device is on
	GOTO	_LED1_END			;
						;
	DECFSZ	LED1_CLOCK,F			;
	GOTO	_LED1_END			;
						;
	BTFSC	LED1_STATE			;
	GOTO	_TURN_LED1_OFF			;
						;
_TURN_LED1_ON					;
	BSF	LED1_STATE			;
	BSF	LED1				;don't go to sleep while LED1 is ON
	MOVLW	PW_ON_PERIOD			;
	GOTO	_LED1_SET			;
						;
_TURN_LED1_OFF					;
	BCF	LED1_STATE			;
	BCF	LED1				;don't go to sleep while LED1 is ON
	MOVLW	PW_OFF_PERIOD			;
						;
_LED1_SET					;
	MOVWF	LED1_CLOCK			;
_LED1_END					;
	RETURN					;
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Treat the battery LCD segment according to its state
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
TREAT_BATTERY_DISPLAY				;
	BTFSS	BATTERY_WARN			;
	GOTO	_BATT_LOW			;
	DECFSZ	BATTERY_BLINK_COUNT,F		;battery warning
	GOTO	_BATT_FIN			; decrement the blink counter
	MOVLW	BLINK_PERIOD			; when the count reches 0, toggle the bit
	MOVWF	BATTERY_BLINK_COUNT		; and display in the LCD
	MOVLW	b'10000000'			;
	XORWF	LCD_CHAR1,F			;
	BSF	LCD_UPD				;
	CALL	UPDATE_LCD			;
	GOTO	_BATT_FIN			;
						;		
_BATT_LOW					;
	BTFSS	BATTERY_LOW			;
	GOTO	_BATT_GOOD			;
	BSF	BATTLOW				;battery low
	BSF	LCD_UPD				;
	GOTO	_BATT_FIN			;
						;
_BATT_GOOD					;
	BCF	BATTLOW				;
_BATT_FIN					;
	RETURN					;
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;blink the colon (:) every sec (based on the LCD period
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SECONDS_BLINK					;
	DECFSZ	TMR2_1SECOND,F			;
	GOTO	_BLINK_END			;
						;
	BTFSC	CLCKSET_ACT			;blink : if we're NOT adjusting the clock
	GOTO	_BLINK_END			;
						;
	MOVLW	BLINK_2P_PERIOD			;toggle the COLON bit
	MOVWF	TMR2_1SECOND			;
	MOVLW	b'00100000'			;
	XORWF	LCD_CHAR5,F			;
	BSF	LCD_UPD				;
_BLINK_END					;
	RETURN					;
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Updates the real time clock and the LCD display when necessary
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
REAL_TIME_SERVICES				;
	BTFSS	TMR1_IF				;if TMR1 rolled over
	GOTO	_RT_DONE			;
						;
;============================= SECONDS COUNTERS ===============================
	BCF	TMR1_IF				;
_RT_SECONDS					;
	INCF	RT_SECONDS,F			;ticks every 2 seconds at 32K
	INCF	RT_SECONDS,F			;
;...............................................;
;HANDLE ANY OTHER REAL TIME SECONDS COUNTERS
;...............................................;
	MOVF	BACKLIGHT_CNT,F			;BACKLIGHT OFF
	BTFSC	STATUS,Z			;
	GOTO	_RESEND_ON_MSG			;
	DECFSZ	BACKLIGHT_CNT,F			;
	GOTO	_BL1				;BACKLIGHT OFF time should always be an even number
	GOTO	_TURN_OFF_BL			; <-- this GOTO in case it was odd
_BL1	DECFSZ	BACKLIGHT_CNT,F			;
	GOTO	_RESEND_ON_MSG			;
_TURN_OFF_BL					;
	BCF	BACKLIGHT			;
;...............................................;
_RESEND_ON_MSG					;periodic ON message
	BTFSS	DEVON				;
	GOTO	_RELOCK_SECS			;
	DECFSZ	RESEND_ON_COUNT_L,F		;
	GOTO	_RELOCK_SECS			;
	DECFSZ	RESEND_ON_COUNT_H,F		;
	GOTO	_RELOCK_SECS			;
						;
_RELOAD_ON_MSG					;
	CALL	FILL_RESEND_PERIOD		;
	BCF	BEEPER				;
	BSF	SND_REFRESH_MSG			;
;...............................................;
_RELOCK_SECS					;
	BTFSS	RELOCK_ON			;RE-LOCK
	GOTO	_RT_MINUTES			;relock time should always be an even number
	DECFSZ	RE_LOCK_TIME,F			;
	GOTO	$+2				;
	GOTO	_RELOCK_REACHED			;
	DECFSZ	RE_LOCK_TIME,F			;
	GOTO	_RT_MINUTES			;
_RELOCK_REACHED					;
	BSF	LOCKED				;
	BSF	LCD_UPD				;
	BSF	AUTOLOCK_ON			;LOCK again
	BCF	RELOCK_ON			;prepare the count till un-lock
						;
;============================= MINUTES COUNTERS ===============================
_RT_MINUTES					;
	M_CMPL_JG RT_SECONDS,.59,_INCMIN	;
	GOTO	_RT_DONE			;
						;
_INCMIN						;
	CLRF	RT_SECONDS			;REAL TIME MINUTES
	INCF	RT_MINUTES,F			;
	BSF	LCD_UPD				;minutes have been updated so LCD must be updated also
;...............................................;
_RESEND_OFF_MSG					;
	MOVF	RESEND_OFF_COUNT,F		;see if OFF msg has to be resent
	BTFSC	STATUS,Z			;
	GOTO	_AUTOSHUTOFF			;
	DECFSZ	RESEND_OFF_COUNT,F		;
	GOTO	_AUTOSHUTOFF			;
	BCF	BEEPER				;
	BSF	SND_OFF_MSG			;
;...............................................;
_AUTOSHUTOFF					;
	BTFSS	DEVON				;
	GOTO	PREHEAT_COUNTDOWN		;
	DECFSZ	AUTO_OFF_MINUTES,F		;AUTO SHUT-OFF minutes count down
	GOTO	PREHEAT_COUNTDOWN		;
	DECFSZ	AUTO_OFF_HOURS,F		;hours count down
	GOTO	_RELOAD_AO_MINUTES		;
	GOTO	_AO_DONE			;
_RELOAD_AO_MINUTES				;
	MOVLW	SIXTY_MINUTES			;
	MOVWF	AUTO_OFF_MINUTES		;
	GOTO	PREHEAT_COUNTDOWN		;
_AO_DONE					;
	CALL	DEVICE_OFF			;
	MOVF	TMPTR_VALUE,W			;
	MOVWF	SAVED_TEMPERATURE		;Save the temperature before going off
;...............................................;
PREHEAT_COUNTDOWN				;
	BTFSS	BOOST				;
	GOTO	_RT_HOURS			;
						;
	DECFSZ	BOOST_MINUTES,F			;PRE-HEAT period minutes count down
	GOTO	_RT_HOURS			;
	BCF	BOOST				;
	BCF	BOOST_ACT			;
	MOVF	SAVED_TEMPERATURE,W		;
	MOVWF	TMPTR_VALUE			;
	BCF	BEEPER				;
	BSF	SND_BOO_OFF_MSG			;turn pre heat off in the base
						;
;============================= HOURS COUNTERS ===============================
_RT_HOURS					;
	M_CMPL_JG RT_MINUTES,.59,_INCHR		;
	GOTO	_RT_DONE			;
_INCHR						;
	CLRF	RT_MINUTES			;0 minutes
	INCF	RT_HOURS,F			;next hour
	M_CMP_JLE RT_HOURS,MAX_HOURS,_BATTERY_COUNTER
	MOVLW	.1				;
	MOVWF	RT_HOURS			;roll the clock over
						;
;...............................................;
_BATTERY_COUNTER				;
	DECFSZ	IDLE_BATT_COUNT,F		;
	GOTO	_RT_DONE			;
						;
	BSF	SND_TEST_MSG			;If the counter is exceeded, send a test message
	MOVLW	IDLE_BATTERY_TEST		; and reload the counter
	MOVWF	IDLE_BATT_COUNT			;
						;
_RT_DONE					;
 	RETURN					;
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;If there are no jobs pending and the display must be cupdated, 
;display move the REal Time info into the variables for the LCD
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DISPLAY_REAL_TIME				;Display the real time in the clock
	MOVLW	b'00011111'			;unless some action is in progress
	ANDWF	LCD_CHAR3,W			;
	BTFSS	STATUS,Z			;
	GOTO	_TM1ENDEND			;(but don't reset LCD_UPDATE)
						;
	BTFSS	LCD_UPD				;
	GOTO	_TM1ENDEND			;
						;
	BSF	MINUTES				;
	MOVF	RT_MINUTES,W			;
	CALL	Convert_to_BCD			;convert both hours and minutes to BCD
	MOVWF	MIN_VALUE			;
						;
	MOVF	RT_HOURS,W			;
	CALL	Convert_to_BCD			;convert to BCD
	MOVWF	HOUR_VALUE			;
	BSF	HOURS				;
_TM1ENDEND					;
	RETURN					;
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
INTERRUPT
;Servo l'interrupt
ISR	BTFSC	_T0IF
	BTFSS	_T0IE
	B	ISR_X

;=======================================
;*** BASE TEMPI OGNI 204,8 µS [(256 (CICLI) * 4 (PRESCALE) / 5 (QUARZO 20 MHZ)]
	BCF	_T0IF

	SS	TRASMISSIONE_HCS
	B	ISR_X

	LW	.200
	SUBWF	TMR_HCS,F

	CALL	GESTIONE_TMR_HCS

;=======================================
ISR_X
POP	M_BANKSEL_0
	FW	BI_FSR
	WF	FSR
	FW	BI_PCLATH
	WF	PCLATH
	SWAPF	BI_STATUS,W	;RIPRISTINO DELLO STATUS
	MOVWF	STATUS
	SWAPF	BI_WREG,F	;RIPRISTINO DEL WREG
	SWAPF	BI_WREG,W
	RETFIE
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;LCD driver
;PARAMETERS: LCD DIGIT,VALUE (when displaying minutes, hours and temp)
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
UPDATE_LCD					;
	M_BANKSEL_2				;
	BCF	LCDCON,LCDEN			;this is needed to be able to clear the LCDIF flag
	BCF	STATUS,6			;bank 0
	BCF	LCD_IF				;
	BSF	STATUS,6			;bank 2
	BSF	LCDCON,LCDEN			;
						;
	BTFSS	LCD_UPD				;write only if there is a request
	GOTO	_LCD_DONE			;
						;
#IFDEF 	WAVE_TYPE_B				;
	MOVLW	1				;
	XORWF	TOGGLE_LCD,F			;Write only every other frame with WaveType "B"
	BTFSC	STATUS,Z			;
	GOTO	_LCD_DONE			;
#ENDIF						;
						;
	BTFSS	LCDCON,WERR			;write only if no errors writing to the LCD
	GOTO	_LCDCONT			;
	BCF	LCDCON,WERR			;
						;
	BTFSS	LCDPS,WA			;write only if WA (write allowed) flag is set
	GOTO	_LCD_DONE			;
						;manage here the character flags an blinking
_LCDCONT					;
	BCF	LCD_UPD				;
	INCF	WR_NOERRORS,F			;FOR DEBUG - bANK 2
	CLRF	LCDDATA0			;first clear the display
	CLRF	LCDDATA1			;
	CLRF	LCDDATA3			;
	CLRF	LCDDATA4			;
	CLRF	LCDDATA6			;
	CLRF	LCDDATA7			;
	CLRF	LCDDATA9			;
	CLRF	LCDDATA10			;
						;
	BTFSS	MINUTES				;
	GOTO	_COLON				;
	MOVLW	HIGH (DIGIT_SELECT)		;take care of paging and jump tables
	MOVWF	PCLATH				;
	MOVF	MIN_VALUE,W			;
	ANDLW	0x0F				;
	CALL	DIGIT_SELECT			;
	MOVWF	TEMP_BYT0_B2			;Display units of minutes
	BTFSC	TEMP_BYT0_B2,0			;
	BSF	LCDDATA0,0			;4A
	BTFSC	TEMP_BYT0_B2,1			;
	BSF	LCDDATA3,0			;4B
	BTFSC	TEMP_BYT0_B2,2			;
	BSF	LCDDATA6,0			;4C
	BTFSC	TEMP_BYT0_B2,3			;
	BSF	LCDDATA9,0			;4D
	BTFSC	TEMP_BYT0_B2,4			;
	BSF	LCDDATA6,1			;4E
	BTFSC	TEMP_BYT0_B2,5			;
	BSF	LCDDATA0,1			;4F
	BTFSC	TEMP_BYT0_B2,6			;
	BSF	LCDDATA3,1			;4G
						;
	MOVLW	HIGH (DIGIT_SELECT)		;take care of paging and jump tables
	MOVWF	PCLATH				;
	SWAPF	MIN_VALUE,W			;
	ANDLW	0x0F				;
	CALL	DIGIT_SELECT			;Display tens of minute
	MOVWF	TEMP_BYT0_B2			;
	BTFSC	TEMP_BYT0_B2,0			;
	BSF	LCDDATA0,2			;3A
	BTFSC	TEMP_BYT0_B2,1			;
	BSF	LCDDATA3,2			;3B
	BTFSC	TEMP_BYT0_B2,2			;
	BSF	LCDDATA6,2			;3C
	BTFSC	TEMP_BYT0_B2,3			;
	BSF	LCDDATA9,2			;3D
	BTFSC	TEMP_BYT0_B2,4			;
	BSF	LCDDATA6,3			;3E
	BTFSC	TEMP_BYT0_B2,5			;
	BSF	LCDDATA0,3			;3F
	BTFSC	TEMP_BYT0_B2,6			;
	BSF	LCDDATA3,3			;3G
_COLON						;
	BTFSC	COLON				;
	BSF	LCDDATA9,4			;":"
_HOURS:						;
	BTFSS	HOURS				;
	GOTO	_1HR				;
	MOVLW	HIGH (DIGIT_SELECT)		;take care of paging and jump tables
	MOVWF	PCLATH				;
	MOVF	HOUR_VALUE,W			;
	ANDLW	0x0F				;
	CALL	DIGIT_SELECT			;
	MOVWF	TEMP_BYT0_B2			;Display units of hours
	BTFSC	TEMP_BYT0_B2,0			;
	BSF	LCDDATA0,4			;2A
	BTFSC	TEMP_BYT0_B2,1			;
	BSF	LCDDATA3,4			;2B
	BTFSC	TEMP_BYT0_B2,2			;
	BSF	LCDDATA6,4			;2C
	BTFSC	TEMP_BYT0_B2,3			;
	BSF	LCDDATA9,5			;2D
	BTFSC	TEMP_BYT0_B2,4			;
	BSF	LCDDATA6,5			;2E
	BTFSC	TEMP_BYT0_B2,5			;
	BSF	LCDDATA0,5			;2F
	BTFSC	TEMP_BYT0_B2,6			;
	BSF	LCDDATA3,5			;2G
						;
	MOVLW	HIGH (DIGIT_SELECT)		;take care of paging and jump tables
	MOVWF	PCLATH				;
	SWAPF	HOUR_VALUE,W			;
	ANDLW	0x0F				;
	CALL	DIGIT_SELECT			;Display tens of hours
	MOVWF	TEMP_BYT0_B2			;
	BTFSC	TEMP_BYT0_B2,0			;
	BSF	LCDDATA0,7			;1A
	BTFSC	TEMP_BYT0_B2,1			;
	BSF	LCDDATA3,7			;1B
	BTFSC	TEMP_BYT0_B2,2			;
	BSF	LCDDATA6,7			;1C
	BTFSC	TEMP_BYT0_B2,3			;
	BSF	LCDDATA9,6			;1D
	BTFSC	TEMP_BYT0_B2,4			;
	BSF	LCDDATA6,6			;1E
	BTFSC	TEMP_BYT0_B2,5			;
	BSF	LCDDATA0,6			;1F
	BTFSC	TEMP_BYT0_B2,6			;
	BSF	LCDDATA3,6			;1G
_1HR:						;
	BTFSC	ONEHR				;
	BSF	LCDDATA9,7			;1G
_3HR						;
	BTFSC	THREEHR				;
	BSF	LCDDATA10,0			;1G
_12HR						;
	BTFSC	TWELVEHR			;
	BSF	LCDDATA9,1			;1G
_TEMPERATURE					;
	BTFSS	TEMPETR				;
	GOTO	_LOCKED				;
						;
	MOVF	TMPTR_VALUE,W			;
	MOVWF	TEMP_BYT1_B2			;
_TEMPHIGH					;
	M_CMPL_JNE TMPTR_VALUE,.10,_TEMP_CONT	;
	MOVLW	.11				;If 10 display 'H'
	MOVWF	TEMP_BYT1_B2			;
_TEMP_CONT					;else normal temp 
	MOVLW	HIGH (DIGIT_SELECT)		;take care of paging and jump tables
	MOVWF	PCLATH				;
	MOVF	TEMP_BYT1_B2,W			;
	CALL	DIGIT_SELECT			;
	MOVWF	TEMP_BYT0_B2			;
	BTFSC	TEMP_BYT0_B2,0			;
	BSF	LCDDATA10,1			;5A
	BTFSC	TEMP_BYT0_B2,1			;
	BSF	LCDDATA7,1			;5B
	BTFSC	TEMP_BYT0_B2,2			;
	BSF	LCDDATA4,1			;5C
	BTFSC	TEMP_BYT0_B2,3			;
	BSF	LCDDATA1,1			;5D
	BTFSC	TEMP_BYT0_B2,4			;
	BSF	LCDDATA4,2			;5E
	BTFSC	TEMP_BYT0_B2,5			;
	BSF	LCDDATA10,2			;5F
	BTFSC	TEMP_BYT0_B2,6			;
	BSF	LCDDATA7,2			;5G
_LOCKED						;
	BTFSC	LOCKED				;
	BSF	LCDDATA1,0			;
_BATTERY					;
	BTFSC	BATTLOW				;
	BSF	LCDDATA1,2			;
_ON						;
	BTFSC	DEVON				;
	BSF	LCDDATA4,0			;
_OFF						;
	BTFSC	DEVOFF				;
	BSF	LCDDATA4,3			;
_BOOST						;
	BTFSC	BOOST				;
	BSF	LCDDATA7,0			;
_LCD_DONE:					;
	M_BANKSEL_0				;
	RETURN					;
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;INPUT: 	W in binary
;OUTPUT:	W in BCD
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Convert_to_BCD					;
	CLRF	TEMP_BYT0_B0			;bank 0
LOOP_BCD:					;
	ADDLW	-.10				;
	BTFSS	STATUS,C			;
	GOTO	SWAPBCD				;
	INCF	TEMP_BYT0_B0,F			;
	GOTO	LOOP_BCD			;
SWAPBCD:					;
	ADDLW	.10				;
	SWAPF	TEMP_BYT0_B0,F			;
	IORWF	TEMP_BYT0_B0,W			;
	RETURN					;
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Called from hcs_tx.inc at the end of every message sent.
;Do and A/D conversion to test the battery voltage and decide its
;charge state
;**********************************************************
TEST_BATTERY					;
	BSF	GO_DONE				;start conversion
_ADCON_GO					;
	BTFSC	GO_DONE				;
	GOTO	_ADCON_GO			;
						;
	NOP					;
	BSF	KB0				;
	BCF	F_BODY_GUARD			;
	NOP					;
	M_CMPL_JG ADRESH,BATT_HIGH_THRESHLD,_BATTERY_OK;
	M_CMPL_JG ADRESH,BATT_LOW_THRESHLD,_BATTERY_WARNING;
						;
_BATTERY_LOW					;
	MOVF	BAT_OFF_MSG_COUNT,F		;initialized to one at restart, send this messag from
	BTFSC	STATUS,Z			;  here only once, than the machine is shutoff anyways
	GOTO	_TESTBATT_DONE			;
	CALL	DEVICE_OFF			;
	BSF	BATTLOW				;turn on the LOWBATT symbol, no blink
	BCF	MINUTES				;turn off hours and minutes also
	BCF	HOURS				;
	BSF	BATTERY_LOW			;
	BCF	BATTERY_WARN			;
	BSF	LCD_UPD				;
	DECF	BAT_OFF_MSG_COUNT,F		;
	GOTO	_TESTBATT_DONE			;
_BATTERY_WARNING				;
	BSF	BATTERY_WARN			;
	BCF	BATTERY_LOW			;
	MOVLW	BLINK_PERIOD			;
	MOVWF	BATTERY_BLINK_COUNT		;
	GOTO	_TESTBATT_DONE			;
						;
_BATTERY_OK					;
	BCF	BATTLOW				;
	BCF	BATTERY_WARN			;
	BCF	BATTERY_LOW			;
	BSF	LCD_UPD				;
						;
_TESTBATT_DONE					;
	MOVLW	IDLE_BATTERY_TEST		;in all cases reload the idle counter
	MOVWF	IDLE_BATT_COUNT			;
	RETURN					;
;**********************************************************
;Called during interrupts, message is being sent, start the converter
;**********************************************************
AD_START					;
	SET	F_BODY_GUARD			;
	BCF	KB0				;
	BSF	ADCON0,0			;START ADCONVERTER
	RETURN					;
;**********************************************************
CLEAR_RAM_0
	MOVLW	01FH		;INIZIO RAM -1
	MOVWF	FSR

PR	INCF	FSR,F
	CLRF	INDF
	MOVLW	07FH		;FINE RAM
	XORWF	FSR,W
	SKPZ
	B	PR

	RETURN
;******** PULIZIA RAM BANK1 *****************************************
CLEAR_RAM_1
	MOVLW	09FH		;INIZIO RAM -1
	MOVWF	FSR

PURA1	INCF	FSR,F
	CLRF	INDF
	MOVLW	0EFH		;FINE RAM
	XORWF	FSR,W
	SKPZ
	B	PURA1

	RETURN
;**********************************************************
ORG_INCLUDES:
	#include	<hcs_tx.inc>


;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Jump table selection of Serial Number digits (28sb)
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	;ATTENTION: END OF PAGE 1

	org	0x7FC		;lookout this OFFSET is fixed!!!!!!!!
GET_SERIAL_3	RETLW	0xA8	;serial number (lsb)
GET_SERIAL_2	RETLW	0xCB	;serial number
GET_SERIAL_1	RETLW	0xED	;serial number
GET_SERIAL_0	RETLW	0x0F	;low nibble only: msb serial number


	org	0x800
	NOP
	
	END                       ; directive 'end of program'
