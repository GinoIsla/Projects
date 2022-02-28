
;
;Pin usage definitions for the GMB ECHO BUS and other ports
#define	OFF						0
#define	ON						1
#define	FALSE					0
#define	TRUE					1
;
;Heartbeat
#define	C_TIMER1_H				0x100-0x04	;1200 TICKS for 1ms
#define	C_TIMER1_L				0x100-0xB0	;1200 TICKS
;Delays
#define	C_TEN_MS				10		;
#define	C_TWENTYFIVE_MS			25		;not used
#define	C_FIFTY_MS				50		;not used
#define	C_HUNDRED_MS			100		;basic THRESHOLD resduced timers
#define	C_ONESECOND				10		;based on 100ms tmr
#define	C_ONEMINUTE				60		;not used
;Periodic jobs
#define	C_RX_TIMER				 5		;RX queus emptied every 5ms
#define	C_RXTIME				0xF0	;message RE-tranmission counter (15 in high nibble) 
#define	C_TX_TIMER				15		;TX queus emptied every 15ms
#define	C_SAMPLE_SCAN			10		;4 samples of analogue data each second (based on 1ms)
;										;(has 2 multipliers!)
;Dimmer timers
#define	C_DIM_STP_TIM			20		;20ms granules
#define	C_DIMMER_ACTION			1		;based on C_DIM_STP_TIM, one dimmer step = 20ms
#define C_ON_OFF_WAIT			24		;based on C_DIM_STP_TIM, wait 240ms for ON/OFF msg 

#define C_SFTY_DIM_STOP			30		;(*1sec)Turn off dimming autonomously if no OFF  
;
;Funzioni Ingresso
#define	C_IN_NOT_USED			0
#define	C_IN_STEP_WATCH			1		;Also referred to as FUNCTION A
#define	C_IN_THRHLD_WATCH		2		;Also referred to as FUNCTION B
;
;Funzione Uscita
#define	C_OUT_NOT_USED			0
#define	C_OUT_LISTEN_OWN		1
#define	C_OUT_LISTEN_OTHR		2
#define	C_OUT_DIMMER			3
;
;clock 4MHz
;#define C_BIT_0				91		;Duration (in clock ticks) of a '0' byte
;#define C_BIT_1				63		;Duration (in clock ticks) of a '1' byte
;#define C_BIT_SUP				120		;Max limit of of a bit during reception/transmission

;clock 8MHz
#define	C_BIT_0					182		;Duration (in clock ticks) of a '0' byte
#define	C_BIT_1					126		;Duration (in clock ticks) of a '1' byte
#define	C_BIT_SUP				240		;Max limit of of a bit during reception/transmission

#define BUS_IN					PORTA,2
#define BUS_OUT					PORTC,4
;#define KEY_IN					PORTB,2
;#define MULTIKEY				PORTA,5
;
;EEPROM ADDRESSES
EE_FUNZIONE_ING					EQU	0	;(X2)DEFAULT 0
EE_FUNZIONE_USCITA				EQU	2	;(X2)DEFAULT=0
EE_TEMPO_INVIO					EQU	4	;(X2)DEFAULT 0 = not active
EE_STEP_FUNZ_A					EQU	6	;(X2)DEFAULT 0 = not active
EE_TEMPO_ATTIVAZIONE			EQU	8	;(X2) - NOT USED
EE_SOGLIE_FUNZ_B0_UP			EQU	10	;(X8) PORT 0 - UP
EE_SOGLIE_FUNZ_B0_DWN			EQU	18	;(X8) PORT 0 - DOWN
EE_SOGLIE_FUNZ_B1_UP			EQU	26	;(X8) PORT 1 - UP
EE_SOGLIE_FUNZ_B1_DWN			EQU	34	;(X8) PORT 1 - DOWN
EE_TIPO_SCHEDA					EQU	42	;*** DONT MOVE DEFAULT = 3 = ANALOGUE 
EE_SW_VERSION					EQU	43	;*** DONT MOVE DEFAULT = 1
EE_SERIAL_ASCOLTO				EQU	44	;DEFAULT 0
EE_PORT_ASCOLTO					EQU	46	;(X2)
EE_SERIAL_NBR					EQU	48	;*** DONT MOVE DEFAULT = 254 (-2)
EE_STEP_BACK					EQU	49	;(X1) 
EE_SAMPLE_TIMER					EQU	50	;(X2) multipliers (*10ms => *4 for an AVG)
EE_MESSAGE_0_UP					EQU	52	;(X40) 5 byte message (S/N, DISC, ARGOM)
EE_MESSAGE_0_DWN				EQU	92	;(X40) 5 byte message (S/N, DISC, ARGOM)
EE_MESSAGE_1_UP					EQU	132	;(X40) 5 byte message (S/N, DISC, ARGOM)
EE_MESSAGE_1_DWN				EQU	172	;(X40) 5 byte message (S/N, DISC, ARGOM)
EE_SAVED_SAMPLE					EQU	212	;(X2) reserved for saved samples across restarts
EE_SAVED_OUTPUT					EQU	214	;(X2)
EE_SAVED_CURSOR					EQU	216	;(X2)
EE_DIMM_TOGGLE					EQU	218	;(X2)
EE_DIM_DRCTN_STAT				EQU	220	;(X2)
;
;Protocol elements
#define	C_NBR_PROTOCOL_BYTES 		6	;TYPE, SUB-TYPE, SERIAL, DISCRIMINATOR, ARGUMENT, SUMCHECK
;
;---------------------------------------------------------
#define	C_SIZE_RX_Q_ENTRY			5	;only message data, no CS
#define	C_NBR_ENTRIES_RX			6	;Total size of RX_QUE = 30
;---------------------------------------------------------
;	Structure of the RX_QUEU:
;	byte0 ... byte4 identical to the protocol messages
;	minus the check sum since we don`t store it
;---------------------------------------------------------
#define	C_SIZE_TX_Q_ENTRY			8	;includes the expiration, CS and key_to_port
#define	C_NBR_ENTRIES_TX			6	;multicomms have to be process one by one
;---------------------------------------------------------
;	Structure of the TX_QUEU:
;	byte0 = expiraion counter (0=repeats expired)
;	byte1...byte5 = protocol bytes
;	byte6 = checksum
;	byte7 = key/port (ingresso/uscita) assignment
#define	TX_EXPIRATION				0
#define	TX_MSGTYPE					1
#define	TX_MSGSUBTYPE				2
#define	TX_SERIAL					3
#define	TX_DISCRMINATOR				4
#define	TX_ARGUMENT					5
#define	TX_SUMCHECK					6
#define	TX_IN_OUT_KEY				7		;used for visualizzazione
;---------------------------------------------------------
;										;size of TX_QUE = 49
;
#define	C_NO_RETRY					1	;No retries
#define	C_MAX_RETRIES				5	;Retries commands 85,[16|128|34],....
;
;digital messages
#define	TYPE_PROGRAMMAZIONE			170
#define	TYPE_RISPOSTA				51
#define	TYPE_INTERROG_PROGR			119
#define	TYPE_FUNZIONAMENTO			85
;analogue messages
#define	TYPE_INVIO_STATO			180
#define	TYPE_INTERROG_STAT			181
#define	TYPE_RISPOSTA_STAT			182
#define	TYPE_IMPOSTAZIONE_USCITA	183
;
#define	SUBT_INVIO_MODULO			 16
#define	SUBT_INVIO_ZONA				 17		;nuovo commando verso ZONA
#define	SUBT_RISPO_MODULO			  0
#define	SUBT_RISP_S_R				  7
#define	SUBT_INVIO_CPU				 34
#define	SUBT_RISPO_CPU				  2
#define	SUBT_ALLARME_C				128
#define	SUBT_RISPO_C				 70
;
#define	SUBT_RICH_CPU				 33
#define	SUBT_RISTAT_CPU				  1

;Tipo Programma
#define	INGRESSO_USCITA		 		 15
#define	INGRESSO_VISUAL				240
#define	ING_USC_RC					 51
;
;Fuzione
#define	NON_USATA					 0
#define	MONOSTABILE					 3
#define	INVERTITORE					12
#define	PASSOPASSO					48
#define	TAPPARELLA					51
;#define SETRESET		   			192  - NOT USED
#define	TEMPORIZZATA	   			204
#define	VISUALIZZAZIONE				240
;
;Tipo messagio
#define	C_NORMALE					0
#define	C_SET						1
#define	C_RESET						2
#define	C_ALLARME					3
