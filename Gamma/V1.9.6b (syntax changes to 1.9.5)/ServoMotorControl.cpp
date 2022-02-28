/*
 * *Programmer:  Gino Isla 2021, for Gamma Ray (based on ClearCore Library)
 */

// *************************************************************************************************************
// init_transport_motors()
// Sets both FEED and TAKE-UP modes for FOLLOW DIGITAL TORQUE with Unipolar PWM Command mode
// (In MSP select Mode>>Torque>>Follow Digital Torque Command, then with "Unipolar PWM Command" selected hit the OK button).
// The INPUT_A_FILTER must match the Input A filter setting in MSP (Advanced >> Input A, B Filtering...)
// The limit of the torque command (maxTorque), is a percent of the motor's peak torque rating (must match the value used in MSP)
//
// Initialize Feed, Takeup motors and Capstan
// Either ALL 3 motors are initialized or NONE of them, i.e. if any initialization fails, ALL 3 motors will   
// be disabled (EnableRequest(false))
//
// initialize motors only after TCP connection is up, otherwise we may have a contention with communications ports
// *************************************************************************************************************
bool init_transport_motors() {

	if(!transport_initializing) {

		transp_ok = false;			// if an init fails, it generate it's own reports and disables all motors
		
		MotorMgr.MotorModeSet(MotorManager::MOTOR_M2M3, Connector::CPM_MODE_A_DIRECT_B_PWM);

		if (init_capstan_motor()){
		
			if (init_Feed_motor()){

				if(init_Takeup_motor()){
					transp_ok = true;
				}		
			}
		}
	
		// Init was successful, start the torque
		if (transp_ok){
			transp_ok = Feed_Torque(25 * wind_sense);				//Start Feed torque
			if (transp_ok){
				transp_ok = Takeup_Torque(-25 * wind_sense); 		//Start Take-up torque
				transport_initializing = true;
			}
		}
		if (!transp_ok)	{		// init fail, reports already sent
			return false;
		}
	}

//Feed and Takeup have been initialized and started. Make sure the motors stay asserted for a 
// full 4 seconds to make sure the motors don't exceed the speed limit if there is no tape tension
		
	FeedState = Feed.HlfbState();
	TakeupState = Takeup.HlfbState();
		
	if (Feed.HlfbState() != MotorDriver::HLFB_ASSERTED){
		handle_transport_error(Feed_failed);
		transport_initializing = false;			//abort
		return false;
	}
		
	if (Takeup.HlfbState() != MotorDriver::HLFB_ASSERTED){
		handle_transport_error(Takeup_failed);
		transport_initializing = false;
		return false;
	}
					
	if(++transport_counter >= TRANSPORT_MAX_COUNTER){// takes about 4 seconds (8*500ms) to exceed the speed limit
		//SUCCESFUL START
		clean_report_buffer();
		build_report(Feed_started, false, 0, true);	
		send_report();

		clean_report_buffer();
		build_report(Takeup_started, false, 0, true);
		send_report();
			
		transport_initializing = false;	// successful finish
		transport_initialized = true;		
		return true;
	}
	return false;
}

// *************************************************************************************************************
// bool init_Feed_motor()
// Sets Feed motor connector to the correct mode
// Make sure in MSP:
// Motor operation, Mode -> Follow Digital TOrque, Unipolar PWM Command
// HLFB reporting, Advanced -> Measured Torque
// *************************************************************************************************************
bool init_Feed_motor(void){
	
	Feed.HlfbMode(MotorDriver::HLFB_MODE_HAS_PWM);
	Feed.HlfbCarrier(MotorDriver::HLFB_CARRIER_482_HZ);
	
	Feed.EnableRequest(true);

	// Allow some time for HLFB to assert
	safety_count = 0;
	while (Feed.HlfbState() != MotorDriver::HLFB_ASSERTED){
		Delay_ms(1);
		
		if (safety_count++ > MAX_SAFETY_COUNT){
			handle_transport_error(Feed_failed);
			return false;
		}
	}
	
	return true;
}

//**************************************************************************************************************
// Feed_Torque()
//    Command the Feed motor to move using a torque of commandedTorque 
//    Returns when HLFB asserts (indicating the motor has reached the commanded torque)
// Parameters:
//		int8_t commandedTorque
// Returns: True/False depending on whether the torque was successfully commanded.
//**************************************************************************************************************
bool Feed_Torque(int8_t commandedTorque) {
//	volatile bool spin_succesful = false;
	
    if (abs(commandedTorque) > 100) {
        return false;								// wrong torque value passed
    }
	
	Feed.ClearAlerts();
	Delay_ms(2);

	
	//Check if an alert is currently preventing motion
	if (Feed.StatusReg().bit.AlertsPresent) {		// alert present on Feed motor
		handle_transport_error(Feed_alert);
		return false;
	}

	feed_dutyRequest = abs(commandedTorque) * SCALE_FACTOR; // torque in % of PWM duty

	// Set input A to match the direction of torque.
    if (commandedTorque < 0) {
        Feed.MotorInAState(true);
    }
    else {
        Feed.MotorInAState(false);
    }
    // Ensures this delay is at least 2ms longer than the Input A filter setting in MSP
    Delay_ms(2 + INPUT_A_FILTER);
	
    // Command the move
    Feed.MotorInBDuty(feed_dutyRequest);
	

	Delay_ms(2);	// Wait 0.x secs to make a valid reading of the HLFB again.
	FeedState = Feed.HlfbState();

	if (Feed.HlfbState() != MotorDriver::HLFB_ASSERTED) {
		handle_transport_error(Feed_failed);				//stops all motors
		return false;
	}
	return true;
}

// *************************************************************************************************************
// bool init_Takeup_motor(void)
// Sets Takeup motor connector to the correct mode:
// Make sure in MSP: 
// Motor operation, Mode -> Follow Digital TOrque, Unipolar PWM Command
// HLFB reporting, Advanced -> Measured Torque
// *************************************************************************************************************
bool init_Takeup_motor(){

	Takeup.ClearAlerts();
	Takeup.HlfbMode(MotorDriver::HLFB_MODE_HAS_PWM);
	Takeup.HlfbCarrier(MotorDriver::HLFB_CARRIER_482_HZ);
	
	Takeup.EnableRequest(true);

	// Allow some time for HLFB to assert
	safety_count = 0;
	while (Takeup.HlfbState() != MotorDriver::HLFB_ASSERTED){
		Delay_ms(1);
		
		if (safety_count++ > MAX_SAFETY_COUNT){
			handle_transport_error(Takeup_failed);
			return false;
		}
	}
	return true;
}

//**************************************************************************************************************
// Takeup_Torque()
//    Command the Takeup motor to move using a torque of commandedTorque 
//    Returns when HLFB asserts (indicating the motor has reached the commanded torque)
// Parameters:
//		int8_t commandedTorque
// Returns: True/False depending on whether the torque was successfully commanded.
//**************************************************************************************************************
bool Takeup_Torque(int8_t commandedTorque) {
	
    if (abs(commandedTorque) > 100) {
	    return false;								// wrong torque value passed
    }
	
    //Check if an alert is currently preventing motion
    if (Takeup.StatusReg().bit.AlertsPresent) {		// alert present on Feed motor
	    handle_transport_error(Feed_alert);
	    return false;
    }

    takeup_dutyRequest = abs(commandedTorque) * SCALE_FACTOR;

    // Set input A to match the direction of torque.
    if (commandedTorque < 0) {			// if + moves CW, - moves CCW
	    Takeup.MotorInAState(true);
    }
    else {
	    Takeup.MotorInAState(false);
    }

	// Ensures this delay is at least 2ms longer than the Input A filter setting in MSP
	Delay_ms(2 + INPUT_A_FILTER);
	
	// Command the move
	Takeup.MotorInBDuty(takeup_dutyRequest);
	
	Delay_ms(2);	// Wait 0.x secs to make a valid reading of the HLFB again.
	TakeupState = Takeup.HlfbState();

	if (Takeup.HlfbState() != MotorDriver::HLFB_ASSERTED) {
		handle_transport_error(Takeup_failed);		//stops all motors
		return false;
	}
	return true;
}

/* *************************************************************************************************************
 * init_capstan_motor():
 * ClearPath-MCPV CAPSTAN operational mode using Pulse Burst Positioning.
 *
 * MSP Settings (for Capstan Motor):
 * 1. A ClearPath motor connected to Connector M-1.
 * 2. The connected ClearPath motor must be configured through the MSP software
 *    for Pulse Burst Positioning mode (In MSP select Mode>>Position>>Pulse
 *    Burst Positioning, then hit the OK button).
 * 3. The ClearPath motor must be set to use the HLFB mode "ASG-Position
 *    w/Measured Torque" with a PWM carrier frequency of 482 Hz through the MSP
 *    software (select Advanced>>High Level Feedback [Mode]... then choose
 *    "ASG-Position w/Measured Torque" from the dropdown, make sure that 482 Hz
 *    is selected in the "PWM Carrier Frequency" dropdown, and hit the OK
 *    button).
 * 4. Ensure the Trigger Pulse Time in MSP is set to 20ms. To configure, click
 *    the "Setup..." button found under the "Trigger Pulse" label on the MSP's
 *    main window, fill in the text box, and hit the OK button. Setting this to
 *    20ms allows trigger pulses to be as long as 60ms, which will accommodate
 *    our 25ms pulses used later.
 *
 *************************************************************************************************************/
bool init_capstan_motor(){

//DEBUG:
return true;

	//Sets the capstan connectors into step and direction mode. The motor will move a distance proportional to the number
	//   of pulses sent to input B (input A controls direction).
		MotorMgr.MotorModeSet(MotorManager::MOTOR_M0M1, Connector::CPM_MODE_STEP_AND_DIR);	// Capst = M1, Feed = M2, Take-up = M3

	// Set the motor's HLFB mode to bipolar PWM
		CapstanMotor.HlfbMode(MotorDriver::HLFB_MODE_HAS_BIPOLAR_PWM);

	// Enforces the state of the motor's A and B inputs before enabling
		CapstanMotor.MotorInAState(false);
		CapstanMotor.MotorInBState(false);
		
    // Set the HFLB carrier frequency to 482 Hz
		CapstanMotor.HlfbCarrier(MotorDriver::HLFB_CARRIER_482_HZ);	

	// Sets the maximum velocity and acceleration for each command.
	// The move profile in this mode is determined by ClearPath, so the two
	// lines below should be left as is. Set your desired speed and acceleration in MSP
		CapstanMotor.VelMax(INT32_MAX);
		CapstanMotor.AccelMax(INT32_MAX);

    // Enables the motor; homing will begin automatically if homing is enabled
    // in MSP.
		CapstanMotor.EnableRequest(true);
		
		int safetycount = 0;
		
		while (CapstanMotor.HlfbState() != MotorDriver::HLFB_ASSERTED) {
			Delay_ms(1);
			if (safetycount++ > 2){
				handle_transport_error(Capstan_failed);		
				return false;
			}
	}
	return true;		
}

//**************************************************************************************************************
// MoveCapstan()
// Command "distance" number of step pulses away from the current position, bool = true = start the trigger for alt speed
// Parameters: int distance  - in step pulses to move (pulses are - for CCW or + for CW rotation)
// Returns: True/False depending on whether the move was successfully triggered.
//**************************************************************************************************************
bool MoveCapstan(int32_t distance, bool trigger_start) {
	
	if (!transport_initialized){
		handle_transport_error(Transport_not_ready);
		return false;
	}
	
    if (CapstanMotor.StatusReg().bit.AlertsPresent) {		 // Check if an alert is currently preventing motion
		handle_transport_error(CapstanInAlert);
        return false;
    }
	
	capstan_moving = true;

	if (alt_speed && trigger_start){			// 1st move after alt speed set by command or count down while still in alt_speed
		trigger_pulse = TRIGGER_PULSE_TIME;
		CapstanMotor.EnableRequest(false);			// start trigger pulse
		return true;
	}

	CapstanMotor.EnableRequest(true);			// end trigger pulse and move
    Delay_ms(2);								
    CapstanMotor.Move(distance);				// Move started
	return true;
}
//**************************************************************************************************************
// Capstan_Motion_Handler()
// Call from the idle loop. Decrements the trigger pulse if using the alt speed and starts the move 
// Otherwise cheks to see if the motor has reached the commanded position (HLFB asserts)
// Parameters: 
// Returns: 
//**************************************************************************************************************
void Capstan_Motion_Handler(){
	
	CheckTapeIntegrity();
	if (!transport_initialized){
		trigger_pulse = 0;	// just in case
		return;			// nothing to do, transport failed
	}
	
	if (alt_speed && trigger_pulse > 0) {
		--trigger_pulse;
		
		if 	(trigger_pulse == 0) {
			CapstanMotor.EnableRequest(true);
			Delay_ms(2);								// Allow HLFB to update
			MoveCapstan(Cap_distance, false);			// end trigger pulse
		}
		return;											// Move NOT started yet - trigger_pulse still on-going -
	}

    // Confirm that HLFB has asserted 
	CapstanMotor.EnableRequest(true);
    if(CapstanMotor.StepsComplete() && CapstanMotor.HlfbState() == MotorDriver::HLFB_ASSERTED) { //  move has successfully completed?
		capstan_moving = false;
		build_report (Cap_position, true, capstan_position, true);		// End of SUCCESFUL move, send report
		send_report();
    }
	else {
		handle_transport_error(Capstan_failed);		
	}
}

// *************************************************************************************************************
// DisplayCapstanStatus():
// Reads and displays the Capstan Status Registers
// *************************************************************************************************************
void DisplayCapstanStatus(){
	build_report (Cap_position, true, capstan_position, false);
	build_report (Mov_in_alt_speed, true, alt_speed, false);
	build_report (Cap_at_target, true, (CapstanMotor.StatusReg().bit.AtTargetPosition), false);		// other values to be added !!!
	build_report (Cap_at_fault, true, (CapstanMotor.StatusReg().bit.MotorInFault), false);
	build_report(Cap_status, true, (CapstanMotor.EnableRequest()), true);
	send_report();
}

// *************************************************************************************************************
// DisplayMotorStatus(): 
// Reads and displays the Feed or Takeup Status Registers
// *************************************************************************************************************
void DisplayMotorStatus(MotorDriver motor){
	
	char * str;
	char str1[] = {" HLFB_ASSERTED"};
	char str2[] = {" HLFB_DEASSERTED"};
	char str3[] = {" HLFB_UNKNOWN"};
		
	//Header  was built in ProcessPacket()
	build_report (Enabled, true, (motor.StatusReg().bit.Enabled), false);
	
	if(motor.StatusReg().bit.Enabled){
		if (motor.StatusReg().bit.MoveDirection){
			build_report (WindBDirection, true, (motor.StatusReg().bit.AlertsPresent), false);
		}
		else 
		{
			build_report (WindADirection, true, (motor.StatusReg().bit.MoveDirection), false);
		}
	}
	build_report (In_alert, true, (motor.StatusReg().bit.AlertsPresent), false);

	motor_state = motor.HlfbState();
	
	if(motor.HlfbState() == MotorDriver::HLFB_ASSERTED) str = str1;
	else if (motor.HlfbState() == MotorDriver::HLFB_DEASSERTED) str = str2;
	else str = str3;
	
	build_report (str, false, 0, true);
	send_report();
}

// *************************************************************************************************************
// CheckTapeIntegrity():
// Whenever the transport motors are initialized, check that there is no failure
// *************************************************************************************************************
void CheckTapeIntegrity(){
	if (transport_initialized){
			// Always check if the tape integrity on the F&T
		if (Feed.HlfbState() != MotorDriver::HLFB_ASSERTED){
			handle_transport_error(Feed_failed);
			return;
		}
		
		if (Takeup.HlfbState() != MotorDriver::HLFB_ASSERTED){
			handle_transport_error(Takeup_failed);
			return;
		}
	}
}

// *************************************************************************************************************
// handle_transport_error(* string):
// An error occurred in one of the motors - ALL motors must be turned off and disabled
// *************************************************************************************************************
void handle_transport_error(char * err) {
	build_report (err, false, 0, true);
	send_report();
	
	CapstanMotor.EnableRequest(false);		//Capstan off
	Delay_ms(10);
	capstan_moving = false;

	Feed.EnableRequest(false);				//	Toggle Feed
	Delay_ms(10);
	Feed.MotorInBDuty(0);					// no PWM to Feed

	Takeup.EnableRequest(false);			// Toggle Take up
	Delay_ms(10);
	Takeup.MotorInBDuty(0);					// no PWM to Take up
	
	transport_initializing = false;
	transport_initialized = false;

}