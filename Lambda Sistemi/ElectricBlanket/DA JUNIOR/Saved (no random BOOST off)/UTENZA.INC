

LED1_ON_PERIOD			EQU	.300	;100÷7968 milliseconds;
LED1_OFF_PERIOD			EQU	.3000	;100÷7968 milliseconds;


DEBOUNCE_NORMAL			EQU	.200	;100÷7968 milliseconds; debounce for all keys if not in autolock 
DEBOUNCE_AUTOLOCK		EQU	.2000	;100÷7968 milliseconds; debounce for MODE keys only if in autolock


	IF	DEBOUNCE_NORMAL < .150
	ERROR:"DEBOUNCE_NORMAL OUT OF RANGE"
	ENDIF


BLINK_TIME			EQU	.500	;100÷7968 milliseconds; blinks when adjusting the clock


AUTOLOCK_OFF_TIME		EQU	.30	;1÷255	seconds


BACKLIGHT_PERIOD		EQU	.30	;1÷255	seconds


BOOST_PERIOD			EQU	.30	;1÷255	minutes


HEAT_MSG_DELAY			EQU	.300	;100÷1000 milliseconds; delay before sending the last heat message


PERCENT_BATT_HIGH_THRESHLD	EQU	.60	;1÷100	percent battery high threshold
PERCENT_BATT_LOW_THRESHLD	EQU	.53	;1÷100	percent battery low threshold


REXMIT_NORMAL			EQU	.2	;1÷255	number of times to resend the message of temperature
REXMIT_EXTEND			EQU	.3	;1÷255	number of times to resend the message of learn and refresh
