/* ------------------------------------------------------------------------------------------------------ */
// Active CANOpen node controller of a Hydraulic Valve
// Programmer:	Gino Isla for Lambda Sistemi, Milano
// Created: 	09-10-2006	Version 1.0
// Tools:		MPLAB v. 7.40, C18 v. 3.04
// Updates:		
// Version:	1.01.00	|	18-04-07	|	gi	|	Corrected index when calling Copy_RAM_to_RAM()
// Version:			|				|	 	|	
/* ------------------------------------------------------------------------------------------------------ */


/* ------------------------------------------- Include files: ------------------------------------------- */
#include "pic_include.h"		/* include correct symbols for this processor */
#include "config.h"
#include "can.h"
#include "prototype.h"
#include "application_data.h"
#include "DS408_errors.DEF"
#include "dict.h"
#include "Profile_data.h"
//#include "Controller.h"
//#include "config_data.inc"
//
/* ------------------------------------------- Configuration bits --------------------------------------- */

//#define UnitTest

#pragma udata program_data				//paging to solve problem with too large data space
//volatile M_TXB_BUFF TXB_B[MAX_CAN_OUT];
//volatile M_TXB_BUFF RXB_B[MAX_CAN_IN];
M_TXB_BUFF TXB_B[MAX_CAN_OUT];
M_TXB_BUFF RXB_B[MAX_CAN_IN];

extern int vpoc_set_point;			//test
extern int vpoc_actual_value;		//test
extern M_ERROR_REGISTER uCO_DevErrReg;	//this is OD object 0x1001,0
extern M_MULTIPLEXOR multiplexor;
extern unsigned char T0_1ms;

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
//
//#pragma udata temp_data
//unsigned char SDO_RX_HOLD_DATA[128];
////
//#pragma udata ramp_up_data
//unsigned char mspd_ramp_up_buffer[128];
////
//#pragma udata ramp_down_data
//unsigned char mspd_ramp_down_buffer[128];
////
//#pragma udata ramp_left_data
//unsigned char mspd_ramp_left_buffer[128];
////
//#pragma udata ramp_right_data
//unsigned char mspd_ramp_right_buffer[128];
////
extern unsigned char mspd_ramp_up_buffer[128];
extern unsigned char mspd_ramp_down_buffer[128];
extern unsigned char mspd_ramp_left_buffer[128];
extern unsigned char mspd_ramp_right_buffer[128];



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
//test	TXB_B [CAN_OPEN_IdEMCY].TXBD6 = 0x00;
//test	TXB_B [CAN_OPEN_IdEMCY].TXBD7 = 0x00;

	TXB_B [CAN_OPEN_IdEMCY].TXBD6 = vpoc_set_point; //test
	TXB_B [CAN_OPEN_IdEMCY].TXBD7 = vpoc_actual_value; //test

	TXB_B [CAN_OPEN_IdEMCY].TXBD6 = (vpoc_actual_value  >> 8) & 0xFF;
	TXB_B [CAN_OPEN_IdEMCY].TXBD7 = (vpoc_actual_value & 0xFF); //test

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
	vpoc_set_point = RXB_B [CAN_OPEN_PDO1].TXBD1 + RXB_B [CAN_OPEN_PDO1].TXBD0 * 0x100;	//vpoc_set_point is an integer
	demand_value_generator();


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
	dev_status_word.Ready = 1;

	//...other actions after device goes into operation....

}
//***************************************************//
//Render the device available for operation
//***************************************************//
void device_disable (void)
{
	dev_status_word.Ready = 0;

	//...other actions after device goes into operation....

}
//***************************************************//
//Performs all the necessary calculations and controls for
//the demand value.
//This procedure is entered when the set_point PDO is received and
//everytime during the idle-main loop
//***************************************************//
void demand_value_generator(void)
{
unsigned char direction;
unsigned char changespeed;

	getActualValue();		//Sebastiano, this procedure is in "Controller.c"
	if (vpoc_set_point == vpoc_actual_value)	
	{
		dev_status_word.CM_targetReached = 1;
		dev_status_word.CM_rampRunning = 0;
		//also here consider
		//  dev_status_word.hold?;
		//	dev_status_word.deviceModeActiveEnable?;
		return;
	}

	dev_status_word.CM_targetReached = 0;			//we're not at target
	dev_status_word.CM_rampRunning = 1;

	if (vpoc_actual_value < 0) 		//determine where we are
		direction = NEGATIVE;
	else
		direction = POSITIVE;

	if ((direction == POSITIVE) && (vpoc_set_point > vpoc_actual_value))		//determine in which direction we're going
	{
		changespeed = ACCELERATION;
		direction = POSITIVE;
	}
	else if ((direction == POSITIVE) && (vpoc_set_point < vpoc_actual_value))
	{
		changespeed = DECELERATION;
		direction = NEGATIVE;
	}
	else if ((direction == NEGATIVE) && (vpoc_set_point < vpoc_actual_value))
	{
		changespeed = ACCELERATION;
		direction = NEGATIVE;
	}
	else if ((direction == NEGATIVE) && (vpoc_set_point > vpoc_actual_value))
	{
		changespeed = DECELERATION;
		direction = POSITIVE;
	}

//	vpoc_demand_value  = vpoc_set_point;		//WARNING: vpoc_set_point changes only with PDO
	vpoc_demand_value  = vpoc_actual_value;		//WARNING: vpoc_set_point changes only with PDO

LIMITS:
	dev_status_word.CM_limitTouched = 0;
	if (vpoc_demand_value <  vpoc_demand_lower_limit)
	{
		vpoc_demand_value  =  vpoc_demand_lower_limit;
		dev_status_word.CM_limitTouched = 1;
	}
	else if (vpoc_demand_value > vpoc_demand_upper_limit)
	{
		vpoc_demand_value = vpoc_demand_upper_limit;
		dev_status_word.CM_limitTouched = 1;
	}

SCALING:
	vpoc_demand_value += vpoc_demand_scaling_offset;	//6323  
	vpoc_demand_value *= vpoc_demand_scaling_factor.numerator; 	//6322
	vpoc_demand_value /= vpoc_demand_scaling_factor.denominator; //6322

RAMP:
	switch (vpoc_demand_ramp_type) //(6330) 
	{
		case NO_RAMP_0:
			break;		//no ramp active, vpoc_demand_value unmodified

		case LINEAR_1:
			if (direction == POSITIVE)
				vpoc_demand_value += vpoc_ramp_acceleration_time;		//????? acceleration_time ?????
			else
				vpoc_demand_value -= vpoc_ramp_acceleration_time;
			break;

		case LINEAR_2:
			if (changespeed == ACCELERATION)
			{
				if (direction == POSITIVE)
					vpoc_demand_value += vpoc_ramp_acceleration_time;		//????? acceleration_time ?????
				else if (direction == NEGATIVE)
					vpoc_demand_value -= vpoc_ramp_acceleration_time;		//????? acceleration_time ?????
			}
			else //DECELERATION
				if (direction == POSITIVE)	//negative moving in a positive direction
					vpoc_demand_value += vpoc_ramp_deceleration_time;		//????? acceleration_time ?????
				else if (direction == NEGATIVE)
					vpoc_demand_value -= vpoc_ramp_deceleration_time;		//????? acceleration_time ?????				
			break;

		case LINEAR_3:
			if (changespeed == ACCELERATION)
			{
				if (direction == POSITIVE)
					vpoc_demand_value += vpoc_ramp_acceleration_time_pos;		//????? acceleration_time ?????
				else if (direction == NEGATIVE)
					vpoc_demand_value -= vpoc_ramp_acceleration_time_neg;		//????? acceleration_time ?????
			}
			else //DECELERATION
				if (direction == POSITIVE)	//negative moving in a positive direction
					vpoc_demand_value += vpoc_ramp_deceleration_time_pos;		//????? acceleration_time ?????
				else if (direction == NEGATIVE)//positive moving in negative direction
					vpoc_demand_value -= vpoc_ramp_deceleration_time_neg;		//????? acceleration_time ?????				

			break;

		case SINE_SQR_4:
		case PROF_GEN_5:
		case PROF_GEN_6:
		default:
			; //differentiated values for each quadrant not implemented;

	}//switch
}

//***************************************************//
// Start execution                                   //
//***************************************************//
void main ( )
{ 
// Use uCO_DevErrReg for error codes (accessible RO by SDOs)

  init_cip ();
  uCO_DevErrReg.GENERIC = TRUE;
  ERROR_CODE.err_high = 0;
  ERROR_CODE.err_low = 0;
  SendEmergency ();		//generic error
  uCO_DevErrReg.GENERIC = FALSE;

  // Main loop
  for (;;)
  {
    _asm clrwdt _endasm

    CanOut();										// Send outstanding CAN messages if any
    CanIn ();					    				// Unpack CAN messages if any
	Control();


	if (T0_1ms == 1)							// 1 ms tasks
	{
		T0_1ms = 0;	  						//Reset tmr0
		demand_value_generator();						//if we are moving, continue to travel the ramp until target is reached
		TimingControl ();

		if ((--heartbeat_count.count) == 0)
		{
			SendHeartbeat ();
//SendEmergency ();	//test
			heartbeat_count.count = heartbeat_rate.count;
			CheckBusError();
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



