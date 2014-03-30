////////////////////////////////////////////////////////////////////////////////
//
//  Copyright 2013-2014 by Michael A. Morris, dba M. A. Morris & Associates
//
//  All rights reserved. The source code contained herein is publicly released
//  under the terms and conditions of the GNU Lesser Public License. No part of
//  this source code may be reproduced or transmitted in any form or by any
//  means, electronic or mechanical, including photocopying, recording, or any
//  information storage and retrieval system in violation of the license under
//  which the source code is released.
//
//  The source code contained herein is free; it may be redistributed and/or 
//  modified in accordance with the terms of the GNU Lesser General Public
//  License as published by the Free Software Foundation; either version 2.1 of
//  the GNU Lesser General Public License, or any later version.
//
//  The source code contained herein is freely released WITHOUT ANY WARRANTY;
//  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
//  PARTICULAR PURPOSE. (Refer to the GNU Lesser General Public License for
//  more details.)
//
//  A copy of the GNU Lesser General Public License should have been received
//  along with the source code contained herein; if not, a copy can be obtained
//  by writing to:
//
//  Free Software Foundation, Inc.
//  51 Franklin Street, Fifth Floor
//  Boston, MA  02110-1301 USA
//
//  Further, no use of this source code is permitted in any form or means
//  without inclusion of this banner prominently in any derived works. 
//
//  Michael A. Morris
//  Huntsville, AL
//
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company:         M. A. Morris & Associates 
// Engineer:        Michael A. Morris 
// 
// Create Date:     13:56:44 12/29/2013 
// Design Name:     M65C02 Arduino Shield 
// Module Name:     M65C02_Arduino
// Project Name:    C:\XProjects\ISE10.1i\M65C02_Arduino
// Target Devices:  Generic SRAM-based FPGA 
// Tool versions:   Xilinx ISE10.1i SP3
//
// Description:
//
//  This module demonstrates a 65C02-compatible soft-core processor in a real
//  application. The chosen target is the Chameleon FPGA Development Board. The
//  Chameleon board is a shield compatible with an Arduino UNO base board. The
//  Chameleon is the same form factor as the Arduino UNO. The Chameleon board
//  provides a limited number of buffered Arduino UNO I/O connections. Level
//  shifters are included to allow the Chameleon to support both +5V and +3.3V
//  I/O signal levels. (The user manually sets the I/O signalling voltage using
//  a jumper block.)
//
//  The Chameleon provides the following connections to the Arduino UNO:
//
//      (1)  +5V        - Allows Chameleon to be powered from the UNO
//      (2)  GND        - Common signal/power return
//
//      (3)  IO[0]      - Port D[0]; TTL UART RxD             (Level Shift Open)
//      (4)  IO[1]      - Port D[1]; TTL UART TxD             (Level Shift Open)
//      (5)  IO[2]      - Port D[2]; INT0 (Interrupt 0 Input) (Level Shift Drvr)
//      (6)  IO[3]      - Port D[3]; INT1 (Interrupt 1 Input) (Level Shift Drvr)
//      (7)  IO[4]      - Port D[4]; T0   (Timer 0 Output)    (Level Shift Drvr)
//      (8)  IO[5]      - Port D[5]; T1   (Timer 1 Output)    (Level Shift Drvr)
//
//      (9)  IO[10]     - Port B[2]; SS   (SPI Slave Slct)    (Level Shift Drvr)
//      (10) IO[11]     - Port B[3]; MOSI                     (Level Shift Drvr)
//      (11) IO[12]     - Port B[4]; MISO                     (Level Shift Drvr)
//      (12) IO[13]     - Port B[5]; SCK  (SPI Slave Clk)     (Level Shift Drvr)
//      (13) SDA        - AD[4];     SDA  (I2C Serial Data)   (Level Shift Open)
//      (14) SCL        - AD[5];     SCL  (I2C Serial Clk)    (Level Shift Open)
//
//  The term "Level Shift Open" indicates that the level shifter on board sup-
//  ports open-source/open-drain type of signals. In other words, the level
//  shifter can be used with open-drain busses such as I2C that use pull-up
//  resistor to passively terminate the bus and to set the bus to logic 1. The
//  term "Level Shift Drvr" is used to indicate that the level shifter on board
//  is an active driver. The level shifter is not able to drive heavy loads, but
//  it does actively switch. Thus, Chameleon I/O signals buffered by such a
//  driver should not be used for open source/open drain busses.
//
//  The Chameleon board is available with one of two Xilinx Spartan 3A FPGAs:
//
//      (1) XC3S50A-4VQG100I, or
//      (2) XC3S200A-4VQG100I.
//
//  The XC3S50A FPGA is described by Xilinx as having the equivalent of 50,000
//  logic gates. The XC3S50A has 1,408 FFs and 4-input Look-Up Tables (LUTs), 62
//  I/O and 6 input-only user configurable pins, three (3) 18kb Block RAMs, and
//  two Digital Clock Managers (DCMs). The XC3S200A the same number of user con-
//  figurable pins, but has 3,584 FFs and 4-input Look-Up Tables (LUTs), sixteen
//  (16) 18kb Block RAMs, and 4 DCMs.
//
//  Beyond the twelve (12) I/O connections to the Arduino UNO, the Chameleon
//  provides the following features:
//  
//      (1) 128kB SRAM              - External User RAM
//      (2) 32Mb SPI Flash EPROM    - Configuration Image and User Data Flash
//      (3) 512B SPI FRAM           - Non-volatile Ferro-Electric RAM
//      (4) two 4-wire RS-232 or 2-wire RS-485 ports (drivers and connector)
//
//  In support of the open hardware concept of which the Arduino orgranization 
//  is a leader, the Chameleon is provided as an open hardware platform. The
//  schematics and BOMs are freely available as PDFs. This FPGA project is
//  also available as an LGPL project: https://github.com/MorrisMA/Chameleon.
//
//  The Chameleon board is primarily intended to be a slave device in an Arduino
//  project. It specifically provides a number of interfaces between an Arduino
//  base board and the Chameleon for this purpose (see above). It is envisioned
//  that a Chameleon equipped with the XC3S50A FPGA will not contain a soft-core
//  processor (as demonstrated in this project). With an XC3S50A FPGA, the board
//  is best suited as a dual-channel bufferred interface for industrial automa-
//  tion interfaces such as Modbus. The user/integrator is free to configure the
//  much lower cost XC3S50A FPGA to use the external SRAM as a deep RAM-based
//  FIFO, and to provide an I2C, SPI, or UART slave interface in order to inter-
//  face the Chameleon to the Arduino base board.
//  
//  With a XC3S200A FPGA, the Chameleon board can be used as a slave or a master
//  device. As a slave device, a Chameleon board equipped with an XC3S200A FPGA
//  can support a soft-core processor. The soft-core processor demonstrated in
//  this project can operate from 26-28kB of internal block RAM, and operate at
//  clock rates in excess of 30 MHz. As configured for this application, the
//  M65C02_CPU soft-core processor operates at 48 MHz using a four clock micro-
//  cycle. (Single cycle operation is possible, but is beyond the scope of this
//  project.) In this configuration, the 65C02-compatible core provides access
//  to a very fast microcomputer with access to two buffered UARTs and a buffer-
//  ed SPI master interface, and 26 kB of internal block RAM and 128 kB of ex-
//  ternal SRAM. When attached to an SPI/SSP slave interface and dual-port RAM
//  interface to an Arduino-compatible base board, the M65C02 becomes a very 
//  powerful intelligent peripheral.
//
//  As an Arduino-compatible base board, a Chameleon board equipped with an 
//  XC3S200A FPGA can be a very economical custom controller. The M65C02 soft-
//  core provided in this project is not the only open source soft-core pro-
//  cessor that can be used in such an application. The flexibility of the
//  Chameleon board is only limited by the imagination of those using it. The
//  FPGA is very flexible, and the external memory and serial interfaces which
//  connect to it provide a powerful starting point for many hobby and indus-
//  trial control projects.
//
// Dependencies:
//
// Revision: 
//
//  0.00    14C27   MAM     Initial File Creation.
//
// Additional Comments:
//
////////////////////////////////////////////////////////////////////////////////

module M65C02_Arduino #(
    parameter pIRQ_Vector      = 16'hFFFE,  // Maskable Interrupt Vector
    parameter pBRK_Vector      = 16'hFFFE,  // BRK Instruction Trap Vector
    parameter pRST_Vector      = 16'hFFFC,  // Reset Vector
    parameter pNMI_Vector      = 16'hFFFA,  // Non-Maskable Interrupt Vector

    parameter pStkPtr_Rst      = 8'hFF,     // Stk Ptr Value after Reset
    parameter pInt_Hndlr       = 9'h021,    // _Int microroutine address

    parameter pROM_AddrWidth   = 8'd9,
    parameter pROM_Width       = 8'd36,
    parameter pROM_Init        = "Src/M65C02_uPgm_V3b.coe",
    
    parameter pDEC_AddrWidth   = 8'd8,
    parameter pDEC_Width       = 8'd36,
    parameter pDEC_Init        = "Src/M65C02_IDEC_v3.coe",

    parameter pMMU_Init         = "Src/M65C02_MMU_CPU.coe", // MMU Init. File
    
    parameter pRAM_A_AddrWidth = 8'd14,     // 16384 x 8 Block RAM
    parameter pRAM_B_AddrWidth = 8'd13,     //  8192 x 8 Block RAM
    parameter pMON_AddrWidth   = 8'd11,     //  2048 x 8 Block RAM
    parameter pBus_Width       = 8'd8,      // Bus Width = 8 bits
    parameter pRAM_A_Init      = "Src/65C02_ft.txt",        // Funct. Test Pgm
    parameter pRAM_B_Init      = "Src/M65C02_Tst6.txt",     // Here: JMP Here
    parameter pMON_Init        = "Src/Mon6502_sbc25.txt",   // (0xFFFC)=0x0400
    
    parameter pFrequency       = 48000000,  // (48.0000 MHz * 1)

    parameter pDefault_LCR_A   = 8'h40, // ~BRRE, RTSo, 232 w/o HS, 8N1
    parameter pDefault_IER_A   = 8'h00, // No interrupts enabled
    parameter pBaudrate_A      = 115200,
    parameter pRTOChrDlyCnt_A  = 3,     // RTO asserted on Rx idle 3 char times
    parameter pTF_Depth_A      = 0,     // Tx FIFO Depth = (2**(0+4))=16
    parameter pRF_Depth_A      = 0,     // Rx FIFO Depth = (2**(0+4))=16
    parameter pTF_Init_A       = "Src/UART_TF_16.coe",
    parameter pRF_Init_A       = "Src/UART_RF_16.coe",
    
    parameter pDefault_LCR_B   = 8'h40, // ~BRRE, RTSo, 232 w/o HS, 8N1 
    parameter pDefault_IER_B   = 8'h00, // No interrupts enabled
    parameter pBaudrate_B      = 115200,
    parameter pRTOChrDlyCnt_B  = 3,     // RTO asserted on Rx idle 3 char times
    parameter pTF_Depth_B      = 0,     // Tx FIFO Depth = (2**(0+4))=16
    parameter pRF_Depth_B      = 0,     // Rx FIFO Depth = (2**(0+4))=16
    parameter pTF_Init_B       = "Src/UART_TF_16.coe",
    parameter pRF_Init_B       = "Src/UART_RF_16.coe",

    parameter pDefault_CR      = 8'h30,  // Rate=1/16, Mode=0, Dir=MSB, Sel=0 
    parameter pSPI_FIFO_Depth  = 8'd4,   // Depth = (1 << 4) = 16
    parameter pSPI_FIFO_Init   = "Src/SPI_FIFO_Init_16.coe"
)(
    input   nRst,               // System Reset Input
    input   ClkIn,              // System Clk Input
    
    //  External Memory Interface Bus

    output  nCE0,               // Chip Enable for External RAM/ROM Memory
    output  nOE,                // External Asynchronous Bus
    output  nWE,                // External Asynchronous Bus Write Strobe
    output  XA0,                // Extended Address Output for External Memory
    output  [15:0] A,           // External Memory Address Bus
    inout   [ 7:0] DB,          // External, Bidirectional Data Bus
    
    //  COM A - Asynchronous Serial Port Interface
    
    output  TxD_RS232_A,        // Port A: RS232 Transmit Serial Data Output
    output  nRTS_RS232_A,       // Port A: RS232 Ready To Send Flow Control Output
    input   RxD_RS232_A,        // Port A: RS232 Receive Serial Data Input
    input   nCTS_RS232_A,       // Port A: RS232 Clear To Send Flow Control Input
    
    output  DE_RS485_A,         // Port A: RS485 Drive Enable
    
    output  TxD_RS485_A,        // Port A: RS485 Transmit Serial Data Output
    input   RxD_RS485_A,        // Port A: RS485 Receive Serial Data Input

    //  COM B - Asynchronous Serial Port Interface
    
    output  TxD_RS232_B,        // Port B: RS232 Transmit Serial Data Output
    output  nRTS_RS232_B,       // Port B: RS232 Ready To Send Flow Control Output
    input   RxD_RS232_B,        // Port B: RS232 Receive Serial Data Input
    input   nCTS_RS232_B,       // Port B: RS232 Clear To Send Flow Control Input
    
    output  DE_RS485_B,         // Port B: RS485 Drive Enable

    output  TxD_RS485_B,        // Port B: RS485 Transmit Serial Data Output
    input   RxD_RS485_B,        // Port B: RS485 Receive Serial Data Input

    //  SPI Port Interface
    
    output  [1:0] nCSO,         // SPI I/F Chip Select
    output  SCK,                // SPI I/F Serial Clock
    output  MOSI,               // SPI I/F Master Out/Slave In Serial Data
    input   MISO,               // SPI I/F Master In/Slave Out Serial Data

    //  Non-65C02 Special Interface Signals

    input   nWP                 // Internal Boot/Monitor RAM write protect
);

////////////////////////////////////////////////////////////////////////////////
//
//  Declarations
//

//  ClkGen Interface Signals

wire    Buf_ClkIn;                      // Buffered External Input Clock

wire    Rst;                            // System Reset
wire    Clk;                            // System Clock
wire    Clk90;                          // Phase shifted system clock

//  M65C02 CPU Interface Signals

wire    [2:0] MC;
wire    C2, C3, C4;

wire    NMI;
wor     IRQ;
wire    VP;
wire    WAI, STP;
wire    Fetch, ML;
wire    [ 7:0] CE;
wire    RE, WE;
wire    IntWait, Wait;
wire    [19:0] PA;
wire    [ 7:0] DO;
wor     [ 7:0] DI;

wire    Start, OE;

//  Interrupt Sources

wire    COM_A_IRQ, COM_B_IRQ;       // Interrupt Request signals from UARTs

//  Development Board Interface Signals

wire    WP;

////////////////////////////////////////////////////////////////////////////////
//
//  Implementation
//

// Instantiate the Clk and Reset Generator Module

M65C02_ClkGen   ClkGen (
                    .nRst(nRst),            // External Reset Input
                    .ClkIn(ClkIn),          // External Reference Clock Input
                    
                    .Buf_ClkIn(Buf_ClkIn),  // RefClk   <= Buffered ClkIn

                    .Rst(Rst),              // System Reset
                    .Clk(Clk),              // Clk      <= (M/D) x ClkIn
                    .Clk90(Clk90),          // Quadrature Clk

                    .Clk2x(),               // Clk_UART <= 2x ClkIn 

                    .Locked()               // ClkGen DCM Locked
                );

//  Instantiate M65C02 Processor Cores

wire    CE_uPgm;
wire    [(pROM_AddrWidth - 1):0] uPgm_A;
wire    [(pROM_Width     - 1):0] uPgm_D; 

wire    CE_IDEC;
wire    [(pDEC_AddrWidth - 1):0] IDEC_A;
wire    [(pDEC_Width     - 1):0] IDEC_D; 

M65C02_CPU  #(
                .pIRQ_Vector(pIRQ_Vector),      // Maskable Interrupt Vector
                .pBRK_Vector(pBRK_Vector),      // BRK Instruction Trap Vector
                .pRST_Vector(pRST_Vector),      // Reset Vector
                .pNMI_Vector(pNMI_Vector),      // Non-Maskable Interrupt Vector

                .pStkPtr_Rst(pStkPtr_Rst),      // Stk Ptr Value after Reset
                .pInt_Hndlr(pInt_Hndlr),        // _Int microroutine address

                .pROM_AddrWidth(pROM_AddrWidth),
                .pROM_Width(pROM_Width),
                .pDEC_AddrWidth(pDEC_AddrWidth),
                .pDEC_Width(pDEC_Width),
                
                .pMMU_Init(pMMU_Init)           // Initial MMU State
            ) CPU (
                .Rst(Rst), 
                .Clk(Clk),
                
                .MC(MC),
                .Rdy(Rdy), 

                .NMI(1'b0), 
                .IRQ(IRQ), 
                .VP(), 

                .WAI(),
                .STP(),

                .Fetch(), 
                .ML(), 

                .CE(CE), 
                .RE(RE), 
                .WE(WE),
                
                .IntWait(),
                .Wait(1'b0), 

                .PA(PA), 
                .DI(DI), 
                .DO(DO), 

                .En_uPL(CE_uPgm), 
                .A_uPL(uPgm_A), 
                .uPL(uPgm_D), 

                .En_IDEC(CE_IDEC), 
                .A_IDEC(IDEC_A), 
                .IDEC(IDEC_D)
            );
            
//  Instantiate two BRAMs for the fixed and variable microprogram ROMs of the
//  M65C02 soft-core processor.

BRAM_SP_mn  #(
                .pBRAM_AddrWidth(pROM_AddrWidth),
                .pBRAM_Width(pROM_Width),
                .pBRAM_SP_mn_Init(pROM_Init)
            ) uPgm (
                .Clk(Clk),
                
                .WP(1'b1),
                
                .CE(CE_uPgm), 
                .WE(1'b0), 
                .PA(uPgm_A), 
                .DI({pROM_Width{1'b0}}), 
                .DO(uPgm_D)
            );

BRAM_SP_mn  #(
                .pBRAM_AddrWidth(pDEC_AddrWidth),
                .pBRAM_Width(pDEC_Width),
                .pBRAM_SP_mn_Init(pDEC_Init)
            ) IDEC (
                .Clk(Clk),
                
                .WP(1'b1),
                
                .CE(CE_IDEC), 
                .WE(1'b0), 
                .PA(IDEC_A), 
                .DI({pDEC_Width{1'b0}}), 
                .DO(IDEC_D)
            );

//  Decode Core 0 Microcycle States

assign C2 = (MC == 7);      // 2nd cycle of microcycle
assign C3 = (MC == 5);      // 3rd cycle of microcycle
assign C7 = (MC == 1);      // 7th cycle of microcycle (Wait State Sequence)

assign Wr = (WE & (C3 | C7) & ~Wait);

reg     Rd;
always  @(posedge Clk) Rd <= #1 ((Rst) ? 0 : RE & (C3 | C7) & ~Wait); 

//  Instantiate 16384 x 8 Single-Port Block RAM - RAM_A

wire    [(pBus_Width - 1):0] RAM_A_DO;

BRAM_SP_mn  #(
                .pBRAM_AddrWidth(pRAM_A_AddrWidth),
                .pBRAM_Width(pBus_Width),
                .pBRAM_SP_mn_Init(pRAM_A_Init)
            ) RAM_A (
                .Clk(Clk),
                
                .WP(1'b0),
                
                .CE(CE[0]), 
                .WE(Wr), 
                .PA(PA[(pRAM_A_AddrWidth - 1):0]), 
                .DI(DO), 
                .DO(RAM_A_DO)
            );

assign DI = ((CE[0] & (C3 | C7) & ~Wait) ? RAM_A_DO : 0);

//  Instantiate 8192 x 8 Single-Port Block RAM - RAM_B

wire    [(pBus_Width - 1):0] RAM_B_DO;

BRAM_SP_mn  #(
                .pBRAM_AddrWidth(pRAM_B_AddrWidth),
                .pBRAM_Width(pBus_Width),
                .pBRAM_SP_mn_Init(pRAM_B_Init)
            ) RAM_B (
                .Clk(Clk),
                
                .WP(1'b0),
                
                .CE(CE[1]), 
                .WE(Wr), 
                .PA(PA[(pRAM_B_AddrWidth - 1):0]), 
                .DI(DO), 
                .DO(RAM_B_DO)
            );

assign DI = ((CE[1] & (C3 | C7) & ~Wait) ? RAM_B_DO : 0);

//  Instantiate 2048 x 8 Single-Port Block RAM - ROM

wire    [(pBus_Width - 1):0] ROM_DO;

BRAM_SP_mn  #(
                .pBRAM_AddrWidth(pMON_AddrWidth),
                .pBRAM_Width(pBus_Width),
                .pBRAM_SP_mn_Init(pMON_Init)
            ) ROM (
                .Clk(Clk),
                
                .WP(WP),
                
                .CE(CE[7] & PA[pMON_AddrWidth]), 
                .WE(Wr), 
                .PA(PA[(pMON_AddrWidth - 1):0]), 
                .DI(DO), 
                .DO(ROM_DO)
            );

assign DI = ((CE[7] & (C3 | C7) & ~Wait) ? ROM_DO : 0);

////////////////////////////////////////////////////////////////////////////////
//
//  I/O Peripherals
//
////////////////////////////////////////////////////////////////////////////////

//  UART #0

wire    COM_A_CE = (CE[7] & (PA[11:4] == 8'b0000_0000));
wire    [(pBus_Width - 1):0] COM_A_DO;
wire    xRTS_A, xCTS_A;

UART    #(
            .pFrequency(pFrequency),
            .pDefault_LCR(pDefault_LCR_A),
            .pDefault_IER(pDefault_IER_A),
            .pBaudrate(pBaudrate_A),
            .pRTOChrDlyCnt(pRTOChrDlyCnt_A),
            .pTF_Depth(pTF_Depth_A),
            .pRF_Depth(pRF_Depth_A),
            .pTF_Init(pTF_Init_A),
            .pRF_Init(pRF_Init_A)
        ) COM_A (
            .Rst(Rst), 
            .Clk(Clk),
            
            .IRQ(COM_A_IRQ),
            
            .Sel(COM_A_CE), 
            .Reg(PA[1:0]), 
            .RE(Rd), 
            .WE(Wr), 
            .DI(DO), 
            .DO(COM_A_DO),
            
            .TxD_232(TxD_RS232_A), 
            .RxD_232(RxD_RS232_A), 
            .xRTS(xRTS_A), 
            .xCTS(xCTS_A),
            
            .TxD_485(TxD_RS485_A), 
            .RxD_485(RxD_RS485_A), 
            .xDE(DE_RS485_A), 

            .TxIdle(), 
            .RxIdle()
        );

assign nRTS_RS232_A = ~xRTS_A;        
assign xCTS_A       = ~nCTS_RS232_A;        
        
assign IRQ = ((COM_A_IRQ) ? 1 : 0);
assign DI  = ((COM_A_CE & (C3 | C7) & ~Wait) ? COM_A_DO : 0);       

//  UART #1 Peripheral

wire    COM_B_CE = (CE[7] & (PA[11:4] == 8'b0000_0001));
wire    [(pBus_Width - 1):0] COM_B_DO;
wire    xRTS_B, xCTS_B;

UART    #(
            .pFrequency(pFrequency),
            .pDefault_LCR(pDefault_LCR_B),
            .pDefault_IER(pDefault_IER_B),
            .pBaudrate(pBaudrate_B),
            .pRTOChrDlyCnt(pRTOChrDlyCnt_B),
            .pTF_Depth(pTF_Depth_B),
            .pRF_Depth(pRF_Depth_B),
            .pTF_Init(pTF_Init_B),
            .pRF_Init(pRF_Init_B)
        ) COM_B (
            .Rst(Rst), 
            .Clk(Clk),
            
            .IRQ(COM_B_IRQ),
            
            .Sel(COM_B_CE), 
            .Reg(PA[1:0]), 
            .RE(Rd), 
            .WE(Wr), 
            .DI(DO), 
            .DO(COM_B_DO),
            
            .TxD_232(TxD_RS232_B), 
            .RxD_232(RxD_RS232_B), 
            .xRTS(xRTS_B), 
            .xCTS(xCTS_B),
            
            .TxD_485(TxD_RS485_B), 
            .RxD_485(RxD_RS485_B), 
            .xDE(DE_RS485_B), 

            .TxIdle(), 
            .RxIdle()
        );

assign nRTS_RS232_B = ~xRTS_B;
assign xCTS_B       = ~nCTS_RS232_B;
        
assign IRQ = ((COM_B_IRQ) ? 1 : 0);
assign DI  = ((COM_B_CE & (C3 | C7) & ~Wait) ? COM_B_DO : 0);       

//  SPI Master Interface
        
wire    SPI_IRQ;
wire    SPI_CE = (CE[7] & (PA[11:4] == 8'b0111_1111));
wire    [(pBus_Width - 1):0] SPI_A_DO;
wire    [1:0] SSel;

M65C02_SPIxIF   #(
                    .pDefault_CR(pDefault_CR),
                    .pSPI_FIFO_Depth(pSPI_FIFO_Depth),
                    .pSPI_FIFO_Init(pSPI_FIFO_Init)
                ) SPI (
                    .Rst(Rst), 
                    .Clk(Clk),
                    
                    .IRQ(SPI_IRQ), 

                    .Sel(SPI_CE), 
                    .RE(Rd), 
                    .WE(Wr), 
                    .Reg(PA[1:0]), 
                    .DI(DO), 
                    .DO(SPI_A_DO), 
                    
                    .SSel(SSel), 
                    .SCK(SCK), 
                    .MOSI(MOSI), 
                    .MISO(MISO)
                );

assign nCSO = ~SSel;

assign IRQ = ((SPI_IRQ) ? 1 : 0);
assign DI  = ((SPI_CE & (C3 | C7) & ~Wait) ? SPI_A_DO : 0);       


////////////////////////////////////////////////////////////////////////////////
//
//  End of Implementation
//
////////////////////////////////////////////////////////////////////////////////

endmodule
