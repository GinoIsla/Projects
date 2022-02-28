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

#include "japplication_data.h"
//see EEPROM_initializer.c and EEPROM_data.def for external EEPROM initialization strings

rom unsigned long rCO_DevType 						= 0x01070191;									//object 1000, 191h=Joystick, io func=7=dig.outputs, spec func=joystick
rom unsigned char rCO_DevName[] 					= "Joystick___CO_Italia    ";					//object 1008
rom unsigned char rCO_DevHardwareVer[] 				= "V1.0";										//object 1009, doubly mapped as 6050
rom unsigned char rCO_DevSoftwareVer[] 				= "V1.0";										//object 100A
rom unsigned char rCO_DevIdentityIndx 				= 0x4;											//object 1018,0 number of sub-indecees in 
unsigned long rCO_DevVendorID 						= 0x12345678L;									//object 1018,1 
unsigned long rCO_DevProductCode 					= 0x87654321L;									//object 1018,2
unsigned long rCO_DevRevNo 							= 0x12345678L;									//object 1018,3
unsigned long rCO_DevSerialNo 						= 0x87654321L;									//object 1018,4, (not the same as 6052)

//Manufacturer specific data
//-----------------------------DS-401 / Apendix 1 Joystick PROFILE --------------
unsigned char jIO_switch1_value						= 0;											// 0x6000,01 digital inputs 1 thru 8 (other digital inputs in 6000,02, etc.)
unsigned char uIOin1Polarity						= 0;											// 0x6002,01 polarity
unsigned char uIOin1Filter							= 0xFF;											// 0x6003,01 filter - all enabled
unsigned char uIOin1IntEnable						= 0;											// 0x6005,01 GLOBAL interrupts disabled
unsigned char uIOin1IntChange						= 0;											// 0x6006,01 interrupt on change disABLED
unsigned char uIOin1IntRise							= 0;											// 0x6007 interrupt on positive edge disabled
unsigned char uIOin1IntFall							= 0;											// 0x6008 interrupt on negative edge disabled
unsigned int jIO_Potentiometer_1;																	// 0x6401,01, Analogue,16 bit, input
unsigned int jIO_Potentiometer_2;																	// 0x6401,02, Analogue,16 bit, input
unsigned int jIO_Potentiometer_3;																	// 0x6401,03, Analogue,16 bit, input
unsigned int jIO_Potentiometer_4;																	// 0x6401,04, Analogue,16 bit, input


//----------------------------- MANUIFACTURER SPECIFIC PROFILE DATA --------------
////The following data is banked because of space reasons
#pragma udata temp_data
unsigned char SDO_RX_HOLD_DATA[128];
////
//#pragma udata ramp_up_data
//unsigned char mspd_ramp_up_buffer[128];															//object 0x2000, Ramp in Manuf. Specific Profile Data
//....
//









