/*****************************************************************************
 *Programmer:  Gino Isla 2021, for Gamma Ray
 * Sasquatch stepper motor control functions )Lens and Camera=
 *****************************************************************************/

// ******************************* L E N S   S T A G E *********************************************
// Lens_Motion_Handler():
// Counts the steps the lens has taken and advances the phase for the next homing/positioning phase.
// *************************************************************************************************
void Lens_Motion_Handler() { // LENS RUNNING
		if (--LensSteps > 0){											// decrement number of pulses remaining and write the pulse to the port
			LensMotorPulse = !LensMotorPulse;
			if(LensMotorPulse) {Lens_steps_taken++;}						// increment  only on + pulse
			CcioMgr.PinByIndex(static_cast<ClearCorePins>(LensStageStepperPulse))->State(LensMotorPulse);	// invert pulse, keep running
			return;	
		} 
		
		else {	// LENS FINISHED STEPPING 
			if (Lens_restarting_phase == 0){							// if we reach forward limit during restart, go to next phase, move
				Lens_restarting_phase = 1;								//    the lens forward, go to the next phase of homing
				return;
			}
			else if (LensGoingHome || LensHomingToPos){					// the lens is in the safe or new absolute position forward?
				Lens_old_position = Lens_new_position;
				LensGoingHome = false;
				LensHomingToPos = false;
				return;	
			}
			else if(Lens_forwarding){
				Lens_old_position += Lens_steps_taken;
				if(Lens_overflow){
					Lens_overflow = false;
					Lens_steps_taken = 0;
					LensMotorRunning = true;
					Lens_forwarding = false;
					LensStepperToPosition(LENS_SAFE_POS * 2, BACKWARD);			//go to home position
					return;
				}
				else {
					Lens_forwarding = false;
				}
			}
			else if (Lens_reversing){
				if(Lens_overflow){
					Lens_steps_taken = 0;
					LensMotorRunning = true;
					Lens_reversing = false;
					LensStepperToPosition(LENS_SAFE_POS * 2, FORWARD);			//go to home position
					return;
				} 
				else {
					Lens_old_position -= Lens_steps_taken;
					Lens_reversing = false;
				}
			}
		}
		LensMotorRunning = false;
		clean_report_buffer();
		build_report (LensNewPos, true, Lens_old_position, true);
		send_report();
		Lens_new_position = 0;
		Lens_steps_taken = 0;
		LensSteps = 0;
		InputMgr.InterruptsEnabled(true);			// Enable interrupts
	}

// *************************************************************************************************************
// LensStepperHome():
// Controls the motion for going home, i.e. back to Rear sensor and forward to the safe distance or intended
// distance in case of absolute positioning ([StepLensToPos: x])
// *************************************************************************************************************
void LensStepperHome(){
		if (Lens_homing_phase == 0){									// 
			LensStepperToPosition(2 * MAX_STEPPER_STEPS, BACKWARD);		// this will wait for the interrupt
			Lens_homing_phase++;
			return;	
		} 
		
		else if (Lens_homing_phase == 1) {
			if (LensGoingHome){
				LensStepperToPosition(2 * LENS_SAFE_POS, FORWARD);			// move away from front Hall
//				LensStepperToPosition(6 * LENS_SAFE_POS, FORWARD);			// run till the interrupt   DEBUG
			}
			else {
				LensStepperToPosition((Lens_new_position*2) + (2 * LENS_SAFE_POS), FORWARD);	// move away from front Hall
			}
		Lens_homing_phase++;
		LensGoingHome = false;
		return;
		}
		
		else if (Lens_homing_phase == 2) {
			if (LensGoingHome){
				Lens_old_position = 0;
				Lens_new_position = 0;
			}
			else{
				Lens_old_position = Lens_new_position;
			}
			Lens_homing_phase++;
			LensMotorRunning = false;
			}
	}

// *************************************************************************************************************
// LensStepperToPosition():
// Input: number of steps to take (int), direction(bool - forward or backward)
// Setup the move for the lens stage. Lens movements stop at either when the hitting the Rear Hall sensor 
// (when going back), when completing the number of steps (forward or backward) or on hitting the Front Hall sensor.
// *************************************************************************************************************
void LensStepperToPosition(int steps_to_take, bool direction){
		InputMgr.InterruptsEnabled(true);		// Enable interrupts
		LensMotorPulse = false;
		CcioMgr.PinByIndex(static_cast<ClearCorePins>(LensStageDirection))->State(direction);
		CcioMgr.PinByIndex(static_cast<ClearCorePins>(LensStageStepperPulse))->State(LensMotorPulse);		// first pulse
		LensMotorRunning = true;
		LensSteps = steps_to_take;					// stepper moves in rising edge
}

// *************************************************************************************************************
// InitLensStepper():
// Take the Lens Stage through the 3 phases of initialization: move forward, 
// move back to home, move forward to the Safe position.
// *************************************************************************************************************
void InitLensStepper(){
		Lens_old_position = 0;
		Lens_new_position = 0;
		
		if (Lens_restarting_phase == 0){
			if (LensSteps == 0) {					// forward move started?
				LensSteps = LENS_SAFE_POS * 2;
				Lens_restarting_phase++;
				LensStepperToPosition(LensSteps, FORWARD);				//begin forward motion
			}			
		}

		LensSteps--;									// decrement number of pulses remaining and write the pulse to the port
		LensMotorPulse = !LensMotorPulse;
		CcioMgr.PinByIndex(static_cast<ClearCorePins>(LensStageStepperPulse))->State(LensMotorPulse);	// invert pulse, keep running
		
		if (LensSteps <= 0){		//when the motor is in place, move to the next phase
			switch(Lens_restarting_phase){
				case 0:
					Lens_restarting_phase++;
					break;
			
				case 1:
					LensStepperToPosition(2 * MAX_STEPPER_STEPS, BACKWARD);			// this will wait for the interrupt
					Lens_restarting_phase++;
					break;
					
				case 2:
					LensSteps = LENS_SAFE_POS * 2;
					LensStepperToPosition(LensSteps, FORWARD);
					Lens_restarting_phase++;
					Lens_old_position = 0;
					break;
			}
		}
	}

// ************************************** C A M E R A   S T A G E **********************************************
// Cam_Motion_Handler():
// Counts the steps the camera has taken and advances the phase for the next homing/positioning phase.
// *************************************************************************************************************
void Cam_Motion_Handler() { // CAMERA RUNNING
		if (--CamSteps > 0){											// decrement number of pulses remaining and write the pulse to the port
			CamMotorPulse = !CamMotorPulse;
			if(CamMotorPulse) {Cam_steps_taken++;}						// increment  only on + pulse
			CcioMgr.PinByIndex(static_cast<ClearCorePins>(CamStageStepperPulse))->State(CamMotorPulse);	// invert pulse, keep running
			return;	
		} 
		
		else {	// CAMERA FINISHED STEPPING 
			if (Cam_restarting_phase == 0){								// if we reach forward limit during restart, go to next phase, move
				Cam_restarting_phase = 1;								//    the camera forward, go to the next phase of homing
				return;
			}
			else if (CamGoingHome || CamHomingToPos){					// the camera is in the safe or new absolute position forward?
				Cam_old_position = Cam_new_position;
				CamGoingHome = false;
				CamHomingToPos = false;
				return;	
			}
			else if(Cam_forwarding){
				Cam_old_position += Cam_steps_taken;
				if(Cam_overflow){
					Cam_overflow = false;
					Cam_steps_taken = 0;
					CamMotorRunning = true;
					Cam_forwarding = false;
					CamStepperToPosition(CAM_SAFE_POS * 2, BACKWARD);			//go to home position
					return;
				}
				else {
					Cam_forwarding = false;
				}
			}
			else if (Cam_reversing){
				if(Cam_overflow){
					Cam_steps_taken = 0;
					CamMotorRunning = true;
					Cam_reversing = false;
					CamStepperToPosition(CAM_SAFE_POS * 2, FORWARD);			//go to home position
					return;
				} 
				else {
					Cam_old_position -= Cam_steps_taken;
					Cam_reversing = false;
				}
			}
		}
		CamMotorRunning = false;
		clean_report_buffer();
		build_report (CamNewPos, true, Cam_old_position, true);
		send_report();
		Cam_new_position = 0;
		Cam_steps_taken = 0;
		CamSteps = 0;
		InputMgr.InterruptsEnabled(true);			// Enable interrupts
	}

// *************************************************************************************************************
// CamStepperHome():
// Controls the motion for going home, i.e. back to Rear sensor and forward to the safe distance or intended
// distance in case of absolute positioning ([StepCamToPos: x])
// *************************************************************************************************************
void CamStepperHome(){
		if (Cam_homing_phase == 0){									// 
			CamStepperToPosition(2 * MAX_STEPPER_STEPS, BACKWARD);		// this will wait for the interrupt
			Cam_homing_phase++;
			return;	
		} 
		
		else if (Cam_homing_phase == 1) {
			if (CamGoingHome){
				CamStepperToPosition(2 * CAM_SAFE_POS, FORWARD);			// move away from front Hall
			}
			else {
				CamStepperToPosition((Cam_new_position*2) + (2 * CAM_SAFE_POS), FORWARD);	// move away from front Hall
			}
		Cam_homing_phase++;
		CamGoingHome = false;
		return;
		}
		
		else if (Cam_homing_phase == 2) {
			if (CamGoingHome){
				Cam_old_position = 0;
				Cam_new_position = 0;
			}
			else{
				Cam_old_position = Cam_new_position;
			}
			Cam_homing_phase++;
			CamMotorRunning = false;
			}
	}

// *************************************************************************************************************
// CamStepperToPosition():
// Input: number of steps to take (int), direction(bool - forward or backward)
// Setup the move for the camera stage. Camera movements stop at either when the hitting the Rear Hall sensor 
// when going back, when completing the number of steps (forward or backward) or on hitting the Front Hall sensor.
// *************************************************************************************************************
void CamStepperToPosition(int steps_to_take, bool direction){
		InputMgr.InterruptsEnabled(true);		// Enable interrupts
		CamMotorPulse = false;
		CcioMgr.PinByIndex(static_cast<ClearCorePins>(CamStageDirection))->State(direction);
		CcioMgr.PinByIndex(static_cast<ClearCorePins>(CamStageStepperPulse))->State(CamMotorPulse);		// first pulse
		CamMotorRunning = true;
		CamSteps = steps_to_take;					// stepper moves in rising edge
}

// *************************************************************************************************************
// InitCamStepper():
// Take the Camera Stage through the 3 phases of initialization: move forward, move back to home, 
// move forward to SAFe position.
// *************************************************************************************************************
void InitCamStepper(){
		Cam_old_position = 0;
		Cam_new_position = 0;
		
		if (Cam_restarting_phase == 0){
			if (CamSteps == 0) {					// forward move started?
				CamSteps = CAM_SAFE_POS * 2;
				Cam_restarting_phase++;
				CamStepperToPosition(CamSteps, FORWARD);				//begin forward motion
			}			
		}

		CamSteps--;									// decrement number of pulses remaining and write the pulse to the port
		CamMotorPulse = !CamMotorPulse;
		CcioMgr.PinByIndex(static_cast<ClearCorePins>(CamStageStepperPulse))->State(CamMotorPulse);	// invert pulse, keep running
		
		if (CamSteps <= 0){		//when the motor is in place, move to the next phase
			switch(Cam_restarting_phase){
				case 0:
					Cam_restarting_phase++;
					break;
			
				case 1:
					CamStepperToPosition(2 * MAX_STEPPER_STEPS, BACKWARD);			// this will wait for the interrupt
					Cam_restarting_phase++;
					break;
					
				case 2:
					CamSteps = CAM_SAFE_POS * 2;
					CamStepperToPosition(CamSteps, FORWARD);
					Cam_restarting_phase++;
					Cam_old_position = 0;
					break;
			}
		}	
}
