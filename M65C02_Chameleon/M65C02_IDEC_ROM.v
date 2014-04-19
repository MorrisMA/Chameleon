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
// Create Date:     13:56:13 12/23/2013 
// Design Name:     M65C02 Dual Core 
// Module Name:     M65C02_uPgm_ROM 
// Project Name:    C:\XProjects\ISE10.1i\M65C02Duo 
// Target Devices:  Generic SRAM-based FPGA 
// Tool versions:   Xilinx ISE10.1i SP3
//
// Description:
//
//  This module provides a parameterized dual-ported block RAM implementation of
//  the microprogram ROM of the M65C02 soft-core microprocessor. It's primary
//  purpose is to provide a single block RAM module that can be simultaneously
//  accessed by either processor core of the M65C02Duo. Parameterization allows
//  the module to be configured to support either the fixed or the variable
//  microprogram ROMs required. The default parameters support the variable
//  microprogram ROM.
//
// Dependencies:    None
//
// Revision: 
//
//  0.00    13L23   MAM     Initial File Creation
//
//  0.10    13L24   MAM     Added separate reset signals for each port.
//
// Additional Comments: 
//
////////////////////////////////////////////////////////////////////////////////

module M65C02_IDEC_ROM #(
    parameter pROM_AddrWidth = 8'd8,
    parameter pROM_Width     = 8'd36,
    parameter pROM_Init      = "Src/M65C02_IDEC_v2.coe"
)(
    input   Clk,
    input   Clk90,
    
    // Core 0 Interface (A Side)
    
    input   Rst_A,
    
    input   En_A,
    input   [(pROM_AddrWidth - 1):0] Addr_A,
    output  reg [(pROM_Width - 1):0] DO_A,

    // Core 1 Interface (B Side)
    
    input   Rst_B,
    
    input   En_B,
    input   [(pROM_AddrWidth - 1):0] Addr_B,
    output  reg [(pROM_Width - 1):0] DO_B
);

////////////////////////////////////////////////////////////////////////////////
//
//  Local Parameters
//

localparam  pROM_Depth = (2**pROM_AddrWidth);

////////////////////////////////////////////////////////////////////////////////
//
//  Implementation
//

`ifdef Sim_ROM

reg     [(pROM_Width - 1):0] ROM [(pROM_Depth - 1):0];
reg     [(pROM_Width - 1):0] ROM_DO_A, ROM_DO_B;

initial
    $readmemb(pROM_Init, ROM, 0, (pROM_Depth - 1));

always @(negedge Clk90)
begin
    if(En_A | Rst_A)                    //  Port A
        ROM_DO_A <= #1 ROM[Addr_A];

    if(En_B | Rst_B)                    //  Port B
        ROM_DO_B <= #1 ROM[Addr_B];
end

`else

wire    [(pROM_Width - 1):0] ROM_DO_A, ROM_DO_B;

DPBR_ROM_256x36 ROM (
                    .clka(~Clk90),

                    .ena(Rst_A | En_A),
                    .addra(Addr_A),             // Bus [ 7:0] 
                    .douta(ROM_DO_A),           // Bus [35:0]
                    
                    .clkb(~Clk90),

                    .enb(Rst_B | En_B),
                    .addrb(Addr_B),             // Bus [ 7:0] 
                    .doutb(ROM_DO_B)            // Bus [35:0]
                );


`endif

always @(posedge Clk) DO_A <= #1 ROM_DO_A;
always @(posedge Clk) DO_B <= #1 ROM_DO_B;

endmodule
