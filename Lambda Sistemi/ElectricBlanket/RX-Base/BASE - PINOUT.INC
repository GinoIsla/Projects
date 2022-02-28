;================ BASE - PINOUT ================
;
;					PIC16F73
;					 	_______________  ________________
;MCLR -		MCLR		| 1 MCLR/VPP	\/	RB7/PGD	28|			X
;NTC	 -	AN0			| 2 RA0/AN0		RB6/PGC	27|			X
;		AN1				| 3 RA1/AN1		RB5	26|			X
;		X				| 4 RA2/AN2		RB4	25|			X
;VREF ? -	VREF/AN3	| 5 RA3/AN3/VREF	RB3	24|			X
;		X				| 6 RA4/TOCKI		RB2	23|ERROR AFT2 -		IN
;		X				| 7 RA5/AN4/SS		RB1	22|ERROR AFT1 -		IN
;						| 8 VSS			RB0/INT021|RX RF -		IN
;CLKIN -	CLKIN		| 9 OSC1/CLKIN		VDD	20|
;CLKOUT -	CLKOUT		|10 OSC2/CLKOUT		VSS	19|
;ENABLE PWM2 -	OUT		|11 RC0			RC7	18|EE_CLOCK		OUT
;PWM2/BUZZER -	CCP2	|12 RC1/CCP2		RC6	17|EE_DATA		X
;PWM1 -		CCP1		|13 RC2/CCP1		RC5	16|LED ALARM AFT2 -	OUT
;ENABLE BUZZER - OUT	|14 RC3			RC4	15|LED ALARM AFT1 -	OUT
;			 			---------------------------------
