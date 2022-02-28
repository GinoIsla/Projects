/*
 *	Header file for the Microchip 
 *	PIC 16F870
 *	PIC 16F871
 *	PIC 16F872 chip
 *	PIC 16F873 chip
 *	PIC 16F874 chip
 *	PIC 16F876 chip
 *	PIC 16F877 chip
 *	Midrange Microcontroller
 */

#if defined(_16F874) || defined(_16F877) || defined(_16F871)
#define	__PINS_40
#endif

static volatile unsigned char	TMR0	@ 0x01;
static volatile unsigned char	PCL	@ 0x02;
static volatile unsigned char	STATUS	@ 0x03;
static          unsigned char	FSR	@ 0x04;
static volatile unsigned char	PORTA	@ 0x05;
static volatile unsigned char	PORTB	@ 0x06;
static volatile unsigned char	PORTC	@ 0x07;
#ifdef __PINS_40
static volatile unsigned char	PORTD	@ 0x08;
static volatile unsigned char	PORTE	@ 0x09;
#endif
static          unsigned char	PCLATH	@ 0x0A;
static volatile unsigned char	INTCON	@ 0x0B;
static volatile unsigned char	PIR1	@ 0x0C;
static volatile unsigned char	PIR2	@ 0x0D;
static volatile unsigned char	TMR1L	@ 0x0E;
static volatile unsigned char	TMR1H	@ 0x0F;
static volatile unsigned char	T1CON	@ 0x10;
static volatile unsigned char	TMR2	@ 0x11;
static volatile unsigned char	T2CON	@ 0x12;
#if !defined(_16F870) && !defined(_16F871)
static volatile unsigned char	SSPBUF	@ 0x13;
static volatile unsigned char	SSPCON	@ 0x14;
#endif
static volatile unsigned char	CCPR1L	@ 0x15;
static volatile unsigned char	CCPR1H	@ 0x16;
static volatile unsigned char	CCP1CON	@ 0x17;
#ifndef _16F872
static volatile unsigned char	RCSTA	@ 0x18;
static volatile unsigned char	TXREG	@ 0x19;
static volatile unsigned char	RCREG	@ 0x1A;
#if !defined(_16F870) && !defined(_16F871)
static volatile unsigned char	CCPR2L	@ 0x1B;
static volatile unsigned char	CCPR2H	@ 0x1C;
static volatile unsigned char	CCP2CON	@ 0x1D;
#endif
#endif
static volatile unsigned char	ADRESH	@ 0x1E;
static volatile unsigned char	ADCON0	@ 0x1F;

/*	bank 1 registers */
static          unsigned char bank1	OPTION	@ 0x81;
static volatile	unsigned char bank1	TRISA	@ 0x85;
static volatile	unsigned char bank1	TRISB	@ 0x86;
static volatile	unsigned char bank1	TRISC	@ 0x87;
#ifdef	__PINS_40
static volatile unsigned char bank1	TRISD	@ 0x88;
static volatile unsigned char bank1	TRISE	@ 0x89;
#endif
static volatile unsigned char bank1	PIE1	@ 0x8C;
static volatile unsigned char bank1	PIE2	@ 0x8D;
static volatile unsigned char bank1	PCON	@ 0x8E;
#if !defined(_16F870) && !defined(_16F871)
static volatile unsigned char bank1	SSPCON2	@ 0x91;
#endif
static volatile unsigned char bank1	PR2	@ 0x92;
#if !defined(_16F870) && !defined(_16F871)
static volatile unsigned char bank1	SSPADD	@ 0x93;
static volatile unsigned char bank1	SSPSTAT	@ 0x94;
#endif
#ifndef _16F872
static volatile unsigned char bank1	TXSTA	@ 0x98;
static volatile unsigned char bank1	SPBRG	@ 0x99;
#endif
static volatile unsigned char bank1	ADRESL	@ 0x9E;
static volatile unsigned char bank1	ADCON1	@ 0x9F;

/*	bank 2 registers */
static volatile unsigned char bank2	EEDATA	@ 0x10C;
static volatile unsigned char bank2	EEADR	@ 0x10D;
static volatile unsigned char bank2	EEDATH	@ 0x10E;
static volatile unsigned char bank2	EEADRH	@ 0x10F;

/*	bank 3 registers */
static volatile unsigned char bank3	EECON1	@ 0x18C;
static volatile unsigned char bank3	EECON2	@ 0x18D;

/*	STATUS bits	*/
static volatile bit	IRP     @ (unsigned)&STATUS*8+7;
static volatile bit	RP1     @ (unsigned)&STATUS*8+6;
static volatile bit	RP0     @ (unsigned)&STATUS*8+5;
static volatile bit	TO	@ (unsigned)&STATUS*8+4;
static volatile bit	PD	@ (unsigned)&STATUS*8+3;
static volatile bit	ZERO    @ (unsigned)&STATUS*8+2;
static volatile bit	DC      @ (unsigned)&STATUS*8+1;
static volatile bit	CARRY   @ (unsigned)&STATUS*8+0;

/*      PORTA bits      */
static volatile bit	RA5	@ (unsigned)&PORTA*8+5;
static volatile bit	RA4	@ (unsigned)&PORTA*8+4;
static volatile bit	RA3	@ (unsigned)&PORTA*8+3;
static volatile bit	RA2	@ (unsigned)&PORTA*8+2;
static volatile bit	RA1	@ (unsigned)&PORTA*8+1;
static volatile bit	RA0	@ (unsigned)&PORTA*8+0;

/*      PORTB bits      */
static volatile bit	RB7	@ (unsigned)&PORTB*8+7;
static volatile bit	RB6	@ (unsigned)&PORTB*8+6;
static volatile bit	RB5	@ (unsigned)&PORTB*8+5;
static volatile bit	RB4	@ (unsigned)&PORTB*8+4;
static volatile bit	RB3	@ (unsigned)&PORTB*8+3;
static volatile bit	RB2	@ (unsigned)&PORTB*8+2;
static volatile bit	RB1	@ (unsigned)&PORTB*8+1;
static volatile bit	RB0	@ (unsigned)&PORTB*8+0;

/*      PORTC bits      */
static volatile bit	RC7	@ (unsigned)&PORTC*8+7;
static volatile bit	RC6	@ (unsigned)&PORTC*8+6;
static volatile bit	RC5	@ (unsigned)&PORTC*8+5;
static volatile bit	RC4	@ (unsigned)&PORTC*8+4;
static volatile bit	RC3	@ (unsigned)&PORTC*8+3;
static volatile bit	RC2	@ (unsigned)&PORTC*8+2;
static volatile bit	RC1	@ (unsigned)&PORTC*8+1;
static volatile bit	RC0	@ (unsigned)&PORTC*8+0;

/*      PORTD bits      */
#ifdef	__PINS_40
static volatile bit	RD7	@ (unsigned)&PORTD*8+7;
static volatile bit	RD6	@ (unsigned)&PORTD*8+6;
static volatile bit	RD5	@ (unsigned)&PORTD*8+5;
static volatile bit	RD4	@ (unsigned)&PORTD*8+4;
static volatile bit	RD3	@ (unsigned)&PORTD*8+3;
static volatile bit	RD2	@ (unsigned)&PORTD*8+2;
static volatile bit	RD1	@ (unsigned)&PORTD*8+1;
static volatile bit	RD0	@ (unsigned)&PORTD*8+0;

/*      PORTE bits      */
static volatile bit	RE2	@ (unsigned)&PORTE*8+2;
static volatile bit	RE1	@ (unsigned)&PORTE*8+1;
static volatile bit	RE0	@ (unsigned)&PORTE*8+0;
#endif

/*	INTCON bits	*/
static volatile bit	GIE	@ (unsigned)&INTCON*8+7;
static volatile bit	PEIE	@ (unsigned)&INTCON*8+6;
static volatile bit	T0IE	@ (unsigned)&INTCON*8+5;
static volatile bit	INTE	@ (unsigned)&INTCON*8+4;
static volatile bit	RBIE	@ (unsigned)&INTCON*8+3;
static volatile bit	T0IF	@ (unsigned)&INTCON*8+2;
static volatile bit	INTF	@ (unsigned)&INTCON*8+1;
static volatile bit	RBIF	@ (unsigned)&INTCON*8+0;

/*	PIR1 bits	*/
#ifdef	__PINS_40
static volatile bit	PSPIF	@ (unsigned)&PIR1*8+7;
#endif
static volatile bit	ADIF	@ (unsigned)&PIR1*8+6;
#ifndef _16F872
static volatile bit	RCIF	@ (unsigned)&PIR1*8+5;
static volatile bit	TXIF	@ (unsigned)&PIR1*8+4;
#endif
#if !defined(_16F870) && !defined(_16F871)
static volatile bit	SSPIF	@ (unsigned)&PIR1*8+3;
#endif
static volatile bit	CCP1IF	@ (unsigned)&PIR1*8+2;
static volatile bit	TMR2IF	@ (unsigned)&PIR1*8+1;
static volatile bit	TMR1IF	@ (unsigned)&PIR1*8+0;

/*	PIR2 bits	*/
static volatile bit	EEIF	@ (unsigned)&PIR2*8+4;
#if !defined(_16F870) && !defined(_16F871)
static volatile bit	BCLIF	@ (unsigned)&PIR2*8+3;
#ifndef _16F872
static volatile bit	CCP2IF	@ (unsigned)&PIR2*8+0;
#endif
#endif

/*	T1CON bits	*/
static volatile bit	T1CKPS1	@ (unsigned)&T1CON*8+5;
static volatile bit	T1CKPS0	@ (unsigned)&T1CON*8+4;
static volatile bit	T1OSCEN	@ (unsigned)&T1CON*8+3;
static volatile bit	T1SYNC 	@ (unsigned)&T1CON*8+2;
static volatile bit	TMR1CS 	@ (unsigned)&T1CON*8+1;
static volatile bit	TMR1ON 	@ (unsigned)&T1CON*8+0;

/*	T2CON bits	*/
static volatile bit	TOUTPS3	@ (unsigned)&T2CON*8+6;
static volatile bit	TOUTPS2	@ (unsigned)&T2CON*8+5;
static volatile bit	TOUTPS1	@ (unsigned)&T2CON*8+4;
static volatile bit	TOUTPS0	@ (unsigned)&T2CON*8+3;
static volatile bit	TMR2ON 	@ (unsigned)&T2CON*8+2;
static volatile bit	T2CKPS1	@ (unsigned)&T2CON*8+1;
static volatile bit	T2CKPS0	@ (unsigned)&T2CON*8+0;

/*	SSPCON bits	*/
#if !defined(_16F870) && !defined(_16F871)
static volatile bit	WCOL	@ (unsigned)&SSPCON*8+7;
static volatile bit	SSPOV	@ (unsigned)&SSPCON*8+6;
static volatile bit	SSPEN	@ (unsigned)&SSPCON*8+5;
static volatile bit	CKP	@ (unsigned)&SSPCON*8+4;
static volatile bit	SSPM3	@ (unsigned)&SSPCON*8+3;
static volatile bit	SSPM2	@ (unsigned)&SSPCON*8+2;
static volatile bit	SSPM1	@ (unsigned)&SSPCON*8+1;
static volatile bit	SSPM0	@ (unsigned)&SSPCON*8+0;
#endif
/*	CCP1CON bits	*/
static volatile bit	CCP1X	@ (unsigned)&CCP1CON*8+5;
static volatile bit	CCP1Y	@ (unsigned)&CCP1CON*8+4;
static volatile bit	CCP1M3	@ (unsigned)&CCP1CON*8+3;
static volatile bit	CCP1M2	@ (unsigned)&CCP1CON*8+2;
static volatile bit	CCP1M1	@ (unsigned)&CCP1CON*8+1;
static volatile bit	CCP1M0	@ (unsigned)&CCP1CON*8+0;

/*	RCSTA bits	*/
#ifndef _16F872
static volatile bit	SPEN	@ (unsigned)&RCSTA*8+7;
static volatile bit	RX9 	@ (unsigned)&RCSTA*8+6;
static volatile bit	SREN	@ (unsigned)&RCSTA*8+5;
static volatile bit	CREN	@ (unsigned)&RCSTA*8+4;
static volatile bit	ADDEN	@ (unsigned)&RCSTA*8+3;
static volatile bit	FERR	@ (unsigned)&RCSTA*8+2;
static volatile bit	OERR	@ (unsigned)&RCSTA*8+1;
static volatile bit	RX9D	@ (unsigned)&RCSTA*8+0;
#endif

/*	CCP2CON bits	*/
#if !defined(_16F870) && !defined(_16F871) && !defined(_16F872)
static volatile bit	CCP2X	@ (unsigned)&CCP2CON*8+5;
static volatile bit	CCP2Y	@ (unsigned)&CCP2CON*8+4;
static volatile bit	CCP2M3	@ (unsigned)&CCP2CON*8+3;
static volatile bit	CCP2M2	@ (unsigned)&CCP2CON*8+2;
static volatile bit	CCP2M1	@ (unsigned)&CCP2CON*8+1;
static volatile bit	CCP2M0	@ (unsigned)&CCP2CON*8+0;
#endif

/*	 ADCON0 bits	*/
static volatile bit	ADCS1	@ (unsigned)&ADCON0*8+7;
static volatile bit	ADCS0 	@ (unsigned)&ADCON0*8+6;
static volatile bit	CHS2	@ (unsigned)&ADCON0*8+5;
static volatile bit	CHS1	@ (unsigned)&ADCON0*8+4;
static volatile bit	CHS0	@ (unsigned)&ADCON0*8+3;
static volatile bit	ADGO	@ (unsigned)&ADCON0*8+2;
static volatile bit	ADON	@ (unsigned)&ADCON0*8+0;

/* 	OPTION bits	*/
static bank1 bit	RBPU	@ (unsigned)&OPTION*8+7;
static bank1 bit	INTEDG	@ (unsigned)&OPTION*8+6;
static bank1 bit	T0CS	@ (unsigned)&OPTION*8+5;
static bank1 bit	T0SE	@ (unsigned)&OPTION*8+4;
static bank1 bit	PSA	@ (unsigned)&OPTION*8+3;
static bank1 bit	PS2	@ (unsigned)&OPTION*8+2;
static bank1 bit	PS1	@ (unsigned)&OPTION*8+1;
static bank1 bit	PS0	@ (unsigned)&OPTION*8+0;

/*      TRISA bits      */
static volatile bank1 bit	TRISA5	@ (unsigned)&TRISA*8+5;
static volatile bank1 bit	TRISA4	@ (unsigned)&TRISA*8+4;
static volatile bank1 bit	TRISA3	@ (unsigned)&TRISA*8+3;
static volatile bank1 bit	TRISA2	@ (unsigned)&TRISA*8+2;
static volatile bank1 bit	TRISA1	@ (unsigned)&TRISA*8+1;
static volatile bank1 bit	TRISA0	@ (unsigned)&TRISA*8+0;

/*      TRISB bits      */
static volatile bank1 bit	TRISB7	@ (unsigned)&TRISB*8+7;
static volatile bank1 bit	TRISB6	@ (unsigned)&TRISB*8+6;
static volatile bank1 bit	TRISB5	@ (unsigned)&TRISB*8+5;
static volatile bank1 bit	TRISB4	@ (unsigned)&TRISB*8+4;
static volatile bank1 bit	TRISB3	@ (unsigned)&TRISB*8+3;
static volatile bank1 bit	TRISB2	@ (unsigned)&TRISB*8+2;
static volatile bank1 bit	TRISB1	@ (unsigned)&TRISB*8+1;
static volatile bank1 bit	TRISB0	@ (unsigned)&TRISB*8+0;

/*      TRISC bits      */
static volatile bank1 bit	TRISC7	@ (unsigned)&TRISC*8+7;
static volatile bank1 bit	TRISC6	@ (unsigned)&TRISC*8+6;
static volatile bank1 bit	TRISC5	@ (unsigned)&TRISC*8+5;
static volatile bank1 bit	TRISC4	@ (unsigned)&TRISC*8+4;
static volatile bank1 bit	TRISC3	@ (unsigned)&TRISC*8+3;
static volatile bank1 bit	TRISC2	@ (unsigned)&TRISC*8+2;
static volatile bank1 bit	TRISC1	@ (unsigned)&TRISC*8+1;
static volatile bank1 bit	TRISC0	@ (unsigned)&TRISC*8+0;

#ifdef	__PINS_40
/*      TRISD bits      */
static volatile bank1 bit	TRISD7	@ (unsigned)&TRISD*8+7;
static volatile bank1 bit	TRISD6	@ (unsigned)&TRISD*8+6;
static volatile bank1 bit	TRISD5	@ (unsigned)&TRISD*8+5;
static volatile bank1 bit	TRISD4	@ (unsigned)&TRISD*8+4;
static volatile bank1 bit	TRISD3	@ (unsigned)&TRISD*8+3;
static volatile bank1 bit	TRISD2	@ (unsigned)&TRISD*8+2;
static volatile bank1 bit	TRISD1	@ (unsigned)&TRISD*8+1;
static volatile bank1 bit	TRISD0	@ (unsigned)&TRISD*8+0;

/*      TRISE bits      */
static volatile bank1 bit	IBF	@ (unsigned)&TRISE*8+7;
static volatile bank1 bit	OBF	@ (unsigned)&TRISE*8+6;
static volatile bank1 bit	IBOV	@ (unsigned)&TRISE*8+5;
static volatile bank1 bit	PSPMODE	@ (unsigned)&TRISE*8+4;

static volatile bank1 bit	TRISE2  @ (unsigned)&TRISE*8+2;
static volatile bank1 bit	TRISE1  @ (unsigned)&TRISE*8+1;
static volatile bank1 bit	TRISE0  @ (unsigned)&TRISE*8+0;
#endif

/*	PIE1 bits	*/
#ifdef	__PINS_40
static volatile bank1 bit	PSPIE	@ (unsigned)&PIE1*8+7;
#endif
static volatile bank1 bit	ADIE	@ (unsigned)&PIE1*8+6;
#ifndef _16F872
static volatile bank1 bit	RCIE	@ (unsigned)&PIE1*8+5;
static volatile bank1 bit	TXIE	@ (unsigned)&PIE1*8+4;
#endif
static volatile bank1 bit	SSPIE	@ (unsigned)&PIE1*8+3;
static volatile bank1 bit	CCP1IE	@ (unsigned)&PIE1*8+2;
static volatile bank1 bit	TMR2IE	@ (unsigned)&PIE1*8+1;
static volatile bank1 bit	TMR1IE	@ (unsigned)&PIE1*8+0;

/*	PIE2 bits	*/
static volatile bank1 bit	EEIE	@ (unsigned)&PIE2*8+4;
static volatile bank1 bit	BCLIE	@ (unsigned)&PIE2*8+3;
#ifndef _16F872
static volatile bank1 bit	CCP2IE	@ (unsigned)&PIE2*8+0;
#endif

/*	PCON bits	*/
static volatile bank1 bit	POR	@ (unsigned)&PCON*8+1;	
static volatile bank1 bit	BOR	@ (unsigned)&PCON*8+0;	

/*	SSPCON2 bits */
#if !defined(_16F870) && !defined(_16F871)
static volatile bank1 bit	GCEN	@ (unsigned)&SSPCON2*8+7;
static volatile bank1 bit	ACKSTAT	@ (unsigned)&SSPCON2*8+6;
static volatile bank1 bit	ACKDT	@ (unsigned)&SSPCON2*8+5;
static volatile bank1 bit	ACKEN	@ (unsigned)&SSPCON2*8+4;
static volatile bank1 bit	RCEN	@ (unsigned)&SSPCON2*8+3;
static volatile bank1 bit	PEN	@ (unsigned)&SSPCON2*8+2;
static volatile bank1 bit	RSEN	@ (unsigned)&SSPCON2*8+1;
static volatile bank1 bit	SEN	@ (unsigned)&SSPCON2*8+0;
#endif

/*      SSPSTAT bits    */
#if !defined(_16F870) && !defined(_16F871)
static volatile bank1 bit	STAT_SMP	@ (unsigned)&SSPSTAT*8+7;
static volatile bank1 bit	STAT_CKE	@ (unsigned)&SSPSTAT*8+6;
static volatile bank1 bit	STAT_DA		@ (unsigned)&SSPSTAT*8+5;
static volatile bank1 bit	STAT_P		@ (unsigned)&SSPSTAT*8+4;
static volatile bank1 bit	STAT_S		@ (unsigned)&SSPSTAT*8+3;
static volatile bank1 bit	STAT_RW		@ (unsigned)&SSPSTAT*8+2;
static volatile bank1 bit	STAT_UA		@ (unsigned)&SSPSTAT*8+1;
static volatile bank1 bit	STAT_BF		@ (unsigned)&SSPSTAT*8+0;
#endif

/*	TXSTA bits	*/
#ifndef _16F872
static volatile bank1 bit	CSRC	@ (unsigned)&TXSTA*8+7;
static volatile bank1 bit	TX9	@ (unsigned)&TXSTA*8+6;
static volatile bank1 bit	TXEN	@ (unsigned)&TXSTA*8+5;
static volatile bank1 bit	SYNC	@ (unsigned)&TXSTA*8+4;
static volatile bank1 bit	BRGH	@ (unsigned)&TXSTA*8+2;
static volatile bank1 bit	TRMT	@ (unsigned)&TXSTA*8+1;
static volatile bank1 bit	TX9D	@ (unsigned)&TXSTA*8+0;
#endif

/*	ADCON1 bits	*/
static volatile bank1 bit	ADFM	@ (unsigned)&ADCON1*8+7;
static volatile bank1 bit	PCFG3	@ (unsigned)&ADCON1*8+3;
static volatile bank1 bit	PCFG2	@ (unsigned)&ADCON1*8+2;
static volatile bank1 bit	PCFG1	@ (unsigned)&ADCON1*8+1;
static volatile bank1 bit	PCFG0	@ (unsigned)&ADCON1*8+0;

/*	EECON1 bits */
static volatile bank3 bit	EEPGD	@ (unsigned)&EECON1*8+7;
static volatile bank3 bit	WRERR	@ (unsigned)&EECON1*8+3;
static volatile bank3 bit	WREN	@ (unsigned)&EECON1*8+2;
static volatile bank3 bit	WR	@ (unsigned)&EECON1*8+1;
static volatile bank3 bit	RD	@ (unsigned)&EECON1*8+0;

/* macro versions of EEPROM write and read */
#define	EEPROM_WRITE(addr, value) while(WR)continue;EEADR=(addr);EEDATA=(value);EEPGD=0;GIE=0;WREN=1;\
					EECON2=0x55;EECON2=0xAA;WR=1;WREN=0
#define	EEPROM_READ(addr) ((EEADR=(addr)),(EEPGD=0),(RD=1),EEDATA)
					
/* library function versions */
					
extern void eeprom_write(unsigned char addr, unsigned char value);
extern unsigned char eeprom_read(unsigned char addr);
					
#define CONFIG_ADDR	0x2007
#define FOSC0		0x01
#define FOSC1		0x02
#define WDTE		0x04
#define PWRTE		0x08
#define CP0		0x1010
#define CP1		0x2020
#define BODEN		0x40
#define LVP		0x80
#define CPD		0x100
#define WRT		0x200
#define BKBUG		0x800

#define UNPROTECT	(CP0 | CP1)
#define PROTECT		0x0000

#if !defined(_16F870) && !defined(_16F871)
#define	PROTECT_TOP	CP1	/* protects top 256 bytes, 1F00h to 1FFFh	*/
#define PROTECT50	CP0	/* protects upper half of address space		*/
				/* 1000h to 1FFFh (pic16f887/876)		*/
				/* 0800h to 0FFFh (pic16f874/873)		*/
#endif
