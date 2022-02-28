// Programmer: Gino Isla for Lambda Sistemi, Milano
// Intialiazation procedures for a CANOpen node
// Created: 22-11-2004
//

#include "pic_include.h"		/* include correct symbols for this processor */
#include "prototype.h"
#include "application_data.h"
#include "can.h"
#include "Profile_data.h"
// PWM INIT
#include "RT_INIT.h"


/* ------------------------------------------- Globals -------------- */
//extern volatile struct M_TXB_BUFF TXB_B[MAX_CAN_OUT];
//extern volatile M_TXB_BUFF TXB_B[MAX_CAN_OUT];
//extern volatile M_TXB_BUFF RXB_B[MAX_CAN_IN];
extern M_TXB_BUFF TXB_B[MAX_CAN_OUT];
extern M_TXB_BUFF RXB_B[MAX_CAN_IN];

extern char StatoUnita;
extern unsigned int Id;
extern M_HEARTBEAT heartbeat_count;
extern M_HEARTBEAT heartbeat_rate;
extern M_TIMER_1_CONVERT T1;
M_LONGID Id_p;
M_LONG_TO_ARRAY lta;
extern M_ERROR_REGISTER uCO_DevErrReg;
extern M_ERROR_CODE ERROR_CODE;
extern unsigned int uCO_COMM_NMTE_HeartBeat;	//DO 1017,0
extern unsigned char z_bytes_for_xfer; 			//number of bytes to transfer to/from the external EEPROM page
extern unsigned char z_EEPROM_bank;				//group of bytes (ramp o,1,2,3), each bank is 128 bytes
extern unsigned char z_EEPROM_page;				//page within the bank where write starts
extern unsigned char z_EEPROM_offset;			// offset within the page (for single varaibles)
extern unsigned int Index;
extern unsigned char SubIndex;
extern unsigned char SDO_Process;
extern unsigned char toggle;
//-------------------------------
extern unsigned char DEBOUNCE_FLAG;
extern unsigned char debounce_count;
extern unsigned char debounce_period;
extern unsigned char Next_Group;
extern unsigned char LEDs [6];
extern unsigned char BlinkLEDs [6];
extern unsigned char BlinkMask [6];
extern unsigned char LEDs_on;
extern unsigned char ultimo_out;
extern unsigned char check_keypad_now; 
extern unsigned char test_error_now; 
extern unsigned char error_persistancy_count;
extern unsigned char NON_error_persistancy_count;

extern rom unsigned char rCO_DevIdentityIndx;
extern unsigned long rCO_DevVendorID; 
extern unsigned long rCO_DevProductCode;
extern unsigned long rCO_DevRevNo;
extern unsigned long rCO_DevSerialNo;
//
extern unsigned char SDO_RX_HOLD_DATA[128];
extern unsigned char mspd_ramp_up_buffer[128];
extern unsigned char mspd_ramp_down_buffer[128];
extern unsigned char mspd_ramp_left_buffer[128];
extern unsigned char mspd_ramp_right_buffer[128];

extern rom unsigned char RAMP_UP_VALUES[];
extern rom unsigned char RAMP_DOWN_VALUES[];
extern rom unsigned char RAMP_LEFT_VALUES[];
extern rom unsigned char RAMP_RIGHT_VALUES[];
extern rom unsigned char rCO_DEVDESCRIPTION[];
//
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
const rom char node_id = 3;
const rom char baud = 2;
const rom char heartbit_rate[] = {0xE8,4};
const rom char sync_time = 0; //not used
const rom char debounce = 3;

//EE data accessible through Object Dictionary:
const rom char vendor_id []={0x12,0x34,0x56,0x78};
const rom char prod_code [] = {0x12,0x34,0x56,0x78};
const rom char rev_num [] = {0,0,0,1};
const rom char serial [] = {1,2,3,4};
#pragma romdata
		
//#pragma interrupt InterruptRxCAN save=PROD,section(".tmpdata") gi: redundant in MPLAB 7.40
//#pragma interrupt InterruptRxCAN

//#pragma code isrcode=0x0008
//void InterruptHandler(void)
//{
// _asm   goto InterruptRxCAN   _endasm 
//}
//
//#pragma code
//***************************************************//
// low priority Interrupts
//***************************************************//
//void InterruptRxCAN(void)
//{ 
#pragma interruptlow low_isr

#pragma code low_vector=0x0018
void interrup_at_low_vector (void)
{
 _asm   goto low_isr  _endasm 
}

#pragma code
//***************************************************//
// Gestione recezione messaggio CAN
//***************************************************//
void low_isr (void)
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
//EE_SPI_mode
//***************************************************//
void EE_SPI_mode (void)
{
	SSPCON1 &= CON1_SSPEN_dis;
	SSPCON1 |= CON1_CKP_hi;
	SSPSTAT &= STAT_CKE_Xidl;
	SSPCON1 |= CON1_SSPEN_ena;
}

//***************************************************//
// Enable writes to external EEPROM
//***************************************************//
void write_enable (void)
{
 unsigned char rxdata;

 EE_CS = FALSE;									//SELECT
 rxdata = Send_data_EX_EEPROM(WRI_ENA);			//WREN
 SSPCON1 &= CON1_CKP_lo;
 EE_CS = TRUE;									//Deselect
 SSPCON1 |= CON1_CKP_hi;
}

//***************************************************//
//Test the WIP (write in progress) bit until it is reset
//***************************************************//
void busy_test (void)
{
 unsigned char stat_reg = 0b0000001;

 while (stat_reg && 0b0000001)
 {
 	EE_CS = FALSE;									//SELECT
 	stat_reg = Send_data_EX_EEPROM(RDSR);			//read status reg
 	stat_reg = Send_data_EX_EEPROM(0);				//
 	EE_CS = TRUE;									//Deselect
 }
}

//***************************************************//
//Send data to external EEPROM 25LC640.
//NOTE: caller enables Chip Select
//***************************************************//
unsigned char Send_data_EX_EEPROM (unsigned char b)
{
unsigned char o;

 if (SSPCON1bits.WCOL)	//if there was a collision, clear it
	SSPCON1bits.WCOL = FALSE;
 SSPBUF = b;

 while (!SSPSTATbits.BF);
 
 o = SSPBUF;
 return(o); 
}
//***************************************************//
//Write data to external EEPROM 25LC640.
// Parameter passed: buffer
//Parameters to be filled by caller:
//		z_EEPROM_bank => the (virtual) bank to read from
//		z_EEPROM_page => 
//		z_page_offset => 
//		z_bytes_for_xfer => numer of bytes to transfer
//***************************************************//
unsigned char Write_to_EX_EEPROM (unsigned char * buffer)
{
 unsigned char rxdata,k,page, baseaddr,high,low,i = 0;

 EE_SPI_mode();

 high  = z_EEPROM_bank / 2;
 low = ((z_EEPROM_bank & 1) * 0x80) + z_EEPROM_page * 0x20 + z_EEPROM_offset;	//address 

 while (i < z_bytes_for_xfer)
 {
 	write_enable();
	EE_CS = FALSE;								//enable
	rxdata = Send_data_EX_EEPROM(WRITE);		//Write sequence
	rxdata = Send_data_EX_EEPROM(high);			//address
 	rxdata = Send_data_EX_EEPROM(low);			//address

	for (k=0 ; k < 32 && i < z_bytes_for_xfer ; k++,i++)	//write 1 page (32 bytes) at a time
		rxdata = Send_data_EX_EEPROM(buffer[i]);			//

	SSPCON1bits.CKP=FALSE;
	EE_CS = TRUE;
	SSPCON1bits.CKP=TRUE;
	busy_test();
	low += k;						//this happens for z_bytes_for_xfer > 0x20
 }
 EE_CS = TRUE;

 return(TRUE);
}

//***************************************************//
//Read data from external EEPROM 25LC640.
//Accepts single or multiple writes. For single write (multi = FALSE), caller passes high address, low addres, data byte. For
//multiple writes (multi = TRUE), caller passes all parameters in global variables. The multiple write starts at the page boundary
// (low address = 0) of the corresponding bank (bank * 128).
//Parameters to be filled by caller:
//		z_bytes_for_xfer => numer of bytes to read;
//		z_EEPROM_bank => the (virtual) bank to read from
// data will be placed in the array pointed by buffer
//***************************************************//
unsigned char Read_from_EX_EEPROM (unsigned char * buffer)
{
 unsigned char high,low,rxdata,i;

 high  = z_EEPROM_bank / 2;
 low = ((z_EEPROM_bank & 1) * 0x80) + z_EEPROM_page * 0x20 + z_EEPROM_offset;	//address 

 EE_SPI_mode();
 EE_CS = FALSE;

 rxdata = Send_data_EX_EEPROM(READ);
 rxdata = Send_data_EX_EEPROM(high);					//send high address
 rxdata = Send_data_EX_EEPROM(low);						//send low address

	for (i=0 ; i < z_bytes_for_xfer ; i++)
	{
 		rxdata = Send_data_EX_EEPROM(0);				//send dummy char
		buffer[i] = SSPBUF;								//
	}
 	EE_CS = TRUE; 

	return(TRUE);
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
 EE_CS = FALSE;			//start SPI EEPROM
 EE_CS = TRUE;			//start SPI EEPROM
 SSPCON1 = 0;			//
 SSPCON1 = 0x31;		//enables serial ports, idle clk states, Master, SCK = fosc/16
 SSPSTAT = 0;
 EE_SPI_mode(); 

#ifdef INIT_EXT_EEPROM
	EEPROM_initializer();		//initializes data in external EEPROM
#endif

Load_Profile_data_from_external_EEPROM();

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
   
 ReadEEprom_OnBoard(EEPROM_CAN_BAUDRATE);
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

//============Received messages===========================================
 // Receive PDO 20X - go_to_set_point
 Id_p.Id_low 	= Id;				//low, high: to get around compiler problems...
 Id_p.Id_high	= 2;
 Id_p.Idword  <<=5;
 RXB_B [CAN_OPEN_PDO1].TXBSIDH = (Id_p.Idword  >> 8) & 0xFF;  //TXBSIDH<SD10....SD3>
 RXB_B [CAN_OPEN_PDO1].TXBSIDL = Id_p.Idword & 0xE0;	  //TXBSIDL<SD2...SD0>,<EXIDE>=0=standard id
 RXB_B [CAN_OPEN_PDO1].ST_B.STATO_TX_B = 0;

 // Receive PDO - Blink LEDS 30X
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
 // Trasnmit PDO (180+Id) keypressed
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

 RCONbits.IPEN = 1;			//Sebastiano: Enable interrupts and interrupts priorities
 INTCONbits.GIEH = 1;
 INTCONbits.GIEL = 1;
//IPR3 = 0x3;				//CAN high interrupt priority
 IPR3 = 0;					//CAN low interrupt priority
 PIE3 = 0x3;				//CAN interrupts allowed in mode 0

 ultimo_out = 0;
// INTCONbits.PEIE = 1;		// Enable peripheral interrupts
// INTCONbits.GIE = 1;		// Enable all interrupts

 StatoUnita = CAN_STATE_PREOPERATIONAL;	//this is the software state
 dev_status_word.status_word = 0;		//this is the hardware state
 SDO_Process = CAN_NOTHING;
 uCO_DevErrReg.ebyte = 0;		//no errors
 ERROR_CODE.err_high = 0;
 ERROR_CODE.err_low = 0;
 INIT_RT();
 SendBoot();
 CanOut ();

}
