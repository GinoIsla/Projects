;Pin usage definitions for the rover Master/Tranmitter
;CC1000 and PIC16f76
;
;===========================================================
;CHANGE THESE DEFINITIONS WHEN COMPILING THE ASM CODE OR THE
;LIBRARY FOR MASTER OR FOR SLAVE 
#define		TX_MASTER
;#define		RX_SLAVE
;===========================================================

	ifdef	TX_MASTER
#define PCLK			PORTC,1	;
#define PALE			PORTC,2	;
	else
#define PCLK			PORTA,2	;
#define PALE			PORTA,1	;
	endif

#define PDATA			PORTC,0	; Register interfaces
#define DIO 			PORTC,3	; Data interfaces
#define DCLK			PORTB,0 ;
#define CHP_OUT			PORTC,5 ;not used
;
#define PDATA_DIR		TRISC,0
#define DIO_DIR			TRISC,3
;
#define SW1				PORTB,1	;Switches on Trasnmitter side
#define SW2				PORTB,2	;
#define SW3				PORTB,3	;
#define	STEERING		PORTC,1	;
#define	SPIN_DIR		PORTC,7	;
;
#define LED1			PORTC,4	;(IN5)LEDs on Receiver side corresponding to the 
#define LED2			PORTB,2	;(IN6) swithces above
#define LED3			PORTB,1	;(IN7)
;
;
;ERRORS AND OTHER EVENTS
#define BUTTON_PRESSED	G_Events,0
#define REPLY_SENT		G_Events,1
#define	NEW_COUNT		G_Events,2
#define TIME_0_OUT		G_Events,3
#define BYTE_FULL		G_Events,4
#define RESET_CNTRS		G_Events,5
#define CALIBRATION_OK	G_Events,6
;
;STATES
#define IDLE_MODE		G_State,0
#define MASTER			G_State,1
#define SLAVE			G_State,2
#define RXCVER			G_State,3
#define TXMTER			G_State,4
#define	QUIET			G_State,5
;
;PROTOCOL 
;PROTOCOL PARTS
#define BOF_FOUND		G_Pr_status,0
#define PREAM_FINISHED	G_Pr_status,1
#define UI_FINISHED		G_Pr_status,2
#define	ADDR_CMPLT		G_Pr_status,3
#define NBR_BYTES_RCVD	G_Pr_status,4
#define DATA_RECEIVED	G_Pr_status,5
#define SUMCHECK_DONE	G_Pr_status,6
#define CMMND_COMPLETE	G_Pr_status,7
;
;OFFSETS:
#define PREAMBLE		0x00
#define UI				0x03
#define ADDRESS			0x05
#define NO_BYTES		0x07
#define DATA_OFFS		0x08
#define SUM_CHECK		0x0F
;
#define	UI_CODE1		0xCD	;unique ramdom number
#define	UI_CODE2		0x4D	;
;
;NUMBER OF BYTES
#define PREA_SIZE		3
#define UI_SIZE			2
#define ADD_SIZE		2
#define NBR_SIZE		1
#define DATA_SIZE		7
#define CS_SIZE			1

TOT_FRAME_SIZ			equ	PREA_SIZE+UI_SIZE+ADD_SIZE+NBR_SIZE+DATA_SIZE+CS_SIZE
FIXED_PART				equ	PREA_SIZE+UI_SIZE+ADD_SIZE+NBR_SIZE

#define	RX_CURRENT		0x44 ;0100xxxx=950uA, XXXX=?????
#define RXPLL			0x60
#define	TX_CURRENT		0x81 ;1000xxxx=1450uA
#define TXPLL			0x48
#define PA_VALUE		0xFF

;TIMER 1 TIMERS
;;;#define	RXMIT_TIM1L		0x90	;at 9600bps: h'3590 = 13,712uS=14ms
;;;#define	RXMIT_TIM1H		0x35	; (104uS/b*8bit/byt*16byt/frame+250uS+xx+ switch RX-TX)

#define	RXMIT_TIM1L		0xf0	;20ms includes delays for the master switch RX -> TX
#define	RXMIT_TIM1H		0x55	;

;LOCK TIMEOUTS (this is a 16 bit integer e.g. 01FF)
#define	LOCK1			0xFF
#define	LOCK2			0x01


;TOGGLES AND CONTROLS FOR LEDS
;#define TOGGLE_G		L_GREEN_CTL,7
;#define	GREEN_FLAG		L_GREEN_CTL,6
;#define	SPEED_G			L_GREEN_CTL,5
;
;#define TOGGLE_R		L_RED_CTL,7
;#define	RED_FLAG		L_RED_CTL,6
;#define	SPEED_R			L_RED_CTL,5
;
;#define	SLOW_ON			b'11000110'		;1xx..=start on, x1x..=on, xx000110=6 beats
;#define	SLOW_OFF		b'01000110'		;0xx..=start off, x1x..=on, xx000110=6 beats
;
;#define	FAST_ON			b'11000010'
;#define	FAST_OFF		b'01000010'
;
;#define VERYSLOW		b'11010000'












