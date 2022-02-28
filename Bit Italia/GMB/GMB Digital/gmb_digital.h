
	ifdef	IN_9_OUT_8
#define	C_NBR_OF_KEYS			8
#define	C_NBR_OF_PORTS			8
#define	C_MAXBIT				3	;2**3 bit for port counting
	else
#define	C_NBR_OF_KEYS			4
#define	C_NBR_OF_PORTS			4
#define	C_MAXBIT				2	;2**2 bit for port counting
	endif
;
;Pin usage definitions for the GMB ECHO BUS and other ports
#define	OFF						0
#define	ON						1
#define	FALSE					0
#define	TRUE					1

#define	C_TIMER1_H				0x100-0x04	;1200 TICKS for 1ms
#define	C_TIMER1_L				0x100-0xB0	;1200 TICKS

#define	C_RX_TIMER				 5		;RX queus emptied every 5ms
#define	C_TX_TIMER				15		;TX queus emptied every 15ms
#define	C_TWENTYFIVEMS			25		;not used
#define	C_FIFTY_MS				50		;ALL SCHEDULED JOBS DELAY
#define	C_SEVENTY_MS			70		;KEY SCAN TIMER
#define	C_HUNDRED_MS			100		;
#define	C_ONESECOND				20		;LONG TIMER (TEMPORIZZATA, TAPPARELLA) based on 50ms tmr
#define	C_ONEMINUTE				60		;scan time based on 1 seconds timer
#define	C_RXTIME				0xF0	;(=15 in high nibble) message retranmission counter  
;
#define	C_BIT_0					91		;Duration (in clock ticks) of a '0' byte
#define	C_BIT_1					63		;Duration (in clock ticks) of a '1' byte
#define	C_BIT_SUP				120		;Max limit of of a bit during reception/transmission

#define BUS_IN					PORTB,0
#define BUS_OUT					PORTB,1
#define	KEY_IN					PORTB,2
#define	MULTIKEY				PORTA,5
;
;EEPROM ADDRESSES
EE_MULTK_KEY_TIPO		EQU		33	;(33...40)tipo messaggio for MULTIKEY commands
EE_STATO_USCITE			EQU		41	;save area for port states
EE_TIPO_SCHEDA			EQU		42	;new, read only
EE_SW_VERSION			EQU		43	;new, read only
EE_RIT_USCITA			EQU		44	;new, delay activation of ports in the same zone
EE_RIT_SCHEDA			EQU		45	;new, delay activation of a scheda during zone command
EE_RIT_MULTIC			EQU		46	;new, delay in sending multiple commands
EE_POLARITA				EQU		47	;new, polarity of the port
;
EE_SERIAL_NBR			EQU		48	;serial number
EE_PROGRAM_TYPE			EQU		49	;program type
EE_SCHEDA				EQU		50	;ingressi (ingresso 1..8)
EE_USCITA_ZONA			EQU		58	;locazioni (ingresso 1..8)
EE_USCITA_PORTA			EQU		66	;numerazione assegnata alla uscita (uscita 1..8)
EE_FUNZIONE				EQU		74	;funzione (uscita 1..8)
EE_TEMPO				EQU		82	;temporizzazione (uscita 1..8)
EE_MULT_SCHEDA			EQU		90	;schede da comandare in multicomando
EE_MULT_USCITA			EQU		98	;uscite da comandare in multicomando
EE_ZONA_APPARTZA		EQU		106	;zone 
EE_SGL_KEY_TIPO			EQU		114	;tipo messaggio for SINGLE KEY commands
;
;Protocol elements
#define	C_NBR_PROTOCOL_BYTES 	6	;TYPE, SUB-TYPE, SERIAL, DISCRIMINATOR, ARGUMENT, SUMCHECK
;
;---------------------------------------------------------
#define	C_SIZE_RX_Q_ENTRY		5		;only message data, no CS
#define	C_NBR_ENTRIES_RX		6		;Total size of RX_QUE = 30
;---------------------------------------------------------
;	Structure of the RX_QUEU:
;	byte0 ... byte4 identical to the protocol messages
;	minus the check sum since we don`t store it
;---------------------------------------------------------
#define	C_SIZE_TX_Q_ENTRY		8		;includes the expiration, CS and key_to_port
#define	C_NBR_ENTRIES_TX		6		;multicomms have to be process one by one
;---------------------------------------------------------
;	Structure of the TX_QUEU:
;	byte0 = expiraion counter (0=repeats expired)
;	byte1...byte5 = protocol bytes
;	byte6 = checksum
;	byte7 = key/port (ingresso/uscita) assignment
#define	TX_EXPIRATION			0
#define	TX_MSGTYPE				1
#define	TX_MSGSUBTYPE			2
#define	TX_SERIAL				3
#define	TX_DISCRMINATOR			4
#define	TX_ARGUMENT				5
#define	TX_SUMCHECK				6
#define	TX_IN_OUT_KEY			7		;used for visualizzazione
;---------------------------------------------------------
;										;size of TX_QUE = 49
;
#define	MAX_SINGLE_RETRIES		5		;Number of retries on single commands before giving up
#define	MAX_MULTI_RETRIES		3		;Number of retries on multiple commands before giving up
#define	MAX_ZONE_RETRIES		1		;No retries for zone commands
;
#define	TYPE_PROGRAMMAZIONE		170
#define	TYPE_RISPOSTA			 51
#define	TYPE_INTERROGAZIONE		119
#define	TYPE_FUNZIONAMENTO		 85
;
#define	SUBT_INVIO_MODULO		 16
#define	SUBT_INVIO_ZONA			 17		;nuovo commando verso ZONA
#define	SUBT_RISPO_MODULO		  0
#define	SUBT_RISP_S_R			  7
#define	SUBT_INVIO_CPU			 34
#define	SUBT_RISPO_CPU			  2
#define	SUBT_ALLARME_C			128
#define	SUBT_RISPO_C			 70
;
#define	SUBT_RICH_CPU			 33
#define	SUBT_RISTAT_CPU			  1

;Tipo Programma
#define	INGRESSO_USCITA		 	 15
#define	INGRESSO_VISUAL			240
#define	ING_USC_RC				 51
;
;Fuzione
#define	NON_USATA				 0
#define	MONOSTABILE				 3
#define	INVERTITORE				12
#define	PASSOPASSO				48
#define	TAPPARELLA				51
;#define SETRESET		   		192  - NOT USED
#define	TEMPORIZZATA	   		204
#define	VISUALIZZAZIONE			240
;
;Tipo messagio
#define	C_NORMALE				0
#define	C_SET					1
#define	C_RESET					2
#define	C_ALLARME				3
