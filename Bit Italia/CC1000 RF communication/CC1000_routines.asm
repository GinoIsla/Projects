;************************************************************
;	TITLE:	CC1000 assembler routines
;	FILENAME:  CC1000_routines.asm
;	REVISION HISTORY:  31-03-03 First try
;	HARDWARE: BIT SRL. transciever
;	FREQUENCY: 4MHz
;	Function: Unlinked Object with Interfaces to CC1000
;************************************************************
			list	p=16f876

#include	<p16f876.inc>
#include 	<CC1000.h>
#include 	<hw_interf.h>


;MISCELLANEOUS DEFINITIONS	
#define F_Carry	STATUS,0	;Most Significant Bit gets rotated through carry flag

;Library support:
;================
	extern	DelaymS,Delay100uS,DelayuS,GET_NEXT_REGISTER,TREAT_ERROR
	extern	CC1Kregs
	
	
;MACROS
;======
@PDATAOUT	MACRO
			BSF		STATUS,RP0			;bank 1
			BCF		PDATA_DIR			;output
			BCF		STATUS,RP0			;return to bank0
			ENDM

@PDATAIN	MACRO
			BSF		STATUS,RP0			;bank 1
			BSF		PDATA_DIR			;input
			BCF		STATUS,RP0			;return to bank0
			ENDM

@DIOOUT		MACRO	
			BSF		STATUS,RP0			;bank 1
			BCF		OPTION_REG,6		;Interrupt on RB0 falling edge
			BCF		DIO_DIR				;output
			BCF		STATUS,RP0			;return to bank0
			ENDM

@DIOIN		MACRO
			BSF		STATUS,RP0			;bank 1
			BSF		OPTION_REG,6		;Interrupt on RB0 rising edge
			BSF		DIO_DIR				;input
			BCF		STATUS,RP0			;return to bank0
			ENDM
	
	UDATA
;GLOBAL DATA
G_CC_Reg	res	1
G_CC_Data	res	1

;LOCAL DATA	
L_BITCOU_W	res	1	;bit counter for writing to CC100 regs
L_BITCOU_R	res	1	;bit counter for reading from CC1000 regs
L_BITCOU_S	res	1	;bit counter for sending addr to CC1000 regs
L_TEMPADD	res	1	;
L_TEMPDATA	res	1	;
L_SUP_REG	res	1	;register counter in setupall 
L_RX_CUR	res	1	;RX current
L_TX_CUR	res	1	;TX current
;
L_TIMEOUT1	res	1	;
L_TIMEOUT2	res	1	;

;EXTERNAL OR GLOBAL SYMBOLS
;============================
	global G_CC_Reg,G_CC_Data
	extern	G_Events,G_Pr_status

		CODE	
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Procedure:	WriteToCC1000register
;Function:	Write data to CC1000
;Inputs:	Address to write to loaded in Addr
;			Value loaded in Data_Unit (does not destroy it)
;Returns:	Nothing?
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
WriteToCC1000register
			global WriteToCC1000register
			MOVF	G_CC_Data,W		;
			MOVWF	L_TEMPDATA		;
			CALL	Send_address_to_CC1000
			BSF		PCLK			;
			NOP						;
			BSF		PDATA			;WRITE command is bit(0) HIGH
			NOP
			BCF		PCLK			;(A)
			NOP						;
			BSF		PCLK			;(B)
			NOP						;Allow for Tha
			NOP						;Allow for Tha
			BSF		PALE			;
			NOP						;Allow for Tsa(2)??
			NOP						;Allow for Tsa(2)??
			NOP						;Allow for Tsa(2)??
									;
			MOVLW	0x08			;Send databyte
			MOVWF	L_BITCOU_W		;BIT COUNTER
_WDATA_1	BSF		PCLK			;
			RLF		L_TEMPDATA,F	;
			BTFSS	F_Carry			;Carry flag?
			GOTO	_WDATA_2		;
			BSF		PDATA			;
			GOTO	$+2				;
_WDATA_2	BCF		PDATA			;
			BCF		PCLK			;SEND DATA
			DECFSZ	L_BITCOU_W,F	;
			GOTO	_WDATA_1		;Loop 8 bits
			BSF		PCLK			;
			BSF		PDATA			;
			BSF		PALE			;
			RETURN					;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Procedure:	ReadFromCC1000register
;Function:	Reads data from CC1000
;Inputs:	Address to read from loaded in G_CC_Reg
;Returns:	Read byte in G_CC_Data
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
ReadFromCC1000register
			global	ReadFromCC1000register
			CALL	Send_address_to_CC1000
			BSF		PCLK			;(-A)
			NOP						;
			BCF		PDATA			;READ command is bit(0) LOW
			NOP						;
			BCF		PCLK			;(A)
			NOP						;
			NOP						;
			NOP						;
			BSF		PCLK			;(B)
			NOP						;
			BSF		PDATA			;(C)
			BSF		PALE			;(D)
									;
			@PDATAIN				;Data In
			MOVLW	0x08			;
			MOVWF	L_BITCOU_R		;BIT COUNTER
			CLRF	G_CC_Data		;
									;
_RDATA_1	CLRC					;CLEAR CARRY FLAG
			RLF		G_CC_Data,F		;READ CYCLE
			BCF		PCLK			;
			MOVF	PORTC,W			;READ PORT C
			ANDLW	1				;
			IORWF	G_CC_Data,F		;
			BSF		PCLK			;
			DECFSZ	L_BITCOU_R,F	;
			GOTO	_RDATA_1		;Loop 8 bits
									;read finished
			@PDATAOUT				;leave it as Output, high impedance
			BSF		PCLK			;
			BSF		PDATA			;
			BSF		PALE			;
			RETURN					;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Procedure:	Send_address_to_CC1000
;Function:	Sends the address to CC1000 for either read or write operation
;Inputs:	Address  loaded in G_CC_Reg
;Returns:	Nothing - does not destroy contents of G_CC_Reg
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Send_address_to_CC1000
			BSF		PALE			;
			MOVF	G_CC_Reg,W		;
			MOVWF	L_TEMPADD		;
			BCF		PALE			;
			RLF		L_TEMPADD,F		;Allows for Tsa(1)
			MOVLW	7				;7 MSBs
			MOVWF	L_BITCOU_S		;BIT COUNTER
_ADDR_0		BSF		PCLK			;SEND ADDRESS
			RLF		L_TEMPADD,F		;
			BTFSS	F_Carry			;Carry flag?
			GOTO	_ADDR_1			;
			BSF		PDATA			;
			GOTO	$+2				;
_ADDR_1		BCF		PDATA			;
									;
			NOP						;
			BCF		PCLK			;trigger pdata on negative edge of PCLK
			DECFSZ	L_BITCOU_S,F	;
			GOTO	_ADDR_0			;Loop 7 bits
			RETURN					;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Procedure:	Setup_CC1000PD
;Function:	Power down CC1000
;		Use WakeUpCC1000RX/TX followed by SetupCC1000RX/TX to wake from power down
;Inputs:	None
;Returns:	Nothing
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Setup_CC1000PD
			global	Setup_CC1000PD;
			MOVLW	CC1000_MAIN		;
			MOVWF	G_CC_Reg		;
			MOVLW	0x3F			;
			MOVWF	G_CC_Data		;
			CALL	WriteToCC1000register;Setup CC1000
									;
			MOVLW	CC1000_PA_POW	;Clear PA_POW settings
			MOVWF	G_CC_Reg		;
			CLRF	G_CC_Data		;Turn off PA_POW
			CALL	WriteToCC1000register;
			RETURN					;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Procedure:	Reset_CC1000
;Function:	Reset CC1000
;Inputs:	None
;Returns:	Nothing
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Reset_CC1000
			global	Reset_CC1000	;
			MOVLW	CC1000_MAIN		;
			MOVWF	G_CC_Reg		;
			CALL	ReadFromCC1000register;Save current settings from MAIN
									;
			MOVLW	CC1000_MAIN		;
			MOVWF	G_CC_Reg		;
			MOVLW	b'11111110'		;xx111110 - (1s pwr dwn everything,0 resets regs)(A)
			ANDWF	G_CC_Data,F		;Reset CC1000
			CALL	WriteToCC1000register;
									;
			MOVLW	1				;
			IORWF	G_CC_Data,F		;Restore MAIN and bring CC1000 out of Reset 
			CALL	WriteToCC1000register; (Fig 16, pg 26 --> (B))
			MOVLW	2				;Delay 2 Ms  (C)
			CALL	DelaymS			;
			RETURN					;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Procedure:	Setup_CC1000All
;Function:	Loops through the values of the 28 register of the CC1000, values are
;           passed in W
;Inputs:	(W)-> CC1000 registers
;Returns:	Nothing
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Setup_CC1000All
			global 	Setup_CC1000All
			CLRF	L_SUP_REG		;(Fig 16, pg 26 --> (C))
_SETUP		INCF	L_SUP_REG,F		;
			MOVLW	HIGH GET_NEXT_REGISTER	;
			MOVWF	PCLATH			;
			MOVF	L_SUP_REG,W		;
			CALL	GET_NEXT_REGISTER;
									;
			MOVWF	G_CC_Data		;
			MOVF	L_SUP_REG,W		;
			MOVWF	G_CC_Reg		;
			CALL	WriteToCC1000register;
			MOVLW	d'28'			;
			SUBWF	L_SUP_REG,W		;			
			BTFSS	STATUS,Z		;zero flag set when 0 (EQ)
			GOTO	_SETUP			;
			RETURN					;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Procedure: WakeUpCC1000toRx
;Function:	Turn on CC1000 from power down to Rx
;Inputs:	W = RX_CURRENT
;Returns:	Nothing
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
WakeUpCC1000toRx
			global 	WakeUpCC1000toRx
			MOVWF	L_RX_CUR			;save
			MOVLW	CC1000_MAIN			;Start CC1000 as receiver:
			MOVWF	G_CC_Reg			;
			MOVLW	b'00111011'			;<7>:rx,<6>:reg A,<2>:Power up xtal osc core
			MOVWF	G_CC_Data			;
			CALL	WriteToCC1000register;
										;
			MOVLW	CC1000_CURRENT		;
			MOVWF	G_CC_Reg			;
			MOVF	L_RX_CUR,W			;
			MOVWF	G_CC_Data			;
			CALL	WriteToCC1000register;
										;
			MOVLW	CC1000_PLL			;
			MOVWF	G_CC_Reg			;
			MOVLW	RXPLL				;
			MOVWF	G_CC_Data			;
			CALL	WriteToCC1000register;
										;
			MOVLW	5					;Delay 5 Ms
			CALL	DelaymS				;
										;
			MOVLW	CC1000_MAIN			;Start CC1000 as receiver:
			MOVWF	G_CC_Reg			;
			MOVLW	b'00111001'			;Power up bias generator
			MOVWF	G_CC_Data			;
			CALL	WriteToCC1000register;
										;
			MOVLW	d'250'				;
			CALL	DelayuS				;
										;
			MOVLW	CC1000_MAIN			;
			MOVWF	G_CC_Reg			;
			MOVLW	b'00110001'			;Power up frequency synthesiser
			MOVWF	G_CC_Data			;
			CALL	WriteToCC1000register;
										;
			@DIOIN						;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Procedure: WakeUpCC1000toTx
;Function:	Turn on CC1000 from power down to Tx
;Inputs:	W = TX_CURRENT
;Returns:	Nothing
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
WakeUpCC1000toTx
			global 	WakeUpCC1000toTx
			MOVWF	L_TX_CUR			;save
			MOVLW	CC1000_MAIN			;Start CC1000 as receiver:
			MOVWF	G_CC_Reg			;
			MOVLW	b'11111011'			;<7>:rx,<6>:reg A,<2>:Power up xtal osc core
			MOVWF	G_CC_Data			;
			CALL	WriteToCC1000register;
										;
			MOVLW	CC1000_CURRENT		;
			MOVWF	G_CC_Reg			;
			MOVF	L_TX_CUR,W			;
			MOVWF	G_CC_Data			;
			CALL	WriteToCC1000register;
										;
			MOVLW	CC1000_PLL			;
			MOVWF	G_CC_Reg			;
			MOVLW	TXPLL				;
			MOVWF	G_CC_Data			;
			CALL	WriteToCC1000register;
										;
			MOVLW	d'5'				;
			CALL	DelaymS				;
										;
			MOVLW	CC1000_MAIN			;
			MOVWF	G_CC_Reg			;
			MOVLW	b'11111001'			;Turn on bias generator
			MOVWF	G_CC_Data			;
			CALL	WriteToCC1000register;
										;
			MOVLW	d'250'				;
			CALL	DelayuS				;
										;
										;
			MOVLW	CC1000_PA_POW		;Restore PA_POW settings
			MOVWF	G_CC_Reg			;
			MOVLW	PA_VALUE			;
			MOVWF	G_CC_Data			;
			CALL	WriteToCC1000register;
										;
			MOVLW	CC1000_MAIN			;
			MOVWF	G_CC_Reg			;
			MOVLW	b'11110001'			;Turn on freq synthesiser
			MOVWF	G_CC_Data			;
			CALL	WriteToCC1000register;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Procedure: SetupCC1000Rx
;Function:	Go to Rx mode Freq A
;Inputs:	W = RX_CURRENT
;Returns:	Nothing
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SetupCC1000Rx
			global 	SetupCC1000Rx
			MOVWF	L_RX_CUR			;save
			MOVLW	CC1000_MAIN			;Power up RX part
			MOVWF	G_CC_Reg			;
			MOVLW	b'00010001'			;<7>:rx,<6>:reg A,
			MOVWF	G_CC_Data			;  <5,4>:Power down TX
			CALL	WriteToCC1000register;
										;
			MOVLW	CC1000_PLL			;
			MOVWF	G_CC_Reg			;
			MOVLW	RXPLL				;
			MOVWF	G_CC_Data			;
			CALL	WriteToCC1000register;
										;
			MOVLW	CC1000_CURRENT		;
			MOVWF	G_CC_Reg			;
			MOVF	L_RX_CUR,W			;
			MOVWF	G_CC_Data			;
			CALL	WriteToCC1000register;
										;
			MOVLW	d'2'				;
			CALL	Delay100uS			;
			MOVLW	d'50'				;
			CALL	DelayuS				;

			MOVLW	LOCK1				;
			MOVWF	L_TIMEOUT1			;
			MOVLW	LOCK2				;
			MOVWF	L_TIMEOUT2			;
										;
_WAIT_RX_LK	MOVLW	CC1000_LOCK			;
			MOVWF	G_CC_Reg			;
			CALL	ReadFromCC1000register;
			BTFSC	G_CC_Data,0			; Wait till PLL lock complete
			GOTO	_CONT_1R			;
			DECFSZ	L_TIMEOUT1,F		;
			GOTO	_WAIT_RX_LK			;
			DECFSZ	L_TIMEOUT2,F		;
			GOTO	_WAIT_RX_LK			;
										;
			CALL	CalibrateCC1000		;
			BTFSS	CALIBRATION_OK		;PLL not in lock, re-calibrate
			CALL	TREAT_ERROR			;
										;
_CONT_1R	NOP							;
			@DIOIN						;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Procedure: SetupCC1000Tx
;Function:	Go to Tx mode Freq B
;Inputs:	(W)-> TX_CURRENT
;Returns:	Nothing
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SetupCC1000Tx
			global 	SetupCC1000Tx
			MOVWF	L_TX_CUR			;save
			MOVLW	CC1000_PA_POW		;Turn off PA_POW settings
			MOVWF	G_CC_Reg			;
			CLRF	G_CC_Data			;Turn off PA_POW to avoid spurs
			CALL	WriteToCC1000register;


			MOVLW	CC1000_MAIN			;Power up TX part
			MOVWF	G_CC_Reg			;
			MOVLW	b'11100001'			;<7>:tx,<6>:reg B,<5>:Power down RX
			MOVWF	G_CC_Data			;
			CALL	WriteToCC1000register;

			MOVLW	CC1000_PLL			;
			MOVWF	G_CC_Reg			;
			MOVLW	TXPLL				;(0X48)
			MOVWF	G_CC_Data			;
			CALL	WriteToCC1000register;
										;
			MOVLW	CC1000_CURRENT		;
			MOVWF	G_CC_Reg			;
			MOVF	L_TX_CUR,W			;
			MOVWF	G_CC_Data			;
			CALL	WriteToCC1000register;
										;
			MOVLW	d'2'				;
			CALL	Delay100uS			;
			MOVLW	d'50'				;
			CALL	DelayuS				;
										;
			MOVLW	LOCK1				;
			MOVWF	L_TIMEOUT1			;
			MOVLW	LOCK2				;
			MOVWF	L_TIMEOUT2			;
_WAIT_TX_LK	MOVLW	CC1000_LOCK			;
			MOVWF	G_CC_Reg			;
			CALL	ReadFromCC1000register;
			BTFSC	G_CC_Data,0			; Wait till PLL lock complete
			GOTO	_CONT_1T			;
			DECFSZ	L_TIMEOUT1,F		;
			GOTO	_WAIT_TX_LK			;
			DECFSZ	L_TIMEOUT2,F		;
			GOTO	_WAIT_TX_LK			;
										;
			CALL	CalibrateCC1000		;
			BTFSS	CALIBRATION_OK		; PLL not in lock, recalibrate
			CALL	TREAT_ERROR			;
										;
_CONT_1T	MOVLW	CC1000_PA_POW		;Restore PA_POW settings
			MOVWF	G_CC_Reg			;
			MOVLW	PA_VALUE			;
			MOVWF	G_CC_Data			;
			CALL	WriteToCC1000register;
										;
			@DIOOUT						;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Procedure: CalibrateCC1000 
;  *** This is different than the single OR dual calibrations (Fig.14,15 page 23,24)
;  *** Should it be different for RX and TX - we are doing 2 calibrations...
;Function:	
;Inputs:	None
;Returns:	Nothing
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CalibrateCC1000 
			global 	CalibrateCC1000
			MOVLW	CC1000_PA_POW		;Clear PA_POW settings
			MOVWF	G_CC_Reg			;
			CLRF	G_CC_Data			;Turn off PA_POW to avoid spurs
			CALL	WriteToCC1000register;
										;
			MOVLW	CC1000_CAL			;Start calibration
			MOVWF	G_CC_Reg			;
			MOVLW	b'10100110'			;&& WAS A5!!	
			MOVWF	G_CC_Data			;
			CALL	WriteToCC1000register;
										;
			MOVLW	CC1000_CAL			;
			MOVWF	G_CC_Reg			;
_WAIT_CAL	CALL	ReadFromCC1000register;
			BTFSS	G_CC_Data,3			; Wait till calibration complete
			GOTO	_WAIT_CAL			;
										;
			MOVLW	LOCK1+1				;(+1 accounts for initial decrement)
			MOVWF	L_TIMEOUT1			;
			MOVLW	LOCK2				;
			MOVWF	L_TIMEOUT2			;
_WAI_CAL_LK	MOVLW	CC1000_LOCK			;
			MOVWF	G_CC_Reg			;
			CALL	ReadFromCC1000register;
			BTFSC	G_CC_Data,0			; Wait till PLL lock complete
			GOTO	_CONT_CAL			;
			DECFSZ	L_TIMEOUT1,F		;
			GOTO	_WAI_CAL_LK			;
			DECFSZ	L_TIMEOUT2,F		;
			GOTO	_WAI_CAL_LK			;
			BTFSC	G_CC_Data,0			; Wait till PLL lock complete
			GOTO	_CONT_CAL			;
										;
			CALL	TREAT_ERROR			;Calibartion failed
			BCF		CALIBRATION_OK		;
			GOTO	_CONT_CALE			;
										;
_CONT_CAL	BSF		CALIBRATION_OK		;Indicate calibration successful
_CONT_CALE	MOVLW	CC1000_CAL			;
			MOVWF	G_CC_Reg			;
			MOVLW	b'00100110'			;End calibration
			MOVWF	G_CC_Data			;
			CALL	WriteToCC1000register;
										;
			MOVLW	CC1000_PA_POW		;Restore PA_POW settings
			MOVWF	G_CC_Reg			;
			MOVLW	PA_VALUE			;
			MOVWF	G_CC_Data			;
			CALL	WriteToCC1000register;
			RETURN						;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			END							; end of code
	
