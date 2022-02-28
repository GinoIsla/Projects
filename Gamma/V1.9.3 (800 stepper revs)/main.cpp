/*****************************************************************************
 *Programmer:  Gino Isla 2021, for Gamma Ray
 * Saquatch main
*Change committed 9/22/21
 *****************************************************************************/

// DO NOT CHANGE THE ORDER OF THESE INCLUDES
#include "ClearCore.h"
#include "EthernetTcpServer.h"
#include "MotorDriver.h"
#include "Prototype.h"
#include "SasquatchOperation.h"
#include "..\ClearCore-library-master\libClearCore\inc\IpAddress.h"
#include "ProcessPacket.cpp"		//Sasquatch	local functions to decode packet received
#include "StepperMotorControl.cpp"
#include "ServoMotorControl.cpp"

#include "SdCardDriver.h"
#define SDCard SdCard
char readBuff[30] = {0};


union data_store{
	uint8_t data_in[MAX_PACKET_SIZE];		//raw command
	char data_chars[MAX_PACKET_SIZE];
} data_input;

EthernetTcpServer server = EthernetTcpServer(8888);

int comms_Task = 0;

#define IDLE_LOOP_COUNT 300

void Interrupt1(){InterruptHandler(1);}
void Interrupt2(){InterruptHandler(2);}
void Interrupt3(){InterruptHandler(3);}
void Interrupt4(){InterruptHandler(4);}

// *************************************************************************************************************
// InterruptHandler():
// Handles interrupts from motor lens limit reached
// *************************************************************************************************************
void InterruptHandler(int int_type){
	
	InputMgr.InterruptsEnabled(false);			// Disable interrupts until this interrupt is handled
//	Delay_ms(250); //debounce period // =====================> TO BE REVISED WHEN A REAL HALL SENSOR IS USED!!! 

	switch (int_type) {

		case 1:													// Camera has reached the rear Limit Sensor 
			CamSteps = 0;											// Keep motor from cycling again
			if (Cam_restarting_phase < 2){								// InitCamStepper() takes care of returning the camera to 0 position
				InitCamStepper();
				return;
			}
			CamMotorRunning = true;

			if (Cam_reversing){									// Cam was reversing past the rear sensor!
				Cam_overflow = true;
			}
			
			else if (CamHomingToPos || CamGoingHome) {			// Cam going home or to absolute position?
				CamStepperHome();
			}
			break;
		
		case 2:													// Camera Limit Sensor Front
			CamSteps = 0;											// Lens Limit Sensor Front, Stop the motor
			CamMotorRunning = true;									// LensMotorRunning will be false next idle loop
			Cam_overflow = true;
			clean_report_buffer();
			build_report(CamFront, false, 0, true);
			send_report();
			break;
		
		case 3:													// Lens Limit Sensor Rear, Stop the motor
			LensSteps = 0;											// Keep motor from cycling again
			if (Lens_restarting_phase < 2){								// InitLensStepper() takes care of returning the lens to 0 position
				InitLensStepper();
				return;
			}
			LensMotorRunning = true;

			if (Lens_reversing){									// Lens was reversing past the rear sensor!
				Lens_overflow = true;
			}
			
			else if (LensHomingToPos || LensGoingHome) {				// Lens going home or to absolute position?
				LensStepperHome();
			}
			break;
		
		case 4:											
			LensSteps = 0;								//Lens Limit Sensor Front, Stop the motor
			LensMotorRunning = true;					// LensMotorRunning will be false next idle loop
			Lens_overflow = true;
			clean_report_buffer();
			build_report(LensFront, false, 0, true);
			send_report();
			break;		
	}
	InputMgr.InterruptsEnabled(true);			// Enable interrupts
}

// *************************************************************************************************************
// clean_report_buffer():
// Delete everything in final_string
// *************************************************************************************************************
void clean_report_buffer() {
	for(int i = 0 ; i < MAX_REPORT_SIZE ; i++){report_buffer.data_chars[i] = char (NULL);}	//clean-up report buffer
}
	
// *************************************************************************************************************
// send_report():
// Utility procedure to add a string to final_string.data_chars
// Input: * to the string, int_included (integer to be converted to ascii)
// *************************************************************************************************************
void build_report (char * str, bool int_included, int val, bool EOR) {
	char asc_val[8];

		strcpy(report_buffer.data_chars + string_length(report_buffer.data_chars), str);

		if (int_included) {
			strcpy(report_buffer.data_chars + string_length(report_buffer.data_chars), "(");		// convert the int to ascii and put it between ()
			strcpy(report_buffer.data_chars + string_length(report_buffer.data_chars), itoa(val, asc_val, 10));
			strcpy(report_buffer.data_chars + string_length(report_buffer.data_chars), ")");
		}
				
		if (EOR) {strcpy(report_buffer.data_chars + string_length(report_buffer.data_chars), "]\r");}		// END OF REPORT?
}

// *************************************************************************************************************
// send_report():
// Send an autonomous report to the TCP server if connected
// *************************************************************************************************************
void send_report(){
		if (alarmClient.Connected()){
			alarmClient.Send(report_buffer.data_chars);
			clean_report_buffer();
		}
   }

// *************************************************************************************************************
// init_CCIO()
// Initialize CCIO ports to OUTPUT_DIGITAL and start them.
// EXEPTION: CCIOA-7, will e used for now to discriminate between the TEST IP and the official GAMMA_IP. To use the TEST_IP, 
//			 connect port CCIOA-7 to low  
// *************************************************************************************************************
void init_CCIO() {
	
		CcioPort.Mode(Connector::CCIO);			// CCIO connects to ClearCore COM0 - see #define in SasquatchOperation.h
		CcioPort.PortOpen();
		
		ccioBoardCount = CcioMgr.CcioCount();					// number of CCIO boards

		if (ccioBoardCount > 0){		//CCIO connected?
		
			CcioMgr.PinByIndex(static_cast<ClearCorePins>(CLEARCORE_PIN_CCIOA0))->Mode(Connector::OUTPUT_DIGITAL);
			CcioMgr.PinByIndex(static_cast<ClearCorePins>(CLEARCORE_PIN_CCIOA1))->Mode(Connector::OUTPUT_DIGITAL);		// CamStageStepperPulse
			CcioMgr.PinByIndex(static_cast<ClearCorePins>(CLEARCORE_PIN_CCIOA2))->Mode(Connector::OUTPUT_DIGITAL);		// CamStageDirection
			CcioMgr.PinByIndex(static_cast<ClearCorePins>(CLEARCORE_PIN_CCIOA3))->Mode(Connector::OUTPUT_DIGITAL);		// LensStageStepperPulse
			CcioMgr.PinByIndex(static_cast<ClearCorePins>(CLEARCORE_PIN_CCIOA4))->Mode(Connector::OUTPUT_DIGITAL);		// LensStageDirection 
			CcioMgr.PinByIndex(static_cast<ClearCorePins>(CLEARCORE_PIN_CCIOA5))->Mode(Connector::OUTPUT_DIGITAL);
			CcioMgr.PinByIndex(static_cast<ClearCorePins>(CLEARCORE_PIN_CCIOA6))->Mode(Connector::OUTPUT_DIGITAL);
			
			CcioMgr.PinByIndex(static_cast<ClearCorePins>(CLEARCORE_PIN_CCIOA7))->Mode(Connector::INPUT_DIGITAL);		// used to determine IP address
			
			CcioMgr.PinByIndex(static_cast<ClearCorePins>(CLEARCORE_PIN_CCIOA0))->State(OUTPUT_LOW);
			CcioMgr.PinByIndex(static_cast<ClearCorePins>(CLEARCORE_PIN_CCIOA1))->State(OUTPUT_LOW);
			CcioMgr.PinByIndex(static_cast<ClearCorePins>(CLEARCORE_PIN_CCIOA2))->State(OUTPUT_LOW);
			CcioMgr.PinByIndex(static_cast<ClearCorePins>(CLEARCORE_PIN_CCIOA3))->State(OUTPUT_LOW);
			CcioMgr.PinByIndex(static_cast<ClearCorePins>(CLEARCORE_PIN_CCIOA4))->State(OUTPUT_LOW);
			CcioMgr.PinByIndex(static_cast<ClearCorePins>(CLEARCORE_PIN_CCIOA5))->State(OUTPUT_LOW);
			CcioMgr.PinByIndex(static_cast<ClearCorePins>(CLEARCORE_PIN_CCIOA6))->State(OUTPUT_LOW);
		}
	}
	
// *************************************************************************************************************
// init_ONBOARD_ports():
// Set IO port 0 through 4 as OUTPUT with PWM. The range of the PWD, for ClearCore, runs from 0 (off)
// to 255 (100% duty cycle)
// *************************************************************************************************************
void init_ONBOARD_ports() {

	CcioMgr.PinByIndex(static_cast<ClearCorePins>(CLEARCORE_PIN_CCIOA0))->State(OUTPUT_HIGH); // turn LED power on

	//Setup hall sensor ports
	ConnectorA9.Mode(Connector::INPUT_DIGITAL);		//Camera Limit Sensor Rear
	ConnectorA10.Mode(Connector::INPUT_DIGITAL);	//Camera Limit Sensor Front
	ConnectorA11.Mode(Connector::INPUT_DIGITAL);	//Lens Limit Sensor Rear
	ConnectorA12.Mode(Connector::INPUT_DIGITAL);	//Lens Limit Sensor Front
	
	//interrupts for hall switches: when they go high, enabled
	ConnectorA9.InterruptHandlerSet(Interrupt1, InputManager::RISING);		//Camera Limit Sensor Rear
	ConnectorA10.InterruptHandlerSet(Interrupt2, InputManager::RISING);		//Camera Limit Sensor Front
	ConnectorA11.InterruptHandlerSet(Interrupt3, InputManager::RISING);		//Lens Limit Sensor Rear
	ConnectorA12.InterruptHandlerSet(Interrupt4, InputManager::RISING);		//Lens Limit Sensor Front
	
	InputMgr.InterruptsEnabled(true);		// Enable interrupts
	
	//LED outputs
//	Delay_ms(1000);								// delay for relay to turn on		// <================= To be checked
	
	led_state.all_leds = 0;						// all ports OFF
	ConnectorIO0.Mode(Connector::OUTPUT_PWM);
	ConnectorIO1.Mode(Connector::OUTPUT_PWM);
	ConnectorIO2.Mode(Connector::OUTPUT_PWM);
	ConnectorIO3.Mode(Connector::OUTPUT_PWM);
	ConnectorIO4.Mode(Connector::OUTPUT_PWM);
	
	// IO-0 to IO-5 are "negative true" so 100% duty cycle is 0xff = 0V out
	ConnectorIO0.PwmDuty(MIN_PWM);		//R1
	ConnectorIO1.PwmDuty(MIN_PWM);		//R2
	ConnectorIO2.PwmDuty(MIN_PWM);		//Green
	ConnectorIO3.PwmDuty(MIN_PWM);		//Blue
	ConnectorIO4.PwmDuty(MIN_PWM);		//IR
}

// *************************************************************************************************************
// check_CCIO_connection(): 
// Setup the TCP / IP stack.
// This controller acts as the server to the main frame client
// *************************************************************************************************************
void Check_CCIO_connection(){
	
	if (CcioMgr.LinkBroken()) {					// if the link with CCIO is broken, this call will try to restore it
		init_CCIO();
		init_ONBOARD_ports();
		
		if (!CCIO_alarm_sent){	
				build_report(CCIO_disconnect, false, 0, true);
				send_report();
				CCIO_alarm_sent = true;
		}
	}
	else if (CCIO_alarm_sent == true)			// if we are alarmed and the link is not broken, send alarm off
	{
		build_report(CCIO_connected, false, 0, true);
		send_report();		
		CCIO_alarm_sent = false;			// CCIO connection is up
	}		
}

// *************************************************************************************************************
// init_TCPIP_connection(): 
// Setup the TCP / IP stack.
// This controller acts as the server to the main frame client
// *************************************************************************************************************
bool init_TCPIP_connections() {
bool volatile useTestIP = false;

			ip = GAMMA_IP;					// default IP address
			alarmIp = GAMMA_serverIp;

			useTestIP = CcioMgr.PinByIndex(static_cast<ClearCorePins>(CLEARCORE_PIN_CCIOA7))->State();
			if (useTestIP) {		// if CCIOA-7 is shorted, use the TEST ip addresses
				ip = TEST_IP;
				alarmIp = TEST_serverIp;
			}
			EthernetMgr.Setup();		// Start Ethernet manager

//Init IP
#if DHCP_AUTO		//	(see SasquatchOperation.h)
			if (EthernetMgr.DhcpBegin()){EthernetMgr.Refresh();}
#else
				
			EthernetMgr.LocalIp(ip);			// MANUAL IP address:
			EthernetMgr.GatewayIp(gateway);
			EthernetMgr.NetmaskIp(netmask);
#endif
			EthernetMgr.Refresh();

//START TCP SERVER
			server.Begin();						// Start listening for TCP connections
			return true;
}

// *************************************************************************************************************
// CheckClientConnection:
// This controller acts as the CLIENT to the main frame SERVER.
// The TCP server has to be up and running to receive Alarms generated from this TCP client
// *************************************************************************************************************
void CheckClientConnection(){
		
	if (!client_connnected && --wait_for_client_count == 0){
		client_connnected = alarmClient.Connect(alarmIp, 8889);		
		
		if (!client_connnected)	{	
			wait_for_client_count = 30;
		}
	}
}

// *************************************************************************************************************
// CheckTCPComms:
// The TCP link is up, check if there is communications from the main frame.
// This controller acts as the server to the main frame client
// *************************************************************************************************************
void CheckTCPComms(){
		
	TCPconnectionRunning = server.Ready();
	sasquatch_client[0] = server.Available();
	
	if (sasquatch_client[0].Connected()) {							// Client sending data?
		for(int i = 0 ; i < MAX_PACKET_SIZE ; i++){data_input.data_chars[i] = char (NULL);}		// clean-up command line first

		data_input.data_in[0] = '>';
		idx = 1;
		data_input.data_in[1] = sasquatch_client[0].Read();			// read till end of data
		while (sasquatch_client[0].BytesAvailable() > 0) {
			data_input.data_in[++idx] = sasquatch_client[0].Read();
		}
		sasquatch_client[0].Send(data_input.data_in, string_length(data_input.data_chars));		// echo command with '>' in front
		sasquatch_client[0].Send(cr_lf,1);
		sasquatch_client[0].Send(SerialProcessPacket(data_input.data_chars), string_length(final_string.data_chars));		// process command and send report, returns final_string
		
		for(int i = 0 ; i < MAX_REPORT_SIZE ; i++){final_string.data_chars[i] = char (NULL);}	//clean-up final buffer

	}
}
// *************************************************************************************************************
// SD_card_driver()
// Open and read the SD card
// *************************************************************************************************************
/* void SD_card_driver(){
		
	SDCard.PortMode(SerialBase::SPI);
	SDCard.PortOpen();
	
	readBuff[0] = 0;
	
	if (SDCard.PortIsOpen()){
		for(int i = 0 ; (readBuff[i] !=  SerialBase::EOB) ; i++) {
			readBuff[i] = SDCard.CharGet();
			}
		}

	FILE myFile;
	int16_t myChar[20] = {0};
	volatile bool dsErr = false;
	SpiTransferData(uint8_t data) --- only with SPIs - transfer a char
	int32_t SerialBase::SpiTransferData(uint8_t const *writeBuf, uint8_t *readBuf, int32_t len) - transfer a buffer
	bool SerialBase::SpiTransferDataAsync(uint8_t const *writeBuf, uint8_t *readBuf, int32_t len) { - read/write

	dsErr = SdCard.IsInFault();
	if (!dsErr){

for (int i = 0 ; i < 10 ; i++)
myChar[i] = SdCard.CharGet();
	}
}
*/

//**********************************************************************************************************
//access_SEEPROM()
// NVMCTRL fuses with SBLK = 1 and PSZ = 0
//**********************************************************************************************************

void access_SEEPROM(){

      
       /* wait for SmartEEPROM not busy */
       while (NVMCTRL->SEESTAT.bit.BUSY);
      
       /* write to EEPROM like writing a RAM location. Perform an 8-, 16- or 32-bit write */
       SmartEEPROM8[0] = 0x12; // Write 8 Bits
	   SmartEEPROM8[1] = 0x22; // Write 8 Bits
	   SmartEEPROM8[2] = 0x32; // Write 8 Bits
	   SmartEEPROM8[3] = 0x42; // Write 8 Bits
	   
       while (NVMCTRL->SEESTAT.bit.BUSY){}
		   	   
	   TestIp = IpAddress(SmartEEPROM8[0], SmartEEPROM8[1], SmartEEPROM8[2], SmartEEPROM8[3]);


}

//**********************************************************************************************************
//**********************************************************************************************************
//											main();
//**********************************************************************************************************
//**********************************************************************************************************
int main(void) {

//		SD_card_driver();

		init_CCIO();
		init_ONBOARD_ports();
		init_TCPIP_connections();
		
		access_SEEPROM();

// ****************************************************************************************
// ************************************	          *****************************************
// *********************************  	MAIN LOOP   ***************************************
// ***********************************	           ****************************************
// ****************************************************************************************
		

		while(true) {		
			if (--comms_Task <= 0){
				CheckTCPComms();						// Check for data	from client main frame				
				Check_CCIO_connection();				// CCIO connection must be checked (and re-initialized if broken)
				CheckClientConnection();				// make sure AlarmServer can receive alarms
				CheckTapeIntegrity();
				comms_Task = IDLE_LOOP_COUNT;
			}
						
			if (master_initialize) {		// Motors can be initialized only after receiving the Master start command			
				if (Cam_restarting_phase < 3){
					InitCamStepper();
				} else if (CamMotorRunning){
					Cam_Motion_Handler();
				}

				if (Lens_restarting_phase < 3){
					InitLensStepper();
				} else if (LensMotorRunning){
					Lens_Motion_Handler();
				}
				if (capstan_moving){
					Capstan_Motion_Handler();
				}
				if(transport_initializing){
					init_transport_motors();
				}
			}
				
			Delay_us(1000);

		}
	}


	


