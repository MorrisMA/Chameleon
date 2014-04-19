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
// Create Date:     10:06:21 12/22/2013 
// Design Name:     M65C02 Dual Core 
// Module Name:     M65C02_CPU
// Project Name:    C:\XProjects\ISE10.1i\M65C02Duo 
// Target Devices:  Generic SRAM-based FPGA 
// Tool versions:   Xilinx ISE10.1i SP3
//
// Description:     (See additional comments section below)
//
// Dependencies:    M65C02_MPCv4.v
//                      M65C02_uPgm_V3a.coe (M65C02_uPgm_V3a.txt)
//                      M65C02_Decoder_ROM.coe (M65C02_Decoder_ROM.txt)
//                  M65C02_ALU.v
//                      M65C02_Bin.v
//                      M65C02_BCD.v 
//
// Revision: 
//
//  0.00    13L22   MAM     Initial File Creation. Copied from M65C02_Core.
//                          Modified to incorporate interrupt handler and MMU
//                          modules. Removed the microprogram memories, and made
//                          external modules which are shared between the two
//                          cores.
//
// Additional Comments:
//
////////////////////////////////////////////////////////////////////////////////

module M65C02_CPU #(
    parameter pIRQ_Vector    = 16'hFFFE,        // Maskable Interrupt Vector
    parameter pBRK_Vector    = 16'hFFFE,        // BRK Instruction Trap Vector
    parameter pRST_Vector    = 16'hFFFC,        // Reset Vector
    parameter pNMI_Vector    = 16'hFFFA,        // Non-Maskable Interrupt Vector

    parameter pStkPtr_Rst    = 8'hFF,           // Stk Ptr Value after Reset
    parameter pInt_Hndlr     = 0,               // _Int microroutine address

    parameter pROM_AddrWidth = 8'd9,            // Var. uPgm ROM Addrs Width
    parameter pROM_Width     = 8'd36,           // Var. uPgm ROM Data Width
    parameter pDEC_AddrWidth = 8'd8,            // Fix. uPgm ROM Addrs Width
    parameter pDEC_Width     = 8'd36,           // Fix. uPgm ROM Data Width

    parameter pMMU_Init = "Src/M65C02_MMU.coe"  // MMU Initialization File
)(
    input   Rst,            // System Reset Input
    input   Clk,            // System Clock Input
    
    //  Processor Core Memory Controller Interface
    
    output  [2:0] MC,       // Microcycle State
    output  Rdy,            // Operands Ready

    //  Processor Core Interrupt Interface
    
    input   NMI,            // External Non-Maskable Interrupt Request
    input   IRQ,            // External Maskable Interrupt Request
    output  reg VP,         // Interrupt Vector Pull Start Flag
    
    output  reg WAI,        // Wait For Interrupt Flag
    output  reg STP,        // Processor Stopped

    //  Processor Core Memory Cycle Interface    
    
    output  reg Fetch,      // Instruction Fetch/Complete
    output  reg ML,         // Memory Lock - Read-Modify-Write Operation

    output  reg [ 7:0] CE,  // Chip Enables
    output  reg RE,         // Memory Read Enable
    output  reg WE,         // Memory Write Enable
    
    output  IntWait,        // Internal Wait State Generator Output
    input   Wait,           // Wait Input

    output  reg [19:0] PA,  // External Physical Address
    output  reg [ 7:0] DO,  // External Data Out
    input   [7:0] DI,       // External Data In
 
    //  Microprogram Memory Interface
    
    output  En_uPL,
    output  [(pROM_AddrWidth - 1):0] A_uPL,
    input   [(pROM_Width - 1):0] uPL,
    
    output  En_IDEC,
    output  [(pDEC_AddrWidth - 1):0] A_IDEC,
    input   [(pDEC_Width - 1):0] IDEC
);

////////////////////////////////////////////////////////////////////////////////
//
// Local Parameter Declarations
//

localparam  pBA_Fill = (pROM_AddrWidth - pDEC_AddrWidth);

localparam  pBRV1    = 2'b01;   // MPC Via[1:0] code for BRV1 instruction
localparam  pBRV2    = 2'b10;   // MPC Via[1:0] code for BRV2 instruction
localparam  pBRV3    = 2'b11;   // MPC Via[1:0] code for BRV3 instruction
localparam  pBMW     = 4'b0011; // MPC I[3:0] code for BMW instruction

localparam  pNOP     = 8'hAE;   // NOP opcode

localparam  pPC_Pls  = 2'b01;   // PC Increment
localparam  pPC_Jmp  = 2'b10;   // PC Absolute Jump
localparam  pPC_Rel  = 2'b11;   // PC Conditional Branch

localparam  pIO_IF   = 2'b11;   // Instruction Fetch
localparam  pIO_RD   = 2'b10;   // Memory Read
localparam  pIO_WR   = 2'b01;   // Memory Write

localparam  pDO_ALU  = 2'b00;   // DO    <= ALU_Out
localparam  pDO_PCH  = 2'b01;   // DO    <= PC[15:8]
localparam  pDO_PCL  = 2'b10;   // DO    <= PC[ 7:0]
localparam  pDO_PSW  = 2'b11;   // DO    <= P (also available on ALU_Out)
//
localparam  pDI_Mem  = 2'b00;   // ALU_M <= DI
localparam  pDI_OP2  = 2'b01;   // OP2   <= DI
localparam  pDI_OP1  = 2'b10;   // OP1   <= DI
localparam  pDI_IR   = 2'b11;   // IR    <= DI

localparam  pStk_Psh = 2'b10;   // StkPtr <= S;
localparam  pStk_Pop = 2'b11;   // StkPtr <= S + 1;

localparam  pNA_Nxt  = 4'h1;    // NA <= MAR + 1
localparam  pNA_PSH  = 4'h2;    // NA <= SP + 0
localparam  pNA_POP  = 4'h3;    // NA <= SP + 1
localparam  pNA_MAR  = 4'h4;    // NA <= MAR + 0
localparam  pNA_DPN  = 4'h5;    // NA <= {0, OP1} + 0
localparam  pNA_DPX  = 4'h6;    // NA <= {0, OP1} + {0, X}
localparam  pNA_DPY  = 4'h7;    // NA <= {0, OP1} + {0, Y}
localparam  pNA_VPL  = 4'h8;    // NA <= {OP2, OP1} + 0
localparam  pNA_VPH  = 4'h9;    // NA <= MAR + 1
localparam  pNA_SR0  = 4'hA;    // NA <= SP + OP1 + 0
localparam  pNA_SR1  = 4'hB;    // NA <= SP + OP1 + 1
//
localparam  pNA_LDA  = 4'hD;    // NA <= {OP2, OP1} + 0
localparam  pNA_LDAX = 4'hE;    // NA <= {OP2, OP1} + {0, X}
localparam  pNA_LDAY = 4'hF;    // NA <= {OP2, OP1} + {0, Y}

localparam  pWAI     = 3'b111;  // Mode field encoding for WAI instruction
localparam  pSTP     = 3'b110;  // Mode field encoding for STP instruction
localparam  pBRK     = 3'b101;  // Mode field encoding for BRK instruction
localparam  pMMU     = 3'b100;  // Mode field encoding for MMU instruction
localparam  pXCE     = 3'b011;  // Mode field encoding for XCE instruction
localparam  pCOP     = 3'b010;  // Mode field encoding for COP instruction
localparam  pVAL     = 3'b001;  // Mode field encoding for otherwise valid inst.

localparam  pIntMsk  = 2;       // Bit number of Interrupt mask bit in P

////////////////////////////////////////////////////////////////////////////////
//
// Local Signal Declarations
//

wire    BRV2;                       // MPC BRV2 Instruction Decode
wire    BRV3;                       // MPC BRV3 Instruction Decode
wire    BMW;                        // MPC BMW Instruction Decode

wire    [3:0] I;                        // MPC Instruction Input
wire    [3:0] T;                        // MPC Test Inputs
wire    [2:0] MW;                       // MPC Multi-way Branch Select
reg     [(pROM_AddrWidth - 1):0] BA;    // MPC Branch Address Input
wire    [1:0] Via;                      // MPC Via Mux Control Output
wire    [(pROM_AddrWidth - 1):0] MA;    // MPC uP ROM Address Output
//
wire    [(pROM_AddrWidth - 1):0] uP_BA; // uP Branch Address Field
wire    ZP;                             // Zero Page Addressing Control Field
wire    [3:0] NA_Op;                    // Memory Address Register Control Fld
wire    [1:0] PC_Op;                    // Program Counter Control Field
//
wire    iRE;                        // Memory Interface Read Enable
wire    iWE;                        // Memory Interface Write Enable
//
wire    OE_PSW;                     // Output Enable PSW
wire    OE_dPCH;                    // Output Enable Delayed PCH
wire    OE_dPCL;                    // Output Enable Delayed PCL
wire    OE_PCH;                     // Output Enable PCH
wire    OE_PCL;                     // Output Enable PCL
wire    OE_ALU;                     // Output Enable ALU Out
//
wire    En_OP2;                     // Enable Operand Register 2
wire    En_OP1;                     // Enable Operand Register 1
//
wire    [1:0] Stk_Op;               // Stack Pointer Control Field
wire    [2:0] Reg_WE;               // Register Write Enable Control Field

wire    En;                         // ALU Enable Control Field

//  Instruction Decoder (Fixed) Output

wire    iWAI;                       // M65C02 WAI Instruction
wire    iSTP;                       // M65C02 STP Instruction            
wire    iBRK;                       // M65C02 BRK Instruction
wire    iMMU;                       // M65C02 MMU Instruction
wire    iXCE;                       // M65C02 XCE Instruction
wire    iCOP;                       // M65C02 COP Instruction
wire    iVAL;                       // M65C02 Valid Instruction
//
wire    [5:0] FU_Sel;               // M65C02 ALU Functional Unit Select Field
wire    [1:0] Op;                   // M65C02 ALU Operation Select Field
wire    [1:0] QSel;                 // M65C02 ALU Q Operand Select Field
wire    [1:0] RSel;                 // M65C02 ALU R Operand Select Field
wire    [1:0] CSel;                 // M65C02 ALU Adder Carry In Select Field
wire    [2:0] WSel;                 // M65C02 ALU Register Write Select Field
wire    [2:0] OSel;                 // M65C02 ALU Output Select Field
wire    [3:0] CCSel;                // M65C02 ALU Condition Code Control Field
wire    [7:0] Opcode;               // M65C02 Rockwell Instruction Mask Field
//  
wire    [7:0] Out;                  // M65C02 ALU Data Output Bus
wire    Valid;                      // M65C02 ALU Output Valid Signal

wire    CC;                         // ALU Condition Code Output

wire    SelS;                       // M65C02 Stack Pointer Select
wire    [7:0] S;                    // M65C02 Stack Pointer Register

wire    [15:0] PC;                  // M65C02 Program Counter
wire    [15:0] dPC;                 // Pipeline Compensation Register for PC

wire    Ld_OP1, Ld_OP2;             // Load Strobes for Operand Registers
reg     [7:0] OP1, OP2;             // Operand Registers

wire    [15:0] VA;                  // Virtual Address from Address Gen.

wire    Int;                        // Combined Interrupt Request
wire    [15:0] Vector;              // Interrupt Vector

wire    CE_IntSvc;                  // Clock Enable Interrupt Service FF
reg     IntSvc;                     // Interrupt Service FF

wire    [7:0] A, X, Y, P;           // Processor Core ALU Registers

wire    IRQ_Msk;                    // PSW Interrupt Mask Bit

wor     [ 7:0] iDO;
reg     [ 7:0] iDI;
reg     [ 3:0] WSGen;
wire    [ 3:0] Dly;
wire    [ 7:0] iCE;
wire    [19:0] iPA;

////////////////////////////////////////////////////////////////////////////////
//
//  Start Implementation
//
////////////////////////////////////////////////////////////////////////////////

//  Define Microcycle and Instruction Cycle Status Signals

assign iFetch = (|Via);         // Instruction Complete (1) - ~BRV0
assign Rdy    = (MC == 4);      // Microcycle Complete Signal

assign C1 = (MC == 6);          // 1st cycle of microcycle
assign C3 = (MC == 5);          // 3rd cycle of microcycle
assign C7 = (MC == 1);          // 7th cycle of microcycle (Wait State Sequence)

////////////////////////////////////////////////////////////////////////////////
//
//  Microprogram Controller Interface
//
//  Decode MPC Instructions being used for strobes

assign BRV2 = (Via == pBRV2);
assign BRV3 = (Via == pBRV3);
assign BMW  = (I   == pBMW ); 

//  Define the Multi-Way Input Signals
//      Implement a 4-way branch when executing WAI, and a 2-way otherwise

assign MW = ((iWAI) ? {uP_BA[2], IRQ, Int} : {uP_BA[2:1], Int});

//  Implement the Branch Address Field Multiplexer for Instruction Decode

always @(*)
begin
    case(Via)
        pBRV1   : BA <= {{pBA_Fill{1'b1}}, iDI[3:0], iDI[7:4]};
        pBRV3   : BA <= ((Int) ? pInt_Hndlr
                               : {{pBA_Fill{1'b1}}, iDI[3:0], iDI[7:4]});
        default : BA <= uP_BA;
    endcase
end

//  Assign Test Input Signals

assign T = {3'b000, Valid};

//  Instantiate Microprogram Controller/Sequencer - modified F9408A MPC

M65C02_MPCv4    #(
                    .pAddrWidth(pROM_AddrWidth)
                ) MPCv4 (
                    .Rst(Rst), 
                    .Clk(Clk),
                    
                    .MC(MC),                // Microcycle State
                    .Wait(iWait),           // Microcycle Wait state request

                    .I(I),                  // Instruction 
                    .T(T),                  // Test signal input
                    .MW(MW),                // Multi-way branch inputs
                    .BA(BA),                // Branch address input
                    .Via(Via),              // BRVx multiplexer control output

                    .MA(MA)                 // Microprogram ROM address output
                );
                
//  Define Enable and Address for uPL ROM

assign En_uPL = Rdy;
assign A_uPL  = MA;

//  Assign uPL fields

assign I       = uPL[35:32];    // MPC Instruction Field (4)
assign uP_BA   = uPL[31:23];    // MPC Branch Address Field (9)
assign ZP      = uPL[   22];    // When Set, ZP % 256 addressing required (1)
assign NA_Op   = uPL[21:18];    // Next Address Operation (4)
assign PC_Op   = uPL[17:16];    // Program Counter Control (2)
assign iRE     = uPL[15];       // Memory Read Eanble
assign iWE     = uPL[14];       // Memory Write Enable
assign OE_PSW  = uPL[13];       // Output Enable PSW
assign OE_dPCH = uPL[12];       // Output Enable Delayed PCH
assign OE_dPCL = uPL[11];       // Output Enable Delayed PCL
assign OE_PCH  = uPL[10];       // Output Enable PCH
assign OE_PCL  = uPL[ 9];       // Output Enable PCL
assign OE_ALU  = uPL[ 8];       // Output Enable ALU Out
assign En_OP2  = uPL[ 7];       // Enable Operand Register 2
assign En_OP1  = uPL[ 6];       // Enable Operand Register 1
//
assign Stk_Op  = uPL[ 5: 4];    // Stack Pointer Control Field (2)
assign Reg_WE  = uPL[ 3: 1];    // Register Write Enable Field (3)
assign ISR     = uPL[ 0];       // Set to clear D and set I on interrupts (1)

//  Operand Register 1

assign Ld_OP1 = iRE & En_OP1 & Rdy;

always @(posedge Clk)
begin
    if(Rst)
        OP1 <= #1 0;
    else if(BRV2)
        OP1 <= #1 Vector[7:0];
    else if(Ld_OP1)
        OP1 <= #1 iDI;   // Load OP1 from DI
end

//  Operand Register 2

assign Ld_OP2 = iRE & En_OP2 & Rdy;

always @(posedge Clk)
begin
    if(Rst)
        OP2 <= #1 0;
    else if(BRV2)
        OP2 <= #1 Vector[15:8];
    else if(Ld_OP2)
        OP2 <= #1 iDI;   // Load OP2 from DI
end

//  Define Enable and Address for Instruction Decode ROM
//      M65C02_IDEC_v3.txt implements the M65C02_ALUv2 instruction decoder with
//      a table constructed using reversed nibbles like the variable micropro-
//      gram ROM, M65C02_uPgm_V3b.txt.

assign  En_IDEC = iFetch & Ld_OP2 | Rst;
assign  A_IDEC  = ((Rst) ? pNOP : {iDI[3:0], iDI[7:4]});
//assign  A_IDEC  = ((Rst) ? {1'b0, pNOP} : {Ld_OP1, iDI[3:0], iDI[7:4]});

//  Decode Fixed Microcode Word

assign  iWAI   = (IDEC[35:33] == pWAI); // M65C02 WAI Instruction            
assign  iSTP   = (IDEC[35:33] == pSTP); // M65C02 STP Instruction
assign  iBRK   = (IDEC[35:33] == pBRK); // M65C02 BRK Instruction
assign  iMMU   = (IDEC[35:33] == pMMU); // M65C02 MMU Instruction
assign  iXCE   = (IDEC[35:33] == pXCE); // M65C02 XCE Instruction
assign  iCOP   = (IDEC[35:33] == pCOP); // M65C02 COP Instruction
assign  iVAL   = |IDEC[35:33];          // M65C02 Valid Instruction
//
assign  iML    = IDEC[32];          // M65C02 Read-Modify-Write Instruction
//
assign  FU_Sel = IDEC[31:26];       // M65C02 ALU Functional Unit Select Field
assign  Op     = IDEC[25:24];       // M65C02 ALU Operation Select Field
assign  QSel   = IDEC[23:22];       // M65C02 ALU AU Q Bus Mux Select Field
assign  RSel   = IDEC[21:20];       // M65C02 ALU AU/SU R Bus Mux Select Field
assign  CSel   = IDEC[19:18];       // M65C02 ALU AU/SU Carry Mux Select Field
assign  WSel   = IDEC[17:15];       // M65C02 ALU Register Write Select Field
assign  OSel   = IDEC[14:12];       // M65C02 ALU Register Output Select Field
assign  CCSel  = IDEC[11: 8];       // M65C02 ALU Condition Code Control Field
assign  Opcode = IDEC[ 7: 0];       // M65C02 Valid Opcode Control Field

//  Next Address Generator

M65C02_AddrGen  AddrGen (
                    .Rst(Rst), 
                    .Clk(Clk),
                    
                    .Vector(Vector), 

                    .NA_Op(NA_Op),
                    .PC_Op(PC_Op),
                    .Stk_Op(Stk_Op),
                    
                    .ZP(ZP),

                    .CC(CC), 
                    .BRV3(BRV3), 
                    .Int(Int), 

                    .Rdy(Rdy),
                    .Valid(Valid),

                    .DI(iDI), 
                    .OP1(OP1), 
                    .OP2(OP2), 
                    .X(X), 
                    .Y(Y), 

                    .VP(iVP),
                    .AO(VA), 

                    .AL(),
                    .AR(),
                    .NA(), 
                    .MAR(), 

                    .SelS(SelS),
                    .S(S),
                        
                    .PC(PC), 
                    .dPC(dPC)
                );
                
//  Instantiate the M65C02 Memory Management Unit (MMU) Module

M65C02_MMU  #(
                .pMMU_Init(pMMU_Init)
            ) Mapper (
                .Clk(Clk),
                
                .WE((iMMU & Rdy)), 
                
                .Sel(A[7:4]), 
                .DI({A[3:0], X, Y}), 
                .DO(), 
                
                .VA(VA), 

                .Dly(Dly), 
                .CE(iCE), 
                .PA(iPA)
            );

//  Interrupt Service Flag

assign CE_IntSvc = ((Int & (BRV3 | BMW)) | (iWE & OE_PSW));

always @(posedge Clk)
begin
    if(Rst)
        IntSvc <= #1 0;
    else if(CE_IntSvc)
        IntSvc <= #1 (Int & (BRV3 | BMW));
end

//  Instantiate the M65C02 Interrupt Handler Module

M65C02_IntHndlr #(
                    .pIRQ_Vector(pIRQ_Vector),
                    .pBRK_Vector(pBRK_Vector),
                    .pRST_Vector(pRST_Vector),
                    .pNMI_Vector(pNMI_Vector)
                ) IntHndlr (
                    .Rst(Rst), 
                    .Clk(Clk),
                    
                    .NMI(NMI), 
                    .IRQ(IRQ), 
                    .BRK(iBRK), 

                    .IRQ_Msk(P[pIntMsk]),           // Interrupt Mask Bit 
                    .IntSvc(IntSvc), 

                    .Int(Int), 
                    .Vector(Vector)
                );

//  Instantiate the M65C02 ALU (Version 2) Module

assign En = (|Reg_WE);

M65C02_ALUv2    ALU (
                    .Rst(Rst),          // System Reset
                    .Clk(Clk),          // System Clock
                    
                    .Rdy(Rdy),          // Ready
                    
                    .En(En),            // M65C02 ALU Enable Strobe Input
                    .Reg_WE(Reg_WE),    // M65C02 ALU Register Write Enable
                    .ISR(ISR),          // M65C02 ALU Interrupt Service Rtn Strb
                    
//                    .SO(SO),            // M65C02 ALU Set oVerflow Flag in PSW
//                    .Clr_SO(Clr_SO),    // M65C02 ALU Clr SO - Acknowledge
                    .SO(1'b0),          // M65C02 ALU Set oVerflow Flag in PSW
                    .Clr_SO(),          // M65C02 ALU Clr SO - Acknowledge
                    
                    .SelS(SelS),        // M65C02 ALU Stack Pointer Select
                    .S(S),              // M65C02 ALU Stack Pointer

                    .FU_Sel(FU_Sel[4:0]),   // M65C02 ALU Functional Unit Select
                    .Op(Op),            // M65C02 ALU Operation Select
                    .QSel(QSel),        // M65C02 ALU Q Data Mux Select
                    .RSel(RSel),        // M65C02 ALU R Data Mux Select
                    .CSel(CSel),        // M65C02 ALU Adder Carry Select
                    .WSel(WSel),        // M65C02 ALU Register Write Select
                    .OSel(OSel),        // M65C02 ALU Output Register Select
                    .CCSel(CCSel),      // M65C02 ALU Condition Code Select
                    
                    .K(Opcode),         // M65C02 ALU Rockwell Instruction Mask
                    .Tmp(OP2),          // M65C02 ALU Temporary Holding Register
                    .M(OP1),            // M65C02 ALU Memory Operand

                    .DO(Out),           // M65C02 ALU Data Output Multiplexer
                    .Val(Valid),        // M65C02 ALU Output Valid Strobe
                    .CC_Out(CC),        // M65C02 ALU Condition Code Mux

                    .A(A),              // M65C02 ALU Accumulator
                    .X(X),              // M65C02 ALU Pre-Index Register
                    .Y(Y),              // M65C02 ALU Post-Index Register

                    .P(P)               // M65C02 Processor Status Word Register
                );

//  Implement Internal Wait State Generator

always @(posedge Clk)
begin
    if(Rst)
        WSGen <= #1 0;
    else if(C1)
        WSGen <= #1 Dly;
    else if(C3 | C7)
        WSGen <= #1 {1'b0, WSGen[3:1]};
end

assign IntWait = WSGen[0];
assign iWait   = (Wait | IntWait);

//  External Bus Data Output

assign iDO = ((OE_ALU)             ? Out       : 0);
assign iDO = ((OE_PCL  & ~OE_PCH ) ?  PC[ 7:0] : 0);
assign iDO = ((OE_PCH  & ~OE_PCL ) ?  PC[15:8] : 0);
assign iDO = ((OE_PCH  &  OE_PCL ) ? OP1       : 0);
assign iDO = ((OE_dPCL & ~OE_dPCH) ? dPC[ 7:0] : 0);
assign iDO = ((OE_dPCH & ~OE_dPCL) ? dPC[15:8] : 0);
assign iDO = ((OE_dPCH &  OE_dPCL) ? OP2       : 0);
assign iDO = ((OE_PSW)             ? P         : 0);

//  Register interface signals at the module boundary

always @(posedge Clk) VP    <= #1 ((C1) ? iVP    : VP);
always @(posedge Clk) WAI   <= #1 ((C1) ? iWAI   : WAI);
always @(posedge Clk) STP   <= #1 ((C1) ? iSTP   : STP);
//
always @(posedge Clk) Fetch <= #1 ((C1) ? iFetch : Fetch);
always @(posedge Clk) ML    <= #1 ((C1) ? iML    : ML);
//
always @(posedge Clk) CE    <= #1 ((C1) ? iCE    : CE);
always @(posedge Clk) RE    <= #1 ((C1) ? iRE    : RE);
always @(posedge Clk) WE    <= #1 ((C1) ? iWE    : WE);
//
always @(posedge Clk) PA    <= #1 ((C1) ? iPA    : PA);
always @(posedge Clk) DO    <= #1 ((C1) ? iDO    : DO);

always @(posedge Clk)
begin
    if(Rst)
        iDI <= #1 8'hEA;
    else if((C3 | C7) & ~iWait)
        iDI <= #1 DI;
end

////////////////////////////////////////////////////////////////////////////////
//
//  End Implementation
//
////////////////////////////////////////////////////////////////////////////////

endmodule
