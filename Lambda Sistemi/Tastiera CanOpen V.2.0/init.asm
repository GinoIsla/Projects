#include "P18F458.INC"



;Configuration Byte 4L Options
_DEBUG_ON_4L      EQU  H'7F'    ; Enabled
_DEBUG_OFF_4L     EQU  H'FF'    ; Disabled

_LVP_ON_4L        EQU  H'FF'    ; Enableda
_LVP_OFF_4L       EQU  H'FB'    ; Disabled

_CP_200_1FFF      EQU  H'FE'    ; Disabled


    ; Configurazione bit
	__CONFIG	_CONFIG1L, _CP_OFF_1L
	__CONFIG	_CONFIG1H, _OSCS_OFF_1H & _HSPLL_OSC_1H
	__CONFIG	_CONFIG2L, _BOR_ON_2L & _BORV_27_2L & _PWRT_ON_2L
	__CONFIG	_CONFIG2H, _WDT_ON_2H & _WDTPS_128_2H
	__CONFIG	_CONFIG4L, _STVR_ON_4L & _LVP_OFF_4L
	__CONFIG	_CONFIG4L, _DEBUG_OFF_4L
	__CONFIG	_CONFIG5L, _CP_200_1FFF
	

end
   
