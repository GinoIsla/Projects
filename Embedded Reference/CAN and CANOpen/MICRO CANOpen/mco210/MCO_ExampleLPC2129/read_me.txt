MicroCANopen Example Implementation
===================================

CONTAINS:  Example application using MicroCANopen
           Tested with Keils MCB2100 development board
           Using the Keil Compiler - www.keil.com
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


To build, open the project file MCO_LPC2.uv2 from within Keil's
MicroVision IDE and select the menu Project | Build Target


Implementation Description
==========================

ONLY CAN INTERFACE 1 IS USED

Node-ID: 7
Baudrate: 125kbit

Messages generated:
0x707 - Heartbeat
                Send every 2 seconds
0x187 - TPDO1 - Four bytes of digital inputs. 
                All bytes copied/echoed from the digital output value
                received in RPDO1.
                Transmit Trigger: 300ms event time and change of state (COS)
                                  with 20ms inhibit time
0x287 - TPDO2 - Two 16-bit analog inputs. The first value is the potentiometer.
                The second value is copied from the analog output value
                received in RPDO2.
                Transmit Trigger: 200ms event time and change of state (COS)
                                  with 50ms inhibit time

Messages received:
0x000 - NMT Master command message
0x207 - RPDO1 - Four bytes of digital outputs.
                All bytes copied to TPDO1 (echo mode).
0x307 - RPDO2 - Two 16-bit analog outputs. The first value is ignored. The
                second value is copied to TPDO2.


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

