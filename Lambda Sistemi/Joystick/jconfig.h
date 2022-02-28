//
// See C:\mcc18\docs\hlpPIC18ConfigSet FOR config varaibles. 
//

#pragma config OSC = HS, FCMEN = OFF, IESO = OFF
#pragma config PWRT = ON, BOREN = BOHW, BORV = 2
#pragma config WDT = OFF, WDTPS=128, MCLRE = ON, LPT1OSC = OFF
#pragma config PBADEN = OFF, XINST = OFF, BBSIZ = 1024
#pragma config LVP = OFF, STVREN = ON
#pragma config CP0 = ON, CP1 = ON, CP2 = ON, CP3 =ON
#pragma config CPB = ON, CPD = OFF, WRT0 = ON, WRT1 = ON
#pragma config WRT2 = ON, WRT3 = ON, WRTB = ON, WRTC = ON
#pragma config WRTD = OFF, EBTR0 = ON, EBTR1 = ON, EBTR2 = ON
#pragma config EBTR3 = ON, EBTRB = ON

#define debug

#ifdef debug
#pragma config DEBUG = ON
#else
#pragma config DEBUG = OFF
#endif


