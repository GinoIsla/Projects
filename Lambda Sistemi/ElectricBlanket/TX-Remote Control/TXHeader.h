;
;********* make changes to LCD prescale here  ONLY ********************
LCD_PRESCALE	EQU		b'00000011'			;PRESCALE=4 (last 4 bits of LCDPS)
;*********************************************************************
;#DEFINE	WAVE_TYPE_A						;type of WAVE determines, among other things, the number of
#DEFINE		WAVE_TYPE_B						; cycles we have to use to write to the LCD
;*********************************************************************
;#DEFINE RANDMOM_REFRESH					;random restranmission of the REFRESH_MSG or
;											; COMMENTED OUT = rxmit REFRESH every 15 minutes
;#DEFINE RANDMOM_BOOST_OFF					;random restranmission of BOOST_OFF or
;											; COMMENT OUT = rxmit at exactly 15 seconds
;*********************************************************************
WFT_A				EQU	b'00000000'
WFT_B				EQU	b'10000000'
MULTIPLEX			EQU	.4					;1/4 multiplex

LCD_FRAME_FREQ		EQU	.1024/(MULTIPLEX * (LCD_PRESCALE+1))	;Hz
MILLI				EQU	.1000					;
LCD_FRAME_PERIOD	EQU	.1000*MILLI/LCD_FRAME_FREQ		;in millisecs

;++++++++++++ This is the time base for this project (1/4 mpx) +++++++++++++++++++++++++++
LCD_TICK			EQU	LCD_FRAME_PERIOD*2 			;
;++++++++++++ This is the time base for this project +++++++++++++++++++++++++++++++++++++

PW_ON_PERIOD		EQU	LED1_ON_PERIOD*MILLI/LCD_TICK		;counts for a period of approx 300ms
PW_OFF_PERIOD		EQU	LED1_OFF_PERIOD*MILLI/LCD_TICK		;counts for a period of approx 3 seconds
DEBOUNCE_PERIOD		EQU	DEBOUNCE_NORMAL*MILLI/LCD_TICK		;debounce

	IF	DEBOUNCE_PERIOD < .150*MILLI/LCD_TICK
	ERROR:"DEBOUNCE_PERIOD OUT OF RANGE"
	ENDIF

AUTOLOCK_DEBOUNCE	EQU	DEBOUNCE_AUTOLOCK*MILLI/LCD_TICK	;2seconds
HEAT_ADJ_DEBOUNCE	EQU	.400*MILLI/LCD_TICK					;slow down continuous heat adjustments

BLINK_PERIOD		EQU	BLINK_TIME*MILLI/LCD_TICK			;1/2 second blinks when adjusting the clock

;AUTOLOCK_OFF_TIME	EQU	.30									;in seconds
SIXTY_MINUTES		EQU	.60									;
;BACKLIGHT_PERIOD	EQU	.30									;seconds

MAX_TEMP			EQU	.10									;max setting

;BOOST_PERIOD		EQU	.30									;minutes
SEND_OFF_PERIOD		EQU	.30									;in minutes, repeat OFF msg

#IFDEF RANDMOM_REFRESH
SEND_ON_PERIOD		EQU	.720								;12 minutes + a random number 0:191secs for random repeat ON msg
#ELSE
SEND_ON_PERIOD		EQU	.900								;fixed 15 minutes
#ENDIF

RESEND_BOOST_PERIOD	EQU	.15									;retransmit BOOST_OFF unless RANDOM_BOOST_OFF, see SECONDS_TASKS() )

MSG_PAUSE_PERIOD	EQU	.32*MILLI/LCD_TICK					;30 ms betwwen repeats of the same message

HEAT_MSG_COUNTDWN	EQU	HEAT_MSG_DELAY*MILLI/LCD_TICK		;delay before sending the last heat message

BATT_HIGH_THRESHLD	EQU	(PERCENT_BATT_HIGH_THRESHLD*.255)/.100	;substitute the percent load (.65) by appropriate number
BATT_LOW_THRESHLD	EQU	(PERCENT_BATT_LOW_THRESHLD*.255)/.100	;substitute the percent load (.40) by appropriate number
IDLE_BATTERY_TEST	EQU	.12										;number of HOURS in which to perform the battery test if no messages are sent

BLINK_2P_PERIOD		EQU	.1000*MILLI/LCD_TICK

CLKP_NOTHING		EQU	0
CLKP_1224			EQU	1
CLKP_MIN_ADJ		EQU	2
CLKP_HOUR_ADJ		EQU	3
CLKP_HOUR_DISP24	EQU	0x24					;in BCD for displaying during adjustments
CLKP_HOUR_DISP12	EQU	0x12					;in BCD for displaying during adjustments
CLKP_HOUR_24		EQU	.24					;
CLKP_HOUR_12		EQU	.12					;
;
AUTO_OFF_OFF		EQU	.0					;
AUTO_OFF_1HR		EQU	.1					;in hours
AUTO_OFF_3HR		EQU	.3					;
AUTO_OFF_12HR		EQU	.12					;

MESSAGE_LENGTH		EQU	.48					;packet length
;REXMIT_NORMAL		EQU	.2					;number of times to resend the message
;REXMIT_EXTEND		EQU	.3					;learn and refresh

#define	TXENBL_TRIS	TRISA,0					;switch the TX_ENABLE port when not in use

;Port assignment
#define	TX_ENABLE	PORTA,0
#define	LCD7		PORTA,1
#define	COM2		PORTA,2
#define KB0			PORTA,3
#define	LCD4		PORTA,4
#define	LCD5		PORTA,5
#define				PORTA6	"NOT USED"
#define				PORTA7	"NOT USED"
#define	MASKTA		b'11000001'					;TX_ENABLE in INPUT
;
#define	LCD0		PORTB,0
#define	LCD1		PORTB,1
#define	LCD2		PORTB,2
#define	LCD3		PORTB,3
#define	COM0		PORTB,4
#define	COM1		PORTB,5
#define BACKLIGHT	PORTB,6
#define LED1		PORTB,7
#define	MASKTB		b'00000000'
;
#define 			PORTC0	"DONT KNOW"
#define 			PORTC1	"DONT KNOW"
#define 			PORTC2	"DONT KNOW"
#define	LCD6		PORTC,3
#define	LCD11		PORTC,4
#define	LCD10		PORTC,5
#define	LCD9		PORTC,6
#define	LCD8		PORTC,7
#define	MASKTC		b'00000111'
;
#define	COM3		PORTD,0
#define	KB1			PORTD,1
#define	KB2			PORTD,2
#define	KB3			PORTD,3
#define	KB4			PORTD,4
#define	KB5			PORTD,5
#define	KB6			PORTD,6
#define	PWM_HCS		PORTD,7
#define	MASKTD		b'00111110'
;
#define	DEBUG_OUT	PORTE,0
#define	KB7			PORTE,0
#define	KB8			PORTE,1
#define	VDIODE		PORTE,2
#define	MCLR		PORTE,3
#define	MASKTE		b'11111110'

;******* FLAGS ********* LOOK OUT FOR BANK CHANGES *********************
#DEFINE	MINUTES			LCD_CHAR1,0			; LCD_CHAR1 IS THE COMMON BANK
#DEFINE	HOURS			LCD_CHAR1,1			;
#DEFINE ONEHR			LCD_CHAR1,2			;characters to be displayed in the LCD 
#DEFINE THREEHR			LCD_CHAR1,3			;
#DEFINE TWELVEHR		LCD_CHAR1,4			;
#DEFINE	TEMPETR			LCD_CHAR1,5			;
#DEFINE	LOCKED			LCD_CHAR1,6			;
#DEFINE	BATTLOW			LCD_CHAR1,7			;

#DEFINE	DEVON			LCD_CHAR2,0			; LCD_CHAR2 IS IN THE COMMON BANK
#DEFINE	DEVOFF			LCD_CHAR2,1			;
#DEFINE	BOOST			LCD_CHAR2,2			;
#DEFINE LCD_UPD			LCD_CHAR2,3			;time to update the real time clock counters
#DEFINE LED1_STATE		LCD_CHAR2,4			;LED1 flashes for.3 secs/3secs
#DEFINE	PLUS_BUT		LCD_CHAR2,5			;
#DEFINE	MINUS_BUT		LCD_CHAR2,6			;
#DEFINE	ADJUST_RT		LCD_CHAR2,7			;

#DEFINE	DEBOUNCING		LCD_CHAR3,0			; LCD_CHAR3 IS IN BANK 0
#DEFINE	BTN_ACT_PDG		LCD_CHAR3,1			;button action in progress
#DEFINE MODE_ACT		LCD_CHAR3,2			;on-going MODE change 
#DEFINE CLCKSET_ACT		LCD_CHAR3,3			;now changing the clock
#DEFINE	UNLOCKING		LCD_CHAR3,4			;now in process of unlocking
#DEFINE	HEAT_ACT		LCD_CHAR3,5			;
#DEFINE	AUTOLOCK_ON 	LCD_CHAR3,6			;
#DEFINE	RELOCK_ON		LCD_CHAR3,7			;

#DEFINE	SND_OFF_MSG		LCD_CHAR4,0			;LCD_CHAR4 IS IN BANK 0
#DEFINE	SND_ON_MSG		LCD_CHAR4,1			;messages to the base
#DEFINE	SND_BOOSTON_MSG	LCD_CHAR4,2			;
#DEFINE	SND_BOO_OFF_MSG	LCD_CHAR4,3			;
#DEFINE	SND_TEMP_MSG	LCD_CHAR4,4			;
#DEFINE	SND_LEARN_MSG	LCD_CHAR4,5			;
#DEFINE	SND_TEST_MSG	LCD_CHAR4,6			;
#DEFINE	SND_REFRESH_MSG	LCD_CHAR4,7

#DEFINE	BEEPER			LCD_CHAR5,0			;LCD_CHAR5 IS IN  THE COMMON BANK
#DEFINE	BATTERY_WARN	LCD_CHAR5,1			;warnings for the battery charge level
#DEFINE	BATTERY_LOW		LCD_CHAR5,2			;
#DEFINE BOOST_ACT		LCD_CHAR5,3			;pre-heat
#DEFINE F_BODY_GUARD	LCD_CHAR5,4			;DISABLE KB0 CONTROL
#DEFINE COLON			LCD_CHAR5,5			;late requirement, blink ":" every second
#DEFINE F_SEND_BOOFF	LCD_CHAR5,6			;counts seconds for send and re-send of PREHEAT-OFF MSG
#DEFINE F_RESEND_BOOFF	LCD_CHAR5,7			;

;
#DEFINE	SPARE			NEW_BUTTON_CONFIG,0		;KB8
#DEFINE	PREHEAT			NEW_BUTTON_CONFIG,1		;KB1
#DEFINE	MODE			NEW_BUTTON_CONFIG,2		;KB2	
#DEFINE	MINUS			NEW_BUTTON_CONFIG,3		;KB3
#DEFINE	PLUS			NEW_BUTTON_CONFIG,4		;KB4
#DEFINE	CLOCK_SET		NEW_BUTTON_CONFIG,5		;KB5
#DEFINE	S_KB6			NEW_BUTTON_CONFIG,6
#DEFINE	S_KB7			NEW_BUTTON_CONFIG,7




