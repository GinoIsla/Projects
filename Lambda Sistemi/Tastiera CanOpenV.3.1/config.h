//
// See C:\mcc18\docs\hlpPIC18ConfigSet FOR config varaibles. 
//

#pragma config OSC = XT, FCMEN = OFF, IESO = OFF
#pragma config PWRT = OFF, BOREN = OFF, BORV = 2
#pragma config WDT = ON, WDTPS=1, MCLRE = OFF, LPT1OSC = OFF
#pragma config PBADEN = OFF, XINST = OFF, BBSIZ = 1024
#pragma config LVP = OFF, STVREN = ON
#pragma config CP0 = ON, CP1 = ON, CP2 = ON, CP3 =ON
#pragma config CPB = ON, CPD = ON, WRT0 = ON, WRT1 = ON
#pragma config WRT2 = ON, WRT3 = ON, WRTB = ON, WRTC = ON
#pragma config WRTD = ON, EBTR0 = ON, EBTR1 = ON, EBTR2 = ON
#pragma config EBTR3 = ON, EBTRB = ON

#ifdef debug
#pragma config DEBUG = ON
#else
#pragma config DEBUG = OFF
#endif


