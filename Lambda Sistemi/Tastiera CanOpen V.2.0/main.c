// Passive Keypad with LEDs as CANOpen node
// Programmer:	Gino Isla for Lambda Sistemi, Milano
// Created: 	22-11-2004	Version 1.0
// Updates:		30-11-2004	(circa) no Version: turn-off LEDs before applying new pattern.  Add
//							delay before turning-on common port of LED group.
//				17-01-2005	Version 1.2: Modify Configuration bits to correct writes to EEPROM
//				14-07-2005	Version 2.0: Change sequence for reading keypad:
//											a. Read keys only after LEds are lit
//											b. Read all keypad rows before checking for variations
//											Add error functions (read columns, send EMCY)
//											Change port assignments for new hw
//				09-09-2005	---------		Fixed several bugs, added Timer 1 to manage timings between
//											write of the LEDs,read of the keypad and error detection
/* ------------------------------------------- Include files: -------------- */
#include <p18f458.h>
#include "can.h"

volatile struct TXB_BUFF TXB_B [MAX_CAN_OUT];
volatile struct TXB_BUFF RXB_B [MAX_CAN_IN];

char StatoUnita 				= 0;    // Stato unita
unsigned char Id;                    	// Numero Id

struct timer1_convert T1;
struct heartbeat heartbeat_count;
struct heartbeat heartbeat_rate;

unsigned char	debounce_count;
unsigned char	debounce_period;
unsigned char	ten_millisec_count = 10;
unsigned int	blink_rate = 1;
struct Key_Row	KEY_PAD_NEW [MAX_ROWS] ={0,0,0,0,0,0,0};  //recently read keypad
struct Key_Row	KEY_PAD_PREV [MAX_ROWS] ={0,0,0,0,0,0,0}; //previous keypad states
struct Key_Row	KEY_PAD_SENT [MAX_ROWS] ={0,0,0,0,0,0,0}; //last sent keypad states
unsigned char	DEBOUNCE_FLAG = OFF;
unsigned char	Next_keypad_read;
unsigned char Next_Group = GROUP0;

unsigned char LEDs [MAX_LED_ROWS];
unsigned char BlinkLEDs [MAX_LED_ROWS];
unsigned char BlinkMask [MAX_LED_ROWS];
unsigned char LEDs_on;
unsigned char ultimo_out;
struct LED_mask mask;
//start new in 2.0
unsigned char	check_keypad_now = FALSE; 						//allows read keypad at the end of the led cycle
unsigned char	test_error_now = FALSE; 						//allows checkfor errors at the end of the keypad cycle
unsigned char	row_count = 0; 									//keeps track of rows read
unsigned char	error_persistancy_count = ERROR_DEBOUNCE;		//debounce for errors
unsigned char	NON_error_persistancy_count = NON_ERROR_COUNT;	//non-error increments of counter
unsigned char	error_register = 0;								//errro flags
//end new in 2.0

//***************************************************//
//Scrittura nel bus CAN                              //
//***************************************************//
void CanOut(void)
{
 char i; 

 if (TXB0CONbits.TXREQ) return;
 if (PIR3bits.TXB1IF) PIR3bits.TXB1IF = 0;

 // Ricerca messaggio da inviare
 for (i = ultimo_out ; i < MAX_CAN_OUT ; i++)
  {
   if (TXB_B [i].ST_B.OUT)
    {
     TXB_B [i].ST_B.OUT  = 0;
     TXB0SIDL = TXB_B [i].TXBSIDL;
     TXB0SIDH = TXB_B [i].TXBSIDH;
     TXB0DLC = TXB_B [i].TXBDLC;
     TXB0D0 = TXB_B [i].TXBD0;
     TXB0D1 = TXB_B [i].TXBD1;
     TXB0D2 = TXB_B [i].TXBD2;
     TXB0D3 = TXB_B [i].TXBD3;
     TXB0D4 = TXB_B [i].TXBD4;
     TXB0D5 = TXB_B [i].TXBD5;
     TXB0D6 = TXB_B [i].TXBD6;
     TXB0D7 = TXB_B [i].TXBD7;
     TXB0CONbits.TXREQ = 1;

	 _asm clrwdt _endasm
	 while (TXB0CONbits.TXREQ) ;

	 if (PIR3bits.TXB0IF) PIR3bits.TXB0IF = 0; 
	 ultimo_out = i++;
	 break;
     } 
  }
 if (i >= MAX_CAN_OUT)
   ultimo_out = 0;
}

//***************************************************//
//Prepare BOOT message                              //
//***************************************************//
void SendBoot (void)
  {
	TXB_B [CAN_OPEN_IdErr].TXBD0 = 0;
	TXB_B [CAN_OPEN_IdErr].ST_B.OUT = 1;	  
  }
  //***************************************************//
//Prepare Emergency message                              //
//***************************************************//
void SendEmergency ( char registry, char error_data)
  {
	TXB_B [CAN_OPEN_IdEMCY].TXBD0 = 0x00;
	TXB_B [CAN_OPEN_IdEMCY].TXBD1 = 0x50; 		// Emergency Error Code: Device Hardware (Table 21, p. 9-38)
	TXB_B [CAN_OPEN_IdEMCY].TXBD2 = registry;	// registry: Error Register (Table 47, p. 9-65)
	TXB_B [CAN_OPEN_IdEMCY].TXBD3 = error_data;
	TXB_B [CAN_OPEN_IdEMCY].TXBD4 = 0x00;
	TXB_B [CAN_OPEN_IdEMCY].TXBD5 = 0x00;
	TXB_B [CAN_OPEN_IdEMCY].TXBD6 = 0x00;
	TXB_B [CAN_OPEN_IdEMCY].TXBD7 = 0x00;
 	TXB_B [CAN_OPEN_IdEMCY].TXBDLC  = 0x08;
	TXB_B [CAN_OPEN_IdEMCY].ST_B.OUT = 1;	  
  }
  
//***************************************************//
//Prepare HEARTBEAT message                          //
//***************************************************//
void SendHeartbeat (void)
  {
	TXB_B [CAN_OPEN_IdErr].TXBD0 = StatoUnita;
	TXB_B [CAN_OPEN_IdErr].ST_B.OUT = 1;	  
  }
  
//***************************************************//
//Prepare PDO KEYPAD VARIATION                       //
//***************************************************//
void SendKeypad (void)
{
    TXB_B [CAN_OPEN_IdTx].TXBD0 = KEY_PAD_SENT[0].All_Col;
    TXB_B [CAN_OPEN_IdTx].TXBD1 = KEY_PAD_SENT[1].All_Col;
    TXB_B [CAN_OPEN_IdTx].TXBD2 = KEY_PAD_SENT[2].All_Col;
    TXB_B [CAN_OPEN_IdTx].TXBD3 = KEY_PAD_SENT[3].All_Col;
    TXB_B [CAN_OPEN_IdTx].TXBD4 = KEY_PAD_SENT[4].All_Col;
    TXB_B [CAN_OPEN_IdTx].TXBD5 = KEY_PAD_SENT[5].All_Col;
    TXB_B [CAN_OPEN_IdTx].TXBD6 = KEY_PAD_SENT[6].All_Col;
    TXB_B [CAN_OPEN_IdTx].TXBD7 = 0;
    TXB_B [CAN_OPEN_IdTx].TXBDLC  = 8;
    TXB_B [CAN_OPEN_IdTx].ST_B.OUT = 1;
}

//******************************************************//
// Look for keypad variations and debouncing 			//
//******************************************************//
unsigned char Keypad_Changed (void)
{
 unsigned char Keychange = 0;
 unsigned char i;

 ReadKeypad ();

 if (++row_count < MAX_ROWS) 
	return (FALSE); //test for keypad changes only after all rows have been checked
 else 
	row_count = 0;


//All rows checked, detect keypad changes
 for (i=0 ; i<MAX_ROWS ; i++)
 	{
 	Keychange = (KEY_PAD_NEW[i].All_Col ^ KEY_PAD_PREV[i].All_Col);
 	if (Keychange) break;	//stop on first change
 	}

 //If No Keychange but DEBOUNCE_FLAG is on (i.e. n'th detection)
 if ((!Keychange) && (DEBOUNCE_FLAG == ON))
	{
	if ((--debounce_count) > 0)
		return(FALSE);  //debounce count not yet reached (don't reset debounce)
    else
		{
		//debounce_count reached the limit, make sure this is a real change
		for (i=0 ; i<MAX_ROWS ; i++)
 			{
	 		Keychange = (KEY_PAD_SENT[i].All_Col ^ KEY_PAD_PREV[i].All_Col);
			if (Keychange) break;
 			}
		if (Keychange) //debounced keypad configuration != than the last sent
			{
			for (i = 0 ; i < MAX_ROWS ; i++) KEY_PAD_SENT[i].All_Col = KEY_PAD_PREV[i].All_Col; 
			debounce_count = debounce_period;
			DEBOUNCE_FLAG = OFF;
			return(TRUE); //this is a real change
			}
		else goto RESET_KP; //keypad didn't changed from last send, ignore it.
		}
	}

 else if ((Keychange) && (DEBOUNCE_FLAG == OFF))
 	{
	// First detection of a key, copy NEW to PREV
	for (i = 0 ; i < MAX_ROWS ; KEY_PAD_PREV[i].All_Col = KEY_PAD_NEW[i].All_Col, i++);
	DEBOUNCE_FLAG = ON; //indicate debouncing
	return (FALSE);
	}

 // unexpected Keychange while debouncing  OR !Keychange && !debouncing (normal idle state)
 else //if ((Keychange) && (DEBOUNCE_FLAG == ON))
	{
RESET_KP:
	DEBOUNCE_FLAG = OFF;
	debounce_count = debounce_period;
	return(FALSE);
	}
}

//***************************************************//
//	Read the key pad                                 //
//***************************************************//
void ReadKeypad (void)
{
unsigned char i,column;

 Stop_unit();

//------------  consider that the rows get read only after this FSM gets to the last state
 switch (row_count)
 	{
	 case 0:
		PORTBbits.RB4 = 1;
		column = GetPortBits();
		PORTBbits.RB4 = 0;
		break;

	 case 1:
		PORTBbits.RB5 = 1;
		column = GetPortBits();
		PORTBbits.RB5 = 0;
		break;

	 case 2:
		PORTBbits.RB6 = 1;
		column = GetPortBits();
		PORTBbits.RB6 = 0;
		break;

	 case 3:
		PORTBbits.RB7 = 1;
		column = GetPortBits();
		PORTBbits.RB7 = 0;
		break;

	 case 4:
		PORTEbits.RE0 = 1;
		column = GetPortBits();
		PORTEbits.RE0 = 0;
		break;

	 case 5:						//make sure RE0,1,2 are not the last columns read
		PORTEbits.RE1 = 1;
		column = GetPortBits();
		PORTEbits.RE1 = 0;
		break;

	 case 6:
		PORTEbits.RE2 = 1;
		column = GetPortBits();
		PORTEbits.RE2 = 0;
		test_error_now = TRUE;
		break;
 	}
	KEY_PAD_NEW[row_count].All_Col = column;
}

//***************************************************//
//Read ports and put them in the corresponding byte of KEY_PAD_NEW
//***************************************************//
unsigned char GetPortBits (void)
{
int i;
struct Key_Row	KEY_PAD;

for (i=0 ; i<66  ; i++);		//closed delay ~200uS for hw: 13Tcyc*.16uS/Tcyc*100 = 200.84uS

KEY_PAD.All_Col=0;
KEY_PAD.All_Col=PORTA; ////KEY_PAD.col_0...5 = PORTAbits.RA0...RA5
KEY_PAD.col_6 = PORTBbits.RB0;
KEY_PAD.col_7 = PORTBbits.RB1;
return (KEY_PAD.All_Col);
}

//***************************************************//
//Operate LEDs (called every 1ms)                    //
//***************************************************//
void LightLEDs (void)
{
 unsigned char LEDmask0,LEDmask1,i; 

 PORTD = 0;					//turn off leds before applying new pattern
 PORTC = 0; 
 mask.common_mask=ON;
	
	if (StatoUnita == CAN_STATE_OPERATIONAL)
	{
	 switch (Next_Group)
		{
		 case GROUP0:
			PORTEbits.RE1=OFF;			//turn off other groups	
			PORTEbits.RE2=OFF;
			LEDmask0 = LEDs[0];
			LEDmask1 = LEDs[1];
			LEDmask0 ^= BlinkMask[0];
			LEDmask1 ^= BlinkMask[1];
			for (i=0 ; i<5	; i++);		//delay 10uS for hw: 13Tcyc*.16uS/Tcyc*5 = 10.4uS
			PORTEbits.RE0=mask.common_mask;
			Next_Group=GROUP1;
			break;
		 case GROUP1:
			PORTEbits.RE0=OFF;
			PORTEbits.RE2=OFF;
			LEDmask0 = LEDs[2];
			LEDmask1 = LEDs[3];
			LEDmask0 ^= BlinkMask[2];
			LEDmask1 ^= BlinkMask[3];
			for (i=0 ; i<5	; i++);		//delay ~10uS for hw: 13Tcyc*.16uS/Tcyc*5 = 10.4uS
			PORTEbits.RE1=mask.common_mask;
			Next_Group=GROUP2;
			break;
	 	case GROUP2:
			PORTEbits.RE0=OFF;
			PORTEbits.RE1=OFF;
			LEDmask0 = LEDs[4];
			LEDmask1 = LEDs[5];
			LEDmask0 ^= BlinkMask[4];
			LEDmask1 ^= BlinkMask[5];
			for (i=0 ; i<5	; i++);		//delay ~10uS for hw: 13Tcyc*.16uS/Tcyc*5 = 10.4uS
			PORTEbits.RE2=mask.common_mask;
			check_keypad_now = TRUE;  //allow read of errors and keypad (proc Error_found turns off all leds)
			Next_Group=GROUP0;
			break;
		}
	}
 	PORTD = LEDmask0; 
 	PORTC = LEDmask1; 

	PIR1bits.TMR1IF = 0;
	TMR1H = T1.T1high_byte;			//start TMR1, make sure the LED cycles is always 1ms
	TMR1L = T1.T1low_byte;

}

//***************************************************//
//Shut-off all LEDs and common ports
//***************************************************//
void Stop_unit(void)
{
	PORTEbits.RE0=OFF;
	PORTEbits.RE1=OFF;			//turn off all columns
	PORTEbits.RE2=OFF;			//
	PORTD = 0;					// turn off all rows
	PORTC = 0; 
}

//***************************************************//
// Check state of "columns". They should always be off unless a real
// hw error indication set one or more ON.  If an error is found, the state 
// of this unit changes to STOPPED and an EMCY PDO is sent.
// This procedure is called only when stato_unita = CAN_STATE_OPERATIONAL.
//***************************************************//
void Test_for_Error(void)
{
struct Key_Row	ERROR_PAD;
int i;

 Stop_unit();
 ERROR_PAD.All_Col = GetPortBits();			//includes delay
 
 if (ERROR_PAD.All_Col != 0)
	{
 	if (((--error_persistancy_count) == 0))
		{
			StatoUnita = CAN_STATE_STOPPED;
			SendEmergency(0x84, ERROR_PAD.All_Col);		//err registr=generic, device specific (table 47, p.9-65)
			error_persistancy_count = ERROR_DEBOUNCE;
			NON_error_persistancy_count = NON_ERROR_COUNT;		// leaky bucket counter reinitialized
		}
 	} 
 else
 	{
	if ((--NON_error_persistancy_count) == 0)
		{
			error_persistancy_count += (error_persistancy_count < ERROR_DEBOUNCE ? 1 : 0); //incrment if counting
			NON_error_persistancy_count = NON_ERROR_COUNT;	//reset
		}
	}

}

//***************************************************//
//Toggle Blink masks
//***************************************************//
void TreatBlinkMask (void)
{
 char i;

 if ((--blink_rate) == 0)		//at 1/2 sec intervals, toggle the blink mask
	{
	for (i=0	; i < MAX_LED_ROWS	; i++)
		BlinkMask[i] ^= BlinkLEDs[i];	

	blink_rate = HALF_SECOND;
	}		
}

//***************************************************//
// Unpack a CANOpen message                            //
//***************************************************//
void CanIn(void)
{
 char k;
 unsigned int Id_p;

  if (RXB_B [CAN_OPEN_IdNet].ST_B.IN)		//NMT COB-ID=x0000
   {
    RXB_B [CAN_OPEN_IdNet].ST_B.IN = 0;
    
	switch (RXB_B [CAN_OPEN_IdNet].TXBD0)
		{

		case CAN_REQUEST_START:
			{
			if (RXB_B [CAN_OPEN_IdNet].TXBD1 == 0 || RXB_B [CAN_OPEN_IdNet].TXBD1 == Id) // if all or me
				{
				StatoUnita        = CAN_STATE_OPERATIONAL;
				error_persistancy_count = ERROR_DEBOUNCE;
				ReadKeypad();
				SendKeypad();
				}
			break;
			}
		case CAN_REQUEST_STOP:      // STOP
			{
			if (RXB_B [CAN_OPEN_IdNet].TXBD1 == 0 || RXB_B [CAN_OPEN_IdNet].TXBD1 == Id) // if all or me
			{
				StatoUnita = CAN_STATE_STOPPED;
				Stop_unit();
			}
			break;
			}
		case CAN_REQUEST_ENTER_PREOP:      // ENTER PREOPERATIONAL
			{
			if (RXB_B [CAN_OPEN_IdNet].TXBD1 == 0 || RXB_B [CAN_OPEN_IdNet].TXBD1 == Id) // if all or me
			{
				StatoUnita = CAN_STATE_PREOPERATIONAL;
				Stop_unit();
			}
			break;
			}
		case CAN_REQUEST_RESET:      // RESET
			{
			if (RXB_B [CAN_OPEN_IdNet].TXBD1 == 0 || RXB_B [CAN_OPEN_IdNet].TXBD1 == Id) // if all or me
				{
				StatoUnita = CAN_STATE_PREOPERATIONAL;
				Stop_unit();
				init_cip ();
				}
			break;
			}
		default:;
		}
   }

  if (RXB_B [CAN_OPEN_PDO1].ST_B.IN)
   {
    RXB_B [CAN_OPEN_PDO1].ST_B.IN = 0;		//lighting
    LEDs[0] = RXB_B [CAN_OPEN_PDO1].TXBD0;
    LEDs[1] = RXB_B [CAN_OPEN_PDO1].TXBD1;
    LEDs[2] = RXB_B [CAN_OPEN_PDO1].TXBD2;
    LEDs[3] = RXB_B [CAN_OPEN_PDO1].TXBD3;
    LEDs[4] = RXB_B [CAN_OPEN_PDO1].TXBD4;
    LEDs[5] = RXB_B [CAN_OPEN_PDO1].TXBD5;	
    }

  if (RXB_B [CAN_OPEN_PDO2].ST_B.IN)		//blinking
    {
    RXB_B [CAN_OPEN_PDO2].ST_B.IN = 0;
    BlinkLEDs[0] = RXB_B [CAN_OPEN_PDO2].TXBD0;
    BlinkLEDs[1] = RXB_B [CAN_OPEN_PDO2].TXBD1;
    BlinkLEDs[2] = RXB_B [CAN_OPEN_PDO2].TXBD2;
    BlinkLEDs[3] = RXB_B [CAN_OPEN_PDO2].TXBD3;
    BlinkLEDs[4] = RXB_B [CAN_OPEN_PDO2].TXBD4;
    BlinkLEDs[5] = RXB_B [CAN_OPEN_PDO2].TXBD5;
	for (k=0	; k<6	; k++)					//new blink pattern, clear old one
		BlinkMask[k] =0;
    }           
}

//***************************************************//
// Start execution                                   //
//***************************************************//
void main ( )
{ 
 unsigned long counter,i;

  { _asm movlw 0xb0 movwf 0xf9c,0 _endasm }	// x Errata - Table Read

  init_cip ();
  SendEmergency(0x80,0x00);

  // Main loop
  for (;;)
   {
    _asm clrwdt _endasm

    CanOut();										// Send outstanding CAN messages if any
    CanIn ();					    				// Unpack CAN messages if any

	if (INTCONbits.TMR0IF)							// 1 ms tasks
		{
		TMR0L = 0x0 - Timer0tick_ms;				//Reset tmr0
 		INTCONbits.TMR0IF = 0;

		if ((--heartbeat_count.count) == 0)
			{
			SendHeartbeat ();
			heartbeat_count.count = heartbeat_rate.count;
			}	
			TreatBlinkMask();						//blink mask changes each 1/2 sec
		}


	if (PIR1bits.TMR1IF)
	{
		PIR1bits.TMR1IF = 0;
		if (StatoUnita == CAN_STATE_OPERATIONAL)
		{
			if (test_error_now == TRUE)
			{
				Test_for_Error();								//error test: once each 7 keypad reeads
				if (error_persistancy_count == ERROR_DEBOUNCE)			// leaky bucket counter reinitialized
					test_error_now = FALSE;								// continue to check error if we are deboucing a previous error
			}
			else if ((check_keypad_now == TRUE) && (StatoUnita == CAN_STATE_OPERATIONAL))
			{ 
				if (Keypad_Changed()) SendKeypad();    			//keypad treatment with debounce
				check_keypad_now = FALSE;  						//defer keypad reads 
			}
			if (StatoUnita == CAN_STATE_OPERATIONAL) LightLEDs();	//LED variations each 1ms.

		}//state
	}//TMR1IF
 } //for

}



