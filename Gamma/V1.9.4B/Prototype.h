/*****************************************************************************
 *Programmer:  Gino Isla 2021, for Gamma Ray
 *Declare prototypes
 *****************************************************************************/

/* -------- Prototypes: -------------- */
//void SD_card_driver(void);
//void ConfigurePeriodicInterrupt(uint32_t);

void write_SEEPROM(uint8_t *, uint8_t *, int);
void read_SEEPROM(uint8_t *, uint8_t *);
void get_Port_number(void);

bool init_capstan_motor(void);
bool MoveCapstan(int32_t, bool);
void Capstan_Alt_Speed(void);
void CheckTapeIntegrity(void);
void DisplayMotorStatus(MotorDriver);
void DisplayCapstanStatus(void);

bool init_transport_motors(void);
void handle_transport_error(char *);
bool init_Feed_motor(void);
bool init_Takeup_motor(void);
bool Feed_Torque(int8_t);
bool Takeup_Torque(int8_t);

void Interrupt1(void);
void Interrupt2(void);
void Interrupt3(void);
void Interrupt4(void);
void InterruptHandler(int);

void InitCamStepper(void);
void Cam_Motion_Handler(void);
void CamStepperHome(void);
void CamStepperToPosition(int, bool);

void InitLensStepper(void);
void Lens_Motion_Handler(void);
void LensStepperHome(void);
void LensStepperToPosition(int, bool);

void send_report(void);
void init_CCIO(void);
void init_ONBOARD_ports(void);
void Check_CCIO_connection(void);
bool init_TCPIP_connections(void);
void CheckClientConnection(void);
void get_TCPIP_addresses(void);
void CheckTCPComms(void);
uint8_t string_length(char *);
void clean_report_buffer(void);
void build_report (char *, bool, int, bool);
int parse_value (void);
bool  parse_key(void);
bool parse_proc(volatile char *);
uint8_t * SerialProcessPacket(volatile char *);

