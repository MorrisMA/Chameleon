`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:00:59 06/17/2013 
// Design Name: 
// Module Name:    M65C02_BrdTst 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
////////////////////////////////////////////////////////////////////////////////

module M65C02_BrdTst(
    input   nRst,               // System Reset Input
    input   ClkIn,              // System Clk Input

    output  nCE0,               // Chip Enable for External RAM/ROM Memory
    output  nOE,                // External Asynchronous Bus
    output  nWE,                // External Asynchronous Bus Write Strobe
    output  XA0,                // Extended Address Output for External Memory
    output  [15:0] A,           // External Memory Address Bus
    output  [ 7:0] DB,          // External, Bidirectional Data Bus
    
    output  [1:0] LED,

    output  TxD_RS232_A,
    output  nRTS_RS232_A,
    
    output  DE_RS485_A,
    output  TxD_RS485_A,
    
    output  TxD_RS232_B,
    output  nRTS_RS232_B,
    
    output  DE_RS485_B,
    output  TxD_RS485_B,
    
    output  [1:0] nCSO,         // SPI I/F Chip Select
    output  SCK,                // SPI I/F Serial Clock
    output  MOSI                // SPI I/F Master Out/Slave In Serial Data
);

////////////////////////////////////////////////////////////////////////////////
//
//  Declarations
//

//  ClkGen Interface Signals

wire    Buf_ClkIn;                      // Buffered External Input Clock

wire    Rst;                            // System Reset
wire    Clk;                            // System Clock


////////////////////////////////////////////////////////////////////////////////
//
//  Implementation
//

// Instantiate the Clk and Reset Generator Module

M65C02_ClkGen   ClkGen (
                    .nRst(nRst),            // External Reset Input
                    .ClkIn(ClkIn),          // External Reference Clock Input
                    
                    .Buf_ClkIn(),           // RefClk   <= Buffered ClkIn

                    .Rst(Rst),              // System Reset
                    .Clk(Clk),              // Clk      <= (M/D) x ClkIn
                    .Clk90(),               // Quadrature Clk

                    .Clk2x(),               // Clk_UART <= 2x ClkIn 

                    .Locked()               // ClkGen DCM Locked
                );

//  Implement Test Pattern Generator
//

reg     [26:0] TstPtrn = ~0;

always @(posedge Clk)
begin
    if(Rst)
        TstPtrn <= #1 ~0;
    else
        TstPtrn <= #1 TstPtrn + 1;
end

assign SCK     =  TstPtrn[4];
assign MOSI    =  TstPtrn[5];
assign nCSO[0] =  TstPtrn[6];
assign nCSO[1] = ~TstPtrn[6];

assign DB[0]   =  TstPtrn[4];
assign DB[1]   =  TstPtrn[5];
assign DB[2]   =  TstPtrn[6];
assign DB[3]   =  TstPtrn[7];
assign DB[4]   =  TstPtrn[8];
assign DB[5]   =  TstPtrn[9];
assign DB[6]   =  TstPtrn[10];
assign DB[7]   =  TstPtrn[11];

assign A[ 0]   =  TstPtrn[ 4];
assign A[ 1]   =  TstPtrn[ 5];
assign A[ 2]   =  TstPtrn[ 6];
assign A[ 3]   =  TstPtrn[ 7];
assign A[ 4]   =  TstPtrn[ 8];
assign A[ 5]   =  TstPtrn[ 9];
assign A[ 6]   =  TstPtrn[10];
assign A[ 7]   =  TstPtrn[11];
assign A[ 8]   =  TstPtrn[12];
assign A[ 9]   =  TstPtrn[13];
assign A[10]   =  TstPtrn[14];
assign A[11]   =  TstPtrn[15];
assign A[12]   =  TstPtrn[16];
assign A[13]   =  TstPtrn[17];
assign A[14]   =  TstPtrn[18];
assign A[15]   =  TstPtrn[19];

assign XA0     =  TstPtrn[20] & TstPtrn[22];

assign nWE     =  TstPtrn[21] & TstPtrn[22];
assign nOE     = ~TstPtrn[21] & TstPtrn[22];

assign nCE0    =  TstPtrn[22];


assign TxD_RS232_A  =  TstPtrn[21];  
assign nRTS_RS232_A =  TstPtrn[22];  
    
assign DE_RS485_A   =  TstPtrn[21];  
assign TxD_RS485_A  =  TstPtrn[22];  
    
assign TxD_RS232_B  =  TstPtrn[21];  
assign nRTS_RS232_B =  TstPtrn[22];  
    
assign DE_RS485_B   =  TstPtrn[21];  
assign TxD_RS485_B  =  TstPtrn[22];

assign LED[0]       =  TstPtrn[23];
assign LED[1]       = ~TstPtrn[23];

endmodule
