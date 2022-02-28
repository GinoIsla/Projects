;----------------------------------------------------------------
;Receiver / Base for an electric blanket.  
;Funtions:	Recieve commands from the TX, Drive the PWMs for the heating elements 
;			and the buzzer, read the NTS feedback for regulation
;
; Created: 		21-10-2005	Version 1.0
; Clock:		4Mhz with PWMs running at 31KHz and 4Hz
; IDE: 			MPLAB v7.20
;----------------------------------------------------------------
;	list		p=16f873			; list directive to define processor not used in 7.2



	__IDLOCS	0110	;1.1.0


;#DEFINE	PIC16F73
#DEFINE	PIC16F873
;#DEFINE	PIC16F873A

	IFDEF	PIC16F73
	#include	<P16F73.inc>		; processor specific variable definitions	
ADRESH	EQU	ADRES
	__CONFIG	_CP_ALL&_WDT_ON&_BODEN_ON&_PWRTE_ON&_HS_OSC&_PWRTE_ON
	ENDIF

	IFDEF	PIC16F873
	#include	<P16F873.inc>		; processor specific variable definitions
	__CONFIG	_CP_ALL&_WDT_ON&_BODEN_ON&_PWRTE_ON&_HS_OSC&_PWRTE_ON&_LVP_OFF&_DEBUG_OFF&_CPD_OFF
	ENDIF

	IFDEF	PIC16F873A
	#include	<P16F873A.inc>		; processor specific variable definitions
	__CONFIG	_CP_ALL&_WDT_ON&_BODEN_ON&_PWRTE_ON&_HS_OSC&_PWRTE_ON&_LVP_OFF&_DEBUG_OFF&_CPD_OFF
	ENDIF

	#include	<Macros.inc>
	#include	<UTENZA.INC>
	#include	<RXHeader.h>

;+++++++++++++  see includes at the bottom of this code ++++++++++
;	#include	<receive.inc>
;	#include	<J_EEPROM.inc>
;+++++++++++++  see includes at the bottom of this code ++++++++++
	
	ERRORLEVEL -302

;****** MICRO MACRO *******************************************
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

;#DEFINE	RF_RX	PORTB,0 (IN HEADER FILE)
#DEFINE	_GIE	INTCON,GIE
#DEFINE	RF	RF_RX
#DEFINE	BITIN	FLAGS_RX,0
#DEFINE	RECEIVED FLAGS_RX,1

;A/D conversion
MASK_ADCON0	EQU	81H		; 10=Fosc/32,00.0=Analogue inp chan is AN0 (RA0), 0=go/done, 1=AD on
MASK_ADCON1	EQU	05H		; ...101 = Vref in RA3, RA2=D, RA1=A, RA0=A (selected input for AD in ADCON0)

#define GO__DONE	ADCON0,2	;


;***** VARIABLE DEFINITIONS
		CBLOCK	020H				;BANK 0
TEMP_BYT0				;reusable byte
TEMP_BYT1				;reusable byte
FLAGS1					;miscellaneous flags
FLAGS2					;miscellaneous flags
FLAGS3					;
SECONDS					;
LEARN_COUNTER				;60 seconds learning period

SERIAL_LEFT_1H				;
SERIAL_LEFT_2				;
SERIAL_LEFT_3				;
SERIAL_LEFT_4L				;serial number of remote (LEFT or both)
					;
SERIAL_RIGHT_1H				;
SERIAL_RIGHT_2				;
SERIAL_RIGHT_3				;
SERIAL_RIGHT_4L				;
					;	"		"		"		RIGHT
FIRST_MSG_1H				;
FIRST_MSG_2				;
FIRST_MSG_3				;
FIRST_MSG_4				;
FIRST_MSG_5				;
FIRST_MSG_6L				;

LEARN_MESSAGE_COUNT		;number of received LEARN messages 
TEMP_MESSAGE_COUNT		;number of received TEMPERATURE messages 

TEMPERATURE_SETTING_L	;
TEMPERATURE_SETTING_R	;
BUZZ_COUNT				;period for the buzzer
RT_SECONDS				;
;RT_MINUTES				;
REFRESH_COUNT_L				;
REFRESH_COUNT_R				;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
ADDRESS					;variables used by J_EEPROM.INC
EE_ADDR					;
EE_DATA					;
TMP2					;
TMP1					;
COUNTER					;
PC_OFFSET				;
EEBYTE					;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CNT0					;Variables used by receive.inc
CNT1					;
CNT2					;
TMP_CNT					;
BUFFER1					;received data
BUFFER2					;	"
BUFFER3					;	"
BUFFER4					;	"
BUFFER5					;	"
BUFFER6					;	"
FLAGS_RX				;	"
SECOND_MSG_COUNTER		;
OTHER					;
BEEP_COUNT				;
LAST					;
	ENDC

	IF	LAST > 0x6F
	ERROR:"RAM OUT OF BOUNDS!!"
	ENDIF

;SERIAL_LEFT	EQU	SERIAL_LEFT_1H
;SERIAL_RIGHT	EQU	SERIAL_RIGHT_1H
;FIRST_MSG	EQU	FIRST_MSG_1H

		CBLOCK	070H				;COMMON BANK
w_temp					; variable used for context saving
w1_temp					; variable used for context saving
status_temp				; variable used for context saving
		ENDC

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	ORG	0x000					; processor reset vector
	CLRF	PCLATH					;
	CLRF	STATUS					; BANK 0 REGISTERS
  	goto	MAIN					; go to beginning of program
							;
	ORG		0x004				; interrupt vector location
;	goto	Service_Interrupt			;
							;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Temperature conversion table.
;IN:	W = level code
;OUT:	W = PWM duty cycle
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
TEMP_SELECT						;
	ADDWF	PCL,F					;
	RETLW	.0					;
	RETLW	.6					;
	RETLW	.8					;
	RETLW	.10					;
	RETLW	.12					;
	RETLW	.14					;
	RETLW	.16					;
	RETLW	.18					;
	RETLW	.20					;
	RETLW	.22					;
	RETLW	.24					;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
MAIN:							;
	CLRWDT						;
	CALL	CLEAR_RAM_0				;
	CLRF	INTCON					;No interrupts
	CLRF	PORTA					;
	CLRF	PORTB					;
	LW	030H						;
	MOVWF	PORTC					;CANC_ALARM_AFT1 & CANC_ALARM_AFT2;
							;
;A/D CONVERTER						;
;=============						;
	MOVLW	b'10000001'				;Conversion Clock=fosc/32 (ADCON1<6> must be 0 for this work properly with 18F873A)
	MOVWF	ADCON0					;  bits<5..3> select analogue channel AN0, A/D converter ON
							;
	BANK1						;
	MOVLW	b'00000101'				;VREF=AN3, AN0,AN1=analogue inputs (in 16f873A -> fosc/32,left justif = read result in ADRESH) 
	MOVWF	ADCON1					;
;PORTS							;
;=====							;
	MOVLW	MASKA					;RA0=AN0,RA1=AN1
	MOVWF	TRISA					;
							;
	MOVLW	MASKB					;
	MOVWF	TRISB					;
							;
	MOVLW	MASKC					;
	MOVWF	TRISC					;
							;
	BANK0						;
	CLRF	PORTA					;
	CLRF	PORTB					;
	LW	030H					;
	MOVWF	PORTC					;CANC_ALARM_AFT1 & CANC_ALARM_AFT2
							;
;INTERRUPTS						;
;==========						;
	BANK1						;
	CLRF	PIE1					;
	CLRF	PIE2					;
	MOVLW	b'10001110'				;OPTION<6>=0=int on falling edge RB0, PS assigned to WDT
	MOVWF	OPTION_REG				;PortB pullups disabled
;PWD D/A & TIMER2					;
;================					;
	BANK0						;
	MOVLW	b'00001100' 				;bits 3-0=PWM mode (pg. 62)
	MOVWF	CCP1CON					;
	MOVWF	CCP2CON					;
	MOVLW	b'00000100'				;
	MOVWF	T2CON					;PRESCALE and POSTSCALE 1:1, TMR2 on
							;
	CLRF	CCPR1L					;
	CLRF	CCPR2L					;
							;
	BANK1						;
	MOVLW	PR2_HEAT_PERIOD				;value for 31,25MHz PWM freq at 4MHz Fosc - heater -
	MOVWF	PR2					; (.249 for the beeper)
	BANK0						;
							;
	CLRF	PIR1					;
	CLRF	PIR2					;
;GET SERIAL NUMBERS					;
;==================					;
	MOVLW	0					;load the serial numbers of the commanding remotes
	MOVWF	ADDRESS					;
	CALL	EEREAD					;results in TEMP1 and TEMP2
							;
	BCF	LEFT_EXISTS				;
	BTFSC	TMP1,7					;empty slot?
	GOTO	_REMOTE_CONT				;IT SHOULD NEVER HAPPEN THAT THERE IS NO LEFT SIDE SERIAL BUT THERE IS A RIGHT
							;
	BSF	LEFT_EXISTS				;
							; SIDE SERIAL, SO WE WON'T READ THE RIGHT SIDE SERIAL
	MOVF	TMP1,W					;
	MOVWF	SERIAL_LEFT_1H				;
	MOVF	TMP2,W					;
	MOVWF	SERIAL_LEFT_2				;
							;
	MOVLW	2					;load the rest of the 4 byte address of the left side
	MOVWF	ADDRESS					;
	CALL	EEREAD					;results in TEMP1 and TEMP2
	MOVF	TMP1,W					;
	MOVWF	SERIAL_LEFT_3				;
	MOVF	TMP2,W					;
	MOVWF	SERIAL_LEFT_4L				;
							;
	MOVLW	0xFF					;default no right side
	MOVWF	SERIAL_RIGHT_1H				;
							;
_GET_NEXT						;
	MOVLW	4					;load the serial numbers of the commanding remotes
	MOVWF	ADDRESS					;
	CALL	EEREAD					;results in TEMP1 and TEMP2
							;
	BCF	RIGHT_EXISTS				;
	BTFSC	TMP1,7					;empty slot?
	GOTO	_REMOTE_CONT				;IT SHOULD NEVER HAPPEN THAT THERE IS NO LEFT SIDE SERIAL BUT THERE IS A RIGHT
							;
	BSF	RIGHT_EXISTS				;
							;
	MOVF	TMP1,W					;
	MOVWF	SERIAL_RIGHT_1H				;
	MOVF	TMP2,W					;
	MOVWF	SERIAL_RIGHT_2				;
							;
	MOVLW	6					;load the rest of the 4 byte address of the left side
	MOVWF	ADDRESS					;
	CALL	EEREAD					;results in TEMP1 and TEMP2
							;
	MOVF	TMP1,W					;
	MOVWF	SERIAL_RIGHT_3				;
	MOVF	TMP2,W					;
	MOVWF	SERIAL_RIGHT_4L				;
							;
_REMOTE_CONT						;
;TIMER1							;
;======							;
	MOVLW	HIGH (T1_100MS)				;
	MOVWF	TMR1H					;
	MOVLW	LOW (T1_100MS)				;
	MOVWF	TMR1L					;
							;
	MOVLW	T1CON_MASK				;
	MOVWF	T1CON					;

	CANC_ALARM_AFT1					;
	CANC_ALARM_AFT2					;
							;
	MOVLW	.10					;
	MOVWF	SECONDS					;
	MOVLW	LEARN_PERIOD				;
	MOVWF	LEARN_COUNTER				;
	BSF	F_START					;
							;
;-------------------------------------------------------------------------------------------
_MAIN_LOOP:						;
	CLRWDT						;
	CALL	RECEIVE					;
	CALL	PACKET_RECEIVED				;
	CALL	SERVE_REQUEST				;
	CALL	HANDLE_TIMERS				;
	CALL	CHECK_LIMITS_ERRORS			;
	CALL	DRIVE_PWM				;
	GOTO	_MAIN_LOOP				;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Received packet
;BUFFER1	BIT 7÷5		0		RESERVED, FORCED TO ZERO
;BUFFER1	BIT 4		0÷1		LEFT/RIGHT SIDE
;BUFFER1	BIT 3÷0		0÷F		SERIAL NUMBER HIGH
;BUFFER2	BIT 7÷0		00÷FF		SERIAL NUMBER
;BUFFER3	BIT 7÷0		00÷FF		SERIAL NUMBER
;BUFFER4	BIT 7÷0		00÷FF		SERIAL NUMBER LOW
;BUFFER5	BIT 7÷3		00÷0A		LEVEL CODE
;BUFFER5	BIT 2		0÷1		BEEPER
;BUFFER5	BIT 1		0-1		LEARN MODE ON/OFF
;BUFFER5	BIT 0		0		PADDING
;BUFFER6	BIT 7÷0		00÷FF		CHECKSUM
;
;This procedure validate all messages coming in. The following checks will be
;performed:
;1) For ALL messages:
;	a)valid checksum
;	b)reserved fields have their defualt values
;2) For LEARN messsages:	
;	a) that this program is within the learn period
;	b) that an arriving serial number FOR THE right SIDE is different than the 
;	recently learned LEFT side
;3) For TEMPERATURE messages: 	
;	a)that we have stored (from EEPROM or learned) a valid serial number
;	b)the temperature level is in range (0-10)
;	c)valid SERIAL number i.e. the serial number in this msg matches one of our's
;If the checks are passed, in the arriving burst of messages we will only store the
;first message. All others message in the train, will be compared to this one but we 
;will only accepted the Nth message (where N=predeternmined CAE number), the rest are 
;discarded
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PACKET_RECEIVED						;if packet received, analyze it
	BTFSS	RECEIVED				;
	GOTO	_END_PCKT				;
							;
	BCF	RECEIVED				;
	CLRF	TEMP_BYT0				;1.a) All messages verify the checksum
	MOVLW	BUFFER1					;
	MOVWF	FSR					;
	MOVLW	.5					;
	MOVWF	TEMP_BYT1				;
							;
_CHKSUM_LOOP						;
	MOVF	INDF,W					;
	ADDWF	TEMP_BYT0,F				;
	INCF	FSR,F					;
	DECFSZ	TEMP_BYT1,F				;
	GOTO	_CHKSUM_LOOP				;
							;
	MOVF	BUFFER6,W				;
	XORWF	TEMP_BYT0,W				;
	BTFSS	STATUS,Z				;
	GOTO	_END_PCKT				;checksum error, discard
							;
	MOVLW	b'11100000'				;1.b)Validate reserved fields
	ANDWF	BUFFER1,W				;
	SKPZ						;
	GOTO	_END_PCKT				;...invalid BUFFER1
	BTFSC	BUFFER5,0				;
	GOTO	_END_PCKT				;...invalid BUFFER5, PADDING bit
							;
;................................LEARN or TEMPERATURE...;
	BTFSS	BUFFER5,1				;Proceed with LEARN or TEMPERATURE message
	GOTO	_VALIDATE_TEMP_MESSAGE			;
							;
;...............................................LEARN...;
_VALIDATE_LEARN_MESASGE					;
	BTFSS	F_START					;2a) are we in the learn period?
	GOTO	_END_PCKT				;reject LEARN msg outside the learn period
							;LEARN is valid and we are in the learn period
	BTFSC	F_FIRST_MSG_RECEIVD			;
	GOTO	_OTHER_LEARN				;
							;
_FIRST_LEARN						;
	MOVLW	.1					;
	MOVWF	LEARN_MESSAGE_COUNT			;The first message is stored
	CALL	SAVE_MSG				;
	GOTO	_CHK_LEARN_SERVE			;See if this is the msg to be served
							;
_OTHER_LEARN						;
	MOVLW	FIRST_MSG_1H				;This is not the first message, make sure this new message
	MOVWF	FSR					;is the same, if its not, start a new count.
	MOVLW	.6					;	
	CALL	COMPARE_MSG_STR				;
	BTFSS	F_MATCH					;
	GOTO	_NEW_MSG_NOT_MATCHED			;
	INCF	LEARN_MESSAGE_COUNT,F			;
	INCF	LAST,F					;debug only
							;
_CHK_LEARN_SERVE					;
	MOVLW	SECOND_MSG_PERIOD			;re-start the inter-msg timer whenever a msg is counted
	MOVWF	SECOND_MSG_COUNTER			;
	M_CMPL_JE LEARN_MESSAGE_COUNT, NTH_LEARN_MSG, _SERVE_LEARN
	GOTO	_END_PCKT				;the count is either not reached or exceeded, discard
							;
_SERVE_LEARN						;
	BTFSS	F_LEFT_SIDE				;2b) if the arrived serial number must be saved for the right SIDE 
	GOTO	_LEARN_CONT1				; then it must be different than the LEFT side
	MOVLW	SERIAL_LEFT_1H				;
	MOVWF	FSR					;
	MOVLW	.4					;
	CALL	COMPARE_MSG_STR				; 
	BTFSC	F_MATCH					;
	GOTO	_END_PCKT				;
							;
_LEARN_CONT1						;
	BSF	F_LEARN					;
	BSF	F_PKT_ACT_PENDING			;
	GOTO	_END_PCKT				;LEARN message ready
							;
;.........................................TEMPERATURE...;
_VALIDATE_TEMP_MESSAGE					;Validate serial number
	BTFSS	LEFT_EXISTS				;3.a) do we have at least 1 valid serial number?
	GOTO	_END_PCKT				;NO, no LEARN messages received
							;
	BTFSC	F_FIRST_MSG_RECEIVD			;
	GOTO	_MATCH_NEW_TEMP_MSG			;The first message is stored already?
							;
	MOVF	BUFFER5,W				;3.b) temperature level in range?
	MOVWF	TEMP_BYT0				;
	RRF	TEMP_BYT0,F				;
	RRF	TEMP_BYT0,F				;
	RRF	TEMP_BYT0,W				;
	ANDLW	0x1F					;
	MOVWF	TEMP_BYT0				;
	M_CMPL_JL TEMP_BYT0,.11,_VALID_TEMP		;
	GOTO	_END_PCKT				;TEMPRT message reject, temp level out of range
							;
_VALID_TEMP						;This is the first temprt msg, check it
	MOVLW	SERIAL_LEFT_1H				;3.c) do we recognize the serial number? 
	MOVWF	FSR					;
	MOVLW	.4					;	
	CALL	COMPARE_MSG_STR				;
	BTFSS	F_MATCH					;
	GOTO	_CHK_RIGHT				;didn't match, see if RIGHT matches
	BSF	LEFT_RECEIVED				;
	GOTO	_VAL_SERIAL_MATCH			;if the RIGTH serial doesn't match, check the left
_CHK_RIGHT						;
	MOVLW	SERIAL_RIGHT_1H				;
	MOVWF	FSR					;
	MOVLW	.4					;	
	CALL	COMPARE_MSG_STR				;
	BTFSS	F_MATCH					;
	GOTO	_END_PCKT				;(message reject, no matches)
	BSF	RIGHT_RECEIVED				;
							;
_VAL_SERIAL_MATCH					;
	MOVLW	.1					;
	MOVWF	TEMP_MESSAGE_COUNT			;1ST message received
	CALL	SAVE_MSG				;
	GOTO	_CHK_TEMPRT_SERVE			;See if this is the msg to be served
							;
_MATCH_NEW_TEMP_MSG					;
	MOVLW	FIRST_MSG_1H				;This is not the first temprt message, make sure this new one
	MOVWF	FSR					;is the same, if its not, start a new count.
	MOVLW	.6					;	
	CALL	COMPARE_MSG_STR				;
	BTFSS	F_MATCH					;
	GOTO	_NEW_MSG_NOT_MATCHED			;
	INCF	TEMP_MESSAGE_COUNT,F			;
							;
_CHK_TEMPRT_SERVE					;
	MOVLW	SECOND_MSG_PERIOD			;re-start the inter-msg timer each time a new msg is counted
	MOVWF	SECOND_MSG_COUNTER			;
	M_CMPL_JE TEMP_MESSAGE_COUNT, NTH_TEMPR_MSG, _SERVE_TEMPR
	GOTO	_END_PCKT				;the count is either not reached or exceeded, discard
_SERVE_TEMPR						;
	BCF	F_LEARN					;...just in case
	BSF	F_PKT_ACT_PENDING			;
	GOTO	_END_PCKT				;LEARN message ready
;.......................................................;
							;
_NEW_MSG_NOT_MATCHED					;
	CLRF	TEMP_MESSAGE_COUNT			;
	CLRF	LEARN_MESSAGE_COUNT			;this new messages didn't match a previous one, 
	BCF	F_FIRST_MSG_RECEIVD			;start over
	GOTO	PACKET_RECEIVED				;treat it as new
;.......................................................;	
_END_PCKT						;
	RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Save the received message in FIRST_MSG 
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SAVE_MSG						;
	INCF	OTHER,F					;debug only
	BSF	F_FIRST_MSG_RECEIVD			;
	MOVF	BUFFER1,W				;save it
	MOVWF	FIRST_MSG_1H				;
	MOVF	BUFFER2,W				;
	MOVWF	FIRST_MSG_2				;
	MOVF	BUFFER3,W				;
	MOVWF	FIRST_MSG_3				;
	MOVF	BUFFER4,W				;
	MOVWF	FIRST_MSG_4				;
	MOVF	BUFFER5,W				;
	MOVWF	FIRST_MSG_5				;
	MOVF	BUFFER6,W				;
	MOVWF	FIRST_MSG_6L				;
							;
	BTFSC	BUFFER5,2				;
	BSF	F_BEEP					;
	RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;The message has been accepted and checked, now use it
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SERVE_REQUEST						;
	BTFSC	F_PWM_BUZZ				;don't start any jobs until the buzzer is finished beeping
	GOTO	_REQ_END				;(F_PWM_BUZZ is reset at timeout)
							;
	BTFSS	F_PKT_ACT_PENDING			;The buzzer is not beeping (either finished or didn't have to)
	GOTO	_REQ_END				; now proceed to unpack the pending message 
							;
	BTFSS	F_LEARN					;
	GOTO	_SRV_TEMP				;serve the corresponding message
							;
_SRV_LEARN						;
	CALL	UNPACK_LEARN				;
	GOTO	_REQ_END				;
_SRV_TEMP						;
	CALL	TEMPERATURE_MSG				;
_REQ_END						;
	RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Performs an A/D conversion to see if the tempertature has exceeded the limits and
;tests the alarms coming from the AFT module.  In any case, wether we axceed the limits
;or have AFT alarms, we shut-off the corresponding sides.
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CHECK_LIMITS_ERRORS					;
	BSF	ADCON0,GO				;start conversion


_ADCON_GO						;
	BTFSC	ADCON0,GO				;
	GOTO	_ADCON_GO				;

	BTFSC	F_EMERGENCY				;if there was an emergency before...
	GOTO	_NO_EMGCY_LIMIT				;check the hysteresis
							;

_EMGCY_LIMIT
	NOP
	M_CMPL_JL ADRESH,MAX_READING,_EMGCY_LIMIT_X	;there is an emergency with the limits

	BSF	F_EMERGENCY				;
	BSF	F_UPDATE_PWM				;
	BSF	F_PWM_LEFT				;
	BSF	F_PWM_RIGHT				;
	GOTO	_EMGCY_LIMIT_X				;


_NO_EMGCY_LIMIT						;
	NOP
	M_CMPL_JG ADRESH,MIN_READING,_ALM_FIN		;AD result under the limit ?
							;no, jumps others check
	BCF	F_EMERGENCY				;ya, clear emergency...
	BSF	F_UPDATE_PWM				;...update pwm
	BSF	F_PWM_LEFT				;
	BSF	F_PWM_RIGHT				;


_EMGCY_LIMIT_X
					;


_AFT1	BTFSS	AFT1_ERROR				;
	GOTO	_NO_AFT1_ERROR				;
							;
	BTFSC	F_EMERG_AFT1				;AFT1 emergency, report only if no other emergency
	GOTO	_AFT2					;is the emergency already reported?

	SET_ALARM_AFT1					;If there is an AFT1 alarm (AFT2 see below), set the flags neessary for
	BSF	F_EMERG_AFT1				; - emergency shutoff of the left (right) side
	BSF	F_UPDATE_PWM				; - F_EMERG_AFT1 flag so that when the alarm ceases the original temperatures is restored
	BSF	F_PWM_LEFT				; - the left (right) side to be updated
	GOTO	_AFT2					;


_NO_AFT1_ERROR						;
	BTFSS	F_EMERG_AFT1				;
	GOTO	_AFT2					;
							;
	BCF	F_EMERG_AFT1				;
	CANC_ALARM_AFT1					;
	BSF	F_PWM_LEFT				;
	BSF	F_UPDATE_PWM				;
							;

_AFT2	BTFSS	AFT2_ERROR				;
	GOTO	_NO_AFT2_ERROR				;
							;
	BTFSC	F_EMERG_AFT2				;AFT2 emergency, report only if no other emergency
	GOTO	_ALM_FIN				;is the emergency already reported?

	SET_ALARM_AFT2					;
	BSF	F_EMERG_AFT2				;
	BSF	F_UPDATE_PWM				;
	BSF	F_PWM_RIGHT				;
	GOTO	_ALM_FIN				;


_NO_AFT2_ERROR						;
	BTFSS	F_EMERG_AFT2				;
	GOTO	_ALM_FIN				;

	BCF	F_EMERG_AFT2				;
	CANC_ALARM_AFT2					;
	BSF	F_PWM_RIGHT				;
	BSF	F_UPDATE_PWM				;

							;
_ALM_FIN						;
	RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;See if the buzzer has to beep
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
TEST_BUZZER						;
	MOVWF	BEEP_COUNT
	RLF	BEEP_COUNT,F
	DECF	BEEP_COUNT,F

	BTFSS	F_BEEP					;see if we have to beep 
	GOTO	_NO_BUZZ				;
							;
	BCF	F_BEEP					;make sure we beep only once
	BSF	F_PWM_BUZZ				;
	BSF	F_UPDATE_PWM				;
	MOVLW	BUZZ_PERIOD				;
	MOVWF	BUZZ_COUNT				;
_NO_BUZZ						;
	RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;All serial numbers have been checked.  At this point we know we will heat 1 or both
;sides depending on the flags set.
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
TEMPERATURE_MSG						;
	BTFSS	LEFT_EXISTS				;
	GOTO	_HEAT_NONE				;
							;
	BTFSS	LEFT_RECEIVED				;
	GOTO	_CHECK_RIGHT_SIDE			;
							;
	BTFSS	RIGHT_EXISTS				;does this serial command both sides (i.e. no right side)?
	GOTO	_HEAT_BOTH				;
	GOTO	_HEAT_LEFT				;
							;

_CHECK_RIGHT_SIDE					;
	BTFSS	RIGHT_EXISTS				;
	GOTO	_HEAT_NONE				;
							;
	BTFSS	RIGHT_RECEIVED				;
	GOTO	_HEAT_NONE				;
							;
	GOTO	_HEAT_RIGHT				;
							;

_HEAT_BOTH						;
	MOVLW	N_NORMAL_BEEP
	BTFSC	F_EMERGENCY
	MOVLW	N_ALARM_BEEP

	BTFSC	F_EMERG_AFT1
	MOVLW	N_ALARM_BEEP

	BTFSC	F_EMERG_AFT2
	MOVLW	N_ALARM_BEEP

	CALL	TEST_BUZZER				;If we need to buzz first we abandon this procedure till buzzing is finished
	BTFSC	F_PWM_BUZZ				;
	GOTO	_HEAT_FIN				;
							;
	CALL	UNPACK_TEMP				;
	MOVWF	TEMPERATURE_SETTING_L			;both sides same temperature
	MOVWF	TEMPERATURE_SETTING_R			;
	BSF	F_PWM_LEFT				;
	BSF	F_PWM_RIGHT				;
	MOVLW	REFRESH_PERIOD				;
	MOVWF	REFRESH_COUNT_L				;
	MOVWF	REFRESH_COUNT_R				;
	BSF	F_UPDATE_PWM				;
	BCF	LEFT_RECEIVED				;
	BCF	RIGHT_RECEIVED				;
	GOTO	_HEAT_NONE				;


_HEAT_LEFT						;
	MOVLW	N_NORMAL_BEEP
	BTFSC	F_EMERGENCY
	MOVLW	N_ALARM_BEEP

	BTFSC	F_EMERG_AFT1
	MOVLW	N_ALARM_BEEP

	CALL	TEST_BUZZER				;If we need to buzz first we abandon this procedure till buzzing is finished
	BTFSC	F_PWM_BUZZ				;
	GOTO	_HEAT_FIN				;
							;
	CALL	UNPACK_TEMP				;
	MOVWF	TEMPERATURE_SETTING_L			;
	BSF	F_PWM_LEFT				;
	BSF	F_UPDATE_PWM				;
	MOVLW	REFRESH_PERIOD				;
	MOVWF	REFRESH_COUNT_L				;
	BCF	LEFT_RECEIVED				;
	GOTO	_HEAT_NONE				;


_HEAT_RIGHT						;
	MOVLW	N_NORMAL_BEEP
	BTFSC	F_EMERGENCY
	MOVLW	N_ALARM_BEEP

	BTFSC	F_EMERG_AFT2
	MOVLW	N_ALARM_BEEP

	CALL	TEST_BUZZER				;If we need to buzz first we abandon this procedure till buzzing is finished
	BTFSC	F_PWM_BUZZ				;
	GOTO	_HEAT_FIN				;

	CALL	UNPACK_TEMP				;
	MOVWF	TEMPERATURE_SETTING_R			;
	BSF	F_PWM_RIGHT				;
	BSF	F_UPDATE_PWM				;
	MOVLW	REFRESH_PERIOD				;
	MOVWF	REFRESH_COUNT_R				;
	BCF	RIGHT_RECEIVED				;
							;

_HEAT_NONE						;
	BCF	F_PKT_ACT_PENDING			;


_HEAT_FIN						;
	RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Drive the PWM ports (left, right or buzzer)
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DRIVE_PWM						;
	BTFSS	F_UPDATE_PWM				;
	GOTO	_PWM_FIN				;
							;
	BCF	F_UPDATE_PWM				;
	BTFSS	F_PWM_LEFT				;
	GOTO	_PWM_RIGHT				;

	BANK1						;LEFT side
	MOVLW	PR2_HEAT_PERIOD				;
	MOVWF	PR2					;
	BANK0						;
	BTFSC	F_EMERGENCY				;
	GOTO	_EMGCY_L				;

	BTFSS	F_EMERG_AFT1				;
	GOTO	_NO_EMGCY_L				;


_EMGCY_L						;
	MOVLW	0					;
	GOTO	_PWM_L_CONT				;


_NO_EMGCY_L						;
	MOVF	TEMPERATURE_SETTING_L,W			;LSBs in CCP1CON/CCP2CON are already cleared (pic16F873)


_PWM_L_CONT						;
	MOVWF	CCPR1L					;
	BCF	F_PWM_LEFT				;
							;

_PWM_RIGHT						;
	BTFSS	F_PWM_RIGHT				;PWM2 (RIGHT SIDE) shares the PWM pin with the BUZZER
	GOTO	_PWM_BUZZER				;

	BCF	F_PWM_BUZZ				;(make sure BUZZER is not activated if we're activating the right side)
							;
	BANK1						;
	BSF	TRISC_ENAPWM2				;2) switch the PWM2_ENABLE port to input (remains high - enabled)
	MOVLW	PR2_HEAT_PERIOD				;
	MOVWF	PR2					;
	BANK0						;
	BCF	ENA_BUZZ				;sequence for enabling PMW2
	BANK1						;1) switch buzzer port to output and set the port low (disabled)
	BCF	TRISC_ENABUZZ				;
	BANK0						;
	BCF	ENA_BUZZ				;
	BTFSC	F_EMERGENCY				;
	GOTO	_EMGCY_R				;

	BTFSS	F_EMERG_AFT2				;
	GOTO	_NO_EMGCY_R				;


_EMGCY_R						;
	MOVLW	0					;
	GOTO	_PWM_R_CONT				;


_NO_EMGCY_R						;
	MOVF	TEMPERATURE_SETTING_R,W			;LSBs in CCP1CON/CCP2CON are already cleared (pic16F873)


_PWM_R_CONT						;
	MOVWF	CCPR2L					;
	BCF	F_PWM_RIGHT				;
	GOTO	_PWM_FIN				;

							;
_PWM_BUZZER						;
	BTFSS	F_PWM_BUZZ				;
	GOTO	_PWM_FIN				;
							;
	BANK1						;
	BSF	TRISC_ENABUZZ				;
	MOVLW	PR2_BUZZ_PERIOD				;
	MOVWF	PR2					;
	BANK0						;
	BCF	ENA_PW2					;
	BANK1						;turn off PWM2-RIGHT side enable and turn on buzzer enable
	BCF	TRISC_ENAPWM2				;usign the same sequence as above
	BANK0						;
	BCF	ENA_PW2					;
	MOVLW	(PR2_BUZZ_PERIOD+1)/2	;50% duty cycle	;
	MOVWF	CCPR2L					;
	CLRF	CCPR1L					;


_PWM_FIN						;
	BSF	T2CON,2					;make sure TMR2 is on
	RETURN						;
;**********************************************************************


;**********************************************************************
;See if the packet received is a learn message.  If it is, store the serial
;number in either the first (LEFT side) or second (RIGHT side)
;The rules for storing the serial number are:
;0. An empty entry in EEPROM is denoted by a high msb in the byte that holds the high part
;	of the serial number (i.e. b'1xxxXXX)
;1. The first serial number received during F_START is stored in the first position if
;	it is different than the number already stored there.
;2. Upon reception of the first (LEFT) serail number, the second (RIGHT) position is set to EMPTY
;3. If a second LEARN message arrives during F_START, it gets stored in the second position (RIGHT)
;	regardless of whether there was a another or the same number stored there.
;4. The LEARN period ends (a) if a second LEARN message is received snf (b) at timeout of the learn
;	period.
;5. If a second LEARN does not arrive, the second position is left empty and this base
;	will use the same heat settigns for both sides.
;6. EEPROM is read like this:
;	ADDRESS 0: 4 bytes LEFT serial number
;	ADDRESS 4: 4 bytes RIGTH serial number
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
UNPACK_LEARN						;
	LW	N_LEARN_BEEP
	CALL	TEST_BUZZER				;sets up buzzer flags
							;
	BCF	F_LEARN					;
							;
	BTFSS	F_LEFT_SIDE				;did we write the first of the remotes?
	GOTO	_FILL_LEFT				;(we use a flag instead of SERIAL_LEFT,7 so we can overwrite a SERIAL left number when we
	GOTO	_FILL_RIGHT				;   initialize)
							;
_FILL_LEFT						;Left is the first address
	MOVLW	0					;EEPROM addr 0,1
	MOVWF	ADDRESS					;
	MOVF	FIRST_MSG_1H,W				;
	ANDLW	0x0F					;IF WE TREAT LEFT/RIGHT INDICATIONS IN THE MESSAGE THIS IS WHERE THE CODE MUST BE INSERTED
	MOVWF	TMP1					;
	MOVWF	SERIAL_LEFT_1H				;fill also the serial numbers in RAM
	MOVF	FIRST_MSG_2,W				;
	MOVWF	TMP2					;
	MOVWF	SERIAL_LEFT_2				;serial numbers in RAM
	CALL	EEWRITE					;data in TEMP1 and TEMP2
							;
	MOVLW	2					;EEPROM addr 2,3
	MOVWF	ADDRESS					;
	MOVF	FIRST_MSG_3,W				;
	MOVWF	TMP1					;
	MOVWF	SERIAL_LEFT_3				;serial numbers in RAM
	MOVF	FIRST_MSG_4,W				;
	MOVWF	TMP2					;
	MOVWF	SERIAL_LEFT_4L				;serial numbers in RAM
	CALL	EEWRITE					;data in TEMP1 and TEMP2
							;
	MOVLW	4					;Cancel the address for the right side in EEPROM addr 4,5
	MOVWF	ADDRESS					;
	MOVLW	0xFF					;
	MOVWF	TMP1					;
	MOVWF	TMP2					;
	MOVWF	SERIAL_RIGHT_1H				;
	CALL	EEWRITE					;data in TEMP1 and TEMP2
							;
	BSF	F_LEFT_SIDE				;
	BSF	LEFT_EXISTS				;
	BCF	RIGHT_EXISTS				;
	BCF	F_LEARN					;
	GOTO	_LEARN_FIN				;
							;
_FILL_RIGHT						;
	MOVLW	4					;
	MOVWF	ADDRESS					;
	MOVF	FIRST_MSG_1H,W				;
	ANDLW	0x0F					;IF WE TREAT LEFT/RIGHT INDICATIONS IN THE MESSAGE THIS IS WHERE THE CODE MUST BE INSERTED
	MOVWF	TMP1					;
	MOVWF	SERIAL_RIGHT_1H				;fill also the serial numbers in RAM
	MOVF	FIRST_MSG_2,W				;
	MOVWF	TMP2					;
	MOVWF	SERIAL_RIGHT_2				;
	CALL	EEWRITE					;data in TEMP1 and TEMP2
							;
	MOVLW	6					;EEPROM addr 2,3
	MOVWF	ADDRESS					;
	MOVF	FIRST_MSG_3,W				;
	MOVWF	TMP1					;
	MOVWF	SERIAL_RIGHT_3				;
	MOVF	FIRST_MSG_4,W				;
	MOVWF	TMP2					;
	MOVWF	SERIAL_RIGHT_4L				;
	CALL	EEWRITE					;data in TEMP1 and TEMP2
							;we've memorized 2 commands, can't learn anymore
	BSF	RIGHT_EXISTS				;
	BCF	F_LEARN					;
	BCF	F_START					;end the earn period
							;
_LEARN_FIN						;
	BCF	F_PKT_ACT_PENDING			;
	RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;After inititalization, for 1 minute, we can receive the LEARN message
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
HANDLE_TIMERS						;
	BTFSS	PIR1,TMR1IF				;
	GOTO	_START_FIN				;
							;
	BCF	T1CON,TMR1ON				;
	BCF	PIR1,TMR1IF				;Reload TMR1	
	MOVLW	HIGH (T1_100MS)				;
	SUBWF	TMR1H,F					;
	MOVLW	LOW (T1_100MS)				;
	SUBWF	TMR1L,F					;
	SKPNB						;
	DECF	TMR1H,F					;
	BSF	T1CON,TMR1ON				;
;------------------------------------------------ milseconds tasks -----------
	BTFSS	F_FIRST_MSG_RECEIVD			;message burst finished?
	GOTO	_BUZZER_BEEPING				;
	DECFSZ	SECOND_MSG_COUNTER,F			;
	GOTO	_BUZZER_BEEPING				;

	BCF	F_FIRST_MSG_RECEIVD			;message burst MUST be finished

;------------------------------------------------ BUZZER ----------------------
_BUZZER_BEEPING						;
	MOVF	BUZZ_COUNT,F				;if zero, the buzzer is NOT beeping
	BTFSC	STATUS,Z				;
	GOTO	BUZZ_BEEP_X				;

	DECFSZ	BUZZ_COUNT,F				;
	GOTO	BUZZ_BEEP_X				;
							;
	DECF	BEEP_COUNT,F				;beeper counter decrease to zero ?
	SKPNZ
	B	_TURN_OFF_BUZZER			;ya, buzzer off

	MOVLW	BUZZ_PERIOD				;no,
	MOVWF	BUZZ_COUNT				;reload buzzer counter

	BTFSS	BEEP_COUNT,0				;beeper counter odd ?
	B	BUZZ_PAUSE				;no, pause

	MOVLW	(PR2_BUZZ_PERIOD+1)/2			;ya, reload with 50% duty cycle
	MOVWF	CCPR2L					;
	B	BUZZ_BEEP_X	


BUZZ_PAUSE
	MOVLW	0					;load with 0% duty cycle
	MOVWF	CCPR2L					;
	B	BUZZ_BEEP_X	


_TURN_OFF_BUZZER					;turn off buzzer and turn on PWM2
	BCF	F_PWM_BUZZ				;
	BSF	F_PWM_LEFT				;(this includes the alarmed state!)
	BSF	F_PWM_RIGHT				;
	BSF	F_UPDATE_PWM				;allow restoring of previous settings


BUZZ_BEEP_X
;-------------------------------------------------- seconds tasks -----------
_SECONDS_TASKS						;
	DECFSZ	SECONDS,F				;
	GOTO	_START_FIN				;
									;
_RELOAD_SEC							;
	MOVLW	.10						;
	MOVWF	SECONDS					;
									;
_ONE_SECOND_PASSED					;
	INCF	RT_SECONDS,F			;
									;
	BTFSS	F_START					;
	GOTO	_MINUTE_TASKS			;
	DECFSZ	LEARN_COUNTER,F			;
	GOTO	_MINUTE_TASKS			;
	BCF	F_START						;Learn period is over after 1 minute
									;
_MINUTE_TASKS						;
	M_CMPL_JL RT_SECONDS,.60,_START_FIN		;
	CLRF	RT_SECONDS				;
									;
_MIN_CONT							;
	DECFSZ	REFRESH_COUNT_L,F		;
	GOTO	_REFRESH_RIGHT			;If the bases's refresh timer expires, which is twice the refresh 
	BSF	F_PWM_LEFT					; period of the remote control, then it means that the
	CLRF	TEMPERATURE_SETTING_L	; remote control is out of order, we must turn the
	BSF	F_UPDATE_PWM				; blanket off
									;
_REFRESH_RIGHT						;
	DECFSZ	REFRESH_COUNT_R,F		;
	GOTO	_START_FIN				;
	BSF	F_PWM_RIGHT					;
	CLRF	TEMPERATURE_SETTING_R	;
	BSF	F_UPDATE_PWM				;
									;
_START_FIN						;
	RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Extract level code from the message and translate it to the PWM duty cycle
;OUTPUT:	W = tempertaure setting
;BUFFER5	BIT 7÷3		00÷0A	LEVEL CODE
;**********************************************************************
UNPACK_TEMP							;
	MOVF	FIRST_MSG_5,W			;
	MOVWF	TEMP_BYT0				;
	RRF		TEMP_BYT0,F				;
	RRF		TEMP_BYT0,F				;
	RRF		TEMP_BYT0,W				;
	ANDLW	0x1F					;
	MOVWF	TEMP_BYT0				;
	MOVLW	HIGH (TEMP_SELECT)		;take care of paging and jump tables
	MOVWF	PCLATH					;
	MOVF	TEMP_BYT0,W				;
	CALL	TEMP_SELECT				;W has the correct temperature
	RETURN							;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;INPUT:	FSR pointes to the data to be matched against the msg BUFFER
;	W has the number of bytes to be compared
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
COMPARE_MSG_STR						;
	MOVWF	TEMP_BYT0				;FSR -> data
	BCF	F_MATCH					;
							;
	MOVF	BUFFER1,W				;
	ANDLW	0x0F					;
	XORWF	INDF,W					;
	BTFSS	STATUS,Z				;
	GOTO	_SER_NO_MATCH				;	
	DECFSZ	TEMP_BYT0,F				;
	GOTO	_NEXT1					;
	GOTO	_SER_MATCH				;
							;
_NEXT1							;
	INCF	FSR,F					;
	MOVF	BUFFER2,W				;
	XORWF	INDF,W					;
	BTFSS	STATUS,Z				;
	GOTO	_SER_NO_MATCH				;	
	DECFSZ	TEMP_BYT0,F				;
	GOTO	_NEXT2					;
	GOTO	_SER_MATCH				;
							;
_NEXT2							;
	INCF	FSR,F					;
	MOVF	BUFFER3,W				;
	XORWF	INDF,W					;
	BTFSS	STATUS,Z				;
	GOTO	_SER_NO_MATCH				;	
	DECFSZ	TEMP_BYT0,F				;
	GOTO	_NEXT3					;
	GOTO	_SER_MATCH				;
							;
_NEXT3							;
	INCF	FSR,F					;
	MOVF	BUFFER4,W				;
	XORWF	INDF,W					;
	BTFSS	STATUS,Z				;
	GOTO	_SER_NO_MATCH				;	
	DECFSZ	TEMP_BYT0,F				;
	GOTO	_NEXT4					;
	GOTO	_SER_MATCH				;
							;
_NEXT4							;
	INCF	FSR,F					;
	MOVF	BUFFER5,W				;
	XORWF	INDF,W					;
	BTFSS	STATUS,Z				;
	GOTO	_SER_NO_MATCH				;	
	DECFSZ	TEMP_BYT0,F				;
	GOTO	_NEXT5					;
	GOTO	_SER_MATCH				;
							;
_NEXT5							;
	INCF	FSR,F					;
	MOVF	BUFFER6,W				;
	XORWF	INDF,W					;
	BTFSS	STATUS,Z				;
	GOTO	_SER_NO_MATCH				;	
							;
_SER_MATCH						;
	BSF	F_MATCH					;
_SER_NO_MATCH						;
		RETURN					;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Service_Interrupt
;	movwf	w_temp					; save off current W register contents
;	movf	STATUS,w				; move status register into W register
;	bcf		STATUS,RP0				; select bank0
;	movwf	status_temp				; save off contents of STATUS register
;
;; isr code can go here or be located as a call subroutine elsewhere
;
;	bcf		STATUS,RP0
;	movf	status_temp,w				; retrieve copy of STATUS register
;	movwf	STATUS					; restore pre-isr STATUS register contents
;	swapf	w_temp,f				;
;	swapf	w_temp,w				; restore pre-isr W register contents
;	retfie							; return from interrupt
;
;**********************************************************************
CLEAR_RAM_0						;
	MOVLW	01FH					;start RAM
	MOVWF	FSR					;
PR	INCF	FSR,F					;
	CLRF	INDF					;
	MOVLW	07FH					;end RAM
	XORWF	FSR,W					;
	SKPZ						;
	GOTO	PR					;
	RETURN						;
;******** PULIZIA RAM BANK1 *****************************************
	#include	<receive.inc>
	#include	<J_EEPROM.inc>

	END 		                      		; directive 'end of program'

