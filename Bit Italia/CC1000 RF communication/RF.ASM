;************************************************************
;	TITLE:	RF Transceiver via CC1000
;	Programmer: GINO ISLA
;	REVISION HISTORY:	31-03-03 First try
;						05-09-03 v1.0
;	HARDWARE: BIT SRL. lOW pOWER transciever
;	FREQUENCY: 4MHz
;	Function: Master salve query/response using a CC1000
;************************************************************
			list	p=16f876

#include	<p16f876.inc>
#include 	<CC1000.h>
#include 	<hw_interf.h>

;LOCAL DATA
	UDATA
L_Temp1			res 1 		;
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
L_GREEN_CTL		res	1		;control for flicking the leds
L_GREEN_COU		res	1		;number of times to flip
L_GR_SPEED		res	1		;temporary speed counter
;
L_RED_CTL		res	1		;same as green..
L_RED_COU		res	1		;
L_RED_SPEED		res	1		;
;
D_ERROR_CNT		res	1		;Counts number of times in TREAT_ERROR
D_ERROR_FLG		res	1		;Manual flag to read all CC1000 regs in TREAT_ERROR
D_BUGGGER		res	1		;
;
STATUS_TEMP		res 1		;for saving STATUS reg during ISR
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
	
;CONSTANTS
EE_ADDR_H	equ	0x21					; See EE_counter_addr
EE_ADDR_L	equ	0X00					;
;
;See also GET_NEXT_REGISTER and RAW_BUFFER for CC1000 constants.

;CONFIGURATION OF PIC
	__CONFIG	_CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_ON & _XT_OSC & _PWRTE_ON & _LVP_OFF & _DEBUG_ON & _CPD_OFF

	CODE
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			org	0x2100					;EEPROM as defined in linker
EE_counter_addr	de	0					;

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
START_OF_THE_PROGRAM
			org		0X000				; Reset Vector
			nop							;
			clrf	PCLATH				;
			goto	Start				;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			org		0x004				;Iterrupt Vector
			goto	Service_Interrupt	;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Table lookups for CC1000 register
;Lookout for page boundaries!!!!!
GET_NEXT_REGISTER
			Global	GET_NEXT_REGISTER	;
			ADDWF	PCL,F				;
										;	
CC1Kregs	DATA 0x3400,0x3458,0x3420,0x3400,0x3442,0x3414,0x349c,0x3402	;Rf XTAL: 14.745600
			DATA 0x3480,0x3444,0x3412,0x34FF,0x3460,0x3410,0x3426,0x348E	;PA_POW<0BH>=FF 
			DATA 0x346F,0x3447,0x3470,0x3401,0x3400,0x3400,0x3400,0x3400	;MODEM0<11H>
			DATA 0x3400,0x3400,0x3400,0x3400,0x3400
			Global	CC1Kregs			;
			RETURN 	

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Table lookup, build a frame of data
RAW_BUFFER
			Global	RAW_BUFFER			;
			ADDWF	PCL,F				;
										;	
Comm_buffer	DATA 0x34AA,0x34AA,0x34AA,0x34CD,0x344D,0x3400,0x3400,0x3407	;whole frame
			DATA 0x3400,0x3400,0x3400,0x3400,0x3400,0x3400,0x3400,0x3400
			Global	Comm_buffer			;
			RETURN 	
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
			CLRF	L_EE_COUNT_L		;
			CLRF	STATUS				;BANK 0 REGISTERS
			CLRF	SSPCON				;disable serial port
			CLRF	ADCON0				;
			CLRF	RCSTA				;Serial port disabled(bit banging)
			CLRF	INTCON				;
			CLRF	PORTA				;
			CLRF	PORTB				;
			CLRF	PORTC				;
										;
			BSF		STATUS,RP0			;BANK 1 REGISTERS
			MOVLW	7					;
			MOVWF	ADCON1				;
										;
			MOVLW	b'00000011'			;
			MOVWF	PCON				;power-on, brown-out resets
										;
			MOVLW	0xFF				;  RA3=Master/Salve Strap (MSTRAP)
			MOVWF	TRISA				;
			MOVLW	0xF9				; RB0=DCLK,RB1=GREEN LED,RB2=RED LED,RB4=button
			MOVWF	TRISB				;(read INTF INTCON<1> for external INT on RB0)
			MOVLW	0xF0				;RC<0,1,2,3>=PDATA,PCLK,PALE,DIO = out
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
			MOVLW	b'11001000'			;PortB pullups disabled,
			MOVWF	OPTION_REG			;xxxx1000b prescaler assigned to WDT
										;
			BCF		STATUS,RP0			;MORE BANK 0 REGISTERS
			MOVLW	b'00000000'			;xx00xx0x ; Timer1 1:1 prescale, timer1 OFF
			MOVWF	T1CON				;
			MOVLW	RXMIT_TIM1L			;Reset TIMER1
			MOVWF	TMR1L				;
			COMF	TMR1L,F				;
			MOVLW	RXMIT_TIM1H			;
			MOVWF	TMR1H				;
			COMF	TMR1H,F				;
										;
			BSF		PCLK				;
			BSF		PDATA				;
			BSF		PALE				;
			BSF		CALIBRATION_OK		;
										;
			BSF		RED_LED				;start of CC1000 initialization
			CALL	Setup_CC1000PD		;Setup after Power down CC1000
										;
			CALL	Reset_CC1000		;Reset it  [(A) and (B) fig 16]
										;
			MOVLW	CC1Kregs 			;
			CALL	Setup_CC1000All		;Setup all other 28 registers [(C) fig 16]
										;
			MOVLW	RX_CURRENT			;
			CALL	WakeUpCC1000toRx	;Start calibration (A....G) fig 17)
										;
			MOVLW	RX_CURRENT			;
			CALL	SetupCC1000Rx		;
			BTFSS	CALIBRATION_OK		;
			GOTO	_CAL_ENDED			;
										;
			CALL	CalibrateCC1000		;Single calibration as TX
			BTFSS	CALIBRATION_OK		;
			GOTO	_CAL_ENDED			;
										;
			MOVLW	TX_CURRENT			;
			CALL	WakeUpCC1000toTx	;
										;
			MOVLW	TX_CURRENT			;
			CALL	SetupCC1000Tx		;Switch to Tx
			BTFSS	CALIBRATION_OK		;
			GOTO	_CAL_ENDED			;
										;
			CALL	CalibrateCC1000		;Single calibration  [(D) and (E) FIG 16]
										;
_CAL_ENDED	BTFSS	CALIBRATION_OK		;
			GOTO	_CAL_NOK			;
			BCF		RED_LED				; 
			MOVLW	3					;
			MOVWF	L_GREEN_COU			;
			MOVLW	SLOW_ON				;
			MOVWF	L_GREEN_CTL			;
			GOTO	_INIT_CONT			;
_CAL_NOK	MOVLW	3					;Flash 3 times to indicate failed 
			MOVWF	L_RED_COU			;startup of RF part
			MOVLW	SLOW_ON				;
			MOVWF	L_RED_CTL			;
										;
_INIT_CONT	MOVLW	0x88				;set GIE<7>,INTE<4>,RBIE<3> (GIE,BUTTN)
			MOVWF	INTCON				;clear TMR0IF<2>,INTF<1>,RBIF<0>,PEIE<6>,
			BCF		PIR1,TMR1IF			;clear TMR1 interrupt flag
										;
			BSF		T1CON,TMR1ON		;Start timer1
										;
			BTFSC	MSTRAP 				;Strap to high for MASTER
			GOTO	_MASTER_RESET		;
			MOVLW	RX_CURRENT			;
			CALL	SetupCC1000Rx		;
			BSF		SLAVE				;
			BSF		RXCVER				; Slave stays in Rx mode
			GOTO	_RESET				;
										;
_MASTER_RESET							;
			CALL	Setup_CC1000PD		;Turn off CC1000 until master button is pressed (normally high)
			BSF		MASTER				;
			BSF		QUIET				;
			GOTO	_RESET				;
										;
;If this is the master wait for the button press to start the query to the slave.  
;If slave, wait for the button to be pressed or for the master's query.
;ISR will trap the button for slave and master actions.
										;
_IDLE_LOOP	BTFSS	RESET_CNTRS			;
			GOTO	_TIMR1_ACTIONS		;
										;
_RESET		CLRF	L_BYTES				;Start all over
			MOVLW	8					;
			MOVWF	L_BITS				;Initialize bit counter
			MOVLW	-1					;  so index goes to 0 on BOF
			BTFSC	TXMTER				;L_INDEX starts at -1 or 0 depending
			CLRW						; on wether we're receiver or xmitter
			MOVWF	L_INDEX				;
			BCF		BYTE_FULL			;G_Events<4,5>
			BCF		RESET_CNTRS			;
			CLRF	G_Pr_status			;
										;
_TIMR1_ACTIONS							;
			BTFSS	PIR1,TMR1IF			;TIMR1 expired?
			GOTO	_POLL_DCLCK			;
			BCF		PIR1,TMR1IF			; 
			CALL	HANDLE_LED_BLINK	;
										;
			BTFSS	MASTER				;IF TMR1 EXPIRED &  
			GOTO	_POLL_DCLCK			;   MASTER & 
			BTFSS	RXCVER				;   ~XMITTER &
			GOTO	_POLL_DCLCK			;   ~BOF_FOUND
			BTFSC	BOF_FOUND			;THEN
			GOTO	_POLL_DCLCK			;
			CALL	START_MST_XMIT		; Time to send again
			GOTO	_COMMS_END			;ENDIF
										;
_POLL_DCLCK								;
			BTFSS	INTCON,INTF			;IF DCLCK PULSE &
			GOTO	_COMMS_END			;   ~QUIET
			BTFSC	QUIET				;
			GOTO	_COMMS_END			;THEN
										;
			BTFSS	RXCVER				;
			GOTO	_XMIT				;
										;
_RCVE		CALL	RECEIVE_BIT			;  IF RECEIVER
			BTFSS	BYTE_FULL			;     (Master or Slave) receive next bit
			GOTO	_COMMS_END			;
			CALL	RECEIVE_BYTE		;     IF received a full byte
			BCF		BYTE_FULL			;       check protocol parts
			GOTO	_COMMS_END			;     ENDIF
										;  ELSE (XMT)
_XMIT		CALL	SEND_BIT			;     Send next bit
			BTFSS	BYTE_FULL			;     IF full byte sent
			GOTO	_COMMS_END			;        IF MASTER        
			BTFSS	MASTER				;          do master EOTX actions
			GOTO	_XMIT_SLV			;           (see if finished, adjust index)
										;         ELSE (slave)
			CALL	CHECK_MST_EOTX		;           do slave EOTX actions 
			GOTO	_XMIT_END			;         ENDIF
_XMIT_SLV	CALL	CHECK_SLV_EOTX		;      
_XMIT_END	BCF		BYTE_FULL			;      ENDIF
										;   ENDIF
_COMMS_END	GOTO	_IDLE_LOOP			;ENDIF (end of idle loop)
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;This procedure handles the blinking of the LEDs which are candenced by TMR1
;
HANDLE_LED_BLINK
_GREEN_LED	BTFSS	GREEN_FLAG			;
			GOTO	_RED_LED			;
			MOVF	L_GR_SPEED,F		;test if zero
			BTFSC	STATUS,Z			;
			GOTO	_TOGGLE_GR			;
			DECF	L_GR_SPEED,F		;
			GOTO	_RED_LED			;
										;
_TOGGLE_GR	RLF		L_GREEN_CTL,W		;Rotate through carry
			BTFSS	STATUS,C			; and flip the toggle bit
			GOTO	_GREEN_OFF			;
			BSF		GREEN_LED			;
			BCF		TOGGLE_G			;
			GOTO	_RES_G_SPD			;
_GREEN_OFF	BCF		GREEN_LED			;Decrement the count only on OFF
			BSF		TOGGLE_G			;
			DECFSZ	L_GREEN_COU,F		;Reached number of toggles?
			GOTO	_RES_G_SPD			;
			CLRF	L_GREEN_CTL			;finished			
			GOTO	_RED_LED			;
_RES_G_SPD	MOVF	L_GREEN_CTL,W		;Reset the speed counter
			ANDLW	0x3F				;
			MOVWF	L_GR_SPEED			;
										;
_RED_LED	BTFSS	RED_FLAG			;
			GOTO	_BLINK_END			;
			MOVF	L_RED_SPEED,F		;test if zero
			BTFSC	STATUS,Z			;
			GOTO	_TOGGLE_RD			;
			DECF	L_RED_SPEED,F		;
			GOTO	_BLINK_END			;
										;
_TOGGLE_RD	RLF		L_RED_CTL,W			;Rotate through carry
			BTFSS	STATUS,C			; and flip the toggle bit
			GOTO	_RED_OFF			;
			BSF		RED_LED				;
			BCF		TOGGLE_R			;
			GOTO	_RES_R_SPD			;
_RED_OFF	BCF		RED_LED				;Decrement the count only on OFF
			BSF		TOGGLE_R			;
			DECFSZ	L_RED_COU,F			;Reached number of toggles?
			GOTO	_RES_R_SPD			;
			CLRF	L_RED_CTL			;finished			
			GOTO	_BLINK_END			;		
_RES_R_SPD	MOVF	L_RED_CTL,W			;Reset the speed counter
			ANDLW	0x3F				;
			MOVWF	L_RED_SPEED			;
										;
_BLINK_END	RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Receive the next bit,count full bytes, find the beginning of a frame.
;CALLED FROM: Idle loop
;
RECEIVE_BIT
_DATA_IN	MOVLW	d'6'				;do a persistancy check first (50us)
			MOVWF	L_PERSIST			;
_DCLK_IN	BTFSS	DCLK				;
			GOTO	_NO_BIT_IN			;ignore spikes
			DECFSZ	L_PERSIST,F			;
			GOTO	_DCLK_IN			;
										;
_RX_CONT	MOVF	PORTC,W				;Persistancy check on the port
			ANDLW	8					;PORTC<3>
			MOVWF	L_PORTC				;
			MOVLW	d'4'				;
			MOVWF	L_PERSIST			;
_DIO_IN_P	MOVF	PORTC,W				;read again
			ANDLW	8					;
			XORWF	L_PORTC,W			;
			BTFSS	STATUS,Z			;still the same?
			GOTO	_NO_BIT_IN			;ignore spikes
			DECFSZ	L_PERSIST,F			;
			GOTO	_DIO_IN_P			;
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
_RX_END		BCF		INTCON,INTF			;
_NO_BIT_IN	RETURN
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Send the next bit in L_TX_BUFF(L_INDEX,L_BITS)
SEND_BIT								;
			MOVLW	d'12'				;persistancy check 50us
			MOVWF	L_PERSIST			;
_DCLK_OUT	BTFSC	DCLK				;
			GOTO	_NO_BIT_OUT			;ignore spikes
			DECFSZ	L_PERSIST,F			;
			GOTO	_DCLK_OUT			;
										;
_TX_CONT	MOVF	L_INDEX,W			;
			ADDLW	L_TX_BUFF			;
			MOVWF	FSR					;Data to send: L_TX_BUFFER(L_INDEX<L_BITS>)
			RLF		INDF,F				;
			BTFSS	STATUS,C			;CARRY?
			GOTO	_CLR_DIO			;
			BSF		DIO					;
			GOTO	_XM_CONT			;
_CLR_DIO	BCF		DIO					;
										;
_XM_CONT	DECFSZ	L_BITS,F			;8 bits sent?
			GOTO	_OUT_END			;
										;
			BSF		BYTE_FULL			;
			INCF	L_BYTES,F			;L_BYTES is modified by each procedure
			INCF	L_INDEX,F			;
			MOVLW	8					;
			MOVWF	L_BITS				;reset bit count 
										;
_OUT_END	BCF		INTCON,INTF			;
_NO_BIT_OUT	RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Procedure:	Service_Interrupt
;Function:	Handles Interrupts for the Push Button and the TMR1 expiration.
;           Handling of the button is different depending on wether this is 
;			the Master or the Slave.
;Inputs:	None
;Returns:	Nothing.
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Service_Interrupt						;
			MOVWF	W_TEMP				;W_TEMP MUST be in shared memory
			SWAPF	STATUS,W			;
			MOVWF	STATUS_TEMP			;
			CLRF	STATUS				;
			MOVWF	STATUS_TEMP			;
										;
			BTFSS	INTCON,RBIF			;BUTTON PRESS (PORTB<4> state change)?
			CALL	TREAT_ERROR			; Unknown Interrupt
										;Read the port so it can be cleared
			MOVF	PORTB,W				;
			BTFSC	PORTB,4				;Button pushed
			GOTO	_RES_RBIF			;
										;
_WAI_RELS	MOVLW	d'100'				;Introduce delays to avoid bouncing
			CALL	DelaymS				; (note that interrupts are disabled)
			BTFSS	PORTB,4				;Stay in loop while button is released
			GOTO	_WAI_RELS			;(normally high goes low when pushed)
										;
			BTFSS	MASTER 				;
			GOTO	_BUTTN_SLV			;
										;
			BTFSS	QUIET				;
			GOTO	_RES_RBIF			;Send from master only if we're not already
										; sending or receiveing
			MOVLW	TX_CURRENT			;First power up CC1000 - consider at least 14ms
			CALL	WakeUpCC1000toTx	;
										;
			CALL	START_MST_XMIT		;
			GOTO	_RES_RBIF			;
										;
_BUTTN_SLV	CALL	SLAVE_BUTTON		;
_RES_RBIF	BCF		INTCON,RBIF			;
										;
_ISR_END	SWAPF	STATUS_TEMP,W		;
			MOVWF	STATUS				;
			SWAPF	W_TEMP,F			;
			SWAPF	W_TEMP,W			;
			RETFIE						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Treat reception of a packet - the first byte of the pre-amble has already been
;detected
;CALLED FROM: Idle Loop
;
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
;This is a good place to set a breakpoint in case of error
;
TREAT_ERROR
			Global	TREAT_ERROR
			nop							;BREAKPOINT TO RAISE THE FLAG
			btfss	D_ERROR_FLG,0		;Set this flag to 1 while in debugging mode
			GOTO	_SKIP_REGS			;
			clrf	D_BUGGGER			;
_read_all	movf	D_BUGGGER,w			;
			movwf	G_CC_Reg			;read all regs 1 by 1
			sublw	d'28'				;
			btfss	STATUS,C			;
			goto	_SKIP_REGS			;
			call	ReadFromCC1000register
			movf	G_CC_Data,w			;
			nop							;BREAKPOINT TO READ THE REGISTER
			incf	D_BUGGGER,f			;
			goto	_read_all			;
										;
_SKIP_REGS	incf	D_ERROR_CNT,F		;count transmission errors										;
			bsf		RESET_CNTRS			;
			RETURN
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Read, increment and re-write the counter
;Runs on interrupts disabled
;CALLED FROM: ISR
;
SLAVE_BUTTON							;
;			CALL	READ_EEPROM			;
			BTFSS	NEW_COUNT			;
			GOTO	_COUNT_UP			;
			BCF		NEW_COUNT			;
			CLRF	L_EE_COUNT_L		;
_COUNT_UP	INCF	L_EE_COUNT_L,F		;Increment the counter
			NOP							;This is where we would treat an overflow
;			CALL	WRITE_EEPROM		;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Setup the buffer which will be transmitted in NEXT_BIT, then become transmitter.
;CALLED FROM: ISR, Idle loop
;
START_MST_XMIT							;
			BSF		GREEN_LED			;
			CALL	FILL_TX_BUFFER		;
										;Here we could add additional instructions for
			MOVLW	TX_CURRENT			; the slave in the TX buffer
			CALL	SetupCC1000Tx		;Switch to Tx
			BCF		QUIET				;
			BCF		RXCVER				;
			BSF		TXMTER				;
			BSF		RESET_CNTRS			;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;When transmission is finished, become receiver and set the retry timer.
;CALLED FROM: Idle loop
CHECK_MST_EOTX							;
			MOVF	L_INDEX,W			;
			SUBLW	TOT_FRAME_SIZ		;	
			BTFSS	STATUS,Z			;
			GOTO	_MASTR_NOT_DONE		;still sending bits...
										;
			MOVLW	RX_CURRENT			;Tranmission is finished, become receiver again 
			CALL	SetupCC1000Rx		;(NOTE: this takes as much as 4-5 mS!!)
										;
			INCF	D_BUG2,F			;for debug, indicate MASTER-TX buffer sent
			MOVF	D_BUG2,W			;
			MOVWF	L_TX_BUFF			;
										;
			BCF		T1CON,TMR1ON		;Reset TIMER1
			BCF		PIR1,TMR1IF			; 
			MOVLW	RXMIT_TIM1L			;
			MOVWF	TMR1L				;
			COMF	TMR1L,F				;
			MOVLW	RXMIT_TIM1H			;
			MOVWF	TMR1H				;
			COMF	TMR1H,F				;
			BSF		T1CON,TMR1ON		;Start timer1
										;
			BCF		TXMTER				;
			BSF		RXCVER				;
			BCF		GREEN_LED			;
			BSF		RESET_CNTRS			;
_MASTR_NOT_DONE							;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Prepare the slave response, fill the buffer add the EEPROM data, recalculate the SC 
;and become transmitter
;CALLED FROM: PROCESS_DATA
;
START_SLV_XMIT
			BSF		GREEN_LED			;Signal
			CALL	FILL_TX_BUFFER		;Build the TX_BUFFER
;			CALL	READ_EEPROM			;Get the EEPROM counters
			MOVF	L_EE_COUNT_L,W		;
			MOVWF	L_Temp1				;
										;
			MOVLW	L_TX_BUFF			;put it as last byte of data
			ADDLW	(DATA_OFFS+6)		;
			MOVWF	FSR					;
			MOVF	L_Temp1,W			;
			MOVWF	INDF				;
										;
			MOVLW	L_TX_BUFF			;Update CS 
			ADDLW	SUM_CHECK			;
			MOVWF	FSR					;
			MOVF	INDF,W				;
			ADDWF	L_Temp1,W			;
			MOVWF	INDF				;
										;clear EEPROM counter
;			CALL	WRITE_EEPROM		;
										;
			MOVLW	TX_CURRENT			;
			CALL	SetupCC1000Tx		;Become transmitter
			MOVLW	d'7'				;necessary courtesy wait for master tx -> rx transition
			CALL	DelaymS				;
										;
			BSF		NEW_COUNT			;
			BCF		RXCVER				;
			BSF		TXMTER				;
			BSF		RESET_CNTRS			;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;This procedure gets called each time a full byte (8 bits) has been transmitted by
;SEND_BIT.  When the end of the buffer is reached, it causes this PIC to become a
;receiver again.
;CALLED FROM: Idle loop
CHECK_SLV_EOTX							;
			MOVF	L_INDEX,W			;
			SUBLW	TOT_FRAME_SIZ		;Check for end of tranmission	
			BTFSS	STATUS,Z			;
			GOTO	_SLAVE_DONE			;
										;we're done sending
			MOVLW	RX_CURRENT			;
			CALL	SetupCC1000Rx		;Become receiver again
										;
			INCF	D_BUG2,F			;for debug, indicate SLAVE-TX buffer sent
			MOVF	D_BUG2,W			;
			MOVWF	L_TX_BUFF			;
										;
			BCF		TXMTER				; initiate transmission
			BSF		RXCVER				;
			BCF		GREEN_LED			;
			BSF		RESET_CNTRS			;
_SLAVE_DONE	RETURN
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;This is the first procedure to be called after a RX. Detects and validates the preamble.
;The first byte of the preamble, in L_RX_BUFF(0), has already been detected and counted by
;RECEIVE.
;CALLED FROM: RECEIVE
;
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
;CALLED FROM: RECEIVE
;
CHECK_UI	
			MOVLW	L_RX_BUFF			;Point to the unique code of the receive buffer
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
;Address is not really implemented, check for 0,0 now
;CALLED FROM: RECEIVE
;
CHECK_ADDR
			MOVLW	L_RX_BUFF			;
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
;CALLED FROM: RECEIVE
;
NBR_BYTES_DATA
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
;and set the DATA_RECEIVED flag. The real check for data validity is in the checksum and in 
;the processing of that data.
;CALLED FROM: RECEIVE
;
ACCEPT_DATA	
			MOVLW	L_RX_BUFF			;
			ADDLW	(DATA_OFFS-1)		;
			ADDWF	L_BYTES,W			;Point to data part of the receive buffer
										;........ do something....
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
;
CHECK_SUM
			MOVLW	L_RX_BUFF			;
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
;Process the the packet received depending on wether this is slave or master. 
;The Slave replies to the master query, the Master receives the data sent from
;the Slave and lights the corresponding LED.
;Sets RESET_CNTRS when necessary to force start over.
;Note:
;If the response from the slave to the master query is lost, there is no recovery. The
;protocol should consider and acknowledgement before the counter is wiped out.
;CALLED FROM: RECEIVE
;
PROCESS_DATA		
			MOVLW	1					;
			MOVWF	L_RED_COU			;
			MOVLW	SLOW_ON				;
			MOVWF	L_RED_CTL			;
										;
			BCF		INTCON,GIE			;Disable interrupts to switch to TX/Rx
			BTFSC	MASTER				;Master
			GOTO	_MAST_PROC			;
			CALL	START_SLV_XMIT		;This is were we could chose slave
			GOTO	_PROC_END			;actions.  For now, just send the counter.
										;
_MAST_PROC	MOVLW	L_RX_BUFF			;Read the RX_BUFFER
			ADDLW	(DATA_OFFS+6)		; and light the 
			MOVWF	FSR					; corresponding LED
			MOVF	INDF,W				;
			BTFSC	STATUS,Z			;
			GOTO	_MAST_END			;
			MOVWF	L_GREEN_COU			;
			MOVLW	SLOW_ON				;
			MOVWF	L_GREEN_CTL			;
_MAST_END	BSF		QUIET				;job finished
			CALL	Setup_CC1000PD		;Turn off CC1000 until button is pressed again
_PROC_END	BSF		INTCON,GIE			;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;copy the Comm_buffer to the TX_BUFFER, calculate and fill the check sum
;CALLED FROM: START_MST_XMIT, START_SLV_XMIT
;
FILL_TX_BUFFER							;
			CLRF	L_INDEX				;
			CLRF	L_Temp_CS			;
			CLRF	L_NEXT_FR_BYT		;number of frame bytes
			MOVLW	L_TX_BUFF			;
			ADDWF	L_NEXT_FR_BYT,W		;
			MOVWF	FSR					;INDF -> L_TX_BUFF (Dest)
			MOVLW	(TOT_FRAME_SIZ-1)	;
			MOVWF	L_TX_COUNT			;
										;
_TX_COPY	MOVLW	HIGH RAW_BUFFER		;
			MOVWF	PCLATH				;
			MOVF	L_NEXT_FR_BYT,W		;
			CALL	RAW_BUFFER			;
			MOVWF	INDF				;
			ADDWF	L_Temp_CS,F			;compute check sum
										;
			INCF	FSR,F				;
			INCF	L_NEXT_FR_BYT,F		;
			DECFSZ	L_TX_COUNT,F		;
			GOTO	_TX_COPY			;
										;
			MOVF	L_Temp_CS,W			;
			MOVWF	INDF				;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Reads the counter in EEPROM which is locatated in PROGRAM MEMORY and returns it in L_EE_COUNT.
;EEPROM is defined as FLASH MEMORY (in Program Memory)
;Runs on interrupts disabled
;CALLED FROM: 
;
;READ_EEPROM
;			BSF		STATUS,RP1			;bank 2
;			BCF		STATUS,RP0			;
;			MOVLW	EE_ADDR_H			;
;			MOVWF	EEADRH				;
;			MOVLW	EE_ADDR_L			;
;			MOVWF	EEADR				;
;			BSF		STATUS,RP0			;bank 3
;			BSF		EECON1,EEPGD		;Point to program memory
;			BSF		EECON1,RD			;
;			NOP							;
;			NOP							;
;			BCF		STATUS,RP0			;bank 2
;			MOVF	EEDATA,W			;
;			MOVWF	L_EE_COUNT_L		;
;			MOVF	EEDATH,W			;
;			MOVWF	L_EE_COUNT_H		;
;			BCF		STATUS,RP1			;bank 0
;			RETURN 						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Writes the counter in EEPROM which is locatated in PROGRAM MEMORY
;Parameters: L_EE_COUNT
;Runs on interrupts disabled
;CALLED FROM: 
;
;WRITE_EEPROM
;			BSF		STATUS,RP1			;
;			BCF		STATUS,RP0			;bank 2
;			MOVLW	EE_ADDR_H			;
;			MOVWF	EEADRH				;
;			MOVLW	EE_ADDR_L			;
;			MOVWF	EEADR				;
;			MOVLW	L_EE_COUNT_L		;contains (points) the 1st byte of data
;			MOVWF	FSR					;
_;EE_LOOP	MOVF	INDF,W				;
;			MOVWF	EEDATA				;
;			INCF	FSR,F				;
;			MOVF	INDF,W				;second byte
;			MOVWF	EEDATH				;
;			INCF	FSR,F				;
;			BSF		STATUS,RP0			;bank 3
;			BSF		EECON1,EEPGD		;
;			BSF		EECON1,WREN			;
;			BCF		INTCON,GIE			;
;			MOVLW	0x55				;
;			MOVWF	EECON2				;
;			MOVLW	0xAA				;
;			MOVWF	EECON2				;
;			BSF		EECON1,WR			;
;			NOP							;			
;			NOP							;			
;			BCF		EECON1,WREN			;
;			BSF		INTCON,GIE			;
;			BCF		STATUS,RP0			;bank 2
;			INCF	EEADR,F				;
;			MOVF	EEADR,W				;
;			ANDLW	0x03				;
;			XORLW	0x03				;
;			BTFSC	STATUS,Z			;
;			GOTO	_EE_LOOP			;
;			BCF		STATUS,RP1			;bank 0
;			BCF		STATUS,RP0			;
;			RETURN 						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Reads the counter in EEPROM which is locatated in DATA MEMORY and returns it in W.  
;Runs on interrupts disabled
;CALLED FROM: 
;
;READ_EEPROM
;			MOVLW	EE_counter_addr		;
;			BSF		STATUS,RP1			;bank 2
;			BCF		STATUS,RP0			;
;			MOVWF	EEADR				;
;			BSF		STATUS,RP0			;bank 3
;			BCF		EECON1,EEPGD		;
;			BSF		EECON1,RD			;
;			BCF		STATUS,RP0			;
;			MOVF	EEDATA,W			;
;			BCF		STATUS,RP1			;bank 0
;			BCF		STATUS,RP0			;
;			MOVWF	L_EE_COUNT			;
;			RETURN 						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Writes the counter in EEPROM which is locatated in DATA MEMORY
;Parameters: L_EE_COUNT
;Runs on interrupts disabled
;CALLED FROM: 
;
;WRITE_EEPROM
;			BSF		STATUS,RP1			;bank 3
;			BSF		STATUS,RP0			;
;			BTFSC	EECON1,WR			;in case of pending writes?
;			GOTO	$-1					;
;			BCF		STATUS,RP0			;bank 2
;			MOVLW	EE_counter_addr		;
;			MOVWF	EEADR				;
;			BCF		STATUS,RP1			;bank 0
;			MOVF	L_EE_COUNT,W		;
;			BSF		STATUS,RP1			;bank 2
;			MOVWF	EEDATA				;
;			BSF		STATUS,RP0			;
;			BCF		EECON1,EEPGD		;Prepare to write
;			BSF		EECON1,WREN			;
;			MOVLW	0x55				;
;			MOVWF	EECON2				;
;			MOVLW	0xAA				;
;			MOVWF	EECON2				;
;			BSF		EECON1,WR			;
;			BCF		EECON1,WREN			;Enable writes
;			BCF		STATUS,RP1			;bank 0
;			BCF		STATUS,RP0			;
;			RETURN 						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			END		; of code
