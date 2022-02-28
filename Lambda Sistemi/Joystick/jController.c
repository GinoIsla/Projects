//************************************************************************
// Programmer: Sebastiano
// Function: 
// Created: 
//************************************************************************

#include "jpic_include.h"		/* include correct symbols for this processor */
#include "jprototype.h"
#include "japplication_data.h"
#include "jcan.h"
#include "jProfile_data.h"
#include "jController.h"			// Sebastiano...meti in Controller.h le tue variabile

/* ------------------------------------------- Globals -------------- */


//Sebastiano: Please note, every new procedure that is declared must have a a prototype. "See Prototype.h"

//***************************************************//
//Brief description of the procedure goes here
//***************************************************//
void Control (void)				
{		
	if (INTCONbits.TMR0IF)							// 1 ms tasks
	{
		TMR0L = 0x0 - Timer0tick_ms;				//Reset tmr0
 		INTCONbits.TMR0IF = 0;						//Sebastiano, gestione temporanea del T0 (per lavorare col mio codice
		T0_1ms = TRUE;
	}
}

//***************************************************//
//Brief description of the procedure goes here
//***************************************************//
void TimingControl (void)
{

	return;
}

//***************************************************//
//Read the actual position of the valve
//***************************************************//
void getActualValue(void)
{


	return;
}

//***************************************************//
//Read the actual position of the valve
//***************************************************//
void INIT_RT(void)
{


return;
}
