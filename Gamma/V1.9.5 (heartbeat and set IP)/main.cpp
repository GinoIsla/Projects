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

char readBuff[30] = {0};
	
union data_store{
	uint8_t data_in[MAX_PACKET_SIZE];		//raw command
	char data_chars[MAX_PACKET_SIZE];
} data_input;

EthernetTcpServer server = EthernetTcpServer(DEFAULT_CLIENT_PORT);
//EthernetTcpServer server;

int comms_Task = 0;


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
		
		case 2:														// Camera Limit Sensor Front
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
// build_report():
// Utility procedure to add a string to final_string.data_chars
// Input: * to the string, int_included (integer to be converted to ascii)
// *************************************************************************************************************
void build_report (char * str, bool int_included, int val, bool EOR) {
	char asc_val[8];

		strcpy(report_buffer.data_chars + string_length(report_buffer.data_chars), str);

		if (int_included) {
//			strcpy(report_buffer.data_chars + string_length(report_buffer.data_chars), "(");		// convert the int to ascii and put it between ()
			strcpy(report_buffer.data_chars + string_length(report_buffer.data_chars), itoa(val, asc_val, 10));
//			strcpy(report_buffer.data_chars + string_length(report_buffer.data_chars), ")");
		}
				
		if (EOR) {strcpy(report_buffer.data_chars + string_length(report_buffer.data_chars), "]\r");}		// END OF REPORT?
}

// *************************************************************************************************************
// send_report():
// Send an autonomous report to the TCP server if connected
// *************************************************************************************************************
void send_report(){
	
		if (alarmClient.Connected()){			// this device is client
			alarmClient.Send(report_buffer.data_chars);
			clean_report_buffer();
		}
		else {
			CheckClientConnection();	// try to reconnect if the connection was lost
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
// Test the connection to CCIO and report if it changed
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
// get_TCPIP_addresses(): 
// Get the correct IP address for client and server (as seen from this C software)
// First validate that there is a valid address and get it if there is
// If not in EEPROM, test the port that indicates if this is  test setup or use the default addresses
// *************************************************************************************************************
void get_TCPIP_addresses() {
	bool volatile useTestIP = false;
	useTestIP = CcioMgr.PinByIndex(static_cast<ClearCorePins>(CLEARCORE_PIN_CCIOA7))->State(); //if CCIOA-7 is shorted, use the TEST ip addresses

		read_SEEPROM(Client_valid, newIp);	// read validation code 
		if (newIp[0] == VAL_CODE) {
			read_SEEPROM(Client_EEPROM8, newIp);
			ip = IpAddress(newIp[0], newIp[1], newIp[2], newIp[3]);
		}
		else if (useTestIP) {
				ip = TEST_IP;
		}
		else {
			ip = GAMMA_IP;				// default
		}
		
		read_SEEPROM(Server_valid, newIp);
		if (newIp[0] == VAL_CODE) {
			read_SEEPROM(Server_EEPROM8, newIp);
			alarmIp = IpAddress(newIp[0], newIp[1], newIp[2], newIp[3]);
		}
		else if (useTestIP) {
				alarmIp = TEST_serverIp;
		}
		else {
			alarmIp = GAMMA_serverIp;				// default
		}
}

// *************************************************************************************************************
// get_Port_number() 
// Read the port number where reports and alarms will be sent to the external server
// *************************************************************************************************************
int get_Port_number(){
	
		read_SEEPROM(Server_Port_valid, newIp);
		if (newIp[0] == VAL_CODE) {
			read_SEEPROM(Server_Port_EEPROM, newIp);		// reads bytes, convert to word
			Server_Port_Id.bytes.low_byte = newIp[0];
			Server_Port_Id.bytes.high_byte = newIp[1];
			Server_Port = Server_Port_Id.whole_word;
		}
		else {
			Server_Port = DEFAULT_SERVER_PORT;
		}
		return (int) Server_Port;
}
// *************************************************************************************************************
// get_server_port():
// Read this device's server port from EEPROM
// This controller is a SERVER to the main frame CLIENT for receiving commands
// This controller is a CLIENT to the main frame SERVER for sending reports
// *************************************************************************************************************
int get_server_port() {
	
		read_SEEPROM(Client_Port_valid, newIp);
		if (newIp[0] == VAL_CODE) {
			read_SEEPROM(Client_Port_EEPROM, newIp);		// reads bytes, convert to word
			Server_Port_Id.bytes.low_byte = newIp[0];		// variable Server_Port_Id is being reused 
			Server_Port_Id.bytes.high_byte = newIp[1];
			Server_Port = Server_Port_Id.whole_word;
		}
		else {
			Server_Port = DEFAULT_CLIENT_PORT;
		}
	return (int) Server_Port;
}

// *************************************************************************************************************
// init_TCPIP_connection(): 
// Setup the TCP / IP stack.
// This controller is a SERVER to the main frame for receiving commands
// This controller is a CLIENT to the main frame for sending reports
// *************************************************************************************************************
bool init_TCPIP_connections() {
	
		get_TCPIP_addresses();		// gets IP of this controllers client and server addresses
		Dest_Server_Port = get_Port_number();			// gets the port ID for this controller's client (to send reports to the server)
		
		server = EthernetTcpServer(get_server_port());		// read the server from EEPROM
		
		EthernetMgr.Setup();		// Start Ethernet manager

//Init IP
#if DHCP_AUTO		//	(see SasquatchOperation.h)
		if (EthernetMgr.DhcpBegin()){EthernetMgr.Refresh();}
#else
				
		EthernetMgr.LocalIp(ip);			// MANUAL IP address:
		EthernetMgr.GatewayIp(gateway);
		EthernetMgr.NetmaskIp(netmask);
#endif

//START TCP SERVER
		client_connnected = alarmClient.Connect(alarmIp, Dest_Server_Port);		//start this client (reports)

//		client_connnected = alarmClient.Connect(alarmIp, get_Port_number());		//start this client (reports)
		
		server.Begin();						// Start listening for commands
		
		EthernetMgr.Refresh();
		
		return true;

}

// *************************************************************************************************************
// CheckClientConnection:
// This ClearCore controller acts as the CLIENT to the main frame SERVER.
// The TCP server (main frame) has to be up and running to receive Alarms generated from this TCP client
// *************************************************************************************************************
void CheckClientConnection(){
	
	EthernetMgr.Refresh();			// // Keep the connection alive
	
	client_connnected = alarmClient.Connected();
		
	if (!client_connnected && --wait_for_client_count <= 0){
		client_connnected = alarmClient.Connect(alarmIp, Dest_Server_Port);		
		
		if (!client_connnected)	{	
			wait_for_client_count = 3;
		}
	}
}

// *************************************************************************************************************
// CheckTCPComms:
// The TCP link is up, check if there is communications from the main frame client.
// If its a Heartbeat check from desk top client, acknowledge and stop processing, if it's an echo to our heartbeat
// towards the desktop server, just discard it for now
// *************************************************************************************************************
void CheckTCPComms(){
	
char * pch;

	if (!EthernetMgr.PhyLinkActive()) {
		init_TCPIP_connections();
	}
	else {	
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
			
			// Check if this command is just an echo of our Heartbeat to the Master, if it is, just discard
			pch = strstr (data_input.data_chars,"DesktopServerCheck");
			if (pch != NULL) {
				return;	
			}
			
			sasquatch_client[0].Send(data_input.data_in, string_length(data_input.data_chars));		// echo command with '>' in front
			
			pch = strstr (data_input.data_chars,"ClearCoreServerCheck");		// if it's a Heartbeat from the desktop client, after ack discard
			if (pch != NULL) {
				return;	
			}
			
			sasquatch_client[0].Send(cr_lf,1);
			sasquatch_client[0].Send(SerialProcessPacket(data_input.data_chars), string_length(final_string.data_chars));		// process command and send report, returns final_string
		
			for(int i = 0 ; i < MAX_REPORT_SIZE ; i++){final_string.data_chars[i] = char (NULL);}	//clean-up final buffer

		}
	}
}

//**********************************************************************************************************
//write_SEEPROM()
// NVMCTRL fuses with SBLK = 1 and PSZ = 2
//**********************************************************************************************************
void write_SEEPROM(uint8_t * EE_ADDRESS, uint8_t * str, int num_bytes){
      
       /* wait for SmartEEPROM not busy */
      while (NVMCTRL->SEESTAT.bit.BUSY){}
      for (int i = 0; i < num_bytes ; i++){
		  EE_ADDRESS[i] = str[i];
	  }	   
}
//**********************************************************************************************************
//read_SEEPROM()
// NVMCTRL fuses with SBLK = 1 and PSZ = 2
//**********************************************************************************************************
void read_SEEPROM(uint8_t * EE_ADDRESS, uint8_t * str){
      
       /* wait for SmartEEPROM not busy */
       while (NVMCTRL->SEESTAT.bit.BUSY){}
		   	   
		for (int i = 0; i < 4 ; i++){
		   str[i] = EE_ADDRESS[i];
		}
}

//**********************************************************************************************************
// init_Heartbeat()
// Read the interval between heartbeats in EEPROM. 
// NOTE: We call this functions  every 300ms (during the idle loop) so the approximate value in seconds
// is obtained by multiplying 3 * the value in seconds 
//**********************************************************************************************************
void init_Heartbeat(){
	interval_count = HEARTBEAT_COUNT;
	
		read_SEEPROM(Interval_valid, newIp);
			
		if (newIp[0] == VAL_CODE) {
			read_SEEPROM(Heartbit_Interval_EEPROM, newIp);		// reads bytes, convert to word
			interval_count = newIp[0] * 3;				// 
		}
}

//**********************************************************************************************************
//Send_heartbeat()
// Periodic check of the main frame server
//**********************************************************************************************************
void Send_heartbeat(){
	
	if (--heartbit_count <= 0) {
		build_report (Server_check, true, ++heartbit_verify, true);
		send_report();
		heartbit_count = interval_count;
		
		if (heartbit_verify >= 10000){
			heartbit_verify = 0;
		}
	}
}

//**********************************************************************************************************
//**********************************************************************************************************
//											main();
//**********************************************************************************************************
//REMINDER: UPDATE VERSION NUMBER - now (Version: 01.09.5)
//**********************************************************************************************************

int main(void) {

		init_CCIO();
		init_ONBOARD_ports();
		init_TCPIP_connections();
		init_Heartbeat();

// ****************************************************************************************
// ************************************	          *****************************************
// *********************************  	MAIN LOOP   ***************************************
// ***********************************	           ****************************************
// ****************************************************************************************

		while(true) {		
			if (--comms_Task <= 0){
				CheckTCPComms();						// Check for commands from client main frame				
				Check_CCIO_connection();				// CCIO connection must be checked (and re-initialized if broken)
				CheckClientConnection();				// Make sure AlarmServer can receive alarms
				CheckTapeIntegrity();					// If the motors are moving make sure they are within range
				Send_heartbeat();						// Check that the server is responding
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


	


