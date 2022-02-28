/*****************************************************************************
 *Programmer:  Gino Isla for Lambda Sistemi, Milano
 *Declare prototypes
 *****************************************************************************/

#include	"jcan.h"

/* -------- Prototypes: -------------- */
void InterruptRxCAN(void);
void CheckBusError(void);
void CanOut(void);
void CanIn (void);
void init_cip ( void );   
void Delay1KTCYx ( unsigned char);
void SendBoot (void);
void SendEmergency (void);
void SendHeartbeat (void);
void Stop_unit(void);
void treat_SDO (M_TXB_BUFF);
void Access_dictionary (unsigned char);
void Send_Init_Download_resp(int, unsigned char);
void Send_SDO_Abort(int, unsigned char, char);
void Send_Download_resp(unsigned char);
void Send_Init_Upload_resp(void);
void Send_Upload_Segment(unsigned char, unsigned char, unsigned char);
unsigned char find_dictionary_entry(unsigned int, char);
void Download_to_RAM (char *, char *, int);
void Upload_from_RAM (char *, char *, int);
void Upload_from_ROM (rom unsigned char *, char *, int);
unsigned char Download_to_EEPROM (unsigned char * from, int n);
void Init_profile_data (void);
void WriteEEprom_OnBoard (unsigned char,unsigned char);
unsigned char ReadEEprom_OnBoard (unsigned char);
void Control (void);
void TimingControl (void);
void device_enable (void);
void device_disable (void);
void getActualValue(void);
void INIT_RT(void);
void initialize_slaves(void);
//
