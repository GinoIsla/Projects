/*****************************************************************************
 *Programmer:  Gino Isla 2021, for Gamma Ray
 * Saquatch command decoding and execution
 *****************************************************************************/
#include <string.h>
uint8_t command_stream[MAX_PACKET_SIZE];

bool parse_result = false;
unsigned int parserIdx = 0;

char key[MAX_KEY_SIZE];
bool RGB1_ON = false;
bool RGB2_ON = false;
int LEDs_ON_count = 0;

// *************************************************************************************************************
// string_length():
// Utility procedure
// *************************************************************************************************************
uint8_t string_length(char *str ){

	volatile int s = 0;
	for (s = 0 ; s < MAX_REPORT_SIZE ; s++) {
		if (str[s] == '\0') break;
	}
	
	return (uint8_t) s;
}

// *************************************************************************************************************
// parse_value():
// Generic procedure to find the value of a key in the TCP command
// *************************************************************************************************************
int parse_value (){

	volatile int value = 0;
	volatile int j = 0;
	char asc_val[MAX_KEY_SIZE];

	for (j = 0 ; j < MAX_KEY_SIZE ; j++) {asc_val[j] = '\0';}		//clear asc_val
	
	if (command_stream[parserIdx] == ':') {		// value1?
		parserIdx++;
		j = 0;
		while (parserIdx < MAX_PACKET_SIZE && \
		command_stream[parserIdx] != '\0' && \
		command_stream[parserIdx] != '|' && \
		command_stream[parserIdx] != ':' && \
		command_stream[parserIdx] != ']')\
		{
			asc_val[j] = command_stream[parserIdx];
			parserIdx++;
			j++;
		}
		value = atoi(asc_val);
	}
	else {
		value = -1;		//no ':' found
	}
	
	//	parserIdx++;
	if (command_stream[parserIdx] != ']' || command_stream[parserIdx] != '|'){		// end of command
		return value;
	}
	return 0;		// no end of command
}

// *************************************************************************************************************
// parse_key():
// Generic procedure to find the key name in the TCP command
// *************************************************************************************************************
bool  parse_key(){

	volatile int j = 0;

	for(int i = 0; i < MAX_KEY_SIZE; i++){key[i] = '\0';}		// clean up key[];
	
	if (command_stream[parserIdx] == '|') {		//
		parserIdx++;
		j = 0;

		while (parserIdx < MAX_PACKET_SIZE && \
		command_stream[parserIdx] != '\0' && \
		command_stream[parserIdx] != '|' && \
		command_stream[parserIdx] != ':' && \
		command_stream[parserIdx] != ']')\
		{
			key[j] = command_stream[parserIdx];
			parserIdx++;
			j++;
		}
	}
	
	if (command_stream[parserIdx] == ']') {		// end of string found
		return true;
	}
	
	return false;
}

// *************************************************************************************************************
// parse_proc():
// Scan and extract the TCP command. Call functions to extract all keys and values
// *************************************************************************************************************
bool parse_proc(volatile char * commandString) {

	volatile bool start = false;
	volatile bool end = false;
	volatile int j;

	//Clear the entire parsed_command struct
	for (j = 0 ; j < MAX_COMMAND_SIZE ; j++){ parsed_command.name[j] = '\0';}
	for (j = 0 ; j < MAX_KEY_SIZE ; j++){parsed_command.key1[j] = '\0';}
	parsed_command.val1 = -1;
	for (j = 0 ; j < MAX_KEY_SIZE ; j++){parsed_command.key2[j] = '\0';}
	parsed_command.val2 = -1;
	for (j = 0 ; j < MAX_KEY_SIZE ; j++){parsed_command.key3[j] = '\0';}
	parsed_command.val3 = -1;
	for (j = 0 ; j < MAX_KEY_SIZE ; j++){parsed_command.key4[j] = '\0';};
	parsed_command.val4 = -1;
	for (j = 0 ; j < MAX_KEY_SIZE ; j++){parsed_command.key5[j] = '\0';}
	parsed_command.val5 = -1;
	
	for (int i = 0 ; i < MAX_PACKET_SIZE ; i++) {				// copy THE WHOLE command to global memory and check for command delimiters '[' && ']'
		if (commandString[i] == '[') start = true;
		if (commandString[i] == ']') end = true;
		command_stream[i] = commandString[i];
	}
	
	if (!(start && end)) return false;							// missing command delimiters
	
	parserIdx=2;												// skip added ">["
	j = 0;
	
	// SCAN THE COMMAND AND PUT IT IN parsed_command.name
	while (parserIdx < MAX_COMMAND_SIZE && command_stream[parserIdx] != '\0' && command_stream[parserIdx] != '|' && command_stream[parserIdx] != ':' && command_stream[parserIdx] != ']'){
		parsed_command.name[j] =  command_stream[parserIdx];
		parserIdx++;
		j++;
	}
	if (command_stream[parserIdx] == ']') {		//end of command found	
		return true;
	}
	
	// SCAN KEYS AND VALUES AND PUT THEM IN parsed_command.keyX AND parsed_command.valueX
	//============	KEY1
	parse_key();		//  (parserIdx is correct) ***** empty key is accepted
	for (int i = 0; i < MAX_KEY_SIZE ; i++) {parsed_command.key1[i] = key[i];}
	parsed_command.val1 = parse_value();		// VAL1
	
	//============	KEY2
	parse_key();		//  (parserIdx is correct)
	for (int i = 0; i < MAX_KEY_SIZE ; i++) {parsed_command.key2[i] = key[i];}
	parsed_command.val2 = parse_value();		// VAL2

	//============	KEY3
	parse_key();		//  (parserIdx is correct) ***** empty key is accepted
	for (int i = 0; i < MAX_KEY_SIZE ; i++) {parsed_command.key3[i] = key[i];}
	parsed_command.val3 = parse_value();		// VAL3
	
	//============	KEY4
	parse_key();		//  (parserIdx is correct) ***** empty key is accepted
	for (int i = 0; i < MAX_KEY_SIZE ; i++) {parsed_command.key4[i] = key[i];}
	parsed_command.val4 = parse_value();		// VAL4

	//============	KEY5
	parse_key();		//  (parserIdx is correct) ***** empty key is accepted
	for (int i = 0; i < MAX_KEY_SIZE ; i++) {parsed_command.key5[i] = key[i];}
	parsed_command.val5 = parse_value();		// VAL4

	return true;
}

// *************************************************************************************************************
// SerialProcessPacket():
// All commands in the command stream will be process here. The command stream is parsed, rejected if malformed, 
// unpacked into the parsed_command structured. It's up to the individual command processor to do the semantic
// check (nbr of prameters, values out of range, etc.)
// *************************************************************************************************************
uint8_t * SerialProcessPacket(volatile char *commandStr){
	
volatile bool parse_result = false;
Cam_overflow = false;

	parse_result = parse_proc(commandStr);
	clean_report_buffer();
	strcpy(final_string.data_chars, Command_OK);

	if(parse_result){
// ################################# BEGIN COMMAND PROCESSING ### 

		if (strcmp(parsed_command.name,"MasterInitialize") == 0){	// validate timing of the command
			master_initialize = true;
			int l = string_length(final_string.data_chars);
			strcpy(final_string.data_chars + l - 2, VERSION);
		}
		
//the following commands can be issued before MasterInitialize
//====================================================================================
		else if (strcmp(parsed_command.name,"SetClientIP") == 0){
			if (parsed_command.val1 == 0xff || parsed_command.val2 == 0xff){
				strcpy(final_string.data_chars, out_of_range);
			}
			else {
				newIp[0] = (uint8_t) parsed_command.val1;
				newIp[1] = (uint8_t) parsed_command.val2;
				newIp[2] = (uint8_t) parsed_command.val3;
				newIp[3] = (uint8_t) parsed_command.val4;
				write_SEEPROM(Client_valid, &VAL_CODE, 1);		// write the validation code that makes this a valid ip
				write_SEEPROM(Client_EEPROM8, newIp, 4);		// write the ip
			}			
		}
//====================================================================================
		else if (strcmp(parsed_command.name,"SetServerIP") == 0){
			if (parsed_command.val1 == 0xff || parsed_command.val2 == 0xff){
				strcpy(final_string.data_chars, out_of_range);
			}
			else {
				newIp[0] = (uint8_t) parsed_command.val1;
				newIp[1] = (uint8_t) parsed_command.val2;
				newIp[2] = (uint8_t) parsed_command.val3;
				newIp[3] = (uint8_t) parsed_command.val4;
				write_SEEPROM(Server_valid, &VAL_CODE, 1);
				write_SEEPROM(Server_EEPROM8, newIp, 4);
			}			
		}
//====================================================================================
		else if (strcmp(parsed_command.name,"GetClientIP") == 0){
			
			read_SEEPROM(Client_valid, newIp);
			if (newIp[0] == VAL_CODE) {		
				read_SEEPROM(Client_EEPROM8, newIp);
				 strcpy(final_string.data_chars  - 2 + string_length(final_string.data_chars), Client_ADDRESS);

				 for (int i = 0 ; i < 4 ; i++) {
					itoa(newIp[i], ip_string, 10);
					strcpy(final_string.data_chars  + string_length(final_string.data_chars), ip_string);
					strcpy(final_string.data_chars  + string_length(final_string.data_chars), ".");
				 }
				strcpy(final_string.data_chars  + string_length(final_string.data_chars) - 1, "]");	
			}
			else {
				strcpy(final_string.data_chars, no_valid_IP);
			}
		}
//====================================================================================
		else if (strcmp(parsed_command.name,"GetServerIP") == 0){
			read_SEEPROM(Server_valid, newIp);
			if (newIp[0] == VAL_CODE) {	
				read_SEEPROM(Server_EEPROM8, newIp);
				strcpy(final_string.data_chars  - 2 + string_length(final_string.data_chars), Server_ADDRESS);

				for (int i = 0 ; i < 4 ; i++) {
					itoa(newIp[i], ip_string, 10);
					strcpy(final_string.data_chars  + string_length(final_string.data_chars), ip_string);
					strcpy(final_string.data_chars  + string_length(final_string.data_chars), ".");
				}
				strcpy(final_string.data_chars  + string_length(final_string.data_chars) - 1, "]");
			} 
			else {
				strcpy(final_string.data_chars, no_valid_IP);
			}
		}
//====================================================================================
		else if (strcmp(parsed_command.name,"SetServerPortNum") == 0){
			if (parsed_command.val1 == 0xffff){
				strcpy(final_string.data_chars, Par_missing);
			}
			else {
				Server_Port_Id.whole_word = parsed_command.val1;				
				newIp[0] = Server_Port_Id.bytes.low_byte;
				newIp[1] = Server_Port_Id.bytes.high_byte;
				write_SEEPROM(Server_Port_valid, &VAL_CODE, 1);
				write_SEEPROM(Server_Port_EEPROM, &Server_Port_Id.bytes.low_byte, 1);
				write_SEEPROM(Server_Port_EEPROM+1, &Server_Port_Id.bytes.high_byte, 1);

			}

		}
//====================================================================================
		else if (strcmp(parsed_command.name,"GetServerPortNum") == 0){
			char asc_val[8];
			
			strcpy(final_string.data_chars  - 2 + string_length(final_string.data_chars), "|Port ID=");
			
			read_SEEPROM(Server_Port_valid, newIp);
			
			if (newIp[0] == VAL_CODE) {
				read_SEEPROM(Server_Port_EEPROM, newIp);		// reads bytes, convert to word
				Server_Port_Id.bytes.high_byte = newIp[1];
				Server_Port_Id.bytes.low_byte = newIp[0];				
				strcpy(final_string.data_chars + string_length(final_string.data_chars), itoa(Server_Port_Id.whole_word, asc_val, 10));	
			}			
			else {
				strcpy(final_string.data_chars + string_length(final_string.data_chars), itoa(Server_Port, asc_val, 10));
			}
			
			strcpy(final_string.data_chars  + string_length(final_string.data_chars), "]");

		}
//====================================================================================
		else if (master_initialize == false)
		{
			strcpy(final_string.data_chars, Command_rejected);
			return (final_string.data_out);
		}
		else if (transport_initializing){							// wait while transport is moving ...
			strcpy(final_string.data_chars, Transport_not_ready);
			return (final_string.data_out);
		}

// ################################# COMMANDS after Master Init ####################
		else if (strcmp(parsed_command.name,"StepFwd") == 0)						// Forward motion is the + direction
			{
			Cap_distance = parsed_command.val1;
			if (MoveCapstan(Cap_distance, true)){
				strcpy(final_string.data_chars, Command_executing);
				capstan_position += parsed_command.val1;
			}
		}
	
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"StepRev") == 0)						// Backward motion is the - direction
			{
			Cap_distance = -(parsed_command.val1);
			if(MoveCapstan(Cap_distance, true)){
				strcpy(final_string.data_chars, Command_executing);
				capstan_position -= parsed_command.val1;
			}
		}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"CapstanSetPos") == 0) 
			{
				capstan_position = parsed_command.val1;
			}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"StepToPos") == 0)
			{
				if (capstan_position == parsed_command.val1){
					strcpy(final_string.data_chars, already_in_pos);	// we're already there
				return(final_string.data_out);
				}

				else if(capstan_position > parsed_command.val1) {	// move back if new < current position
					Cap_distance = -(capstan_position - parsed_command.val1);
				}

				else if(parsed_command.val1 > capstan_position) {
					Cap_distance = parsed_command.val1 - capstan_position;
				}
				
				if(MoveCapstan(Cap_distance, true)){
					strcpy(final_string.data_chars, Command_executing);	// Value out of range
					capstan_position = parsed_command.val1;
				}
			}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"StepFwdToPos") == 0)
			{
				strcpy(final_string.data_chars, Deprecated);
			}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"StepRevToPos") == 0)
			{
				strcpy(final_string.data_chars, Deprecated);
			}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"SlewForward") == 0)
			{

			}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"SlewBackward") == 0)
			{

			}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"SlewForwardToPos") == 0)
			{

			}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"SlewBackwardToPos") == 0)
			{

			}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"CapstanStop") == 0)
			{
				CapstanMotor.EnableRequest(false);
				capstan_position = 0;
				strcpy(final_string.data_chars, Cap_stopped);
				return(final_string.data_out);

			}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"LoadFilm") == 0)
			{				
				wind_sense = A_wind;
				strcpy(final_string.data_chars, Command_executing);
				transport_counter = 0;
				init_transport_motors();
			}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"UnloadFilm") == 0)
			{
				//rewind till end of tape???????
				transport_initializing = false;
				transport_initialized = false;
				Feed.MotorInBDuty(0);
				Takeup.MotorInBDuty(0);
				CapstanMotor.EnableRequest(false);		//????? 
				Feed.EnableRequest(false);				//?????
				Takeup.EnableRequest(false);

			}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"SetZeroFrame") == 0)
			{

			}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"SetEndFrame") == 0)
			{

			}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"SetFeedMotorTension") == 0)
			{

			}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"SetTakeupMotorTension") == 0)
			{

			}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"GetPosition") == 0)
			{

			}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"GetFeedMotorStatus") == 0)
			{
				strcpy(final_string.data_chars, Command_executing);
//				build_report (Feed_status, false, 0, false);		// Report header only ...
				DisplayMotorStatus(Feed);
			}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"GetTakeupMotorStatus") == 0)
			{
				strcpy(final_string.data_chars, Command_executing);
//				build_report (Takeup_status, false, 0, false);		// Report header only ...
				DisplayMotorStatus(Takeup);
				
			}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"GetCapstanMotorStatus") == 0)
			{
				strcpy(final_string.data_chars, Command_executing);
				DisplayCapstanStatus();
			}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"SetCapstanAltSpeed") == 0)
		{
			alt_speed = true;
		}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"CancelAltSpeed") == 0)
		{
			alt_speed = false;
		}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"GetFeedMotorTension") == 0)
			{

			}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"GetTakeupMotorTension") == 0)
			{
		
			}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"EnableLedR1") == 0)
		{
			if (RGB1_ON || RGB2_ON){
				strcpy(final_string.data_chars, RGB1_or_2); // RGB1 or RGB2 need to be turned off first
				return(final_string.data_out);
			}
				
			if (parsed_command.val1 > 100 || parsed_command.val1 < 0) {
					strcpy(final_string.data_chars, out_of_range);	// Value out of range
					return(final_string.data_out);
			}
				
			if(!led_state.b.led_R1)	{						// are we on?
				if (parsed_command.val1 == 0) {				// we're not on but are asked to turn off
					LedR1.PwmDuty(MIN_PWM);					// just make sure we're OFF
					intensity[0] = 0;
					strcpy(final_string.data_chars, already_off);// return success (but led was already off!)
				}
						
				if (LEDs_ON_count >= MAX_LED_COUNT)			// Not ON, check how many leds are on
				{		
					strcpy(final_string.data_chars, too_many_leds);	// too many leds already ON
				}
				else
				{
					LEDs_ON_count++;		// we weren't on, we are now
					led_state.b.led_R1 = 1;	// show state
				}
			} 
			// if we were already off, nothing to do but write the correct PWM
			if (parsed_command.val1 == 0)	{
				led_state.b.led_R1 = 0;
				LEDs_ON_count--;
			}
			volatile int pwm_val = 0xff - ((parsed_command.val1 * 255) / 100);	// convert prescaled value and write the complement
			LedR1.PwmDuty(pwm_val);
			intensity[0] = parsed_command.val1;
		}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"EnableLedR2") == 0)
		{
				if (RGB1_ON || RGB2_ON){
					strcpy(final_string.data_chars, RGB1_or_2); // RGB1 or RGB2 need to be turned off first
					return(final_string.data_out);
				}

				if (parsed_command.val1 > 100 || parsed_command.val1 < 0) {
					strcpy(final_string.data_chars, out_of_range);	// Value out of range
					return(final_string.data_out);
				}
				
				if(!led_state.b.led_R2)	{							// are we on?
					if (parsed_command.val1 == 0) {				// we're not on but are asked to turn off
						LedR2.PwmDuty(MIN_PWM);				// just make sure we're OFF
						intensity[1] = 0;

						strcpy(final_string.data_chars, already_off);// return ok (but led was already off!)
					}
					
					if (LEDs_ON_count >= MAX_LED_COUNT)			// Not ON, check how many leds are on
					{		
						strcpy(final_string.data_chars, too_many_leds);	// Not ON, too many leds already ON
					}
					else
					{
						LEDs_ON_count++;		// we weren't on, we are now
						led_state.b.led_R2 = 1;	// record state
					}
				} 
				// if we were already on, nothing to do but write the correct PWM
				if (parsed_command.val1 == 0)	{		// if the new value is 0 we shut off this led.   Perry - is this correct??????????
					led_state.b.led_R2 = 0;
					LEDs_ON_count--;
				}
				volatile int pwm_val = 0xff - ((parsed_command.val1 * 255) / 100);	// convert prescaled value and write the complement
				LedR2.PwmDuty(pwm_val);
				intensity[1] = parsed_command.val1;
		}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"EnableLedG") == 0)
		{
			if (RGB1_ON || RGB2_ON){
				strcpy(final_string.data_chars, RGB1_or_2); // RGB1 or RGB2 need to be turned off first
				return(final_string.data_out);
			}
				
			if (parsed_command.val1 > 100 || parsed_command.val1 < 0) {
				strcpy(final_string.data_chars, out_of_range);	// Value out of range
				return(final_string.data_out);

			}
			if(!led_state.b.led_G)	{						// are we on?
				if (parsed_command.val1 == 0) {				// we're not on but are asked to turn off
					LedG.PwmDuty(MIN_PWM);						// just make sure it's OFF
					intensity[2] = 0;
					strcpy(final_string.data_chars, already_off);// return success (but led was already off!)
				}
				
				if (LEDs_ON_count >= MAX_LED_COUNT)			// Not ON, check how many leds are on
				{
					strcpy(final_string.data_chars, too_many_leds);	// Not ON, too many leds already ON
				}
				else
				{
					LEDs_ON_count++;		// we weren't on, we are now
					led_state.b.led_G = 1;	// show state
				}
			}
			// if we were already on, nothing to do but write the correct PWM
			if (parsed_command.val1 == 0)	{		// if the new value is 0 we shut off this led.   Perry - is this correct??????????
				led_state.b.led_G = 0;
				LEDs_ON_count--;
			}
			volatile int pwm_val = 0xff - ((parsed_command.val1 * 255) / 100);	// convert prescaled value and write the complement
			LedG.PwmDuty(pwm_val);
			intensity[2] = parsed_command.val1;
		}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"EnableLedB") == 0)
		{
			if (RGB1_ON || RGB2_ON){
				strcpy(final_string.data_chars, RGB1_or_2); // RGB1 or RGB2 need to be turned off first
				return(final_string.data_out);
			}

			if (parsed_command.val1 > 100 || parsed_command.val1 < 0) {
				strcpy(final_string.data_chars, out_of_range);	// Value out of range
				return(final_string.data_out);
			}
			
			if(!led_state.b.led_B)	{						// are we on?
				if (parsed_command.val1 == 0) {				// we're NOT on but are asked to turn off
					LedB.PwmDuty(MIN_PWM);				// just make sure we're OFF
					intensity[3] = 0;
					strcpy(final_string.data_chars, already_off);// return ok (but led was already off!)
				}
				
				if (LEDs_ON_count >= MAX_LED_COUNT)			// Not ON, check how many leds are on
				{
					strcpy(final_string.data_chars, too_many_leds);	// Not ON, too many leds already ON
				}
				else
				{
					LEDs_ON_count++;		// we weren't on, we are now
					led_state.b.led_B = 1;	// show state
				}
			}
			// if we were already off, nothing to do but write the correct PWM
			if (parsed_command.val1 == 0)	{		// if the new value is 0 we shut off this led.   Perry - is this correct?
				led_state.b.led_B = 0;
				LEDs_ON_count--;
			}
			volatile int pwm_val = 0xff - ((parsed_command.val1 * 255) / 100);	// convert prescaled value and write the complement
			LedB.PwmDuty(pwm_val);
			intensity[3] = parsed_command.val1;
		}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"EnableLedIR") == 0)
		{
			if (RGB1_ON || RGB2_ON){
				strcpy(final_string.data_chars, RGB1_or_2); // RGB1 or RGB2 need to be turned off first
				return(final_string.data_out);
			}

			if (parsed_command.val1 > 100 || parsed_command.val1 < 0) {
				strcpy(final_string.data_chars, out_of_range);	// Value out of range
				return(final_string.data_out);
			}
			
			if(!led_state.b.led_IR)	{						// are we on?
				if (parsed_command.val1 == 0) {				// we're not on but are asked to turn off
					LedIR.PwmDuty(MIN_PWM);					// just make sure we're OFF
					intensity[4] = 0;
					strcpy(final_string.data_chars, already_off);// return ok (but led was already off!)
				}
				
				if (LEDs_ON_count >= MAX_LED_COUNT)			// Not ON, check how many leds are on
				{
					strcpy(final_string.data_chars, too_many_leds);	// Not ON, too many leds already ON
				}
				else
				{
					LEDs_ON_count++;		// we weren't on, we are now
					led_state.b.led_IR = 1;	// show state
				}
			}
			// if we were already on, nothing to do but write the correct PWM
			if (parsed_command.val1 == 0)	{		// if the new value is 0 we shut off this led.   Perry - is this correct?
				led_state.b.led_IR = 0;
				LEDs_ON_count--;
			}
			volatile int pwm_val = 0xff - ((parsed_command.val1 * 255) / 100);	// convert prescaled value and write the complement
			LedIR.PwmDuty(pwm_val);
			intensity[4] = parsed_command.val1;
		}

// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"EnableRGB1") == 0)
		{
			volatile int pwm_val = 0xff - ((parsed_command.val1 * 255) / 100);	// convert prescaled value and write the complement
		
			if (RGB2_ON) {
				strcpy(final_string.data_chars, RGB2_not_off); //Perry review: RGB2 is on, reply "too many leds"	
				return(final_string.data_out);
			}
		
			led_state.all_leds = 0b00001101;		// Regardless of individual states, all Leds off but R1, G, B
			LedR2.PwmDuty(MIN_PWM);
			LedIR.PwmDuty(MIN_PWM);
			intensity[1] = 0;
			intensity[4] = 0;
		
			LedR1.PwmDuty(pwm_val);
			intensity[0] = parsed_command.val1;
			LedG.PwmDuty(pwm_val);
			intensity[2] = parsed_command.val1;
			LedB.PwmDuty(pwm_val);
			intensity[3] = parsed_command.val1;
			
			RGB1_ON = true;
			LEDs_ON_count = 3;			
		}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"EnableRGB2") == 0)
			{
			volatile int pwm_val = 0xff - ((parsed_command.val1 * 255) / 100);	// convert prescaled value and write the complement
				
		if (RGB1_ON) {
			strcpy(final_string.data_chars, RGB1_not_off);	
			return(final_string.data_out);
		}
			led_state.all_leds = 0b00001110;						// Regardless of individual states, all Leds off but R2, G, B
			LedR1.PwmDuty(MIN_PWM);
			intensity[0] = 0;
			
			LedIR.PwmDuty(MIN_PWM);
			intensity[4] = 0;
		
			LedR2.PwmDuty(pwm_val);
			intensity[1] = parsed_command.val1;
			LedG.PwmDuty(pwm_val);
			intensity[2] = parsed_command.val1;
			LedB.PwmDuty(pwm_val);
			intensity[3] = parsed_command.val1;
			
			RGB2_ON = true;
			LEDs_ON_count = 3;			
		}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"DisableLedR1") == 0)
			{
			if (RGB1_ON || RGB2_ON){
				strcpy(final_string.data_chars, RGB1_or_2); // RGB1 or RGB2 need to be turned off first
				return(final_string.data_out);
			}
				
			if(!led_state.b.led_R1){							// already off?
				strcpy(final_string.data_chars, already_off);// return ok (but led was already off!)
			}

			LedR1.PwmDuty(MIN_PWM);					// turn off led
			intensity[0] = 0;
			led_state.b.led_R1 = 0;	
			if (LEDs_ON_count > 0){				// make sure we don't corrupt the counter
				LEDs_ON_count--;
			}
		}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"DisableLedR2") == 0)
			{
			if (RGB1_ON || RGB2_ON){
				strcpy(final_string.data_chars, RGB1_or_2); // RGB1 or RGB2 need to be turned off first
				return(final_string.data_out);
			}

			if(!led_state.b.led_R2){							// already off?
				strcpy(final_string.data_chars, already_off);	// return ok (but led was already off!)
			}

			LedR2.PwmDuty(MIN_PWM);						// turn off led
			intensity[1] = 0;
			led_state.b.led_R2 = 0;
			if (LEDs_ON_count > 0){				// make sure we don't corrupt the counter
				LEDs_ON_count--;
			}
		}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"DisableLedG") == 0)
			{
			if (RGB1_ON || RGB2_ON){
				strcpy(final_string.data_chars, RGB1_or_2); // RGB1 or RGB2 need to be turned off first
				return(final_string.data_out);
			}

			if(!led_state.b.led_G){							// already off?
				strcpy(final_string.data_chars, already_off);	// return ok (but led was already off!)
			}

			LedG.PwmDuty(MIN_PWM);						// turn off led
			intensity[2] = 0;
			led_state.b.led_G = 0;
			if (LEDs_ON_count > 0){				// make sure we don't corrupt the counter
				LEDs_ON_count--;
			}
		}
			/// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"DisableLedB") == 0)
			{
			if (RGB1_ON || RGB2_ON){
				strcpy(final_string.data_chars, RGB1_or_2); // RGB1 or RGB2 need to be turned off first
				return(final_string.data_out);
			}

			if(!led_state.b.led_B){							// already off?
				strcpy(final_string.data_chars, already_off);	// return ok (but led was already off!)
			}

			LedB.PwmDuty(MIN_PWM);						// turn off led
			led_state.b.led_B = 0;
			intensity[3] = 0;
			if (LEDs_ON_count > 0){				// make sure we don't corrupt the counter
				LEDs_ON_count--;
			}
		}
			/// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"DisableLedIR") == 0)
			{
			if (RGB1_ON || RGB2_ON){
				strcpy(final_string.data_chars, RGB1_or_2); // RGB1 or RGB2 need to be turned off first
				return(final_string.data_out);
			}

			if(!led_state.b.led_IR){							// already off?
				strcpy(final_string.data_chars, already_off);	// return ok (but led was already off!)
			}

			LedIR.PwmDuty(MIN_PWM);						// turn off led
			led_state.b.led_IR = 0;
			intensity[4] = 0;
			if (LEDs_ON_count > 0){						// make sure we don't corrupt the counter
				LEDs_ON_count--;
			}
		}
			/// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"DisableRGB1") == 0)
		{
			if (RGB1_ON){												// disable RGB1 only if it's on
				led_state.all_leds = led_state.all_leds & 0b00010010;	// Regardless of individual states, turn off R1, G, B
				LedR1.PwmDuty(MIN_PWM);
				intensity[0] = 0;
				LedG.PwmDuty(MIN_PWM);
				intensity[2] = 0;
				LedB.PwmDuty(MIN_PWM);	
				intensity[3] = 0;
				
				RGB1_ON = false;
			
				if (LEDs_ON_count >= 3) {
					LEDs_ON_count = LEDs_ON_count - 3;
				}
			} 
			else 
			{
				strcpy(final_string.data_chars, RGB1_off);	// RGB1 not ON
			}
			
		}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"DisableRGB2") == 0)
		{
			if (RGB2_ON){
				led_state.all_leds = led_state.all_leds & 0b00010001;	// Regardless of individual states, turn off R2, G, B		
				LedR2.PwmDuty(MIN_PWM);
				intensity[1] = 0;
				LedG.PwmDuty(MIN_PWM);
				intensity[2] = 0;
				LedB.PwmDuty(MIN_PWM);
				intensity[3] = 0;
				RGB2_ON = false;
			
				if (LEDs_ON_count >= 3) {
					LEDs_ON_count = LEDs_ON_count - 3;
				}
			} 
			else 
			{
				strcpy(final_string.data_chars, RGB2_off);	// RGB2 is not ON
			}
			
		}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"GetLedBoardTemp") == 0)
			{
				strcpy(final_string.data_chars, Deprecated);
			}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"GetLedBoardStatus") == 0)
			{				
				strcpy(report_buffer.data_chars, LED_STATUS);
				
				if(RGB1_ON) {
					build_report(RGB1_on, true, intensity[0], true);		// report intensity of R1, end of report
					send_report();
					return(final_string.data_out);
					
				}
				
				if(RGB2_ON) {
					build_report(RGB2_on, true, intensity[1], true);		// report intensity of R2
					send_report();
					return(final_string.data_out);
				}
				
				// if RGB1 and RGB 2 are not ON, build a report with the individual LEDs
				build_report(LED_R1, false, 0, false);
				if(led_state.b.led_R1) {build_report(_on, true, intensity[0], false);}
				else {build_report(_off, false, 0, false);}
				
				build_report(LED_R2, false, 0, false);
				if(led_state.b.led_R2) {build_report(_on, true, intensity[1], false);}	
				else {build_report(_off, false, 0, false);}
				
				build_report(LED_G, false, 0, false);
				if(led_state.b.led_G) {build_report(_on, true, intensity[2], false);}	
				else {build_report(_off, false, 0, false);}
				
				build_report(LED_B, false, 0, false);
				if(led_state.b.led_B) {build_report(_on, true, intensity[3], false);}	
				else {build_report(_off, false, 0, false);}

				build_report(LED_IR, false, 0, false);
				if(led_state.b.led_IR) {build_report(_on, true, intensity[4], true);}	// end of report
				else {build_report(_off, false, 0, true);}	// EOR
						
				send_report();
			}
// #############################################################
// ########################## LENS #############################
// #############################################################
		else if (strcmp(parsed_command.name,"HomeLensStage") == 0)
			{
			LensSteps = 0;
			Lens_homing_phase = 0;
			LensGoingHome = true;
			Lens_new_position = 0;
			Lens_old_position = 0;
			strcpy(final_string.data_chars, Command_executing);
			LensStepperHome();						// first go to home position, interrupthandler() will send it to 'lens_position'
		}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"StepLensToPos")== 0)		// go to absolute position from 0
			{
			if(parsed_command.val1 <= 0 || parsed_command.val1 > MAX_STEPPER_STEPS){
				strcpy(final_string.data_chars, out_of_range);	// Value out of range
				return(final_string.data_out);
			}
			LensSteps = 0;
			Lens_homing_phase = 0;
			LensHomingToPos = true;
			Lens_new_position = parsed_command.val1;
			strcpy(final_string.data_chars, Command_executing);
			LensStepperHome();						// first go to home position, interrupthandler() wil send it to 'Lens_position'
		}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"StepLensStageFwd") == 0)
			{
			if(parsed_command.val1 <= 0 || parsed_command.val1 > MAX_STEPPER_STEPS){
				strcpy(final_string.data_chars, out_of_range);	// Value out of range
				return(final_string.data_out);
			}
			strcpy(final_string.data_chars, Command_executing);
			Lens_forwarding = true;
			Lens_new_position = Lens_old_position + parsed_command.val1;
			LensStepperToPosition(parsed_command.val1 *2, FORWARD);
			}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"StepLensStageRev") == 0)
			{
			if(parsed_command.val1 <= 0 || parsed_command.val1 > MAX_STEPPER_STEPS){
				strcpy(final_string.data_chars, out_of_range);	// Value out of range
				return(final_string.data_out);
			}
			if(Lens_old_position - parsed_command.val1 <= 0 ){	// reverse to negative?
				strcpy(final_string.data_chars, Lens_rev_past);	// Value out of range
				return(final_string.data_out);
			}
			strcpy(final_string.data_chars, Command_executing);
			Lens_reversing = true;
			Lens_new_position = Lens_old_position - parsed_command.val1;
			LensStepperToPosition((parsed_command.val1 * 2), BACKWARD);	
			}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"StepLensStageStop") == 0)
		{
			if(LensMotorRunning){
				LensSteps = 0;
				if (Lens_reversing){
					Lens_old_position -= Lens_steps_taken;
				}
				else if (Lens_forwarding){
					Lens_old_position += Lens_steps_taken;
				}
				LensMotorRunning = true;						// handle the stop & reporting in Lens_Motion_Handler()
				Lens_reversing = false;
				Lens_forwarding = false;
			}
			else {
				strcpy(final_string.data_chars, Lens_not_running);	// Value out of range
				return(final_string.data_out);
			}
		}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"GetLensStagePos") == 0)
		{
			build_report (Lens_position, true, Lens_old_position, true);
			send_report();
		}

// #############################################################
// ######################## CAMERA #############################
// #############################################################
		else if (strcmp(parsed_command.name,"HomeCamStage") == 0)
			{
			CamSteps = 0;
			Cam_homing_phase = 0;
			CamGoingHome = true;
			Cam_new_position = 0;
			Cam_old_position = 0;
			strcpy(final_string.data_chars, Command_executing);
			CamStepperHome();						// first go to home position, interrupthandler() will send it to 'lens_position'
		}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"StepCamToPos")== 0)		// go to absolute position from 0
			{
			if(parsed_command.val1 <= 0 || parsed_command.val1 > MAX_STEPPER_STEPS){
				strcpy(final_string.data_chars, out_of_range);	// Value out of range
				return(final_string.data_out);
			}
			CamSteps = 0;
			Cam_homing_phase = 0;
			CamHomingToPos = true;
			Cam_new_position = parsed_command.val1;
			strcpy(final_string.data_chars, Command_executing);
			CamStepperHome();						// first go to home position, interrupthandler() wil send it to 'cam_position'
		}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"StepCamStageFwd") == 0)
			{
			if(parsed_command.val1 <= 0 || parsed_command.val1 > MAX_STEPPER_STEPS){
				strcpy(final_string.data_chars, out_of_range);	// Value out of range
				return(final_string.data_out);
			}
			strcpy(final_string.data_chars, Command_executing);
			Cam_forwarding = true;
			Cam_new_position = Cam_old_position + parsed_command.val1;
			CamStepperToPosition(parsed_command.val1 *2, FORWARD);
			}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"StepCamStageRev") == 0)
			{
			if(parsed_command.val1 <= 0 || parsed_command.val1 > MAX_STEPPER_STEPS){
				strcpy(final_string.data_chars, out_of_range);	// Value out of range
				return(final_string.data_out);
			}
			if(Cam_old_position - parsed_command.val1 <= 0 ){	// reverse to negative?
				strcpy(final_string.data_chars, Cam_rev_past);	// Value out of range
				return(final_string.data_out);
			}
			strcpy(final_string.data_chars, Command_executing);
			Cam_reversing = true;
			Cam_new_position = Cam_old_position - parsed_command.val1;
			CamStepperToPosition((parsed_command.val1 * 2), BACKWARD);	
			}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"StepCamStageStop") == 0)
		{
			if(CamMotorRunning){
				CamSteps = 0;
				if (Cam_reversing){
					Cam_old_position -= Cam_steps_taken;
				}
				else if (Cam_forwarding){
					Cam_old_position += Cam_steps_taken;
				}
				CamMotorRunning = true;						// handle the stop & reporting in Cam_Motion_Handler()
				Cam_reversing = false;
				Cam_forwarding = false;
			}
			else {
				strcpy(final_string.data_chars, Cam_not_running);
				return(final_string.data_out);
			}
		}
// ################################# COMMAND ####################
		else if (strcmp(parsed_command.name,"GetCamStagePos") == 0)
		{
			build_report (Cam_position, true, Cam_old_position, true);
			send_report();
		}
// ################################# UNRECOGNIZED COMMANDS ####################
	else{
			strcpy(final_string.data_chars, unrecognized);
		}
	
// ################################# MALFORMED COMMAND (NO DELIMITERS) ####################
		}		
		else // if (parse_result)
		{
			strcpy(final_string.data_chars, syntax_error);		//Syntax or malformed command
		}
	
	return (final_string.data_out);

}
