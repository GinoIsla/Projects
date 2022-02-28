// Programmer: Gino Isla for Lambda Sistemi, Milano
// Intialiazation procedures for a CANOpen node
// Created: 22-11-2004
//

//---------------------------------------------------------------------
// Interrupt Code
//---------------------------------------------------------------------
#include <p18f458.h>
#include "can.h"

/* ------------------------------------------- Variabili globali: -------------- */
extern volatile struct TXB_BUFF TXB_B [MAX_CAN_OUT];
extern volatile struct TXB_BUFF RXB_B [MAX_CAN_IN];
extern char StatoUnita;
extern unsigned int Id;
extern struct heartbeat heartbeat_count;
extern struct heartbeat heartbeat_rate;
extern	struct timer1_convert T1;
extern struct Key_Row	KEY_PAD_NEW [MAX_ROWS];  //recently read keypad
extern struct Key_Row	KEY_PAD_PREV [MAX_ROWS]; //previous keypad states
extern struct Key_Row	KEY_PAD_SENT [MAX_ROWS]; //last sent keypad states
extern unsigned char	DEBOUNCE_FLAG;
extern unsigned char debounce_count;
extern unsigned char debounce_period;
extern unsigned char row_count; 

extern unsigned char Next_Group;
extern unsigned char LEDs [6];
extern unsigned char BlinkLEDs [6];
extern unsigned char BlinkMask [6];
extern unsigned char LEDs_on;
extern struct LED_mask mask;
extern unsigned char ultimo_out;
extern unsigned char check_keypad_now; 
extern unsigned char test_error_now; 
extern unsigned char error_persistancy_count;
extern unsigned char NON_error_persistancy_count;

char    RXB_B_BTXBD0;
char    RXB_B_BTXBD1;
char    RXB_B_BTXBD2;
char    RXB_B_BTXBD3;
char    RXB_B_BTXBD4;
char    RXB_B_BTXBD5;
char    RXB_B_BTXBD6;
char    RXB_B_BTXBD7;
char    RXB_B_BST_BR_R;
char    RXB_B_BTXBSIDL;
char    RXB_B_BTXBSIDH;
char    RXB_B_BTXBDLC;

char   bus_passive = 0;
char   bus_off_int = 0;


// default parameters
#pragma romdata eeprom=0xF00000
const rom char y []= {3,2,0x3,0xE8,0,3,9,9,9,9};

#pragma romdata
		
#pragma interrupt InterruptRxCAN save=PROD,section(".tmpdata")

#pragma code isrcode=0x0008
void InterruptHandler(void)
{
 _asm   goto InterruptRxCAN   _endasm 
}
#pragma code


//***************************************************//
// Gestione recezione messaggio CAN
//***************************************************//
void InterruptRxCAN(void)
{ 
 char i;
 char TempCANSTAT,TempCANCON;

// Recezione telegramma via CAN
    TempCANSTAT = CANSTAT;
    TempCANCON = CANCON;

    if (RXB0CONbits.RXFUL)
    {
     RXB_B_BTXBD0 = RXB0D0;
     RXB_B_BTXBD1 = RXB0D1;
     RXB_B_BTXBD2 = RXB0D2;
     RXB_B_BTXBD3 = RXB0D3;
     RXB_B_BTXBD4 = RXB0D4;
     RXB_B_BTXBD5 = RXB0D5;
     RXB_B_BTXBD6 = RXB0D6;
     RXB_B_BTXBD7 = RXB0D7;
     RXB_B_BST_BR_R = RXB0CONbits.RXRTRRO;
     RXB_B_BTXBSIDL = RXB0SIDL;
     RXB_B_BTXBSIDH = RXB0SIDH;
	 RXB_B_BTXBDLC = RXB0DLC;
     RXB0CONbits.RXFUL = 0;
     PIR3bits.RXB0IF = 0;
    } 
   else
    {
     RXB_B_BTXBD0 = RXB1D0;
     RXB_B_BTXBD1 = RXB1D1;
     RXB_B_BTXBD2 = RXB1D2;
     RXB_B_BTXBD3 = RXB1D3;
     RXB_B_BTXBD4 = RXB1D4;
     RXB_B_BTXBD5 = RXB1D5;
     RXB_B_BTXBD6 = RXB1D6;
     RXB_B_BTXBD7 = RXB1D7;
     RXB_B_BST_BR_R = RXB1CONbits.RXRTRRO;
     RXB_B_BTXBSIDL = RXB1SIDL;
     RXB_B_BTXBSIDH = RXB1SIDH;
	 RXB_B_BTXBDLC = RXB1DLC;
     RXB1CONbits.RXFUL = 0;
     PIR3bits.RXB1IF = 0;
    } 

   // Ricerca tipo di messaggio ricevuto
   for (i = 0 ; i < CAN_OPEN_RX_END ; i++)
    {
     if ( RXB_B [i].TXBSIDL == RXB_B_BTXBSIDL && RXB_B [i].TXBSIDH == RXB_B_BTXBSIDH )
      {
       RXB_B [i].TXBD0 = RXB_B_BTXBD0;
       RXB_B [i].TXBD1 = RXB_B_BTXBD1;
       RXB_B [i].TXBD2 = RXB_B_BTXBD2;
       RXB_B [i].TXBD3 = RXB_B_BTXBD3;
       RXB_B [i].TXBD4 = RXB_B_BTXBD4;
       RXB_B [i].TXBD5 = RXB_B_BTXBD5;
       RXB_B [i].TXBD6 = RXB_B_BTXBD6;
       RXB_B [i].TXBD7 = RXB_B_BTXBD7;
	   RXB_B [i].TXBDLC = RXB_B_BTXBDLC;
       RXB_B [i].ST_B.IN  = 1;
       RXB_B [i].ST_B.R_R = RXB_B_BST_BR_R;                       
       break;
      }
    } 
    
   // Overflow buffer 
   if (COMSTAT & 0xC0)
    { 
     COMSTATbits.RXB0OVFL   = 0;
     COMSTATbits.RXB1OVFL   = 0;
    }      

	CANCON &= 0xF1;		//clear CANCON.WIN bits
	TempCANSTAT &= 0x0E;
	CANCON |= TempCANSTAT;
	CANCON &=0xF1;
	CANCON |= TempCANCON;

}

//***************************************************//
//Write information to EEPROM                       //
//***************************************************//
void WriteEEprom (unsigned char EEPROM_address,unsigned char EEPROM_data)
{
  while (EECON1bits.WR);  //wait for write cycle to complete
  
  EEADR = EEPROM_address;
  EEDATA = EEPROM_data;
  EECON1bits.EEPGD = 0;
  EECON1bits.CFGS = 0;
  EECON1bits.WREN = 1;
  INTCONbits.GIE = 0;
  EECON2 = 0x55;
  EECON2 = 0xAA;
  EECON1bits.WR = 1;
  INTCONbits.GIE = 1;
  EECON1bits.WREN = 0;
}

//***************************************************//
// Wait for PDO 4F8 with config data during BOOT period
//***************************************************//
void WaitConfigurationData (void)
{
unsigned int Id_p,flash = 0;
unsigned long int counter;
unsigned char i,valid = FALSE;

 StatoUnita        = CAN_STATE_BOOTUP;
 CANCON 	= 0x80;		//initialize BUS
 while (CANSTATbits.OPMODE2 == 0); // wait for the module to enter configuration mode
 
 BRGCON1 	= CAN_BAUD_125K;
 BRGCON2 	= 0xBF;
 BRGCON3 	= 0x07;
 CIOCON 	= 0x20;  	//gi:CAN IO pin
 IPR3 		= 0x3;		//interrupt priority
 PIE3 		= 0x3;		//RXB0,RXB1 ints

 // BOOT MSG WITH PARAMETERS
 Id_p	= BOOTUP_MSG*0x20;				//4F8
 RXB_B [CAN_OPEN_IdNet].TXBSIDH = (Id_p  >> 8) & 0xFF;
 RXB_B [CAN_OPEN_IdNet].TXBSIDL = Id_p & 0xE0;
 RXB_B [CAN_OPEN_IdNet].ST_B.IN = 0;

 RXF0SIDH = RXB_B [CAN_OPEN_IdNet].TXBSIDH;
 RXF0SIDL = RXB_B [CAN_OPEN_IdNet].TXBSIDL;
 RXB0CONbits.RXM0 = 1;
 RXB1CONbits.RXM0 = 1;

// Unused extended identifiers and filters
 RXM0SIDH = 0xFF;
 RXM0SIDL = 0xFF;
 RXM0EIDH = 0x00;
 RXM0EIDL = 0x00;     
 RXM1SIDH = 0xFF;
 RXM1SIDL = 0xFF;
 RXM1EIDH = 0x00;
 RXM1EIDL = 0x00;
 RXF0EIDL = 0;RXF0EIDH = 0;
 RXF1EIDL = 0;RXF1EIDH = 0;
 RXF2EIDL = 0;RXF2EIDH = 0;
 RXF3EIDL = 0;RXF3EIDH = 0;
 RXF4EIDL = 0;RXF4EIDH = 0;
 RXF5EIDL = 0;RXF5EIDH = 0;
 RXF1SIDH = RXF0SIDH;
 RXF1SIDL = RXF0SIDL;
 RXF2SIDH = RXF0SIDH;
 RXF2SIDL = RXF0SIDL;
 RXF3SIDH = RXF0SIDH;
 RXF3SIDL = RXF0SIDL;
 RXF4SIDH = RXF0SIDH;
 RXF4SIDL = RXF0SIDL;
 RXF5SIDH = RXF0SIDH;
 RXF5SIDL = RXF0SIDL;

 CANCON &= 0x0F;
 while (CANSTATbits.OPMODE2 == 1); // wait for the module to enter normal mode

 INTCONbits.PEIE = 1;		// Enable peripheral interrupts
 INTCONbits.GIE = 1;		// Enable all interrupts

  Id_p	 = BOOT_REPLY;				//3F8
  Id_p  <<=5;
  TXB0SIDH 	= (Id_p  >> 8) & 0xFF;
  TXB0SIDL 	= Id_p & 0xE0;
  TXB0DLC	= 6;
  TXB0D0	= 0;
  TXB0D1	= 0;
  TXB0D2	= 0;
  TXB0D3	= 0;
  TXB0D4	= 0;
  TXB0D5	= 0;
  counter	= 0 ;  
  flash 	= 0;

  do 
	{								//wait here until configuration is sent
    _asm clrwdt _endasm
	PORTE  = 0x02;
    if (counter++ >= 80000)
     	{
	    PORTD ^= 0xFF;
	    PORTC ^= 0xFF;
	    counter = 0;
	 	}

    if (RXB_B [CAN_OPEN_IdNet].ST_B.IN)		//NMT COB-ID=x4F8
		{
		RXB_B [CAN_OPEN_IdNet].ST_B.IN=0;
		Id = RXB_B [CAN_OPEN_IdNet].TXBD0;
		if (Id <= 0x0F)
			{
			valid=TRUE;
			WriteEEprom (EEPROM_ID,Id);
			WriteEEprom (EEPROM_CAN_BAUDRATE,RXB_B[CAN_OPEN_IdNet].TXBD1);
			WriteEEprom (EEPROM_HEART_BEAT,RXB_B[CAN_OPEN_IdNet].TXBD2);
			WriteEEprom (EEPROM_HEART_BEAT+1,RXB_B[CAN_OPEN_IdNet].TXBD3);
			WriteEEprom (EEPROM_SYNC_TIME,RXB_B[CAN_OPEN_IdNet].TXBD4);
			WriteEEprom (EEPROM_DEBOUNCE_RATE,RXB_B[CAN_OPEN_IdNet].TXBD5);
			//
			TXB0D0	 = RXB_B [CAN_OPEN_IdNet].TXBD0;
			TXB0D1	 = RXB_B [CAN_OPEN_IdNet].TXBD1;
			TXB0D2	 = RXB_B [CAN_OPEN_IdNet].TXBD2;
			TXB0D3	 = RXB_B [CAN_OPEN_IdNet].TXBD3;
			TXB0D4	 = RXB_B [CAN_OPEN_IdNet].TXBD4;
			TXB0D5	 = RXB_B [CAN_OPEN_IdNet].TXBD5;
			}
		else						//invalid Id, reply once with 0s
			{
			for (i=0 ; i <= 2 ;i++)
				{
				for ( ; TXB0CONbits.TXREQ ; ); 
				TXB0CONbits.TXREQ = 1;
				}
			}
		}

	} while (!valid);


	counter=0;
	flash = 0xFF;
	PORTD = 0xFF;
	PORTC = 0xFF;

	for (;;)	// no return from here!!!
		{
		_asm clrwdt _endasm
		do {counter++; } while (counter <= 50000);
		counter=0;
		PORTC = flash;
		PORTD = flash;
	 	flash <<= 1;
		flash &= 0xFE;
	 	if (!flash) flash = 0xFF;
		if (TXB0CONbits.TXREQ == 0) 
			TXB0CONbits.TXREQ = 1;
		}


}
//***************************************************//
// Inizializzazione micro
//***************************************************//
void
init_cip ( void )   
{
 unsigned char i,j,baud_rate;
 struct longid Id_p;

 StatoUnita        = CAN_STATE_INITIALISING;
 
 // inizializzazione porte
 ADCON0 = 0x00;
 ADCON1 = 0x07;		//gi: all digital ports
 CMCON  = 0x07;		//gi: comparator OFF
 CCP1CON = 0x00;	//gi: CCP modules off

 TRISA = 0xFF;
// TRISB = 0x8B;		//RB0, RB1 = KEYPAD, RB4..RB7 = ROWS KEYPAD
 TRISB = 0x0B;		//RB0, RB1 = KEYPAD, RB4..RB7 = ROWS KEYPAD
 TRISC = 0;			//LEDS OUT
 TRISD = 0;			//LEDs OUT
 TRISE = 0x0; 		//RE0, RE1, RE2 = LED & KEYPAD COMMON
 PORTA = 0;
 PORTB = 0;
 PORTC = 0;
 PORTD = 0;
 PORTE = 0;

 row_count = 3;
 ReadKeypad();	// read key states
 if (KEY_PAD_NEW[3].col_5 && KEY_PAD_NEW[3].col_6)		//2 buttons pressed with common RE2
	WaitConfigurationData();
 
 EEADR = EEPROM_ID;EECON1bits.EEPGD = 0;EECON1bits.RD = 1;
 Id = EEDATA;

 EEADR = EEPROM_HEART_BEAT;EECON1bits.EEPGD = 0;EECON1bits.RD = 1;
 heartbeat_rate.high_byte = EEDATA;
 heartbeat_count.high_byte = EEDATA;

 EEADR = EEPROM_HEART_BEAT+1;EECON1bits.EEPGD = 0;EECON1bits.RD = 1;
 heartbeat_rate.low_byte = EEDATA;
 heartbeat_count.low_byte = EEDATA;

 EEADR = EEPROM_DEBOUNCE_RATE;EECON1bits.EEPGD = 0;EECON1bits.RD = 1;
 debounce_period = (EEDATA+1)/2;	//debounce period given in 10ms, adjust for 21ms cycle
 debounce_count =  (EEDATA+1)/2;

/*-------------- debug --------------
 Id=3; //debug
 baud_rate = 2;
 heartbeat_rate.high_byte = 3; //debug
 heartbeat_count.high_byte = 3;
 heartbeat_rate.low_byte = 0x0E8; //debug
 heartbeat_count.low_byte = 0x0E8;
 debounce_period = 0x03; //debug
 debounce_count = 0x03;
-------------- debug --------------
*/

   
 EEADR = EEPROM_CAN_BAUDRATE;EECON1bits.EEPGD = 0;EECON1bits.RD = 1;
 baud_rate = EEDATA;

 switch (baud_rate)			//translate baud rate number to BRGCOM1
 	{
	 case 1:
	 	baud_rate = CAN_BAUD_500K;
	 	break;
	 case 2:
	 	baud_rate = CAN_BAUD_250K;
	 	break;
	 case 3:
	 	baud_rate = CAN_BAUD_125K;
	 	break;
	 case 4:
	 	baud_rate = CAN_BAUD_100K;
	 	break;
	 case 5:
	 	baud_rate = CAN_BAUD_50K;
	 	break;
	 case 6:
	 	baud_rate = CAN_BAUD_20K;
	 	break;
	 default:
	 	baud_rate = CAN_BAUD_250K;
	}

 SSPSTAT        = 0;		//gi: NO SPI
 SSPCON1        = 0;		//gi: 
 SSPCON2        = 0;		//gi:

 // ---------- Dati in Input -------
 // Receive PDO - ON LEDS (20xH)
 Id_p.Id_low 	= Id;				//low, high: to get around compiler problems...
 Id_p.Id_high	= 2;
 Id_p.Idword  <<=5;
 RXB_B [CAN_OPEN_PDO1].TXBSIDH = (Id_p.Idword  >> 8) & 0xFF;  //TXBSIDH<SD10....SD3>
 RXB_B [CAN_OPEN_PDO1].TXBSIDL = Id_p.Idword & 0xE0;	  //TXBSIDL<SD2...SD0>,<EXIDE>=0=standard id
 RXB_B [CAN_OPEN_PDO1].ST_B.STATO_TX_B = 0;

 // Receive PDO - Blink LEDS (30xH)
 Id_p.Id_low	= Id ;
 Id_p.Id_high	= 3;
 Id_p.Idword  <<=5;
 RXB_B [CAN_OPEN_PDO2].TXBSIDH = (Id_p.Idword  >> 8) & 0xFF;
 RXB_B [CAN_OPEN_PDO2].TXBSIDL = Id_p.Idword & 0xE0;
 RXB_B [CAN_OPEN_PDO2].ST_B.STATO_TX_B = 0;

 // Dati recezione dati di gestione rete
 RXB_B [CAN_OPEN_IdNet].TXBSIDH = 0x00;
 RXB_B [CAN_OPEN_IdNet].TXBSIDL = 0x00;
 RXB_B [CAN_OPEN_IdNet].ST_B.STATO_TX_B = 0;

 // start CANBUS
 CANCON 	= 0x30;					// ERRATA, go through disable mode before config....?
 while (CANSTATbits.OPMODE0 == 0);	// wait for the module to enter disable mode

 CANCON 	= 0x80;		//gi:bit 7-5: Configuration mode,ABAT=0 = normal operation 
 while (CANSTATbits.OPMODE2 == 0); // wait for the module to enter configuration mode
 
 BRGCON1 	= baud_rate;
 BRGCON2 	= 0xBF;
 BRGCON3 	= 0x07;

 CIOCON 	= 0x20;  	//gi:CAN IO pin
 IPR3 		= 0x3;		//gi: interrupt priority
 PIE3 		= 0x3;		//gi: RXB0,RXB1 ints
 PIR3		= 0x04;
 
// Init filters
 RXM0SIDH = 0xFF;
 RXM0SIDL = 0xFF;
 RXM0EIDH = 0x00;
 RXM0EIDL = 0x00;
     
 RXM1SIDH = 0xFF;
 RXM1SIDL = 0xFF;
 RXM1EIDH = 0x00;
 RXM1EIDL = 0x00;
 RXF0EIDL = 0;RXF0EIDH = 0;
 RXF1EIDL = 0;RXF1EIDH = 0;
 RXF2EIDL = 0;RXF2EIDH = 0;
 RXF3EIDL = 0;RXF3EIDH = 0;
 RXF4EIDL = 0;RXF4EIDH = 0;
 RXF5EIDL = 0;RXF5EIDH = 0;
 RXB0CONbits.RXM0 = 1;
 RXB0CONbits.RXB0DBEN = 1;
 RXB1CONbits.RXM0 = 1;
    
 RXF0SIDH = RXB_B [CAN_OPEN_PDO1].TXBSIDH;
 RXF0SIDL = RXB_B [CAN_OPEN_PDO1].TXBSIDL;
 RXF1SIDH = RXB_B [CAN_OPEN_PDO2].TXBSIDH;
 RXF1SIDL = RXB_B [CAN_OPEN_PDO2].TXBSIDL;
 RXF2SIDH = RXB_B [CAN_OPEN_IdNet].TXBSIDH;
 RXF2SIDL = RXB_B [CAN_OPEN_IdNet].TXBSIDL;

 // Dati non usati
 RXF3SIDH = RXF2SIDH;
 RXF3SIDL = RXF2SIDL;
 RXF4SIDH = RXF2SIDH;
 RXF4SIDL = RXF2SIDL;
 RXF5SIDH = RXF2SIDH;
 RXF5SIDL = RXF2SIDL;

 CANCON = 0x20;						// ERRATA, go through disable mode before normal....?
 CANCON = 0x00;						// Fine inizializzazione
 while (CANSTATbits.OPMODE2 == 1); 	// wait for the module to enter normal mode

 // Dati trasmissione (180+Id)
 Id_p.Id_low  = Id + 0x80;			//make sure high bits are cleared
 Id_p.Id_high = 1;

 Id_p.Idword  <<=5;
 TXB_B [CAN_OPEN_IdTx].TXBSIDH = (Id_p.Idword  >> 8) & 0xFF;
 TXB_B [CAN_OPEN_IdTx].TXBSIDL = Id_p.Idword & 0xE0;
 TXB_B [CAN_OPEN_IdTx].TXBDLC  = 8; 		//max possible number of rows in key_pad    
 TXB_B [CAN_OPEN_IdTx].ST_B.STATO_TX_B = 0;

 // Error Protocol (heartbeat, boot) (Id + 0x700)
 Id_p.Id_low    = Id;
 Id_p.Id_high   = 0x7;
 Id_p.Idword  <<=5;
 TXB_B [CAN_OPEN_IdErr].TXBSIDH = (Id_p.Idword  >> 8) & 0xFF;
 TXB_B [CAN_OPEN_IdErr].TXBSIDL = Id_p.Idword & 0xE0;
 TXB_B [CAN_OPEN_IdErr].TXBDLC  = 0x01;
 TXB_B [CAN_OPEN_IdErr].TXBD0  = 0x0;
 TXB_B [CAN_OPEN_IdErr].TXBD1  = 0x0;
 TXB_B [CAN_OPEN_IdErr].TXBD2  = 0x0;
 TXB_B [CAN_OPEN_IdErr].TXBD3  = 0x0;
 TXB_B [CAN_OPEN_IdErr].TXBD4  = 0x0;
 TXB_B [CAN_OPEN_IdErr].TXBD5  = 0x0;
 TXB_B [CAN_OPEN_IdErr].TXBD6  = 0x0;
 TXB_B [CAN_OPEN_IdErr].TXBD7  = 0x0;
 TXB_B [CAN_OPEN_IdErr].ST_B.STATO_TX_B = 0;

 // Emergency Protocol(80H)
 Id_p.Id_low  = Id + 0x80;
 Id_p.Id_high = 0;
 Id_p.Idword  <<=5;
 TXB_B [CAN_OPEN_IdEMCY].TXBSIDH = (Id_p.Idword  >> 8) & 0xFF;
 TXB_B [CAN_OPEN_IdEMCY].TXBSIDL = Id_p.Idword & 0xE0;
 TXB_B [CAN_OPEN_IdEMCY].TXBDLC  = 0x05;
 TXB_B [CAN_OPEN_IdEMCY].ST_B.STATO_TX_B = 0;

 // Sdo in uscita - not used (580H)
 Id_p.Id_low    = Id + 0x80;
 Id_p.Id_high	= 5;
 Id_p.Idword  <<=5;							// function-code = 1011...
 TXB_B [CAN_OPEN_IdSdoTx].TXBSIDH = (Id_p.Idword  >> 8) & 0xFF;
 TXB_B [CAN_OPEN_IdSdoTx].TXBSIDL = Id_p.Idword & 0xE0;
 TXB_B [CAN_OPEN_IdSdoTx].TXBDLC  = 0x08;
 TXB_B [CAN_OPEN_IdSdoTx].ST_B.STATO_TX_B = 0;

 T0CON = 0b11000101;		//timer0 on, 8 bit, internal,prescale 1:64
 TMR0L = 0x0 - Timer0tick_ms;

 T1CON = 0b10110101;			//timer1 RD16=on,prescale=8,t1psc=off,no ext sync,internal clk,tmr1 on
 T1.T1_int = Timer1tick_ms;
 TMR1H = T1.T1high_byte;
 TMR1L = T1.T1low_byte;

 INTCONbits.PEIE = 1;		// Enable peripheral interrupts
 INTCONbits.GIE = 1;		// Enable all interrupts
 StatoUnita = CAN_STATE_PREOPERATIONAL;
 LEDs_on = 0;				//leds intensity counter
 Next_Group = 0;
 check_keypad_now = FALSE;  //slow down keypad reads until all 3 groups LEDS are processed 
 test_error_now = FALSE;
 for(i=0	; i<MAX_ROWS	; i++)
	{
	KEY_PAD_NEW[i].All_Col = 0; //recently read keypad
	KEY_PAD_PREV[i].All_Col = 0; //previous keypad states
	KEY_PAD_SENT[i].All_Col = 0; //last sent keypad states
	}
 DEBOUNCE_FLAG = OFF;

 for (i=0	; i<MAX_LED_ROWS	; i++)
	{
	LEDs[i]		= 0;
	BlinkLEDs[i]	= 0;
	BlinkMask[i]	= 0;
 }
 row_count = 0;
 mask.common_mask=ON;
 ultimo_out = 0;
 error_persistancy_count = ERROR_DEBOUNCE;
 NON_error_persistancy_count = NON_ERROR_COUNT;
 SendBoot();
 CanOut ();
}


//***************************************************//
// Send emergency in case of bus errors
//***************************************************//
void CheckBusError(void)
{ 
 // ---- Errori di trasmissione 
 if ((COMSTATbits.TXBO & 0xF8) > 0) // Severe errors on the bus
  	{
    if (!bus_passive)
        {
         TXB_B [CAN_OPEN_IdEMCY].TXBD0 = 0x10;	//generic error
         TXB_B [CAN_OPEN_IdEMCY].TXBD1 = 0x00;
         TXB_B [CAN_OPEN_IdEMCY].TXBD1 = 0x80;  //error registry
         TXB_B [CAN_OPEN_IdEMCY].ST_B.OUT = TRUE;
         bus_passive = TRUE;
        }
	else
         bus_passive = FALSE;
  	}
}
