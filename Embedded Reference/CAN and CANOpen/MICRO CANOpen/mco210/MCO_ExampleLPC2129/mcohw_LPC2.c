/**************************************************************************
MODULE:    MCOHW_LPC2
CONTAINS:  Preliminary, limited hardware driver implementation for 
           Philips LPC2000 derivatives with CAN interface.
           Compiled and Tested with Keil Tools www.keil.com
COPYRIGHT: Embedded Systems Academy, Inc. 2002-2005.
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

#include "mcohw.h"

// Process data communicated via CAN
extern UNSIGNED8 gProcImg[PROCIMG_SIZE];

// Define CAN SFR address bases 
#define CAN_REG_BASE                    (0xE0000000)
#define ACCEPTANCE_FILTER_RAM_BASE      (CAN_REG_BASE + 0x00038000)
#define ACCEPTANCE_FILTER_REGISTER_BASE (CAN_REG_BASE + 0x0003C000)
#define CENTRAL_CAN_REGISTER_BASE       (CAN_REG_BASE + 0x00040000)              
#define CAN_1_BASE                      (CAN_REG_BASE + 0x00044000)              
#define CAN_2_BASE                      (CAN_REG_BASE + 0x00048000)              

// Common CAN bit rates
#define   CANBitrate125k_12MHz          0x001C001D
#define   CANBitrate250k_12MHz          0x001C000E

// Maximum number of FullCAN Filters
#define MAX_FILTERS 20

// Timer Interrupt
void MCOHW_TimerISR (void) __attribute__ ((interrupt)); 

// CAN Interrupt
void MCOHW_CANISR_Err (void) __attribute__ ((interrupt));
void MCOHW_CANISR_Tx1 (void) __attribute__ ((interrupt));
void MCOHW_CANISR_Rx1 (void) __attribute__ ((interrupt));
void MCOHW_DefaultISR (void) __attribute__ ((interrupt)); 


// Global timer/conter variable, incremented every millisecond
UNSIGNED16 volatile gTimCnt = 0;

// Counts number of filters (CAN message objects) used
UNSIGNED16 volatile gCANFilter = 0;

// Type definition to hold a FullCAN message
typedef struct
{
  UNSIGNED32 Dat1;
  UNSIGNED32 DatA;
  UNSIGNED32 DatB;
} FULLCAN_MSGFIELD;

// FullCAN Message List
FULLCAN_MSGFIELD volatile gFullCANList[MAX_FILTERS];

// Lookup table for receive filters
UNSIGNED16 gFilterList[20];                           


// Pull the next CAN message from receive buffer
UNSIGNED8 MCOHW_PullMessage (CAN_MSG MEM_FAR *pReceiveBuf)
{
UNSIGNED16 obj;
UNSIGNED32 *pSrc; // Source Pointer
UNSIGNED32 *pDst; // Destination Pointer

  obj = 0;
  pDst = (UNSIGNED32 *) &(pReceiveBuf->BUF[0]);
  pSrc = (UNSIGNED32 *) &(gFullCANList[0].Dat1);
  
  while (obj < gCANFilter)
  {
      // if its currently updated, we come back next time and do not wait here
    // semaphore set to 11?
    if ((*pSrc & 0x03000000L) == 0x03000000L)
    { // Object Updated since last access
      *pSrc &= 0xFCFFFFFF; // clear Semaphore
      pSrc++; // Set to DatA
      *pDst = *pSrc; // Copy DatA
      pSrc++; // Set to DatB
      pDst++; // Set to DatB
      *pDst = *pSrc; // Copy DatB
      pSrc -= 2; // Back to Dat1

      pReceiveBuf->ID = (UNSIGNED16) *pSrc & 0x07FF;
      pReceiveBuf->LEN = (UNSIGNED8) (*pSrc >> 16) & 0x0F;

      // Re-read semaphore
      if ((*pSrc & 0x03000000L) == 0)
      { // Only return it, if not updated while reading
        return 1;
      }
    }
    obj ++; // Next message object buffer
    pSrc += 3; // Next record in gFullCANList array
  }
  return 0; // Return False, no msg rcvd 
}

// Push the next transmit message into transmit queue
UNSIGNED8 MCOHW_PushMessage (CAN_MSG MEM_FAR *pTransmitBuf)
{
UNSIGNED32 *pAddr;  
UNSIGNED32 status;
UNSIGNED32 candata;
UNSIGNED32 *pCandata;
UNSIGNED32 TXBufOffset;
  
  if (pTransmitBuf->ID == 0)
  { // This may not happen
    pTransmitBuf->ID = 1;
    pTransmitBuf->LEN = 8;
  }
  
  status = C1SR; // CANSR

  if (!(status & 0x00000004L))
  { // Transmit Channel 1 is not available
    if (!(status & 0x00000400L))
    { // Transmit Channel 2 is not available
      if (!(status & 0x00040000L))
      { // Transmit Channel 3 is not available
        return 0; // No channel available
      }
      else
      {
        TXBufOffset = 0x08;
      }
    }
    else
    {
      TXBufOffset = 0x04;
    }
  }
  else
  {
    TXBufOffset = 0x00;
  }

  candata = pTransmitBuf->LEN;
  candata <<= 16;

  pAddr = (UNSIGNED32 *) &C1TFI1 + TXBufOffset;
  *pAddr = candata;  
  
  pAddr++;
  *pAddr = pTransmitBuf->ID;
 
  pCandata = (UNSIGNED32 *) &(pTransmitBuf->BUF[0]);
  pAddr++;
  *pAddr = *pCandata;

  pCandata++;
  pAddr++;
  *pAddr = *pCandata;
  
  if (TXBufOffset == 0x00)
  {
    C1CMR = 0x21; // Transmission Request  Buf 1
  }
  else if (TXBufOffset == 0x04)
  {
    C1CMR = 0x41; // Transmission Request Buf 2
  }
  else if (TXBufOffset == 0x08)
  {
    C1CMR = 0x81; // Transmission Request Buf 3
  }
  else
  {
    return 0;
  }

  return 1;
}


/**************************************************************************
DOES: Reads and returns the value of the current 1 millisecond system
      timer tick.
**************************************************************************/
UNSIGNED16 MCOHW_GetTime (void)
{
  return gTimCnt;
}


// Checks if a TimeStamp expired
UNSIGNED8 MCOHW_IsTimeExpired(UNSIGNED16 timestamp)
{
UNSIGNED16 time_now;

  time_now = gTimCnt;
  if (time_now > timestamp)
  {
    if ((time_now - timestamp) < 0x8000)
      return 1;
    else
      return 0;
  }
  else
  {
    if ((timestamp - time_now) > 0x8000)
      return 1;
    else
      return 0;
  }
}

// Timer ISR
void MCOHW_TimerISR 
  (
  void
  ) 
{
  gTimCnt++;
  T0IR = 1; // Clear interrupt flag
  VICVectAddr = 0xFFFFFFFF; // Acknowledge Interrupt
}

// CDefault ISR
void MCOHW_DefaultISR 
  (
  void
  ) 
{
  VICVectAddr = 0xFFFFFFFF; // Acknowledge Interrupt
  while (1)
  {
  // DEBUG: WE SHOULD NEVER GET HERE
  }
}
                                                        
// CAN ISR
void MCOHW_CANISR_Err 
  (
  void
  ) 
{
  VICVectAddr = 0xFFFFFFFF; // Acknowledge Interrupt
  while (1)
  {
  // DEBUG: WE SHOULD NEVER GET HERE
  }
}

void MCOHW_CANISR_Tx1 
  (
  void
  ) 
{
  VICVectAddr = 0xFFFFFFFF; // Acknowledge Interrupt
}


void MCOHW_CANISR_Rx1 
  (
  void
  ) 
{
UNSIGNED32 buf;
UNSIGNED32 *pDest;

  if (!(C1RFS & 0xC0000400L))
  { // 11-bit ID, no RTR, matched a filter

    // initialize destination pointer
    // filter number is in lower 10 bits of C1RFS
    pDest = (UNSIGNED32 *) &(gFullCANList[(C1RFS & 0x000003FFL)].Dat1);
    
    // calculate contents for first entry into FullCAN list
    buf = C1RFS & 0xC00F0000L; // mask FF, RTR and DLC
    buf |= 0x01000000L; // set semaphore to 01b
    buf |= C1RID & 0x000007FFL; // get CAN message ID

    // now copy entire message to FullCAN list
    *pDest = buf; 
    pDest++; // set to gFullCANList[(C1RFS & 0x000003FFL)].DatA
    *pDest = C1RDA; 
    pDest++; // set to gFullCANList[(C1RFS & 0x000003FFL)].DatB
    *pDest = C1RDB; 

    // now set the sempahore to complete
    buf |= 0x03000000L; // set semaphore to 11b
    pDest -= 2; // set to gFullCANList[(C1RFS & 0x000003FFL)].Dat1
    *pDest = buf; 
  }

  C1CMR = 0x04; // release receive buffer
  VICVectAddr = 0xFFFFFFFF; // acknowledge Interrupt
}


// Init CAN Interface and Timer
UNSIGNED8 MCOHW_Init 
  (
  UNSIGNED16 BaudRate
  )
{
  if (BaudRate != 125) 
  { // This implementation only supports 125kbit
      return 0;
  }

  // Enable Pins for CAN port 1 and 2
  PINSEL1 |= (UNSIGNED32) 0x00054000; 
  
  C1MOD = 1; // Enter Reset Mode
  C1GSR = 0; // Clear status register
  C1BTR = CANBitrate125k_12MHz; // Set bit timing
  
  AFMR = 0x00000001; // Disable acceptance filter

  // Disable All Interrupts
  C1IER = 0;

  // Enter Normal Operating Mode
  C1MOD = 0; // Operating Mode 

  // Init Interrupts
  VICDefVectAddr = (unsigned long) MCOHW_DefaultISR;

  // Initialize Timer Interrupt
  T0MR0 = 59999; // 1mSec = 60.000-1 counts
  T0MCR = 3; // Interrupt and Reset on MR0
  T0TCR = 1;  // Timer0 Enable

  VICVectAddr0 = (unsigned long) MCOHW_TimerISR; // set interrupt vector
  VICVectCntl0 = 0x20 | 4;  // use it for Timer 0 Interrupt
  VICIntEnable = 0x00000010;  // Enable Timer0 Interrupt

  VICVectAddr1 = (unsigned long) MCOHW_CANISR_Rx1; // set interrupt vector
  VICVectCntl1 = 0x20 | 26;  // use it for CAN Rx1 Interrupt
  VICIntEnable = 0x04000000;  // Enable CAN Rx1 Interrupt
  
  C1IER = 0x0001; // Enable CAN 1 RX interrupt

  gCANFilter = 0; // Reset all filters

  return 1;
}


UNSIGNED8 MCOHW_SetCANFilter 
  (
  UNSIGNED16 CANID
  )
{
int p, n;
int buf0, buf1;
int ID_lower, ID_upper;
UNSIGNED32 candata;
UNSIGNED32 *pAddr;

  if (gCANFilter == 0)
  { // First call, init entry zero
    gFilterList[0] = 0x17FF; // Disabled and unused
  }
  if (gCANFilter >= MAX_FILTERS)
  {
    return 0;
  }

  // Filters must be sorted by priority

  // new filter is sorted into array
  p = 0;
  while (p < gCANFilter) // loop through all existing filters 
  {
    if (gFilterList[p] > CANID)
    {
      break;
    }
    p++;
  }
  // insert new filter here
  buf0 = gFilterList[p]; // save current entry
  gFilterList[p] = CANID; // insert the new entry
  // move all remaining entries one row up
  gCANFilter++;
  while (p < gCANFilter)
  {
    p++;
    buf1 = gFilterList[p];
    gFilterList[p] = buf0;
    buf0 = buf1;
  }

  // Now work on Acceptance Filter Configuration     
  // Acceptance Filter Mode Register = off !
  AFMR = 0x00000001;
  
  // Set CAN filter for 11-bit standard identifiers
  p = 0;

  // Set pointer for Standard Frame Individual
  // Standard Frame Explicit
  SFF_sa = p;

  pAddr = (UNSIGNED32 *) ACCEPTANCE_FILTER_RAM_BASE;
  for (n = 0; n < ((gCANFilter+1)/2); n++)
  {
    ID_lower = gFilterList[n * 2];
    ID_upper = gFilterList[n * 2 + 1];
    // 0x20002000 indicates CAN interface 1
    candata = 0x20002000 + (ID_lower << 16) + ID_upper;
    *pAddr = candata;
    p += 4;
    pAddr++;
  }

  // p is still ENDofTable;
  
  // Set pointer for Standard Frame Groups
  // Standard Frame Group Start Address Register
  SFF_GRP_sa = p;

  // Set pointer for Extended Frame Individual
  // Extended Frame Start Address Register
  EFF_sa = p;

  // Set pointer for Extended Frame Groups
  // Extended Frame Group Start Address Register
  EFF_GRP_sa = p;

  // Set ENDofTable 
  // End of AF Tables Register
  ENDofTable = p;

  // Acceptance Filter Mode Register, start using filter
  AFMR = 0x00000000;
  
  return 1;
}


/*----------------------- END OF FILE ----------------------------------*/

