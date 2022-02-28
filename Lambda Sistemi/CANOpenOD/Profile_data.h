
/*****************************************************************************
 * Provides locations of OD to the dictionary
 * Derived from Microchip CANopen Stack (Device Info)
 * by
 * Gino Isla for Lambda Sistemi, Milano
 *****************************************************************************/

extern rom unsigned long rCO_DevType; 
extern rom unsigned char rCO_DevName[]; 
extern rom unsigned char rCO_DevHardwareVer[];
extern rom unsigned char rCO_DevSoftwareVer[]; 

extern rom unsigned char rCO_DevIdentityIndx;
extern unsigned long rCO_DevVendorID; 
extern unsigned long rCO_DevProductCode;
extern unsigned long rCO_DevRevNo;
extern unsigned long rCO_DevSerialNo;
extern unsigned int Id;

extern unsigned char mspd_ramp_up_buffer[128];
extern unsigned char mspd_ramp_down_buffer[128];
extern unsigned char mspd_ramp_left_buffer[128];
extern unsigned char mspd_ramp_right_buffer[128];

extern rom unsigned char 	_uSDO1COMMIndx;

extern unsigned long uCO_DevManufacturerStatReg;
extern unsigned long uCO_DevPredefinedErrField;

extern unsigned char uCO_COMM_SYNC_COBID;
extern unsigned int uCO_COMM_NMTE_GuardTime;
extern unsigned char uCO_COMM_NMTE_LifeTimeFactor;
extern unsigned int uCO_COMM_NMTE_HeartBeat;

extern rom unsigned int uCO_COMM_SDO1_CLIENT_COBID;
extern rom unsigned int uCO_COMM_SDO1_SERVER_COBID;

extern rom unsigned int uCO_COMM_RPDO1_COBID;
extern rom unsigned int uCO_COMM_RPDO2_COBID;

extern rom unsigned int uCO_COMM_TPDO1_COBID;
extern rom unsigned int uCO_COMM_TPDO1_Type;
extern rom unsigned int uCO_COMM_TPDO2_COBID;
extern rom unsigned int uCO_COMM_TPDO2_Type;

//for device profile specific (objects at 6000h...)
extern unsigned char uLocalXmtBuffer[8];			// (6000,0 Local buffer for TPDO1
extern unsigned char uIOinFilter;					// 0x6003 filter
extern unsigned char uIOinPolarity;					// 0x6002 polarity
extern unsigned char uIOinIntChange;				// 0x6006 interrupt on change
extern unsigned char uIOinIntRise;					// 0x6007 interrupt on positive edge
extern unsigned char uIOinIntFall;					// 0x6008 interrupt on negative edge
extern unsigned char uIOinIntEnable;				// 0x6005 enable interrupts

extern unsigned char uLocalRcvBuffer[8];			// local buffer fot RPDO1
extern rom struct _DICTIONARY_OBJECT_TEMPLATE *od_entry;
extern struct _sdo_request_type;
extern rom unsigned char const_vpoc_num_entries_1;

extern int vpoc_device_code_number;
extern M_CONTROL_WORD dev_control_word;
extern M_STATUS_WORD dev_status_word;
extern unsigned char device_mode;
extern unsigned char device_cntrl_mode;						//object 6043
extern M_ERROR_CODE ERROR_CODE;
extern unsigned char device_local;
extern unsigned char rCO_DevDescription[]; 
extern rom unsigned char rCO_DevModelDescription[]; 
extern rom unsigned char rCO_DevModelURL[];
extern unsigned char uIO_DevSetCode;
extern rom unsigned char rCO_DeviceVendorName[]; 
extern int vpoc_set_point;
extern int vpoc_actual_value;
extern int vpoc_demand_value;
extern int vopc_demand_ref_value;
extern int vpoc_demand_hold_set_point;
extern int vpoc_demand_upper_limit;
extern int vpoc_demand_lower_limit;
extern M_SCALING_FACTOR vpoc_demand_scaling_factor; //object 6322
extern int vpoc_demand_scaling_offset;
extern int vpoc_demand_zero_correction_offset;
extern signed char vpoc_demand_ramp_type;
extern int vpoc_ramp_acceleration_time;
extern int vpoc_ramp_acceleration_time_pos;
extern int vpoc_ramp_acceleration_time_neg;
extern int vpoc_ramp_deceleration_time;
extern int vpoc_ramp_deceleration_time_pos;
extern int vpoc_ramp_deceleration_time_neg;
extern signed char vpoc_directional_dependent_gain_type;
extern unsigned long vpoc_dir_dependent_gain_factor; //object 6341
extern signed char vpoc_dead_band_compensation_type;	//object 6342
extern int vpoc_dead_band_compensation_A_side;
extern int vpoc_dead_band_compensation_B_side;
extern int vpoc_dead_band_compensation_threshold;	//object 6345
extern signed char vpoc_characteristic;
extern rom int vpoc_control_deviation;
extern signed char vpoc_control_monitoring_type;
extern int vpoc_control_monitoring_delay_time;
extern int vpoc_control_monitoring_threshold;
extern int vpoc_control_monitoring_upper_threshold;
extern int vpoc_control_monitoring_lower_threshold;
extern signed char vpoc_target_window_monitoring_type;
extern int vpoc_target_monitoring_switch_on_time;
extern int vpoc_target_monitoring_switch_off_time;
extern int vpoc_target_monitoring_threshold;
extern int vpoc_target_monitoring_upper_threshold;
extern int vpoc_target_monitoring_lower_threshold;





