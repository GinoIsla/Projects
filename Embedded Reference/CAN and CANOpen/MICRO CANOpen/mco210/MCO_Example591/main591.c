/**************************************************************************
MODULE:    MAIN
CONTAINS:  Example application using MicroCANopen
           Written for Phytec phyCORE 591 with development board
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
#include "r591io.h"
#include <reg591.h>

// external declaration for the process image array
extern UNSIGNED8 MEM_NEAR gProcImg[];

/**************************************************************************
DOES:    The main function
RETURNS: nothing
**************************************************************************/
void main
  (
  void
  )
{
  // Reset/Initialize CANopen communication
  MCOUSER_ResetCommunication();

  // end of initialization, enable all interrupts
  EA = 1;

  // foreground loop
  while(1)
  {
    // Update process data
    // First digital inputs are real I/O
    gProcImg[IN_digi_1] = read_dip_switches();
    gProcImg[IN_digi_2] = check_button(1);
    gProcImg[IN_digi_3] = check_button(2);
    
    // output first digital outputs to LEDs
    switch_leds(gProcImg[OUT_digi_1]); 

    // echo all other I/O values from input to
    // output
    // digital
    gProcImg[IN_digi_4] = gProcImg[OUT_digi_4];

    // first analog input is real I/O
    gProcImg[IN_ana_1] = 0; // lo byte
    gProcImg[IN_ana_1+1] = read_poti(); // hi byte

    // echo all other I/O values from input to output
    // analog
    gProcImg[IN_ana_2]   = gProcImg[OUT_ana_2];
    gProcImg[IN_ana_2+1] = gProcImg[OUT_ana_2+1];

    // Operate on CANopen protocol stack
    MCO_ProcessStack();
  } // end of while(1)
} // end of main

