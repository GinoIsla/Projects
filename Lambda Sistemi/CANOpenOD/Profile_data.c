//Cutomized device specific RO information and RW Error information//
/*****************************************************************************
 *
 * Derived from Microchip CANopen Stack (Device Info)
 * by
 * Gino Isla for Lambda Sistemi Milano
 *
 * This code contains dictionary object initialization 
 * values which are likely to change from device to device
 *****************************************************************************/

#include "application_data.h"
//see EEPROM_initializer.c and EEPROM_data.def for external EEPROM initialization strings

rom unsigned long rCO_DevType 						= 0x00000198;									//object 1000, 198h=Hydraulic Valves, 0000=additional info, not modular
rom unsigned char rCO_DevName[] 					= "HydroValve_CO_Italia    ";					//object 1008
rom unsigned char rCO_DevHardwareVer[] 				= "V1.0";										//object 1009, doubly mapped as 6050
rom unsigned char rCO_DevSoftwareVer[] 				= "V1.0";										//object 100A
rom unsigned char rCO_DevIdentityIndx 				= 0x4;											//object 1018,0 number of sub-indecees in 
unsigned long rCO_DevVendorID 						= 0x12345678L;									//object 1018,1 
unsigned long rCO_DevProductCode 					= 0x87654321L;									//object 1018,2
unsigned long rCO_DevRevNo 							= 0x12345678L;									//object 1018,3
unsigned long rCO_DevSerialNo 						= 0x87654321L;									//object 1018,4, (not the same as 6052)

//add the address of the node id.....

//Manufacturer specific data

//Local data for objects of the device profile (6000h....)
unsigned char uLocalXmtBuffer[8];																	// 0x6000,0 Local buffer for TPDO1
unsigned char uIOinFilter;																			// 0x6003 filter
unsigned char uIOinPolarity;																		// 0x6002 polarity
unsigned char uIOinIntChange;																		// 0x6006 interrupt on change
unsigned char uIOinIntRise;																			// 0x6007 interrupt on positive edge
unsigned char uIOinIntFall;																			// 0x6008 interrupt on negative edge
unsigned char uIOinIntEnable;																		// 0x6005 enable interrupts

//-----------------------------DS-408 PROFILE Operating values--------------
rom unsigned char const_vpoc_num_entries_1 			= 1;		
rom unsigned char const_vpoc_num_entries_2 			= 2;		
rom unsigned char const_vpoc_num_entries_3 			= 3;		

M_CONTROL_WORD dev_control_word						= DEV_CONTROL_WORD_0;							//object 6040
M_STATUS_WORD dev_status_word						= 0; 											//object 6041
unsigned char device_mode 							= DEV_MODE_SETPOINT_VIA_BUS;					//object 6042
unsigned char device_cntrl_mode						= CNTRL_MODE_CLOSED_LOOP;						//object 6043
//extern M_ERROR_CODE ERROR_CODE																	//object 604E --> defined in main.c and used throughout
unsigned char device_local							= DEVICE_LOCAL_CONTROL_WORD_VIA_CAN;			//object 604F
//rom unsigned char rCO_DevHardwareVer[]															//object 6050 --> also object 1009, defined above
int vpoc_device_code_number							= DEV_DUMMY_DEV_CODE_NUM;						//object 6051 (2 bytes)
rom unsigned char DeviceSerialNo[]					= "001A2345";									//object 6052 (not the same as 1018,4)
unsigned char rCO_DevDescription[24];																//object 6053 (initialized from EEPROM)
rom unsigned char rCO_DevModelDescription[]			= "Insert Valve description";					//object 6054 (24 bytes)
rom unsigned char rCO_DevModelURL[]	   				= "http://www.HydraulicValves.com  ";			//object 6055 (32 bytes)
unsigned char uIO_DevSetCode		   				= DEV_SETCODE_0;								//object 6056
rom unsigned char rCO_DeviceVendorName[]			= "Lambda Sistemi,Milano,IT";					//object 0x6057  (24 bytes)
/*-----------------------------------------------------------------------------------------------------------------------------------------------*/
int	vpoc_set_point									= 0;		//test value						//object 6300,1
int	vpoc_actual_value								= 20;		//test value						//object 6301,1
int	vpoc_demand_value								= 0;											//object 6310,1
int	vopc_demand_ref_value 							= DEMAND_REFVALUE_100;							//object 6311,1 = 100%
int vpoc_demand_hold_set_point						= HOLD_SETVALUE_0;				 				//object 6314,1
int vpoc_demand_upper_limit							= DEMAND_UPPERLIMIT_100;						//object 6320,1
int vpoc_demand_lower_limit							= DEMAND_LOWERLIMIT_0;		 					//object 6321,1
M_SCALING_FACTOR vpoc_demand_scaling_factor			= DEMAND_SCALEFACTOR11;						 	//object 6322
int vpoc_demand_scaling_offset						= DEMAND_SCALEOFFSET_0;			 				//object 6323,1
int vpoc_demand_zero_correction_offset				= DEMAND_ZEROCORRECTION_0;						//object 6324,1
char vpoc_demand_ramp_type 							= LINEAR_1;										//object 6330
int vpoc_ramp_acceleration_time						= RAMP_ACCELTIME_0;								//object 6331,1
int vpoc_ramp_acceleration_time_pos					= RAMP_ACCELTIME_POS_0;							//object 6332,1
int vpoc_ramp_acceleration_time_neg					= RAMP_ACCELTIME_NEG_0;							//object 6333,1
int vpoc_ramp_deceleration_time						= RAMP_DECELTIME_0;								//object 6334,1
int vpoc_ramp_deceleration_time_pos					= RAMP_DECELTIME_POS_0;							//object 6335,1
int vpoc_ramp_deceleration_time_neg					= RAMP_DECELTIME_NEG_0;							//object 6336,1
char vpoc_directional_dependent_gain_type			= NO_DIRECTIONAL_GAIN_0;						//object 6340
unsigned long vpoc_dir_dependent_gain_factor		= DIR_DEPENDNT_GAIN;							//object 6341
signed char vpoc_dead_band_compensation_type 		= TYPE_1;										//object 6342
int vpoc_dead_band_compensation_A_side				= DEAD_BAND_COMP_A;								//object 6343,1
int vpoc_dead_band_compensation_B_side				= DEAD_BAND_COMP_B;								//object 6344,1
int vpoc_dead_band_compensation_threshold			= DEAD_BAND_COMP_THRHLD;						//object 6345,1
signed char vpoc_characteristic  					= NO_COMPENSATION_0;							//object 6346
rom int vpoc_control_deviation						= 0;											//object 6350,1
signed char vpoc_control_monitoring_type 			= NO_MONITORING_0;								//object 6351
int vpoc_control_monitoring_delay_time				= MONITORING_DELAY;								//object 6352,1
int vpoc_control_monitoring_threshold				= MONITORING_TRHLD;								//object 6353,1
int vpoc_control_monitoring_upper_threshold			= MONITORING_TRHLD_UP;							//object 6354,1
int vpoc_control_monitoring_lower_threshold			= MONITORING_TRHLD_DOWN;						//object 6355,1
signed char vpoc_target_window_monitoring_type 		= NO_TARGET_MON_0;								//object 6370
int vpoc_target_monitoring_switch_on_time			= MONITORING_SWITHCHON;							//object 6371,1
int vpoc_target_monitoring_switch_off_time			= MONITORING_SWITHCHOFF;						//object 6372,1
int vpoc_target_monitoring_threshold				= TARGET_MONITORING_TRHLD;						//object 6373,1
int vpoc_target_monitoring_upper_threshold			= TARGET_MONTNG_TRHLD_UP;						//object 6374,1
int vpoc_target_monitoring_lower_threshold			= TARGET_MONTNG_TRHLD_DOWN;						//object 6375,1


//----------------------------- MANUIFACTURER SPECIFIC PROFILE DATA --------------
//The following data is banked because of space reasons
#pragma udata temp_data
unsigned char SDO_RX_HOLD_DATA[128];
//
#pragma udata ramp_up_data
unsigned char mspd_ramp_up_buffer[128];															//object 0x2000, Ramp in Manuf. Specific Profile Data
//
#pragma udata ramp_down_data
unsigned char mspd_ramp_down_buffer[128];														//object 0x2001, Ramp in Manuf. Specific Profile Data
//
#pragma udata ramp_left_data
unsigned char mspd_ramp_left_buffer[128];														//object 0x2002, Ramp in Manuf. Specific Profile Data
//
#pragma udata ramp_right_data
unsigned char mspd_ramp_right_buffer[128];														//object 0x2003, Ramp in Manuf. Specific Profile Data
//











