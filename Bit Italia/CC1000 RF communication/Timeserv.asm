;************************************************************
;	TITLE:	Timing services for PIC17F876A
;	FILENAME:  Timeserv.asm
;	REVISION HISTORY:  31-03-03 First try
;	HARDWARE: BIT SRL. transciever
;	FREQUENCY: 4MHz
;	Function: Provides timing services to other modules
;************************************************************
			list	p=16f876

#include	<p16f876.inc>
#include 	<CC1000.h>
#include 	<hw_interf.h>

;Local variables
	UDATA
L_Tim1		res		1
L_Tim2		res		1
L_Tim3		res		1

	Extern	G_Events	;(see hw_interf.h for flags in G_Events)

		CODE	
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Procedure: 	These are actually 3 procedures that offer a combination of delays
;Function:	Cause a delay by a specified number of miliseconds,100uS or uS
;			In these procedures, the flag XMIT_RCVD will be set only by the ISR
;			if a data is received.  Otherwise, if its used for just delaying,
;			it is assumed that no delays are expected (corresponding interrupt enables
;			are reset).
;Inputs:	W number of 100 Ms,100Us or uS
;Returns:	Nothing
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DelaymS
			global DelaymS
			MOVWF	L_Tim3		;W has the number of miliseconds
_MILISEC	MOVLW	d'10'		;
			CALL	Delay100uS	;
			DECFSZ	L_Tim3,F	;
			GOTO	_MILISEC	;
TIMEREXMs	RETURN				;
;........................................................
Delay100uS
			global Delay100uS
			MOVWF	L_Tim2		;W has number of 100uS to wait
_MIC100S	MOVLW	d'100'		;				
			CALL	DelayuS		;
			DECFSZ	L_Tim2,F	;
			GOTO	_MIC100S	;
TIMEREX100	RETURN				;
;........................................................
DelayuS
			global DelayuS
			BCF		INTCON,T0IF	;
			MOVWF	L_Tim1		;W has the number of uS (1:1 prescaler)
			COMF	L_Tim1,F	;TMR0=(256 - number of clocks)
			INCF	L_Tim1,F	;2 increments for lost instruct clocks
			INCF	L_Tim1,W	;		
			MOVWF	TMR0		;
_LOOP_TIM0	BTFSS	INTCON,T0IF	;Timer0 overflow?
			GOTO	_LOOP_TIM0	;
TIMERXuS	RETURN				;
;........................................................
			END						; end timeserve code
