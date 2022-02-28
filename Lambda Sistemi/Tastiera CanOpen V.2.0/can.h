// Versione can main
#define VERSIONE4 '1' 
#define VERSIONE3 '.' 
#define VERSIONE2 '0'
#define VERSIONE1 '0'

#define	TRUE	1
#define FALSE	0
#define	ON		1
#define OFF		0

/* Baud Rate  -> Fosc=25Mhz,Tbit = 1+8+8+8=25tq
*
* We set PropSeg to 8, PhaseSeg1 to 8 and PhaseSeg2 to 8 which gives the bit
* time 1+8+8+8=25 tq and the sampling point (1+8+8)/(1+8+8+8) = 68%.
* With prescaler 0, we get 500 kbps.
* Also, we use SJW = 2 tq, SAM=1
*
* 500 kbps: 01 000000    1 0 111 111    0 0 000 111    40 bf 07
* 250 kbps: 01 000001    1 0 111 111    0 0 000 111    41 bf 07
* 125 kbps: 01 000011    1 0 111 111    0 0 000 111    43 bf 07
*/

/*Baud rate triplets for 25 MHz chrystal */
#define CAN_BAUD_1000K   -
#define CAN_BAUD_500K    0x40	// (0xbf, 0x07)
#define CAN_BAUD_250K    0x41	// (0xbf, 0x07)
#define CAN_BAUD_125K    0x43	// (0xbf, 0x07)
#define CAN_BAUD_100K    0x44	// (0xbf, 0x07)
#define CAN_BAUD_50K     0x49	// (0xbf, 0x07)
#define CAN_BAUD_20K     0x58	// (0xbf, 0x07)


#define MAX_CAN_OUT  4
#define MAX_CAN_IN   4

#define	CAN_STATE_BOOTUP			0	//STATES FOR HEARTBEAT
#define	CAN_STATE_STOPPED			4
#define	CAN_STATE_OPERATIONAL		5
#define	CAN_STATE_PREOPERATIONAL	127
#define	CAN_STATE_INITIALISING		131

#define	CAN_REQUEST_START			1
#define	CAN_REQUEST_STOP			2
#define	CAN_REQUEST_ENTER_PREOP		128
#define	CAN_REQUEST_RESET			129
#define	CAN_REQUEST_RESET_COMMS		130


#define BOOTUP_MSG			0x4F8
#define	BOOT_REPLY			0x3F8

// Puntatori ai buffer can
enum CAN_OPEN_TX
{ 
  CAN_OPEN_IdTx = 0,  	// PDOs
  CAN_OPEN_IdErr,		// Life guard - Heartbeat
  CAN_OPEN_IdEMCY,		// Messaggio di errore
  CAN_OPEN_IdSdoTx,		// Risposta Sdo
  CAN_OPEN_TX_END
};

enum DEV_NET_TX
{ 
  DEV_NET_IdSvExp = 0,
  DEV_NET_IdSvCic,
  DEV_NET_IdSvAck,
  DEV_NET_TX_END  
};

enum CAN_OPEN_RX
{ 
  CAN_OPEN_PDO1 = 0,	// LEDs PDO
  CAN_OPEN_PDO2,		// LED blink PDO
  CAN_OPEN_IdNet,		// Gestore di rete
  CAN_OPEN_IdErrIn,		// Richiesta life guard
  CAN_OPEN_RX_END
};

enum DEV_NET_RX
{ 
  DEV_NET_IdSvUER = 0,
  DEV_NET_IdSvMSR,
  DEV_NET_IdMsPCC,
  DEV_NET_IdMsAck,
  DEV_NET_RX_END  
};


// Buffer di uscita CAN
union  STAT_TX_B 
{
  struct
    {
     unsigned :5;
     unsigned R_R:1;  // Ricevuta una richiesta da remoto
     unsigned IN:1;   // Ricevuto nuovo messaggio
     unsigned OUT:1;  // In trasmissione
    };
    
  struct
    {
     char STATO_TX_B;  
    };
};

    
union  TXB_BUFF 
{
  struct // Struttura recezione standard
    {
     unsigned char TXBD7;
     unsigned char TXBD6;
     unsigned char TXBD5;
     unsigned char TXBD4;
     unsigned char TXBD3;
     unsigned char TXBD2;
     unsigned char TXBD1;
     unsigned char TXBD0;

     unsigned char TXBDLC;
     unsigned char TXBSIDL;
     unsigned char TXBSIDH;

     struct STAT_TX_B ST_B;
    };
  struct  // Struttura recezione Sdo
    {
     unsigned char B3;
     unsigned char B2;
     unsigned char B1;
     unsigned char B0;
     unsigned char SUB_INDEX;
     unsigned int  INDEX;
     unsigned char COMMAND;
    };
};

struct  LED_mask
			{
			unsigned undefined:7;
			unsigned common_mask:1;
			};


//#define LedOk  PORTAbits.RA0
//#define LedKo  PORTAbits.RA1

//#define T0RLOAD  105

#define	EEPROM_ID					0
#define EEPROM_CAN_BAUDRATE			1
#define EEPROM_HEART_BEAT			2 //,3 (2 bytes)
#define EEPROM_SYNC_TIME			4
#define EEPROM_DEBOUNCE_RATE		5

#define	GROUP0	0
#define	GROUP1	1
#define	GROUP2	2
#define	GROUP3	3
#define MAX_LED_GROUP 3
#define MAX_LED_ROWS 6
#define	MAX_ROWS	7
#define	ERROR_DEBOUNCE	5	//error persistancy = 105ms (21ms *5)
#define	NON_ERROR_COUNT 10	//leaky bucket counter, empty at 30%

//timer 0
#define Fosc 25000000
#define T0_PreScale 64
#define T1_PreScale 8
#define Milisec 1000
//#define Milisec 1000/8
#define	HALF_SECOND 500
#define Timer0tick_ms  ((Fosc)/(4*T0_PreScale*Milisec))-32	//(-32 lost accuracy in the division)
#define Timer1tick_ms 	0 - ((Fosc)/(4*T1_PreScale*Milisec))		//

union timer1_convert
	{
		unsigned int T1_int;
		
		struct
		{
		unsigned char T1low_byte;
		unsigned char T1high_byte;
		};
	};

union Key_Row
	{
	struct 
		{
		unsigned col_0:1;
		unsigned col_1:1;
		unsigned col_2:1;
		unsigned col_3:1;
		unsigned col_4:1;
		unsigned col_5:1;
		unsigned col_6:1;
		unsigned col_7:1;
		 };
	unsigned char All_Col;
	};
	
union heartbeat
	{
		unsigned int count;
		
		struct
		{
		unsigned char low_byte;
		unsigned char high_byte;
		};
	};

union	longid
	{
		unsigned int Idword;
		struct
		{
			unsigned char Id_low;
			unsigned char Id_high;
		};
	};
/* ------------------------------------------- Prototipi: -------------- */
void InterruptRxCAN(void);
void CheckBusError(void);
void CanOut(void);
void CanIn (void);
void init_cip ( void );   
void Delay1KTCYx ( unsigned char);
void ReadKeypad (void);
unsigned char Keypad_Changed (void);
unsigned char Error_found(void); 
void SendKeypad (void);
void WaitConfigurationData (void);
void WriteEEprom (unsigned char,unsigned char);
void SendBoot (void);
void SendEmergency (char,char);
void SendHeartbeat (void);
unsigned char GetPortBits (void);
void TreatBlinkMask (void);
void Stop_unit(void);
