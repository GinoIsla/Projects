/**************************************************************************
MODULE:    USER
CONTAINS:  MicroCANopen Object Dictionary and Process Image implementation
COPYRIGHT: Embedded Systems Academy, Inc. 2002-2004.
           All rights reserved. www.microcanopen.com
           This software was written in accordance to the guidelines at
           www.esacademy.com/software/softwarestyleguide.pdf
DISCLAIM:  Read and understand our disclaimer before using this code!
           www.esacademy.com/disclaim.htm
LICENSE:   THIS IS THE EDUCATIONAL VERSION OF MICROCANOPEN
           See file license_educational.txt or
           www.microcanopen.com/license_educational.txt
           A commercial MicroCANopen license is available at
           www.CANopenStore.com
VERSION:   2.10, ESA 12-JAN-05
           $LastChangedDate: 2005-01-12 13:53:59 -0700 (Wed, 12 Jan 2005) $
           $LastChangedRevision: 48 $
***************************************************************************/ 

#include <LPC21XX.H> // LPC21XX Peripheral Registers
#include <string.h>

#include "mco.h"
#include "mcohw.h"

#if (NR_OF_RPDOS != 2)
  #if (NR_OF_TPDOS != 2)
ERROR: This example is for 2 TPDOs and 2 RPDOs only
  #endif
#endif

// Global timer/conter variable, incremented every millisecond
extern UNSIGNED16 volatile gTimCnt;


/**************************************************************************
GLOBAL VARIABLES
***************************************************************************/ 

// This structure holds all node specific configuration
UNSIGNED8 volatile gProcImg[PROCIMG_SIZE];

// Table with SDO Responses for read requests to OD
UNSIGNED8 MEM_CONST SDOResponseTable[] = {
// Each Row has 8 Bytes:
// Command Specifier for SDO Response (1 byte)
//   bits 2+3 contain: '4' – {number of data bytes}
// Object Dictionary Index (2 bytes, low first)
// Object Dictionary Subindex (1 byte)
// Data (4 bytes, lowest bytes first)

// [1000h,00]: Device Type
SDOREPLY(0x1000, 0x00, 4, OD_DEVICE_TYPE),

#ifdef OD_SERIAL
// [1018h,00]: Identity Object, Number of Entries = 4
SDOREPLY(0x1018, 0x00, 1, 0x00000004L),
#else
// [1018h,00]: Identity Object, Number of Entries = 3
SDOREPLY(0x1018, 0x00, 1, 0x00000003L),
#endif

// [1018h,01]: Identity Object, Vendor ID
SDOREPLY(0x1018, 0x01, 4, OD_VENDOR_ID),

// [1018h,02]: Identity Object, Product Code
SDOREPLY(0x1018, 0x02, 4, OD_PRODUCT_CODE),

// [1018h,03]: Identity Object, Revision
SDOREPLY(0x1018, 0x03, 4, OD_REVISION),

#ifdef OD_SERIAL
// [1018h,04]: Identity Object, Serial
SDOREPLY(0x1018, 0x04, 4, OD_SERIAL),
#endif

// [2018h,00]: MicroCANopen Identity Object, Number of Entries = 3
SDOREPLY(0x2018, 0x00, 1, 0x00000003L),

// [2018h,01]: MicroCANopen Identity Object, Vendor ID = 01455341, ESA Inc.
SDOREPLY(0x2018, 0x01, 4, 0x01455341L),

// [2018h,02]: MicroCANopen Identity Object, Product Code = "MCOP"
SDOREPLY4(0x2018, 0x02, 4, 'P', 'O', 'C', 'M'),

// [2018h,03]: MicroCANopen Identity Object, Revision = 1.20
SDOREPLY(0x2018, 0x03, 4, 0x00010020L),

#ifdef PDO_IN_OD
  // NOTE: These entries must be added manually. The parameters must match
  // the parameters used to call the functions MCO_InitRPDO and MCO_InitTPDO.

  // These entries are necessary to be fully CANopen compliant.
  // Suppported in commercial version of MicroCANopen available from
  // www.CANopenStore.com

  // Warning: This version is not fully CANopen compliant - PDO_IN_OD must not be defined
  #error Warning: This version of MicroCANopen has a limited Object Dictionary! Un-define PDO_IN_OD to confirm!
#endif // PDO_IN_OD

  // End-of-table marker
  SDOREPLY(0xFFFF, 0xFF, 0x0F, 0xFFFFFFFFL),
};

#ifdef PROCIMG_IN_OD
  // Table with Object Dictionary entries to process data.

  // These entries are necessary to be fully CANopen compliant.
  // Suppported in commercial version of MicroCANopen available from
  // www.CANopenStore.com

  // Warning: This version is not fully CANopen compliant - PROCIMG_IN_OD must not be defined
  #error Warning: This version of MicroCANopen has a limited Object Dictionary! Un-define PROCIMG_IN_OD to confirm!
#endif // PROCIMG_IN_OD


/**************************************************************************
GLOBAL FUNCTIONS
***************************************************************************/ 

/**************************************************************************
DOES:    Call-back function for occurance of a fatal error. 
         Stops operation and displays blnking error pattern on LED
**************************************************************************/
void MCOUSER_FatalError (UNSIGNED16 ErrCode)
{
  gProcImg[OUT_ana_2] = (UNSIGNED8) ErrCode;
  gProcImg[OUT_ana_2+1] = (UNSIGNED8) ErrCode >> 8;

  // To Do: DEBUG, report Error Code
  while(1)
  {
  }
}


/**************************************************************************
DOES:    Call-back function for reset application.
         Starts the watchdog and waits until watchdog causes a reset.
**************************************************************************/
void MCOUSER_ResetApplication (void)
{
  WDTC = 0x80; // Watchdog reload value
  WDMOD = 0x03; // Enable Watchdog
  WDFEED = 0xAA; // First Watchdog feed sequence 
  WDFEED = 0x55;
  while (1) // No wait until Watchdog hits
  {
  }
}


/**************************************************************************
DOES:    Call-back function for reset communication.
         Re-initializes the process image and the entire MicroCANopen
         communication.
**************************************************************************/
void MCOUSER_ResetCommunication (void)
{
UNSIGNED8 i;
UNSIGNED16 delay;

  // Initialize Process Variables
  for (i = 0; i < PROCIMG_SIZE; i++)
  {
    gProcImg[i] = 0;
  }

  // 125kbit, Node 7, 2s heartbeat
  MCO_Init(125,0x07,2000); 

  // DEBUG: Delay 10ms for all external HW to catch up
  delay = gTimCnt + 10;
  while (!MCOHW_IsTimeExpired(delay))
  {
  }

  MCO_InitRPDO(1,0,4,OUT_digi_1); 
  // RPDO1, default ID(0x200+nodeID), 4 bytes

  MCO_InitRPDO(2,0,4,OUT_ana_1); 
  // RPDO2, default ID, 4 bytes

  MCO_InitTPDO(1,0,300,50,4,IN_digi_1);    
  // TPDO1, default ID (0x180+nodeID), 300ms event, 50ms inhibit, 4 bytes
  
  MCO_InitTPDO(2,0,200,20,4,IN_ana_1); 
  // TPDO2, default ID (0x280+nodeID), 200ms event, 20ms inhibit, 4 bytes
}

/**************************************************************************
END-OF-FILE 
***************************************************************************/ 

