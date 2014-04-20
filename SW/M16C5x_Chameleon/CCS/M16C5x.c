#include <M16C5x.h>

#byte PortA = 5
#byte PortB = 6
#byte PortC = 7

#byte SPI_CR    = 10
#byte SPI_SR    = 11
#byte SPI_DIO_H = 12
#byte SPI_DIO_L = 13
#byte Dly_Cntr  = 15

#bit  SPI_CR_REn   = 10.0
#bit  SPI_CR_SSel  = 10.1
#bit  SPI_CR_MD0   = 10.2
#bit  SPI_CR_MD1   = 10.3
#bit  SPI_CR_BR0   = 10.4
#bit  SPI_CR_BR1   = 10.5
#bit  SPI_CR_BR2   = 10.6
#bit  SPI_CR_DIR   = 10.7

#bit  SPI_SR_TF_EF = 5.0
#bit  SPI_SR_TF_FF = 5.1
#bit  SPI_SR_RF_EF = 5.2
#bit  SPI_SR_RF_FF = 5.3

#bit  SPI_DIO_RRdy = 12.2
#bit  SPI_DIO_RErr = 12.0

#bit  RD_Ext_ASCII = 13.7

#use fast_io(ALL)

void main()
{
    set_tris_A(0xFF);
    set_tris_B(0xFF);
    
    set_tris_C(0x1E);
    SPI_CR = 0x1E;

    Dly_Cntr = 8;
    while(--Dly_Cntr > 0);
    
    PortC = 0x13;
    PortC = 0x00;
    PortC = 0x30;
    PortC = 0x01;
    
    while(~SPI_SR_TF_EF);   
    
    while(TRUE) {
        // Read UART Receive FIFO
                
        SPI_CR_REn = 1; 
        set_tris_C(SPI_CR);
        
        do {
            PortC = 0x60; PortC = 0xFF;
            
            while(~SPI_SR_TF_EF); SPI_DIO_H = PortC;
            while( SPI_SR_RF_EF); SPI_DIO_L = PortC;
            
        } while(~SPI_DIO_RRdy || SPI_DIO_RErr);
        
        // Process received data - lc to uc and uc to lc, otherwise unchanged
        
        if(~RD_Ext_ASCII) {     // if Extended ASCII data, skip conversion
            if((SPI_DIO_L >= 'A') && (SPI_DIO_L <= 'z')) {
                if((SPI_DIO_L <= 'Z') || (SPI_DIO_L >= 'a')) {
                    SPI_DIO_L ^= 0x20;
                }
            }
        }
        
        // Write processed data to UART transmit FIFO

        SPI_CR_REn = 0;
        set_tris_C(SPI_CR);
        
        PortC = 0x50; PortC = SPI_DIO_L;    // Transmit processed data
        
        while(~SPI_SR_TF_EF);
    }

}
