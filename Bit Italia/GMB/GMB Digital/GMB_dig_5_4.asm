;************************************************************
;	TITLE:	ECHO BUS multinodal control ----- Version for 9 ports IN, 8 out
;	Programmer: GINO ISLA for BIT Srl.
;	REVISION HISTORY:	08-11-03 
;	FREQUENCY: 4MHz
;   **** ALL CHANGES MUST MADE IN GMB_dig_9_8.asm AND THEN PUT IN ***
;   ****                   GMB_dig_5_4.asm       ***
;************************************************************
			list	p=16f628

;#define		IN_9_OUT_8
#define		IN_5_OUT_4

#include	<p16f628.inc>
#include 	<gmb_digital.h>

	__CONFIG _BODEN_ON&_CP_OFF&_PWRTE_ON&_WDT_ON&_INTRC_OSC_NOCLKOUT&_MCLRE_OFF&_LVP_OFF&_DATA_CP_OFF
	ERRORLEVEL -302

	UDATA
TIME_SCAN_TX		RES		1	;reduced timer to treat the msg TX QUE
TIME_SCAN_RX		RES		1	;reduced timer to treat the msg RX QUE
TIME_ALL_SCAN		RES		1	;reduced timer for periodic jobs
TIME_KEY_SCAN		RES		1	;reduced timer for KEY scanning
;
TEMP_BYT0			RES		1	;general purpose byte hold
TEMP_BYT1			RES		1	;general purpose byte hold
TEMP_BYT2			RES		1	;general purpose byte hold
;
BIT_0				RES		1	;length of a '0' bit
FLAGS0				RES 	1	;miscellaneous flags (see below)
FLAGS1				RES 	1	;miscellaneous flags (see below)
;
OWN_SERIAL			RES		1	;These are the mirror registers of their equivalent in EEPROM
OWN_PROGRAM			RES		1	;program type
POLARITA			RES		1	;Port polarity (neg/pos)
FUNZIONE			RES		8	;Port functions
;
SCHEDA				RES		1	;
USCITA				RES		1	;
;
MULTICOM			RES		1	;Counter for next multicommands (no multi command pending=8)
MULT_ITNVAL			RES		1	;base for delay between multiple commands
MULTIMER			RES		1	;Time counter between commands (multiples of 50ms)
;
ACTIVE_ZONE			RES		1	;Zone number for which port actions are pending in this scheda
ZONE_COUNTR			RES		1	;Counter for next zone command (no zone action pending=8)
ZONE_INTVAL			RES		1	;base for delay between multiple
ZONETIMER			RES		1	;Time counter between zone commands (multiples of 50ms)
SCHEDA_DELAY2		RES		1	;To extend the delay of RIT_SCHEDA using 50ms delay iso of 100ms
ZONE_COMMAND		RES		1	;New state for the porta in a zone (could be forced)
ZONE_PORTS			RES		1	;Ports that were changed when executing zone command - for reply message
;
ONE_SECOND			RES		1	;1 second reduced counter
PORT_MINUTES		RES		8	;Number of minutes until shutoff (temporizzate, tapparella)
PORT_SECONDS		RES		8	;Number of seconds until shutoff (temporizzate, tapparella)
TIMER_INFO			RES		1	;temporary use of temporizzatto
;
OWN_PORT_TAP		RES		1	;own port for TAPPARELLA function
OTHRPORT_TAP		RES		1	;other port for TAPPARELLA function
OWNSTATE			RES		1	;own state for TAPPARELLA 
OTHRSTATE			RES		1	;other side state for TAPPARELLA 
;
PORTSTATE			RES		1	;Bit array for state of the ports
PRTSTATES			RES		1	;Bit array for state of the ports
FRONTE				RES		1	;1/0 for salita/discesa
NBR_PORT			RES		1	;port counter
GET_PORT			RES		1	;  "    "   used in READ_ALL_PORT_STATES
RD_WR_PORT			RES		1	;  "    "     "   " to access port state
;
NBR_ENTRIES			RES		1	;nbr of entries in the qeueus
WAIT_BUS_CLEAR		RES		1	;wait period to get hold of the bus
KEY_COUNTER			RES		1	;Identifies the KEY (tasto) being scanned
KEY_MASK			RES		1	;Local storage for PORTB
PREV_KEYS			RES		1	;previous state of the keys
KEY_CHANGES			RES		1	;Array of changed keys since last scan
KEYSTATES			RES		1	;Current state of all keys
KEY_STATE			RES		1	;Current state of a single key
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
Bank1Data 			UDATA	
TX_QUEU				RES		(C_SIZE_TX_Q_ENTRY*C_NBR_ENTRIES_TX)	;reserved space for sending data
RX_QUEU				RES		(C_SIZE_RX_Q_ENTRY*C_NBR_ENTRIES_RX)	;reserve space incoming msgs (no SUM_CHK)
;
Bank2Data			UDATA
GARBAGE_CAN			RES		10	;in case no RX messages available, put unwanted message here

	UDATA_SHR					;Common bank
I_W_TEMP			RES		1	;save environment
TEMP_BIT			RES 	1	;general purpose bit hold
NBR_BITS			RES		1	;general purpose bit counter
NBR_BYTES			RES		1	;general purpose byte counter
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
;
;Miscellaneous flags
#define		F_MULTIKEY_NOW	FLAGS0,0	;
#define		F_MULTIKEY_PRE	FLAGS0,1	;
#define		F_REP_KEY_READ	FLAGS0,2	;
#define		F_DELAY_SCHEDA	FLAGS0,3	;
#define		F_ABORT_RX_FLAG	FLAGS0,4	;
#define		F_BUS_IS_MINE	FLAGS0,5	;
#define		F_SERIAL_MATCH	FLAGS0,6	;
#define		F_MSG_FOUND		FLAGS0,7	;
#define		F_STATEZONE_KEY	FLAGS1,0	;
#define		F_ZONE_MSG_SNT	FLAGS1,1	;
#define		F_INITIALIZING	FLAGS1,2	;
#define		F_DEFER_MSG		FLAGS1,3	;
#define		F_HAVE_VISUAL	FLAGS1,4	;
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
;Begining of executable code			;
			org		0x05				;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Table lookup for key interface with CD4051.  Returns the correct bit sequence for
;the port number (RB5,RB4,RB3 and  RB0,RB1,RB0)
SELECT_KEY	ADDWF	PCL,F				;
			RETLW	b'00000100'			;RB7,RB6 || Key 1 0x00 || RB2,RB1,RB0
			RETLW	b'00100100'			;	"		Key 2 0x20			"
			RETLW	b'00010100'			;	"		Key 3 0x10			"
			RETLW	b'00110100'			;	"		Key 4 0x30			"
			RETLW	b'00001100'			;	"		Key 5 0x08			"
			RETLW	b'00101100'			;	"		Key 6 0x28			"
			RETLW	b'00011100'			;	"		Key 7 0x18			"
			RETLW	b'00111100'			;	"		Key 8 0x38			"
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Truth tables for different function types of the ports
;INPUTS:	W<0,1> = operands (INPUT,CURRENT STATE)
;OUTPUTS:	W<0>=ON/OFF
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
TABLE_MONOSTABILE						;
			ADDWF	PCL,F				;
			RETLW	OFF					;W=b'00000000'
			RETLW	OFF					;W=b'00000001'
			RETLW	ON					;W=b'00000010'
			RETLW	ON					;W=b'00000011'
										;
TABLE_INVERTITORE						;
			ADDWF	PCL,F				;
			RETLW	ON					;
			RETLW	OFF					;	"
			RETLW	ON					;
			RETLW	OFF					;
										;
TABLE_PASSOPASSO						;
			ADDWF	PCL,F				;
			RETLW	OFF					;
			RETLW	ON					;	"
			RETLW	ON					;
			RETLW	OFF					;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Read port state.
;INPUT:		W = PORT NUMBER
;OUTPUT:	PORT_STATE<0> has the current state of the port
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
READ_PORT_STATE							;
			MOVWF	RD_WR_PORT			;save port number
			ADDWF	PCL,F				;go read the correct port bit
			GOTO	_RPORT0				;
			GOTO	_RPORT1				;
			GOTO	_RPORT2				;
			GOTO	_RPORT3				;
			GOTO	_RPORT4				;
			GOTO	_RPORT5				;
			GOTO	_RPORT6				;
			GOTO	_RPORT7				;
										;
_RPORT0		BTFSC	PORTA,0				;
			BSF		PORTSTATE,0			;
			GOTO	_RPORT_FIN			;
_RPORT1		BTFSC	PORTA,1				;
			BSF		PORTSTATE,0			;
			GOTO	_RPORT_FIN			;
_RPORT2		BTFSC	PORTA,2				;
			BSF		PORTSTATE,0			;
			GOTO	_RPORT_FIN			;
_RPORT3		BTFSC	PORTA,3				;
			BSF		PORTSTATE,0			;
			GOTO	_RPORT_FIN			;
_RPORT4		BTFSC	PORTB,7				;
			BSF		PORTSTATE,0			;
			GOTO	_RPORT_FIN			;
_RPORT5		BTFSC	PORTA,6				;
			BSF		PORTSTATE,0			;
			GOTO	_RPORT_FIN			;
_RPORT6		BTFSC	PORTA,7				;
			BSF		PORTSTATE,0			;
			GOTO	_RPORT_FIN			;
_RPORT7		BTFSC	PORTB,6				;
			BSF		PORTSTATE,0			;
										;
_RPORT_FIN	INCF	RD_WR_PORT,F		;
			MOVF	POLARITA,W			;
			MOVWF	TEMP_BYT1			;
										;
_RD_POL		DECFSZ	RD_WR_PORT,F		;adjust the state according to polarization bit
			GOTO	$+2					;
			GOTO	$+3					;
			RRF		TEMP_BYT1,F			;rotate TEMP_BYT1 till bit <0> has the correct polarity of this port
			GOTO	_RD_POL				;
										;
			MOVF	PORTSTATE,W			;
			XORWF	TEMP_BYT1,F			;TEMP_BYT1<0> now has the state of the port
			RRF		PORTSTATE,F			;shift to prepare PORTSTATE<0>
			RRF		TEMP_BYT1,F			;STATUS<C> has the polarized value of the port
			RLF		PORTSTATE,F			;  move it into PORTSTATE<0>
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Write to a port taken into consideration the polarity defined in EEPROM.
;INPUT:		W = port number, PORTSTATE=new state
;OUTPUT:	modified port state
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
WRITE_PORT_STATE						;
			MOVWF	RD_WR_PORT			;save port number
			BTFSC	F_INITIALIZING		;ignore polarity (during START ports are read as is)
			GOTO	_WRITE_TAB			;
										;
			INCF	RD_WR_PORT,W		;
			MOVWF	NBR_BITS			;
			MOVF	POLARITA,W			;
			MOVWF	TEMP_BYT1			;
										;
_WR_POL		DECFSZ	NBR_BITS,F			;
			GOTO	$+2					;
			GOTO	$+3					;
			RRF		TEMP_BYT1,F			;rotate TEMP_BYT1 till bit <0> has the polarity of this port
			GOTO	_WR_POL				;
										;
			MOVF	PORTSTATE,W			;
			XORWF	TEMP_BYT1,F			;TEMP_BYT1<0> now has the OUTPUT value of the port
			RRF		PORTSTATE,F			;shift to prepare PORTSTATE<0>
			RRF		TEMP_BYT1,F			;STATUS<C> has the OUTPUT value of the port
			RLF		PORTSTATE,F			;  move it into PORTSTATE<0>
										;
_WRITE_TAB	MOVF	RD_WR_PORT,W		;
			ADDWF	PCL,F				;
			GOTO	_WPORT0				;
			GOTO	_WPORT1				;
			GOTO	_WPORT2				;
			GOTO	_WPORT3				;
			GOTO	_WPORT4				;
			GOTO	_WPORT5				;
			GOTO	_WPORT6				;
			GOTO	_WPORT7				;
										;
_WPORT0		BTFSS	PORTSTATE,0			;
			BCF		PORTA,0				;
			BTFSC	PORTSTATE,0			;
			BSF		PORTA,0				;
			GOTO	_WPORT_FIN			;
										;
_WPORT1		BTFSS	PORTSTATE,0			;
			BCF		PORTA,1				;
			BTFSC	PORTSTATE,0			;
			BSF		PORTA,1				;
			GOTO	_WPORT_FIN			;
										;
_WPORT2		BTFSS	PORTSTATE,0			;
			BCF		PORTA,2				;
			BTFSC	PORTSTATE,0			;
			BSF		PORTA,2				;
			GOTO	_WPORT_FIN			;
										;
_WPORT3		BTFSS	PORTSTATE,0			;
			BCF		PORTA,3				;
			BTFSC	PORTSTATE,0			;
			BSF		PORTA,3				;
			GOTO	_WPORT_FIN			;
										;
_WPORT4		BTFSS	PORTSTATE,0			;
			BCF		PORTB,7				;
			BTFSC	PORTSTATE,0			;
			BSF		PORTB,7				;
			GOTO	_WPORT_FIN			;
										;
_WPORT5		BTFSS	PORTSTATE,0			;
			BCF		PORTA,6				;
			BTFSC	PORTSTATE,0			;
			BSF		PORTA,6				;
			GOTO	_WPORT_FIN			;
										;
_WPORT6		BTFSS	PORTSTATE,0			;
			BCF		PORTA,7				;
			BTFSC	PORTSTATE,0			;
			BSF		PORTA,7				;
			GOTO	_WPORT_FIN			;
										;
_WPORT7		BTFSS	PORTSTATE,0			;
			BCF		PORTB,6				;
			BTFSC	PORTSTATE,0			;
			BSF		PORTB,6				;
_WPORT_FIN								;
			BTFSC	F_INITIALIZING		;don't rewrite port states during START
			GOTO	_END_WRITE_PORT		;
;			CALL	READ_ALL_PORT_STATES; *** CALL ELIMINATED, STACK REDUCTION
			CLRF	PORTSTATE			;
			CLRF	PRTSTATES			;
			CLRF	GET_PORT			;
_READ_PORT2	MOVF	GET_PORT,W			;
			CALL	READ_PORT_STATE		;
			RRF		PORTSTATE,F			;portstate in STATUS<C>
			RRF		PRTSTATES,F			;port state in PRTSTATES<8>
										;
			INCF	GET_PORT,F			;
			MOVF	GET_PORT,W			;8 OR 4
			XORLW	C_NBR_OF_PORTS		;
			BTFSS	STATUS,Z			;
			GOTO	_READ_PORT2			;
										;
			MOVF	PRTSTATES,W			;
			MOVWF	PORTSTATE			;
  ifdef IN_5_OUT_4
 			SWAPF	PORTSTATE,F			;only 4 ports read, make sure portstate bit occupy lower nibble
			MOVLW	0x0F				;
			ANDWF	PORTSTATE,F			;
  endif
			MOVF	PORTSTATE,W			;
			MOVWF	E2VALUE				;
			MOVLW	EE_STATO_USCITE		;
			MOVWF	E2ADDRESS			;
			CALL	COPY_TO_EEPROM		;
_END_WRITE_PORT							;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
;WARNING, ALL PROCEDURES ABOVE THIS REFERENCE JUMP TABLES, DON'T MOVE THEM!
;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;++++++++++++++++++++++++ START OF THE PROGRAM +++++++++++++++++++++++++++++++++
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
Start									;
;			BSF		STATUS,RP0			;leave out comments when no debug
;			BTFSC	PCON,1				;POWER ON?
;			GOTO	_NO_RESET			;
										;
			BCF		STATUS,RP0			;
			BCF		INTCON,GIE			;Disable interrupts
			MOVLW	0x07				;
			MOVWF	CMCON				;comparator p.57
			CLRF	PORTA				;
			CLRF	PORTB				;
			CLRF	PREV_KEYS			;Initialize local varialbles
			CLRF	KEY_CHANGES			;
										;
			BSF		STATUS,RP0			;BANK 1 REGISTERS
			CLRF	PIE1				;
			MOVLW	b'10001011'			;OPTION<6>=0=int on falling edge RB0, ...SELECT TMR0 AND WDT OPTION
			MOVWF	OPTION_REG			;PortB pullups disabled
			MOVLW	b'00100000'			;RA5 = multitasto IN
			MOVWF	TRISA				;RA7,RA6,RA3,RA2,RA1,RA0 + RB5, RB7 = USCITE
	ifdef	IN_9_OUT_8
			MOVLW	b'00100000'			;RA5 = multitasto IN
			MOVWF	TRISA				;RA7,RA6,RA3,RA2,RA1,RA0 + RB5, RB7 = USCITE
			MOVLW	b'00000111'			;9_8: RB0=ECHOBUS OUT, RB1=ECHOBUS IN, RB2=IN KEYS
			MOVWF	TRISB				;
	else
			MOVLW	b'11100000'			;RA5 = multitasto IN
			MOVWF	TRISA				;RA7,RA6,RA3,RA2,RA1,RA0 + RB5, RB7 = USCITE
			MOVLW	b'11111111'			;5_IN_4_OUT: RB0=ECHOBUS OUT, RB1=ECHOBUS IN, RB2,RB3,RB4,RB5=IN KEYS
			MOVWF	TRISB				;
	endif	
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
			BCF		STATUS,RP0			;
			CLRF	NBR_BYTES			;clear all LONG TIMERS (MINUTES and SECONDS
			MOVLW	PORT_MINUTES		;
			MOVWF	FSR					;
_TEMPO_TMRS	CLRF	INDF				;
			INCF	FSR,F				;
			INCF	NBR_BYTES,F			;
			BTFSS	NBR_BYTES,4			;
			GOTO	_TEMPO_TMRS			;
										;
			CLRF	ZONE_INTVAL			;not active
			CLRF	ZONETIMER			;not active
			CLRF	FLAGS0				;
			CLRF	FLAGS1				;
			CLRF	ZONE_PORTS			;
			MOVLW	8					;MULTICOM =8  means last multikey command has been processed
			MOVWF	MULTICOM			;(i.e. no more multicommands left to process)
			MOVWF	ZONE_COUNTR			;(i.e no zone actions pending)
										;
			MOVLW	1					;to force re-read of EEPROM
			MOVWF	MSG_DISC			;
			CALL	READ_STABLE_DATA	;Read operating parameters from EEPROM
										;Reset ALL reduced timers and counters
_NO_RESET	BSF		STATUS,RP0			;
			BSF		PCON,1				;set POR bit (1=no POR)
			BCF		STATUS,RP0			;
										;
			MOVLW	C_RX_TIMER			;Reset basic timers
			MOVWF	TIME_SCAN_RX		;
										;
			MOVLW	C_TX_TIMER			;
			MOVWF	TIME_SCAN_TX		;
										;
			MOVLW	C_SEVENTY_MS		;key_scan and job_scan start at different times
			MOVWF	TIME_ALL_SCAN		;
										;
			MOVLW	C_FIFTY_MS			;
			MOVWF	TIME_KEY_SCAN		;
										;
			MOVLW	C_ONESECOND			;start seconds timer
			MOVWF	ONE_SECOND			;
										;
			BSF		F_INITIALIZING		;
			MOVLW	EE_STATO_USCITE		;reset ports to original values
			CALL	READ_EEPROM			;
			MOVWF	PORTSTATE			;
			CLRF	NBR_BYTES			;
_NXT_PORT_INI							;
			MOVF	NBR_BYTES,W			;
			CALL	WRITE_PORT_STATE	;
			RRF		PORTSTATE,F			;
			INCF	NBR_BYTES,F			;
			BTFSS	NBR_BYTES,C_MAXBIT	;
			GOTO	_NXT_PORT_INI		;
			BCF		F_INITIALIZING		;
										;
			MOVLW	C_TIMER1_H			;
			MOVWF	TMR1H				;
			MOVLW	C_TIMER1_L			;
			MOVWF	TMR1L				;
			BCF		PIR1,TMR1IF			;clear TMR1 interrupt flag
			MOVLW	b'00000001'			;prescale 1:1, internal clk,TMR1ON
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
			MOVWF	TMR1L				;
										;
			DECFSZ	TIME_SCAN_RX,F		;SCAN RX QUEU every 5ms
			GOTO	_SCAN_TX			;
			GOTO	SCAN_RX_QUEU		;GOTO ISO CALLs for STACK REDUCTION
_RET1		MOVLW	C_RX_TIMER			;reset RX timer
			MOVWF	TIME_SCAN_RX		;
										;
_SCAN_TX	DECFSZ	TIME_SCAN_TX,F		;SCAN TX QUEU every 15ms
			GOTO	_SCAN_JOBS			;
			GOTO	SCAN_TX_QUEU		;GOTO ISO CALLs for STACK REDUCTION
_RET2		MOVLW	C_TX_TIMER			;reset TX timer
			MOVWF	TIME_SCAN_TX		;
										;
_SCAN_JOBS	DECFSZ	TIME_ALL_SCAN,F		;every 50ms
			GOTO	_KEYS_SCAN			;
			GOTO	ZONE_NEXT_COMM		;ZONE and MULTIKEY procs use additional reduced counters 
_RET3		GOTO	MULTIKEY_NEXT_COMM	; (based on the 50ms TIME_ALL_SCAN)
_RET4		GOTO	CHECK_LONG_TIMERS	;This uses reduced counters based on 1 second counter
_RET5		MOVLW	C_FIFTY_MS			;
			MOVWF	TIME_ALL_SCAN		;
										;
_KEYS_SCAN	DECFSZ	TIME_KEY_SCAN,F		;
			GOTO	_IDLE				;
			GOTO	SCAN_KEYS			;
_RET6		MOVLW	C_FIFTY_MS			;
			MOVWF	TIME_KEY_SCAN		;
_IDLE		GOTO	_MAIN_LOOP			;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;This procedure scans all the keys starting with the KEY for multiple commands and
;then the keys connected to the CD4051.  When variation in any of the key states are 
;detected, the appropiate procedures will be called to store messages in the TX_QUEU.
;Multiple commands as a result of a variation of the MULTIKEY will be created one at
;a time under the control of its own reduced timer.
;(Interface with CD4051: RB3, RB4, RB5  ->>  inputs C,B,A)
;INPUT:		NONE
;OUTPUT:	NONE
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SCAN_KEYS	BTFSS	MULTICOM,3			;multiple command is active if the counter is =/ 8,
			GOTO	_SINGLE_KEY			;do not read the multikey until the multiple command is 
										;finished
			BTFSC	MULTIKEY			;no multicommand running, read the port
			BSF		F_MULTIKEY_NOW		;
			BTFSS	MULTIKEY			;
			BCF		F_MULTIKEY_NOW		;
			MOVLW	1					;F_MULTIKEY_NOW=0/1
			ANDWF	FLAGS0,W			;
			BCF		F_STATEZONE_KEY		;SAVE THE STATE OF THE MULTIKEY (in case its for a zone)
			IORWF	FLAGS1,F			;
			MOVWF	KEYSTATES			;KEYSTATES<0> = new state of multikey
			RRF		FLAGS0,W			;W<0>=F_MULTIKEY_PRE (e.g. previous state of multikey)
			XORWF	KEYSTATES,W			;
			MOVWF	KEY_CHANGES			;KEY_CHANGES<0> =1= key changed
			BTFSS	KEY_CHANGES,0		;check for variations
			GOTO	_SINGLE_KEY			;no variation in multikey
										;
			BTFSC	F_REP_KEY_READ		;crude debounce method, on first key change detection, just 
			GOTO	_MULKY_CON			; set the F_REPEAT_READ flag, action occurs only
			BSF		F_REP_KEY_READ		; on second detection
			GOTO	_SINGLE_KEY			;
										;
_MULKY_CON	BCF		F_REP_KEY_READ		;MULTIKEY has changed for the 2nd time, save new state as previous state:
			MOVLW	b'11111101'			;reset F_MULTIKEY_PRE
			ANDWF	FLAGS0,F			;
			RLF		KEYSTATES,W			;now copy F_MULTIKEY_NOW into it
			ANDLW	b'00000010'			;
			IORWF	FLAGS0,F			;FLAGS0<1>=F_MULTIKEY_PRE
										;
			MOVLW	EE_RIT_MULTIC		;read the delay between multiple commands
			CALL	READ_EEPROM			;
			MOVWF	MULT_ITNVAL			;
			MOVWF	MULTIMER			;
			CLRF	MULTICOM			;start the multikey command counter 
			MOVLW	1					;
			ANDWF	KEYSTATES,W			;KEYSTATES<0> has the state of KEYS(KEY_COUNTER)
			MOVWF	KEY_STATE			;
;---------------------------------------;
_SINGLE_KEY	CALL	READ_IN_KEYS		;check individual keys
			MOVF	KEYSTATES,W			;KEYSTATES has the current state of the keys
			XORWF	PREV_KEYS,W			;Detect if any KEY variations
			MOVWF	KEY_CHANGES			;'1' in the position(s) of the key(s) that have changed
										;
			MOVF	KEY_CHANGES,F		;check for any changes
			BTFSC	STATUS,Z			;
			GOTO	_KEY_SCAN_DONE		;No more changes (or no changes at all)
			BTFSC	F_REP_KEY_READ		;crude debounce method, on first key change detection, just 
			GOTO	_SGLKY_CON			; set the F_REPEAT_READ flag, action occurs only
			BSF		F_REP_KEY_READ		; on second detection
			GOTO	_KEY_SCAN_DONE		;
										;
_SGLKY_CON	BCF		F_REP_KEY_READ		;
			MOVF	KEYSTATES,W			;Save the current state as previous state
			MOVWF	PREV_KEYS			;
										;
			MOVLW	C_NBR_OF_KEYS		;
			MOVWF	NBR_BITS			;
			CLRF	KEY_COUNTER			;KEYS(0..7)
_NEXT_KEY_CHG							;Loop to find which key(s) have changed
			MOVF	KEY_CHANGES,F		;(executes until KEY_CHANGES becomes 0 if not already)
			BTFSC	STATUS,Z			;
			GOTO	_KEY_SCAN_DONE		;No more changes (or no changes at all)
			CLRC						;
			RRF		KEY_CHANGES,F		;this loop executes until KEY_CHANGES
			BTFSS	STATUS,C			;This key changed?
			GOTO	_NOT_THIS_KEY		;
			MOVLW	1					;
			ANDWF	KEYSTATES,W			;KEYSTATES<0> has the state of KEYS(KEY_COUNTER)
			MOVWF	KEY_STATE			;
			CALL	KEY_ACTION			;KEY_STATE & KEY_COUNTER are inputs to KEY__ACTION
_NOT_THIS_KEY							;
			RRF		KEYSTATES,F			;
			DECFSZ	NBR_BITS,F			;
			GOTO	$+2					;
			GOTO	_KEY_SCAN_DONE		;
			INCF	KEY_COUNTER,F		;
			GOTO	_NEXT_KEY_CHG		;
_KEY_SCAN_DONE							;
;			RETURN						;
			GOTO	_RET6				;
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
;			CALL	COPY_FROM_RX		;move the message to the SHARED data area
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;INCORPORATED FOR STACK REDUCTION
;Moves a RECEIVED message from the RX_QUEU to the SHARED bank (MSG_TYPE...MSG_BYTE4)
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
										;
			MOVF	MSG_TYPE,W			;command type 85
			XORLW	TYPE_FUNZIONAMENTO	;
			BTFSC	STATUS,Z			;
			GOTO	_FUNZIONAMENTO		;
										;
			MOVF	MSG_TYPE,W			;command type 170
			XORLW	TYPE_PROGRAMMAZIONE	;
			BTFSC	STATUS,Z			;
			GOTO	_PROGRAMMAZIONE		;
										;
			MOVF	MSG_TYPE,W			;command type 119
			XORLW	TYPE_INTERROGAZIONE	;
			BTFSC	STATUS,Z			;
			GOTO	_INTERROGAZIONE		;
			GOTO	_DISCARD			;Unknown or untreated (e.g. 51) message type - throw away
										;
_PROGRAMMAZIONE							;FSR -> RX msg
			CALL	CHECK_SERIAL		;
			BTFSS	F_SERIAL_MATCH		;(170,X,NS,DISCRIMINATOR,ARGUMENT) 
			GOTO	_DISCARD			;NOT a msg for us
			MOVF	MSG_DISC,W			;
			MOVWF	E2ADDRESS			;
			MOVF	MSG_ARGT,W			;
			MOVWF	E2VALUE				;
			CALL	COPY_TO_EEPROM		;Put msg data into EEPROM
			CALL	READ_STABLE_DATA	;reread new parameters
			CALL	SEND_PROG_REPLY		;
										;
			MOVLW	1					;Check if programmazione is for a ZONE 
			XORWF	MSG_SUBT,W			;
			BTFSS	STATUS,Z			;
			GOTO	_DISCARD			;
										;
			MOVLW	EE_USCITA_ZONA		;Do not delete this message, instead
			SUBWF	MSG_DISC,W			; convert it to a message for EE_SCHEDA and write 0 to it
			ADDLW	EE_SCHEDA			; to indicate zone command
			MOVWF	E2ADDRESS			;
			CLRF	E2VALUE				;
			CALL	COPY_TO_EEPROM		;
			GOTO	_DISCARD			;
										;
_INTERROGAZIONE							;
			CALL	CHECK_SERIAL		;
			BTFSC	F_SERIAL_MATCH		;
			CALL	SEND_PROG_REPLY		;
			GOTO	_DISCARD			;Finished
										;
_FUNZIONAMENTO							;
;			CALL	FUNZIONAMENTO		;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;INCORPORATED FOR STACK REDUCTION
;Analyze command sub-type (for type 85) and react accordingly 
;INPUT:		msg in SHARED bank
;OUTPUT:	NONE
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
FUNZIONAMENTO							;
			MOVF	MSG_SUBT,W			;
			XORLW	SUBT_INVIO_MODULO	;16
			BTFSC	STATUS,Z			;
			GOTO	_INVIO_MODULO		;
										;
			MOVF	MSG_SUBT,W			;
			XORLW	SUBT_INVIO_ZONA		;17
			BTFSC	STATUS,Z			;
			GOTO	_INVIO_ZONA			;
										;
			MOVF	MSG_SUBT,W			;
			XORLW	SUBT_RISPO_MODULO	;0
			BTFSC	STATUS,Z			;
			GOTO	_RISPO_MODULO_O_CPU	;
										;
			MOVF	MSG_SUBT,W			;
			XORLW	SUBT_RISPO_C		;70 (REPLY TO ALLARM MESSAGE)
			BTFSC	STATUS,Z			;
			GOTO	_RISPO_MODULO_O_CPU	;
										;
			MOVF	MSG_SUBT,W			;
			XORLW	SUBT_INVIO_CPU		;34
			BTFSC	STATUS,Z			;
			GOTO	_INVIO_CPU			;
										;
			MOVF	MSG_SUBT,W			;
			XORLW	SUBT_RISPO_CPU		;2
			BTFSC	STATUS,Z			;
			GOTO	_RISPO_MODULO_O_CPU	;
										;
			MOVF	MSG_SUBT,W			;
			XORLW	SUBT_RICH_CPU		;33
			BTFSC	STATUS,Z			;
			GOTO	_RICH_CPU			;
			GOTO	_FUNZ_FIN			;SUBTYPE NOT TREATED (128,70,1,7) OR UNKNOWN 
_INVIO_MODULO							;
			CALL	CHECK_SERIAL		;
			BTFSS	F_SERIAL_MATCH		;
			GOTO	_FUNZ_FIN			;NOT a msg for us
			CALL	PORT_ACTION			;action message for us
			MOVLW	SUBT_RISPO_MODULO	;start filling reply parameters (0)
			MOVWF	MSG_SUBT			;
			CALL	SEND_ACTION_REPLY	;
			GOTO	_FUNZ_FIN			;
_INVIO_CPU								;
			CALL	CHECK_SERIAL		;
			BTFSS	F_SERIAL_MATCH		;
			GOTO	_FUNZ_FIN			;NOT a msg for us
			CALL	PORT_ACTION			;action message for us
			MOVLW	SUBT_RISPO_CPU		;start filling reply parameters (2)
			MOVWF	MSG_SUBT			;
			CALL	SEND_ACTION_REPLY	;
			GOTO	_FUNZ_FIN			;
_INVIO_ZONA								;we only handle ONE zone number at a time
;			CALL	MANAGE_ZONE_CNTRS	;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;INCORPORATED FOR STACK REDUCTION
;(85,17,ZN,0,[ON|OFF])
;A message for a zone has arrived, analyse to see if we have a port assigned to it 
;and starts the necessary counters.
;INPUT:		msg in SHARED datat
;OUPUT:		NONE
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
MANAGE_ZONE_CNTRS						;
			BTFSC	ZONE_COUNTR,3		;zone command is already active (counter is =/ 8)
			GOTO	_MANAGE_CNT			;
			BSF		F_DEFER_MSG			;don't treat the message but keep it
			GOTO	_NO_ZONE			; 
										;
_MANAGE_CNT	CLRF	ZONE_COUNTR			;
			CLRF	ZONE_PORTS			;
			MOVF	MSG_SERL,F			;MSG_SERL is now MSG_zone
			BTFSC	STATUS,Z			;
			GOTO	_START_COUNTERS		;all schede belong to ZONE 0
										;
_NXT_ZONE	MOVF	ZONE_COUNTR,W		;
			ADDLW	EE_ZONA_APPARTZA	;read zone assignments from EEPROM
			CALL	READ_EEPROM			;
			XORWF	MSG_SERL,W			;
			BTFSC	STATUS,Z			;do we have a port assigned to this zone?
			GOTO	_START_COUNTERS		;
			INCF	ZONE_COUNTR,F		;
			BTFSC	ZONE_COUNTR,3		;all zones
			GOTO	_NO_ZONE			;
			GOTO	_NXT_ZONE			;check if next port asssigned to this ZONE
										;
_START_COUNTERS							;
			MOVLW	EE_RIT_SCHEDA		;read the delay for SCHEDA activation
			CALL	READ_EEPROM			;
			MOVWF	ZONETIMER			;this 2 reduced timers serve to duplicate the delay in EE_RIT_SCHEDA
			MOVWF	SCHEDA_DELAY2		;
			BSF		F_DELAY_SCHEDA		;
										;
			MOVLW	EE_RIT_USCITA		;read the delay for inter USCITA activation
			CALL	READ_EEPROM			;
			MOVWF	ZONE_INTVAL			;this timer for all subsequent activations
										;
_TIMR_CONT	MOVF	MSG_SERL,W			;
			MOVWF	ACTIVE_ZONE			;zone being commanded
			CLRF	ZONE_COUNTR			;start counter
			MOVF	MSG_ARGT,W			;assume normal
										;determine type of action
			MOVWF	ZONE_COMMAND		;ZONE_COMMAND: 	0=normal off
			MOVF	MSG_DISC,F			;				1=normal on
			BTFSC	STATUS,Z			;				2=forced off
			GOTO	_NO_ZONE			;				3=forced on
			MOVLW	2					;
			ADDWF	ZONE_COMMAND,F		;
_NO_ZONE	;RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			GOTO	_FUNZ_FIN			;
										;
_RISPO_MODULO_O_CPU						;
;			CALL	REPLY_TO_MY_MSG		;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;INCORPORATED FOR STACK REDUCTION
;85,[0|2|70],SN,USCITA|E,STATE
;A scheda has replied to a command (MSG 85):
;a) Check the TX_QUEU and match serial and USCITA COMANDATA, if a match is found, 
;   delete it from the QUE.
;b) Check to see if we are VISUALIZZAZIONE port, if we do, match serial and port to it
;   to see if this is a delayed reply (e.g. TEMPORIZZATA or ZONE command) and match the
;   reported state to the corresponding port.
;INPUT:		msg in SHARED data
;OUTPUT:	TX_QUEU entry = null
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
REPLY_TO_MY_MSG							;
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


			INCF	FSR,F				;not an alarm...FSR -> TX_DISCRMINATOR (uscita da comandare)
			MOVF	INDF,W				;
			ANDWF	MSG_DISC,W			;at least one match in the reply must be made with the ports sent
			BTFSC	STATUS,Z			;
			GOTO	_NOT_THIS_MSG		;
										;TX msg found, see if we need to mirror the state
			MOVLW	3					;
			ADDWF	FSR,F				;FSR -> TX_IN_OUT_KEY
			MOVF	INDF,W				;key that was pressed to produce the command
			CALL	PROC_VISUALIZZAZIONE;
										;
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
										;FI 
_TXD_Q_SEAR	CLRF	NBR_PORT			;Now check if this state has to be mirrored
_NXT_VISUAL	MOVF	NBR_PORT,W			;see if this is a delayed  message from a TEMPORIZZATA or TAPPARELLA
			CALL	PROC_VISUALIZZAZIONE;
			INCF	NBR_PORT,F			;
			BTFSS	NBR_PORT,C_MAXBIT	;check all ports
			GOTO	_NXT_VISUAL			;
_END_REPLY	;RETURN						;return REPLY_TO_MY_MSG
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			GOTO	_FUNZ_FIN			;
_RICH_CPU								;
			CALL	CHECK_SERIAL		;
			BTFSS	F_SERIAL_MATCH		;
			GOTO	_FUNZ_FIN			;NOT a msg for us
			MOVLW	SUBT_RISTAT_CPU		;(1) Reply to query from CPU
			MOVWF	MSG_SUBT			;
;			CALL	SND_PORT_PARS		;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;INCORPORATED FOR STACK REDUCTION
;Get states of inputs and outputs and report back to the CPU
;INPUT:		msg in SHARED data
;OUTPUT:	
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SND_PORT_PARS							;
			CALL	READ_IN_KEYS		; returns KEYSTATES
			MOVF	KEYSTATES,W			;
			MOVWF	MSG_DISC			;
			CALL	READ_ALL_PORT_STATES; returns PORTSTATE
			MOVF	PORTSTATE,W			;
			MOVWF	MSG_ARGT			;
										;
			CALL	FIND_EMPTY_TX_Q		;try to send the message
			BTFSC	F_MSG_FOUND			;
			GOTO	_SND_PORT_PARMS		;
			CALL	ERROR_HANDLER		;ERROR: NO TX ENTRY AVAILABLE FOR REPLY
			GOTO	_PORT_PARS_FIN		;
										;
_SND_PORT_PARMS							;
			MOVLW	1					;send only once
			MOVWF	MSG_EXPIRE			;
			CALL	COPY_TO_TX			;RX msg will be discarded on return
_PORT_PARS_FIN							;
;			RETURN						;return SND_PORT_PARS
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
										;
_FUNZ_FIN	;RETURN						;
_DISCARD	BTFSC	F_DEFER_MSG			;
			GOTO	_CLEAR_DISC			;
			MOVF	RX_MSG_START,W		;
			MOVWF	FSR					;
			MOVLW	0xFF				;Release RX message
			MOVWF	INDF				;
_CLEAR_DISC	BCF		F_DEFER_MSG			;
_RXQ_FIN	;RETURN						;STACK REDUCTION
			GOTO	_RET1				;
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
;			BSF		F_BUS_IS_MINE		;
			;RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;			BTFSS	F_BUS_IS_MINE		;WARNING: TAKE_BUS DISABLES INTERRUPTS AND PUTS BUS_OUT LOW
;			GOTO	_NO_MORE_MSG		;If we don't own the bus or were interrupted, 
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
;See if a zone action is active for this scheda.  I this is the first time we execute the zone
;command (RIT_SCHEDA), we duplicate the wait to obtain the 100ms granularity.
;INPUT:		ACTIVE_ZONE	= Zone number for which port actions are pending in this scheda
;			ZONE_COUNTR = Counter for next zone command (no zone action pending=8)
;			ZONE_INTVAL	= delay between activation of each uscita
;			ZONETIMER = Time counter between commands (multiples of 50ms)
;			ZONE_COMMAND = state OFF/ON
;OUTPUT:	MSG_TYPE,MSG_SUBT, ETC, (see also procedure ZONE__ACTION)
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
ZONE_NEXT_COMM							;
			BTFSC	ZONE_COUNTR,3		;zone command running if ZONE_COUNTR <> 8
			GOTO	_CLR_ZONE			;
										;zone command is running
			DECFSZ	ZONETIMER,F			;time for next action?
			GOTO	_ZONE_FIN			;
										;
	 		BTFSS	F_DELAY_SCHEDA		;if this is the scheda delay, wait a second time
			GOTO	_INTERVALS			; 
			MOVF	SCHEDA_DELAY2,W		;duplicate wait
			MOVWF	ZONETIMER			;
			BCF		F_DELAY_SCHEDA		;
			GOTO	_ZONE_FIN			;
										;
_INTERVALS	MOVF	ZONE_INTVAL,W		;fill timer for next USCITA activation
			MOVWF	ZONETIMER			;set delay for next zone activation
										;
_NEXT_ZONE	MOVF	ACTIVE_ZONE,F		;DO (while ZONE_COUNTR < 8)
			BTFSS	STATUS,Z			;  IF zone=0  
			GOTO	_ZONE_NOT_ZERO		;
			MOVF	ZONE_COUNTR,W		;    AND port =/ NOT ASSIGNED
			ADDLW	FUNZIONE			;        W -> FUNZIONE for this port
			MOVWF	FSR					;
			MOVF	INDF,F				;????
			BTFSS	STATUS,Z			;
			GOTO	_ZONE_FOUND			;  THEN activate next port (all ports belong to zone 0)
			GOTO	_NO_ZONE_F			;
										;
_ZONE_NOT_ZERO							;  ELSE
			MOVF	ZONE_COUNTR,W		;    IF the port belongs to this (non-zero) ZONE
			ADDLW	EE_ZONA_APPARTZA	;
			CALL	READ_EEPROM			;      THEN activate the port
			XORWF	ACTIVE_ZONE,W		;
			BTFSC	STATUS,Z			;    END
			GOTO	_ZONE_FOUND			;  END
										;ENDO;
_NO_ZONE_F	CLRC						;
			RRF		ZONE_PORTS,F		;collect port number that have and have not changed
			INCF	ZONE_COUNTR,F		;
			BTFSS	ZONE_COUNTR,3		;last zone/port has been handled (ZONE_COUNTR = 8)
			GOTO	_NEXT_ZONE			;
			GOTO	_SND_REPL_ZONE		;
										;
_ZONE_FOUND	BSF		F_ZONE_MSG_SNT		;
			BSF		STATUS,C			;
			RRF		ZONE_PORTS,F		;collect port number that have and have not changed
;			CALL	ZONE_ACTION			;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;INCORPORATE FOR STACK REDUCTION
;This is actually a subprocedure of ZONE_NEXT_COMM.  It allows to handle the action on this 
;port properly, by simulating a message to our own scheda with appropiate parameters
;INPUT:		NBR_PORT
;OUTPUT:	A simulated message is created in the MSG_... parameters of shared data
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
ZONE_ACTION								;
			MOVLW	TYPE_FUNZIONAMENTO	;
			MOVWF	MSG_TYPE			;
			MOVLW	SUBT_INVIO_MODULO	;pretend to be a scheda
			MOVWF	MSG_SUBT			;
			MOVLW	2					;
			SUBWF	ZONE_COMMAND,W		;if the message is for a force action
			BTFSS	STATUS,C			; pretend to be a CPU
			GOTO	$+3					;
			MOVLW	SUBT_INVIO_CPU		;34
			MOVWF	MSG_SUBT			;
										;
			MOVF	OWN_SERIAL,W		;
			MOVWF	MSG_SERL			;
										;
			CLRF	MSG_DISC			;
			INCF	ZONE_COUNTR,W		;
			MOVWF	TEMP_BYT1			;
			BSF		STATUS,C			;
_ROT_PORT	RLF		MSG_DISC,F			;convert port number to bin
			DECFSZ	TEMP_BYT1,F			; and put in MSG_DISC
			GOTO	_ROT_PORT			;
										;
			CLRF	MSG_ARGT			;
			MOVLW	1					;if ZONE_COMMAND is odd, MSG_ARGT=0, OFF			
			ANDWF	ZONE_COMMAND,W		;
			BTFSC	STATUS,Z			;
			GOTO	$+3					;
			MOVF	MSG_DISC,W			;
			MOVWF	MSG_ARGT			;
			CALL	PORT_ACTION			;
;			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			INCF	ZONE_COUNTR,F		;
			BTFSC	ZONE_COUNTR,3		;last zone/port has been handled (ZONE_COUNTR = 8)
			GOTO	_SND_REPL_ZONE		;
										;
			MOVF	ZONE_INTVAL,W		;fill timer for next USCITA activation
			BTFSC	STATUS,Z			;
			GOTO	_NEXT_ZONE			;if INTERVAL timer is 0, no delay, activate next zone
										;
			MOVWF	ZONETIMER			;set delay for next zone activation
			GOTO	_ZONE_FIN			;
										;
_SND_REPL_ZONE							;
			BTFSS	F_ZONE_MSG_SNT		;send state message only if a port(s) has changed state
			GOTO	_ZONE_FIN			;
			MOVLW	SUBT_RISPO_MODULO	;0
			MOVWF	MSG_SUBT			;
			MOVF	OWN_SERIAL,W		;
			MOVWF	MSG_SERL			;serial
			MOVF	ZONE_PORTS,W		;collected port numbers
			MOVWF	MSG_DISC			;
			CALL	SEND_ACTION_REPLY	;only one reply per scheda is sent
_CLR_ZONE	BCF		F_ZONE_MSG_SNT		;
_ZONE_FIN	;RETURN						;
			GOTO	_RET3				;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Check to see if there is a multicommand running and if its time for the next send (50ms).  To
;send a new command read EEPROM for next scheda and uscita.
;INPUT:		MULTICOM, counter for the next command to be sent.
;OUTPUT:	Entry in TX_QUE (or RX_QUE if key is assigned to action in this processor)
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
MULTIKEY_NEXT_COMM						;
			BTFSC	MULTICOM,3			;Multicommand acvtive if MULTICOM =< 8	
			GOTO	_MULT_FIN			;
										;
			DECFSZ	MULTIMER,F			;time to scan for next command (if any)?
			GOTO	_MULT_FIN			;
										;
_TRY_ANOTHR	MOVLW	8					;
			MOVWF	KEY_TO_PORT			;8th key (key number 9)indicates a multikey command
			MOVF	MULTICOM,W			;
			ADDLW	EE_MULT_SCHEDA		;MULTI PORT command: EE_MULT_SCHEDA<>0, MULT_USCITA<>0xFF<>0
			CALL	READ_EEPROM			;
			MOVWF	MSG_SERL			;
			MOVF	MSG_SERL,F			;see if the multicommand has been assigned, otherwise
			BTFSS	STATUS,Z			;
			GOTO	_MULTI_CONT			;
										;
			MOVF	MULTICOM,W			;this could be a zone command
			ADDLW	EE_MULT_USCITA		;
			CALL	READ_EEPROM			;
			MOVWF	MSG_SERL			;save in case for HANDLE_ZONE_TX() 
			MOVLW	0xFF				;
			XORWF	MSG_SERL,W			;
			BTFSS	STATUS,Z			;
			GOTO	_MULTI_ZONE			;ZONE command: EE_MULT_SCHEDA=0, MULT_USCITA<>0xFF
										;
			INCF	MULTICOM,F			;NOT ASSIGNED when EE_MULT_SCHEDA=0, MULT_USCITA=0xFF
			BTFSC	MULTICOM,3			;Try again if needed allowing for holes in the sequence
			GOTO	_MULT_FIN			;
			GOTO	_TRY_ANOTHR			;
										;
_MULTI_CONT	MOVF	MULTICOM,W			;
			ADDLW	EE_MULT_USCITA		;
			CALL	READ_EEPROM			;
			MOVWF	MSG_DISC			;
			MOVWF	MSG_ARGT			;preload with 'ON'
										;
			MOVF	MULTICOM,W			;Fill variable params according to type of message.
			ADDLW	EE_MULTK_KEY_TIPO	;Get the message type to be sent
			CALL	READ_EEPROM			;
			MOVWF	TEMP_BYT1			;save message type
										;
			XORLW	C_NORMALE			;normal
			BTFSC	STATUS,Z			;
			GOTO	_MULT_NRML			;
										;
			MOVLW	SUBT_INVIO_CPU		;(34)not C_NORMALE, must be forzatura
			MOVWF	MSG_SUBT			;
			MOVF	TEMP_BYT1,W			;
			XORLW	C_SET				;forced ON?
			BTFSS	STATUS,Z			;
			GOTO	$+2					;
			GOTO	_MULT_OTHR			;if SET, ARGT already filled, fill other messge parameters
			CLRF	MSG_ARGT			;RESET 
			GOTO	_MULT_OTHR			;
										;
_MULT_NRML	BTFSS	F_MULTIKEY_PRE		;ON/OFF follows the multikey state
			CLRF	MSG_ARGT			;
			MOVLW	SUBT_INVIO_MODULO	;16
			MOVWF	MSG_SUBT			;
										;
_MULT_OTHR	MOVLW	TYPE_FUNZIONAMENTO	;85
			MOVWF	MSG_TYPE			;
			MOVLW	MAX_MULTI_RETRIES	;3
			MOVWF	MSG_EXPIRE			;
										;
			MOVF	OWN_SERIAL,W		;is this a command for my own scheda?
			XORWF	MSG_SERL,W			;
			BTFSS	STATUS,Z			;
			GOTO	_SND_TX_MSG			;
										;
_MULTOWN	CALL	FIND_EMPTY_RX_Q		;
			BTFSS	F_MSG_FOUND			;
			GOTO	_RESET_INTVAL		;skip the increment of the command counter
			CALL	COPY_TO_RX			; so this multicom can be tried again later
			GOTO	_NEX_MULTCOM		;
										;
_MULTI_ZONE	CALL	HANDLE_ZONE_TX		;
			XORLW	TRUE				;
			BTFSC	STATUS,Z			;
			GOTO	_SND_TX_MSG			;
			INCF	MULTICOM,F			;HANDLE_ZONE_TX returns FALSE if zone command is FORCED but 
			BTFSC	MULTICOM,3			; key is OFF so try next multicommand rightaway
			GOTO	_MULT_FIN			;
			GOTO	_TRY_ANOTHR			;
										;
_SND_TX_MSG	CALL	FIND_EMPTY_TX_Q		;if no TX_QUE entry available try again later
			BTFSS	F_MSG_FOUND			;
			GOTO	_RESET_INTVAL		;skip the increment of the command counter
			CALL	COPY_TO_TX			;
_NEX_MULTCOM							;
			INCF	MULTICOM,F			;Next command on next cycle - this one succesfully processed
_RESET_INTVAL							;
			MOVF	MULT_ITNVAL,W		;start multikey interval timer before leaving
			MOVWF	MULTIMER			;
_MULT_FIN	;RETURN						;
			GOTO	_RET4				;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Check if its time to shut-off a TEMPORIZZATTA or TAPPARELLA port.
;INPUT:		NONE
;OUTPUT:	NONE
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CHECK_LONG_TIMERS						;
			DECFSZ	ONE_SECOND,F		;
			GOTO	_TEMPO_FIN			;
										;
			CLRF	NBR_PORT			;TEST THE SECONDS TIMERS
_SECS_TEST	MOVF	NBR_PORT,W			;
			ADDLW	PORT_SECONDS		;
			MOVWF	FSR					;FSR -> seconds counter
			MOVF	INDF,F				;test for 0 (not active)
			BTFSC	STATUS,Z			;
			GOTO	_NXT_SEC_TIMER		;
			DECFSZ	INDF,F				;
			GOTO	_NXT_SEC_TIMER		;
										;
			MOVF	NBR_PORT,W			;if minute counter is also 0: shutoff
			ADDLW	PORT_MINUTES		;
			MOVWF	FSR					;FSR -> minute counter
			MOVF	INDF,F				;
			BTFSC	STATUS,Z			;
			GOTO	_SHUT_IT_OFF		;
			DECF	INDF,F				;decrement minutes
			MOVF	NBR_PORT,W			;
			ADDLW	PORT_SECONDS		;
			MOVWF	FSR					;FSR -> seconds counter again
			MOVLW	60					;
			MOVWF	INDF				;
			GOTO	_NXT_SEC_TIMER		;not time yet
_SHUT_IT_OFF							;
			MOVLW	OFF					;A TEMPO timer expired, shut-off the corresponding port 
			MOVWF	PORTSTATE			;
			MOVF	NBR_PORT,W			;
			CALL	WRITE_PORT_STATE	;
			MOVF	NBR_PORT,W			;
			CALL	BROADCAST_STAT		;
_NXT_SEC_TIMER							;
			INCF	NBR_PORT,F			;prepare test for next port
			BTFSS	NBR_PORT,C_MAXBIT	;all ports checked?
			GOTO	_SECS_TEST			;
_RESET_SECONDS							;
			MOVLW	C_ONESECOND			;reset
			MOVWF	ONE_SECOND			;
;			RETURN						;
_TEMPO_FIN	GOTO	_RET5				;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;A port has been turned off, broadcast new state
;INPUT:		W = port number
;OUTPUT:	msg in TX_QUE
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
BROADCAST_STAT							;
			MOVWF	TEMP_BYT1			;save
			MOVLW	TYPE_FUNZIONAMENTO	;broadcast the new state of the ports
			MOVWF	MSG_TYPE			;85
			MOVLW	SUBT_RISPO_MODULO	;0
			MOVWF	MSG_SUBT			;
			MOVF	OWN_SERIAL,W		;
			MOVWF	MSG_SERL			;serial
			INCF	TEMP_BYT1,F			;
			CLRF	MSG_DISC			;
			BSF		STATUS,C			;convert port number INT to BIN PACKED
_BCAS_ROL	RLF		MSG_DISC,F			;
			DECFSZ	TEMP_BYT1,F			;
			GOTO	_BCAS_ROL			;
			CALL	READ_ALL_PORT_STATES;
			MOVF	PORTSTATE,W			;
			MOVWF	MSG_ARGT			;
			MOVLW	1					;send only once
			MOVWF	MSG_EXPIRE			;
			CALL	FIND_EMPTY_TX_Q		;
			BTFSC	F_MSG_FOUND			;
			GOTO	$+3					;
			CALL	ERROR_HANDLER		;ERROR: NO TX ENTRY AVAILABLE FOR REPLY
			GOTO	$+2					;
			CALL	COPY_TO_TX			;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Translate timing information into number of minutes and seconds for a timed port
;WARNING:	Time is read from EEPROM and is given in GRANULARITY of 4 SECONDS
;INPUT:		W = port number 
;OUTPUT:	PORT_MINUTES, PORT_SECONDS contain the real time delay
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SELECT_TEMPO_TIME						;
			MOVWF	TEMP_BYT0			;save the port number passed in W
			MOVF	TEMP_BYT0,W			;
			ADDLW	PORT_MINUTES		;  
			MOVWF	FSR					;FSR -> minute counter
			CLRF	INDF				;
										;
			MOVF	TEMP_BYT0,W			;
			ADDLW	EE_TEMPO			;w has the port number
			CALL	READ_EEPROM			;read timing info
			MOVWF	TIMER_INFO			;
										;
_DEVIDE_15	MOVLW	15					;
			SUBWF	TIMER_INFO,W		;
			BTFSS	STATUS,C			;
			GOTO	_DIV_DONE			;
			INCF	INDF,F				;			
			MOVWF	TIMER_INFO			;
			GOTO	_DEVIDE_15			;
_DIV_DONE								;
			MOVLW	8					;FSR-> PORT_SECONDS(port number)
			ADDWF	FSR,F				;convert to seconds
			CLRC						;
			RLF		TIMER_INFO,F		;
			RLF		TIMER_INFO,F		;
			MOVF	TIMER_INFO,W		;
			MOVWF	INDF				;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Read the input keys from the CD4051 in 9 in 8 out or directly in 5 in 4 out.
;INPUT:		NONE
;OUTPUT:	KEYSTATES contains the state of the input keys
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
READ_IN_KEYS							;
			CLRF	KEYSTATES			;
			CLRF	KEY_COUNTER			; KEY_COUNTER=0 means KEY 1
			MOVLW	C_NBR_OF_KEYS		;
			MOVWF	NBR_BITS			;general purpose bit counter
 ifdef IN_9_OUT_8
_NEXT_KEY	MOVF	KEY_COUNTER,W		;Read all the keys
			CALL	SELECT_KEY			;Returns in W the correct bit sequence for addressing the CD4051
			MOVWF	KEY_MASK			;save mask
			MOVF	PORTB,W				;Read the ports
			ANDLW	b'11000011'			;mask out addressing bits
			IORWF	KEY_MASK,W			;
			MOVWF	PORTB				;write it back
			BSF		STATUS,RP0			;
			BCF		TRISB,2				;switch RB2 to output
			BCF		STATUS,RP0			;
			BCF		KEY_IN				;
			NOP							;
			NOP							;
			BSF		STATUS,RP0			;
			BSF		TRISB,2				;
			BCF		STATUS,RP0			;
										;
			CLRC						;Prepare the CARRY bit
			NOP							;
			NOP							;
			BTFSC	KEY_IN				;
			BSF		STATUS,C			;
			RRF		KEYSTATES,F			;Carry has the state of the key
			DECFSZ	NBR_BITS,F			;
			GOTO	$+2					;
			GOTO	_READ_KEY_FIN		;
			INCF	KEY_COUNTER,F		;
			GOTO	_NEXT_KEY			;
 else
			BSF		STATUS,RP0			;
			MOVLW	b'11111111'			;5_IN_4_OUT: RB0=ECHOBUS OUT, RB1=ECHOBUS IN, RB2,RB3,RB4,RB5=IN KEYS
			MOVWF	TRISB				;
			BCF		STATUS,RP0			;
 			BTFSC	PORTB,2				;read in single keys for 5 in 4 out
			BSF		KEYSTATES,0			;
 			BTFSC	PORTB,3				;
			BSF		KEYSTATES,1			;
 			BTFSC	PORTB,4				;
			BSF		KEYSTATES,2			;
 			BTFSC	PORTB,5				;
			BSF		KEYSTATES,3			;
 endif			
_READ_KEY_FIN							;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Read all the ports and build a map in PORTSTAT with the complete array of port states
;INPUT:		NONE
;OUTPUT:	PORTSTATE
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
READ_ALL_PORT_STATES					;
			CLRF	PORTSTATE			;
			CLRF	PRTSTATES			;
			CLRF	GET_PORT			;
_READ_PORT	MOVF	GET_PORT,W			;
			CALL	READ_PORT_STATE		;
			RRF		PORTSTATE,F			;portstate in STATUS<C>
			RRF		PRTSTATES,F			;port state in PRTSTATES<8>
										;
			INCF	GET_PORT,F			;
			MOVF	GET_PORT,W			;8 OR 4
			XORLW	C_NBR_OF_PORTS		;
			BTFSS	STATUS,Z			;
			GOTO	_READ_PORT			;
										;
			MOVF	PRTSTATES,W			;
			MOVWF	PORTSTATE			;
  ifdef IN_5_OUT_4
 			SWAPF	PORTSTATE,F			;only 4 ports read, make sure portstate bit occupy lower nibble
			MOVLW	0x0F				;
			ANDWF	PORTSTATE,F			;
  endif
			RETURN						;
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
			CLRWDT						;
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
;TEMPORIZZATA goes on on a high and stays on till the timer runs out, a new high
;resets the timer.  Timer is given in units of 1/2 seconds.
;INPUT:		NBR_PORT, PORTSTATE<0,1> = current and requested states
;OUTPUT:	W=ON/OFF action
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROC_TEMPORIZZATA						;
			MOVLW	b'000000010'		;
			ANDWF	PORTSTATE,W			;
			BTFSC	STATUS,Z			;
			GOTO	_TEMPO_END			;no changes made on a LOW
										;
			MOVLW	1					;Turn the port ON
			MOVWF	PORTSTATE			;
			MOVF	NBR_PORT,W			;
			CALL	WRITE_PORT_STATE	;
			MOVF	NBR_PORT,W			;
			CALL	SELECT_TEMPO_TIME	;start the necessary timers
_TEMPO_END	MOVLW	0xFE				;indicate actions already performed
			RETURN						;END
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;TAPPARELLA changes the state of 2 ports depending of their current state. Shutoff 
;		  	timers are started or stopped when necessary
;WARNING: it is assumed that the TAPPARELLA port are next to each other, the lower
;         of the pair is the even number, the higher the odd.  
;
;INPUT:		NBR_PORT, PORTSTATE<0,1> = requested and current states
;OUTPUT:	W=ON/OFF action
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROC_TAPPARELLA							;
			MOVF	NBR_PORT,W			;figure out who is OWN and OTHER
			MOVWF	OWN_PORT_TAP		;
			MOVLW	1					;
			ANDWF	NBR_PORT,W			;
			BTFSS	STATUS,Z			;
			GOTO	_ODD				;
			INCF	NBR_PORT,W			;
			MOVWF	OTHRPORT_TAP		;
			GOTO	_TAP_CONT			;
_ODD		DECF	NBR_PORT,W			;
			MOVWF	OTHRPORT_TAP		;
										;
_TAP_CONT	MOVF	PORTSTATE,W			;SAVE STATES OF OWN PORT (CURR,REQUESTED)
			MOVWF	OWNSTATE			;
			MOVF	OTHRPORT_TAP,W		;OWNSTATE has current and requested states of own port
			CALL	READ_PORT_STATE		;PORTSTATE has state of other side
										;
			MOVF	PORTSTATE,W			;save state of other port
			MOVWF	OTHRSTATE			;
			MOVLW	b'00000010'			;
			ANDWF	OWNSTATE,W			;IF REQUESTED STATE = ON
			BTFSC	STATUS,Z			;
			GOTO	_TAP_IGNORE			;then
			MOVLW	b'00000001'			;
			ANDWF	OWNSTATE,W			;
			BTFSS	STATUS,Z			;  if OWNstate = OFF (ignore if OWNstate is already ON)
			GOTO	_TAP_IGNORE			;
			MOVLW	b'00000001'			;	  and
			ANDWF	OTHRSTATE,W			;
			BTFSS	STATUS,Z			;     OTHstate = OFF
			GOTO	_TAP_OTHR_SIDE		;
			MOVLW	ON					;     then OWNstate = ON
			MOVWF	PORTSTATE			;
			MOVF	OWN_PORT_TAP,W		;			and
			CALL	WRITE_PORT_STATE	;
										;           start the shutoff timer
			MOVF	OWN_PORT_TAP,W		;
			CALL	SELECT_TEMPO_TIME	;
			GOTO	_TAP_IGNORE			;
										;
_TAP_OTHR_SIDE							;  else
			MOVLW	OFF					;     
			MOVWF	PORTSTATE			;
			MOVF	OTHRPORT_TAP,W		;    OTHRstate = OFF
			CALL	WRITE_PORT_STATE	;
										;
			MOVF	MSG_DISC,W			;
			MOVWF	OWN_PORT_TAP		;  (re-use OWN_PORT_TAP to save MSG_DISC (destroyed by broadcast))
			MOVF	OTHRPORT_TAP,W		;
			CALL	BROADCAST_STAT		;  end
			MOVF	OWN_PORT_TAP,W		;restore MSG_DISC to send correct ACTION_REPLY
			MOVWF	MSG_DISC			;
										;
			MOVF	OTHRPORT_TAP,W		;
			ADDLW	PORT_MINUTES		;
			MOVWF	FSR					;
			CLRF	INDF				;
			MOVF	OTHRPORT_TAP,W		;
			ADDLW	PORT_SECONDS		;
			MOVWF	FSR					;
			CLRF	INDF				;
										;
_TAP_IGNORE	MOVLW	0xFE				;indicate port actions already taken
			MOVWF	PORTSTATE			;
			RETURN						;END
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;HANDLE A SIGLE KEY (NOT MULTIKEY) ACTION: Read the appropiate eeprom memory and 
;prepare a message for the destination.
;INPUT:		KEY_COUNTER = key number
;			KEY_STATE(0) = state of the key
;OUTPUT:	Entry in TX_QUE and/or RX_QUE if key is assigned to action in this processor
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
KEY_ACTION								;
			MOVF	KEY_COUNTER,W		;
			ADDLW	EE_SCHEDA			;
			CALL	READ_EEPROM			;returns W=scheda da comandare
			MOVWF	MSG_SERL			;
			MOVF	MSG_SERL,F			;not assigned or possible ZONE command
			BTFSC	STATUS,Z			;
			GOTO	_ZONE_KEY			;
_KEY_COMMAND							;PUT VARIABLE PARS IN THE MESSAGE
			MOVF	KEY_COUNTER,W		;remember key that produced the command in KEY_TO_PORT
			MOVWF	KEY_TO_PORT			;
			MOVLW	MAX_SINGLE_RETRIES	;5
			MOVWF	MSG_EXPIRE			;
			MOVLW	TYPE_FUNZIONAMENTO	;85
			MOVWF	MSG_TYPE			;
										;
			MOVF	KEY_COUNTER,W		;
			ADDLW	EE_SGL_KEY_TIPO		;
			CALL	READ_EEPROM			;
			MOVWF	TEMP_BYT0			;save msg type
			XORLW	C_ALLARME			;
			BTFSS	STATUS,Z			;
			GOTO	_NORMAL				;
										;
_ALARM		MOVLW	SUBT_ALLARME_C		;Send Alarm (subtype=128)
			MOVWF	MSG_SUBT			;
			MOVF	OWN_SERIAL,W		;
			MOVWF	MSG_SERL			;
			MOVF	PREV_KEYS,W			;state of the keys when they were read
			MOVWF	MSG_DISC			;
			CALL	READ_ALL_PORT_STATES;
			MOVWF	PORTSTATE			;
			MOVWF	MSG_ARGT			;
			GOTO	_SEND_TX			;
										;
_NORMAL		MOVF	KEY_COUNTER,W		;
			ADDLW	EE_USCITA_ZONA		;
			CALL	READ_EEPROM			;
			MOVWF	MSG_DISC			;USCITA/E da comandare 
			MOVWF	MSG_ARGT			;default normal msg ON
										;;
			MOVF	TEMP_BYT0,W			;saved MESSAGE TYPE
			BTFSS	STATUS,Z			;C_NORMALE
			GOTO	_FORCED				;
										;
			MOVLW	SUBT_INVIO_MODULO	;DEFAULT: NORMALE(16)
			MOVWF	MSG_SUBT			;
			BTFSS	KEY_STATE,0			;state of the key
			CLRF	MSG_ARGT			;normal msg OFF
			GOTO	_KEY_CONT1			;
										;
_FORCED		MOVLW	SUBT_INVIO_CPU		;this is a forced command
			MOVWF	MSG_SUBT			;pretend to be CPU (subtype 34)to force outputs
										;
			MOVF	KEY_STATE,W			;state of the key
			BTFSC	STATUS,Z			;0
			GOTO	_KEY_ACT_FIN		;send forced messages only when key is ON
										;
			MOVF	TEMP_BYT0,W			;saved MESSAGE TYPE
			XORLW	C_SET				;
			BTFSC	STATUS,Z			;
			GOTO	_KEY_CONT1			;MSG_ARGT already has the correct value
_FORC_RESET	CLRF	MSG_ARGT			;forced msg OFF
										;
_KEY_CONT1	CALL	CHECK_SERIAL		;is this a command for my own scheda?
			BTFSS	F_SERIAL_MATCH		;
			GOTO	_SEND_TX			;
										;
_MYOWN		CALL	FIND_EMPTY_RX_Q		;
			BTFSS	F_MSG_FOUND			;
			GOTO	_KEY_ACT_FIN		;
			CALL	COPY_TO_RX			;
			GOTO	_KEY_ACT_FIN		;
										;
_ZONE_KEY	MOVF	KEY_COUNTER,W		;
			MOVWF	KEY_TO_PORT			;save the key sending the zone command
			ADDLW	EE_USCITA_ZONA		;get zone number
			CALL	READ_EEPROM			;W has the zone
			MOVWF	MSG_SERL			;save ZONE da commandare (if present)
			XORLW	0xFF				;
			BTFSC	STATUS,Z			;
			GOTO	_KEY_ACT_FIN		;this key really not assigned (scheda 0, zona -1)			
			CALL	HANDLE_ZONE_TX		;
										;
_SEND_TX	CALL	FIND_EMPTY_TX_Q		;put this message in the TX_QUE
			BTFSC	F_MSG_FOUND			;
			CALL	COPY_TO_TX			;
_KEY_ACT_FIN							;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Send ZONE command
;INPUT:		KEY_TO_PORT=KEY NUMBER (note: multikey is number 8)
;			KEYSTATES=state of the key (including multikey)
;			MSG_SERL = ZONE NUMBER
;OUTPUT:	message to zones
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
HANDLE_ZONE_TX							;
			MOVF	KEY_TO_PORT,W		;
			XORLW	8					;
			BTFSS	STATUS,Z			;If this is multikey-multizone conmmand, read
			GOTO	_SINGLE_KEY_ZONE	; the message type using the MULTICOM counter
			MOVF	MULTICOM,W			;
			ADDLW	EE_MULTK_KEY_TIPO	;
			GOTO	_EEPROMTIPO			;
_SINGLE_KEY_ZONE						;
			MOVF	KEY_TO_PORT,W		;
			ADDLW	EE_SGL_KEY_TIPO		;check what type of message must be sent
_EEPROMTIPO	CALL	READ_EEPROM			;
			MOVWF	TEMP_BYT0			;save msg type
			MOVF	TEMP_BYT0,F			;
			BTFSS	STATUS,Z			;
			GOTO	_ZONE_FORCE			;
										;
_ZON_NORMAL	CLRF	MSG_DISC			;send normal type message
			CLRF	MSG_ARGT			;
			MOVLW	1					;send the KEY_STATE (ON,OFF)
			ANDWF	KEY_STATE,W			;
			BTFSS	STATUS,Z			;
			INCF	MSG_ARGT,F			;
			GOTO	_ZONE_CONT			;
										;
_ZONE_FORCE	MOVF	KEY_STATE,W			;state of the key 
			BTFSC	STATUS,Z			;0
			GOTO	_ZONE_END_FALSE		;send forced messages only if the key is 'ON'
										;
			MOVLW	0xFF				;indicates forced ZONE message
			MOVWF	MSG_DISC			;
			CLRF	MSG_ARGT			;
			MOVLW	C_RESET				;2
			XORWF	TEMP_BYT0,W			;send ON or OFF depending on SET or RESET
			BTFSS	STATUS,Z			;
			INCF	MSG_ARGT,F			;
										;
_ZONE_CONT	MOVLW	TYPE_FUNZIONAMENTO	;85
			MOVWF	MSG_TYPE			;
			MOVLW	SUBT_INVIO_ZONA		;17
			MOVWF	MSG_SUBT			;
			MOVLW	MAX_ZONE_RETRIES	;(1=expect no reply)
			MOVWF	MSG_EXPIRE			;
			CALL	FIND_EMPTY_RX_Q		;ZONE messages are put in both RX and TX ques in case
			BTFSC	F_MSG_FOUND			; this scheda has ports in that zone
			CALL	COPY_TO_RX			;
_ZONE_END_TRUE							;
			RETLW	TRUE				;the return procedure will put the message in TX
_ZONE_END_FALSE							;
			RETLW	FALSE				;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;(85,[34|16],NS,[255|OUT],[SO|[OUT|0]]) 
;WARNING: This messages can be generated also by procedure ZONE_NEXT_COMM
;Analyze the message received and perform requested action on a port depending on 
;the function or if its a forced state from CPU.
;INPUT:		msg in SHARED datat
;OUPUT:		NONE
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PORT_ACTION	CLRF	NBR_PORT			;
			MOVLW	SUBT_INVIO_CPU		;34: forced states
			XORWF	MSG_SUBT,W			;
			BTFSC	STATUS,Z			;
			GOTO	_FORCED_OUTPUTS		;
										;
			CLRF	FRONTE				;
			MOVF	MSG_ARGT,F			;
			BTFSC	STATUS,Z			;If argument is 0, is a LOW (FRONTE DISCESA)
			GOTO	_ACT_CONT			;fronte discesa
_FRONTE_SALITA							;
			INCF	FRONTE,F			;
			MOVF	MSG_DISC,W			;If argument is equal to discriminator is a HIGH
			XORWF	MSG_ARGT,W			;
			BTFSC	STATUS,Z			;If they are not equal its an error
			GOTO	_ACT_CONT			;
										;
			CALL	ERROR_HANDLER		;
			GOTO	_PORT_ACTS_FIN		;
										;
_ACT_CONT	MOVF	MSG_DISC,W			;has a 1 for the ports that must change
			MOVWF	TEMP_BYT2			;look out for TEMP_BYT2!!!
_NXT_PORT	RRF		TEMP_BYT2,F			;
			BTFSS	STATUS,C			;
			GOTO	_NO_CHANGE			;
										;
			CLRF	PORTSTATE			;
			MOVF	NBR_PORT,W			;
			CALL	READ_PORT_STATE		;see PORTSTATE - returns PORTSTATE<0>= state of the port
			CLRC						;
			RLF		FRONTE,W			;
			IORWF	PORTSTATE,F			;PORTSTATE<1>=resquested state && PORTSTATE<0>=current state 
;			CALL	FIND_OUTPUT_ACTION	;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;INCORPORATED STACK REDUCTION
;According to PORT NUMBER, FUNZIONE, PORT STATE and REQUESTED STATE get the output action
;INPUT:		NBR_PORT, PORTSTATE<0,1> =  current and requested state
;OUTPUT:	W=ON/OFF action
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
FIND_OUTPUT_ACTION						;
			MOVF	NBR_PORT,W			;
			ADDLW	FUNZIONE			;W -> FUNZIONE for this port
			MOVWF	FSR					;
										;
			MOVLW	MONOSTABILE			;
			XORWF	INDF,W				;
			BTFSS	STATUS,Z			;
			GOTO	$+4					;
			MOVF	PORTSTATE,W			;
			CALL	TABLE_MONOSTABILE	;W HAS THE ACTION (ON/OFF)
			GOTO	_OUT_ACT_C			;
										;
			MOVLW	INVERTITORE			;
			XORWF	INDF,W				;
			BTFSS	STATUS,Z			;
			GOTO	$+4					;
			MOVF	PORTSTATE,W			;
			CALL	TABLE_INVERTITORE	;
			GOTO	_OUT_ACT_C			;
										;
			MOVLW	PASSOPASSO			;
			XORWF	INDF,W				;
			BTFSS	STATUS,Z			;
			GOTO	$+4					;
			MOVF	PORTSTATE,W			;
 			CALL	TABLE_PASSOPASSO	;
			GOTO	_OUT_ACT_C			;
										;
			MOVLW	TAPPARELLA			;
			XORWF	INDF,W				;
			BTFSS	STATUS,Z			;
			GOTO	$+4					;
			MOVF	PORTSTATE,W			;
 			CALL	PROC_TAPPARELLA		;this is a procedure, not a table
			GOTO	_OUT_ACT_C			;
										;
			MOVLW	TEMPORIZZATA		;
			XORWF	INDF,W				;
			BTFSS	STATUS,Z			;
			GOTO	$+4					;
			MOVF	PORTSTATE,W			;
			CALL	PROC_TEMPORIZZATA	;
			GOTO	_OUT_ACT_C			;
										;
			MOVLW	VISUALIZZAZIONE		;VISUALIZZAZIONE cannot be commanded
			XORWF	INDF,W				;
			BTFSS	STATUS,Z			;
			GOTO	$+3					;
			MOVLW	0xFE				;no error but do nothing
			GOTO	_OUT_ACT_C			;
										;
			CALL	ERROR_HANDLER		;THIS PORT HAS NOT BEEN ASSIGNED
			MOVLW	0xFF				;RETURN ERROR	
_OUT_ACT_C	;RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			MOVWF	PORTSTATE			;
			XORLW	0xFE				;TAPPARELLA, TEMPORIZZATTA - port actions already done
			BTFSC	STATUS,Z			;
			GOTO	_NO_CHANGE			;
			MOVF	PORTSTATE,W			;
			XORLW	0xFF				;ERROR: function unknown (error was reported by FIND_OUTPUT_ACTION)
			BTFSC	STATUS,Z			;
			GOTO	_PORT_ACTS_FIN		;
										;
			MOVF	NBR_PORT,W			;
			CALL	WRITE_PORT_STATE	;returns W with intended port state required for NBR_PORT
										;
_NO_CHANGE	INCF	NBR_PORT,F			;
			BTFSS	NBR_PORT,C_MAXBIT	;all ports checked?
			GOTO	_NXT_PORT			;
			GOTO	_PORT_ACTS_FIN		;
										;
_FORCED_OUTPUTS							;command from CPU to force outputs to a state
			MOVF	MSG_DISC,W			;
			MOVWF	TEMP_BYT2			;
_NXT_FORCED	CLRC						;
			RRF		TEMP_BYT2,F			;all outputs (MSG_DISC=FF) or only some (MSG_DISC=SO,MSG_ARGT=SO)
			BTFSS	STATUS,C			; in either case the same reasoning applies.
			GOTO	_INC_PORT			;this port to change?
										;
			MOVLW	1					;
			ANDWF	MSG_ARGT,W			;
			MOVWF	PORTSTATE			;PORTSTATE<0> has the intended port state required for NBR_PORT
			MOVF	NBR_PORT,W			;
			CALL	WRITE_PORT_STATE	;
			MOVLW	PORT_MINUTES		;turn LONG TIMER OFF
			ADDWF	NBR_PORT,W			;
			MOVWF	FSR					;
			CLRF	INDF				;
			ADDLW	8					;move FSR to PORT_SECONDS
			MOVWF	FSR					;
			CLRF	INDF				;
_INC_PORT	RRF		MSG_ARGT,F			;rotate to next port's state
			INCF	NBR_PORT,F			;
			BTFSS	NBR_PORT,C_MAXBIT	;4 OR 8
			GOTO	_NXT_FORCED			;
_PORT_ACTS_FIN							;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Put an action reply message in the message in the TX_QUEU
;INPUT:		Parameters already filled in MSG_... shared data
;OUTPUT:	entry in TX_QUEU is filled
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SEND_ACTION_REPLY						;
			CALL	READ_ALL_PORT_STATES;
			MOVF	PORTSTATE,W			;
			MOVWF	MSG_ARGT			;
			MOVLW	1					;send only once
			MOVWF	MSG_EXPIRE			;
			CALL	FIND_EMPTY_TX_Q		;
			BTFSC	F_MSG_FOUND			;
			GOTO	$+3					;
			CALL	ERROR_HANDLER		;ERROR: NO TX ENTRY AVAILABLE FOR REPLY
			GOTO	_SND_A_FIN			;
			CALL	COPY_TO_TX			;RX msg will be discarded on return
_SND_A_FIN	RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Given a port, check if it is of type VISUALIZZAZIONE, if it is, change the state
;of the port according to the corresponding bit in MSG_ARGT
;INPUT:		W=port number
;OUTPUT:	NONE, changes the port state if necessary
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROC_VISUALIZZAZIONE					;
			MOVWF	NBR_PORT			;save
			BTFSC	NBR_PORT,3			;If this msg was sent by multikey(8), ignore port visualization
			GOTO	_END_VISUAL			;
			BTFSS	F_HAVE_VISUAL		;do we have any visualizzazione ports?
			GOTO	_END_VISUAL			;
			ADDLW	FUNZIONE			;
			MOVWF	FSR					;
			MOVF	INDF,W				;
			XORLW	VISUALIZZAZIONE		;see if this port is of function VISUALIZZ.
			BTFSS	STATUS,Z			;
			GOTO	_END_VISUAL			;
			MOVF	NBR_PORT,W			;
			ADDLW	EE_SCHEDA			;
			CALL	READ_EEPROM			;see if this port commands the scheda that sent the reply
			XORWF	MSG_SERL,W			;
			BTFSS	STATUS,Z			;
			GOTO	_END_VISUAL			;
			MOVF	NBR_PORT,W			;
			ADDLW	EE_USCITA_ZONA		;
			CALL	READ_EEPROM			;see if this port commands the port of scheda that sent the reply
			MOVWF	TEMP_BYT0			;save
			ANDWF	MSG_DISC,W			;
			BTFSC	STATUS,Z			;
			GOTO	_END_VISUAL			;
			MOVF	MSG_ARGT,W			;
			MOVWF	TEMP_BYT2			;
										;
_NXT_ROTATE	RRF		TEMP_BYT0,F			;rotate the state that the remote scheda reported
			BTFSS	STATUS,C			;  until our port's state is in TEMP_BYT2<0>
			GOTO	$+2					;
			GOTO	$+4					;
			RRF		TEMP_BYT2,F			;
			CLRC						;
			GOTO	_NXT_ROTATE			;
										;
_PORT_CHANG	MOVF	TEMP_BYT2,W			;TEMP_BYT2<0>=port state
			MOVWF	PORTSTATE			;
			MOVF	NBR_PORT,W			;send port number
			CALL	WRITE_PORT_STATE	;now change the state of the own port
_END_VISUAL	RETURN						;
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
;Reads all operating parameters from EEPROM if the programmazione argument is <= 81
;(last port FUNZIONE)
;INPUT:		NONE
;OUTPUT:	NONE
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
READ_STABLE_DATA						;
			MOVLW	82					;FUNZIONE for the last port
			SUBWF	MSG_DISC,W			;
			BTFSC	STATUS,C			;C is set when negative
			GOTO	_STABLE_DONE		;
			MOVLW	EE_SERIAL_NBR		;
			CALL	READ_EEPROM			;
			MOVWF	OWN_SERIAL			;
			MOVLW	EE_PROGRAM_TYPE		;
			CALL	READ_EEPROM			;
			MOVWF	OWN_PROGRAM			;			
			CLRF	NBR_BYTES			;READ eeprom to get port functions
			MOVLW	FUNZIONE			;
			MOVWF	FSR					;
										;
			BCF		F_HAVE_VISUAL		;
_NXT_FUNZIONE							;
			MOVF	NBR_BYTES,W			;
			ADDLW	EE_FUNZIONE			;
			CALL	READ_EEPROM			;
			MOVWF	INDF				;save port assignment
			XORLW	VISUALIZZAZIONE		;
			BTFSC	STATUS,Z			;
			BSF		F_HAVE_VISUAL		;indicate we have at least one visualizzazione port
			INCF	NBR_BYTES,F			;
			BTFSC	NBR_BYTES,C_MAXBIT	;4 or 8 ports
			GOTO	_READ_PLRTY			;
			INCF	FSR,F				;
			GOTO	_NXT_FUNZIONE		;
										;
_READ_PLRTY	MOVLW	EE_POLARITA			;
			CALL	READ_EEPROM			;
			MOVWF	POLARITA			;byte that describes the polarity of each port
_STABLE_DONE							;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Treat errors, only for deugging purposes
;INPUT:		NONE
;OUTPUT:	NONE
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
ERROR_HANDLER							;
			NOP							;Good spot for breakpoint
			NOP							;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Read EEPROM memory.
;Input: 	W=address
;Output: 	W=value read
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
READ_EEPROM								;
			BANKSEL	EECON1				;
			BTFSC	EECON1,WR			;
			GOTO	READ_EEPROM			;
			MOVWF	EEADR				;
			BSF		EECON1,RD			;
			MOVF	EEDATA,W			;W=eeprom data
			BCF		STATUS,RP0			;bank 0
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Write to EEPROM
;Input:		MSG_DISC4, MSG_ARGT
;Output:	None
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
COPY_TO_EEPROM
			BANKSEL	EECON1				;
			BTFSC	EECON1,WR			;
			GOTO	COPY_TO_EEPROM		;
			BANKSEL	E2ADDRESS			;
			MOVF	E2ADDRESS,W			;IN BANK 0
			BSF		STATUS,RP0			;BANK1
			MOVWF	EEADR				;
			BCF		STATUS,RP0			;BANK0
			MOVF	E2VALUE,W			;
			BSF		STATUS,RP0			;BANK1
			MOVWF	EEDATA				;
			BSF		EECON1,WREN			;
			BCF		INTCON,GIE			;
			MOVLW	0x55				;
			MOVWF	EECON2				;
			MOVLW	0xAA				;
			MOVWF	EECON2				;
			BSF		EECON1,WR			;
			BSF		INTCON,GIE			;
;			BCF		EECON1,WREN			;
			NOP							;
			BCF		STATUS,RP0			;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;PREINITIALIZED EEPROM VALUES

			ORG		(0x2100)
			DE		"by Gino Isla for BIT Srl - Italia"

			ORG		(0X2100+EE_MULTK_KEY_TIPO)
			DE		0,0,0,0,0,0,0,0				;default type NORMAL for MULTIKEY commanding a ZONE

			ORG		(0x2100+EE_STATO_USCITE)
			DE		0							;default all ports OFF

			ORG		(0x2100+EE_TIPO_SCHEDA)		
			DE		0							;tipo 0 

			ORG		(0x2100+EE_SW_VERSION)		
			DE		2							;version 2

			ORG		(0x2100+EE_RIT_USCITA)		
			DE		1							;delay activation of ports in the same zone

			ORG		(0x2100+EE_RIT_SCHEDA)		
			DE		1							;delay activation of a scheda during zone command

			ORG		(0x2100+EE_RIT_MULTIC)		
			DE		5							;250ms delay in sending multiple commands
			
			ORG		(0x2100+EE_POLARITA)		
			DE		0							;default POSITIVE polarity of the ports

			ORG		(0x2100+EE_SERIAL_NBR)		
			DE		2							;default SERIAL NUMBER

			ORG		(0x2100+EE_PROGRAM_TYPE)	
			DE		15							;default TIPO PROGRAMMA

			ORG		(0x2100+EE_SCHEDA)
			DE		0,0,0,0,0,0,0,0				;scheda NOT ASSIGNED - could be zone though...

			ORG		(0x2100+EE_USCITA_ZONA)
			DE		-1,-1,-1,-1,-1,-1,-1,-1		;default, no assignment

			ORG		(0x2100+EE_USCITA_PORTA)
			DE		0,1,2,3,4,5,6,7				;Default INGRESSO to USCITA assignment (prog B)

			ORG		(0x2100+EE_FUNZIONE)
			DE		0,0,0,0,0,0,0,0				;FUNZIONE NON USATA

			ORG		(0x2100+EE_TEMPO)
			DE		0,0,0,0,0,0,0,0				;TEMPORIZAZZIONE NOT ASSIGNED
			
			ORG		(0x2100+EE_MULT_SCHEDA)
			DE		0,0,0,0,0,0,0,0				;MULTI COMMAND NOT ASSIGNED

			ORG		(0x2100+EE_MULT_USCITA)
			DE		-1,-1,-1,-1,-1,-1,-1,-1		;MULTI COMMAND NOT ASSIGNED

			ORG		(0x2100+EE_ZONA_APPARTZA)
			DE		-1,-1,-1,-1,-1,-1,-1,-1		;ZONE NOT ASSIGNED

			ORG		(0x2100+EE_SGL_KEY_TIPO)
			DE		0,0,0,0,0,0,0,0				;TYPE NORMAL FOR SINGLE KEYS
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			END							;PROGRAM FINISHED

			
