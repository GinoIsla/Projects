/**************************************************************************
MODULE:    MAIN
CONTAINS:  Example application using MicroCANopen
           Philips LPC2000 derivatives with CAN interface.
           Compiled and Tested with Keil Tools www.keil.com
COPYRIGHT: Embedded Systems Academy, Inc. 2002 - 2005
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

#include "mco.h"
#include <LPC21XX.H> // LPC21XX Peripheral Registers

// external declaration for the process image array
extern UNSIGNED8 MEM_NEAR gProcImg[];

/**************************************************************************
DOES:    Execute an A to D conversion
RETURNS: Converted value
**************************************************************************/
UNSIGNED32 read_poti(
  void
  ) 
{    
  UNSIGNED32 val;

  ADCR |= 0x01000000; // Start A/D Conversion

  do 
  {
    val = ADDR; // Read A/D Data Register
  } 
  while ((val & 0x80000000) == 0); // Wait for end of A/D Conversion

  ADCR &= ~0x01000000; // Stop A/D Conversion
  val = (val >> 6) & 0x03FF; // Extract AIN0 Value

  return val;
}


/**************************************************************************
DOES:    The main function
RETURNS: nothing
**************************************************************************/
int main(
  void
  )
{
UNSIGNED32 pot;

  // No divider: peripheral clock = processor clock
  VPBDIV = 1; 
    
  // Init Vector Interrupt Controller
  VICIntEnClr = 0xFFFFFFFF; // Disable all Ints
  VICIntSelect = 0x00000000;

  IODIR1 = 0x00FF0000; // P1.16..23 defined as Outputs
  ADCR   = 0x00270401; // Setup A/D: 10-bit AIN0 @ 3MHz 

  // Reset/Initialize CANopen communication
  MCOUSER_ResetCommunication();

  // foreground loop
  while(1)
  {
    // Update process data
    // Echo all data
    gProcImg[IN_digi_1] = gProcImg[OUT_digi_1];
    gProcImg[IN_digi_2] = gProcImg[OUT_digi_2];
    gProcImg[IN_digi_3] = gProcImg[OUT_digi_3];
    gProcImg[IN_digi_4] = gProcImg[OUT_digi_4];

    // first analog input is real I/O
    pot = read_poti();
    gProcImg[IN_ana_1] = pot & 0x000000FF; // lo byte
    gProcImg[IN_ana_1+1] = (pot >> 8) & 0x000000FF; // hi byte

    // echo all other I/O values from input to output
    // analog
    gProcImg[IN_ana_2]   = gProcImg[OUT_ana_2];
    gProcImg[IN_ana_2+1] = gProcImg[OUT_ana_2+1];

    // Operate on CANopen protocol stack
    MCO_ProcessStack();
  } // end of while(1)
} // end of main

