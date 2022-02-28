/*****************************************************************************
 *Programmer:  Gino Isla 2021, for Gamma Ray
 * Saquatch data structures and constants
 *****************************************************************************/
// Software interrupts
//===========================================================================================
#define PERIODIC_INTERRUPT_PRIORITY     4
#define ACK_PERIODIC_INTERRUPT  TCC2->INTFLAG.reg = TCC_INTFLAG_MASK
uint32_t period;
uint8_t prescale;


//TCP-IP constants, structs and globals **************************
// #define DHCP_AUTO		// <========== uncomment for DHCP IP automatic address assignment)

uint32_t idx;
long debug1 = 0;
long debug2 = 0;
uint32_t interruptFreqHz = 4;

//GENERAL VARIABLES FOR COMMANDS, TCP AND OTHER INITIALIZATION
//===========================================================================================
bool master_initialize = false;
bool TCPconnectionRunning = false;
EthernetTcpClient sasquatch_client[4];							// Clients for this server
int wait_for_client_count = 1;
bool client_connnected = false;

//TCP SERVER (COMMANDS)
IpAddress GAMMA_IP = IpAddress(192, 168, 1, 220);				// GAMMA RAY
IpAddress TEST_IP = IpAddress(192, 168, 99, 128);				// ICSAC

//TCP CLIENT (ALARMS) 
IpAddress GAMMA_serverIp = IpAddress(192, 168, 1, 221);				// GAMMA_RAY PC
IpAddress TEST_serverIp = IpAddress(192, 168, 99, 176);				// ICSAC PC
EthernetTcpClient alarmClient;

IpAddress gateway = IpAddress(192, 168, 1, 1);					// Gateway is not used, ClearCore and PCs are local to this LAN
IpAddress netmask = IpAddress(255, 255, 255, 0);				// Mask to separate network vs. host addresses (required for TCP)

IpAddress ip;				// Server
IpAddress alarmIp;			// Client

#define MAX_PACKET_SIZE 150
#define MAX_COMMAND_SIZE 30
#define MAX_KEY_SIZE 10
#define MAX_REPORT_SIZE 150

#define MAX_PWM 0
#define MIN_PWM 0xff

struct COMMAND {
	char name[MAX_COMMAND_SIZE];
	char key1[MAX_KEY_SIZE];
	int val1;
	char key2[MAX_KEY_SIZE];
	int val2;
	char key3[MAX_KEY_SIZE];
	int val3;
	char key4[MAX_KEY_SIZE];
	int val4;
	char key5[MAX_KEY_SIZE];
	int val5;
} parsed_command;

union {
	struct
	{
		volatile unsigned int led_R1:1;
		volatile unsigned int led_R2:1;
		volatile unsigned int led_G:1;
		volatile unsigned int led_B:1;
		volatile unsigned int led_IR:1;
		volatile unsigned int spare_leds:4;		// for other leds 5, 6, 7, 8
	} b;
		volatile unsigned char all_leds;
}led_state;

unsigned intensity[5] = {0,0,0,0,0};		// for LED status report: [0] = R1, [1] = R2, [2] = G, [3] = B, [4] = IR

//LED PORTS
//===========================================================================================
#define LedR1 ConnectorIO0
#define LedR2 ConnectorIO1
#define LedG ConnectorIO2
#define LedB ConnectorIO3
#define LedIR ConnectorIO4

// ALARMS AND REPORTS
//===========================================================================================
char CCIO_disconnect[] = "[ALARM|CCIO connection lost";
char CCIO_connected[] = "[STATUS|CCIO connection recovered";

//char CamInit_pos[] = "[STATUS|Camera at Start Position (0)]\r";
//char CamRear[] = "[WARNING|Camera REAR Limit Reached]\r";		// int 1
char CamFront[] = "[WARNING|Camera FRONT Limit Reached";		// int 2
char Cam_not_running[] = "[WARNING|Camera stage not running]\r";			//reply
char Cam_rev_past[] = "[ERROR|Camera reverse past limit]\r";				//reply
//char Cam_pos_undef[] = "[WARNING|Camera position undefined]\r";
char Cam_position[] = "[STATUS|Camera position ";				// missing "[" is intentional
char CamNewPos[] = "[STATUS|Camera Stage in position ";		// missing "[" is intentional

//char LensInit_pos[] = "[STATUS|Lens at Start Position (0)]\r";
//char LensRear[] = "[WARNING|Lens REAR Limit Reached]\r";		// int 3
char LensFront[] = "[WARNING|Lens FRONT Limit Reached";		// int 4
char Lens_not_running[] = "[WARNING|Lens stage not running]\r";				//reply
char Lens_rev_past[] = "[ERROR|Lens reverse past limit]\r";					//reply
//char Lens_pos_undef[] = "[WARNING|Lens position undefined]\r";
char Lens_position[] = "[STATUS|Lens position ";					// missing "[" is intentional
char LensNewPos[] = "[STATUS|Lens Stage in position ";				// missing "[" is intentional

char CapstanInAlert[] = "[ERROR|Capstan in Alert]\r";				//reply
char Cap_position[] = "[STATUS|Capstan position ";					// missing "[" is intentional
char already_in_pos[] = "[WARNING|Capstan already in this position]\r";		//reply
char Cap_at_target[] = ", Capstan at target: ";
char Cap_status[] = ", Capstan Enabled: ";
char Cap_at_fault[] = ", Capstan at fault: ";
char Mov_in_alt_speed[] = ", Moving at ALT speed: ";
char Cap_reset_pos[] = "[STATUS|Capstan position reset to ";		// missing "[" is intentional
char Cap_stopped[] = "[WARNING|Stop requested, position set to (0)]\r";		//reply
char Cap_started[] = "[STATUS|Capstan motor started";				// DO WE DISABLE THE MOTORS ??????
char Capstan_failed[] = "[ERROR|Capstan motor in Alert or not ready (ALL motors disabled)";

char Feed_failed[] = "[ERROR|Feed motor Over Speed or not ready (ALL motors disabled)";
char Feed_alert[] = "[STATUS|Feed motor is in Alert (ALL motors disabled)";
char Feed_started[] = "[STATUS|Feed motor started";

char Takeup_failed[] = "[ERROR|Take-up motor Over Speed or not ready (ALL motors disabled)";
char Takeup_alert[] = "[STATUS|Take-up motor is in Alert (ALL motors disabled)";
char Takeup_started[] = "[STATUS|Take-up motor started";

// Replies to commands
//====================
char out_of_range[] =	"[ERROR|Value out of range]\r";
char syntax_error[] = "[ERROR|Syntax error]\r";
char unrecognized[] = "[ERROR|Unrecognized Command]\r";
char Command_rejected[] = "[ERROR|Command rejected - use MasterInitialize]\r";
char Transport_not_ready[] = "[ERROR|Command rejected - Transport not initialized]\r";
char too_many_leds[] = "[ERROR|Too many LEDS are on]\r";
char already_off[] = "[WARNING|LED was already OFF)]\r";
char RGB1_off[] = "[ERROR|RGB1 is not ON]\r";
char RGB2_off[] = "[ERROR|RGB2 is not ON]\r";
char RGB1_not_off[] = "[ERROR|RGB1 is ON]\r";
char RGB2_not_off[] = "[ERROR|RGB2 is ON]\r";
char RGB1_or_2[] = "[ERROR|Disable RGB1 or RGB2 first]\r";
char RGB1_on[] = "STATUS|RGB1 ON ";								// missing "[" is intentional
char RGB2_on[] = "STATUS|RGB2 ON ";


char Command_OK[] = "[STATUS|Command Successful]\r";
char Command_executing[] = "[STATUS|Command Executing, Report Follows]\r";
char Deprecated[] = "[ERROR|Command deprecated]\r";
char LED_STATUS[] = "[STATUS|LED report:  ";
char LED_R1[] = "LED_R1: ";
char LED_R2[] = ", LED_R2: ";
char LED_G[]  = ", LED_G: ";
char LED_B[]  = ", LED_B: ";
char LED_IR[] = ", LED_IR: ";

uint8_t cr_lf[] = "\r";
char _on[]  = "ON ";
char _off[] = "OFF";

union string_out{
	char data_chars[MAX_REPORT_SIZE];
	uint8_t data_out[MAX_REPORT_SIZE];		//raw command
} final_string;

union report_out{
	char data_chars[MAX_REPORT_SIZE];
	uint8_t data_out[MAX_REPORT_SIZE];		//raw command
} report_buffer;

#define MAX_LED_COUNT 3		// <================== This to be updated when power supply is ready

#define TRY_AGAIN_TRANPORT_MOTORS 10000 //???????
int try_again = 0;

#define REPEAT_REPORT_DELAY 6		//  <== This value causes the report for failure of the motors ever 6 * 10 secs = 1 minute
int repeat_report = 0;

//CCIO-8 constants, structs and globals
//===========================================================================================
#define CcioPort ConnectorCOM0

#define OUTPUT_HIGH false
#define OUTPUT_LOW true

uint8_t ccioBoardCount;
int16_t state;
bool CCIO_alarm_sent = false;

//STEPPER MOTORS
//===========================================================================================
#define STEPS_PER_REV 400						// ***** OJO **** THIS NUMBER FOLLOW SW5, SW6, SW7, SW8 IN STEPPERLINE MOTOR
#define MAX_STEPPER_STEPS STEPS_PER_REV * 25		// MAXIMUM NUMBER OF TURNS IN THIS SLIDER

#define CAM_SAFE_POS 400
#define LENS_SAFE_POS 400

#define FORWARD  true							// High output on CC
#define BACKWARD  false							// Low		"	"

//LENS AND CAMERA MOTION PORTS
#define CamStageStepperPulse	CLEARCORE_PIN_CCIOA1
#define CamStageDirection		CLEARCORE_PIN_CCIOA2
#define LensStageStepperPulse	CLEARCORE_PIN_CCIOA3
#define LensStageDirection		CLEARCORE_PIN_CCIOA4

// LENS AND CAMERA HALL SENSORS
#define Cam_Rear_Hall ConnectorA9
#define Cam_Front_Hall ConnectorA10
#define Lens_Rear_Hall ConnectorA11
#define Lens_Front_Hall ConnectorA12

//VARIABLES FOR LENS AND CAMERA MOTION
bool Lens_forwarding = false;
bool Lens_reversing = false;
bool LensMotorRunning = false;
bool LensMotorPulse = false;
bool LensHomingToPos = false;
bool LensGoingHome = false;
bool Lens_overflow = false;			// Lens sent beyond Hall sensors
int LensSteps = 0;					// steps to move the linear lens stage
int Lens_steps_taken = 0;			// steps moved by the linear lens stage
int Lens_homing_phase = 0;
int Lens_old_position = 0;
int Lens_new_position = 0;
int Lens_restarting_phase = 0;			// initialize in phases of Lens restart

bool Cam_forwarding = false;
bool Cam_reversing = false;
bool CamMotorRunning = false;
bool CamMotorPulse = false;
bool CamHomingToPos = false;
bool CamGoingHome = false;
bool Cam_overflow = false;			// camera sent beyond Hall sensors
int CamSteps = 0;					// steps to move the linear lens stage
int Cam_steps_taken = 0;			// steps moved by the linear lens stage
int Cam_homing_phase = 0;
int Cam_old_position = 0;
int Cam_new_position = 0;
int Cam_restarting_phase = 0;			// initialize in phases of camera restart

// CAPSTAN MOTOR, PULSE BURST POSITIONING mode
//===========================================================================================
#define CapstanMotor ConnectorM1
#define TRIGGER_PULSE_TIME 25

int trigger_pulse = 0;
bool capstan_moving = false;
bool alt_speed = false;
int capstan_position = 0;
int32_t Cap_distance = 0;
uint32_t Cap_status_reg;
bool capstan_started = false;

// FEED AND TAKE-UP MOTORS, FOLLOW DIGITAL TORQUE mode
//===========================================================================================
#define A_wind 1
#define B_wind -1
int wind_sense = A_wind;				// wind sense: A-Wind (default)
uint8_t feed_dutyRequest = 0;
uint8_t takeup_dutyRequest = 0;
bool transp_ok = false;
bool spin_succesful = false;

int transport_counter = 0;
bool transport_initializing = false;

#define Feed ConnectorM2
#define Takeup ConnectorM3
#define INPUT_A_FILTER 20
#define MAX_SAFETY_COUNT 25		// for Feed and Take-up motors to assert
#define MAX_TRANSPORT_INIT_SPEED 30	// maximum speed of transport motors at init as % or maximum speed
#define MIN_TRANSPORT_INIT_SPEED 2	// maximum speed reported when not moving
#define TRANSPORT_MAX_COUNTER 4000		// 4 seconds to validate transport speed

MotorDriver::HlfbStates FeedState;		// HLFB variables
MotorDriver::HlfbStates TakeupState;
float FeedPercent = 0;
//float TempFeedPercent =0;	//debug
float TakeupPercent = 0;


bool transport_initialized = false;
//bool feed_started = false;
//bool takeup_started = false;
int safety_count = 0;

//double MAX_TORQUE = 100;				// maximum torque = 100% duty cycle 
//double MIN_TORQUE = -MAX_TORQUE;		// symmetric torque
double SCALE_FACTOR = 255 / 100;


/* UNUSED:
Some motor definitions will do
***************************** Motor constants, structs and globals **************************

#define INPUT_A_B_FILTER 20
#define POSITION_INCREMENT_1 1000  //at start up this value is this, but the software Perry wrote will be able change that
#define POSITION_INCREMENT_2 -1000 //at start up this value is this, but the software Perry wrote will be able change that

 Use this for limit switch
#define HomingSensor ConnectorDI6.Mode(Connector::INPUT_DIGITAL)

//defined commands
#define StepFwd 0x11
#define StepRev 0x12
#define StepFwdToPos 0x13
#define StepRevToPos 0x14
#define SlewForward	0x15
#define SlewBackward 0x16
#define SlewForwardToPos 0x17
#define SlewBackwardToPos 0x18
#define CapstanStop 0x19
#define LoadFilm 0x20
#define UnloadFilm 0x21
#define SetZeroFrame 0x22
#define SetEndFrame 0x23
#define SetFeedMotorTension 0x24
#define SetTakeupMotorTension 0x25
#define GetPosition 0x26
#define GetFeedMotorStatus 0x27
#define GetTakeupMotorStatus 0x28
#define GetCapstanMotorStatus 0x29
#define GetFeedMotorTension 0x30
#define GetTakeupMotorTension 0x31
#define EnableLedR1 0x32
#define EnableLedR2	0x33
#define EnableLedG 0x34
#define EnableLedB 0x35
#define EnableLedIR 0x36
#define EnableRGB1 0x37
#define EnableRGB2 0x38
#define DisableLedR1 0x39
#define DisableLedR2 0x40
#define DisableLedG 0x41
#define DisableLedB 0x42
#define DisableLedIR 0x43
#define DisableRGB1 0x44
#define DisableRGB2 0x45
#define	GetLedBoardTemp 0x46
#define GetLedBoardStatus 0x47
#define HomeLensStage 0x48
#define HomeCamStage 0x49
#define StepLensStageFwd 0x50
#define StepLensStageRev 0x51
#define StepCamStageFwd 0x52
#define StepCamStageRev 0x53
#define StepLensToPos 0x54
#define StepCamToPos 0x55
#define GetLensStagePos 0x56
#define GetCamStagePos 0x57

*/