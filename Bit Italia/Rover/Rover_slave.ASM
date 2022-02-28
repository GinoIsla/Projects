;************************************************************
;	TITLE:	Rover Slave - Receiver side
;	It continually receives data from the Master and applies it to the 
;	drive motors and lights
;	Programmer: GINO ISLA
;	Created:	June-02-2004
;	REVISION HISTORY:
;	HARDWARE: BIT SRL. Low Power transciever
;	FREQUENCY: 4.0 MHz
;	Function: Remotly controlled vehicle
;************************************************************
			list	p=16f876

#define		DEBUG_MODE

#include	<p16f876.inc>
#include 	<CC1000.h>
;
;REMEMBER TO CHANGE THE TX_MASTER/RX_SLAVE DEFINITION IN Rover.h
;AND ASSEMBLE THE CC1000_Routines LIBRARY
;
#include 	<rover.h>
#include	<macros.inc>

;LOCAL DATA
	UDATA
L_Temp1			res 1 		;
L_TEMP_2		RES	1		;
L_Temp_CS		res	1		;temporary sum-check
L_BITS			res 1		;number of bits sent or received
L_BYTES			res 1		;number of bytes sent or received
L_TX_COUNT		res	1		;TX_BUFFER counter
L_NEXT_FR_BYT	res	1		;counts the byte in the TX buffer
L_INDEX			res 1		;index for addressing buffers below
L_PORTC			res 1		;temporary PORTC
L_DATA_RX		res 1		;1 byte of received data
L_RX_BUFF		res d'16'	;Received data buffer
L_TX_BUFF		res d'16'	;Transmit data buffer
L_PERSIST		res	1		;counter for persistancy checks
;
G_Events 		res 1		;This has to be seen by other modules
G_Pr_status		res 1 		;
G_State			res 1		;will determine the reaction in ISR
;
D_ERROR_CNT		res	1		;Counts number of times in TREAT_ERROR
D_ERROR_FLG		res	1		;Manual flag to read all CC1000 regs in TREAT_ERROR
D_BUGGGER		res	1		;
;
STATUS_TEMP		res 1		;for saving STATUS reg during ISR
L_FREQ_L		res	1		;calculated value for TIMER1_L
L_FREQ_H		res	1		;calculated value for TIMER1_H, steering motor frequency (half cycle)

;=========================================================================================
DEBUG_BITS		res	1
D_BUG1			res	1		;
D_BUG2			res	1		;
;==========================================================================================
	UDATA_SHR				;Common bank
L_EE_COUNT_L	res	1		;This has to be @ addr xxxxxx00 BUT the linker puts it in x71!!!
L_EE_COUNT_H	res	1		;These reserve 8 bytes for data transfer with EEPROM
L_EE_COUNT_MORE	res	6		;
W_TEMP			res	1		;for saving W reg during ISR
;
;EXTERNAL AND GLOBAL SYMBOLS
			Global	G_Events,G_Pr_status
			extern	G_CC_Reg,G_CC_Data

;LIBRARY SUPPORT ROUTINES
	extern	Setup_CC1000PD,Reset_CC1000,Setup_CC1000All,CalibrateCC1000
	extern	SetupCC1000Tx,SetupCC1000Rx,WakeUpCC1000toRx,WakeUpCC1000toTx
	extern	DelaymS,Delay100uS,DelayuS
	extern	ReadFromCC1000register
	
;CONFIGURATION OF PIC
	__CONFIG	_CP_OFF & _WDT_ON & _BODEN_OFF & _PWRTE_ON & _XT_OSC & _PWRTE_ON & _LVP_OFF & _DEBUG_ON & _CPD_OFF

	CODE
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
START_OF_THE_PROGRAM					;
			org		0X000				; Reset Vector
			nop							;
			clrf	PCLATH				;
			goto	Start				;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			org		0x004				;Iterrupt Vector
			goto	TREAT_ERROR			; no Ints expected
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Table lookups for CC1000 register
;Lookout for page boundaries!!!!!
GET_NEXT_REGISTER						;
			Global	GET_NEXT_REGISTER	;
			ADDWF	PCL,F				;
										;	
CC1Kregs	DATA 0x3400,0x3458,0x3420,0x3400,0x3442,0x3414,0x349c,0x3402	;Rf XTAL: 14.745600
			DATA 0x3480,0x3444,0x3412,0x34FF,0x3460,0x3410,0x3426,0x348E	;PA_POW<0BH>=FF 
			DATA 0x346F,0x3447,0x3470,0x3401,0x3400,0x3400,0x3400,0x3400	;MODEM0<11H>
			DATA 0x3400,0x3400,0x3400,0x3400,0x3400
			Global	CC1Kregs			;
			RETURN 						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Program execution starts here
Start									;Setup MCU
			MOVLW	(D_BUG2-L_Temp_CS)+1;Clears all varialble data including
			MOVWF	L_Temp1				; RX and TX buffers, L_Temp1 is used 
			MOVLW	L_Temp_CS			;
			MOVWF	FSR					;
_CLR_MEM	CLRF	INDF				;
			INCF	FSR,F				;
			DECFSZ	L_Temp1,F			;
			GOTO	_CLR_MEM			;
										;
			CLRF	STATUS				;BANK 0
			CLRF	SSPCON				;disable serial port
			CLRF	ADCON0				;
			CLRF	RCSTA				;Serial port disabled(bit banging)
			CLRF	INTCON				;
			CLRF	PORTA				;
			CLRF	PORTB				;
			CLRF	PORTC				;
			CLRF	CCPR2L				;
										;
			CLRF	L_EE_COUNT_L		;
;PWD 									;
;===									;
			MOVLW	b'00001100' 		;bits 3-0=PWM mode (pg. 62)
			MOVWF	CCP1CON				;analogue chan 1
;			MOVWF	CCP2CON				;analogue chan 0
			CLRF	CCP2CON				;analogue chan 2 - RC1 used as normal port for steering
			MOVLW	b'00000111'			;PRESCALE 1:16
			MOVWF	T2CON				;
										;
			BANKSEL	TRISA				;BANK 1
			MOVLW	d'16'				;8 bit resolution clock at 4MZ
			MOVWF	PR2					;
;===									;
			MOVLW	7					;not used
			MOVWF	ADCON1				;
										;
			MOVLW	b'00000011'			;
			MOVWF	PCON				;power-on, brown-out resets
										;
			MOVLW	b'11111000'			;RA0=OUT MOTOR,,RA1=PALE,RA2=PCLK
			MOVWF	TRISA				;
			MOVLW	b'11001001'			;RB0=DCLK,+outputs
			MOVWF	TRISB				;
			MOVLW	b'00101000'			;RC<0,3>=PDATA,DIO, RC<1,2>=CCP1,2, +outputs
			MOVWF	TRISC				;
										;
			MOVLW	25					;4Mhz,9.6Kb
			MOVWF	SPBRG				;not necessary when running synchronous slave
										;
			MOVLW	b'00000000'			;MCU is slave,8bit,TxEN,Async,high speed,  
			MOVWF	TXSTA				;
										;
			MOVLW	b'00000000'			;
			MOVWF	PIE1				;TMR1 int disabled (xxxxxxx1)
										;
			MOVLW	b'11001110'			;PortB pullups disabled,
			MOVWF	OPTION_REG			;xxxx111xb prescaler to WDT,1:128
										;
			BANKSEL	L_Temp1				;MORE BANK 0
										;start of CC1000 initialization
			CALL	Setup_CC1000PD		;Setup after Power down CC1000
										;
			CALL	Reset_CC1000		;Reset it  [(A) and (B) fig 16]
										;
			MOVLW	CC1Kregs 			;
			CALL	Setup_CC1000All		;Setup all other 28 registers [(C) fig 16]
										;
			MOVLW	TX_CURRENT			;
			CALL	WakeUpCC1000toTx	;
										;
			MOVLW	TX_CURRENT			;
			CALL	SetupCC1000Tx		;Switch to Tx
										;
			CALL	CalibrateCC1000		;Single calibration  [(D) and (E) FIG 16]
										;
			MOVLW	RX_CURRENT			;
			CALL	WakeUpCC1000toRx	;Start calibration (A....G) fig 17)
										;
			MOVLW	RX_CURRENT			;
			CALL	SetupCC1000Rx		;Slave stays as reeiver
										;
			CALL	CalibrateCC1000		;Single calibration as RX
										;
_CAL_ENDED	BTFSS	CALIBRATION_OK		;
			CALL	TREAT_ERROR			;
										;
			MOVLW	0x80				;enable GIE<7> although they are not expected
			MOVWF	INTCON				;clear TMR0IF<2>,INTF<1>,RBIF<0>,PEIE<6>,
			BSF		RESET_CNTRS			;
										;setup TIMER1 to produce a freq of 300Hz (1656ms)
			MOVLW	0X06				;
			MOVWF	L_FREQ_H			;
			COMF	L_FREQ_H,W			;TIMER1 is a count-up timer
			MOVWF	TMR1H				;
			MOVLW	0X78				;
			MOVWF	L_FREQ_L			;
			COMF	L_FREQ_L,W			;
			MOVWF	TMR1L				;
			BCF		PIR1,TMR1IF			;clear TMR1 interrupt flag
			MOVLW	b'00000001'			;prescale 1:1, internal clk,TMR1ON
			MOVWF	T1CON				;
										;
			CLRF	CCPR1L				;Start with traction wheels at rest
			BCF		SPIN_DIR			;
										;
_IDLE_LOOP	BTFSS	PIR1,TMR1IF			;TIMR1 expired?
			GOTO	_READ_MSG			;
			CALL	STEER_FREQ			;

_READ_MSG	BTFSS	RESET_CNTRS			;
			GOTO	_SLAVE_ACTIONS		;
										;
_RESET		CLRF	L_BYTES				;Start all over
			MOVLW	8					;
			MOVWF	L_BITS				;Initialize bit counter
			MOVLW	-1					;  so index goes to 0 on BOF
			MOVWF	L_INDEX				;
			BCF		BYTE_FULL			;
			BCF		RESET_CNTRS			;
			BCF		BOF_FOUND			;
			CLRF	G_Pr_status			;
										;
_SLAVE_ACTIONS							;
			CLRWDT						;Clear watch dog
			BTFSS	DCLK				;IF DCLCLK PULSE (CC1000 rdy to receive?)
			GOTO	_COMMS_END			; 
										;
			CALL	RECEIVE_BIT			;
			BTFSS	BYTE_FULL			;
			GOTO	_COMMS_END			;
			BTFSS	BOF_FOUND			;
			GOTO	_COMMS_END			;
			CALL	RECEIVE_BYTE		;
			BCF		BYTE_FULL			;
_COMMS_END	GOTO	_IDLE_LOOP			;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;On expiration of TIMER1, builds a square wave on the port used for driving the 
;steering motor.  (See CALCULATE_PERIOD for L_FREQ_x calculations)
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
STEER_FREQ								;
			BTFSS	STEERING			;SWAP THE STATE OF THE IO PORT
			GOTO	$+3					;
			BCF		STEERING			;
			GOTO	$+2					;
			BSF		STEERING			;
										;
			COMF	L_FREQ_H,W			;reset timer 1 with new period
			MOVWF	TMR1H				;
			COMF	L_FREQ_L,W			;
			MOVWF	TMR1L				;
			BCF		PIR1,TMR1IF			;clear TMR1 interrupt flag
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Receive the next bit,count full bytes, find the beginning of a frame.
;CALLED FROM: Idle loop
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
RECEIVE_BIT								;
			MOVLW	d'5'				;persistancy check on DCLK
			MOVWF	L_PERSIST			;
_DCLK_TST	BTFSS	DCLK				;
			GOTO	_RX_ERROR			;ignore spikes
			DECFSZ	L_PERSIST,F			;
			GOTO	_DCLK_TST			;
										;
			MOVF	PORTC,W				;Persistancy check on DIO (data)
			ANDLW	8					;PORTC<3>
			MOVWF	L_PORTC				;
			MOVLW	d'4'				;
			MOVWF	L_PERSIST			;
_DIO_IN_P	MOVF	PORTC,W				;read again
			ANDLW	8					;
			XORWF	L_PORTC,W			;
			BTFSS	STATUS,Z			;still the same?
			GOTO	_RX_ERROR			;
			DECFSZ	L_PERSIST,F			;
			GOTO	_DIO_IN_P			;
			GOTO	_RX_CONT			;
										;
_RX_ERROR	INCF	D_BUG1,F			;
			GOTO	_RX_END				;ignore spikes
										;
_RX_CONT	INCF	D_BUG2,F			;
			BTFSS	DCLK				;
			GOTO	$-1					;stay here till DCLK is low
										;
			CLRC						;Accept bit
			RLF		L_DATA_RX,F			;
			CLRW						;
			BTFSC	L_PORTC,3			;
			MOVLW	1					;
			IORWF	L_DATA_RX,F			;
										;
			BTFSC	BOF_FOUND			; If BOF has been found we are now collecting data
			GOTO	_BOF_CONT2			;
										;Look for BOF
			MOVF	L_DATA_RX,W			;This check is done bit by bit through the 1st
			SUBLW	0xAA				; byte of the preamble
			BTFSC	STATUS,Z			;zero flag set when 0 (EQ)
			GOTO	_BOF_FOUND			;
										;
_NO_BOF		BCF		BOF_FOUND			;
			GOTO	_RX_END				;
										;
_BOF_FOUND	BSF		BOF_FOUND			;Begining of Frame found
			MOVLW	1					;Force recognition of 1st byte of data
			MOVWF	L_BITS				;
										;
_BOF_CONT2	DECFSZ	L_BITS,F			;8 bits received?
			GOTO	_RX_END				;
										;
			BSF		BYTE_FULL			;
			INCF	L_BYTES,F			;L_BYTES are modified by each procedure
			INCF	L_INDEX,F			;  (on detection of BOF, L_BYTES is 1)
			MOVLW	8					;
			MOVWF	L_BITS				;reset bit count 
			MOVF	L_INDEX,W			;
			ADDLW	L_RX_BUFF			;
			MOVWF	FSR					;Complete byte put in the RX_BUFFER
			MOVF	L_DATA_RX,W			;
			MOVWF	INDF				;
			BCF		INTCON,INTF			;
_RX_END		RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Treat reception of a packet - the first byte of the pre-amble has already been
;detected
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
RECEIVE_BYTE							;
			BTFSC	PREAM_FINISHED		;
			GOTO	_UNIQUE_ID			;
			CALL	CHECK_PREAMBLE		;Continue checking the preamble
			GOTO	_RCV_FINISH			;
										;
_UNIQUE_ID	BTFSC	UI_FINISHED			;
			GOTO	_ADDRESS			;
			CALL	CHECK_UI			;Frame valid, checks the Unique Identifier
			GOTO	_RCV_FINISH			;
										;
_ADDRESS	BTFSC	ADDR_CMPLT			;
			GOTO	_NBR_BYTES			;
			CALL	CHECK_ADDR			;
			GOTO	_RCV_FINISH			;
										;
_NBR_BYTES	BTFSC	NBR_BYTES_RCVD		;Number of bytes field has been received
			GOTO	_RECV_DATA			;
			CALL	NBR_BYTES_DATA		;
			GOTO	_RCV_FINISH			;
										;
_RECV_DATA	BTFSC	DATA_RECEIVED		;
			GOTO	_SUMCHECK			;
			CALL	ACCEPT_DATA			;data is made available
			GOTO	_RCV_FINISH			;
										;
_SUMCHECK	BTFSC	SUMCHECK_DONE		;
			GOTO	_ACCEPT_COMMAND		;
			CALL	CHECK_SUM			;
										;
_ACCEPT_COMMAND							;
			CALL	PROCESS_DATA		;Finished - sets RESET_CNTRS to force start over
_RCV_FINISH								;
			CLRF	L_DATA_RX			;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;This is a good place to set a break in case of error.  This procedure is made
;available to the library modules.
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
TREAT_ERROR
			Global	TREAT_ERROR
#IFDEF	DEBUG_MODE
			clrf	D_BUGGGER			;
_read_all	movf	D_BUGGGER,w			;
			movwf	G_CC_Reg			;read all regs 1 by 1
			sublw	d'28'				;
			btfss	STATUS,C			;
			goto	_SKIP_REGS			;
			call	ReadFromCC1000register
			movf	G_CC_Data,w			;
BREAKPOINT	nop							;READ THE REGISTER
			incf	D_BUGGGER,f			;
			goto	_read_all			;
#ENDIF									;
_SKIP_REGS	incf	D_ERROR_CNT,F		;count transmission errors										;
			BSF		RESET_CNTRS			;
			RETURN
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;This is the first procedure to be called after a RX. Detects and validates the preamble.
;The first byte of the preamble, in L_RX_BUFF(0), has already been detected and counted by
;RECEIVE_BIT
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CHECK_PREAMBLE							;
			MOVF	L_INDEX,W			;Point to the RX_buffer
			ADDLW	L_RX_BUFF			;
			MOVWF	FSR					;
			MOVLW	0xAA				;
			SUBWF	INDF,W				;			
			BTFSS	STATUS,Z			;zero flag set when 0 (EQ)
			GOTO	_PREA_FAIL			;
										;
_PREA_CONT	MOVF	L_BYTES,W			;The minimun matches must be 3
			SUBLW	2					;
			BTFSC	STATUS,C			;
			GOTO	_PREA_FIN			;
			BSF		PREAM_FINISHED		;Preamble found - this is where AverageLock would be managed
			CLRF	L_BYTES				;  if we were not using Manchester coding
			GOTO	_PREA_FIN			;			
_PREA_FAIL	BSF		RESET_CNTRS			;
			BCF		BOF_FOUND			;
			CLRF	L_BYTES				;
										;
_PREA_FIN	RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Checks for an exact match of the Unique Identifiers (2 bytes)
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CHECK_UI	MOVLW	L_RX_BUFF			;Point to the unique code of the receive buffer
			ADDLW	(UI-1)				;adjust for L_BYTES (1,2,3,...)
			ADDWF	L_BYTES,W			;
			MOVWF	FSR					;
			MOVLW	1					;
			SUBWF	L_BYTES,W			;Decide if we're looking for UI1 or UI2
			BTFSS	STATUS,Z			;
			GOTO	_CODE2				;
			MOVLW	UI_CODE1			;
			GOTO	_UI_CONT			;
_CODE2		MOVLW	UI_CODE2			;
										;
_UI_CONT	SUBWF	INDF,W				;			
			BTFSS	STATUS,Z			;zero flag set when 0 (EQ)
			GOTO	_UI_FAIL			;
										;
			MOVF	L_BYTES,W			;
			SUBLW	UI_SIZE				;done checking IU?
			BTFSS	STATUS,Z			;
			GOTO	_UI_BACK			;
										;
			BSF		UI_FINISHED			;UI complete and successful
			CLRF	L_BYTES				;
			GOTO	_UI_BACK			;
										;
_UI_FAIL	CALL	TREAT_ERROR			;IF ERROR
_UI_BACK	RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Address is not implemented, check for 0,0 now
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CHECK_ADDR	MOVLW	L_RX_BUFF			;
			ADDLW	(ADDRESS-1)			;
			ADDWF	L_BYTES,W			;Point to address part in the receive buffer
			MOVWF	FSR					;
			MOVLW	0					;fake address
			SUBWF	INDF,W				;			
			BTFSS	STATUS,Z			;zero flag set when 0 (EQ)
			GOTO	_ADDR_FAIL			;
			MOVF	L_BYTES,W			;Check the Addr and set the ADDR_CMPLT flag
			SUBLW	ADD_SIZE			; if this is the last byte (of 2)
			BTFSS	STATUS,Z			;
			GOTO	_ADDR_BACK			;
										;
			BSF		ADDR_CMPLT			;Address complete and correct
			CLRF	L_BYTES				;
			GOTO	_ADDR_BACK			;
										;
_ADDR_FAIL	CALL	TREAT_ERROR			;IF ERROR
										;
_ADDR_BACK	RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;We receive exactly 7 bytes of data.  If we are going to implement a
;variable size frame, Timer1 must be loaded according to the following:
;((numer of bytes in the frame* (10**6/baudrate)) / timer1 prescaler)
;where: 10**6/baudrate at 9600 = 104 uS per bit
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NBR_BYTES_DATA							;
			MOVLW	L_RX_BUFF			;Point to number of bytes in the receive buffer
			ADDLW	(NO_BYTES-1)		;
			ADDWF	L_BYTES,W			;
			MOVWF	FSR					;
			MOVLW	7					;make sure number of bytes is seven
			SUBWF	INDF,W				;
			BTFSS	STATUS,Z			;zero flag set when 0 (EQ)
			GOTO	_BYTES_FAIL			;
										;
			BSF		NBR_BYTES_RCVD		;
			CLRF	L_BYTES				;
			GOTO	_BYTES_DONE			;
										;
_BYTES_FAIL	CALL	TREAT_ERROR			;If too big or too small
_BYTES_DONE	RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Here the only thing to be done is wait for the number of bytes we are supposed to receive
;(currently fixed to 7 bytes) and set the DATA_RECEIVED flag. The real check for data 
;validity is in the checksum and in the processing of that data.
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
ACCEPT_DATA	
			MOVLW	L_RX_BUFF			;
			ADDLW	(DATA_OFFS-1)		;
			ADDWF	L_BYTES,W			;Point to data part of the receive buffer
										;
			MOVLW	L_RX_BUFF			;Point to number of bytes
			ADDLW	NO_BYTES			;
			MOVWF	FSR					;
			MOVF	INDF,W				;
			SUBWF	L_BYTES,W			;
			BTFSS	STATUS,Z			;
			GOTO	_ACCEPT_END			;
			BSF		DATA_RECEIVED		;all data received
			CLRF	L_BYTES				;
_ACCEPT_END	RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Sum check is only one byte so no use checking length.  This procedure called during
;reception of a frame
;CALLED FROM: RECEIVE
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CHECK_SUM	MOVLW	L_RX_BUFF			;
			MOVWF	FSR					;
			MOVLW	(TOT_FRAME_SIZ-1)	;
			MOVWF	L_Temp1				;
			CLRW						;
_CS_LOOP	ADDWF	INDF,W				;calculate the CS for the frame
			INCF	FSR,F				;
			DECFSZ	L_Temp1,F			;
			GOTO	_CS_LOOP			;
			MOVWF	L_Temp_CS			;
										;
			MOVLW	L_RX_BUFF			;
			ADDWF	L_INDEX,W			;L_INDEX points to CS
			MOVWF	FSR					;
			MOVF	INDF,W				;
			SUBWF	L_Temp_CS,W			;
			BTFSS	STATUS,Z			;SCs must be identical
			CALL	TREAT_ERROR			;
_SC_OK		BSF		SUMCHECK_DONE		;
_SC_FIN		RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Output the received data to the corresonding ports
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROCESS_DATA							;
			MOVLW	L_RX_BUFF+0xE		;Read the L_RX_BUFFER get received data for channel 1
			MOVWF	FSR					; 
			CALL	OUTPUT_PWM			;
										;
			MOVLW	L_RX_BUFF+0xD		;Read the L_RX_BUFFER get received data for channel 2
			MOVWF	FSR					;
			MOVF	INDF,W				;
			MOVWF	L_FREQ_L			;
			CALL	CALCULATE_PERIOD	;set the period value for next timer 1 expiration
										;
			MOVLW	L_RX_BUFF+0xC		;
			MOVWF	FSR					;
			MOVF	INDF,W				;
			MOVWF	L_TEMP_2			;
										;
			CLRC						;Read the L_RX_BUFFER get received data from the Switches
			RRF		L_TEMP_2,F			;
			BTFSS	STATUS,C			;output to LED1
			BCF		LED1				;
			BTFSC	STATUS,C			;
			BSF		LED1				;
										;
			RRF		L_TEMP_2,F			;
			BTFSS	STATUS,C			;output to LED2
			BCF		LED2				;
			BTFSC	STATUS,C			;
			BSF		LED2				;
										;
			RRF		L_TEMP_2,F			;
			BTFSS	STATUS,C			;output to LED3
			BCF		LED3				;
			BTFSC	STATUS,C			;
			BSF		LED3				;
										;
			MOVLW	L_RX_BUFF+0xC		;clean up
			MOVWF	FSR					;
			CLRF	INDF				;
			INCF	FSR,F				;
			CLRF	INDF				;
			INCF	FSR,F				;
			CLRF	INDF				;

			BSF		RESET_CNTRS			;
			MOVLW	L_RX_BUFF			;
			MOVWF	FSR					;
										;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Based on the value received from the master, calculate the period of the
;steering motor:	1/2 PERIOD = (2780+(255-L_FREQ_L)*4)/2
;i.e. the value 0xFF correspond to the maximun freq of 360Hz or 2.78ms period
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CALCULATE_PERIOD						;
			CLRF	L_FREQ_H			;
			COMF	L_FREQ_L,F			;X=(255-L_FREQ_L)
			RLF		L_FREQ_L,F			;X=X*2
			BTFSC	STATUS,C			;
			INCF	L_FREQ_H,F			;
			RLF		L_FREQ_L,F			;X=X*4
			BTFSC	STATUS,C			;
			INCF	L_FREQ_H,F			;
			MOVLW	0XDC				;X=X+2780
			ADDWF	L_FREQ_L,F			;
			RRF		L_FREQ_L,F			;
			BTFSC	STATUS,C			;
			INCF	L_FREQ_H,F			;
			MOVLW	0X0A				;			
			ADDWF	L_FREQ_H,F			;
			RRF		L_FREQ_H,F			;X=X/2
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Output received value to the traction wheels
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
OUTPUT_PWM								;
			MOVF	INDF,W				;
			MOVWF	L_TEMP_2			;
		M_CMPL_JG	L_TEMP_2,0x84,_FORWARD
										;
		M_CMPL_JL	L_TEMP_2,0x7C,_BACKWARD
										;
_STOP		BCF		SPIN_DIR			;SINK 0, SOURCE ZERO
			CLRF	CCPR1L				;
			GOTO	_OUTPUT_FIN			;
										;
_FORWARD	BSF		SPIN_DIR			;SINK 1, SOURCE NEGATIVE
			COMF	L_TEMP_2,F			;
			GOTO	_WRITE_PWM			;
										;
_BACKWARD	BCF		SPIN_DIR			;SINK 0, SOURCE POSITIVE
			COMF	L_TEMP_2,F			;
			MOVLW	0X7F				;
			ANDWF	L_TEMP_2,F			;
_WRITE_PWM	RRF		L_TEMP_2,F			;LSB - > CCP1CON<5,4>
			BCF		CCP1CON,4			;
			BTFSC	STATUS,C			;
			BSF		CCP1CON,4			;
										;
			RRF		L_TEMP_2,F			;
			BCF		CCP1CON,5			;
			BTFSC	STATUS,C			;
			BSF		CCP1CON,5			;
			MOVLW	0x3F				;MSB - > CCPR1L
			ANDWF	L_TEMP_2,W			;
			MOVWF	CCPR1L				;




										;
_OUTPUT_FIN	RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			END		; of code
