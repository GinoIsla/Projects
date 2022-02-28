
;J_LIBRAM	E 500

;PROTOCOLLO DI COMUNICAZIONE PER EEPROM A INDIRIZZO FINO A 8 BIT

;	CBLOCK	0x60

;ADDRESS
;EE_ADDR
;EE_DATA
;TMP2
;TMP1
;COUNTER
;PC_OFFSET
;EEBYTE

;	ENDC

EE_OK	EQU	.7


;#DEFINE	EEsda	EEDATA	; EEPROM DATA LINE FOR 24xxxx
;#DEFINE	EEscl	EECLOCK	; EEPROM SERIAL CLOCK FOR 24xxxx	

#DEFINE	T_SDA	TRISC,6
#DEFINE	T_SCL	TRISC,7 

;===========================================================================
;
; FUNCTION     	: EEREAD	      			
;
; DESCRIPTION  	: READ 2 CONSECUTIVE BYTE IN EEPROM 
;
; NOTE		: IN
;			ADDRESS (& ADDRESS+1)
;			, OUT-TEMP1 & TEMP2
;
;===========================================================================
EEREAD	CLRWDT
	MOVF	ADDRESS, W
	MOVWF	EE_ADDR
	CALL	READ_RANDOM
	MOVF	EE_DATA, W
	MOVWF	TMP1
	INCF	ADDRESS, F
;	INCF	EE_ADDR, F
;	CALL	READ_RANDOM
	CALL	READ_CURRENT
	MOVF	EE_DATA, W
	MOVWF	TMP2
	RETURN


;===========================================================================
;
; FUNCTION     	: EEWRITE()	      			
;
; DESCRIPTION  	: WRITE 2 CONSECUTIVE BYTE IN EEPROM 
;
; NOTE		: IN-
;			ADDRESS (& ADDRESS+1)
;			TEMP1 & TEMP2
;
;===========================================================================
EEWRITE	CLRWDT
	MOVF	ADDRESS,W
	MOVWF	EE_ADDR
	MOVF	TMP1, W
	MOVWF	EE_DATA


EEW1	CALL	WRITE_BYTE
	BTFSS	PC_OFFSET,EE_OK
	GOTO	EEW1

	CLRWDT
	INCF	ADDRESS, F
	INCF	EE_ADDR, F
	MOVF	TMP2, W
	MOVWF	EE_DATA


EEW2	CALL	WRITE_BYTE
	BTFSS	PC_OFFSET,EE_OK
	GOTO	EEW2

	INCF	ADDRESS, F

	RETURN


;***************************************************************************
;*********************  EEPROM READ & WRITE Subroutines  *******************
;***************************************************************************
; Communication for EEPROM based on I2C protocall, with Acknowledge.
;
; Byte_Write: Byte write routine
;       Inputs:  EEPROM Address  EE_ADDR
;                EEPROM Data      EE_DATA
;       Outputs: Return 01 in W if OK, else return 00 in W
;
; Read_Current: Read EEPROM at address currently held by EE device. 
;       Inputs:  NONE
;       Outputs: EEPROM Data       EE_DATA
;                Return 01 in W if OK, else return 00 in W
;
; Read_Random: Read EEPROM byte at supplied address
;       Inputs:  EEPROM Address   EE_ADDR
;       Outputs: EEPROM Data       EE_DATA
;                Return 01 in W if OK, else return 00 in W
;
; Note: EEPROM subroutines will set bit 7 in PC_OFFSET register if the
;       EEPROM acknowledged OK, else that bit will be cleared.  This bit 
;       can be checked instead of refering to the value returned in W
;***************************************************************************

;********************** Set up EEPROM control bytes ************************
;***************************************************************************

READ_CURRENT
	RAM1			; SDA and SCL = output
	BCF	T_SDA
	BCF	T_SCL
	RAM0

	BSF     EEscl		; Initalize SCL and SDA to '1'
	BSF     EEsda
	MOVLW   B'10000100'	; PC offset for read current addr. EE_OK bit7='1'
	MOVWF   PC_OFFSET	; Load PC offset
	GOTO    INIT_READ_CONTROL


WRITE_BYTE
	RAM1			; SDA and SCL = output
	BCF	T_SDA
	BCF	T_SCL
	RAM0

	BSF     EEscl		; Initalize SCL and SDA to '1'
	BSF     EEsda
	MOVLW   B'10000000'	; PC offset for write byte.  EE_OK: bit7 = '1'
	GOTO    INIT_WRITE_CONTROL


READ_RANDOM
	RAM1			; SDA and SCL = output
	BCF	T_SDA
	BCF	T_SCL
	RAM0

	BSF     EEscl		; Initalize SCL and SDA to '1'
	BSF     EEsda
	MOVLW   B'10000011'	; PC offset for read random.  EE_OK: bit7 = '1'


INIT_WRITE_CONTROL
	MOVWF   PC_OFFSET	; Load PC offset register, value preset in W
	MOVLW   B'10100000'	; Control byte with write bit, bit 0 = '0'


START_BIT
	BCF     EEsda		; Start bit, SDA and SCL preset to '1'


;******* Set up output data (control, address, or data) and counter ********
;***************************************************************************
PREP_TRANSFER_BYTE
	MOVWF   EEBYTE		; Byte to transfer to EEPROM already in W

	RAM1			; SDA and SCL set to output
	BCF	T_SDA
	BCF	T_SCL
	RAM0

	MOVLW   .8		; Counter to transfer 8 bits
	MOVWF   COUNTER


;************  Clock out data (control, address, or data) byte  ************
;***************************************************************************
OUTPUT_BYTE
	BCF     EEscl		; Set clock low during data set-up
	RLF     EEBYTE,F	; Rotate left, high order bit into carry bit
	BCF     EEsda		; Set data low, if rotated carry bit is
	SKPNC			;   a '1', then:
	BSF     EEsda		; reset data pin to a one, otherwise leave low

	BSF     EEscl		; clock data into EEPROM
	DECFSZ  COUNTER,F	; Repeat until entire byte is sent
	GOTO    OUTPUT_BYTE


;**************************  Acknowkedge Check *****************************
;***************************************************************************
	RAM1			; SDA = input, SCL = output
	SKPC			; if SDA = 1 then tristate port to allow
	GOTO	AC1		;   pullup to hold '1', avoiding bus contention

	BSF	T_SDA		;   if EEPROM acks in < 1us after clock goes low
	BCF	T_SCL


AC1	RAM0			
	BCF     EEscl		; Set SCL low, 0.5us < ack valid < 3us

	RAM1			; SDA = input, SCL = output
	BSF	T_SDA		; If SDA='0' wait until SCL is low to set SDA to
	BCF	T_SCL		;  input. If done above, could have sent STOP bit
	RAM0

	;NOP                   	; May be necessary for SCL Tlow  at low voltage,
			  	;  also give resistor time to pull up bus if last 
				;  bit written='0' and there is no ack from slave
	BSF     EEscl		; Raise SCL, EEPROM acknowledge still valid
	BTFSC   EEsda		; Check SDA for acknowledge (low)
	BCF     PC_OFFSET,EE_OK	; If SDA not low (no ack), set error flag

	BCF     EEscl		; Lower SCL, EEPROM release bus
	BTFSS   PC_OFFSET,EE_OK	; If no error continue, else stop bit
	GOTO    STOP_BIT


;*****  Set up program counter offset, based on EEPROM operating mode  *****
;***************************************************************************
	movlw   HIGH	TAB_EE
	movwf   PCLATH
;	ORG	0x300
	MOVF    PC_OFFSET,W
	ANDLW   B'00001111'
TAB_EE	ADDWF   PCL, F
	GOTO    INIT_ADDRESS	;PC offset=0, write control done, send address
	GOTO    INIT_WRITE_DATA	;PC offset=1, write address done, send data
	GOTO    STOP_BIT	;PC offset=2, write done, send stop bit
	GOTO    INIT_ADDRESS	;PC offset=3, write control done, send address
	GOTO    INIT_READ_CONTROL;PC offset=4, send read control
	GOTO    READ_BIT_COUNTER;PC offset=5, set counter and read byte
TAB_EE_X
	GOTO    STOP_BIT	;PC offset=6, random read done, send stop


	IF HIGH (TAB_EE) != HIGH (TAB_EE_X)
	ERROR "TAB_EE: OVERFLOW del PCL"
	ENDIF


;**********  Initalize EEPROM data (address, data, or control) bytes  ******
;***************************************************************************
INIT_ADDRESS
	INCF    PC_OFFSET, F	; Increment PC offset to 2 (write) or to 4 (read)
	MOVF	EE_ADDR,W	; Put EEPROM addr. in W, ready to send to EEPROM
	GOTO    PREP_TRANSFER_BYTE


INIT_WRITE_DATA
	INCF    PC_OFFSET, F	; Increment PC offset to go to STOP_BIT next
	MOVF    EE_DATA,W	; Put EEPROM data in W, ready to send to EEPROM
	GOTO    PREP_TRANSFER_BYTE


INIT_READ_CONTROL
	BSF     EEscl		; Raise SCL
	INCF    PC_OFFSET, F	; Incr. PC offset to go to READ_BIT_COUNTER next
	MOVLW   B'10100001'	; Set up read control byte,ready to sendto EEPROM
	GOTO    START_BIT	;   bit 0 = '1' for read operation


;**************************  Read EEPROM data  *****************************
;***************************************************************************
READ_BIT_COUNTER
	MOVLW   .8		; Set counter so 8 bits will be read into EE_DATA
	MOVWF   COUNTER


READ_BYTE
	BSF     EEscl		; Raise SCL, SDA valid.  SDA still input from ack
	SETC			; Assume bit to be read = 1
	BTFSS   EEsda		; Check if SDA = 1
	CLRC			; if SDA not = 1 then clear carry bit

	RLF     EE_DATA, F	; rotate carry bit (=SDA) into EE_DATA;
	BCF     EEscl		; Lower SCL
	DECFSZ  COUNTER, F	; Decrement counter
	GOTO    READ_BYTE	; Read next bit if not finished reading byte


;******************  Generate a STOP bit and RETURN  ***********************
;***************************************************************************
STOP_BIT
	BCF     EEsda		; SDA=0, on TRIS,to prepare for transition to '1' 

	RAM1
	BCF	T_SDA		; SDA and SCL set to output
	BCF	T_SCL
	RAM0

	BSF     EEscl		; SCL = 1 to prepare for STOP bit
	;NOP			; 4 NOPs neccessary for I2C spec Tsu:sto = 4.7us                  
	;nop
	;nop
	;nop
	BSF     EEsda		; Stop bit, SDA transition to '1' while SCL high

	RETURN


    ;Note: SDA and SCL still being driven by master, both set to outputs.
;****************************************************************************
;************************  End EEPROM Subroutines  **************************
;****************************************************************************
