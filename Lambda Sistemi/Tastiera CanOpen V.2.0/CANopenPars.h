// Harware dependencies for CANopen node

// Software version 1.00
#define VERSION4 '1' 
#define VERSION3 '.' 
#define VERSION2 '0'
#define VERSION1 '0'

// Baud Rate  -> Fosc=20Mhz
//#define BRGCON1_125KBAUD 0x87
//#define BRGCON1_250KBAUD 0x83
//#define BRGCON1_500KBAUD 0x81
//#define BRGCON1_1MBAUD   0x80

// Baud Rate  -> Fosc=25Mhz
#define BRGCON1_125KBAUD 0x89	// 10 BRPs
#define BRGCON1_250KBAUD 0x85
//#define BRGCON1_500KBAUD 0x81 // these 2 are not exact multiples
//#define BRGCON1_1MBAUD   0x80





#define ERRORE_BUS_P     0x02
#define ERRORE_BUS_O     0x01

#define TIMER_LEDVERDE_MIN    2
#define TIMER_LEDVERDE_MAX    4
#define TIMER_LEDVERDE_L_MIN  50
#define TIMER_LEDVERDE_L_MAX  100


#define MSG_EXPLIC            0x01
#define MSG_POLLED            0x02
#define MSG_CHANGE            0x10
#define MSG_CHANGE_OR_CYCLIC  0x04


#define MAX_CAN_UOT  4
#define MAX_CAN_IN   4

// Puntatori ai buffer can
enum CAN_OPEN_TX
{ 
  CAN_OPEN_IdTx = 0,  	// Stato ingressi Pdo
  CAN_OPEN_IdLF,		// Life guard
  CAN_OPEN_IdErr,		// Messaggio di errore
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
  CAN_OPEN_IdRx = 0,	// Stato Uscite
  CAN_OPEN_IdNet,		// Gestore di rete
  CAN_OPEN_IdLfIn,		// Richiesta life guard
  CAN_OPEN_IdSdoRx,		// Risposta sdo
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



#define LedOk  PORTAbits.RA0
#define LedKo  PORTAbits.RA1

#define T0RLOAD  105

#define EEPROM_POS_ENCODER			0
#define EEPROM_AD_CONVERTER			1
#define EEPROM_POS_CON_ENCODER		5
#define EEPROM_CAN_TRAS_TYPE		6
#define EEPROM_CAN_TRAS_INHIBIT		7
#define EEPROM_TRASMIT_PDO 			8


/* ------------------------------------------- Prototipi: -------------- */
void InterruptRxCAN(void);
void controllo_encoder(void);
void ScritturaOut (void);
void AggSPI (void);
void AggTM0 (void);
void LetturaIn(void);
void VerIo(void);
void CanUot(void);
void CanOpen (void);
void DeviceNet(void);
void init_cip ( void );   
unsigned char ReadRow (char)
