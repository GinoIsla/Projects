// Programmer: Gino Isla for Lambda Sistemi, Milano
// Intialiazation procedures for a CANOpen node
// Created: 06-06-2004
//

#include "jpic_include.h"		/* include correct symbols for this processor */
#include "jprototype.h"
#include "japplication_data.h"
#include "jcan.h"
#include "jProfile_data.h"
#include "jRT_INIT.h"

/* ------------------------------------------- Globals -------------- */
extern M_TXB_BUFF TXB_B[MAX_CAN_OUT];
extern M_TXB_BUFF RXB_B[MAX_CAN_IN];

extern char StatoUnita;
extern unsigned int Id;
extern M_HEARTBEAT heartbeat_count;
extern M_HEARTBEAT heartbeat_rate;
extern unsigned int sendPDO_count;
extern M_TIMER_1_CONVERT T1;
extern M_LONGID Id_p;
M_LONG_TO_ARRAY lta;
extern M_ERROR_REGISTER uCO_DevErrReg;
extern M_ERROR_CODE ERROR_CODE;
extern unsigned int uCO_COMM_NMTE_HeartBeat;	//DO 1017,0
extern M_PDO_ENABLE PDO_enable;

extern unsigned int Index;
extern unsigned char SubIndex;
extern unsigned char SDO_Process;
extern unsigned char toggle;
extern unsigned char z_number_of_nodes;		//2000,0 number of receiver nodes for potentiometer values
extern unsigned char z_sw_node;				//2000,1 receiver of jIO_switch1_value
extern unsigned char z_node_1;				//2000,2 receiver of jIO_Potentiometer_1 value
extern unsigned char z_node_2;				//2000,3 receiver of jIO_Potentiometer_2 value
extern unsigned char z_node_3;				//2000,4 receiver of jIO_Potentiometer_3 value
extern unsigned char z_node_4;				//2000,5 receiver of jIO_Potentiometer_4 value
extern unsigned char next_PDO;
extern unsigned char z_master;				//master or slave indication
extern unsigned char z_master_initializing;	//initializing process
extern unsigned char z_slave_count;
extern unsigned char next_PDO;
extern unsigned char ultimo_out;

//-------------------------------

extern rom unsigned char rCO_DevIdentityIndx;
extern unsigned long rCO_DevVendorID; 
extern unsigned long rCO_DevProductCode;
extern unsigned long rCO_DevRevNo;
extern unsigned long rCO_DevSerialNo;
//
extern unsigned char SDO_RX_HOLD_DATA[128];

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

// default parameters
#pragma romdata eeprom=0xF00000
//const rom char init_pars []= {4,2,3,0xE8,0,3};
const rom char node_id = 127;
const rom char baud = 2;
const rom char heartbit_rate[] = {0xE8,4};
const rom char sync_time = 0; //not used
const rom char debounce = 3;

//EE data accessible through Object Dictionary:
const rom char vendor_id []={0x12,0x34,0x56,0x78};
const rom char prod_code [] = {0x12,0x34,0x56,0x78};
const rom char rev_num [] = {0,0,0,1};
const rom char serial [] = {1,2,3,4};
const rom char num_nodes = 5;		//offset 22
const rom char switches = 1;
const rom char pot1 = 2;
const rom char pot2 = 3;
const rom char pot3 = 4;
const rom char pot4 = 5;
const rom char pdo_rate[] = {0xE8,3};
#pragma romdata
		
//#pragma interrupt InterruptRxCAN save=PROD,section(".tmpdata") gi: redundant in MPLAB 7.40
#pragma interrupt InterruptRxCAN

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

// Get CAN message
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

   // Find the type of message received and store it
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
//Write information to on-board EEPROM                       //
//***************************************************//
void WriteEEprom_OnBoard (unsigned char EEPROM_address,unsigned char EEPROM_data)
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
//Read information from EEPROM                       //
//***************************************************//
unsigned char ReadEEprom_OnBoard (unsigned char EEaddress)
{
  EECON1bits.WREN = 0; //clear write bit just in case
  while (EECON1bits.RD);  //wait for read cycle to complete, just in case

  EEADR = EEaddress;
  EECON1bits.EEPGD = 0;
  EECON1bits.CFGS = 0;
  EECON1bits.RD = 1;
  return (EEDATA);
}

//***************************************************//
// Initialization
//***************************************************//
void init_cip ( void )   
{
 unsigned char i,j,baud_rate;
 int k;
 StatoUnita        = CAN_STATE_INITIALISING;
 
 ADCON0 = 0x00;
 ADCON1 = 0x0F;		//gi: all digital ports
 CCP1CON = 0x00;	//gi: CCP modules off

 PORTA = 0;
 PORTB = 0;
 PORTC = 0;
 TRISA = 0xFF;
 TRISB = 0x0B;		//RB0, RB1 = KEYPAD, RB2= CANTX, RB3= CANRX = set, RB4..RB7 = ROWS KEYPAD
 TRISC = 0x10;		//RC7=CS (out), RC4=SDI port in, RC3=SCK = SPI clock out (should be input according to datasheet)

#ifdef _p18f4580
 CMCON  = 0x07;		//gi: comparator OFF - not in used
 PORTD = 0;
 PORTE = 0;
 TRISD = 0;
 TRISE = 0;
#endif

 INTCON = 0;			//initialize, DISABLE INTERRUPTS while processor initializes

 SSPSTAT        = 0;		//NO SPI
 SSPCON1        = 0; 
 SSPCON2        = 0;

 ReadEEprom_OnBoard(EEPROM_NODE_ID);
 Id = EEDATA;

 ReadEEprom_OnBoard(EEPROM_HEART_BEAT);
 heartbeat_rate.low_byte = EEDATA;
 heartbeat_count.low_byte = EEDATA;

 ReadEEprom_OnBoard(EEPROM_HEART_BEAT+1);
 heartbeat_rate.high_byte = EEDATA;
 heartbeat_count.high_byte = EEDATA;

 lta.b0 = ReadEEprom_OnBoard(EEPROM_Vendor_Id+0);
 lta.b1 = ReadEEprom_OnBoard(EEPROM_Vendor_Id+1);
 lta.b2 = ReadEEprom_OnBoard(EEPROM_Vendor_Id+2);
 lta.b3 = ReadEEprom_OnBoard(EEPROM_Vendor_Id+3);
 rCO_DevVendorID = lta.l;

 lta.b0 = ReadEEprom_OnBoard(EEPROM_Product_code+0);
 lta.b1 = ReadEEprom_OnBoard(EEPROM_Product_code+1);
 lta.b2 = ReadEEprom_OnBoard(EEPROM_Product_code+2);
 lta.b3 = ReadEEprom_OnBoard(EEPROM_Product_code+3);
 rCO_DevProductCode = lta.l;

 lta.b0 = ReadEEprom_OnBoard(EEPROM_revision_numb+0);
 lta.b1 = ReadEEprom_OnBoard(EEPROM_revision_numb+1);
 lta.b2 = ReadEEprom_OnBoard(EEPROM_revision_numb+2);
 lta.b3 = ReadEEprom_OnBoard(EEPROM_revision_numb+3);
 rCO_DevRevNo = lta.l;

 lta.b0 = ReadEEprom_OnBoard(EEPROM_serial_numb+0);
 lta.b1 = ReadEEprom_OnBoard(EEPROM_serial_numb+1);
 lta.b2 = ReadEEprom_OnBoard(EEPROM_serial_numb+2);
 lta.b3 = ReadEEprom_OnBoard(EEPROM_serial_numb+3);
 rCO_DevSerialNo = lta.l;
 
 uCO_COMM_NMTE_HeartBeat = heartbeat_rate.count;	//object 1017,0
   
 baud_rate = ReadEEprom_OnBoard(EEPROM_CAN_BAUDRATE);
 z_number_of_nodes = ReadEEprom_OnBoard(EEPROM_number_rx_nodes);
 z_sw_node= ReadEEprom_OnBoard(EEPROM_SWITCH1);
 z_node_1 = ReadEEprom_OnBoard(EEPROM_POT_RX_ID1);
 z_node_2 = ReadEEprom_OnBoard(EEPROM_POT_RX_ID2);
 z_node_3 = ReadEEprom_OnBoard(EEPROM_POT_RX_ID3);
 z_node_4 = ReadEEprom_OnBoard(EEPROM_POT_RX_ID4);
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

//============Received messages===========================================
 // Receive PDO 20X 
 Id_p.Id_low 	= Id;				//low, high: to get around compiler problems...
 Id_p.Id_high	= 2;
 Id_p.Idword  <<=5;
 RXB_B [CAN_OPEN_PDO1].TXBSIDH = (Id_p.Idword  >> 8) & 0xFF;  //TXBSIDH<SD10....SD3>
 RXB_B [CAN_OPEN_PDO1].TXBSIDL = Id_p.Idword & 0xE0;	  //TXBSIDL<SD2...SD0>,<EXIDE>=0=standard id
 RXB_B [CAN_OPEN_PDO1].ST_B.STATO_TX_B = 0;

 // Receive PDO
 Id_p.Id_low	= Id ;
 Id_p.Id_high	= 3;
 Id_p.Idword  <<=5;
 RXB_B [CAN_OPEN_PDO2].TXBSIDH = (Id_p.Idword  >> 8) & 0xFF;
 RXB_B [CAN_OPEN_PDO2].TXBSIDL = Id_p.Idword & 0xE0;
 RXB_B [CAN_OPEN_PDO2].ST_B.STATO_TX_B = 0;

 // Receive SDO (601H - 67F)
 Id_p.Id_low 	= Id;				//low, high: get around compiler problems...
 Id_p.Id_high	= 6;
 Id_p.Idword  <<=5;
 RXB_B [CAN_OPEN_IdSdoRx].TXBSIDH = (Id_p.Idword  >> 8) & 0xFF;  //TXBSIDH<SD10....SD3>
 RXB_B [CAN_OPEN_IdSdoRx].TXBSIDL = Id_p.Idword & 0xE0;	  //TXBSIDL<SD2...SD0>,<EXIDE>=0=standard id
 RXB_B [CAN_OPEN_IdSdoRx].ST_B.STATO_TX_B = 0;

 // Recieve Network Managemente - NMT - (start, stop, pre-op, etc.)
 RXB_B [CAN_OPEN_IdNet].TXBSIDH = 0x00;
 RXB_B [CAN_OPEN_IdNet].TXBSIDL = 0x00;
 RXB_B [CAN_OPEN_IdNet].ST_B.STATO_TX_B = 0;

//============Tansmission messages===========================================
 // as master trasnmit the first RPDO 20X
 Id_p.Id_low  = Id;				//make sure high bits are cleared
 Id_p.Id_high = 2;
 Id_p.Idword  <<=5;
 TXB_B [CAN_OPEN_IdTx].TXBSIDH = (Id_p.Idword  >> 8) & 0xFF;
 TXB_B [CAN_OPEN_IdTx].TXBSIDL = Id_p.Idword & 0xE0;
 TXB_B [CAN_OPEN_IdTx].TXBDLC  = 2; 		//potetiometer values are signed ints
 TXB_B [CAN_OPEN_IdTx].ST_B.STATO_TX_B = 0;

 // Error Protocol (heartbeat, boot) (Id + 0x700)
 Id_p.Id_low    = Id;
 Id_p.Id_high   = 0x7;
 Id_p.Idword  <<=5;
 TXB_B [CAN_OPEN_IdErr].TXBSIDH = (Id_p.Idword  >> 8) & 0xFF;
 TXB_B [CAN_OPEN_IdErr].TXBSIDL = Id_p.Idword & 0xE0;
 TXB_B [CAN_OPEN_IdErr].TXBDLC  = 1;
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
 TXB_B [CAN_OPEN_IdEMCY].TXBDLC  = 8;
 TXB_B [CAN_OPEN_IdEMCY].ST_B.STATO_TX_B = 0;

 // Sdo out (580H - 5FF)
 Id_p.Id_low    = Id + 0x80;
 Id_p.Id_high	= 5;
 Id_p.Idword  <<=5;							// function-code = 1011...
 TXB_B [CAN_OPEN_IdSdoTx].TXBSIDH = (Id_p.Idword  >> 8) & 0xFF;
 TXB_B [CAN_OPEN_IdSdoTx].TXBSIDL = Id_p.Idword & 0xE0;
 TXB_B [CAN_OPEN_IdSdoTx].TXBDLC  = 8;
 TXB_B [CAN_OPEN_IdSdoTx].COMMAND.b = 0;
 TXB_B [CAN_OPEN_IdSdoTx].INDEX = 0;
 TXB_B [CAN_OPEN_IdSdoTx].SUB_INDEX = 0;
 TXB_B [CAN_OPEN_IdSdoTx].B0 = 0;
 TXB_B [CAN_OPEN_IdSdoTx].B1 = 0;
 TXB_B [CAN_OPEN_IdSdoTx].B2 = 0;
 TXB_B [CAN_OPEN_IdSdoTx].B3 = 0;
 TXB_B [CAN_OPEN_IdSdoTx].ST_B.STATO_TX_B = 0;
//=======================================================

 // start CAN module
 CANCON 	= 0x30;					// ERRATA, go through disable mode before config....?
 while (CANSTATbits.OPMODE0 == 0);	// wait for the module to enter disable mode

 CANCON 	= 0x80;					//gi:bit 7-5: Configuration mode,ABAT=0 = normal operation 
 while (CANSTATbits.OPMODE2 == 0); 	// wait for the module to enter configuration mode
 
 BRGCON1 	= baud_rate;
 BRGCON2 	= 0xBF;
 BRGCON3 	= 0x07;

 CIOCON 	= 0x20;  	//gi:CAN IO pin
 ECANCON	= 0x0;		//bit 7,6 = 0 = legacy mode 0, other bits unused in this mode

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
 RXB1CONbits.RXM0 = 1;
 RXB0CONbits.RXB0DBEN = 1;
    
 RXF0SIDH = RXB_B [CAN_OPEN_PDO1].TXBSIDH;
 RXF0SIDL = RXB_B [CAN_OPEN_PDO1].TXBSIDL;

 RXF1SIDH = RXB_B [CAN_OPEN_PDO2].TXBSIDH;
 RXF1SIDL = RXB_B [CAN_OPEN_PDO2].TXBSIDL;

 RXF2SIDH = RXB_B [CAN_OPEN_IdNet].TXBSIDH;
 RXF2SIDL = RXB_B [CAN_OPEN_IdNet].TXBSIDL;

 RXF3SIDH = RXB_B [CAN_OPEN_IdSdoRx].TXBSIDH;
 RXF3SIDL = RXB_B [CAN_OPEN_IdSdoRx].TXBSIDL;


 // Unused data
 RXF4SIDH = RXF3SIDH;
 RXF4SIDL = RXF3SIDL;
 RXF5SIDH = RXF3SIDH;
 RXF5SIDL = RXF3SIDL;

 CANCON = 0x20;						// ERRATA, go through disable mode before normal....?
 CANCON = 0x00;						// End init
 while (CANSTATbits.OPMODE2 == 1); 	// wait for the module to enter normal mode

 T0CON = 0b11000101;		//timer0 on, 8 bit, internal,prescale 1:64
 TMR0L = 0x0 - Timer0tick_ms;

 T1CON = 0b10110101;			//timer1 RD16=on,prescale=8,t1psc=off,no ext sync,internal clk,tmr1 on
 T1.T1_int = Timer1tick_ms;
 TMR1H = T1.T1high_byte;
 TMR1L = T1.T1low_byte;

 ultimo_out = 0;
 INTCONbits.PEIE = 1;		// Enable peripheral interrupts
 INTCONbits.GIE = 1;		// Enable all interrupts
 IPR3 = 0;					//CAN low interrupt priority
 PIE3 = 0x3;				//CAN interrupts allowed in mode 0

 SDO_Process = CAN_NOTHING;
 uCO_DevErrReg.ebyte = 0;		//no errors
 ERROR_CODE.err_high = 0;
 ERROR_CODE.err_low = 0;
 PDO_enable.PDO_byte = PDOS_ENABLED;
 jIO_switch1_value = 0;
 jIO_Potentiometer_1 = 0;
 jIO_Potentiometer_2 = 0;
 jIO_Potentiometer_3 = 0;
 jIO_Potentiometer_4 = 0;
 next_PDO = 1;
 sendPDO_count = PDO_COUNT;
 uCO_DevErrReg.GENERIC = TRUE;
 ERROR_CODE.err_high = 0;
 ERROR_CODE.err_low = 0;
  //SendEmergency ();		//generic error
 uCO_DevErrReg.GENERIC = FALSE;
 INIT_RT();
 z_master = MASTER_OR_SLAVE;			// initialization finishes depending on master or slave

 if (z_master)
 {
 	StatoUnita = CAN_STATE_OPERATIONAL;
	z_master_initializing = TRUE;
	z_slave_count = z_number_of_nodes;
	initialize_slaves();
 }
 else
 {
	StatoUnita = CAN_STATE_PREOPERATIONAL;
 	SendBoot();
 	CanOut ();
 }

}
