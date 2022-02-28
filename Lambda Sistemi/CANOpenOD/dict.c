
/*****************************************************************************
 *Software derived from  Microchip CANopen Stack (Dictionary Services)
 *by Gino Isla for Lambda Sistemi, Milano
 * 
 *****************************************************************************/
#include	"application_data.h"
#include	"can.h"
#include	"prototype.h"
#include	"ObjDict.DEF"
#include	"dict.h"
#include	"Profile_data.h"
//#include	"CO_TYPES.H"						// Standard types

//extern volatile M_TXB_BUFF TXB_B[MAX_CAN_OUT];
//extern volatile M_TXB_BUFF RXB_B[MAX_CAN_IN];
extern M_TXB_BUFF TXB_B[MAX_CAN_OUT];
extern M_TXB_BUFF RXB_B[MAX_CAN_IN];

extern unsigned char z_bytes_for_xfer; 			//number of bytes to transfer to/from the external EEPROM page
extern unsigned char z_EEPROM_bank;				//group of bytes (ramp o,1,2,3), each bank is 128 bytes
extern unsigned char z_EEPROM_page;				//page within the bank where write starts
extern unsigned char z_EEPROM_offset;			// offset within the page (for single varaibles)

// This fills some of the the dictionary with data
//++++++++++++++++++++++++++++++++++++++++++++
//RW variables initialized to their default values (writeable with SDO)
M_ERROR_REGISTER uCO_DevErrReg;						//(x1001,0)readable by SDO, writeable by the program only
unsigned long uCO_DevManufacturerStatReg;			//(x1002,0)

unsigned char uCO_COMM_SYNC_COBID = 0x80;
unsigned int uCO_COMM_NMTE_GuardTime = 0;			//not used
unsigned char uCO_COMM_NMTE_LifeTimeFactor = 0; 	//not used
unsigned int uCO_COMM_NMTE_HeartBeat = 2000;		//2 seconds

rom unsigned char _uSDO1COMMIndx = 3;				//(1200,0: The length of the SDO object
rom unsigned int uCO_COMM_SDO1_CLIENT_COBID = 0x600;//(1200,1: COB_ID client->server
rom unsigned int uCO_COMM_SDO1_SERVER_COBID = 0x580;//(1200,2: COB_ID server->client

//receive PDOs
rom unsigned int uCO_COMM_RPDO1_COBID = 0x200;		//(1400,1  RPDO1 (+node id)
rom unsigned int uCO_COMM_RPDO2_COBID = 0x300;		//(1401,1  RPDO2 (+node id)

//transmit PDOs
rom unsigned int uCO_COMM_TPDO1_COBID = 0x180;		//(1800,1  TPDO1 (+node id)
rom unsigned int uCO_COMM_TPDO1_Type = .255;		//default xmit type PDO1 = async

rom unsigned int uCO_COMM_TPDO2_COBID = 0x280;
rom unsigned int uCO_COMM_TPDO2_Type = 255;

M_MULTIPLEXOR multiplexor;
unsigned char uLocalRcvBuffer[8];			// local buffer for RPDO1 (gi... something to do with device profile(?) )
rom struct _DICTIONARY_OBJECT_TEMPLATE *od_entry;

//++++++++++++++++++++++++++++++++++++++++++++++

rom unsigned char	__dummy[4] = {0,0,0,0};
rom unsigned long uTPDO1Map = 0x60000108;
rom unsigned long uRPDO1Map = 0x62000108; //gi: app dep???
rom unsigned long uPDO1Dummy = 0x00000008;

// Static data refered to by the dictionary
rom unsigned char rMaxIndex1 = 1;
rom unsigned char rMaxIndex2 = 8;
rom unsigned char uDemoTPDO1Len = 2;

DICT_PARAM	uDict;

rom unsigned char * _pTmpDBase;
unsigned char 		_tDBaseLen;
unsigned char		_uDictTemp[4];
									
/* Dictionary database built into ROM */								
rom DICT_OBJECT_TEMPLATE _db_objects[] = {DICTIONARY_DATA_TYPES};	//comm profile

extern unsigned int Index;
extern unsigned char SubIndex;
extern unsigned char SDO_Process;
extern unsigned char SDO_RX_HOLD_DATA[64];
extern unsigned char SDO_RX_INDEX;
extern unsigned char toggle;
extern unsigned int  downloadbytes;
extern unsigned int Id;
extern unsigned int z_SDO_timer;		//inster SDO time out

unsigned char *q_copy_from_RAM;
unsigned char *q_copy_to_RAM;
rom char *q_copy_from_ROM;
char *q_copy_to;
REQ_STAT cc;
int sdo_req;

//***************************************************
// Copy from sdo Telegram to EEPROM memory. 
//***************************************************
unsigned char Download_to_EEPROM (unsigned char * from, int n)
{
int i;
unsigned char return_code = E_SUCCESS;
unsigned char to;
unsigned char q_write_to_external_EEPROM = TRUE;

typedef union intarray
{
	struct
	{
		unsigned char arr2[2];
	};
	unsigned int int16;
}MQ_INT_TO_ARRAY;

typedef union longarray
{
	struct
	{
		unsigned char arr4[4];
	};
	struct
	{
		int int16high;
		int int16low;
	};
	unsigned long long32;

}MQ_LONG_TO_ARRAY;

MQ_INT_TO_ARRAY q_int_array;
MQ_LONG_TO_ARRAY q_long_array;



	if ((od_entry->ctl) & (EE_BIT))
	{
		z_bytes_for_xfer = n;		//in case of external EEPROM
		z_EEPROM_page = 0;
		z_EEPROM_offset = 0;

		//possible write to on-board EEPROM
		if ((multiplexor.index == 0x100B) && (multiplexor.sindex == 0))
		{
				q_write_to_external_EEPROM = FALSE;
				to = EEPROM_NODE_ID;
		}
		else if ((multiplexor.index == 0x1017) && (multiplexor.sindex == 0))
		{
				q_write_to_external_EEPROM = FALSE;
				to = EEPROM_HEART_BEAT;
		}
		else if (multiplexor.index == 0x1018)
		{
			q_write_to_external_EEPROM = FALSE;
			switch (multiplexor.sindex)
			{
				case (1):
					to = EEPROM_Vendor_Id;
					break;
				case (2):
					to = EEPROM_Product_code;
					break;
				case (3):
					to = EEPROM_revision_numb;
					break;
				case (4):
					to = EEPROM_serial_numb;
					break;
				default:
					return (E_OBJ_NOT_FOUND);	//error
			}//switch
		} //if 1018

		else if ((multiplexor.index == 0x2000) && (multiplexor.sindex == 0))
		{
			z_EEPROM_bank = BANK_RAMP_UP;
		}
		else if ((multiplexor.index == 0x2001) && (multiplexor.sindex == 0))
		{
			z_EEPROM_bank = BANK_RAMP_DOWN;
		}
		else if ((multiplexor.index == 0x2002) && (multiplexor.sindex == 0))
		{
			z_EEPROM_bank = BANK_RAMP_LEFT;
		}
		else if ((multiplexor.index == 0x2003) && (multiplexor.sindex == 0))
		{
			z_EEPROM_bank = BANK_RAMP_RIGHT;
		}
		else if ((multiplexor.index == 0x6040) && (multiplexor.sindex == 0))
		{
			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 0;
			z_EEPROM_offset = 0;			//2 BYTES
		}
		else if ((multiplexor.index == 0x6043) && (multiplexor.sindex == 0))
		{
			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 0;
			z_EEPROM_offset = 2;			//1 BYTE
		}
		else if ((multiplexor.index == 0x6051) && (multiplexor.sindex == 0))
		{
			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 0;
			z_EEPROM_offset = 3;			//2 BYTES
		}
		else if ((multiplexor.index == 0x6053) && (multiplexor.sindex == 0))
		{
			z_EEPROM_bank = BANK_DEV_DESCRIPTION;
			z_EEPROM_page = 0;
			z_EEPROM_offset = 0;	//24 BYTES
		}
		else if ((multiplexor.index == 0x6056) && (multiplexor.sindex == 0))
		{
			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 0;
			z_EEPROM_offset = 5;	//1 BYTE
		}
		else if ((multiplexor.index == 0x6311) && (multiplexor.sindex == 1))
		{
			for (i = 0 ; i < n ; i++)		//convert to int
				q_int_array.arr2[i] = from[i];

			i = q_int_array.int16;
			if ((i > 100) || (i < -100))		//vopc_demand_ref_value
				return(E_PARAM_RANGE);

			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 0;
			z_EEPROM_offset = 6;	//2 BYTE
		}
		else if ((multiplexor.index == 0x6314) && (multiplexor.sindex == 1))
		{
			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 0;
			z_EEPROM_offset = 8;	//2 BYTE
		}
		else if ((multiplexor.index == 0x6320) && (multiplexor.sindex == 1))
		{
			for (i = 0 ; i < n ; i++)		//convert to int
				q_int_array.arr2[i] = from[i];

			i = q_int_array.int16;
			if (i > 100)					//vpoc_demand_upper_limit
				return(E_PARAM_RANGE);

			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 0;
			z_EEPROM_offset = 10;	//2 BYTE
		}
		else if ((multiplexor.index == 0x6321) && (multiplexor.sindex == 1))
		{
			for (i = 0 ; i < n ; i++)		//convert to int
				q_int_array.arr2[i] = from[i];

			i = q_int_array.int16;
			if (i < -100)					//vpoc_demand_lower_limit
				return(E_PARAM_RANGE);

			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 0;
			z_EEPROM_offset = 12;	//2 BYTE
		}
		else if ((multiplexor.index == 0x6322) && (multiplexor.sindex == 0))
		{
			for (i = 0 ; i < n ; i++)		//convert to long
				q_long_array.arr4[i] = from[i];

			if ((q_long_array.int16high == 0) || (q_long_array.int16low == 0))		//semantic check
				return(E_PARAM_RANGE);

			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 0;
			z_EEPROM_offset = 14;	//4 BYTES
		}
		else if ((multiplexor.index == 0x6323) && (multiplexor.sindex == 1))
		{
			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 0;
			z_EEPROM_offset = 18;	//2 BYTES
		}
		else if ((multiplexor.index == 0x6324) && (multiplexor.sindex == 1))
		{
			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 0;
			z_EEPROM_offset = 20;	//2 BYTES
		}
		else if ((multiplexor.index == 0x6330) && (multiplexor.sindex == 0))
		{

			if ((from[0] < 0) || (from[0] > LINEAR_3)) //vpoc_demand_ramp_type
				return(E_UNSUPP_ACCESS);

			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 0;
			z_EEPROM_offset = 22;	//1 BYTES
		}
		else if ((multiplexor.index == 0x6331) && (multiplexor.sindex == 1))
		{
			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 0;
			z_EEPROM_offset = 23;	//2 BYTES
		}
		else if ((multiplexor.index == 0x6332) && (multiplexor.sindex == 1))
		{
			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 0;
			z_EEPROM_offset = 25;	//2 BYTES
		}
		else if ((multiplexor.index == 0x6333) && (multiplexor.sindex == 1))
		{
			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 0;
			z_EEPROM_offset = 27;	//2 BYTES
		}
		else if ((multiplexor.index == 0x6334) && (multiplexor.sindex == 1))
		{
			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 0;
			z_EEPROM_offset = 29;	//2 BYTES
		}
		else if ((multiplexor.index == 0x6335) && (multiplexor.sindex == 1))
		{
			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 1;
			z_EEPROM_offset = 0;	//2 BYTES
		}
		else if ((multiplexor.index == 0x6336) && (multiplexor.sindex == 1))
		{
			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 1;
			z_EEPROM_offset = 2;	//2 BYTES
		}
		else if ((multiplexor.index == 0x6340) && (multiplexor.sindex == 0))
		{
			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 1;
			z_EEPROM_offset = 4;	//1 BYTES
		}
		else if ((multiplexor.index == 0x6341) && (multiplexor.sindex == 0))
		{
			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 1;
			z_EEPROM_offset = 5;	//4 BYTES
		}
		else if ((multiplexor.index == 0x6342) && (multiplexor.sindex == 0))
		{
			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 1;
			z_EEPROM_offset = 9;	//1 BYTES
		}
		else if ((multiplexor.index == 0x6343) && (multiplexor.sindex == 1))
		{
			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 1;
			z_EEPROM_offset = 10;	//2 BYTES
		}
		else if ((multiplexor.index == 0x6344) && (multiplexor.sindex == 1))
		{
			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 1;
			z_EEPROM_offset = 12;	//2 BYTES
		}
		else if ((multiplexor.index == 0x6345) && (multiplexor.sindex == 1))
		{
			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 1;
			z_EEPROM_offset = 14;	//2 BYTES
		}
		else if ((multiplexor.index == 0x6346) && (multiplexor.sindex == 0))
		{
			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 1;
			z_EEPROM_offset = 16;	//1 BYTES
		}
		else if ((multiplexor.index == 0x6351) && (multiplexor.sindex == 0))
		{
			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 1;
			z_EEPROM_offset = 17;	//1 BYTES
		}
		else if ((multiplexor.index == 0x6352) && (multiplexor.sindex == 1))
		{
			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 1;
			z_EEPROM_offset = 18;	//2 BYTES
		}
		else if ((multiplexor.index == 0x6353) && (multiplexor.sindex == 1))
		{
			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 1;
			z_EEPROM_offset = 20;	//2 BYTES
		}
		else if ((multiplexor.index == 0x6354) && (multiplexor.sindex == 1))
		{
			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 1;
			z_EEPROM_offset = 22;	//2 BYTES
		}
		else if ((multiplexor.index == 0x6355) && (multiplexor.sindex == 1))
		{
			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 1;
			z_EEPROM_offset = 24;	//2 BYTES
		}
		else if ((multiplexor.index == 0x6370) && (multiplexor.sindex == 0))
		{
			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 1;
			z_EEPROM_offset = 26;	//1 BYTES
		}
		else if ((multiplexor.index == 0x6371) && (multiplexor.sindex == 1))
		{
			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 1;
			z_EEPROM_offset = 27;	//2 BYTES
		}
		else if ((multiplexor.index == 0x6372) && (multiplexor.sindex == 1))
		{
			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 1;
			z_EEPROM_offset = 29;	//2 BYTES
		}
		else if ((multiplexor.index == 0x6373) && (multiplexor.sindex == 1))
		{
			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 2;
			z_EEPROM_offset = 0;	//2 BYTES
		}
		else if ((multiplexor.index == 0x6374) && (multiplexor.sindex == 1))
		{
			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 2;
			z_EEPROM_offset = 2;	//2 BYTES
		}
		else if ((multiplexor.index == 0x6375) && (multiplexor.sindex == 1))
		{
			z_EEPROM_bank = BANK_GENERAL_DATA1;
			z_EEPROM_page = 2;
			z_EEPROM_offset = 4;	//2 BYTES
		}
		else
			return (E_PARAM_RANGE);	//this is an inconsistancy: EE_PROM bit set but no entry found

		if (!q_write_to_external_EEPROM)			//write to on-board EEPROM
		{
			for (i=0 ; i<n ;i++)
			{
				WriteEEprom_OnBoard (to,(unsigned char) *from);
				from++;
				to++;
			}
		}			
		else
		{ 											//write to external EEPROM
			Write_to_EX_EEPROM (from);
		}
	}	//if EE_BIT

	return (return_code);
}

//***************************************************
// Copy from sdo Telegram to RW memory. 
//***************************************************
void Copy_RAM_to_RAM (char * from, char * to, int n)
{
int i;
char a;

	for (i=0 ; i<n ;i++)
	{
		*to = *from;
		from++;
		to++;
	}
}

//***************************************************
// Copy from sdo Telegram to RW memory. 
//***************************************************
void Download_to_RAM (char * from, char * to, int n)
{
int i;
char a;

	for (i=0 ; i<n ;i++)
	{
		*to = *from;
		from--;
		to++;
	}
}

//***************************************************
// Copy from RAM to sdo Telegram backwards
//***************************************************
void Upload_from_RAM (char * from, char * to, int n)
{
int i;
char a;

	for (i=0 ; i<n ;i++)
	{
		*to = *from;
		from++;
		to--;			//buffer fills backwards
	}
}
//***************************************************
// Copy RO objects (in code segment) to the sdo buffer backwards
//***************************************************
void Upload_from_ROM (rom unsigned char * from, char * to, int n)
{
int i;

	for (i=0 ; i<n ;i++)
	{
		*to = *from;	//only way to copy mem to mem with pointer
		from++;
		to--;			//buffer fills backwards
	}
}
//******************************************************//
//Access to OD search  		                    		//
//Analyze message										//
//Save/retrieve data for download/upload				//
//Reply and comply with SDO protocol					//
//******************************************************//
void treat_SDO (M_TXB_BUFF sdobuf)
{
unsigned char _null[] = {0,0,0,0,0,0,0,0};
unsigned char numchars, lastseg;
char return_code;
unsigned char i;
unsigned char a;

	switch (sdobuf.COMMAND.ANONYMOUS.cs)
	{
	//--------------------------------------------------------------------------------------------------
		case CCS_SDO_INIT_DOWNLOAD:
			if (SDO_Process != CAN_NOTHING)		//already processing an sdo?
			{
				Send_SDO_Abort(sdobuf.INDEX, sdobuf.SUB_INDEX, E_CS_CMD);
				return;
			}
			
			multiplexor.index = (sdobuf.TXBD2 * 0x100) + sdobuf.TXBD1; //put index in int format
			multiplexor.sindex = sdobuf.SUB_INDEX;
			return_code = find_dictionary_entry(multiplexor.index, multiplexor.sindex);

			if(return_code == E_SUCCESS) //entry exists?
			{				
				multiplexor.length = od_entry->len;
				toggle = FALSE;
				downloadbytes = -1;

				if ((od_entry->ctl) & (WR_BIT))									//if it can be written
				{
					switch ((sdobuf.COMMAND.INIT_DOWNLOAD.s), (sdobuf.COMMAND.INIT_DOWNLOAD.e))
					{
						case (TRUE, TRUE):					//expedited, all data in the message
							numchars = 4 - sdobuf.COMMAND.INIT_DOWNLOAD.n;
							if (numchars <= od_entry->len)		//check for appropiate length
							{
								q_copy_from_RAM = &sdobuf.B0;					//data
								Download_to_RAM((char *)q_copy_from_RAM, (char *)&SDO_RX_HOLD_DATA[0], numchars); //collect data in HOLD buffer
								return_code = Download_to_EEPROM ((unsigned char *)&SDO_RX_HOLD_DATA[0], numchars); 	//CHECKS FOR DATA CONSISTANCY 
								if (return_code == E_SUCCESS)
								{
									Copy_RAM_to_RAM((char *)&SDO_RX_HOLD_DATA[0], (char *)od_entry->pROM, numchars);
									Send_Init_Download_resp(sdobuf.INDEX, sdobuf.SUB_INDEX);
								}
								else
									Send_SDO_Abort(sdobuf.INDEX, sdobuf.SUB_INDEX, return_code);
							}
							else
								Send_SDO_Abort(sdobuf.INDEX, sdobuf.SUB_INDEX, E_MEMORY_OUT);

							break;

						case (TRUE,FALSE):		//no data in sdobuf, d has number of bytes to be downloaded

							downloadbytes = (unsigned int) sdobuf.B0 + (sdobuf.B1*0x100); //number of download stated
							if (downloadbytes > od_entry->len)
							{
								Send_SDO_Abort(sdobuf.INDEX, sdobuf.SUB_INDEX, E_MEMORY_OUT);
								return;
							}
/*	let code fall through-->break; <-- let code fall through  */
						default:		//not expedited, download bytes have been stated, or no data specified, expect download messages
							numchars = 0;
							SDO_RX_INDEX = 0;						//index for next download
							SDO_Process = CAN_DONWLOADING;
							z_SDO_timer = INTER_SDO_TIMER;
							Send_Init_Download_resp(sdobuf.INDEX, sdobuf.SUB_INDEX);
					}
				}
				else	//WR_BIT set i.e. writable entry?
				{
					Send_SDO_Abort(sdobuf.INDEX, sdobuf.SUB_INDEX, E_CANNOT_WRITE);
				}
			}
			else	//entry found?
			{
				Send_SDO_Abort(sdobuf.INDEX, sdobuf.SUB_INDEX, return_code);
			}
			break;

	//--------------------------------------------------------------------------------------------------
		case CCS_SDO_SEGMNT_DOWNLOAD:
			if (SDO_Process != CAN_DONWLOADING)		//must be already downloading
			{
				SDO_RX_INDEX = 0;					//unexpected download
				Send_SDO_Abort(sdobuf.INDEX, sdobuf.SUB_INDEX, E_CS_CMD);
				return;
			}
			numchars = 7 - sdobuf.COMMAND.DOWNLOAD_SEGMT.n;
			if (SDO_RX_INDEX + numchars > multiplexor.length)
			{
				Send_SDO_Abort(multiplexor.index, multiplexor.sindex, E_MEMORY_OUT);		//buffer runaway
				return;
			}
			if ((downloadbytes != -1) && (SDO_RX_INDEX + numchars > downloadbytes)) //more than stated number download bytes?
			{
				Send_SDO_Abort(multiplexor.index, multiplexor.sindex, E_MEMORY_OUT);		//buffer runaway
				return;
			}

			if (toggle != sdobuf.COMMAND.DOWNLOAD_SEGMT.t)
			{
				Send_SDO_Abort(multiplexor.index, multiplexor.sindex, E_TOGGLE);
				return;
			}
			q_copy_from_RAM = &sdobuf.D0; 									//data
			Download_to_RAM((char *)q_copy_from_RAM, (char *)&SDO_RX_HOLD_DATA[SDO_RX_INDEX], numchars); //collect data in HOLD buffer
			SDO_RX_INDEX += numchars;						//index for next download
			SDO_Process = CAN_DONWLOADING;					//download not finished

			if (sdobuf.COMMAND.DOWNLOAD_SEGMT.c)			//last segment downloaded
			{			// now copy the received data into the OD address'

				if ((downloadbytes == -1) || ((downloadbytes != -1) && (downloadbytes == SDO_RX_INDEX)))
				{
					return_code = Download_to_EEPROM ((unsigned char *)&SDO_RX_HOLD_DATA[0], SDO_RX_INDEX); 	//ALSO CHECKS FOR DATA CONSISTANCY 

					if (return_code == E_SUCCESS)
					{
						find_dictionary_entry(multiplexor.index, multiplexor.sindex);
						Copy_RAM_to_RAM((char *)&SDO_RX_HOLD_DATA[0], (char *)od_entry->pROM, SDO_RX_INDEX);
					}
					SDO_Process = CAN_NOTHING;
				}
				else	//client quits before completing downloadbytes
				{
					Send_SDO_Abort(multiplexor.index, multiplexor.sindex, E_LEN_SERVICE);
					return;
				}
			}

			Send_Download_resp(toggle);
			z_SDO_timer = INTER_SDO_TIMER;
			toggle ^= 1;

			break;

//--------------------------------------------------------------------------------------------------
		case SCS_SDO_INIT_UPLOAD:
			if (SDO_Process != CAN_NOTHING)		//already processing an sdo?
			{
				SDO_Process = CAN_NOTHING;
				Send_SDO_Abort(sdobuf.INDEX, sdobuf.SUB_INDEX, E_CS_CMD);
				return;
			}

			multiplexor.index = (sdobuf.TXBD2 * 0x100) + sdobuf.TXBD1; //put index in int format
			multiplexor.sindex = sdobuf.SUB_INDEX;
			return_code = find_dictionary_entry(multiplexor.index, multiplexor.sindex);
			if(return_code == E_SUCCESS) //entry exists?
			{				
				multiplexor.length = od_entry->len;
				if ((od_entry->ctl) & (RD_BIT))				//if it can be read
				{
					TXB_B [CAN_OPEN_IdSdoTx].COMMAND.INIT_DOWNLOAD_RESPONSE.x = 0;
					TXB_B [CAN_OPEN_IdSdoTx].TXBD1 = sdobuf.TXBD1;	//write index back - in backwards format
					TXB_B [CAN_OPEN_IdSdoTx].TXBD2 = sdobuf.TXBD2;	
					TXB_B [CAN_OPEN_IdSdoTx].SUB_INDEX = multiplexor.sindex;
					TXB_B [CAN_OPEN_IdSdoTx].COMMAND.INIT_UPLOAD_RESPONSE.s = 1; //data size is indicated (n or d)
					numchars = od_entry->len;

					if (numchars <= 4)
					{							//send expidited
						TXB_B [CAN_OPEN_IdSdoTx].COMMAND.INIT_UPLOAD_RESPONSE.n = (4 - numchars); // <-- data size indicated in n
						TXB_B [CAN_OPEN_IdSdoTx].COMMAND.INIT_UPLOAD_RESPONSE.e = 1; //expedited
						SDO_Process = CAN_NOTHING;
						if (od_entry->ctl & ROM_BIT)
							Upload_from_ROM(od_entry->pROM, (char *)&TXB_B [CAN_OPEN_IdSdoTx].B0, numchars);
						else
							Upload_from_RAM((char *)od_entry->pROM, (char *)&TXB_B [CAN_OPEN_IdSdoTx].B0, numchars);
					}
					else
					{
						TXB_B [CAN_OPEN_IdSdoTx].COMMAND.INIT_UPLOAD_RESPONSE.n = 4; //no data in this msg
						TXB_B [CAN_OPEN_IdSdoTx].COMMAND.INIT_UPLOAD_RESPONSE.e = 0; //not expedited
						Upload_from_RAM((char *)_null, (char *)&TXB_B [CAN_OPEN_IdSdoTx].B0, 4);
						TXB_B [CAN_OPEN_IdSdoTx].B0 = numchars; // <-- data size indicated in d
						SDO_Process = CAN_UPLOADING;
						SDO_RX_INDEX = 0; //running index into dict data
						toggle = FALSE;
						lastseg = FALSE;
					}

					Send_Init_Upload_resp();
					z_SDO_timer = INTER_SDO_TIMER;
				}
				else
				{
					Send_SDO_Abort(sdobuf.INDEX, sdobuf.SUB_INDEX, E_CANNOT_READ);
				}
			}
			else
			{
				Send_SDO_Abort(sdobuf.INDEX, sdobuf.SUB_INDEX, return_code);	//entry not found
			}
			break;
//--------------------------------------------------------------------------------------------------
		case CCS_SDO_UPLOAD_SEGMNT:
			if (SDO_Process != CAN_UPLOADING)		//already processing an sdo?
			{
				Send_SDO_Abort(sdobuf.INDEX, sdobuf.SUB_INDEX, E_CS_CMD);
				return;
			}
			if (toggle != sdobuf.COMMAND.UPLOAD_SEGMT.t)
			{
				Send_SDO_Abort(multiplexor.index, multiplexor.sindex, E_TOGGLE);
				return;
			}
			if ((multiplexor.length - SDO_RX_INDEX) >= 7)
			{
				lastseg = FALSE;
				numchars = 7;
			}
			else
			{
				numchars = multiplexor.length - SDO_RX_INDEX;
				lastseg = TRUE;
				SDO_Process = CAN_NOTHING;		//finsihed
			}

			Upload_from_RAM((char *)_null, (char *)&TXB_B [CAN_OPEN_IdSdoTx].D0, 8);
			return_code = find_dictionary_entry(multiplexor.index, multiplexor.sindex);
			if (od_entry->ctl & ROM_BIT)
				Upload_from_ROM(od_entry->pROM + SDO_RX_INDEX, (char *)&TXB_B [CAN_OPEN_IdSdoTx].D0, numchars);
			else
				Upload_from_RAM((char *)od_entry->pROM + SDO_RX_INDEX, (char *)&TXB_B [CAN_OPEN_IdSdoTx].D0, numchars);

			SDO_RX_INDEX += 7;
			Send_Upload_Segment((7-numchars), toggle, lastseg);
			toggle ^= 1;
			z_SDO_timer = INTER_SDO_TIMER;
			break;

//--------------------------------------------------------------------------------------------------
		case CS_SDO_ABORT:
			SDO_Process = CAN_NOTHING;		//abort any on-going action, SERVICE IS UNCONFIRMED
			break;

//--------------------------------------------------------------------------------------------------
		default:
				// unsupported access services, mainly BLOCK UP/DOWNLOAD and END UP/DOWN BLOCK
				Send_SDO_Abort(multiplexor.index, multiplexor.sindex, E_UNSUPP_ACCESS);
	}

}

//*********************************************************************
//STRUCTURE OF THE OBJECT DICTIONARY:
//unsig int index; unsig char subindex; unsig char ctl; unsig int len; rom unsigned char * pROM;
//
//WARNING: This procedure relies on the fact that entries in the OD are ORDERED
//********************************************************************/
unsigned char find_dictionary_entry(unsigned int i, char s)
{
 rom struct _DICTIONARY_OBJECT_TEMPLATE *q_dop;
 REQ_STAT q_cc;
 unsigned int q_num_objs;
 int q_k=0;

 _asm clrwdt _endasm	//clear wdt before starting the search

	q_k = 0;
 	q_cc = E_OBJ_NOT_FOUND;
	q_dop = (rom DICT_OBJECT_TEMPLATE *)_db_objects;
	q_num_objs = sizeof(_db_objects)/sizeof(DICT_OBJECT_TEMPLATE);


/* search for the right index */
	while ((q_dop->index <= i) && (q_k < q_num_objs))
		{
		if (q_dop->index == i)
			{
			q_cc = E_SUCCESS;
			break;
			}
		q_dop++;		//points to the next element of the OD
		q_k++;	
		}

/* search for the right subindex */
	if (q_cc == E_SUCCESS)		/* an object with the correct index has been found */
		{
	 	q_cc = E_SUBINDEX_NOT_FOUND;
		while ((q_dop->index == i) && (q_dop->subindex < s)) q_dop++;
		q_k=q_dop->subindex;
		if ((q_dop->index == i) && (q_dop->subindex == s))	q_cc = E_SUCCESS;
		}

	if (q_cc == E_SUCCESS)		/* index and subindex found, now read or write the data using the ptr */
		od_entry = q_dop;

	return ((unsigned char)q_cc);

}
