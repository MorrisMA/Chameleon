Chameleon - Arduino-compatible FPGA Shield Board
=======================

Copyright (C) 2013, Michael A. Morris <morrisma@mchsi.com>.
All Rights Reserved.

Released under LGPL.

General Description
-------------------

The Chameleon board is an FPGA-based shield compatible with an Arduino UNO 
base board. The Chameleon is the same form factor as the Arduino UNO. The 
Chameleon board provides a limited number of buffered Arduino UNO I/O 
connections. Level shifters are included to allow the Chameleon to support 
both +5V and +3.3V I/O signal levels. (The user manually sets the I/O 
signalling voltage using a jumper block.) 

The Chameleon provides the following connections to the Arduino UNO:

    (1)  +5V        - Allows Chameleon to be powered from the UNO
    (2)  GND        - Common signal/power return

    (3)  IO[0]      - Port D[0]; TTL UART RxD             (Level Shift Open)
    (4)  IO[1]      - Port D[1]; TTL UART TxD             (Level Shift Open)
    (5)  IO[2]      - Port D[2]; INT0 (Interrupt 0 Input) (Level Shift Drvr)
    (6)  IO[3]      - Port D[3]; INT1 (Interrupt 1 Input) (Level Shift Drvr)
    (7)  IO[4]      - Port D[4]; T0   (Timer 0 Output)    (Level Shift Drvr)
    (8)  IO[5]      - Port D[5]; T1   (Timer 1 Output)    (Level Shift Drvr)

    (9)  IO[10]     - Port B[2]; SS   (SPI Slave Slct)    (Level Shift Drvr)
    (10) IO[11]     - Port B[3]; MOSI                     (Level Shift Drvr)
    (11) IO[12]     - Port B[4]; MISO                     (Level Shift Drvr)
    (12) IO[13]     - Port B[5]; SCK  (SPI Slave Clk)     (Level Shift Drvr)
    (13) SDA        - AD[4];     SDA  (I2C Serial Data)   (Level Shift Open)
    (14) SCL        - AD[5];     SCL  (I2C Serial Clk)    (Level Shift Open)

The term "Level Shift Open" indicates that the level shifter on board supports 
open-source/open-drain type of signals. In other words, the level shifter can 
be used with open-drain busses such as I2C that use pull-up resistor to 
passively terminate the bus and to set the bus to logic 1. The term "Level 
Shift Drvr" is used to indicate that the level shifter on board is an active 
driver. The level shifter is not able to drive heavy loads, but it does 
actively switch. Thus, Chameleon I/O signals buffered by such a driver should 
not be used for open source/open drain busses.

The Chameleon board is available with one of two Xilinx Spartan 3A FPGAs:

    (1) XC3S50A-4VQG100I, or
    (2) XC3S200A-4VQG100I.

The XC3S50A FPGA is described by Xilinx as having the equivalent of 50,000 
logic gates. The XC3S50A has 1,408 FFs and 4-input Look-Up Tables (LUTs), 62 
I/O and 6 input-only user configurable pins, three (3) 18kb Block RAMs, and 
two Digital Clock Managers (DCMs). Xilinx describes the XC3S200A FPGA as 
having the equivalent of 200,000 logic gates. The XC3S200A has the same number 
of user configurable pins, but has 3,584 FFs and 4-input Look-Up Tables 
(LUTs), sixteen (16) 18kb Block RAMs, and 4 DCMs.

Beyond the twelve (12) I/O connections to the Arduino UNO, the Chameleon
provides the following features:

    (1) 128kB SRAM              - External User RAM
    (2) 32Mb SPI Flash EPROM    - Configuration Image and User Data Flash
    (3) 512B SPI FRAM           - Non-volatile Ferro-Electric RAM
    (4) two 4-wire RS-232 or 2-wire RS-485 ports (drivers and connector)

In support of the open hardware concept of which the Arduino orgranization 
is a leader, the Chameleon is provided as an open hardware platform. The
schematics and BOMs are freely available as PDFs. 

The Chameleon board is primarily intended to be a slave device in an Arduino 
project. It specifically provides a number of interfaces between an Arduino 
base board and the Chameleon for this purpose (see above). It is envisioned 
that a Chameleon equipped with the XC3S50A FPGA will not contain a soft-core 
processor (as demonstrated in this project). With an XC3S50A FPGA, the board 
is best suited as a dual-channel bufferred interface for industrial automation 
interfaces such as Modbus. The user/integrator is free to configure the much 
lower cost XC3S50A FPGA to use the external SRAM as a deep RAM-based FIFO, and 
to provide an I2C, SPI, or UART slave interface in order to interface the 
Chameleon to the Arduino base board.

With a XC3S200A FPGA, the Chameleon board can be used as a slave or a master
device. As a slave device, a Chameleon board equipped with an XC3S200A FPGA
can support a soft-core processor. The soft-core processor demonstrated in
this project can operate from 26-28kB of internal block RAM, and operate at
clock rates in excess of 30 MHz. As configured for this application, the
M65C02_CPU soft-core processor operates at 48 MHz using a four clock micro-
cycle. (Single cycle operation is possible, but is beyond the scope of this
project.) In this configuration, the 65C02-compatible core provides access
to a very fast microcomputer with access to two buffered UARTs and a buffer-
ed SPI master interface, and 26 kB of internal block RAM and 128 kB of ex-
ternal SRAM. When attached to an SPI/SSP slave interface and dual-port RAM
interface to an Arduino-compatible base board, the M65C02 becomes a very 
powerful intelligent peripheral.

As an Arduino-compatible base board, a Chameleon board equipped with an 
XC3S200A FPGA can be a very economical custom controller. The M65C02 soft-
core provided in this project is not the only open source soft-core pro-
cessor that can be used in such an application. The flexibility of the
Chameleon board is only limited by the imagination of those using it. The
FPGA is very flexible, and the external memory and serial interfaces which
connect to it provide a powerful starting point for many hobby and indus-
trial control projects.

Implementation
--------------

This FPGA project demonstrates a 65C02-compatible soft-core processor in the 
Chameleon FPGA Development Board. 

Synthesis
---------

The initial FPGA project synthesized into the Chameleon's FPGA is another 
soft-core processor project based on the open-source M65C02 processor core. 
Using ISE 10.1i SP3, the implementation results for an XC3S200A-4VQ100I are as 
follows:

    Device Utilization Summary
    Logic Utilization                                       Used    Avail   Util
        Number of Slice Flip Flops                            758   3,584    21%   
        Number of 4 input LUTs                              1,479   3,584    41%
                                                            
    Logic Distribution                                      
        Number of occupied Slices                             896   1,792    50%   
            Number of Slices containing only related logic    896     896   100%   
            Number of Slices containing unrelated logic         0     896     0%
                                                            
    Total Number of 4 input LUTs                            1,492   3,584    41%   
            Number used as logic                            1,354       
            Number used as a route-thru                        13       
            Number used for Dual Port RAMs                    124       
            Number used as Shift registers                      1       
                                                            
    Number of bonded IOBs                                   
        Number of bonded                                       21      68    30%   
        IOB Flip Flops                                          2       
    Number of BUFGMUXs                                          3      24    12%   
    Number of DCMs                                              1       4    25%   
    Number of RAMB16BWEs                                       15      16    93%   
 
Best Case Achievable:   20.370 ns (0.231 ns Setup, 0.617 ns Hold)

Status
------

Design and verification of the various modules is complete. This project is 
integrating modules previously designed, implemented and tested. 


Release Notes
-------------

###Release 0.1

This initial release of the project has not verified that the integration 
performed to simply synthesize, map, place, and route the FPGA has not broken 
something. A functional test and a test on the Chameleon HW itself remain to 
be performed. The Chameleon board itself is undergoing verification. A board 
level functional test image has been developed to test all of the output 
signal paths. Those tests have been successful. (The user LEDs blink.)

The Chameleon's board functional test has been loaded into the XC3S200A-
4VQG100I FPGA using both JTAG and SPI. Thus, the SPI configuration Flash EPROM 
and the mode and version select settings have been verified. These tests were 
all performed using an Arduino UNO as the base board, and powering the 
Chameleon from the UNO's +5V bus. (The UNO is being powered via its USB 
connector.) The board functional test image is also using the 48MHz oscillator 
for its clock.

###Release 0.2

Chameleon FPGA has been programmed using the M16C5x soft-core processor SoC. 
M16C5x operating at 48 MHz (single cycle mode) and the UART is configured to 
operate at 29.4912 MHz. Same file transfer test previously used to validate 
the M16C5x SoC project reused, and the Chameleon successfully receives and 
echoes the file at 921.6 kbaud. (The M16C5x SoC project requires just 33% of 
the XC3S200A-4VQG100I FPGA used in the Chameleon prototypes. Adding a second 
UART brings the resource utilization to 50%.)

When plugged onto a Arduino UNO, there is physical interference between the 
second serial port's I/O connector and the tope of the UNO's USB Type B 
connector. Changed the part number of the stacking connectors to the version 
with a greater stacking height.

Using another prototyping card in place of the UNO, discovered that an error 
in the power pin assignments on the Arduino UNO power connector: +3.3V and +5V 
pins swapped. Corrected the symbol and applied the changes to the PCB. Changed 
the circuit to make IOREF independent of the +5V power pin. Retained the 
jumper to allow the Chameleon to have the IO voltage reference of its voltage 
translated set as either IOREF or +3.3V.

Also found that the SRAM used in constructing the prototypes was incorrectly 
selected. The value used is a +5V-only device. Adjusted the schematic and BOM 
to correct this issue, and added a second/alternate part as well.
