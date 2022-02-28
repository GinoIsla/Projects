
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
extern unsigned char jIO_switch1_value;
extern unsigned char uIOin1Polarity;				// 0x6002 polarity
extern unsigned char uIOin1Filter;					// 0x6003 filter
extern unsigned char uIOin1IntEnable;				// 0x6005 enable interrupts
extern unsigned char uIOin1IntChange;				// 0x6006 interrupt on change
extern unsigned char uIOin1IntRise;					// 0x6007 interrupt on positive edge
extern unsigned char uIOin1IntFall;					// 0x6008 interrupt on negative edge

extern unsigned int jIO_Potentiometer_1;					// 0x6401,01, Analogue,16 bit, input
extern unsigned int jIO_Potentiometer_2;					// 0x6401,02, Analogue,16 bit, input
extern unsigned int jIO_Potentiometer_3;					// 0x6401,03, Analogue,16 bit, input
extern unsigned int jIO_Potentiometer_4;					// 0x6401,04, Analogue,16 bit, input

extern unsigned char uLocalRcvBuffer[8];			// local buffer fot RPDO1
extern rom struct _DICTIONARY_OBJECT_TEMPLATE *od_entry;
extern struct _sdo_request_type;
extern rom unsigned char const_vpoc_num_entries_1;
extern int vpoc_device_code_number;

extern unsigned char z_number_of_nodes;				//2000,0 number of receiver nodes for potentiometer values
extern unsigned char z_sw_node;						//2000,1 receiver of jIO_switch1_value
extern unsigned char z_node_1;						//2000,2 receiver of jIO_Potentiometer_1 value
extern unsigned char z_node_2;						//2000,3 receiver of jIO_Potentiometer_2 value
extern unsigned char z_node_3;						//2000,4 receiver of jIO_Potentiometer_3 value
extern unsigned char z_node_4;						//2000,5 receiver of jIO_Potentiometer_4 value





