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
// Create Date:     09:39:42 12/21/2013 
// Design Name:     WDC W65C02 Microprocessor Re-Implementation
// Module Name:     M65C02_MMU 
// Project Name:    C:\XProjects\ISE10.1i\M65C02Duo 
// Target Devices:  Generic SRAM-based FPGA 
// Tool versions:   Xilinx ISE10.1i SP3
//
// Description:
//
//  This module implements a simple memory management unit for the M65C02 soft-
//  core microprocessor. It uses dual-ported distributed memory to map a virtual
//  address to a physical address and a chip enable. The uppermost 4 bits of the
//  16-bit M65C02 virtual address is used to address a set of 16 memory mapping
//  registers.
//
//  The outputs of these registers provide the minimum number of wait states re-
//  quired for each mapped memory segment, the chip enable for the memory block
//  to which the segment is mapped, and the uppermost 8 address values. This or-
//  ganization provides a means by which any 4kB memory segment can be mapped to
//  any defined memory or IO device space. The loading of the mapping ROM of the
//  MMU is performed using a single write cycle, which is performed by specify-
//  ing a custom instruction taken from the unused opcode space of the M65C02.
//  
//  This special instruction, MMU, provides a write strobe which simultaneously
//  writes the contents of the A, X and Y processor registers into the various
//  fields of the addressed memory management unit register. The address of the
//  memory management unit register is provided by the most significant 4 bits
//  of the A register. The least significant 4 bits of the A register define the
//  desired number of default wait states for each mapped memory or IO segment.
//  The X register provide the desired one-hot chip enables for the memory and
//  IO blocks attached to the M65C02. The Y register provides value to be driven
//  onto the upper 8 bits of the memory address bus.
//
//  This MMU only provides simple address substitution and chip select genera-
//  tion. Address arithmetic and range checking could be added, but the addi-
//  tional logic in the critical address output data path will result in lower
//  performance.
//
// Dependencies:    None 
//
// Revision: 
//
//  0.00    13L21   MAM     Initial File Creation
//
// Additional Comments: 
//
////////////////////////////////////////////////////////////////////////////////

module M65C02_MMU #(
    parameter pMMU_Init = "Src/M65C02_MMU.coe"  // MMU Initialization File
)(
    input   Clk,                        // System Clock
    
    input   WE,                         // MMU Write Enable 
    input   [ 3:0] Sel,                 // MMU Map Register Select
    input   [19:0] DI,                  // MMU Map Data Input
    output  [19:0] DO,                  // MMU Map Data Output            

    input   [15:0] VA,                  // MMU Virtual Address Input

    output  [ 3:0] Dly,                 // MMU Memory Segment Wait State
    output  [ 7:0] CE,                  // MMU Chip Enable Output
    output  [19:0] PA                   // MMU Physical (Mapped) Address Output
);

////////////////////////////////////////////////////////////////////////////////
//
//  Declarations
//

reg     [19:0] MMU_RAM [15:0];
wire    [ 3:0] RSel;

////////////////////////////////////////////////////////////////////////////////
//
//  Implementation
//

//  Implement Dual-Ported Distributed RAM for MMU RAM

initial
    $readmemh(pMMU_Init, MMU_RAM, 0, 15);

always @(posedge Clk)
begin
    if(WE)
        MMU_RAM[Sel] <= #1 DI;
end

assign DO = MMU_RAM[Sel];               // Read MMU RAM

// Map Virtual Address into Wait State, Chip Enable, and Physical Address

assign RSel = VA[15:12];
assign {Dly, CE, PA} = {MMU_RAM[RSel], VA[11:0]};

endmodule
