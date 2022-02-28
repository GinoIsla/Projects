/* ------------------------------------------------------------------------------------------------------ */
// Active CANOpen node controller of a JOYSTICK
// Programmer:	Gino Isla for Lambda Sistemi, Milano
// Created: 	04-06-2007	Version 1.0 
// Tools:		MPLAB v. 7.40, C18 v. 3.04
// Updates:		
/* ------------------------------------------------------------------------------------------------------ */


/* ------------------------------------------- Include files: ------------------------------------------- */
#include "jpic_include.h"		/* include correct symbols for this processor */
#include "jconfig.h"
#include "jcan.h"
#include "jprototype.h"
#include "japplication_data.h"
#include "jDS401_errors.DEF"
#include "jdict.h"
#include "jProfile_data.h"
//
/* ------------------------------------------- Configuration bits --------------------------------------- */

//#define UnitTest

#pragma udata program_data				//paging to solve problem with too large data space
M_TXB_BUFF TXB_B[MAX_CAN_OUT];
M_TXB_BUFF RXB_B[MAX_CAN_IN];
M_PDO_ENABLE PDO_enable;
M_ERROR_REGISTER uCO_DevErrReg;	//this is OD object 0x1001,0
M_MULTIPLEXOR multiplexor;
extern unsigned char T0_1ms;

M_LONGID Id_p;
char StatoUnita = 0;				// Stato unita
unsigned int Id;
unsigned int Index;
unsigned char SubIndex;
unsigned char SDO_Process;
unsigned char SDO_RX_INDEX;
unsigned char toggle;
unsigned int  downloadbytes;
M_TIMER_1_CONVERT T1;
M_HEARTBEAT heartbeat_count;
M_HEARTBEAT heartbeat_rate;
unsigned int sendPDO_count;
M_ERROR_CODE ERROR_CODE;				//dictionary object 0x604E	---> SEE DS-408 SECTION 5.2, p.22 for additional errros
unsigned char ten_millisec_count = 10;
unsigned char ultimo_out;
char   bus_passive = 0;
unsigned int z_SDO_timer;				//SDO sanity time out

//global variables for writing to external EEPROM
unsigned char z_bytes_for_xfer; 		//number of bytes to transfer to/from the external EEPROM page
unsigned char z_EEPROM_bank;			//group of bytes (ramp o,1,2,3), each bank is 128 bytes
unsigned char z_EEPROM_page;			//page within the bank where write starts
unsigned char z_EEPROM_offset;			// offset within the page (for single varaibles)

//nodes ids where pot values are sent
unsigned char z_number_of_nodes;		//2000,0 number of receiver nodes for potentiometer values
unsigned char z_sw_node;				//2000,1 receiver of jIO_switch1_value
unsigned char z_node_1;					//2000,2 receiver of jIO_Potentiometer_1 value
unsigned char z_node_2;					//2000,3 receiver of jIO_Potentiometer_2 value
unsigned char z_node_3;					//2000,4 receiver of jIO_Potentiometer_3 value
unsigned char z_node_4;					//2000,5 receiver of jIO_Potentiometer_4 value
unsigned char z_master;					//master or slave indication
unsigned char z_master_initializing;	//initializing process
unsigned char z_slave_count;
unsigned char next_PDO;
//***************************************************//
// Send emergency in case of bus errors if necessary
//***************************************************//
void CheckBusError(void)
{ 
 // ---- Transmission error
 	if ((COMSTAT & 0xF8) > 0) // Severe errors on the bus must be reported.
  	{
		uCO_DevErrReg.COMMUNICATIONS=TRUE;
    	if (!bus_passive)
    	{
			ERROR_CODE.err_high = 0x81;
			ERROR_CODE.err_low = 0x20;
			SendEmergency();		//generic error
        	bus_passive = TRUE;
    	}
  	}
	else
	{
		bus_passive = FALSE;
		uCO_DevErrReg.COMMUNICATIONS=FALSE;
	}

}

//***************************************************//
// This node is master, send NMT messages to all the 
// slaves in the list
//***************************************************//
void initialize_slaves(void)
{
 if (z_slave_count != 0)
 {
	if (z_slave_count == 1)
	 	TXB_B [CAN_OPEN_IdNet].TXBD1 = z_sw_node;
	else if (z_slave_count == 2)
	 	TXB_B [CAN_OPEN_IdNet].TXBD1 = z_node_1;
	else if (z_slave_count == 3)
	 	TXB_B [CAN_OPEN_IdNet].TXBD1 = z_node_2;
	else if (z_slave_count == 4)
	 	TXB_B [CAN_OPEN_IdNet].TXBD1 = z_node_3;
	else if (z_slave_count == 5)
	 	TXB_B [CAN_OPEN_IdNet].TXBD1 = z_node_4;

 	TXB_B [CAN_OPEN_IdNet].TXBDLC  = 2;
 	TXB_B [CAN_OPEN_IdNet].TXBSIDH = 0x00;		//NMT request
 	TXB_B [CAN_OPEN_IdNet].TXBSIDL = 0x00;
 	TXB_B [CAN_OPEN_IdNet].TXBSIDL = 0x00;
 	TXB_B [CAN_OPEN_IdNet].TXBD0 = CAN_REQUEST_START;
 	TXB_B [CAN_OPEN_IdNet].ST_B.OUT = 1;

	if (--z_slave_count == 0)
		z_master_initializing = FALSE;

 }
}
//***************************************************//
//Scrittura nel bus CAN                              //
//***************************************************//
void CanOut(void)
{
 char i; 


 if (TXB0CONbits.TXREQ) return;
 if (PIR3bits.TXB1IF) PIR3bits.TXB1IF = 0;

 // Look for a message to send
 for (i = ultimo_out ; i < MAX_CAN_OUT ; i++)
  {
   if (TXB_B [i].ST_B.OUT)
    {
     TXB_B [i].ST_B.OUT  = 0;
     TXB0SIDL = TXB_B [i].TXBSIDL;
     TXB0SIDH = TXB_B [i].TXBSIDH;
     TXB0DLC = TXB_B [i].TXBDLC;
     TXB0D0 = TXB_B [i].TXBD0;
     TXB0D1 = TXB_B [i].TXBD1;
     TXB0D2 = TXB_B [i].TXBD2;
     TXB0D3 = TXB_B [i].TXBD3;
     TXB0D4 = TXB_B [i].TXBD4;
     TXB0D5 = TXB_B [i].TXBD5;
     TXB0D6 = TXB_B [i].TXBD6;
     TXB0D7 = TXB_B [i].TXBD7;
     TXB0CONbits.TXREQ = 1;

	 _asm clrwdt _endasm
	 while (TXB0CONbits.TXREQ) ;

	 if (PIR3bits.TXB0IF) PIR3bits.TXB0IF = 0; 
	 ultimo_out = i++;
	 break;
     } 
  }
 if (i >= MAX_CAN_OUT)
   ultimo_out = 0;
}

//***************************************************//
//Prepare BOOT message                              //
//***************************************************//
void SendBoot (void)
  {
	TXB_B [CAN_OPEN_IdErr].TXBD0 = 0;
	TXB_B [CAN_OPEN_IdErr].ST_B.OUT = 1;	  
  }
  //***************************************************//
//Prepare Emergency message                              //
//***************************************************//
void SendEmergency (void)
  {
	TXB_B [CAN_OPEN_IdEMCY].TXBD0 = ERROR_CODE.err_high; 	// (Table 21, p. 9-38)
	TXB_B [CAN_OPEN_IdEMCY].TXBD1 = ERROR_CODE.err_low;
	TXB_B [CAN_OPEN_IdEMCY].TXBD2 = uCO_DevErrReg.ebyte;	// registry (DO 0x1001,0: Error Register (Table 47, p. 9-65)
	TXB_B [CAN_OPEN_IdEMCY].TXBD3 = 0x00;
	TXB_B [CAN_OPEN_IdEMCY].TXBD4 = 0x00;
	TXB_B [CAN_OPEN_IdEMCY].TXBD5 = 0x00;
	TXB_B [CAN_OPEN_IdEMCY].ST_B.OUT = 1;	  
	ERROR_CODE.err_high = 0;				//once reported clear.
	ERROR_CODE.err_low = 0;					// historic error DO (0x1003) not supported
											// uCO_DevErrReg is managed by the caller
  }
  
//***************************************************//
//Prepare HEARTBEAT message                          //
//***************************************************//
void SendHeartbeat (void)
  {
	TXB_B [CAN_OPEN_IdErr].TXBD0 = StatoUnita;
	TXB_B [CAN_OPEN_IdErr].ST_B.OUT = 1;	  
  }

//***************************************************//
//Prepare INIT_SDO_INIT_RESPONSE                     //
//***************************************************//
void Send_Init_Download_resp(int i, unsigned char s)
{
 TXB_B [CAN_OPEN_IdSdoTx].COMMAND.INIT_DOWNLOAD_RESPONSE.scs = SCS_SDO_INIT_DOWNLOAD_RESP;
 TXB_B [CAN_OPEN_IdSdoTx].COMMAND.INIT_DOWNLOAD_RESPONSE.x = 0;
 TXB_B [CAN_OPEN_IdSdoTx].INDEX = i;
 TXB_B [CAN_OPEN_IdSdoTx].SUB_INDEX = s;
 TXB_B [CAN_OPEN_IdSdoTx].ST_B.OUT = 1;
}

//***************************************************//
//Prepare DOWNLOAD_RESPONSE 	                    //
//***************************************************//
void Send_Download_resp(unsigned char t)
{
 TXB_B [CAN_OPEN_IdSdoTx].COMMAND.DOWNLOAD_RESPONSE.scs = SCS_SDO_DOWNLOAD_RESP;
 TXB_B [CAN_OPEN_IdSdoTx].COMMAND.DOWNLOAD_RESPONSE.t = t;
 TXB_B [CAN_OPEN_IdSdoTx].COMMAND.DOWNLOAD_RESPONSE.x = 0;
 TXB_B [CAN_OPEN_IdSdoTx].ST_B.OUT = 1;
}

//***************************************************//
//Prepare INIT_SDO_UPLOAD_RESPONSE                     //
//***************************************************//
void Send_Init_Upload_resp(void)
{
 TXB_B [CAN_OPEN_IdSdoTx].COMMAND.INIT_DOWNLOAD_RESPONSE.scs = CCS_SDO_INIT_UPLOAD_RESP;
 TXB_B [CAN_OPEN_IdSdoTx].ST_B.OUT = 1;
}

//***************************************************//
//Prepare INIT_SDO_UPLOAD_RESPONSE                   //
//***************************************************//
void Send_Upload_Segment(unsigned char n, unsigned char t, unsigned char c)
{
 TXB_B [CAN_OPEN_IdSdoTx].COMMAND.UPLOAD_SEGMT_RESP.scs = SCS_SDO_UPLOAD_SEG_RESP;
 TXB_B [CAN_OPEN_IdSdoTx].COMMAND.UPLOAD_SEGMT_RESP.n = n;
 TXB_B [CAN_OPEN_IdSdoTx].COMMAND.UPLOAD_SEGMT_RESP.t = t;
 TXB_B [CAN_OPEN_IdSdoTx].COMMAND.UPLOAD_SEGMT_RESP.c = c;
 TXB_B [CAN_OPEN_IdSdoTx].ST_B.OUT = 1;
}

//***************************************************//
//Prepare SDO ABORT				                     //
//***************************************************//
void Send_SDO_Abort(int i, unsigned char s, char retcode)
{

M_ABORT abort_code;

	switch	(retcode)
	{
	case	E_SUCCESS:
			abort_code.high = 0x00; abort_code.low = 0;
			return ;

	case	E_TOGGLE:
			abort_code.high = 0x503; abort_code.low = 0;
			break;

	case	E_SDO_TIME:
			abort_code.high = 0x504; abort_code.low = 0;
			break;

	case	E_CS_CMD:
			abort_code.high = 0x504; abort_code.low = 1;
			break;

	case	E_MEMORY_OUT:
			abort_code.high = 0x504; abort_code.low = 5;
			break;

	case	E_UNSUPP_ACCESS:
			abort_code.high = 0x601; abort_code.low = 0;
			break;

	case	E_CANNOT_READ:
			abort_code.high = 0x601; abort_code.low = 1;
			break;

	case	E_CANNOT_WRITE:
			abort_code.high = 0x601; abort_code.low = 2;
			break;

	case	E_OBJ_NOT_FOUND:
			abort_code.high = 0x602; abort_code.low = 0;
			break;

	case	E_OBJ_CANNOT_MAP:
			abort_code.high = 0x604; abort_code.low = 0x41;
			break;

	case	E_OBJ_MAP_LEN:
			abort_code.high = 0x604; abort_code.low = 0x42;
			break;

	case	E_GEN_PARAM_COMP:
			abort_code.high = 0x604; abort_code.low = 0x47;
			break;

	case	E_GEN_INTERNAL_COMP:
			abort_code.high = 0x604; abort_code.low = 0x43;
			break;

	case	E_HARDWARE:
			abort_code.high = 0x606; abort_code.low = 0;
			break;

	case	E_LEN_SERVICE:
			abort_code.high = 0x607; abort_code.low = 0x10;
			break;

	case	E_LEN_SERVICE_HIGH:
			abort_code.high = 0x607; abort_code.low = 0x12;
			break;

	case	E_LEN_SERVICE_LOW:
			abort_code.high = 0x607; abort_code.low = 0x13;
			break;

	case	E_SUBINDEX_NOT_FOUND:
			abort_code.high = 0x609; abort_code.low = 0x11;
			break;

	case	E_PARAM_RANGE:
			abort_code.high = 0x609; abort_code.low = 0x30;
			break;

	case	E_PARAM_HIGH:
			abort_code.high = 0x609; abort_code.low = 0x31;
			break;

	case	E_PARAM_LOW:
			abort_code.high = 0x609; abort_code.low = 0x32;
			break;

	case	E_MAX_LT_MIN:
			abort_code.high = 0x609; abort_code.low = 0x36;
			break;

	case	E_GENERAL:
			abort_code.high = 0x800; abort_code.low = 0;
			break;

	case	E_TRANSFER:
			abort_code.high = 0x800; abort_code.low = 0x20;
			break;

	case	E_LOCAL_CONTROL:
			abort_code.high = 0x800; abort_code.low = 21;
			break;

	case	E_DEV_STATE:
			abort_code.high = 0x800; abort_code.low = 22;
			break;

	case	E_NO_DICTIONARY:
			abort_code.high = 0x800; abort_code.low = 23;
			break;
	}

 TXB_B [CAN_OPEN_IdSdoTx].COMMAND.ABORT_SDO.cs = CS_SDO_ABORT;
 TXB_B [CAN_OPEN_IdSdoTx].COMMAND.ABORT_SDO.x = 0;
 TXB_B [CAN_OPEN_IdSdoTx].INDEX = i;
 TXB_B [CAN_OPEN_IdSdoTx].SUB_INDEX = s;
 TXB_B [CAN_OPEN_IdSdoTx].B0 = abort_code.b1;
 TXB_B [CAN_OPEN_IdSdoTx].B1 = abort_code.b0;
 TXB_B [CAN_OPEN_IdSdoTx].B2 = abort_code.b3;
 TXB_B [CAN_OPEN_IdSdoTx].B3 = abort_code.b2;
 TXB_B [CAN_OPEN_IdSdoTx].ST_B.OUT = 1;
 SDO_Process = CAN_NOTHING;

}

//***************************************************//
// Unpack a CANOpen message                            //
//***************************************************//
void CanIn(void)
{
 char k;
 unsigned int Id_p;

  if (RXB_B [CAN_OPEN_IdNet].ST_B.IN)		//NMT COB-ID=x0000
   {
    RXB_B [CAN_OPEN_IdNet].ST_B.IN = 0;
    
	switch (RXB_B [CAN_OPEN_IdNet].TXBD0)
		{

		case CAN_REQUEST_START:
		{
			if (RXB_B [CAN_OPEN_IdNet].TXBD1 == 0 || RXB_B [CAN_OPEN_IdNet].TXBD1 == Id) // if all or me
			{
				StatoUnita = CAN_STATE_OPERATIONAL;
				device_enable();
			}
		break;
		}
		case CAN_REQUEST_STOP:      // STOP
		{
			if (RXB_B [CAN_OPEN_IdNet].TXBD1 == 0 || RXB_B [CAN_OPEN_IdNet].TXBD1 == Id) // if all or me
			{
				StatoUnita = CAN_STATE_STOPPED;
				device_disable();
			}
		break;
		}
		case CAN_REQUEST_ENTER_PREOP:      // ENTER PREOPERATIONAL
		{
			if (RXB_B [CAN_OPEN_IdNet].TXBD1 == 0 || RXB_B [CAN_OPEN_IdNet].TXBD1 == Id) // if all or me
			{
				StatoUnita = CAN_STATE_PREOPERATIONAL;
				device_disable();
			}
		break;
		}
		case CAN_REQUEST_RESET:      // RESET
		{
			if (RXB_B [CAN_OPEN_IdNet].TXBD1 == 0 || RXB_B [CAN_OPEN_IdNet].TXBD1 == Id) // if all or me
			{
				StatoUnita = CAN_STATE_PREOPERATIONAL;
				device_disable();
				init_cip ();
			}
		break;
		}
		default:;
		}
   }

  if (RXB_B [CAN_OPEN_PDO1].ST_B.IN)		// SEBASTIANO: qui il set point
  {
    RXB_B [CAN_OPEN_PDO1].ST_B.IN = 0;
//	vpoc_set_point = RXB_B [CAN_OPEN_PDO1].TXBD1 + RXB_B [CAN_OPEN_PDO1].TXBD0 * 0x100;	//vpoc_set_point is an integer
//	demand_value_generator();


//	vpoc_actual_value = vpoc_set_point; //test only
	SendEmergency();

//    LEDs[0] 
//    LEDs[1] 
//    LEDs[2] = RXB_B [CAN_OPEN_PDO1].TXBD2;
//    LEDs[3] = RXB_B [CAN_OPEN_PDO1].TXBD3;
//    LEDs[4] = RXB_B [CAN_OPEN_PDO1].TXBD4;
//    LEDs[5] = RXB_B [CAN_OPEN_PDO1].TXBD5;	
  }

  if (RXB_B [CAN_OPEN_PDO2].ST_B.IN)		//blinking
  {
    RXB_B [CAN_OPEN_PDO2].ST_B.IN = 0;
//    BlinkLEDs[0] = RXB_B [CAN_OPEN_PDO2].TXBD0;
//    BlinkLEDs[1] = RXB_B [CAN_OPEN_PDO2].TXBD1;
//    BlinkLEDs[2] = RXB_B [CAN_OPEN_PDO2].TXBD2;
//    BlinkLEDs[3] = RXB_B [CAN_OPEN_PDO2].TXBD3;
//    BlinkLEDs[4] = RXB_B [CAN_OPEN_PDO2].TXBD4;
//    BlinkLEDs[5] = RXB_B [CAN_OPEN_PDO2].TXBD5;
//	for (k=0	; k<6	; k++)					//new blink pattern, clear old one
//		BlinkMask[k] =0;
  }           

  if (RXB_B [CAN_OPEN_IdSdoRx].ST_B.IN)		//SDO
  {
		RXB_B [CAN_OPEN_IdSdoRx].ST_B.IN = 0;

		if (StatoUnita == CAN_STATE_OPERATIONAL)
		{
			treat_SDO (RXB_B [CAN_OPEN_IdSdoRx]);	//pass the message to the dictionary procedures
		}
  }
}

//***************************************************//
//Render the device available for operation
//***************************************************//
void device_enable (void)
{

	//...other actions after device goes into operation....

}
//***************************************************//
//Render the device available for operation
//***************************************************//
void device_disable (void)
{

	//...other actions after device goes into operation....

}

//***************************************************//
//Send PDO with switch positions (with correct polarity)
//***************************************************//
void sendDigitalInputs (void)
{
unsigned char s,t;
typedef union Pot_val
{
	struct
	{
	unsigned char pot_low;
	unsigned char pot_high;
	};
	int	pot_int;
}M_POT_VAL;

M_POT_VAL pot_value;

	t = FALSE;

	if ((next_PDO ==1) && (PDO_enable.SwitchBank1) )
	{
 		Id_p.Id_low  = z_sw_node;
	 	TXB_B [CAN_OPEN_IdTx].TXBDLC  = 1; 		//unsingned char
		pot_value.pot_high = jIO_switch1_value;
		pot_value.pot_high ^= uIOin1Polarity;
		pot_value.pot_low = 0;
		t = TRUE;
	}
	else if (((next_PDO ==2) && PDO_enable.Pot1))
	{
 		Id_p.Id_low  = z_node_1;
		pot_value.pot_int = jIO_Potentiometer_1;
		t = TRUE;
	}
	else if ((next_PDO ==3) && (PDO_enable.Pot2))
	{
 		Id_p.Id_low  = z_node_2;
		pot_value.pot_int = jIO_Potentiometer_2;
		t = TRUE;
	}
	else if ((next_PDO ==4) && (PDO_enable.Pot3))
	{
 		Id_p.Id_low  = z_node_3;
		pot_value.pot_int = jIO_Potentiometer_3;
		t = TRUE;
	}
	else if ((next_PDO ==5) && (PDO_enable.Pot4))
	{
 		Id_p.Id_low  = z_node_4;
		pot_value.pot_int = jIO_Potentiometer_4;
		t = TRUE;
	}

	if (t)
	{
	 	Id_p.Id_high = 2;								//use RPDO1 20X
	 	Id_p.Idword  <<=5;
	 	TXB_B [CAN_OPEN_IdTx].TXBSIDH = (Id_p.Idword  >> 8) & 0xFF;
	 	TXB_B [CAN_OPEN_IdTx].TXBSIDL = Id_p.Idword & 0xE0;
		TXB_B [CAN_OPEN_IdTx].TXBDLC  = 2; 				//signed int
		TXB_B [CAN_OPEN_IdTx].TXBD0 = pot_value.pot_high;
		TXB_B [CAN_OPEN_IdTx].TXBD1 = pot_value.pot_low;
		TXB_B [CAN_OPEN_IdTx].ST_B.OUT = 1;
	}

	if ((++next_PDO) > z_number_of_nodes)
		next_PDO = 1;
}

//***************************************************//
// Start execution                                   //
//***************************************************//
void main ( )
{ 
// Use uCO_DevErrReg for error codes (accessible RO by SDOs)

  init_cip ();

  // Main loop
  for (;;)
  {
    _asm clrwdt _endasm

    CanOut();										// Send outstanding CAN messages if any
    CanIn ();					    				// Unpack CAN messages if any
	Control();

	if (z_master_initializing)
		initialize_slaves();
	else if (next_PDO > 1)
		sendDigitalInputs();

	if (T0_1ms == 1)							// 1 ms tasks
	{
		T0_1ms = 0;	  						//Reset tmr0
		TimingControl ();

		if ((--heartbeat_count.count) == 0)
		{
			SendHeartbeat ();
			heartbeat_count.count = heartbeat_rate.count;
			CheckBusError();
		}	

		if ((StatoUnita == CAN_STATE_OPERATIONAL) && !z_master_initializing)
		{
			if ((--sendPDO_count) == 0)
			{
				sendDigitalInputs();				// start the series of messages, switch and potentiometer values
				sendPDO_count = PDO_COUNT;
			}
		}

		if (SDO_Process |= CAN_NOTHING)
		{
			if (--z_SDO_timer == 0)
			{
				SDO_Process = CAN_NOTHING;
				Send_SDO_Abort(multiplexor.index, multiplexor.sindex, E_SDO_TIME);
			}
		}
	}

  } //for

}



