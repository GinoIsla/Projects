// Programmer: Gino Isla for Lambda Sistemi, Milano

#include "japplication_data.h"
#include "jprototype.h"
#include "jEEPROM_data.def"

extern unsigned char z_bytes_for_xfer; 			//number of bytes to transfer to/from the external EEPROM page
extern unsigned char z_EEPROM_bank;				//group of bytes (ramp o,1,2,3), each bank is 128 bytes
extern unsigned char z_EEPROM_page;				//page within the bank where write starts
extern unsigned char z_EEPROM_offset;			// offset within the page (for single varaibles)
extern unsigned char SDO_RX_HOLD_DATA[128];

void EEPROM_initializer(void)
{
unsigned char CHAR8;
unsigned int INT16;
long unsigned int INT32;

unsigned char i;

#ifdef INIT_EXT_EEPROM

// for (i=0 ; i < 50; i++)   SDO_RX_HOLD_DATA[i] = RAMP_UP_VALUES[i];
// z_bytes_for_xfer = 50;
// z_EEPROM_bank = BANK_RAMP_UP;
// z_EEPROM_page = 0;
// z_EEPROM_offset = 0;
// Write_to_EX_EEPROM (SDO_RX_HOLD_DATA);
//
// for (i=0 ; i < 50; i++)	SDO_RX_HOLD_DATA[i] = RAMP_DOWN_VALUES[i];
// z_bytes_for_xfer = 50;
// z_EEPROM_bank = BANK_RAMP_DOWN;
// z_EEPROM_page = 0;
// z_EEPROM_offset = 0;
// Write_to_EX_EEPROM (SDO_RX_HOLD_DATA);
//
// for (i=0 ; i < 50; i++)	SDO_RX_HOLD_DATA[i] = RAMP_LEFT_VALUES[i];
// z_bytes_for_xfer = 50;
// z_EEPROM_bank = BANK_RAMP_LEFT;
// z_EEPROM_page = 0;
// z_EEPROM_offset = 0;
// Write_to_EX_EEPROM (SDO_RX_HOLD_DATA);
//
// for (i=0 ; i < 50; i++)	SDO_RX_HOLD_DATA[i] = RAMP_RIGHT_VALUES[i];
// z_bytes_for_xfer = 50;
// z_EEPROM_bank = BANK_RAMP_RIGHT;
// z_EEPROM_page = 0;
// z_EEPROM_offset = 0;
// Write_to_EX_EEPROM (SDO_RX_HOLD_DATA);
//
////6040
//INT16 = DEV_CONTROL_WORD_0;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 0;
//z_EEPROM_offset = 0;
//z_bytes_for_xfer = 2;
//Write_to_EX_EEPROM ((unsigned char *) &INT16);
//
////6043
//CHAR8 = CNTRL_MODE_CLOSED_LOOP;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 0;
//z_EEPROM_offset = 2;			//1 BYTE
//z_bytes_for_xfer = 1;
//Write_to_EX_EEPROM (&CHAR8);
//
////6051
//INT16 = DEV_DUMMY_DEV_CODE_NUM;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 0;
//z_EEPROM_offset = 3;
//z_bytes_for_xfer = 2;
//Write_to_EX_EEPROM ((unsigned char *) &INT16);
//
////6053
//for (i=0 ; i < 24; i++)	SDO_RX_HOLD_DATA[i] = rCO_DEVDESCRIPTION[i];
//z_EEPROM_bank = BANK_DEV_DESCRIPTION;
//z_EEPROM_page = 0;
//z_EEPROM_offset = 0;
//z_bytes_for_xfer = 24;
//Write_to_EX_EEPROM (SDO_RX_HOLD_DATA);
//
////6056
//CHAR8 = DEV_SETCODE_0;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 0;
//z_EEPROM_offset = 5;	//1 BYTE
//z_bytes_for_xfer = 1;
//Write_to_EX_EEPROM (&CHAR8);
//
////6311
//INT16 = DEMAND_REFVALUE_100;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 0;
//z_EEPROM_offset = 6;	//2 BYTE
//z_bytes_for_xfer = 2;
//Write_to_EX_EEPROM ((unsigned char *) &INT16);
//
////6314
//INT16 = HOLD_SETVALUE_0;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 0;
//z_EEPROM_offset = 8;	//2 BYTE
//Write_to_EX_EEPROM ((unsigned char *) &INT16);
//
////6320
//INT16 = DEMAND_UPPERLIMIT_100;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 0;
//z_EEPROM_offset = 10;	//2 BYTE
//z_bytes_for_xfer = 2;
//Write_to_EX_EEPROM ((unsigned char *) &INT16);
//
////6321
//INT16 = DEMAND_LOWERLIMIT_0;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 0;
//z_EEPROM_offset = 12;	//2 BYTE
//z_bytes_for_xfer = 2;
//Write_to_EX_EEPROM ((unsigned char *) &INT16);
//
////6322
//INT32 = DEMAND_SCALEFACTOR11;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 0;
//z_EEPROM_offset = 14;	//4 BYTES
//z_bytes_for_xfer = 4;
//Write_to_EX_EEPROM ((unsigned char *) &INT32);
//
////6323
//INT16 = DEMAND_SCALEOFFSET_0;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 0;
//z_EEPROM_offset = 18;	//2 BYTES
//z_bytes_for_xfer = 2;
//Write_to_EX_EEPROM ((unsigned char *) &INT16);
//
////6324
//INT16 = DEMAND_ZEROCORRECTION_0;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 0;
//z_EEPROM_offset = 20;	//2 BYTES
//z_bytes_for_xfer = 2;
//Write_to_EX_EEPROM ((unsigned char *) &INT16);
//
////6330
//CHAR8 = LINEAR_1;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 0;
//z_EEPROM_offset = 22;	//1 BYTES
//z_bytes_for_xfer = 1;
//Write_to_EX_EEPROM (&CHAR8);
//
////6331
//INT16 = RAMP_ACCELTIME_0;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 0;
//z_EEPROM_offset = 23;	//2 BYTES
//z_bytes_for_xfer = 2;
//Write_to_EX_EEPROM ((unsigned char *) &INT16);
//
////6332
//INT16 = RAMP_ACCELTIME_POS_0;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 0;
//z_EEPROM_offset = 25;	//2 BYTES
//z_bytes_for_xfer = 2;
//Write_to_EX_EEPROM ((unsigned char *) &INT16);
//
////6330
//INT16 = RAMP_ACCELTIME_NEG_0;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 0;
//z_EEPROM_offset = 27;	//2 BYTES
//z_bytes_for_xfer = 2;
//Write_to_EX_EEPROM ((unsigned char *) &INT16);
//
////6334
//INT16 = RAMP_DECELTIME_0;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 0;
//z_EEPROM_offset = 29;	//2 BYTES
//z_bytes_for_xfer = 2;
//Write_to_EX_EEPROM ((unsigned char *) &INT16);
//
////6335
//INT16 = RAMP_DECELTIME_POS_0;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 1;
//z_EEPROM_offset = 0;	//2 BYTES
//z_bytes_for_xfer = 2;
//Write_to_EX_EEPROM ((unsigned char *) &INT16);
//
////6336
//INT16 = RAMP_DECELTIME_NEG_0;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 1;
//z_EEPROM_offset = 2;	//2 BYTES
//z_bytes_for_xfer = 2;
//Write_to_EX_EEPROM ((unsigned char *) &INT16);
//
////6340
//CHAR8 = NO_DIRECTIONAL_GAIN_0;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 1;
//z_EEPROM_offset = 4;	//1 BYTES
//z_bytes_for_xfer = 1;
//Write_to_EX_EEPROM (&CHAR8);
//
////6341
//INT32 = DIR_DEPENDNT_GAIN;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 1;
//z_EEPROM_offset = 5;	//4 BYTES
//z_bytes_for_xfer = 4;
//Write_to_EX_EEPROM ((unsigned char *) &INT32);
//
////6342
//CHAR8 = TYPE_1;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 1;
//z_EEPROM_offset = 9;	//1 BYTES
//z_bytes_for_xfer = 1;
//Write_to_EX_EEPROM (&CHAR8);
//
////6343
//INT16 = DEAD_BAND_COMP_A;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 1;
//z_EEPROM_offset = 10;	//2 BYTES
//z_bytes_for_xfer = 2;
//Write_to_EX_EEPROM ((unsigned char *) &INT16);
//
////6344
//INT16 = DEAD_BAND_COMP_B;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 1;
//z_EEPROM_offset = 12;	//2 BYTES
//z_bytes_for_xfer = 2;
//Write_to_EX_EEPROM ((unsigned char *) &INT16);
//
////6345
//INT16 = DEAD_BAND_COMP_THRHLD;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 1;
//z_EEPROM_offset = 14;	//2 BYTES
//z_bytes_for_xfer = 2;
//Write_to_EX_EEPROM ((unsigned char *) &INT16);
//
////6346
//CHAR8 = NO_COMPENSATION_0;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 1;
//z_EEPROM_offset = 16;	//1 BYTES
//z_bytes_for_xfer = 1;
//Write_to_EX_EEPROM (&CHAR8);
//
////6351
//CHAR8 = NO_MONITORING_0;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 1;
//z_EEPROM_offset = 17;	//1 BYTES
//z_bytes_for_xfer = 1;
//Write_to_EX_EEPROM (&CHAR8);
//
////6352
//INT16 = MONITORING_DELAY;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 1;
//z_EEPROM_offset = 18;	//2 BYTES
//z_bytes_for_xfer = 2;
//Write_to_EX_EEPROM ((unsigned char *) &INT16);
//
////6353
//INT16 = MONITORING_TRHLD;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 1;
//z_EEPROM_offset = 20;	//2 BYTES
//z_bytes_for_xfer = 2;
//Write_to_EX_EEPROM ((unsigned char *) &INT16);
//
////6354
//INT16 = MONITORING_TRHLD_UP;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 1;
//z_EEPROM_offset = 22;	//2 BYTES
//z_bytes_for_xfer = 2;
//Write_to_EX_EEPROM ((unsigned char *) &INT16);
//
////6355
//INT16 = MONITORING_TRHLD_DOWN;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 1;
//z_EEPROM_offset = 24;	//2 BYTES
//z_bytes_for_xfer = 2;
//Write_to_EX_EEPROM ((unsigned char *) &INT16);
//
////6370
//CHAR8 = NO_TARGET_MON_0;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 1;
//z_EEPROM_offset = 26;	//1 BYTES
//z_bytes_for_xfer = 1;
//Write_to_EX_EEPROM (&CHAR8);
//
////6371
//INT16 = MONITORING_SWITHCHON;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 1;
//z_EEPROM_offset = 27;	//2 BYTES
//z_bytes_for_xfer = 2;
//Write_to_EX_EEPROM ((unsigned char *) &INT16);
//
////6372
//INT16 = MONITORING_SWITHCHOFF;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 1;
//z_EEPROM_offset = 29;	//2 BYTES
//z_bytes_for_xfer = 2;
//Write_to_EX_EEPROM ((unsigned char *) &INT16);
//
////6373
//INT16 = TARGET_MONITORING_TRHLD;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 2;
//z_EEPROM_offset = 0;	//2 BYTES
//z_bytes_for_xfer = 2;
//Write_to_EX_EEPROM ((unsigned char *) &INT16);
//
////6374
//INT16 = TARGET_MONTNG_TRHLD_UP;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 2;
//z_EEPROM_offset = 2;	//2 BYTES
//z_bytes_for_xfer = 2;
//Write_to_EX_EEPROM ((unsigned char *) &INT16);
//
////6375
//INT16 = TARGET_MONTNG_TRHLD_DOWN;
//z_EEPROM_bank = BANK_GENERAL_DATA1;
//z_EEPROM_page = 2;
//z_EEPROM_offset = 4;	//2 BYTES
//z_bytes_for_xfer = 2;
//Write_to_EX_EEPROM ((unsigned char *) &INT16);
//
#endif
}
