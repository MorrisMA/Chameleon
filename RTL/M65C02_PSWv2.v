`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company:         M. A. Morris & Associates
// Engineer:        Michael A. Morris 
// 
// Create Date:     22:14:57 10/02/2013 
// Design Name:     WDC W65C02 Microprocessor Re-Implementation
// Module Name:     M65C02_PSWv2.v
// Project Name:    C:\XProjects\ISE10.1i\M6502A 
// Target Devices:  Generic SRAM-based FPGA 
// Tool versions:   Xilinx ISE10.1i SP3
// 
// Description:
//
//  Module implements the PSW of the M65C02_ALUv2 module.  
//
// Dependencies:    None
//
// Revision:
//
//  0.01    13J02   MAM     File Created
//
//  1.00    13J02   MAM     Reverted back to using a case statement for genera-
//                          ing multiplexer for a unitary 6-bit PSW register. 
//                          However, optimized the encoding of the least signi-
//                          ficant 3 bits of the 4-bit CCSel field to maximize
//                          performance and logic reduction. Left implementation
//                          discussed below as comments after the released code.
//
//  1.01    14A19   MAM     Note: two case statement members, pBRK & pPHP, are
//                          included in the WE_P case statement. These CC select
//                          conditions do not assert WE_P, but are included in
//                          case statement below to allow the synthesizer to 
//                          further optimize the control logic/multiplexer for
//                          each bit in the PSW register. Added comments to case
//                          statement members pBRK and pPHP.
//
// Additional Comments: 
//
//  It is modified from the base module to optimize the signal multiplexer pre-
//  ceding the PSW FFs. The control structure based on a case statement used in
//  the first version of this module synthesizes with as many LUTs/Slices as the
//  LST module or the sum of the other modules forming the ALU.
//
//  This indicates that the multiplexer is complex, and that it is a prime con-
//  tributor to the reduced performance of the ALU. Using a case statement for
//  the creation of the control logic of the various PSW FFs is simple and easy
//  to read. However, the width of the select control field, CCSel, impedes the
//  synthesis of a fast multiplexer structure.
//
//  Thus a new approach will be taken. Unlike the current implementation, the
//  new approach will revert back to using individual FFs for each of the 6 PSW
//  FFs that must be provided. Like the register write enable ROM, a decoder
//  will be built using a ROM that selects the FFs involved in a PSW operation
//  based on the lower 3-bits of the 5-bit CCSel field. The current approach 
//  creates a 16:1 case statement around each bit in the PSW. The CCSel encoding
//  may or may not be optimal for logic reduction by the synthesizer. Further,
//  another 8 CCSel codes are used to multiplex the PSW bits onto the CC_Out
//  conditional branch test signal.
//
//  One reduction that will tried to reduce the logic paths is to remove the 
//  condition coded set/clr instructions from the PSW multiplexer. Currently, 
//  seven instructions are mapped into the PSW signal multiplexer along with the
//  appropriate data signals. These operations can be easily performed using the
//  ALU's logic unit. Thus, one optimization will be to move the set/clr opera-
//  from the PSW module back up into the ALU's LU. The mask required to set/clr
//  the bits can be provided by the instruction decode ROM.
//
//  This operation in the LU will resemble the operation needed to provide the
//  RMBx/SMBx instructions. The LU supports the necessary logic operations, and
//  the required operand multiplexers are already in place. Furthermore, the PLP
//  operation already demonstrates the capability to load the PSW from the ALU
//  output data bus. This capability will update the PSW as a single entity from
//  the appropriate ALU DO bus bits.
//
////////////////////////////////////////////////////////////////////////////////

module M65C02_PSWv2(
    input   Rst,
    input   Clk,
    
    input   SO,
    output  Clr_SO,
    
    input   SelP,
    input   Valid,
    input   Rdy,
    
    input   ISR,
    
    input   [2:0] CCSel,
    
    input   [7:6] M,
    input   OV,
    input   LU_Z,
    input   COut,
    input   [7:0] DO,

    output  [7:0] P,
    
    output  N,
    output  V,
    output  D,
    output  Z,
    output  C
);

////////////////////////////////////////////////////////////////////////////////
//
//  Local Parameters
//

localparam pPSW  = 3'b000;  // Set P from ALU
localparam pBRK  = 3'b001;  // Set P.4 when pushing P during interrupt handling
localparam pZ    = 3'b010;  // Set Z = ~|(A & M)
localparam pNVZ  = 3'b011;  // Set N and V flags from M[7:6], and Z = ~|(A & M)
localparam pPHP  = 3'b100;  // Set P.4 when executing PHP instruction
localparam pNZ   = 3'b101;  // Set N and Z flags from ALU
localparam pNZC  = 3'b110;  // Set N, Z, and C flags from ALU
localparam pNVZC = 3'b111;  // Set N, V, Z, and C from ALU

////////////////////////////////////////////////////////////////////////////////
//
//  Declarations
//

reg     [5:0] PSW;
wire    I;

////////////////////////////////////////////////////////////////////////////////
//
//  P - Processor Status Word: {N, V, 1, B, D, I, Z, C}
//

assign WE_P = (SelP | SO) & Valid & Rdy;

always @(posedge Clk)
begin
    if(Rst)
        PSW <= #1 6'b00_0100;       // I set by default on Rst
    else if(ISR & Rdy)
        PSW <= #1 {N, V, 1'b0, 1'b1, Z, C};
    else if(WE_P) 
        case(CCSel)
            pPSW  : PSW <= #1 {DO[7],(DO[6] | SO), DO[3:0]};
            pBRK  : PSW <= #1 {DO[7],(DO[6] | SO), DO[3:0]};
            pZ    : PSW <= #1 {    N,(V     | SO),   D,   I, LU_Z,   C};
            pNVZ  : PSW <= #1 { M[7],(M[6]  | SO),   D,   I, LU_Z,   C};
            pPHP  : PSW <= #1 {DO[7],(V     | SO),   D,   I,~|DO ,   C};
            pNZ   : PSW <= #1 {DO[7],(V     | SO),   D,   I,~|DO ,   C};
            pNZC  : PSW <= #1 {DO[7],(V     | SO),   D,   I,~|DO ,COut};
            pNVZC : PSW <= #1 {DO[7],(OV    | SO),   D,   I,~|DO ,COut};
        endcase
end

//  Decode PSW bits

assign N = PSW[5];  // Negative, nominally Out[7], but M[7] if BIT/TRB/TSB
assign V = PSW[4];  // oVerflow, nominally OV,     but M[6] if BIT/TRB/TSB
assign D = PSW[3];  // Decimal, set/cleared by SED/CLD, cleared on ISR entry
assign I = PSW[2];  // Interrupt Mask, set/cleared by SEI/CLI, set on ISR entry
assign Z = PSW[1];  // Zero, nominally ~|Out, but ~|(A&M) if BIT/TRB/TSB
assign C = PSW[0];  // Carry, set by ADC/SBC, and ASL/ROL/LSR/ROR instructions

//  Assign PSW bits to P (PSW output port)

assign BRK = (CCSel == pBRK);
assign PHP = (CCSel == pPHP);

assign P = {N, V, 1'b1, (BRK | PHP), D, I, Z, C};

//  Generate for Acknowledge SO Command

assign Clr_SO = SO & Valid & Rdy;

endmodule

/*
module M65C02_PSWv2(
    input   Rst,
    input   Clk,
    
    input   SO,
    output  Clr_SO,
    
    input   SelP,
    input   Valid,
    input   Rdy,
    
    input   ISR,
    
    input   [2:0] CCSel,
    
    input   [7:6] M,
    input   OV,
    input   LU_Z,
    input   COut,
    input   [7:0] DO,
    
    input   Brk,
    input   PHP,
    
    output  [7:0] P,
    
    output  reg N,
    output  reg V,
    output  reg D,
    output  reg Z,
    output  reg C
);

////////////////////////////////////////////////////////////////////////////////
//
//  Declarations
//

reg     I;                  // PSW Interrupt Mask FF
reg     [11:0] Sel;         // Register and data selects for PSW FFs

wire    WE_P;
wire    IntP;

wire    N_CE, N_DS, N_In;
wire    V_CE, V_In;
wire    [1:0] V_DS;
wire    D_CE, D_In;
wire    I_CE, I_In;
wire    Z_CE, Z_In;
wire    [1:0] Z_DS;
wire    C_CE, C_DS, C_In;

////////////////////////////////////////////////////////////////////////////////
//
//  Implementation
//

//  Generate Selects for FFs and Input Data Multiplexers

always @(negedge Clk)
begin
    if(Rst)
        Sel <= #1 0;
    else
        case({SO, CCSel[2:0]})
            4'b0000 : Sel <= #1 12'b10_100_1_1_100_10;  // ~SO | pPSW
            4'b0001 : Sel <= #1 12'b00_000_0_0_000_00;  // ~SO | pRSVD1
            4'b0010 : Sel <= #1 12'b00_000_0_0_111_00;  // ~SO | pZ
            4'b0011 : Sel <= #1 12'b11_111_0_0_111_00;  // ~SO | pNVZ
            4'b0100 : Sel <= #1 12'b00_000_0_0_000_00;  // ~SO | pRSVD4
            4'b0101 : Sel <= #1 12'b10_000_0_0_110_00;  // ~SO | pNZ
            4'b0110 : Sel <= #1 12'b10_000_0_0_110_11;  // ~SO | pNZC
            4'b0111 : Sel <= #1 12'b10_110_0_0_110_11;  // ~SO | pNVZC
            //
            4'b1000 : Sel <= #1 12'b10_111_1_1_100_10;  //  SO | pPSW
            4'b1001 : Sel <= #1 12'b00_111_0_0_000_00;  //  SO | pRSVD1
            4'b1010 : Sel <= #1 12'b00_111_0_0_111_00;  //  SO | pZ
            4'b1011 : Sel <= #1 12'b11_111_0_0_111_00;  //  SO | pNVZ
            4'b1100 : Sel <= #1 12'b00_111_0_0_000_00;  //  SO | pRSVD4
            4'b1101 : Sel <= #1 12'b10_111_0_0_110_00;  //  SO | pNZ
            4'b1110 : Sel <= #1 12'b10_111_0_0_110_11;  //  SO | pNZC
            4'b1111 : Sel <= #1 12'b10_111_0_0_110_11;  //  SO | pNVZC
        endcase
end

//  Generate General Control Signals

assign WE_P = SelP & Valid & Rdy;
assign IntP = ISR & Rdy;

//  N - Negative Register

assign N_CE = Sel[11] & WE_P;
assign N_DS = Sel[10];
assign N_In = ((N_DS) ? M[7] : DO[7]); 

always @(posedge Clk)
begin
    if(Rst)
        N <= #1 0;
    else if(N_CE)
        N <= #1 N_In;
end

//  V - oVerflow Register

assign V_CE = (Sel[9] & (SelP | SO) & Valid & Rdy);
assign V_DS = Sel[8:7];
assign V_In = ((V_DS[1]) ? ((V_DS[0]) ? M[6] : OV) : DO[6]); 

always @(posedge Clk)
begin
    if(Rst)
        V <= #1 0;
    else if(V_CE)
        V <= #1 V_In;
end

//  D - Decimal Mode Register

assign D_CE = Sel[6] & WE_P;
assign D_In = DO[3]; 

always @(posedge Clk)
begin
    if(Rst | IntP)
        D <= #1 0;
    else if(D_CE)
        D <= #1 D_In;
end

//  I - Interrupt Mask Register

assign I_CE = Sel[5] & WE_P;
assign I_In = DO[2]; 

always @(posedge Clk)
begin
    if(Rst | IntP)
        I <= #1 1;
    else if(I_CE)
        I <= #1 I_In;
end

//  Z - Zero Register

assign Z_CE = Sel[4] & WE_P;
assign Z_DS = Sel[3:2];
assign Z_In = ((Z_DS[1]) ? ((Z_DS[0]) ? LU_Z : ~|DO) : DO[1]);

always @(posedge Clk)
begin
    if(Rst)
        Z <= #1 0;
    else if(Z_CE)
        Z <= #1 Z_In;
end

//  C - Carry Register

assign C_CE = Sel[1] & WE_P;
assign C_DS = Sel[0];
assign C_In = ((C_DS) ? COut : DO[0]);

always @(posedge Clk)
begin
    if(Rst)
        C <= #1 0;
    else if(C_CE)
        C <= #1 C_In;
end

//  Assign PSW bits to P (PSW output port)

assign P = {N, V, 1'b1, (Brk | PHP), D, I, Z, C};

//  Generate for Acknowledge SO Command

assign Clr_SO = SO & Valid & Rdy;

endmodule

*/