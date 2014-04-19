////////////////////////////////////////////////////////////////////////////////
//
//  Copyright 2013 by Michael A. Morris, dba M. A. Morris & Associates
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
// Create Date:     12:06:18 08/18/2013 
// Design Name:     WDC W65C02 Microprocessor Re-Implementation
// Module Name:     M65C02_IntHndlr.v 
// Project Name:    C:\XProjects\ISE10.1i\M65C02Duo 
// Target Devices:  SRAM-based FPGAs: XC3S50A-xVQ100I, XC3S200A-xVQ100I 
// Tool versions:   Xilinx ISE 10.1i SP3
// 
// Description: 
//
//  This module implements a simple interrupt handler for the M65C02 soft-core
//  microprocessor. It accepts external active low inputs for Non-Maskable
//  Interrupt request (nNMI) and maskable Interrupt ReQuest (nIRQ). It synchro-
//  nizes both inputs to the internal system clock (Clk), and generates internal
//  signals NMI and IRQ. NMI is falling edge sensitive, and IRQ is active low
//  level sensitive. The module also accepts the core's mode output (Mode) and
//  generates an internal BReaK software trap request (BRK).
//
//  The non-maskable interrupt request, nNMI, has priority, followed by BRK, and
//  finally nIRQ. The core, from the I bit in the processor register, provides a
//  mask that prevents the generation of the internal IRQ signal.
//
//  Vectors for each of the four interrupt/trap sources are set using para-
//  meters. The current implementation aims to maintain compatibility with the
//  WDC W65C02S processor, so IRQ and BRK share the same vector. A quick edit
//  of the parameters allows an independent vector location to be added for BRK.
//  Similarly, the vectors for any of the interrupt/trap sources can be moved
//  to any location in the memory space, if W65C02S compatibility is not desired
//  or required.
//
// Dependencies:    redet.v 
//
// Revision:
//
//  0.01    13H18   MAM     File Created
//
//  1.00    13L22   MAM     Modified for the M65C02Duo CPU.
// 
// Additional Comments: 
//
///////////////////////////////////////////////////////////////////////////////

module M65C02_IntHndlr #(
    parameter pIRQ_Vector = 16'hFFFE,
    parameter pBRK_Vector = 16'hFFFE,
    parameter pRST_Vector = 16'hFFFC,
    parameter pNMI_Vector = 16'hFFFA
)(
    input   Rst,
    input   Clk,
    
    input   NMI,
    input   IRQ,
    input   BRK,
    
    input   IRQ_Msk,
    input   IntSvc,
    
    output  reg Int,
    output  reg [15:0] Vector
);

////////////////////////////////////////////////////////////////////////////////
//
//  Local Declarations
//

wire    RE_NMI;
wire    CE_NMI;
reg     rNMI;

//  Perform falling edge detection on the external non-maskable interrupt input

redet   RE1 (
            .rst(Rst), 
            .clk(Clk), 
            .din(NMI), 
            .pls(RE_NMI)
        );

//  Capture and hold the rising edge pulse for NMI in NMI FF until serviced by
//      the processor.

assign CE_NMI = (Rst | IntSvc | RE_NMI);
always @(posedge Clk) rNMI <= #1 ((CE_NMI) ? RE_NMI : 0);

//  Generate Internal INT signal and Interrupt Vector

always @(posedge Clk or posedge Rst)
begin
    if(Rst) begin
        Int    <= #1 0;
        Vector <= #1 pRST_Vector;
    end else begin
        Int    <= #1 (rNMI | (~IRQ_Msk & IRQ));
        Vector <= #1 ((Int) ? ((rNMI) ? pNMI_Vector
                                      : pIRQ_Vector)
                            : ((BRK ) ? pBRK_Vector
                                      : pRST_Vector));
    end
end
                       
endmodule
