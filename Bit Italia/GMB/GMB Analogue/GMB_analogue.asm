;************************************************************
;	TITLE:	ECHO BUS multinodal control ----- Analogue Version (2 ports IN, 2 OUT)
;	Programmer: GINO ISLA for of BIT Srl.
;	REVISION HISTORY:	07-April-2004
;	LAST UPDATE:		GI:	13-05-2004:	Add dimmer function
;						GI:	6-12-2004 change microprocessor type (request by Vladimir)
;	FREQUENCY: 8MHz
;************************************************************
;			list	p=16f876
			list	p=16f877A

;#include	<p16f876.inc> 
#include	<p16f877A.inc>
;
#include 	<GMB_analogue.h>
#include	<macros.inc>

	__CONFIG	_CP_OFF&_WDT_ON&_BODEN_ON&_PWRTE_ON&_HS_OSC&_PWRTE_ON&_LVP_OFF&_DEBUG_OFF&_CPD_OFF
	ERRORLEVEL -302
	
	UDATA
;BASIC TIMERS
TIME_SCAN_TX		RES		1	;reduced timer to treat the msg TX QUE
TIME_SCAN_RX		RES		1	;reduced timer to treat the msg RX QUE
TIME_SAMPLES		RES		1	;reduced timer for periodic jobs
SND_STATS			RES		1	;used to derive the ONE second timer
DIMMER_TIMER		RES		1	;used as basic dimmer timer
SFTY_DIM_TIMR		RES		1	;stops the dimming if the OFF msg is lost
SAMPLE_TIMER_1		RES		1	;sample delay = 50ms*SAMPLE_TIMER_1*SAMPLE_TIMER_2
SAMPLE_TIMER_2		RES		1	;
;
STEPBACK			RES		1	;Number of steps to back off during end of dimming
;
FUNZIONE_ING_0		RES		1	;Programmed function for this port
FUNZIONE_ING_1		RES		1	;
;
;******* keep this block of variables together **************
FUNZIONE_USC_0		RES		1	;
ON_OFF_TIMER_0		RES		1	;ON/OFF timers
DIM_ACT_TIM_0		RES		1	;dimmer action timer and direction (BOOL,INT(7) PACK)
OUT_VAL0			RES		1	;Value to write to output port 1
STEPBACK_TIM_0		RES		1	;
;******* keep this block of variables together **************
;same as above port 1
FUNZIONE_USC_1		RES		1	;
ON_OFF_TIMER_1		RES		1	;
DIM_ACT_TIM_1		RES		1	;
OUT_VAL1			RES		1	;
STEPBACK_TIM_1		RES		1	;
;******* keep this block of variables together **************
;
SAMPLE_CNTR			RES		1	;
SAMPLES				RES		8	;readings obtained in last second (4 each IN-PORT)
;
;******* keep this block of variables together **************
REFERENCE_SAMPLE	RES		1	;avg of previous readings (INGRESSO 0)
REFERENCE_SAMPLE_1	RES		1	;avg of previous readings (INGRESSO 1)
STEP_A				RES		1	;(INGRESSO 0 - STEP WATCH)
STEP_A1				RES		1	;(INGRESSO 1 - STEP WATCH)
;;******* keep this block of variables together **************
;
LISTEN_TO_SRL		RES		1	;Serial number that drives outport
LISTEN_TO_SRL_1		RES		1	;
LISTEN_TO_PORT		RES		1	;port number (+Serial)that drives outport
LISTEN_TO_PORT_1	RES		1	;
;
BIT_0				RES		1	;length of a '0' bit
FLAGS0				RES 	1	;miscellaneous flags (see below)
FLAGS1				RES 	1	;miscellaneous flags (see below)
SEND_FLAGS			RES		1	;flags sent in message
;
OWN_SERIAL			RES		1	;These are the mirror registers of their equivalent in EEPROM
OWN_PROGRAM			RES		1	;program type
;
THRSHD_EX_PERIOD	RES		1	;timer to check thresholds
;
MSG_HEAD_EE			RES		1	;beginning of message to be read from EEPROM
;
PORT_IN				RES		1	;in-port general counter 
PORT_OUT			RES		1	;out-port general counter 
;
NBR_ENTRIES			RES		1	;nbr of entries in the qeueus
WAIT_BUS_CLEAR		RES		1	;wait period to get hold of the bus
;
;Variables starting with I_ are used ONLY during interrupts handling
I_STATUS_TEMP		RES		1	;save environment
I_FSR_TEMP			RES		1	;  "	"
I_TEMP_BIT			RES 	1	;general purpose bit hold during interrupt handling
I_TEMP_BYT0			RES		1	;general purpose byte hold during interrupt handling
I_NBR_BITS			RES		1	;general purpose bit counter during interrupt handling
I_NBR_BYTES			RES		1	;general purpose byte counter during interrupt handling
I_SUPERVISION		RES		1	;supervision of wait for IN_BUS status change
I_FREE_RX_Q			RES		1	;start of the free RX_QUEU entry
;
E2ADDRESS			RES		1	;address for EEPROM
E2VALUE				RES		1	;data to write in EEPROM
;
TX_MSG_START		RES		1	;Begining of a msg in the RX_QUEU
RX_MSG_START		RES		1	;Begining of a msg in the RX_QUEU
MSG_EXPIRE			RES		1	;number of mesage sends until expiration
MSG_TYPE			RES		1	;COMMAND TYPE
MSG_SUBT			RES		1	;COMMAND SUBTYPE
MSG_SERL			RES		1	;SERIAL NUMBER
MSG_DISC			RES		1	;DISCRIMINATOR
MSG_ARGT			RES		1	;ARGUMENT
TEMP_SC				RES		1	;byte to hold SC
KEY_TO_PORT			RES		1	;For VISUALIZZAZIONE, to drive the opposing port to this key
SAVE_SAMPLE_TIM_1	RES		1	;Copy of EE_SAMPLE_TIMER_1
SAVE_SAMPLE_TIM_2	RES		1	;Copy of EE_SAMPLE_TIMER_2
;
Bank1Data 			UDATA	
TX_QUEU				RES		(C_SIZE_TX_Q_ENTRY*C_NBR_ENTRIES_TX)	;reserved space for sending data
RX_QUEU				RES		(C_SIZE_RX_Q_ENTRY*C_NBR_ENTRIES_RX)	;reserve space incoming msgs (no SUM_CHK)
;
Bank2Data			UDATA
TIMER_0_UP			RES		1	;active timer
TIMER_0_DWN			RES		1	;active timer
TIMER_1_UP			RES		1	;active timer
TIMER_1_DWN			RES		1	;active timer
CURSOR_0			RES		1	;active threshold port 0 - UP
CURSOR_1 			RES		1	;active threshold port 1 - UP
THRLD_B0_UP			RES		8	;threshold for FUNCTION B port 0 - UP
THRLD_B0_DWN		RES		8	;threshold for FUNCTION B port 0 - DOWN
THRLD_B1_UP			RES		8	;threshold for FUNCTION B port 1 - UP
THRLD_B1_DWN		RES		8	;threshold for FUNCTION B port 1 - DOWN
GARBAGE_CAN			RES		10	;in case no RX messages available, put unwanted message here

	UDATA_SHR					;Common bank
I_W_TEMP			RES		1	;save environment
TEMP_BIT			RES 	1	;general purpose bit hold
NBR_BITS			RES		1	;general purpose bit counter
NBR_BYTES			RES		1	;general purpose byte counter
PERIOD_AVG_0		RES		1	;running average of last 4 period samples
PERIOD_AVG_1		RES		1	;running average of last 4 period samples
DATA_TIMER			RES		1	;programed time to send data (INGRESSO 0)
DATA_TIMER_1		RES		1	;programed time to send data (INGRESSO 1)
TEMPO_INVIO_0		RES		1	;Copy of EE_TEMPO_INVIO
TEMPO_INVIO_1		RES		1	;Copy of EE_TEMPO_INVIO
TEMP_BYT0			RES		1	;general purpose byte hold
TEMP_BYT1			RES		1	;general purpose byte hold
TEMP_BYT2			RES		1	;general purpose byte hold
;
;
;Miscellaneous flags
#define		F_FA0_TMP_SND	FLAGS0,0	;
#define		F_FA1_TMP_SND	FLAGS0,1	;
#define		F_FA0_STEP_NZ	FLAGS0,2	;
#define		F_FA1_STEP_NZ	FLAGS0,3	;
#define		F_DIM_DIRCT_0	FLAGS0,4	;direction of dimmer (1=up, 0=down)
#define		F_DIM_DIRCT_1	FLAGS0,5	;
#define		F_DIMMR_ON_0	FLAGS0,6	;dimmer ON/OFF state (1=ON,0=OFF)
#define		F_DIMMR_ON_1	FLAGS0,7	;
;
#define		F_ABORT_RX_FLAG	FLAGS1,0	;
#define		F_BUS_IS_MINE	FLAGS1,1	;
#define		F_SERIAL_MATCH	FLAGS1,2	;
#define		F_MSG_FOUND		FLAGS1,3	;
#define		F_NO_DISCARD	FLAGS1,4	;
#define		F_UPD_EEPROM	FLAGS1,5	;
#define		F_ERROR_FLAG	FLAGS1,6	;
;
#define		F_TEMPORANEO	SEND_FLAGS,0 ; 0=message is being sent at end of period,1=THRESHOLD ALARM
#define		F_SOGLIA		SEND_FLAGS,1 ; 1=SOGLIA IN SALITA, 0=SOGLIA IN DISCESA 
;
	CODE
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Reset Vector							;
			org 	0x00				;
			CLRF	PCLATH				;
			CLRF	STATUS				;BANK 0 REGISTERS
			GOTO	Start				;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; Interrupt Vector						;
			org 	0x04				;
			GOTO	Service_Interrupt	;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;++++++++++++++++++++++++ START OF THE PROGRAM +++++++++++++++++++++++++++++++++
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			org		0x05				;
Start									;
;			BSF		STATUS,RP0			;leave out comments when no debug
;			BTFSC	PCON,1				;POWER ON?
;			GOTO	_NO_RESET			;	
			CLRWDT						;
			BCF		INTCON,GIE			;Disable interrupts
			CLRF	PORTA				;
_HERE		CLRF	PORTB				;
			CLRF	PORTC				;
										;
;A/D CONVERTER							;
;=============							;
			MOVLW	b'10000001'			;(see ADCON1 for bits adcon0<7,6> ; bits 5-3=channel selection;
			MOVWF	ADCON0				;  A/D powered on
										;
			BSF		STATUS,RP0			;bank 1
			MOVLW	b'01000100'			;left justtified,fosc/64,3andl/0 vref...
			MOVWF	ADCON1				;
;PORTS&INTERRUPTS						;
;================						;
			MOVLW	0XFF				;
			MOVWF	TRISA				;RA0=AN0,RA1=AN1
			MOVWF	TRISB				;RB0=ECHOBUS OUT, RB1=ECHOBUS IN
			MOVLW	b'11111001'			;RC2=OUT1,RC1=OUT2,RC0=ERROR LED (when error)
			MOVWF	TRISC				;
			CLRF	PIE1				;
			MOVLW	b'10001011'			;OPTION<6>=0=int on falling edge RB0, ...SELECT TMR0 AND WDT OPTION
			MOVWF	OPTION_REG			;PortB pullups disabled
;PWD D/A								;
;=======								;
			BCF		STATUS,RP0			;back to bank 0
			MOVLW	b'00001100' 		;bits 3-0=PWM mode (pg. 62)
			MOVWF	CCP1CON				;analogue chan 0
			MOVWF	CCP2CON				;analogue chan 1
			CLRF	T2CON				;PRESCALE 1:1
;
			BSF		STATUS,RP0			;bank 1 GP regs
			MOVLW	.63				;8 bit resolution clock at 8MZ
			MOVWF	PR2					;
										;
			MOVLW	TX_QUEU				;Clear the tx queu with zeroes
			MOVWF	FSR					;
			MOVLW	C_SIZE_TX_Q_ENTRY*C_NBR_ENTRIES_TX	;
			MOVWF	NBR_BYTES			;
			CLRW						;
_CLR_TX		MOVWF	INDF				;
			INCF	FSR,F				;
			DECFSZ	NBR_BYTES,F			;
			GOTO	_CLR_TX				;
										;
			MOVLW	RX_QUEU				;Clear the RX_QUEU queu with -1s
			MOVWF	FSR					;
			MOVLW	C_SIZE_RX_Q_ENTRY*C_NBR_ENTRIES_RX	;
			MOVWF	NBR_BYTES			;
			MOVLW	0xFF				;
_CLR_RX		MOVWF	INDF				;
			INCF	FSR,F				;
			DECFSZ	NBR_BYTES,F			;
			GOTO	_CLR_RX				;
										;
			BANKSEL	TIME_SCAN_TX		;
			CLRF	SAMPLE_CNTR			;
			CLRF	FLAGS0				;
			CLRF	FLAGS1				;
			CLRF	ON_OFF_TIMER_0		;
			CLRF	DIM_ACT_TIM_0		;
			CLRF	STEPBACK_TIM_0		;
			CLRF	ON_OFF_TIMER_1		;
			CLRF	DIM_ACT_TIM_1		;
			CLRF	STEPBACK_TIM_1		;
										;							
			MOVLW	255					;
			MOVWF	TEMP_BYT0			;delay allow EEPROM to come up
			MOVWF	TEMP_BYT1			;
_DELAY_INI	NOP							;
			NOP							;
			CLRWDT						;
			DECFSZ	TEMP_BYT0,F			;
			GOTO	_DELAY_INI			;			
			MOVLW	255					;
			MOVWF	TEMP_BYT0			;
			DECFSZ	TEMP_BYT1,F			;
			GOTO	_DELAY_INI			;
										;
			MOVLW	1					;to force re-read of EEPROM
			MOVWF	MSG_DISC			;
			CALL	READ_STABLE_DATA	;Read operating parameters from EEPROM
										;Reset ALL reduced timers and counters
			MOVLW	EE_SAVED_SAMPLE		;
			CALL	READ_EEPROM			;
			MOVWF	REFERENCE_SAMPLE	;
			MOVLW	EE_SAVED_SAMPLE+1	;
			CALL	READ_EEPROM			;
			MOVWF	REFERENCE_SAMPLE_1	;
										;
			MOVLW	EE_SAVED_CURSOR		;retrieve FUCTION B thresholds
			CALL	READ_EEPROM			;
			BANKSEL	CURSOR_0			;
			MOVWF	CURSOR_0			;
			BANKSEL	TIME_SCAN_TX		;
			MOVLW	EE_SAVED_CURSOR+1	;
			CALL	READ_EEPROM			;
			BANKSEL	CURSOR_1			;
			MOVWF	CURSOR_1			;
			BANKSEL	TIME_SCAN_TX		;
										;
			MOVLW	EE_SAVED_OUTPUT		;Restore output values before restart
			CALL	READ_EEPROM			;
			MOVWF	OUT_VAL0			;
			CLRF	PORT_OUT			;
			CALL	WRITE_OUT_PORT		;
										;
			MOVF	OUT_VAL0,F			;At initialization, if OUTVAL is <>0 then force EE_TOGGLE to
			BTFSC	STATUS,Z			; be zero
			GOTO	_INIT_PORT1			;
			MOVLW	EE_DIMM_TOGGLE		;
			MOVWF	E2ADDRESS			;
			CLRF	E2VALUE				;
			CALL	COPY_TO_EEPROM		;
										;
_INIT_PORT1	MOVLW	EE_SAVED_OUTPUT+1	;
			CALL	READ_EEPROM			;
			MOVWF	OUT_VAL1			;
			MOVLW	1					;
			MOVWF	PORT_OUT			;
			CALL	WRITE_OUT_PORT		;
										;
			MOVF	OUT_VAL1,F			;At initialization, if OUTVAL is <>0 then force EE_TOGGLE to
			BTFSC	STATUS,Z			; be zero
			GOTO	_NO_RESET			;
			MOVLW	EE_DIMM_TOGGLE+1	;
			MOVWF	E2ADDRESS			;
			CLRF	E2VALUE				;
			CALL	COPY_TO_EEPROM		;
										;
_NO_RESET								;
			BANKSEL	PCON				;
			BSF		PCON,1				;set POR bit (1=no POR)
			BANKSEL	TIMER_0_UP			;
										;
			BANKSEL	TIMER_0_UP			;Reset all basic timers
			CLRF	TIMER_0_UP			;
			CLRF	TIMER_0_DWN			;
			CLRF	TIMER_1_UP			;
			CLRF	TIMER_1_DWN			;
										;
			BANKSEL	TIME_SCAN_TX		;
			MOVLW	C_RX_TIMER			;
			MOVWF	TIME_SCAN_RX		;
										;
			MOVLW	C_DIM_STP_TIM		;
			MOVWF	DIMMER_TIMER		;
										;
			MOVLW	C_TX_TIMER			;
			MOVWF	TIME_SCAN_TX		;
										;
			MOVLW	C_SAMPLE_SCAN		;250MS
			MOVWF	TIME_SAMPLES		;
										;
			MOVLW	C_HUNDRED_MS		;
			MOVWF	SND_STATS			;
			MOVLW	C_ONESECOND			;seconds timer is based on 10*100ms timer
			MOVWF	THRSHD_EX_PERIOD	;
										;
			MOVLW	C_TIMER1_H			;
			MOVWF	TMR1H				;
			MOVLW	C_TIMER1_L			;
			MOVWF	TMR1L				;
			BCF		PIR1,TMR1IF			;clear TMR1 interrupt flag
			MOVLW	b'00010001'			;prescale 1:2(CLOCK 8Mz), internal clk,TMR1ON
			MOVWF	T1CON				;
			MOVLW	b'10010000'			;
			MOVWF	INTCON				;INTCON<4>=enbable RB0 ints
										;
_MAIN_LOOP	CLRWDT						;
			BTFSS	PIR1,TMR1IF			;TIMR1 expired?
			GOTO	_IDLE				;
			BCF		PIR1,TMR1IF			;clear TMR1 interrupt flag
			MOVLW	C_TIMER1_H			;
			MOVWF	TMR1H				;
			MOVLW	C_TIMER1_L			;
										;
			DECFSZ	TIME_SCAN_RX,F		;SCAN RX QUEU every 5ms
			GOTO	_DIMM_JOB			;
			GOTO	SCAN_RX_QUEU		;GOTO ISO CALLs for STACK REDUCTION
_RET1		MOVLW	C_RX_TIMER			;reset RX timer
			MOVWF	TIME_SCAN_RX		;
										;
_DIMM_JOB	DECFSZ	DIMMER_TIMER,F		;24ms based on 1ms
			GOTO	_SCAN_TX			;
			GOTO	SCAN_DIMMERS		;
_RET_7		MOVLW	C_DIM_STP_TIM		;
			MOVWF	DIMMER_TIMER		;
										;
_SCAN_TX	DECFSZ	TIME_SCAN_TX,F		;SCAN TX QUEU every 15ms
			GOTO	_SCAN_JOBS			;
			GOTO	SCAN_TX_QUEU		;GOTO ISO CALLs for STACK REDUCTION
_RET2		MOVLW	C_TX_TIMER			;reset TX timer
			MOVWF	TIME_SCAN_TX		;
										;
_SCAN_JOBS	DECFSZ	TIME_SAMPLES,F		;every 250ms
			GOTO	_SEND_STAT			;
			GOTO	FUNZ_INGRESSO		;
_RET3		MOVLW	C_SAMPLE_SCAN		;
			MOVWF	TIME_SAMPLES		;
										;
_SEND_STAT	DECFSZ	SND_STATS,F			;100ms
			GOTO	_IDLE				;
			MOVLW	C_HUNDRED_MS		;
			MOVWF	SND_STATS			;
			DECFSZ	THRSHD_EX_PERIOD,F	;10*100ms=1sec
			GOTO	_IDLE				;
			MOVLW	C_ONESECOND			;
			MOVWF	THRSHD_EX_PERIOD	;
										;
			DECF	SFTY_DIM_TIMR,F		;1 sec decrements meaningful only for dimming (see SCAN_DIMMERS)
										;
			BTFSS	F_ERROR_FLAG		;
			GOTO	_NO_IDL_ERR			;
			BANKSEL	TRISC				;toggle ERROR LED every 1 sec
			BCF		TRISC,0				;
			BANKSEL	PORTC				;
			BSF		ERROR_PORT			;
			GOTO	_THR_CHK			;
_NO_IDL_ERR								;
			BANKSEL	TRISC				;
			BSF		TRISC,0				;
			BANKSEL	PORTC				;
			BCF		ERROR_PORT			;
_THR_CHK	BCF		F_ERROR_FLAG		;
										;
			GOTO	THRESHOLD_A_PERIOD	;
_RET_5		GOTO	THRESHOLD_B_PERIOD	;
_RET_6		NOP							;
										;
_IDLE		BTFSS	T1CON,TMR1ON		;if either flag is not set it means we got kick 
			GOTO	_IDLE_ERR			;  out of the interrupt
			BTFSS	INTCON,GIE			;
			GOTO	_IDLE_ERR			;
			GOTO	_IDLE_CONT			;
_IDLE_ERR	CALL	ERROR_HANDLER		;
			BSF		F_ERROR_FLAG		;
_IDLE_CONT	;BSF		T1CON,TMR1ON	;commented for testing.... to be sure ....
			GOTO	_MAIN_LOOP			;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Aquire data from the A/D converter for both ports and do the4 necessary actions
;when enough data has been obtained.
;INPUT:		NONE
;OUTPUT:	value aquired from A/D in SAMPLE
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
FUNZ_INGRESSO							;
			DECFSZ	SAMPLE_TIMER_1,F	;number of 10ms seconds per sample
			GOTO	_END_SMPL			;not yet
			MOVF	SAVE_SAMPLE_TIM_1,W	;
			MOVWF	SAMPLE_TIMER_1		;
			DECFSZ	SAMPLE_TIMER_2,F	;number of 10th seconds per sample
			GOTO	_END_SMPL			;not yet
			MOVF	SAVE_SAMPLE_TIM_2,W	;
			MOVWF	SAMPLE_TIMER_2		;
										;
			CLRF	PORT_IN				;
			CALL	GET_SAMPLES			;get sample port 0
			INCF	PORT_IN,F			;
			CALL	GET_SAMPLES			;get sample port 1
			INCF	SAMPLE_CNTR,F		;
	   M_CMPL_JL	SAMPLE_CNTR,4,_END_SMPL
										;4 samples have been collected
			CLRF	PORT_IN				;Calculate average port 0
			CALL	CALC_AVG			;
			INCF	PORT_IN,F			;
			CALL	CALC_AVG			;Calculate average port 1
			CLRF	SAMPLE_CNTR			;
										;
			CLRF	PORT_IN				;
			MOVF	FUNZIONE_ING_0,W	;Decide next action depending on function and port
			XORLW	C_IN_STEP_WATCH		;
			BTFSS	STATUS,Z			;
			GOTO	_FUNC_B0_THR		;
			CALL	FUNC_A_THR_XING		;A0 threshold
			GOTO	_PORT_1_THRS		;
_FUNC_B0_THR							;
			MOVF	FUNZIONE_ING_0,W	;Decide next action depending on function and port
			XORLW	C_IN_THRHLD_WATCH	;
			BTFSC	STATUS,Z			;
			CALL	FUNC_B_THR_XING		;B0 threshold
_PORT_1_THRS							;
			INCF	PORT_IN,F			;
			MOVF	FUNZIONE_ING_1,W	;Decide next action depending on function and port
			XORLW	C_IN_STEP_WATCH		;
			BTFSS	STATUS,Z			;
			GOTO	_FUNC_B1_THR		;
			CALL	FUNC_A_THR_XING		;A1 threshold
			GOTO	_END_SMPL			;
_FUNC_B1_THR							;
			MOVF	FUNZIONE_ING_1,W	;Decide next action depending on function and port
			XORLW	C_IN_THRHLD_WATCH	;
			BTFSC	STATUS,Z			;
			CALL	FUNC_B_THR_XING		;B1 threshold
_END_SMPL	GOTO	_RET3				;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Both dimmer timers are treated here: the ON/OFF and the step-up(down) of the out 
;ports.  Dimmer directions are saved when necessary in EEPROM.
;NOTE:	The STEPBACK_TIM allows to compesate for delays in the propagation of the
;		OFF message and in the electrical circuits.
;INPUT:		ON_OFF_TIMER,DIM_ACT_TIM,STEPBACK_TIM
;OUTPUT:	ON_OFF_TIMER,DIM_ACT_TIM (new values),F_DIM_DIRCT (new direction)
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SCAN_DIMMERS							;
			MOVLW	C_OUT_DIMMER		;are we dimmers?
			XORWF	FUNZIONE_USC_0,W	;
			BTFSS	STATUS,Z			;
			GOTO	_PORT_1_DIM			;NOT A DIMMER
										;
			MOVF	ON_OFF_TIMER_0,F	;see if ON/OFF timer running
			BTFSC	STATUS,Z			;
			GOTO	_DIMMING_0			;no, we might be dimming
										;
			DECFSZ	ON_OFF_TIMER_0,F	;
			GOTO	_PORT_1_DIM			;ON/OFF running but not expired
										;
			MOVLW	C_DIMMER_ACTION		;ON/OFF timer expired
			MOVWF	DIM_ACT_TIM_0		;start dimmer action timer
			MOVLW	C_SFTY_DIM_STOP		;start safety timer
			MOVWF	SFTY_DIM_TIMR		;
			GOTO	_PORT_1_DIM			;dimming starts next cycle
										;
_DIMMING_0	MOVF	DIM_ACT_TIM_0,F		;
			BTFSC	STATUS,Z			;
			GOTO	_STP_BCK_0			;dimmer action is off, check to see if we need to step back
										;
			DECFSZ	DIM_ACT_TIM_0,F		;dimmer action running, dec until 0
			GOTO	_PORT_1_DIM			; - dimming but no action yet
			MOVLW	C_DIMMER_ACTION		;time to dimm, reset the timer right away
			MOVWF	DIM_ACT_TIM_0		;
			GOTO	_DIMM_0_ON			;
										;			
_STP_BCK_0	MOVF	STEPBACK_TIM_0,F	;if step back is non-zero, decrement and dimm
			BTFSC	STATUS,Z			;
			GOTO	_PORT_1_DIM			;we're not dimming port 0, check port 1
			DECF	STEPBACK_TIM_0,F	;we're stepping back
			GOTO	_DIM_0_CONT			;don't look at sfty timer now
										;
_DIMM_0_ON	MOVF	SFTY_DIM_TIMR,F		;we ARE dimming, check safety timmer first, if its expired
			BTFSS	STATUS,Z			; cancel the ACTIVE timer i.e. stop dimming
			GOTO	_DIM_0_CONT			;
			CLRF	DIM_ACT_TIM_0		;(both dimmers are shutoff)
			CLRF	DIM_ACT_TIM_1		;
			GOTO	_DIM_END			;
_DIM_0_CONT								;We are dimming port 0
			BTFSS	F_DIM_DIRCT_0		;
			GOTO	_DEC_DIM_0			;
			INCF	OUT_VAL0,F			;
			MOVLW	0xFF				;reached the maximum?
			XORWF	OUT_VAL0,W			;
			BTFSS	STATUS,Z			;
			GOTO	_OUTPUT_DIMM_0		;
			BCF		F_DIM_DIRCT_0		;reverse direction at maximum
			BSF		F_UPD_EEPROM		;
			GOTO	_OUTPUT_DIMM_0		;
_DEC_DIM_0	DECFSZ	OUT_VAL0,F			;
			GOTO	_OUTPUT_DIMM_0		;
			BSF		F_DIM_DIRCT_0		;reverse direction at minimum
			BSF		F_UPD_EEPROM		;
_OUTPUT_DIMM_0							;
			CLRF	PORT_OUT			;
			CALL	WRITE_OUT_PORT		;
;---------------------------------------;
_PORT_1_DIM								;
			MOVLW	C_OUT_DIMMER		;are we dimmers?
			XORWF	FUNZIONE_USC_1,W	;
			BTFSS	STATUS,Z			;
			GOTO	_MOD_DIM_EE			;NOT A DIMMER
										;
			MOVF	ON_OFF_TIMER_1,F	;see if ON/OF timer running
			BTFSC	STATUS,Z			;
			GOTO	_DIMMING_1			;no, we might be dimming
										;
			DECFSZ	ON_OFF_TIMER_1,F	;
			GOTO	_MOD_DIM_EE			;
										;
			MOVLW	C_DIMMER_ACTION		;ON/OFF wait is over
			MOVWF	DIM_ACT_TIM_1		;START DIMMING-ACTIVE TIMERS
			MOVLW	C_SFTY_DIM_STOP		;
			MOVWF	SFTY_DIM_TIMR		;
			GOTO	_MOD_DIM_EE			;
										;
_DIMMING_1	MOVF	DIM_ACT_TIM_1,F		;
			BTFSC	STATUS,Z			;
			GOTO	_STP_BCK_1			;dimmer action is off, see if we need to step back
										;
			DECFSZ	DIM_ACT_TIM_1,F		;dimmer action running, dec until 0
			GOTO	_MOD_DIM_EE			; - dimming but no action yet
			MOVLW	C_DIMMER_ACTION		; - time to dimm
			MOVWF	DIM_ACT_TIM_1		;  -- reset the timer right away
			GOTO	_DIMM_1_ON			;
										;
_STP_BCK_1	MOVF	STEPBACK_TIM_1,F	;if step back is non-zero, decrement and dimm
			BTFSC	STATUS,Z			;
			GOTO	_MOD_DIM_EE			;we're not dimming port 1 at all
			DECF	STEPBACK_TIM_1,F	;we're stepping back
			GOTO	_DIM_1_CONT			;don't look at sfty timer now
										;
_DIMM_1_ON	MOVF	SFTY_DIM_TIMR,F		;we ARE dimming, check safety timmer first, if its expired
			BTFSS	STATUS,Z			; cancel the ACTIVE timer i.e. stop dimming
			GOTO	_DIM_1_CONT			;
			CLRF	DIM_ACT_TIM_0		;BOTH DIMMER OFF: WE EITHER LOST COMMUNICATIONS OR SOMEONE
			CLRF	DIM_ACT_TIM_1		; IS PLAYING WITH THE LIGHTS!!!
			GOTO	_DIM_END			;
_DIM_1_CONT								;
			BTFSS	F_DIM_DIRCT_1		;			
			GOTO	_DEC_DIM_1			;
			INCF	OUT_VAL1,F			;
			MOVLW	0xFF				;reached the maximum?
			XORWF	OUT_VAL1,W			;
			BTFSS	STATUS,Z			;
			GOTO	_OUTPUT_DIMM_1		;
			BCF		F_DIM_DIRCT_1		;reverse direction at maximum
			BSF		F_UPD_EEPROM		;
			GOTO	_OUTPUT_DIMM_1		;
_DEC_DIM_1	DECFSZ	OUT_VAL1,F			;
			GOTO	_OUTPUT_DIMM_1		;
			BSF		F_DIM_DIRCT_1		;reverse direction at minimum
			BSF		F_UPD_EEPROM		;
_OUTPUT_DIMM_1							;
			MOVLW	1					;
			MOVWF	PORT_OUT			;
			CALL	WRITE_OUT_PORT		;
;---------------------------------------;
_MOD_DIM_EE	BTFSS	F_UPD_EEPROM		;
			GOTO	_DIM_END			;
			CALL	SAVE_STATE_DIRECTION;
										;
_DIM_END	GOTO	_RET_7				;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Function A (STEP WATCH) threshold: check if the PERIOD_AVG deviates from the 
; REFERENCE_SAMPLE by a marging larger than the STEP size.
;INPUT:		PORT_IN
;OUTPUT:	NONE
;DESTROYS:	TEMP_BYT0,TEMP_BYT1
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
FUNC_A_THR_XING							;
			MOVF	PORT_IN,F			;
			BTFSS	STATUS,Z			;
			GOTO	_POR_1_THR_A		;
_POR_0_THR_A							;
			BTFSS	F_FA0_STEP_NZ		;Check if the thrshold crossing function is turned for port 0
			GOTO	_THR_A_END			;
			MOVF	PERIOD_AVG_0,W		;Get the latest period average for this port
			MOVWF	TEMP_BYT1			;
			GOTO	_FUNC_CONT			;
_POR_1_THR_A							;
			BTFSS	F_FA1_STEP_NZ		;Check if the thrshold crossing function is turned for port 1
			GOTO	_THR_A_END			;
			MOVF	PERIOD_AVG_1,W		;
			MOVWF	TEMP_BYT1			;
										;
_FUNC_CONT	MOVF	PORT_IN,W			;
			ADDLW	REFERENCE_SAMPLE	;calculate thresholds based on step size for this port
			MOVWF	FSR					;
			MOVF	INDF,W				;FSR -> REFERENCE_SAMPLE
			MOVWF	TEMP_BYT0			;
			INCF	FSR,F				;
			INCF	FSR,F				;FSR -> STEP_A
			MOVF	INDF,W				;REF+STEP < CURRENT SAMPLE?
			ADDWF	TEMP_BYT0,F			;
			BTFSS	STATUS,C			;overflow? don't test 
			GOTO	$+2					;
			GOTO	_NO_HI_THR			;
										;
		M_CMP_JG	TEMP_BYT0,TEMP_BYT1,_NO_HI_THR
			BSF		F_SOGLIA		 	;1=SOGLIA IN SALITA
			GOTO	_THR_PASSED			;in up direction
										;
_NO_HI_THR	MOVF	INDF,W				;FSR -> STEP_A
			SUBWF	TEMP_BYT0,F			;by subtracting twice the value of STEP we obtain REF-STEP
			SUBWF	TEMP_BYT0,F			;REF-STEP_A < CURRENT SAMPLE?
			BTFSC	STATUS,C			;underflow? don't test 
			GOTO	$+2					;
			GOTO	_THR_A_END			;
										;
		M_CMP_JL	TEMP_BYT0,TEMP_BYT1,_THR_A_END
			BCF		F_SOGLIA		 	;0=SOGLIA IN DISCESA 
										;
_THR_PASSED	DECF	FSR,F				;
			DECF	FSR,F				;FSR -> REFERENCE_SAMPLE
			MOVF	TEMP_BYT1,W			;new reference only when the message is sent 
			MOVWF	INDF				;
										;
			MOVF	PORT_IN,W			;
			ADDLW	EE_SAVED_SAMPLE		;save in EEPROM
			MOVWF	E2ADDRESS			;
			MOVF	INDF,W				;
			MOVWF	E2VALUE				;
			CALL	COPY_TO_EEPROM		;Put msg data into EEPROM
			BSF		F_TEMPORANEO		;ALARM
			CALL	SEND_REF_MSG		;FSR -> REFERENCE_SAMPLE(PORT_IN)
										;
_THR_A_END	RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Function B (THRESHOLD WATCH) threshold: Analyze PERIOD_AVG and compare it to 
;threshold values, if crossed send messages stored in EEPROM for each threshold.  
;Gets called every time the PERIOD_AVG is calculated. All variables in this procedure 
;are in bank 2.
;NOTE: TO FOLLOW THE CODE BELOW ASSUME THAT THE CURRENT THRESHOLD IS  'C'
;INPUT:		PORT_IN,PERIOD_AVG
;OUTPUT:	NONE
;DESTROYS:	FSR, TEMP_BYT0
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
FUNC_B_THR_XING							;
			MOVF	PORT_IN,F			;
			BANKSEL	TIMER_0_UP			;
			BSF		STATUS,IRP			;
			BTFSS	STATUS,Z			;
			GOTO	_PORT_1_B			;
;=======================================;
;	==	PORT 0 FUNTCION B THRESHOLDS ==	;
;=======================================;
_PORT_0_B	MOVF	CURSOR_0,W			;
			XORLW	8					;
			BTFSC	STATUS,Z			;If C is the highest threshold, check only for down threshold
			GOTO	_THR_0_DOWN			;
			INCF	CURSOR_0,W			;
			ADDLW	THRLD_B0_UP-1		;
			MOVWF	FSR					;has PERIOD_AVG crossed threshold 'D'?
			MOVF	INDF,F				;
			BTFSC	STATUS,Z			;threshold not used?
			GOTO	_THR_0_DOWN			;
										;
		M_CMP_JGE	PERIOD_AVG_0,INDF,_B0_UP
										;
_THR_0_DOWN	MOVF	CURSOR_0,W			;Check if we crossed a LOW threshold
			BTFSC	STATUS,Z			;are we at the lowest THR?
			GOTO	_THR_B_END			;
			ADDLW	THRLD_B0_DWN-1		;compare the PERIOD_AVG threshold 'C' to see if
			MOVWF	FSR					; we are down at threshold 'B'
			MOVF	INDF,F				;
			BTFSC	STATUS,Z			;threshold not used?
			GOTO	_THR_B_END			;
										;
		M_CMP_JL	PERIOD_AVG_0,INDF,_B0_DWN
										;
_B0_SAME	CLRF	TIMER_0_UP			;NTHR crossing, clear timers
			CLRF	TIMER_0_DWN			;
			GOTO	_THR_B_END			;no THR-B0 changes
										;
_B0_UP		MOVF	TIMER_0_UP,F		;Threshold 'D' has been crossed
			BTFSC	STATUS,Z			;is UP-clock running?
			GOTO	_SET_UP_0_TMR		;NO
										;
			INCF	CURSOR_0,W			;UP-clock is running
			ADDLW	1					; see if we've crossed an even higher threshold
			MOVWF	TEMP_BYT0			; means we have to move the current cursor up
			XORLW	9					;Did we exceed the highest?
			BTFSC	STATUS,Z			;If yes, the threshold will be incremented on TIMEREX
			GOTO	_THR_B_END			; because we can't test for further increment
										;
			MOVF	TEMP_BYT0,W			;
			ADDLW	THRLD_B0_UP-1		;Now check the higher threshold
			MOVWF	FSR					;
			MOVF	INDF,F				;
			BTFSC	STATUS,Z			;first see if the higher threshold is in use?
			GOTO	_THR_B_END			;
										;
		M_CMP_JGE	PERIOD_AVG_0,INDF,_SND_0_UP_MSG;
			GOTO	_THR_B_END			;
										;
_SND_0_UP_MSG							;We crossed threshold 'E', send message for threshold 'D-UP' 
			INCF	CURSOR_0,F			; and start new timer
			DECF	CURSOR_0,W			;adjust for offset to EEPROM messages
			MOVWF	TEMP_BYT0			;
			CLRC						;
			RLF		TEMP_BYT0,F			;multiply crusor by 5 to get start of message
			RLF		TEMP_BYT0,F			;
			ADDWF	TEMP_BYT0,W			;			
			ADDLW	EE_MESSAGE_0_UP		;
			BANKSEL	TIME_SCAN_TX		;
			BCF		STATUS,IRP			;
			CALL	SEND_EEPROM_MSG		;
			BSF		STATUS,IRP			;
			BSF		F_UPD_EEPROM		;
			BANKSEL	TIMER_0_UP			;
_SET_UP_0_TMR							;
			CLRF	TIMER_0_DWN			;Whatever DOWN timer was doing, it must be shut-off
			MOVF	CURSOR_0,W			;Set the UP-timer only we're not at the higest THRHLD
			XORLW	8					;
			BTFSC	STATUS,Z			;
			GOTO	_THR_B_END			;
										;
			MOVF	TEMPO_INVIO_0,W		;
			MOVWF	TIMER_0_UP			;RE-Start the UP clock
			GOTO	_THR_B_END			;
										;
;---------------------------------------;
_B0_DWN		MOVF	TIMER_0_DWN,F		;DOWN clock running?
			BTFSC	STATUS,Z			;
			GOTO	_SET_DWN_0_TMR		;
										;
_B0_DWN_CNT	DECF	CURSOR_0,F			;Do we need to check for LOWER than LOWEST?????????
			MOVF	CURSOR_0,W			;adjust for offset to EEPROM messages
			MOVWF	TEMP_BYT0			;
			CLRC						;
			RLF		TEMP_BYT0,F			;CURSOR*5 to get start of message
			RLF		TEMP_BYT0,F			;
			ADDWF	TEMP_BYT0,W			;			
			ADDLW	EE_MESSAGE_0_DWN	;
			BANKSEL	TIME_SCAN_TX		;
			BCF		STATUS,IRP			;
			CALL	SEND_EEPROM_MSG		;
			BSF		STATUS,IRP			;
			BSF		F_UPD_EEPROM		;
			BANKSEL	TIMER_0_UP			;
_SET_DWN_0_TMR							;
			MOVF	CURSOR_0,F			;If we are at the lowest threshold do not start
			BTFSS	STATUS,Z			; the timer (cancel if its already running)
			GOTO	_SET_D0				;
			CLRF	TIMER_0_DWN			;
			GOTO	_THR_B_END			;
										;
_SET_D0		MOVF	TEMPO_INVIO_0,W		;First detection of THR crossing
			MOVWF	TIMER_0_DWN			;RE-Start the DOWN clock
			CLRF	TIMER_0_UP			;Whatever UP timer was doing, it must be shut-off
			GOTO	_THR_B_END			;
;=======================================;
;	==	PORT 1 FUNTCION B THRESHOLDS ==	;
;=======================================;
_PORT_1_B	MOVF	CURSOR_1,W			;
			XORLW	8					;
			BTFSC	STATUS,Z			;If C is the highest threshold, check only for down threshold
			GOTO	_THR_1_DOWN			;
			INCF	CURSOR_1,W			;
			ADDLW	THRLD_B1_UP-1		;
			MOVWF	FSR					;has PERIOD_AVG crossed threshold 'D'?
			MOVF	INDF,F				;
			BTFSC	STATUS,Z			;
			GOTO	_THR_1_DOWN			;
										;
		M_CMP_JGE	PERIOD_AVG_1,INDF,_B1_UP
										;
_THR_1_DOWN	MOVF	CURSOR_1,W			;Check if we crossed a LOW threshold
			BTFSC	STATUS,Z			;are we at the lowest THR?
			GOTO	_THR_B_END			;
			ADDLW	THRLD_B1_DWN-1		;compare the PERIOD_AVG with threshold 'C' to see if
			MOVWF	FSR					; we are down at threshold 'B'
			MOVF	INDF,F				;
			BTFSC	STATUS,Z			;threshold not used?
			GOTO	_THR_B_END			;
										;			
		M_CMP_JL	PERIOD_AVG_1,INDF,_B1_DWN
										;
_B1_SAME	CLRF	TIMER_1_UP			;NTHR crossing, clear timers
			CLRF	TIMER_1_DWN			;
			GOTO	_THR_B_END			;no THR-B1 changes
										;
_B1_UP		MOVF	TIMER_1_UP,F		;Threshold 'D' has been crossed
			BTFSC	STATUS,Z			;is UP-clock running?
			GOTO	_SET_UP_1_TMR		;NO
										;
			INCF	CURSOR_1,W			;UP-clock is running
			ADDLW	1					; see if we've crossed an even higher threshold
			MOVWF	TEMP_BYT0			; means we have to move the current cursor up
			XORLW	9					;Did we exceed the highest?
			BTFSC	STATUS,Z			;If yes, the threshold will be incremented on TIMEREX
			GOTO	_THR_B_END			; because can't test for further increment
										;
			MOVF	TEMP_BYT0,W			;
			ADDLW	THRLD_B1_UP-1		;Now check the actual threshold
			MOVWF	FSR					;
			MOVF	INDF,F				;
			BTFSC	STATUS,Z			;see if the higher threshold is also in use
			GOTO	_THR_B_END			;
										;
		M_CMP_JGE	PERIOD_AVG_1,INDF,_SND_1_UP_MSG;
			GOTO	_THR_B_END			;
										;
_SND_1_UP_MSG							;We crossed threshold 'E', send message for threshold 'D-UP' 
			INCF	CURSOR_1,F			; and start new timer
			DECF	CURSOR_1,W			;adjust for offset to EEPROM messages
			MOVWF	TEMP_BYT0			;
			CLRC						;
			RLF		TEMP_BYT0,F			;multiply crusor by 5 to get start of message
			RLF		TEMP_BYT0,F			;
			ADDWF	TEMP_BYT0,W			;			
			ADDLW	EE_MESSAGE_1_UP		;
			BANKSEL	TIME_SCAN_TX		;
			BCF		STATUS,IRP			;
			CALL	SEND_EEPROM_MSG		;
			BSF		STATUS,IRP			;
			BSF		F_UPD_EEPROM		;
			BANKSEL	TIMER_1_UP			;
_SET_UP_1_TMR							;
			CLRF	TIMER_1_DWN			;Whatever DOWN timer was doing, it must be shut-off
			MOVF	CURSOR_1,W			;Set the UP-timer only we're not at the higest THRHLD
			XORLW	8					;
			BTFSC	STATUS,Z			;
			GOTO	_THR_B_END			;
										;
			MOVF	TEMPO_INVIO_1,W		;
			MOVWF	TIMER_1_UP			;RE-Start the UP clock
			GOTO	_THR_B_END			;
										;
;---------------------------------------;
_B1_DWN		MOVF	TIMER_1_DWN,F		;DOWN clock running?
			BTFSC	STATUS,Z			;
			GOTO	_SET_DWN_1_TMR		;
										;
_B1_DWN_CNT	DECF	CURSOR_1,F			;Do we need to check for LOWER than LOWEST?????????
			MOVF	CURSOR_1,W			;adjust for offset to EEPROM messages
			MOVWF	TEMP_BYT0			;
			CLRC						;
			RLF		TEMP_BYT0,F			;CURSOR*5 to get start of message
			RLF		TEMP_BYT0,F			;
			ADDWF	TEMP_BYT0,W			;			
			ADDLW	EE_MESSAGE_1_DWN	;
			BANKSEL	TIME_SCAN_TX		;
			BCF		STATUS,IRP			;
			CALL	SEND_EEPROM_MSG		;
			BSF		STATUS,IRP			;
			BSF		F_UPD_EEPROM		;
			BANKSEL	TIMER_1_UP			;
_SET_DWN_1_TMR							;
			MOVF	CURSOR_1,F			;If we are at the lowest threshold do not start
			BTFSS	STATUS,Z			; the timer (cancel if its already running)
			GOTO	_SET_D1				;
			CLRF	TIMER_1_DWN			;
			GOTO	_THR_B_END			;
										;
_SET_D1		MOVF	TEMPO_INVIO_1,W		;First detection of THR crossing
			MOVWF	TIMER_1_DWN			;RE-Start the DOWN clock
			CLRF	TIMER_1_UP			;Whatever UP timer was doing, it must be shut-off
			GOTO	_THR_B_END			;
;=======================================;
_THR_B_END	BCF		STATUS,IRP			;
			BANKSEL	TIME_SCAN_TX		;
			BTFSS	F_UPD_EEPROM		;
			GOTO	_THR_DONE			;
										;
			BCF		F_UPD_EEPROM		;
			MOVLW	EE_SAVED_CURSOR		;Save the cursors in EEPROM
			MOVWF	E2ADDRESS			;
			BANKSEL	TIMER_0_UP			;
			MOVF	CURSOR_0,W			;
			BANKSEL	TIME_SCAN_TX		;	
			MOVWF	E2VALUE				;
			CALL	COPY_TO_EEPROM		;
			MOVLW	EE_SAVED_CURSOR+1	;
			MOVWF	E2ADDRESS			;
			BANKSEL	TIMER_0_UP			;
			MOVF	CURSOR_1,W			;
			BANKSEL	TIME_SCAN_TX		;	
			MOVWF	E2VALUE				;
			CALL	COPY_TO_EEPROM		;
_THR_DONE	RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;If function A, send samples after SEND_TIMER expires 
;INPUT:		NONE
;OUTPUT:	NONE
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
THRESHOLD_A_PERIOD						;
			CLRF	PORT_IN				;
_NXT_PORT_TIMER							;Decrement the programmed seconds timer
			MOVF	PORT_IN,F			;
			BTFSS	STATUS,Z			;
			GOTO	_PORT_1_TIM			;
										;
_PORT_0_TIM	MOVF	FUNZIONE_ING_0,W	;
			XORLW	C_IN_STEP_WATCH		;
			BTFSS	STATUS,Z			;
			GOTO	_NXT_PORT_NBR		;
			BTFSS	F_FA0_TMP_SND		;See if periodic timers are active for either port
			GOTO	_NXT_PORT_NBR		;
			GOTO	_CHK_TIME			;
										;
_PORT_1_TIM	MOVF	FUNZIONE_ING_1,W	;
			XORLW	C_IN_STEP_WATCH		;
			BTFSS	STATUS,Z			;
			GOTO	_NXT_PORT_NBR		;
			BTFSS	F_FA1_TMP_SND		;
			GOTO	_NXT_PORT_NBR		;
			GOTO	_CHK_TIME			;
										;
_CHK_TIME	MOVLW	DATA_TIMER			;
			ADDWF	PORT_IN,W			; 
			MOVWF	FSR					;
			DECFSZ	INDF,F				;
			GOTO	_NXT_PORT_NBR		;
										;
			MOVF	PORT_IN,W			;Send timer expired 
			ADDLW	TEMPO_INVIO_0		; reset it rigth away
			MOVWF	FSR					;
			MOVF	INDF,W				;
			MOVWF	TEMP_BYT0			;
										;
			MOVF	PORT_IN,W			;
			ADDLW	DATA_TIMER			;
			MOVWF	FSR					;
			MOVF	TEMP_BYT0,W			;FSR -> DATA_TIMER(PORT_IN)
			MOVWF	INDF				;
										;
			CLRF	SEND_FLAGS			;Initialize flags (<0>=temporaneo)
			MOVF	PORT_IN,W			;
			ADDLW	PERIOD_AVG_0		;report the last reading for this port
			MOVWF	FSR					;
			CALL	SEND_REF_MSG		;(PORT_IN,FSR -> REFERENCE_SAMPLE(PORT_IN)
_NXT_PORT_NBR							;
			INCF	PORT_IN,F			;
			BTFSS	PORT_IN,1			;
			GOTO	_NXT_PORT_TIMER		;
_NOT_YET	GOTO	_RET_5				;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Checks for THRESHOLD persistancy for ports with function B.  All variables in Bank 2
;INPUT:		NONE
;OUTPUT:	NONE
;DESTROYS:	FSR,TEMP_BYT0
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
THRESHOLD_B_PERIOD						;
			MOVF	FUNZIONE_ING_0,W	;
			XORLW	C_IN_THRHLD_WATCH	;
			BTFSS	STATUS,Z			;
			GOTO	_PORT_1B_PERIOD		;
										;
			BANKSEL	TIMER_0_UP			;
			BSF		STATUS,IRP			;
			MOVF	TIMER_0_UP,F		;UP-clock running?
			BTFSC	STATUS,Z			;
			GOTO	_TIME_0_DOWN		;NO UP-clock, nothing to do port 0
										;
			DECFSZ	TIMER_0_UP,F		;
			GOTO	_PORT_1B_PERIOD		;no THR-B0 changes... yet
										;
			INCF	CURSOR_0,F			;
			DECF	CURSOR_0,W			;adjust for offset to EEPROM messages
			MOVWF	TEMP_BYT0			;
			CLRC						;
			RLF		TEMP_BYT0,F			;multiply crusor by 5 to get start of message
			RLF		TEMP_BYT0,F			;
			ADDWF	TEMP_BYT0,W			;			
			ADDLW	EE_MESSAGE_0_UP		;
			BANKSEL	TIME_SCAN_TX		;
			BCF		STATUS,IRP			;
			CALL	SEND_EEPROM_MSG		;
			BSF		STATUS,IRP			;
			BSF		F_UPD_EEPROM		;
			BANKSEL	TIMER_0_UP			;
										;THR-B0 moves up on TIMER EXPIRY - NEW REFERENCE
			GOTO	_PORT_1B_PERIOD		;
_TIME_0_DOWN							;
			MOVF	TIMER_0_DWN,F		;DOWN-clock running?
			BTFSC	STATUS,Z			;
			GOTO	_PORT_1B_PERIOD		;no DOWN-clock, no changes port 0
										;
			DECFSZ	TIMER_0_DWN,F		;
			GOTO	_PORT_1B_PERIOD		;no THR-B0 changes... yet
										;
			DECF	CURSOR_0,F			;
			MOVF	CURSOR_0,W			;adjust for offset to EEPROM messages
			MOVWF	TEMP_BYT0			;
			CLRC						;
			RLF		TEMP_BYT0,F			;multiply crusor by 5 to get start of message
			RLF		TEMP_BYT0,F			;
			ADDWF	TEMP_BYT0,W			;			
			ADDLW	EE_MESSAGE_0_DWN	;
			BANKSEL	TIME_SCAN_TX		;
			BCF		STATUS,IRP			;
			CALL	SEND_EEPROM_MSG		;
			BSF		STATUS,IRP			;
			BSF		F_UPD_EEPROM		;THR-B0 moves down on TIMER EXPIRY - NEW REFERENCE
;=======================================;
_PORT_1B_PERIOD							;
			MOVF	FUNZIONE_ING_1,W	;
			XORLW	C_IN_THRHLD_WATCH	;
			BTFSS	STATUS,Z			;
			GOTO	_THR_B_EPILOGUE		;not THR B1 funtion
										;
			BANKSEL	TIMER_1_UP			;
			BSF		STATUS,IRP			;
			MOVF	TIMER_1_UP,F		;UP-clock running?
			BTFSC	STATUS,Z			;
			GOTO	_TIME_1_DOWN		;no THR-B1 changes
										;
			DECFSZ	TIMER_1_UP,F		;
			GOTO	_THR_B_EPILOGUE		;no THR-B1 changes... yet
										;
			INCF	CURSOR_1,F			;THR-B1 moves up on TIMER EXPIRY - NEW REFERENCE
			DECF	CURSOR_1,W			;adjust for offset to EEPROM messages
			MOVWF	TEMP_BYT0			;
			CLRC						;
			RLF		TEMP_BYT0,F			;multiply crusor by 5 to get start of message
			RLF		TEMP_BYT0,F			;
			ADDWF	TEMP_BYT0,W			;			
			ADDLW	EE_MESSAGE_1_UP		;
			BANKSEL	TIME_SCAN_TX		;
			BCF		STATUS,IRP			;
			CALL	SEND_EEPROM_MSG		;
			BSF		STATUS,IRP			;
			BSF		F_UPD_EEPROM		;
			BANKSEL	TIMER_1_UP			;
			GOTO	_THR_B_EPILOGUE		;
_TIME_1_DOWN							;
			MOVF	TIMER_1_DWN,F		;DOWN-clock running?
			BTFSC	STATUS,Z			;
			GOTO	_THR_B_EPILOGUE		;no THR-B1 changes
										;
			DECFSZ	TIMER_1_DWN,F		;
			GOTO	_THR_B_EPILOGUE		;no THR-B1 changes... yet
										;
			DECF	CURSOR_1,F			;THR-B1 moves down on TIMER EXPIRY - NEW REFERENCE
			MOVF	CURSOR_1,W			;adjust for offset to EEPROM messages
			MOVWF	TEMP_BYT0			;
			CLRC						;
			RLF		TEMP_BYT0,F			;multiply crusor by 5 to get start of message
			RLF		TEMP_BYT0,F			;
			ADDWF	TEMP_BYT0,W			;			
			ADDLW	EE_MESSAGE_1_DWN	;
			BANKSEL	TIME_SCAN_TX		;
			BCF		STATUS,IRP			;
			CALL	SEND_EEPROM_MSG		;
			BSF		STATUS,IRP			;
			BSF		F_UPD_EEPROM		;
;=======================================;
_THR_B_EPILOGUE							;
			BANKSEL	TIME_SCAN_TX		;	
			BCF		STATUS,IRP			;
			BTFSS	F_UPD_EEPROM		;put new cursors in EEPROM when necessary
			GOTO	_END_THR_B			;
										;
			BCF		F_UPD_EEPROM		;
			MOVLW	EE_SAVED_CURSOR		;
			MOVWF	E2ADDRESS			;
			BANKSEL	TIMER_0_UP			;
			MOVF	CURSOR_0,W			;
			BANKSEL	TIME_SCAN_TX		;	
			MOVWF	E2VALUE				;
			CALL	COPY_TO_EEPROM		;
			MOVLW	EE_SAVED_CURSOR+1	;
			MOVWF	E2ADDRESS			;
			BANKSEL	TIMER_0_UP			;
			MOVF	CURSOR_1,W			;
			BANKSEL	TIME_SCAN_TX		;	
			MOVWF	E2VALUE				;
			CALL	COPY_TO_EEPROM		;
_END_THR_B	GOTO	_RET_6				;e.g. RETURN
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Read PORT_IN
;DESTROYS:	TEMP_BYT0,TEMP_BYT2
;INPUT:		PORT_IN=port to read (0|1), SAMPLE=sample number (0..3)
;OUTPUT:	sample
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GET_SAMPLES								;
			MOVF	PORT_IN,W			;
			MOVWF	TEMP_BYT0			;
			CLRC						;
			RLF		TEMP_BYT0,F			;*4 to point to correct SAMPLES
			RLF		TEMP_BYT0,W			;
			ADDWF	SAMPLE_CNTR,W		;
			ADDLW	SAMPLES				;
			MOVWF	FSR					;FSR -> SAMPLES(PORT_IN,SAMPLE_CNTR)
										;
			MOVF	PORT_IN,F			;
			BTFSS	STATUS,Z			;
			GOTO	$+3					;
			MOVLW	b'10000000'			;READ PORT 0
			GOTO	$+2					;
			MOVLW	b'10001000'			;READ PORT 1
										;
_READ_DELAY	MOVWF	ADCON0				;
			MOVLW	b'00000001'			;turn ON, A/D module
			IORWF	ADCON0,F			;
			MOVLW	12					;
			MOVWF	TEMP_BYT2			;wait cycle
			DECFSZ	TEMP_BYT2,F			;2 CYC+2CYC=4*12=48us+ delay
			GOTO	$-1					;
_ADCON_GO	BSF		ADCON0,GO			;start conversion
			BTFSC	ADCON0,GO			;
			GOTO	$-1					;
_ADCON_RDY	MOVF	ADRESH,W			;8 MSB (ignore 2 LSBs in ADRESL)
			MOVWF	INDF				;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Calculate average for PORT_IN
;INPUT:		PORT_IN
;OUTPUT:	PERIOD_AVG(PORT_IN) - average of the last 4 samples for this port
;DESTROYS:	TEMP_BYT0,TEMP_BYT1,TEMP_BYT2,FSR
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CALC_AVG	CLRF	SAMPLE_CNTR			;after 4 samples are collected compute the average
			CLRF	TEMP_BYT2			;
			CLRF	TEMP_BYT1			;
										;
			MOVF	PORT_IN,W			;
			MOVWF	TEMP_BYT0			;
			CLRC						;
			RLF		TEMP_BYT0,F			;*4 to point to correct SAMPLES
			RLF		TEMP_BYT0,W			;
			ADDWF	SAMPLE_CNTR,W		;
			ADDLW	SAMPLES-1			;double precision sum of
			MOVWF	FSR					; of 4 collected samples
_NXT_SUM	INCF	FSR,F				;
			MOVF	INDF,W				;
			ADDWF	TEMP_BYT1,F			;
			BTFSC	STATUS,C			;
			INCF	TEMP_BYT2,F			;
			INCF	SAMPLE_CNTR,F		;
	   M_CMPL_JL	SAMPLE_CNTR,4,_NXT_SUM
			RRF		TEMP_BYT2,F			;devide by 4, double precision 
			RRF		TEMP_BYT1,F			;
			RRF		TEMP_BYT2,F			;
			RRF		TEMP_BYT1,F			;
										;
			MOVLW	PERIOD_AVG_0		;Save this period's average
			ADDWF	PORT_IN,W			;
			MOVWF	FSR					;FSR -> PERIOD_AVG
			MOVF	TEMP_BYT1,W			;
			MOVWF	INDF				;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Get states of inputs and outputs and report back to the CPU.
;INPUT:		msg in SHARED data
;OUTPUT:	none
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SND_PORT_PARS							;
		M_CMPL_JNE	MSG_SUBT,1,_PORTS1	; decide if its port pair 0 or 1
			MOVF	PERIOD_AVG_0,W		;
			MOVWF	MSG_DISC			;
			MOVF	OUT_VAL0,W			;
			MOVWF	MSG_ARGT			;
			GOTO	_SND_PP				;
										;
_PORTS1: M_CMPL_JNE	MSG_SUBT,2,_PORT_ERROR;
			MOVF	PERIOD_AVG_1,W		;
			MOVWF	MSG_DISC			;	
			MOVF	OUT_VAL1,W			;
			MOVWF	MSG_ARGT			;
			GOTO	_SND_PP				;
										;
_PORT_ERROR	CALL	ERROR_HANDLER		;ERROR: NO TX ENTRY AVAILABLE FOR REPLY
			GOTO	_PORT_PARS_FIN		;
										;
_SND_PP		MOVLW	TYPE_RISPOSTA_STAT 	;(182)	
			MOVWF	MSG_TYPE			;
			MOVLW	1					;send only once
			MOVWF	MSG_EXPIRE			;
			CALL	FIND_EMPTY_TX_Q		;
			BTFSC	F_MSG_FOUND			;
			GOTO	$+3					;
			CALL	ERROR_HANDLER		;ERROR: NO TX ENTRY AVAILABLE FOR REPLY
			GOTO	_PORT_PARS_FIN		;
			CALL	COPY_TO_TX			;RX msg will be discarded on return
_PORT_PARS_FIN							;
			RETURN						;return SND_PORT_PARS
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Send a messge with the REFERENCE_SAMPLE.  The message is treated more or less as if it 
;was an alarm.
;INPUT:		PORT_IN,FSR -> PERIOD_AVG (timer ex) or REFERENCE_SAMPLE (threshold passed)
;OUTPUT:	message in RX_QUE
;DESTROYS:	FSR
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SEND_REF_MSG							;
			MOVF	INDF,W				;
			MOVWF	MSG_ARGT			;save rightaway
			MOVLW	TYPE_INVIO_STATO	;180
			MOVWF	MSG_TYPE			;
			MOVF	SEND_FLAGS,W		;
			MOVWF	MSG_SUBT			;
			MOVF	OWN_SERIAL,W		;
			MOVWF	MSG_SERL			;
			INCF	PORT_IN,W			;
			MOVWF	MSG_DISC			;
										;
			MOVLW	C_NO_RETRY			;no retries
			MOVWF	MSG_EXPIRE			;
										;
			CALL	FIND_EMPTY_TX_Q		;Prepare reply
			BTFSS	F_MSG_FOUND			;
			GOTO	_ERROR_OUT			;
			CALL	COPY_TO_TX			;RX msg will be discarded on return
			GOTO	_FUN_A_USC			;
_ERROR_OUT	CALL	ERROR_HANDLER		;
										;
_FUN_A_USC	MOVF	PORT_IN,W			;if this USCITA is function A (LISTEN TO OWN PORT) put
			BTFSS	STATUS,Z			;
			GOTO	$+3					;
			MOVLW	FUNZIONE_USC_0		; the message also in the RX QUE
			GOTO	$+2					;
			MOVLW	FUNZIONE_USC_1		; the message also in the RX QUE
			MOVWF	FSR					;
			MOVF	INDF,W				;
			XORLW	C_OUT_LISTEN_OWN	;
			BTFSS	STATUS,Z			;
			GOTO	_REF_OUT			;
			CALL	FIND_EMPTY_RX_Q		;
			BTFSC	F_MSG_FOUND			;
			CALL	COPY_TO_RX			;
_REF_OUT	RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Write to an output port.
;IPUT:		PORT_OUT(0|1),port to write = OUT_VAL0|OUT_VAL1
;OUTPUT:	NONE
;DESTROYS:	TEMP_BYT0
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
WRITE_OUT_PORT							;
			BCF		T2CON,TMR2ON		;shut-off TMR2
			CLRF	TMR2				;
			CLRF	PORTC				;
			MOVF	PORT_OUT,F			;
			BTFSS	STATUS,Z			;
			GOTO	_WRI_PORT1			;
										;
_WRI_PORT0	MOVF	OUT_VAL0,W			;
			MOVWF	TEMP_BYT0			;
			CLRF	CCPR1L				;
			CLRC						;
			RRF		TEMP_BYT0,F			;LSB - > CCP1CON<5,4>
			BCF		CCP1CON,4			;
			BTFSC	STATUS,C			;
			BSF		CCP1CON,4			;
										;
			RRF		TEMP_BYT0,F			;
			BCF		CCP1CON,5			;
			BTFSC	STATUS,C			;
			BSF		CCP1CON,5			;
										;
			MOVLW	0x3F				;MSB - > CCPR1L
			ANDWF	TEMP_BYT0,W			;
			MOVWF	CCPR1L				;
			GOTO	_ENABL_WR			;
										;
_WRI_PORT1	MOVF	OUT_VAL1,W			;
			MOVWF	TEMP_BYT0			;
			CLRF	CCPR2L				;
			CLRC						;
			RRF		TEMP_BYT0,F			;LSB - > CCP1CON<5,4>
			BCF		CCP2CON,4			;
			BTFSC	STATUS,C			;
			BSF		CCP2CON,4			;
										;
			RRF		TEMP_BYT0,F			;
			BCF		CCP2CON,5			;
			BTFSC	STATUS,C			;
			BSF		CCP2CON,5			;
										;
			MOVLW	0x3F				;MSB - > CCPR1L
			ANDWF	TEMP_BYT0,W			;
			MOVWF	CCPR2L				;
										;
_ENABL_WR	BSF		T2CON,TMR2ON		;start TMR2
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Scan the RX queu to see if we have any pending commands to perform.  Note that ALL
;messages in the BUS have been received by the interrupt procedure, here we throw
;away everything that is not ours.
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SCAN_RX_QUEU							;
			BCF		F_ABORT_RX_FLAG		;
			MOVLW	C_NBR_ENTRIES_RX	;
			MOVWF	TEMP_BYT0			;
			MOVLW	RX_QUEU				;Find a msg in the RX_QUEU
			MOVWF	FSR					;
_FIND_RX_Q	MOVLW	0xFF				;
			XORWF	INDF,W				;
			BTFSS	STATUS,Z			;
			GOTO	_RX_MSG_FOUND		;
										;
			MOVLW	C_SIZE_RX_Q_ENTRY	;
			ADDWF	FSR,F				;
			DECFSZ	TEMP_BYT0,F			;		
			GOTO	_FIND_RX_Q			;
			GOTO	_RXQ_FIN			;
										;
_RX_MSG_FOUND							;msg found, analyze -> BREAKPOINT MESSAGE RECEIVED
			MOVF	FSR,W				;Save RX msg start
			MOVWF	RX_MSG_START		;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;INCORPORATED FOR STACK REDUCTION
;Dequeue the message, move from the RX_QUEU to the SHARED bank (MSG_TYPE...MSG_BYTE4)
;INPUT:		RX_MSG_START
;OUTPUT:	BYT0...BYTE4 filled with a copy of the msg
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
COPY_FROM_RX							;
			MOVF	RX_MSG_START,W		;
			MOVWF	FSR					;
										;
			MOVF	INDF,W				;COMMAND_TYPE
			MOVWF	MSG_TYPE			;
										;
			INCF	FSR,F				;COMMAND_SUB_TYPE
			MOVF	INDF,W				;
			MOVWF	MSG_SUBT			;
										;
			INCF	FSR,F				;SERIAL
			MOVF	INDF,W				;
			MOVWF	MSG_SERL			;
										;
			INCF	FSR,F				;DISCRMINATOR
			MOVF	INDF,W				;
			MOVWF	MSG_DISC			;
										;
			INCF	FSR,F				;ARGUMENT
			MOVF	INDF,W				;
			MOVWF	MSG_ARGT			;
;			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			MOVF	MSG_TYPE,W			;
			XORLW	TYPE_INVIO_STATO	;message type 180
			BTFSC	STATUS,Z			;
			GOTO	_COPY_INVIO_STATO	;
										;
			MOVF	MSG_TYPE,W			;message type 181
			XORLW	TYPE_INTERROG_STAT	;
			BTFSC	STATUS,Z			;
			GOTO	_INTERROG_STAT		;
										;
			MOVF	MSG_TYPE,W			;message type 183
			XORLW	TYPE_IMPOSTAZIONE_USCITA;
			BTFSC	STATUS,Z			;
			GOTO	_IMPOST_USCITA		;
										;
			MOVF	MSG_TYPE,W			;command type 170
			XORLW	TYPE_PROGRAMMAZIONE	;
			BTFSC	STATUS,Z			;
			GOTO	_PROGRAMMAZIONE		;
										;
			MOVF	MSG_TYPE,W			;command type 119
			XORLW	TYPE_INTERROG_PROGR	;
			BTFSC	STATUS,Z			;
			GOTO	_INTERROG_PROGR		;
										;
			MOVF	MSG_TYPE,W			;command type 85 - dimmer or CPU interrogation
			XORLW	TYPE_FUNZIONAMENTO	;
			BTFSS	STATUS,Z			;
			GOTO	_DISCARD			;Unknown or untreated message type - throw away
;---------------------------------------;Testing sub-type from here on
			MOVF	MSG_SUBT,W			;Check Sub-type of msg type 85
			XORLW	SUBT_INVIO_MODULO	;16
			BTFSC	STATUS,Z			;
			GOTO	_FUNZIONAMENTO_DIG	;
										;
			MOVF	MSG_SUBT,W			;
			XORLW	SUBT_RISPO_MODULO	;0
			BTFSC	STATUS,Z			;
			GOTO	_REPLY_TO_MY_MSG	;
										;
			MOVF	MSG_SUBT,W			;
			XORLW	SUBT_RISPO_C		;70 -RISPOSTA A UN ALLARME
			BTFSC	STATUS,Z			;
			GOTO	_REPLY_TO_MY_MSG	;
										;
			MOVF	MSG_SUBT,W			;
			XORLW	SUBT_RISPO_CPU		;2
			BTFSC	STATUS,Z			;
			GOTO	_REPLY_TO_MY_MSG	;
										;
			MOVF	MSG_SUBT,W			;
			XORLW	SUBT_RICH_CPU		;33
			BTFSC	STATUS,Z			;
			GOTO	_REPLY_TO_CPU		;
										;
			GOTO	_DISCARD			;Unknown or untreated message SUB-type
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;TREAT RECEIVED MESSAGES:
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
_PROGRAMMAZIONE							;FSR -> RX msg
			CALL	CHECK_SERIAL		;
			BTFSS	F_SERIAL_MATCH		;(170,X,NS,DISCRIMINATOR,ARGUMENT) 
			GOTO	_DISCARD			;NOT for us
			MOVF	MSG_DISC,W			;
			MOVWF	E2ADDRESS			;
			MOVF	MSG_ARGT,W			;
			MOVWF	E2VALUE				;
			CALL	COPY_TO_EEPROM		;Put msg data into EEPROM
			CALL	READ_STABLE_DATA	;Re-read operating parameters from EEPROM
			CALL	SEND_PROG_REPLY		;
			GOTO	_DISCARD			;Finished
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
_REPLY_TO_CPU							;(85,33,NS,0,0)
			CALL	CHECK_SERIAL		;
			BTFSS	F_SERIAL_MATCH		;
			GOTO	_DISCARD			;NOT for us
										;
			MOVLW	SUBT_RISTAT_CPU		;(1) Reply to query from CPU
			MOVWF	MSG_SUBT			;
			CLRF	MSG_DISC			;no digital states in the analogue version
			CLRF	MSG_ARGT			;
										;
			CALL	FIND_EMPTY_TX_Q		;Prepare reply
			BTFSS	F_MSG_FOUND			;
			GOTO	_CPU_FIN			;No reply is possible, msg will be repeated so ignore
										;
			MOVLW	1					;send only once
			MOVWF	MSG_EXPIRE			;
			CALL	COPY_TO_TX			;
_CPU_FIN	GOTO	_DISCARD			;Finished
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
_INTERROG_PROGR							;
			CALL	CHECK_SERIAL		;
			BTFSC	F_SERIAL_MATCH		;
			CALL	SEND_PROG_REPLY		;
			GOTO	_DISCARD			;Finished
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
_INTERROG_STAT							;
			CALL	CHECK_SERIAL		;Interrogates the state of 1 port
			BTFSC	F_SERIAL_MATCH		;
			CALL	SND_PORT_PARS		;
			GOTO	_DISCARD			;Finished
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
_COPY_INVIO_STATO						;
			CLRF	PORT_OUT			;Wether this message came from our scheda or not makes
			GOTO	_WTP_CONT			; no difference i.e.the message came frorm our own
_NEXT_USCITA							; scheda if the function of the USCITA is C_OUT_LISTEN_OWN
			INCF	PORT_OUT,F			;
			BTFSC	PORT_OUT,1			;
			GOTO	_USC_INVIO_DONE		;
										;
_WTP_CONT	MOVF	PORT_OUT,W			;
			ADDLW	LISTEN_TO_SRL		;
			MOVWF	FSR					;
			MOVF	INDF,W				;
			XORWF	MSG_SERL,W			;
			BTFSS	STATUS,Z			;
			GOTO	_NEXT_USCITA		;not the correct serial number
			MOVF	PORT_OUT,W			;
			ADDLW	LISTEN_TO_PORT		;
			MOVWF	FSR					;
			MOVF	INDF,W				;
			XORWF	MSG_DISC,W			;
			BTFSS	STATUS,Z			;
			GOTO	_NEXT_USCITA		;not the correct serial number
										;			
_ACTIVATE_OUTPUT						;
			MOVF	PORT_OUT,W			;
			BTFSS	STATUS,Z			;
			GOTO	$+3					;
			MOVLW	OUT_VAL0			;value to write
			GOTO	$+2					;
			MOVLW	OUT_VAL1			;
			MOVWF	FSR					;
			MOVF	MSG_ARGT,W			;
			MOVWF	INDF				;
			CALL	WRITE_OUT_PORT		;
			CALL	SAVE_OUTPUT_VALUE	;
_USC_INVIO_DONE							;
			GOTO	_DISCARD			;Finished
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
_IMPOST_USCITA							;
			CALL	CHECK_SERIAL		;
			BTFSS	F_SERIAL_MATCH		;
			GOTO	_IMP_DONE			;
			DECF	MSG_SUBT,W			;USCITA
			MOVWF	PORT_OUT			;
			MOVF	PORT_OUT,W			;
			BTFSS	STATUS,Z			;
			GOTO	$+3					;
			MOVLW	OUT_VAL0			;value to write
			GOTO	$+2					;
			MOVLW	OUT_VAL1			;
			MOVWF	FSR					;
			MOVF	MSG_ARGT,W			;
			MOVWF	INDF				;
			CALL	WRITE_OUT_PORT		;Force the state of a port
			CALL	SAVE_OUTPUT_VALUE	;
			CALL	SND_PORT_PARS		;
_IMP_DONE	GOTO	_DISCARD			;Finished
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
_FUNZIONAMENTO_DIG						;Dimmer activation (85,16,SN,USCITA,FRONTE)
			CALL	CHECK_SERIAL		;
			BTFSS	F_SERIAL_MATCH		;
			GOTO	_FUNZ_DIG_DONE		;
										;
			DECF	MSG_DISC,W			;PORT 1,2 -> 0,1
			MOVWF	PORT_OUT			;
		M_CMPL_JG	PORT_OUT,1,_FUNZ_DIG_DONE
			MOVF	PORT_OUT,W			;
			BTFSS	STATUS,Z			;
			GOTO	$+3					;
			MOVLW	FUNZIONE_USC_0		;
			GOTO	$+2					;
			MOVLW	FUNZIONE_USC_1		;
			MOVWF	FSR					;FSR -> FUNZIONE_USC(PORT_OUT)
										;
			MOVF	INDF,W				;(FSR -> FUNZIONE_USC)
			XORLW	C_OUT_DIMMER		;this PORT a dimmer?
			BTFSS	STATUS,Z			;
			GOTO	_FUNZ_DIG_DONE		;command is for port 0 but port 0 is not dimmer
										;
			MOVF	MSG_ARGT,W			;command for dimmer port 0
			BTFSC	STATUS,Z			;SALITA/DISCESA?
			GOTO	_DISCESA			;
										;
_SALITA		MOVF	PORT_OUT,F			;If this dimmer is OFF, do nothing when salita is received
			BTFSC	STATUS,Z			; (in the OFF state, we can only turn ON - no dimming)
			GOTO	_CHECK_OUT_0		;
			GOTO	_CHECK_OUT_1		;
_CHECK_OUT_0							;
			BTFSS	F_DIMMR_ON_0		;
			GOTO	_REPLY_FUNZ_DIG		;just reply to SALITA if we're OFF
			GOTO	_SALIT_CONT			;
_CHECK_OUT_1							;
			BTFSS	F_DIMMR_ON_1		;
			GOTO	_REPLY_FUNZ_DIG		;just reply to SALITA if we're OFF
										;
_SALIT_CONT	INCF	FSR,F				;(FSR -> ON_OFF_TIMER)
			MOVF	INDF,F				;
			BTFSS	STATUS,Z			;
			GOTO	_FUNZ_DIG_DONE		;we are already treating a command, we are waiting for OFF.
			INCF	FSR,F				;(FSR -> DIM_ACT_TIM)
			MOVF	INDF,F				;
			BTFSS	STATUS,Z			;
			GOTO	_FUNZ_DIG_DONE		;we are already dimming the port
										;
			DECF	FSR,F				;(FSR -> ON_OFF_TIMER)
			MOVLW	C_ON_OFF_WAIT		;start ON/OFF timer
			MOVWF	INDF				;
			GOTO	_REPLY_FUNZ_DIG		;
_DISCESA								;(FSR -> FUNZIONE_USC)
			INCF	FSR,F				;(FSR -> ON_OFF_TIMER)
			MOVF	INDF,F				;CASE:
			BTFSS	STATUS,Z			;1. If the ON_OFF_TIMER is running then go toggle
			GOTO	_TOGGLE_ACT			;   (Turn OFF)
										;
			MOVF	PORT_OUT,F			;2. If C_ON_OFF_WAIT is OFF and the dimmer state is off
			BTFSS	STATUS,Z			;   (Turn ON)
			GOTO	$+4					;   
			BTFSS	F_DIMMR_ON_0		; 
			GOTO	_TOGGLE_ACT			;(a salita was ignored if the dimmer state is OFF)
			GOTO	_DIM_CONT			;
			BTFSS	F_DIMMR_ON_1		;
			GOTO	_TOGGLE_ACT			;
										;
_DIM_CONT	INCF	FSR,F				;(FSR -> DIM_ACT_TIM)
			MOVF	INDF,F				;3. If C_ON_OFF_WAIT is OFF and dimmer state is ON and 
			BTFSC	STATUS,Z			;   DIM_ACT_TIM is running (e.g received OFF while dimming)
			GOTO	_REPLY_FUNZ_DIG		;
										;
			CLRF	INDF				;(FSR -> DIM_ACT_TIM)
			INCF	FSR,F				;(FSR -> OUT_VAL)
			INCF	FSR,F				;(FSR -> STEPBACK_TIM)
			MOVF	STEPBACK,W			;Dimming just finished:
			MOVWF	INDF				; a. Clear the action timer.
			CALL	SAVE_OUTPUT_VALUE	; b. Copy the number of STEP BACKs to compesate for timing
										;    delays (form release of the button until message with 
			MOVF	PORT_OUT,F			;    fronte DISCESA received),  start the STEPBACK timer
			BTFSS	STATUS,Z			; c. Save current output in EEPROM
			GOTO	$+3					; d. Toggle and save DIRECTION of the dimmer (next dimming action
			MOVLW	b'00010000'			;    will be done in the opposite direction)
			GOTO	$+2					;
			MOVLW	b'00100000'			;NOTE: the stepback (a) will occur in the new direction (b) even
			XORWF	FLAGS0,F			;      when the 
			CALL	SAVE_STATE_DIRECTION;
			GOTO	_REPLY_FUNZ_DIG		;
										;
_TOGGLE_ACT								;(FSR -> ON_OFF_TIMER)
			MOVF	PORT_OUT,F			;Toggle the state of the dimmer ON/OFF
			BTFSS	STATUS,Z			; (in the OFF state, we can only turn ON - no dimming)
			GOTO	$+3					;
_TOGGLE_0	MOVLW	b'01000000'			;toggle the correct bit
			GOTO	$+2					;
_TOGGLE_1	MOVLW	b'10000000'			;
			XORWF	FLAGS0,F			;
										;(FSR -> ON_OFF_TIMER) ON/OFF was still running
			INCF	FSR,F				;SWAP CURRENT OUTPUT VALUE WITH TOGGLE VALUE IN EEPROM
			INCF	FSR,F				;FSR -> OUT_VAL
			MOVF	INDF,W				;
			MOVWF	TEMP_BYT1			;1. Save current output value
										;
			MOVF	PORT_OUT,W			;
			ADDLW	EE_DIMM_TOGGLE		;
			CALL	READ_EEPROM			;2. Get the output value on last toggle
			MOVWF	INDF				;FSR -> OUT_VAL
										;
			CALL	WRITE_OUT_PORT		;3. Write output
										;
			MOVF	PORT_OUT,W			;4. Save new output to EEPROM
			ADDLW	EE_SAVED_OUTPUT		;
			MOVWF	E2ADDRESS			;
			MOVF	INDF,W				;FSR -> OUT_VAL
			MOVWF	E2VALUE				;
			CALL	COPY_TO_EEPROM		;
										;
			MOVF	PORT_OUT,W			;5. Save old value to EEPROM (toggle value)
			ADDLW	EE_DIMM_TOGGLE		;
			MOVWF	E2ADDRESS			;
			MOVF	TEMP_BYT1,W			;
			MOVWF	E2VALUE				;
			CALL	COPY_TO_EEPROM		;
			CALL	SAVE_STATE_DIRECTION;6. Save state
										;7. Clear timers
			DECF	FSR,F				;FSR -> OUT_VAL
			DECF	FSR,F				;FSR -> DIM_ACT_TIM
			CLRF	INDF				;FSR -> ON_OFF_TIMER
;---------------------------------------;
_REPLY_FUNZ_DIG							;
			CALL	FIND_EMPTY_TX_Q		;Prepare reply
			BTFSS	F_MSG_FOUND			;
			GOTO	_FUNZ_DIG_DONE		;No reply is possible, msg will be repeated so ignore
			CLRF	MSG_SUBT			;SUBT_RISPO_MODULO (0)
			MOVLW	1					;send only once
			MOVWF	MSG_EXPIRE			;
			CALL	COPY_TO_TX			;RX msg will be discarded on return
_FUNZ_DIG_DONE							;
			GOTO	_DISCARD			;Finished
;;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;INCORPORATED FOR STACK REDUCTION
;;85,[0|2|70],SN,USCITA|E,STATE
;;A scheda has replied to a command (MSG 85):
;;a) Check the TX_QUEU and match serial and USCITA COMANDATA, if a match is found, 
;;   delete it from the QUE.
;;b) Check to see if we are VISUALIZZAZIONE port, if we do, match serial and port to it
;;   to see if this is a delayed reply (e.g. TEMPORIZZATA or ZONE command) and match the
;;   reported state to the corresponding port.
;;INPUT:		msg in SHARED data
;;OUTPUT:	TX_QUEU entry = null
;;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
_REPLY_TO_MY_MSG						;
			BCF		F_MSG_FOUND			;
			MOVLW	TX_QUEU				;
			MOVWF	FSR					;
			MOVLW	C_NBR_ENTRIES_TX	;
			MOVWF	NBR_BYTES			;shared bank
_TRY_NEXT_TXQ							;
			MOVF	INDF,W				;Skip empty entry (0 = entry not used)
			BTFSC	STATUS,Z			;
			GOTO	_NOT_THIS_MSG		;Empty message
										;
			MOVF	FSR,W				;FSR -> start of free TX msg
			MOVWF	TX_MSG_START		;non empty TX entry
			MOVLW	TX_SERIAL			;point to serial number
			ADDWF	FSR,F				;FSR -> serial number of TX entry 
			MOVF	INDF,W				;
			XORWF	MSG_SERL,W			;
			BTFSS	STATUS,Z			;
			GOTO	_NOT_THIS_MSG		;

			MOVF	MSG_SUBT,W			;if this is a reply to an alarm, a match on SN is enough
			XORLW	SUBT_RISPO_C		;70
			BTFSC	STATUS,Z			;
			GOTO	_DELETE_MSG			;
										;
			INCF	FSR,F				;not an alarm...FSR -> TX_DISCRMINATOR (uscita da comandare)
			MOVF	INDF,W				;
			ANDWF	MSG_DISC,W			;at least one match in the reply must be made with the ports sent
			BTFSC	STATUS,Z			;
			GOTO	_NOT_THIS_MSG		;
										;TX msg found, see if we need to mirror the state
_DELETE_MSG	MOVF	TX_MSG_START,W		;IT CAN NOW BE DELETED
			MOVWF	FSR					;
			CLRF	INDF				;
			GOTO	_TXD_Q_SEAR			;we're done with this msg in the queu
_NOT_THIS_MSG							;
			DECFSZ	NBR_BYTES,F			;
			GOTO	$+2					;
			GOTO	_TXD_Q_SEAR			;no more messages
			MOVLW	C_SIZE_TX_Q_ENTRY	;
			ADDWF	FSR,F				;
			GOTO	_TRY_NEXT_TXQ		;
_TXD_Q_SEAR								;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
_DISCARD	BTFSC	F_NO_DISCARD		;
			GOTO	_CLEAR_DISC			;
			MOVF	RX_MSG_START,W		;
			MOVWF	FSR					;
			MOVLW	0xFF				;Release RX message
			MOVWF	INDF				;
_CLEAR_DISC	BCF		F_NO_DISCARD		;
_RXQ_FIN	GOTO	_RET1				;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Read EEPROM and reply
;INPUT:		Received message in SHARED data
;OUTPUT:	Message in the TX_BUFFER ready to be sent
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SEND_PROG_REPLY							;
			CALL	FIND_EMPTY_TX_Q		;Prepare reply
			BTFSS	F_MSG_FOUND			;
			GOTO	_RISP_FIN			;No reply is possible, msg will be repeated so ignore
										;
			MOVF	MSG_DISC,W			;read the EEPROM location in DISCRMINATOR
			CALL	READ_EEPROM			;
			MOVWF	MSG_ARGT			;fill ARGUMENT in TX msg
			MOVLW	TYPE_RISPOSTA		;modify the COMMAND_TYPE
			MOVWF	MSG_TYPE			;	
			MOVLW	1					;send only once
			MOVWF	MSG_EXPIRE			;
			CALL	COPY_TO_TX			;RX msg will be discarded on return
_RISP_FIN	RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Scan the TX QUEUE to see if there is a messaqge to be transmitted
;INPUT:		NONE
;OUTPUT:	NONE
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SCAN_TX_QUEU							;
			MOVLW	TX_QUEU				;TX_QUEU in bank1: address only with FSR (IRP=0)
			MOVWF	FSR					;
			MOVLW	C_NBR_ENTRIES_TX	;
			MOVWF	NBR_ENTRIES			;
_FIND_TX	MOVF	INDF,W				;Skip empty entry (0 = entry not used)
			BTFSC	STATUS,Z			;
			GOTO	_NXT_FIND_TX		;not a rdy message
										;
_CANDIDATE_FOUND						;a non-empty TX msg has been found
			MOVF	FSR,W				;Save pointer to entry in case we need to send
			MOVWF	TX_MSG_START		;
			SWAPF	INDF,W				;Look at 
			ANDLW	0x0F				;IF REXMIT counter = 0
			MOVWF	TEMP_BYT0			;
			BTFSC	STATUS,Z			;
			GOTO	_MSG_FOUND			;   send the message
										;
			DECF	TEMP_BYT0,F			;ELSE
			MOVLW	0x0F				;   decrement REXMIT counter
			ANDWF	INDF,F				;
			SWAPF	TEMP_BYT0,W			;				
			IORWF	INDF,F				;END
										;
_NXT_FIND_TX							;find another candidate
			DECFSZ	NBR_ENTRIES,F		;Continue searching for
			GOTO	$+2					; something to send
			GOTO	_NO_MORE_MSG		;Give up, no msgs to send
			MOVLW	C_SIZE_TX_Q_ENTRY	;
			ADDWF	FSR,F				;
			GOTO	_FIND_TX			;
										;
_MSG_FOUND	;CALL	TAKE_BUS			;BEAKPOINT FOR TX MSG TO BE SENT
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;INCORPORATED FOR STACK REDUCTION
;Take ownership of the bus.  Since arriving messages are handled via interrupts, the wait
;for collision can be allowed to be very short.  If a message arrives during this wait
;(e.g. we were interrupted) we will abandon the attempt to send until the next cycle 
;(interrupt service resets F_BUS_IS_MINE).  We do this done to allow greater spacing between 
;messages being sent from different schede.
;
;INPUT:		NONE
;OUTPUT:	NONE
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
TAKE_BUS	BSF		F_BUS_IS_MINE		;
			MOVF	TMR0,W				;Random value of TMR0
			MOVWF	WAIT_BUS_CLEAR		;
			BTFSS	STATUS,Z			;avoid waits of 0 cycles, add serial number
			GOTO	$+3					;
			MOVF	OWN_SERIAL,W		;
			ADDWF	WAIT_BUS_CLEAR,F	;
										;
_CHK_BUS	BTFSC	BUS_IN				;test for free bus
			GOTO	$+3					;
			BCF		F_BUS_IS_MINE		;Impossible situtation: if someone had taken it, we would 
			GOTO	_NO_MORE_MSG		;  have been interrupted, but...
										;
			BTFSS	F_BUS_IS_MINE		;If we were interrupted while waiting to take the bus (means a msg
			GOTO	_NO_MORE_MSG		; has just arrived), abandon until next cycle - see Service_Interr
										;
			DECFSZ	WAIT_BUS_CLEAR,F	;
			GOTO	_CHK_BUS			;
										;
			BTFSS	F_BUS_IS_MINE		;
			GOTO	_NO_MORE_MSG		;
										;
			BSF		STATUS,RP0			;WE OWN THE BUS!
			BCF		TRISB,1				;put RB1 in output
			BCF		STATUS,RP0			;
			BCF		INTCON,GIE			;From here on we operate without interrupts
			BCF		BUS_OUT				;Take ownership
;			CALL	MSG_SEND			;  abandon, will send later
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;INCORPORATED FOR STACK REDUCTION
;PROCEDURE: Send a message in BUS_OUT
;Send a message.  Glare has been avoided.  Runs with interrupts disabled while
;ALL OTHER PROCESSORS ARE INTERRUPTED
;
;INPUT: 	FSR -> Message to be sent
;OUTPUT:	NONE
;SUM CHECK has been calculated already
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
MSG_SEND	MOVLW	C_NBR_PROTOCOL_BYTES;
			MOVWF	NBR_BYTES			;
			MOVF	TX_MSG_START,W		;
			MOVWF	FSR					;
_NXT_T_BYTE	INCF	FSR,F				;Skip MSG_EXPIRE
			MOVF	INDF,W				;W = byte to be sent
;			CALL	SEND_BYTE			;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;INCORPORATED FOR STACK REDUCTION
;Send 8 bits of data + start and stop bits.  LSB is sent first.
;INPUT:		W=byte to send
;OUTPUT:	NONE
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SEND_BYTE								;
			MOVWF	TEMP_BYT0			;Hold the BUS LOW for the rest of the duration of
			MOVLW	8					;  C_BIT_1 before sending the HIGH for the START bit
			MOVWF	NBR_BITS			;
			MOVLW	(C_BIT_1 - 10)		;(17 clocks used in the code up to here + 2 from here to GO_LOW 
			CALL	GO_LOW				; + 2 tp begining of the loop) / 2 instructions per loop
										;
			MOVLW	C_BIT_0				;send START bit (0)
			CALL	GO_HIGH				;
			MOVLW	C_BIT_1				;go low for '1' bit
			CALL	GO_LOW				;
										;
_NEXT_T_BIT	MOVLW	C_BIT_0				;Send 8 bits data
			RRF		TEMP_BYT0,F			;
			BTFSC	STATUS,C			;
			MOVLW	C_BIT_1				;
			CALL	GO_HIGH				;
			MOVLW	C_BIT_1				;go low for '1' bit
			CALL	GO_LOW				;
			DECFSZ	NBR_BITS,F			;
			GOTO	_NEXT_T_BIT			;
										;
			MOVLW	C_BIT_1				;STOP bit
			CALL	GO_HIGH				;
;			RETURN						;return in SEND_BYTE
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			DECFSZ	NBR_BYTES,F			;
			GOTO	_NXT_T_BYTE			;
;			RETURN						;return in MSG_SEND
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			MOVF	TX_MSG_START,W		;decrement retry counter when finished
			MOVWF	FSR					;
			MOVLW	0x0F				;RXMIT counter should be 0 anyways...
			ANDWF	INDF,F				;
			DECFSZ	INDF,F				;When it reaches 0 the message expires
			GOTO	_RESET_RXMIT		;
			GOTO	_MSG_DONE			;
_RESET_RXMIT							;
			MOVLW	C_RXTIME			;C_RXTIME has the timer value in HIGH nibble
			IORWF	INDF,F				;
										;
_MSG_DONE	BSF		BUS_OUT				;release bus
			BCF		INTCON,INTF			;
			BSF		INTCON,GIE			;DONE! interrupts re-enabled
			BSF		STATUS,RP0			;
			BSF		TRISB,1				;RB1 in high impedance (input)
			BCF		STATUS,RP0			;
;			GOTO	_NXT_FIND_TX		;find other ready messages
_NO_MORE_MSG							;
			BCF		INTCON,INTF			;
			BSF		INTCON,GIE			;DONE! interrupts re-enabled
;			RETURN						;
			GOTO	_RET2				;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;INTERRUPT PROCEDURE: Receives a complete message in the ECHO BUS.  
;*** WARNING: on reception of a new message:
;1) The TX timer is incremented to give more time to all schede to digest this 
;   new message before more transmissions are attempted.
;2) TMR1 is stopped to avoid that all processor exit the interrupt procedured with this
;   timer expired
;Contains procedures RECEIVE_BYTE,RECEIVE_BIT
;(Make changes here to extend the protocol)
;INPUT:		NONE
;OUTPUT:	Empty entry on RX_QUEU filled with 6 bytes of recvd data
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Service_Interrupt						;
			MOVWF	I_W_TEMP			;I_W_TEMP MUST be in shared memory
			SWAPF	STATUS,W			;
			MOVWF	I_STATUS_TEMP		;
			CLRF	STATUS				;
			MOVWF	I_STATUS_TEMP		;
			MOVF	FSR,W				;
			MOVWF	I_FSR_TEMP			;
										;
			INCF	TIME_SCAN_TX,F		;add 1 ms to next tranmission to avoid racing
			BCF		T1CON,TMR1ON		;stop TMR1 to avoid synchoronize sending from many schede
			BCF		F_ABORT_RX_FLAG		;
			BCF		F_BUS_IS_MINE		;this is an indication to TAKE_BUS to avoid sending a message
			MOVLW	C_NBR_ENTRIES_RX	; because a new one has just been received
			MOVWF	I_TEMP_BYT0			;
			MOVLW	RX_QUEU				;Find an empty slot in the RX_QUEU
			MOVWF	FSR					;
_FIND_RX	MOVLW	0xFF				;
			XORWF	INDF,W				;
			BTFSC	STATUS,Z			;
			GOTO	_RX_CONT1			;
			MOVLW	C_SIZE_RX_Q_ENTRY	;
			ADDWF	FSR,F				;
			DECFSZ	I_TEMP_BYT0,F		;
			GOTO	_FIND_RX			;
										;
			BSF		STATUS,IRP			;NO SPACE FOR NEW MESSAGE!
			MOVLW	GARBAGE_CAN			;This message will be received but ignored
			MOVWF	FSR					;
			MOVLW	0xFF				;
			MOVWF	INDF				;
										;
_RX_CONT1	MOVF	FSR,W				;
			MOVWF	I_FREE_RX_Q			;
										;
			MOVLW	C_BIT_SUP			;bit supervision: avoid false interrupts
			MOVWF	I_SUPERVISION		;
_SFTY_HIGH	BTFSS	BUS_IN				;BUS must be LOW before call 
			GOTO	_SFTY_CONT			;  to byte receiver
			DECFSZ	I_SUPERVISION,F		;
			GOTO	_SFTY_HIGH			;
			BSF		F_ABORT_RX_FLAG		;
			GOTO	_RX_ABORT			;BUS timed out, was probably a glitch
										;
_SFTY_CONT	MOVLW	C_SIZE_RX_Q_ENTRY	;FSR is pointing at the correct queu entry
			MOVWF	I_NBR_BYTES			;
_NXT_R_BYTE	;CALL	RECEIVE_START_BIT	;STACK REDUCTION
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Receive the START bit.  We use the duty cycle of this bit to calibrate the minimum
;length of the '0' bit. 
;INPUT:		START bit in IN_BUS
;OUTPUT:	Duration of '0' bit in BIT_0 (6.25%*actual duration)
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
RECEIVE_START_BIT
			CLRWDT						;
			CALL	RECEIVE_BIT			;receive the start bit
			BTFSC	F_ABORT_RX_FLAG		;
			GOTO	_RX_ABORT			;BUS timed out
										;
			MOVF	I_TEMP_BIT,W		;I_TEMP_BIT has 100% duty cycle of START bit
			MOVWF	BIT_0				;-6% to allow for errors in variations of clock speed
			RRF		BIT_0,F				;devide by 16
			RRF		BIT_0,F				;
			RRF		BIT_0,F				;
			RRF		BIT_0,F				;
			MOVF	BIT_0,W				;
			ANDLW	0xF					;W=6.25% of BIT_0
			SUBWF	I_TEMP_BIT,W		;
			MOVWF	BIT_0				;BIT_0=Length of START bit
			;RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			CALL	RECEIVE_BYTE		;Receive 5 bytes of data in the received buffer
			CALL	RECEIVE_BIT			;receive and ignore the stop bit
			BTFSC	F_ABORT_RX_FLAG		;
			GOTO	_RX_ABORT			;BUS timed out
			MOVF	I_TEMP_BYT0,W		;
			MOVWF	INDF				;
			DECFSZ	I_NBR_BYTES,F		;
			GOTO	$+2					;
			GOTO	_RX_CS				;
			INCF	FSR,F				;
			GOTO	_NXT_R_BYTE			;
_RX_CS									;stack reduction: = CALL	RECEIVE_START_BIT
			CALL	RECEIVE_BIT			;receive the start bit
			BTFSC	F_ABORT_RX_FLAG		;
			GOTO	_RX_ABORT			;BUS timed out
										;
			MOVF	I_TEMP_BIT,W		;I_TEMP_BIT has 100% duty cycle of START bit
			MOVWF	BIT_0				;-6% to allow for errors in variations of clock speed
			RRF		BIT_0,F				;devide by 16
			RRF		BIT_0,F				;
			RRF		BIT_0,F				;
			RRF		BIT_0,F				;
			MOVF	BIT_0,W				;
			ANDLW	0xF					;W=6.25% of BIT_0
			SUBWF	I_TEMP_BIT,W		;
			MOVWF	BIT_0				;BIT_0=Length of START bit
										;
			CALL	RECEIVE_BYTE		;Receive CS but don't put it in the queu - 
			BTFSC	F_ABORT_RX_FLAG		;   NOTE: last byte: no STOP bit
			GOTO	_RX_ABORT			;BUS timed out
			MOVLW	C_SIZE_RX_Q_ENTRY	;
;			CALL	CALC_CS				;FSR points to the last received byte
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;INCORPORATED FOR STACK REDUCTION:
;Calculate a CHECK SUM	for a number for C_NBR_PROTOCOL_BYTES-1 in reverse order
;INPUT:		W = number of bytes, FSR -> last byte in the string.
;OUTPUT:	W = calculated CS, FSR -> first byte
;WARNING: Runs with disabled interrupts 
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CALC_CS		MOVWF	I_NBR_BYTES			;
			CLRW						;
_LOOP_CS	ADDWF	INDF,W				;
			DECFSZ	I_NBR_BYTES,F		;
			GOTO	$+2					;
			GOTO	_CS_DONE			;
			DECF	FSR,F				;
			GOTO	_LOOP_CS			;
_CS_DONE	;RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			XORWF	I_TEMP_BYT0,W		;FSR now points to the first received byte
			BTFSC	STATUS,Z			;
			GOTO	_ISR_END			;
										;
_RX_ABORT	MOVF	I_FREE_RX_Q,W		;Clear entry and abort
			MOVWF	FSR					;
			MOVLW	0xFF				;
			MOVWF	INDF				;Clear this entry, timeout or SC error
										;
_ISR_END	BSF		T1CON,TMR1ON		;restart timer1 
			MOVF	I_FSR_TEMP,W		;restore pre-interrupt registers
			MOVWF	FSR					;
			SWAPF	I_STATUS_TEMP,W		;
			MOVWF	STATUS				;
			SWAPF	I_W_TEMP,F			;
			SWAPF	I_W_TEMP,W			;
			BCF		INTCON,INTF			;clear interrupt flag
			RETFIE						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Receives the next 8 bits of a transmitted byte. NOTE: LSB is received first
;INPUT:		NONE
;OUTPUT:	I_TEMP_BYT0 contains the full byte
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
RECEIVE_BYTE							;
			CLRF	I_TEMP_BYT0			;prepare to receive 8 bits
			MOVLW	8					;
			MOVWF	I_NBR_BITS			;
_NEXT_R_BIT								;stack reduction: = CALL	RECEIVE_BIT	
			MOVLW	C_BIT_SUP			;
			MOVWF	I_SUPERVISION		;setup supervision
			CLRF	I_TEMP_BIT			;
_WAI_LOW2	BTFSC	BUS_IN				;wait here while bus is LOW
			GOTO	_WAI_HIGH2			;
			DECFSZ	I_SUPERVISION,F		;
			GOTO	_WAI_LOW2			;
			BSF		F_ABORT_RX_FLAG		;timed out on the 'low'
			GOTO	_END_RX_BIT2		;
										;
_WAI_HIGH2	MOVLW	C_BIT_SUP			;bus is HIGH
			MOVWF	I_SUPERVISION		;setup supervision
_NXT_HIGH2	BTFSS	BUS_IN				;next bit started
			GOTO	_END_RX_BIT2			;
			INCF	I_TEMP_BIT,F		;length of the bit received
			DECFSZ	I_SUPERVISION,F		;
			GOTO	_NXT_HIGH2			;
			BSF		F_ABORT_RX_FLAG		;timed out on the 'high'
_END_RX_BIT2							;
			BTFSC	F_ABORT_RX_FLAG		;
			GOTO	_RX_B_ABORT			;BUS timed out
			CLRC						;
			RRF		I_TEMP_BYT0,F		;TEMP_BYT0(7) is now 0
			MOVF	BIT_0,W				;Compare with calibrated '0'
			SUBWF	I_TEMP_BIT,W		;
			BTFSS	STATUS,C			;C is 1 when 0 or positive (e.g. I_TEMP_BIT>='0')
			BSF		I_TEMP_BYT0,7		;TEMP_BYT0(7)=1
			DECFSZ	I_NBR_BITS,F		;
			GOTO	_NEXT_R_BIT			;Loop to next bit
_RX_B_ABORT	RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Receive a bit coming in the ECHOBUS
;INPUT:		NONE - (BUS_IN is low)
;OUTPUT:	I_TEMP_BIT = counter with the duration of the bit received
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
RECEIVE_BIT								;
			MOVLW	C_BIT_SUP			;
			MOVWF	I_SUPERVISION		;setup supervision
			CLRF	I_TEMP_BIT			;
_WAI_LOW	BTFSC	BUS_IN				;wait here while bus is LOW
			GOTO	_WAI_HIGH			;
			DECFSZ	I_SUPERVISION,F		;
			GOTO	_WAI_LOW			;
			BSF		F_ABORT_RX_FLAG		;timed out on the 'low'
			GOTO	_END_RX_BIT			;
										;
_WAI_HIGH	MOVLW	C_BIT_SUP			;bus is HIGH
			MOVWF	I_SUPERVISION		;setup supervision
_NXT_HIGH	BTFSS	BUS_IN				;next bit started
			GOTO	_END_RX_BIT			;
			INCF	I_TEMP_BIT,F		;length of the bit received
			DECFSZ	I_SUPERVISION,F		;
			GOTO	_NXT_HIGH			;
			BSF		F_ABORT_RX_FLAG		;timed out on the 'high'
_END_RX_BIT	RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Keep the BUS_OUT line HIGH for the duration of a the bit passed in W and then put 
;it low.  Note that this procedure expects the BUS_OUT to be (already) high at start.  
;INPUT	:	W=duration (1=93, 0=61 with 4Mz Fosc) (BUS_OUT = high)
;OUTPUT:	NONE (BUS_OUT = high)
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GO_HIGH									;
			MOVWF	TEMP_BIT			;5 instruction clocks since bus is high for START bit
			BSF		BUS_OUT				;
_HOLD_HIGH	DECFSZ	TEMP_BIT,F			;8		"		"		"	"	"	"	"	DATA bit
			GOTO	_HOLD_HIGH			;8		"		"		"	"	"	"	"	STOP bit
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Put the BUS_OUT line to LOW for the duration of a '1' bit. Sets the bus high when done.
;INPUT:		W = duration of low (always bit '1')
;OUTPUT:	NONE
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GO_LOW									;
			MOVWF	TEMP_BIT			;17 intruction clocks since bus is low for START msg
			BCF		BUS_OUT				;13 intruction clocks since bus is low for START of next byte
_HOLD_LOW	DECFSZ	TEMP_BIT,F			; 4		"		"		"	"	"	"	"	any DATA bit
			GOTO	_HOLD_LOW			;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Checks the serial number in a msg of the RX_QUE
;INPUT:		RX_MSG_START
;OUTPUT:	match/no match
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CHECK_SERIAL							;
			BCF		F_SERIAL_MATCH		;initialize as no match
			MOVF	MSG_SERL,W			;
			XORWF	OWN_SERIAL,W		;
			BTFSC	STATUS,Z			;
			BSF		F_SERIAL_MATCH		;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Scan the TX_QUE for an empty msg slot
;INPUT:		NONE
;OUTPUT:	F_MSG_FOUND(T/F), FSR -> free msg
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
FIND_EMPTY_TX_Q							;
			BCF		F_MSG_FOUND			;
			MOVLW	TX_QUEU				;
			MOVWF	FSR					;
			MOVLW	C_NBR_ENTRIES_TX	;
			MOVWF	NBR_BYTES			;shared bank
_FIND_E_TX	MOVF	INDF,W				;Skip empty entry (0 = entry not used)
			BTFSC	STATUS,Z			;
			GOTO	_SLOT_FOUND			;Empty message found
										;
			DECFSZ	NBR_BYTES,F			;
			GOTO	$+2					;
			GOTO	_NOFREESLOT			;Give up, no free messages left
			MOVLW	C_SIZE_TX_Q_ENTRY	;
			ADDWF	FSR,F				;
			GOTO	_FIND_E_TX			;
										;
_SLOT_FOUND	BSF		F_MSG_FOUND			;
			MOVF	FSR,W				;FSR -> start of free TX msg
			MOVWF	TX_MSG_START		;
_NOFREESLOT RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;This procedure is used mostly by KEY actions assigned to an own port.
;Scan the RX_QUE for an empty msg slot.
;INPUT:		NONE
;OUTPUT:	F_MSG_FOUND(T/F), FSR -> free msg
;WARNING: 	Runs with INTERRUPTS DISABLED to avoid conflict with ISR
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
FIND_EMPTY_RX_Q							;
			BCF		F_MSG_FOUND			;
			MOVLW	C_NBR_ENTRIES_RX	;
			MOVWF	TEMP_BYT2			;
			MOVLW	RX_QUEU				;Find an empty slot in the RX_QUEU
			MOVWF	FSR					;
			BCF		INTCON,GIE			;disable interrupts 
_FND_QRX	MOVLW	0xFF				;0xFF indicates empty
			XORWF	INDF,W				;
			BTFSC	STATUS,Z			;
			GOTO	_RX_Q_FOUND			;
			MOVLW	C_SIZE_RX_Q_ENTRY	;
			ADDWF	FSR,F				;
			DECFSZ	TEMP_BYT2,F			;
			GOTO	_FND_QRX			;
			GOTO	_RX_Q_NOT_FOUND		;no space in RX Q
										;
_RX_Q_FOUND	CLRF	INDF				;take this message que entry inmediately
			BSF		F_MSG_FOUND			;
			MOVF	FSR,W				;FSR -> start of free RX msg
			MOVWF	RX_MSG_START		;
										;
_RX_Q_NOT_FOUND							;
			BSF		INTCON,GIE			;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Moves the message found in the SHARED bank (MSG_TYPE...MSG_ARGT) and puts it in 
;the RX_QUEU, typically used for commands assigned to my own scheda
;INPUT:		RX_MSG_START (pointer to empty RX msg)
;OUTPUT:	NONE
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
COPY_TO_RX								;
			MOVF	RX_MSG_START,W		;
			MOVWF	FSR					;
										;
			MOVF	MSG_TYPE,W			;
			MOVWF	INDF				;
										;
			INCF	FSR,F				;
			MOVF	MSG_SUBT,W			;
			MOVWF	INDF				;
										;
			INCF	FSR,F				;
			MOVF	MSG_SERL,W			;
			MOVWF	INDF				;
										;
			INCF	FSR,F				;
			MOVF	MSG_DISC,W			;			
			MOVWF	INDF				;
										;
			INCF	FSR,F				;
			MOVF	MSG_ARGT,W			;
			MOVWF	INDF				;
										;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Moves the bytes found in the SHARED bank (MSG_TYPE...MSG_ARGT) and puts them 
;in the TX_QUEU, calculates and writes the sumcheck.  Copies also the expiration data.
;INPUT:		TX_MSG_START (pointer to empty TX msg), MSG_EXPIRE
;OUTPUT:	NONE
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
COPY_TO_TX								;
			CLRF	TEMP_SC				;
			MOVF	TX_MSG_START,W		;
			MOVWF	FSR					;
										;
			MOVF	MSG_EXPIRE,W		;
			MOVWF	INDF				;
										;
			INCF	FSR,F				;
			MOVF	MSG_TYPE,W			;
			MOVWF	INDF				;
			ADDWF	TEMP_SC,F			;
										;
			INCF	FSR,F				;
			MOVF	MSG_SUBT,W			;
			MOVWF	INDF				;
			ADDWF	TEMP_SC,F			;
										;
			INCF	FSR,F				;
			MOVF	MSG_SERL,W			;
			MOVWF	INDF				;
			ADDWF	TEMP_SC,F			;
										;
			INCF	FSR,F				;
			MOVF	MSG_DISC,W			;			
			MOVWF	INDF				;
			ADDWF	TEMP_SC,F			;
										;
			INCF	FSR,F				;
			MOVF	MSG_ARGT,W			;
			MOVWF	INDF				;
			ADDWF	TEMP_SC,F			;
										;
			INCF	FSR,F				;
			MOVF	TEMP_SC,W			;
			MOVWF	INDF				;
										;
			INCF	FSR,F				;GI: KEY_TO_PORT added 
			MOVF	KEY_TO_PORT,W		;
			MOVWF	INDF				;
										;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
ERROR_HANDLER							;
			NOP							;Good spot for breakpoint
			NOP							;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Reads all operating parameters from EEPROM if the programmazione argument is <= 50
;(last port FUNZIONE)
;INPUT:		NONE
;OUTPUT:	NONE
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
READ_STABLE_DATA						;
;================================================================================
GENERAL:																			;
;================================================================================
			MOVLW	EE_MESSAGE_0_UP		;parameters lower than this get read from EEPROM 
			SUBWF	MSG_DISC,W			; everytime any one of them is programmed and at restart
			BTFSC	STATUS,C			;
			GOTO	_STABLE_DONE		;
										;
			CLRF	FLAGS0				;
			MOVLW	EE_SERIAL_NBR		;
			CALL	READ_EEPROM			;get own serial number
			MOVWF	OWN_SERIAL			;
										;
			MOVLW	EE_STEP_BACK		;
			CALL	READ_EEPROM			;number of stepbacks during end of dimming
			MOVWF	STEPBACK			;
										;
			MOVLW	EE_SAMPLE_TIMER		;
			CALL	READ_EEPROM			;get the multipliers for the sampling timer
			MOVWF	SAMPLE_TIMER_1		;
			MOVWF	SAVE_SAMPLE_TIM_1	;
			MOVLW	EE_SAMPLE_TIMER+1	;
			CALL	READ_EEPROM			;
			MOVWF	SAMPLE_TIMER_2		;
			MOVWF	SAVE_SAMPLE_TIM_2	;
;================================================================================
USCITE:																			;
;================================================================================
_INI_USCITA_0:							;
;---------------------------------------;
			MOVLW	EE_PORT_ASCOLTO		;
			CALL	READ_EEPROM			;
			MOVWF	LISTEN_TO_PORT		;
										;
			MOVLW	EE_FUNZIONE_USCITA	;IF FUNZ USCITA for port 0 = 0 (funz A)
			CALL	READ_EEPROM			; serial to listen to is OWN
			MOVWF	FUNZIONE_USC_0		;
			XORLW	C_OUT_LISTEN_OWN	;
			BTFSS	STATUS,Z			;
			GOTO	_LISTEN_OTHER_0		;
			MOVF	OWN_SERIAL,W		;
			MOVWF	LISTEN_TO_SRL		;
			GOTO	_INI_USCITA_1		;
_LISTEN_OTHER_0							;
			MOVF	FUNZIONE_USC_0,W	;
			XORLW	C_OUT_LISTEN_OTHR	;
			BTFSS	STATUS,Z			;
			GOTO	_DIMM_0				;
			MOVLW	EE_SERIAL_ASCOLTO	;
			CALL	READ_EEPROM			;
			MOVWF	LISTEN_TO_SRL		;
			GOTO	_INI_USCITA_1		;
_DIMM_0									;
			CLRF	DATA_TIMER			;timer value will be filled when activation message arrives from TEMPO_INVIO
			MOVLW	EE_DIM_DRCTN_STAT	;
			CALL	READ_EEPROM			;
			MOVWF	TEMP_BYT0			;Reset DIMMER direction
			RRF		TEMP_BYT0,F			;
			BTFSC	STATUS,C			;
			BSF		F_DIM_DIRCT_0		;
			RRF		TEMP_BYT0,F			;and ON/OFF state
			BTFSC	STATUS,C			;
			BSF		F_DIMMR_ON_0		;
;---------------------------------------;
_INI_USCITA_1:							;
;---------------------------------------;
			MOVLW	EE_PORT_ASCOLTO+1	;
			CALL	READ_EEPROM			;
			MOVWF	LISTEN_TO_PORT_1	;
										;
			MOVLW	EE_FUNZIONE_USCITA+1;
			CALL	READ_EEPROM			;
			MOVWF	FUNZIONE_USC_1		;
			XORLW	C_OUT_LISTEN_OWN	;
			BTFSS	STATUS,Z			;
			GOTO	_LISTEN_OTHER_1		;
			MOVF	OWN_SERIAL,W		;
			MOVWF	LISTEN_TO_SRL_1		;
			GOTO	_INGRESSO_0			;
_LISTEN_OTHER_1							;
			MOVF	FUNZIONE_USC_1,W	;
			XORLW	C_OUT_LISTEN_OTHR	;
			BTFSS	STATUS,Z			;
			GOTO	_DIMM_1				;
			MOVLW	EE_SERIAL_ASCOLTO+1	;
			CALL	READ_EEPROM			;
			MOVWF	LISTEN_TO_SRL_1		;
			GOTO	_INGRESSO_0			;
_DIMM_1									;
			CLRF	DATA_TIMER_1		;timer value will be filled when activation message arrives
			MOVLW	EE_DIM_DRCTN_STAT+1	;
			CALL	READ_EEPROM			;
			MOVWF	TEMP_BYT0			;Reset DIMMER direction
			RRF		TEMP_BYT0,F			;
			BTFSC	STATUS,C			;
			BSF		F_DIM_DIRCT_1		;
			RRF		TEMP_BYT0,F			;
			BTFSC	STATUS,C			;
			BSF		F_DIMMR_ON_1		;
;================================================================================
INGRESSI:																		;
;================================================================================
_INGRESSO_0:							;
;---------------------------------------;
			BSF		F_FA0_TMP_SND		;read delays for sending messages or thresholds
			MOVLW	EE_TEMPO_INVIO		;
			CALL	READ_EEPROM			;
			MOVWF	DATA_TIMER			;
			MOVWF	TEMPO_INVIO_0		;
			MOVF	DATA_TIMER,F		;
			BTFSC	STATUS,Z			;
			BCF		F_FA0_TMP_SND		;
										;
			MOVLW	EE_FUNZIONE_ING		;
			CALL	READ_EEPROM			;
			MOVWF	FUNZIONE_ING_0		;0
			XORLW	C_IN_STEP_WATCH		;
			BTFSS	STATUS,Z			;if FUNCTION=0, read the STEP
			GOTO	_FUNCT_SND_THR_0	;PORT 0 = FUNCTION B?
										;
_STEPA0		BSF		F_FA0_STEP_NZ		;
			MOVLW	EE_STEP_FUNZ_A		;STEP PORT 0 - FUNCTION A
			CALL	READ_EEPROM			;
			MOVWF	STEP_A				;
			MOVF	STEP_A,F			;If the STEP_A0=0, no send on thr crossing
			BTFSC	STATUS,Z			;
			BCF		F_FA0_STEP_NZ		;
			GOTO	_INGRESSO_1			;
_FUNCT_SND_THR_0						;Parameters port 0 - function B
			MOVF	FUNZIONE_ING_0,W	;
			XORLW	C_IN_THRHLD_WATCH	;
			BTFSS	STATUS,Z			;if FUNCTION=B, read the thresholds
			GOTO	_INGRESSO_1			;
										;
			MOVLW	16					;Read all thresholds for function B0
			MOVWF	TEMP_BYT0			;and stored in bank 2
			BSF		STATUS,IRP			;
			MOVLW	THRLD_B0_UP			;
			MOVWF	FSR					;
			MOVLW	EE_SOGLIE_FUNZ_B0_UP;
			MOVWF	TEMP_BYT1			;
_RD_EE_THR0	MOVF	TEMP_BYT1,W			;
			CALL	READ_EEPROM			;
			MOVWF	INDF				;
			DECFSZ	TEMP_BYT0,F			;
			GOTO	$+2					;
			GOTO	_INGRESSO_1			;
			INCF	TEMP_BYT1,F			;
			INCF	FSR,F				;
			GOTO	_RD_EE_THR0			;
;---------------------------------------;
_INGRESSO_1:							;
;---------------------------------------;
			BCF		STATUS,IRP			;
			BSF		F_FA1_TMP_SND		;read delays for sending messages or thresholds
			MOVLW	EE_TEMPO_INVIO+1	;
			CALL	READ_EEPROM			;
			MOVWF	DATA_TIMER_1		;
			MOVWF	TEMPO_INVIO_1		;
			MOVF	DATA_TIMER_1,F		;
			BTFSC	STATUS,Z			;
			BCF		F_FA1_TMP_SND		;IF DATA_TIMER is 0, FUCTION A-periodic send is inhibited
										;
			MOVLW	EE_FUNZIONE_ING+1	;
			CALL	READ_EEPROM			;
			MOVWF	FUNZIONE_ING_1		;
			XORLW	C_IN_STEP_WATCH		;
			BTFSS	STATUS,Z			;FUNCTION=0?
			GOTO	_FUNCT_SND_THR_1	;PORT 1 = FUNCTION B
										;
_STEPA1		BSF		F_FA1_STEP_NZ		;
			MOVLW	EE_STEP_FUNZ_A+1	;STEP PORT 1 - FUNCTION A
			CALL	READ_EEPROM			;
			MOVWF	STEP_A1				;
			MOVF	STEP_A1,F			;If STEP_A1=0, dont send msg on thr crossing
			BTFSC	STATUS,Z			;
			BCF		F_FA1_STEP_NZ		;don't send on teporary basis
			GOTO	_STABLE_DONE		;
_FUNCT_SND_THR_1						;PORT 1 = FUNCTION B
			MOVF	FUNZIONE_ING_1,W	;
			XORLW	C_IN_THRHLD_WATCH	;
			BTFSS	STATUS,Z			;
			GOTO	_STABLE_DONE		;
										;
			MOVLW	16					;
			MOVWF	TEMP_BYT0			;
			BSF		STATUS,IRP			;The thresholds for FUNCTION B are stored in bank 2
			MOVLW	THRLD_B1_UP			;
			MOVWF	FSR					;
			MOVLW	EE_SOGLIE_FUNZ_B1_UP;FILL IN PARAMETERS POR INGRESSO FUNCTION B
			MOVWF	TEMP_BYT1			;
										;
_RD_EE_THR1	MOVF	TEMP_BYT1,W			;Read all thresholds for function B0
			CALL	READ_EEPROM			;
			MOVWF	INDF				;
			DECFSZ	TEMP_BYT0,F			;
			GOTO	$+2					;
			GOTO	_STABLE_DONE		;
			INCF	TEMP_BYT1,F			;
			INCF	FSR,F				;
			GOTO	_RD_EE_THR1			;
_STABLE_DONE							;
			BCF		STATUS,IRP			;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Read a THRESHOLD B message and put it in the the MSG_... variables in shared data.
;INPUT:		W = beginning EEPROM address of message to be read
;OUTPUT:	message in message variables
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SEND_EEPROM_MSG							;
			MOVWF	MSG_HEAD_EE			;MMM - ADD RETRY ACCORDING TO TYPE AND SUBTYPE
			MOVLW	C_SIZE_RX_Q_ENTRY	;5	
			MOVWF	TEMP_BYT2			;
			MOVLW	MSG_TYPE			;
			MOVWF	FSR					;
_NXT_BYTE	MOVF	MSG_HEAD_EE,W		;
			CALL	READ_EEPROM			;
			MOVWF	INDF				;
			INCF	FSR,F				;
			INCF	MSG_HEAD_EE,F		;
			DECFSZ	TEMP_BYT2,F			;
			GOTO	_NXT_BYTE			;
										;
			MOVF	MSG_TYPE,W			;
			XORLW	TYPE_FUNZIONAMENTO	;85,....
			BTFSS	STATUS,Z			;
			GOTO	_MIN_RETRIES		;
										;
			MOVF	MSG_SUBT,W			;
			XORLW	SUBT_INVIO_MODULO	;85,16,..
			BTFSC	STATUS,Z			;
			GOTO	_MAX_RETRIES		;
										;
			MOVF	MSG_SUBT,W			;
			XORLW	SUBT_ALLARME_C		;85,128,..
			BTFSC	STATUS,Z			;
			GOTO	_MAX_RETRIES		;
										;
			MOVF	MSG_SUBT,W			;
			XORLW	SUBT_INVIO_CPU		;85,34,..
			BTFSC	STATUS,Z			;
			GOTO	_MAX_RETRIES		;
			GOTO	_MIN_RETRIES		;
_MAX_RETRIES							;
			MOVLW	C_MAX_RETRIES		;
			MOVWF	MSG_EXPIRE			;
			GOTO	_EE_MSG_SND			;
_MIN_RETRIES							;
			MOVLW	C_NO_RETRY			;
			MOVWF	MSG_EXPIRE			;
										;
_EE_MSG_SND	CALL	FIND_EMPTY_TX_Q		;
			BTFSC	F_MSG_FOUND			;
			GOTO	$+3					;
			CALL	ERROR_HANDLER		;ERROR: NO TX ENTRY AVAILABLE FOR REPLY
			GOTO	_PORT_PARS_FIN		;
			CALL	COPY_TO_TX			;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Save recently written output value to EEPROM
;INPUT:		PORT_OUT,OUT_VALX
;OUTPUT:	NONE
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SAVE_OUTPUT_VALUE						;
			MOVF	PORT_OUT,W			;
			BTFSS	STATUS,Z			;
			GOTO	$+3					;
			MOVF	OUT_VAL0,W			;
			GOTO	$+2					;
			MOVF	OUT_VAL1,W			;
			MOVWF	E2VALUE				;
			MOVF	PORT_OUT,W			;
			ADDLW	EE_SAVED_OUTPUT		;Restore output values before restart
			MOVWF	E2ADDRESS			;
			CALL	COPY_TO_EEPROM		;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Save the current state and direction bits of the dimmer in EEPROM.
;INPUT:		FLAGS0<F_DIM_DIRCT_0,F_DIM_DIRCT_1,F_DIMMR_ON_0,F_DIMMR_ON_1> (4,5,6,7)
;OUTPUT:	NONE
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SAVE_STATE_DIRECTION					;
			BCF		F_UPD_EEPROM		;save dimmer directions/state when necessary
			CLRF	E2VALUE				;
			BTFSC	F_DIM_DIRCT_0		;convert bit to byte (direction 0)
			BSF		E2VALUE,0			;
			BTFSC	F_DIMMR_ON_0		;convert bit to byte (state 0)
			BSF		E2VALUE,1			;
			MOVLW	EE_DIM_DRCTN_STAT	;
			MOVWF	E2ADDRESS			;
			CALL	COPY_TO_EEPROM		;
			CLRF	E2VALUE				;
			BTFSC	F_DIM_DIRCT_1		;convert bit to byte (direction 1)
			BSF		E2VALUE,0			;
			BTFSC	F_DIMMR_ON_1		;convert bit to byte (state 1)
			BSF		E2VALUE,1			;
			MOVLW	EE_DIM_DRCTN_STAT+1	;
			MOVWF	E2ADDRESS			;
			CALL	COPY_TO_EEPROM		;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Write to EEPROM
;Input:		E2ADDRESS,E2VALUE
;Output:	None
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
COPY_TO_EEPROM							;
			BANKSEL	EECON1				;
			BTFSC	EECON1,WR			;b2
			GOTO	$-1					;
			BANKSEL	E2ADDRESS			;b0
			MOVF	E2ADDRESS,W			;
			BANKSEL	EEADR				;b2
			MOVWF	EEADR				;
			BANKSEL	E2VALUE				;b0
			MOVF	E2VALUE,W			;
			BANKSEL	EEDATA				;b2
			MOVWF	EEDATA				;
			BANKSEL	EECON1				;b3
			BCF		EECON1,EEPGD		;
			BSF		EECON1,WREN			;
			BCF		INTCON,GIE			;cc
										;
			MOVLW	0x55				;required sequence
			MOVWF	EECON2				;b3
			MOVLW	0xAA				;
			MOVWF	EECON2				;b3
			BSF		EECON1,WR			;b3
										;required sequence
			BSF		INTCON,GIE			;cc
			BCF		EECON1,WREN			;
			BANKSEL	TIME_SCAN_TX		;bank 0
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Read EEPROM memory.
;Input: 	W=address
;Output: 	W=value read
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
READ_EEPROM								;
			BANKSEL	EECON1				;
			BTFSC	EECON1,WR			;
			GOTO	$-1					;
			BANKSEL	EEADR				;
			MOVWF	EEADR				;
			BANKSEL	EECON1				;
			BCF		EECON1,EEPGD		;
			BSF		EECON1,RD			;
			BANKSEL	EEDATA				;
			MOVF	EEDATA,W			;W=eeprom data
			BANKSEL	TIME_SCAN_TX		;bank 0
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;EEPROM ADDRESSES
			ORG		(0x2100+EE_FUNZIONE_ING)
			DE		0,0
;			DE		0,2							;test: not used, C_IN_thrh_WATCH

			ORG		(0x2100+EE_FUNZIONE_USCITA)
;			DE		0,0
			DE		1,1							;test: funzione dimmer

			ORG		(0x2100+EE_TEMPO_INVIO)
			DE		0,0
;			DE		3,3							;TEST:  SEND MESSAGE EVERY 3 SECOND

			ORG		(0x2100+EE_STEP_FUNZ_A)
			DE		0,0
;			DE		5,5								;test value: STEP 5
			
			ORG		(0x2100+EE_TEMPO_ATTIVAZIONE)
			DE		0,0								;NOT USED

			ORG		(0x2100+EE_SOGLIE_FUNZ_B0_UP)
;			DE		0,0,0,0,0,0,0,0
			DE		0x10,0x20,0x30,0x40,0x50,0x60,0x70,0x80

			ORG		(0x2100+EE_SOGLIE_FUNZ_B0_DWN)
;			DE		0,0,0,0,0,0,0,0
			DE		0x10,0x20,0x30,0x40,0x50,0x60,0x70,0x80

			ORG		(0x2100+EE_SOGLIE_FUNZ_B1_UP)
;			DE		0,0,0,0,0,0,0,0
			DE		0x20,0x40,0x60,0x80,0xA0,0xC0,0xE0,0xF0

			ORG		(0x2100+EE_SOGLIE_FUNZ_B1_DWN)
;			DE		0,0,0,0,0,0,0,0
			DE		0x18,0x38,0x58,0x78,0x98,0xB8,0xD8,0xE8

			ORG		(0x2100+EE_TIPO_SCHEDA)
			DE		3

			ORG		(0x2100+EE_SW_VERSION)
			DE		1

			ORG		(0x2100+EE_SERIAL_ASCOLTO)
			DE		0,0

			ORG		(0x2100+EE_PORT_ASCOLTO)	;DEFAULT = LISTEN TO OWN INGRESSO
			DE		1,2

			ORG		(0x2100+EE_SERIAL_NBR)
			DE		254

			ORG		(0x2100+EE_STEP_BACK)
			DE		1

			ORG		(0x2100+EE_SAMPLE_TIMER)
			DE		1,10						;(based on 10ms = 400 ms per AVERAGE

			ORG		(0x2100+EE_MESSAGE_0_UP)
			DE		85,34,2,1,1
			DE		85,34,2,2,2
			DE		85,34,2,4,4
			DE		85,34,2,8,8
			DE		85,34,2,16,16
			DE		85,34,2,32,32
			DE		85,34,2,64,64
			DE		85,34,2,128,128
;
			DE		85,34,2,1,0
			DE		85,34,2,2,0
			DE		85,34,2,4,0
			DE		85,34,2,8,0
			DE		85,34,2,16,0
			DE		85,34,2,32,0
			DE		85,34,2,64,0
			DE		85,34,2,128,0
;
			DE		85,34,3,1,1
			DE		85,34,3,2,2
			DE		85,34,3,4,4
			DE		85,34,3,8,8
			DE		85,34,3,16,16
			DE		85,34,3,32,32
			DE		85,34,3,64,64
			DE		85,34,3,128,128
;
			DE		85,34,3,1,0
			DE		85,34,3,2,0
			DE		85,34,3,4,0
			DE		85,34,3,8,0
			DE		85,34,3,16,0
			DE		85,34,3,32,0
			DE		85,34,3,64,0
			DE		85,34,3,128,0

			ORG		(0x2100+EE_SAVED_SAMPLE)
			DE		0,0

			ORG		(0x2100+EE_SAVED_OUTPUT)
			DE		0,0
;			DE		0,128

			ORG		(0x2100+EE_SAVED_CURSOR)
			DE		0,0

			ORG		(0x2100+EE_DIMM_TOGGLE)
			DE		0,0

			ORG		(0x2100+EE_DIM_DRCTN_STAT)
			DE		3,3							;default <0>,DIRECTION=UP,<1>STATE=ON

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			END							;PROGRAM FINISHED
