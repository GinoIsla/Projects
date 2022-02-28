
/*-------------------------------------------------------------*/
/* Version for Hydraulic valve */
/*-------------------------------------------------------------*/

//#define INIT_EXT_EEPROM

/* On board EEPROM ADDRESSES */
#define	EEPROM_NODE_ID				0
#define EEPROM_CAN_BAUDRATE			1
#define EEPROM_HEART_BEAT			2 //,3 (2 bytes)
#define EEPROM_SYNC_TIME			4
#define EEPROM_DEBOUNCE_RATE		5
#define EEPROM_Vendor_Id			6 	//x4
#define EEPROM_Product_code			10 	//x4
#define EEPROM_revision_numb		14 	//x4
#define EEPROM_serial_numb			18 	//x4


#define EE_CS			PORTCbits.RC7
#define	CON1_SSPEN_ena	0b00100000
#define	CON1_SSPEN_dis	0b11011111
#define CON1_CKP_hi		0b00010000	
#define CON1_CKP_lo		0b11101111	

#define STAT_CKE_Xact	0b01000000
#define STAT_CKE_Xidl	0b10111111

#define WRI_SR			1
#define WRITE			2
#define	READ			3
#define WRI_DI			4
#define RDSR			5
#define WRI_ENA			6

#define BANK_TEMP				0
#define BANK_RAMP_UP			1
#define BANK_RAMP_DOWN			2
#define BANK_RAMP_LEFT			3
#define BANK_RAMP_RIGHT			4
#define BANK_GENERAL_DATA1		5
#define BANK_DEV_DESCRIPTION	6
#define BANK_GENERAL_DATA2		7

#define DEV_CONTROL_WORD_0			0
#define DEV_DUMMY_DEV_CODE_NUM		0x1278
#define DEV_SETCODE_0				0
#define DEMAND_REFVALUE_100			100
#define HOLD_SETVALUE_0				50
#define DEMAND_UPPERLIMIT_100		80
#define DEMAND_LOWERLIMIT_0			-80
#define DEMAND_SCALEFACTOR11		0x00010001
#define DEMAND_SCALEOFFSET_0		0
#define DEMAND_ZEROCORRECTION_0		2
#define RAMP_ACCELTIME_0			4
#define RAMP_ACCELTIME_POS_0		3
#define RAMP_ACCELTIME_NEG_0		3		//test values????
#define RAMP_DECELTIME_0			5
#define RAMP_DECELTIME_POS_0		2
#define RAMP_DECELTIME_NEG_0		2
#define DIR_DEPENDNT_GAIN			0x00010001
#define DEAD_BAND_COMP_A			0
#define DEAD_BAND_COMP_B			0
#define DEAD_BAND_COMP_THRHLD		0
#define MONITORING_DELAY			0
#define MONITORING_TRHLD			0
#define MONITORING_TRHLD_UP			0
#define MONITORING_TRHLD_DOWN		0
#define MONITORING_SWITHCHON		0
#define MONITORING_SWITHCHOFF		0
#define TARGET_MONITORING_TRHLD		0
#define TARGET_MONTNG_TRHLD_UP		0
#define TARGET_MONTNG_TRHLD_DOWN	0



//TIMER 0
#define Fosc 25000000
#define T0_PreScale 64
#define T1_PreScale 8
#define Milisec 1000
#define	HALF_SECOND 500
#define Timer0tick_ms  ((Fosc)/(4*T0_PreScale*Milisec))-32	//(-32 lost accuracy in the division)
#define Timer1tick_ms 	0 - ((Fosc)/(4*T1_PreScale*Milisec))		//

typedef union scaling_factor
{
	struct
	{
		unsigned int numerator;
		unsigned int denominator;
	};
	unsigned long intlong;
}M_SCALING_FACTOR;

typedef union device_control_word
{
	struct
	{
		unsigned D:1;
		unsigned H:1;
		unsigned M:1;
		unsigned RFault:1;
		unsigned reserv1:2;
		unsigned SWparSet:2;
		unsigned cme_EnaPressure:1;
		unsigned cme_MasterSlave:1;
		unsigned cme_EnaLeakage:1;
		unsigned dev_mode:1;
		unsigned reserv2:1;
		unsigned vs:3;
	};
	unsigned int status_word;
}M_CONTROL_WORD;

enum Direction
{
	NEGATIVE = 0,
	POSITIVE,
};

enum Acceleration
{
	ACCELERATION = 0,
	DECELERATION,
};

enum Device_mode		//object 6042, does not include values -1 to -127 and 7 to 127
{
	DEV_MODE_NONE = 0,
	DEV_MODE_SETPOINT_VIA_BUS,
	DEV_MODE_INPUT_LOCAL,
	DEV_MODE_INSTALL_MODE,
	DEV_MODE_REF_MODE,
	DEV_MODE_AUTOMATIC,
	DEV_MODE_SINGLE_STEP,
	// 7 to 127 	reserved
	// -1 to –127 	manufacturer specific
};

enum Dev_control_mode		//object 6043
{
	CNTRL_MODE_NOT_DEFINEDE=0,
	CNTRL_MODE_OPEN_LOOP,
	CNTRL_MODE_CLOSED_LOOP,
	CNTRL_MODE_PRESS_VALVE_OL,
	CNTRL_MODE_PRESS_VALVE_CL,
	CNTRL_MODE_P_Q_CTRL_VALVE,
	CNTRL_MODE_OPEN_LOOP_MOVE,
	CNTRL_MODE_VELOC_CNTRL_AXIS,
	CNTRL_MODE_FORCE_AXIS,
	CNTRL_MODE_POS_CNTRL,
	CNTRL_MODE_POSTNL_DECEL
	// 11 to 127 	reserved
	// -1 to –127 	manufacturer specific
};

enum Device_Local
{
	DEVICE_LOCAL_CONTROL_WORD_VIA_CAN = 0,
	DEVICE_LOCAL_CONTROL_WORD_LOCAL
	// 2 to 127 	reserved
	// -1 to –127 	manufacturer specific

};

typedef union device_status_word
{
	struct
	{
	unsigned disabled:1;
	unsigned hold:1;
	unsigned deviceModeActiveEnable:1;
	unsigned Ready:1;
	unsigned localControl:1;
	unsigned warning:1;
	unsigned reserved:2;
	unsigned CM_reserved:1;
	unsigned CM_rampRunning:1;
	unsigned CM_limitTouched:1;
	unsigned CM_controlError:1;
	unsigned CM_targetReached:1;
	unsigned manfSpecific:3;
	};
	unsigned int status_word;

}M_STATUS_WORD;

enum ramp_type
{
	NO_RAMP_0 = 0,
	LINEAR_1,			//Linear (same value for all quadrants)
	LINEAR_2, 			//Linear (2 parameters for acceleration and deceleration, pos. and neg. values equal)
	LINEAR_3,		 	//Linear (4 parameters for all quadrants)
	SINE_SQR_4,			//Sine square
	PROF_GEN_5,			//Profile generator linear (drives positioning control only)
	PROF_GEN_6			//Profile generator sine square (drives positioning control only)
	// 7 to 127 	reserved
	// -1 to –128 	manufacturer specific
};

enum direction_dependant_gain	//object 6340
{
	NO_DIRECTIONAL_GAIN_0=0, 	//No directional dependent gain
	DIRECTIONAL_GAIN_1	 		//Directional dependent gain type 1
	//2 to 127 	reserved
	//-1 to -128 	manufacturer specific
};

enum dead_bad_compensation_type	//object 6342
{
	NO_DEADBAND_COMP_0=0, 	//No dead band compensation
	TYPE_1,				 	//Type 1
	TYPE_2 					//Type 2
	//3 to 127 	reserved
	//-1 to -128 	manufacturer specific
};

enum characteristic_compensation_type
{
	NO_COMPENSATION_0 = 0 	//No characteristic compensation
	//1 to 127 	reserved
	// -1 to –128 	manufacturer specific

};

enum monitoring_type	//object 6351
{
	NO_MONITORING_0=0, 	//No control monitoring
	MON_STANDARD_1,	 	//Standard control monitoring (upper and lower threshold)
	MON_STANDARD_2,	 	//Standard control monitoring (symmetric threshold)
	MON_DYNAMIC_3,	 	//Dynamic control monitoring (upper and lower threshold)
	MON_DYNAMIC_4 		//Dynamic control (symmetric threshold)
	//	5 to 127 	reserved
	// -1 to -128 	manufacturer specific
};

enum target_moni_type	//object 6370
{
	NO_TARGET_MON_0,	//No target window monitoring
	TARG_STANDARD_1, 	//Standard target window monitoring (upper and lower threshold)
	TARG_SYMMETRIC_2, 	//Target window monitoring (symmetric threshold)
	// 3 to 127 	reserved
	// -1 to -128 	manufacturer specific
};
