//*******************************************************************
//Programmer: Gino Isla for Lambda Sistemi, Milano
//01-April-2007
//Loaq rpofile data from external EEPROM Load 
//*******************************************************************

#include "jpic_include.h"		/* include correct symbols for this processor */
#include "jprototype.h"
#include "japplication_data.h"
#include "jcan.h"
#include "jProfile_data.h"

extern unsigned char z_bytes_for_xfer; 			//number of bytes to transfer to/from the external EEPROM page
extern unsigned char z_EEPROM_bank;				//group of bytes (ramp o,1,2,3), each bank is 128 bytes
extern unsigned char z_EEPROM_page;				//page within the bank where write starts
extern unsigned char z_EEPROM_offset;			// offset within the page (for single varaibles)
extern unsigned char SDO_RX_HOLD_DATA[128];

void Load_Profile_data_from_external_EEPROM(void)
{
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
	unsigned long long32;
}MQ_LONG_TO_ARRAY;

int i;
MQ_INT_TO_ARRAY q_int_array;
MQ_LONG_TO_ARRAY q_long_array;

//	//Object 2000
//	z_EEPROM_bank = BANK_RAMP_UP;
//	z_EEPROM_page = 0;
//	z_EEPROM_offset = 0;
//	z_bytes_for_xfer = 50;
//	Read_from_EX_EEPROM (mspd_ramp_up_buffer);
//	
//	//2001
//	z_EEPROM_bank = BANK_RAMP_DOWN;
//	z_EEPROM_page = 0;
//	z_EEPROM_offset = 0;
//	z_bytes_for_xfer = 50;
//	Read_from_EX_EEPROM (mspd_ramp_down_buffer);
//	
//	//2002
//	z_EEPROM_bank = BANK_RAMP_LEFT;
//	z_EEPROM_page = 0;
//	z_EEPROM_offset = 0;
//	z_bytes_for_xfer = 50;
//	Read_from_EX_EEPROM (mspd_ramp_left_buffer);
//	
//	//2003
//	z_EEPROM_bank = BANK_RAMP_RIGHT;
//	z_EEPROM_page = 0;
//	z_EEPROM_offset = 0;
//	z_bytes_for_xfer = 50;
//	Read_from_EX_EEPROM (mspd_ramp_right_buffer);
//	
////	//6040
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 0;
//	z_EEPROM_offset = 0;
//	z_bytes_for_xfer = 2;
//	Read_from_EX_EEPROM (q_int_array.arr2);
//	dev_control_word.status_word = q_int_array.int16;
//	
//	//6043
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 0;
//	z_EEPROM_offset = 2;			//1 BYTE
//	z_bytes_for_xfer = 1;
//	Read_from_EX_EEPROM((unsigned char *)device_cntrl_mode);
//	
//	//6051
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 0;
//	z_EEPROM_offset = 3;
//	z_bytes_for_xfer = 2;
//	Read_from_EX_EEPROM (q_int_array.arr2);
//	vpoc_device_code_number = q_int_array.int16;
//	
//	//6053
//	z_EEPROM_bank = BANK_DEV_DESCRIPTION;
//	z_EEPROM_page = 0;
//	z_EEPROM_offset = 0;
//	z_bytes_for_xfer = 24;
//	Read_from_EX_EEPROM (rCO_DevDescription);
//	
//	//6056
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 0;
//	z_EEPROM_offset = 5;	//1 BYTE
//	z_bytes_for_xfer = 1;
//	Read_from_EX_EEPROM ((unsigned char *)uIO_DevSetCode);
//	
//	//6311
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 0;
//	z_EEPROM_offset = 6;	//2 BYTE
//	z_bytes_for_xfer = 2;
//	Read_from_EX_EEPROM (q_int_array.arr2);
//	vopc_demand_ref_value = q_int_array.int16;
//	
//	//6314
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 0;
//	z_EEPROM_offset = 8;	//2 BYTE
//	z_bytes_for_xfer = 2;
//	Read_from_EX_EEPROM (q_int_array.arr2);
//	vpoc_demand_hold_set_point = q_int_array.int16;
//	
//	//6320
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 0;
//	z_EEPROM_offset = 10;	//2 BYTE
//	z_bytes_for_xfer = 2;
//	Read_from_EX_EEPROM (q_int_array.arr2);
//	vpoc_demand_upper_limit = q_int_array.int16;
//	
//	//6321
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 0;
//	z_EEPROM_offset = 12;	//2 BYTE
//	z_bytes_for_xfer = 2;
//	Read_from_EX_EEPROM (q_int_array.arr2);
//	vpoc_demand_lower_limit = q_int_array.int16;
//	
//	//6322
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 0;
//	z_EEPROM_offset = 14;	//4 BYTES
//	z_bytes_for_xfer = 4;
//	Read_from_EX_EEPROM (q_long_array.arr4);
//	vpoc_demand_scaling_factor.intlong = q_long_array.long32;
//	
//	//6323
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 0;
//	z_EEPROM_offset = 18;	//2 BYTES
//	z_bytes_for_xfer = 2;
//	Read_from_EX_EEPROM (q_int_array.arr2);
//	vpoc_demand_scaling_offset = q_int_array.int16;
//	
//	//6324
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 0;
//	z_EEPROM_offset = 20;	//2 BYTES
//	z_bytes_for_xfer = 2;
//	Read_from_EX_EEPROM (q_int_array.arr2);
//	vpoc_demand_zero_correction_offset = q_int_array.int16;
//	
//	//6330
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 0;
//	z_EEPROM_offset = 22;	//1 BYTES
//	z_bytes_for_xfer = 1;
//	Read_from_EX_EEPROM ((unsigned char *)vpoc_demand_ramp_type);
//	
//	//6331
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 0;
//	z_EEPROM_offset = 23;	//2 BYTES
//	z_bytes_for_xfer = 2;
//	Read_from_EX_EEPROM (q_int_array.arr2);
//	vpoc_ramp_acceleration_time = q_int_array.int16;
//	
//	//6332
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 0;
//	z_EEPROM_offset = 25;	//2 BYTES
//	z_bytes_for_xfer = 2;
//	Read_from_EX_EEPROM (q_int_array.arr2);
//	vpoc_ramp_acceleration_time_pos = q_int_array.int16;
//	
//	//6333
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 0;
//	z_EEPROM_offset = 27;	//2 BYTES
//	z_bytes_for_xfer = 2;
//	Read_from_EX_EEPROM (q_int_array.arr2);
//	vpoc_ramp_acceleration_time_neg = q_int_array.int16;
//	
//	//6334
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 0;
//	z_EEPROM_offset = 29;	//2 BYTES
//	z_bytes_for_xfer = 2;
//	Read_from_EX_EEPROM (q_int_array.arr2);
//	vpoc_ramp_deceleration_time = q_int_array.int16;
//	
//	//6335
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 1;
//	z_EEPROM_offset = 0;	//2 BYTES
//	z_bytes_for_xfer = 2;
//	Read_from_EX_EEPROM (q_int_array.arr2);
//	vpoc_ramp_deceleration_time_pos = q_int_array.int16;
//	
//	//6336
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 1;
//	z_EEPROM_offset = 2;	//2 BYTES
//	z_bytes_for_xfer = 2;
//	Read_from_EX_EEPROM (q_int_array.arr2);
//	vpoc_ramp_deceleration_time_neg = q_int_array.int16;
//	
//	//6340
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 1;
//	z_EEPROM_offset = 4;	//1 BYTES
//	z_bytes_for_xfer = 1;
//	Read_from_EX_EEPROM ((unsigned char *)vpoc_directional_dependent_gain_type);
//	
//	//6341
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 1;
//	z_EEPROM_offset = 5;	//4 BYTES
//	z_bytes_for_xfer = 4;
//	Read_from_EX_EEPROM (q_long_array.arr4);
//	vpoc_dir_dependent_gain_factor = q_long_array.long32;
//	
//	//6342
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 1;
//	z_EEPROM_offset = 9;	//1 BYTES
//	z_bytes_for_xfer = 1;
//	Read_from_EX_EEPROM ((unsigned char *)vpoc_dead_band_compensation_type);
//	
//	//6343
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 1;
//	z_EEPROM_offset = 10;	//2 BYTES
//	z_bytes_for_xfer = 2;
//	Read_from_EX_EEPROM (q_int_array.arr2);
//	vpoc_dead_band_compensation_A_side = q_int_array.int16;
//	
//	//6344
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 1;
//	z_EEPROM_offset = 12;	//2 BYTES
//	z_bytes_for_xfer = 2;
//	Read_from_EX_EEPROM (q_int_array.arr2);
//	vpoc_dead_band_compensation_B_side = q_int_array.int16;
//	
//	//6345
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 1;
//	z_EEPROM_offset = 14;	//2 BYTES
//	z_bytes_for_xfer = 2;
//	Read_from_EX_EEPROM (q_int_array.arr2);
//	vpoc_dead_band_compensation_threshold = q_int_array.int16;
//	
//	//6346
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 1;
//	z_EEPROM_offset = 16;	//1 BYTES
//	z_bytes_for_xfer = 1;
//	Read_from_EX_EEPROM ((unsigned char *)vpoc_characteristic);
//	
//	//6351
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 1;
//	z_EEPROM_offset = 17;	//1 BYTES
//	z_bytes_for_xfer = 1;
//	Read_from_EX_EEPROM ((unsigned char *)vpoc_control_monitoring_type);
//	
//	//6352
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 1;
//	z_EEPROM_offset = 18;	//2 BYTES
//	z_bytes_for_xfer = 2;
//	Read_from_EX_EEPROM (q_int_array.arr2);
//	vpoc_control_monitoring_delay_time = q_int_array.int16;
//	
//	//6353
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 1;
//	z_EEPROM_offset = 20;	//2 BYTES
//	z_bytes_for_xfer = 2;
//	Read_from_EX_EEPROM (q_int_array.arr2);
//	vpoc_control_monitoring_threshold = q_int_array.int16;
//	
//	//6354
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 1;
//	z_EEPROM_offset = 22;	//2 BYTES
//	z_bytes_for_xfer = 2;
//	Read_from_EX_EEPROM (q_int_array.arr2);
//	vpoc_control_monitoring_upper_threshold = q_int_array.int16;
//	
//	//6355
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 1;
//	z_EEPROM_offset = 24;	//2 BYTES
//	z_bytes_for_xfer = 2;
//	Read_from_EX_EEPROM (q_int_array.arr2);
//	vpoc_control_monitoring_lower_threshold = q_int_array.int16;
//	
//	//6370
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 1;
//	z_EEPROM_offset = 26;	//1 BYTES
//	z_bytes_for_xfer = 1;
//	Read_from_EX_EEPROM ((unsigned char *)vpoc_target_window_monitoring_type);
//	
//	//6371
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 1;
//	z_EEPROM_offset = 27;	//2 BYTES
//	z_bytes_for_xfer = 2;
//	Read_from_EX_EEPROM (q_int_array.arr2);
//	vpoc_target_monitoring_switch_on_time = q_int_array.int16;
//	
//	//6372
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 1;
//	z_EEPROM_offset = 29;	//2 BYTES
//	z_bytes_for_xfer = 2;
//	Read_from_EX_EEPROM (q_int_array.arr2);
//	vpoc_target_monitoring_switch_off_time = q_int_array.int16;
//	
//	//6373
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 2;
//	z_EEPROM_offset = 0;	//2 BYTES
//	z_bytes_for_xfer = 2;
//	Read_from_EX_EEPROM (q_int_array.arr2);
//	vpoc_target_monitoring_threshold = q_int_array.int16;
//	
//	//6374
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 2;
//	z_EEPROM_offset = 2;	//2 BYTES
//	z_bytes_for_xfer = 2;
//	Read_from_EX_EEPROM (q_int_array.arr2);
//	vpoc_target_monitoring_upper_threshold = q_int_array.int16;
//	
//	//6375
//	z_EEPROM_bank = BANK_GENERAL_DATA1;
//	z_EEPROM_page = 2;
//	z_EEPROM_offset = 4;	//2 BYTES
//	z_bytes_for_xfer = 2;
//	Read_from_EX_EEPROM (q_int_array.arr2);
//	vpoc_target_monitoring_lower_threshold = q_int_array.int16;
}
