MicroCANopen Example Implementation
===================================

CONTAINS:  Example application using MicroCANopen
           Tested with Atmel's 89C51CC01 CANARY and 
           CANopen Demo Boards
           Using the Keil Compiler - www.keil.com or
           Using the Raisonance Compiler - www.amrai.com
COPYRIGHT: Embedded Systems Academy, Inc. 2002 - 2004
           All rights reserved. www.microcanopen.com
           This software was written in accordance to the guidelines at
           www.esacademy.com/software/softwarestyleguide.pdf
DISCLAIM:  Read and understand our disclaimer before using this code!
           www.esacademy.com/disclaim.htm
LICENSE:   THIS IS THE EDUCATIONAL VERSION OF MICROCANOPEN
           See file license_educational.txt or
           www.microcanopen.com/license_educational.txt
VERSION:   2.10, ESA 12-JAN-05


To compile, create a working directory with all the files from the 
directories MCO_ExampleCC01 and MCO. From within the compiler's
user interface create a new project and add all .c source files to
the project.


Implementation Description
==========================

Node-ID: 7
Baudrate: 125kbit

Messages generated:
0x707 - Heartbeat
  Send every 2 seconds
0x187 - TPDO1 - Four bytes of digital inputs. First byte is the switches/dip
                switches. The remaining three bytes are copied from three
                digital output values received in RPDO1.
				Transmit Trigger: 100ms event time
0x287 - TPDO2 - Two 16-bit analog inputs. Copied from the two 16-bit
                analog output values received in RPDO2.
				Transmit Trigger: 100ms event time and 5ms inhibit time

Messages received:
0x000 - NMT Master command message
0x207 - RPDO1 - Four bytes of digital outputs. First byte is LEDs.
                Remaining bytes are copied to TPDO1.
0x307 - RPDO2 - Two 16-bit analog outputs.
                Copied to TPDO2.


Note on CANopen Conformance
The commercial version of MicroCANopen passes the CANopen 
conformance test with some limitations:

a) The available version of the conformance test (2.0.02) can not 
correctly deal with nodes that only support heartbeat and have no 
node guarding.

b) The conformance test offers limited flexibility in regards to
pre-configured nodes. In order for an EDS to pass the check, many
defaults are expected to be zero. However, pre-configured nodes
typically do not use zeros for event and other timers.


