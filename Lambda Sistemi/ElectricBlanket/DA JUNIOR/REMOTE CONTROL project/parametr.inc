;******************************************************************
; DEBUGGING KEY DEFINITION
;
;#DEFINE	KEY_ALBANO	1

	IFDEF	KEY_ALBANO
KEY1_HI	EQU	0x41		;A	KEY DEFINITION
KEY2	EQU	0x6C		;l
KEY3	EQU	0x62		;b
KEY4	EQU	0x61		;a
KEY5	EQU	0x6E		;n
KEY6	EQU	0x6F		;o
KEY7	EQU	0x45		;E
KEY8_LO	EQU	0x6C		;l
	ENDIF

	IFDEF	NO_COMMENT
#DEFINE KEY643	H'416C'		;Al	KEY DEFINITION
#DEFINE KEY642	H'6261'		;ba
#DEFINE KEY641	H'6E6F'		;no
#DEFINE KEY640	H'4562'		;El
	ENDIF

#DEFINE	KEY_DEFAULT	1

	IFDEF	KEY_DEFAULT
KEY1_HI	EQU	0x00
KEY2	EQU	0x00
KEY3	EQU	0x00
KEY4	EQU	0x00
KEY5	EQU	0x00
KEY6	EQU	0x00
KEY7	EQU	0x00
KEY8_LO	EQU	0x00
	ENDIF

;******************************************************************

#DEFINE	SEED_ALBANO	1
	
	IFDEF	SEED_ALBANO
SEED_HI	EQU	414CH		;AL	SEED DEFINITION
SEED_LO	EQU	4241H		;BA
	ENDIF

;******************************************************************
PRIMA_FINESTRA		EQU	.500		;IN PASSI DEL ROLLING CODE (MAX SECONDA_FINESTRA - 1)
SECONDA_FINESTRA	EQU	.5000	;IN PASSI DEL ROLLING CODE (MAX 65 535)
;******************************************************************

;******************************************************************
MANTENIMENTO_RELE	EQU	.6	;IN DECIMI DI SECONDO (MAX 256)
;******************************************************************

;******************************************************************
TEMPO_RESET		EQU	.5	;IN SECONDI (MAX 128)
;******************************************************************

;******************************************************************
TEMPO_LEARN		EQU	.15	;IN SECONDI (MAX 25)
;******************************************************************

;******************************************************************
T_LEARN			EQU	TEMPO_LEARN*.10
;******************************************************************

