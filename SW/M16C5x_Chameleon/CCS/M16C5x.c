#include <M16C5x.h>

#byte PortA         = 0x05
#byte PortB         = 0x06
#byte PortC         = 0x07

#bit  SPI_SR_TF_EF  = 5.0
#bit  SPI_SR_TF_FF  = 5.1
#bit  SPI_SR_RF_EF  = 5.2
#bit  SPI_SR_RF_FF  = 5.3

#byte SPI_CR        = 0x10
#byte SPI_SR        = 0x11
#byte SPI_DIO_H     = 0x12
#byte SPI_DIO_L     = 0x13
#byte Dly_Cntr      = 0x14

#bit  SPI_CR_REn    = 0x10.0
#bit  SPI_CR_SSel   = 0x10.1
#bit  SPI_CR_MD0    = 0x10.2
#bit  SPI_CR_MD1    = 0x10.3
#bit  SPI_CR_BR0    = 0x10.4
#bit  SPI_CR_BR1    = 0x10.5
#bit  SPI_CR_BR2    = 0x10.6
#bit  SPI_CR_DIR    = 0x10.7

#bit  SPI_DIO_RRdy  = 0x12.2
#bit  SPI_DIO_RErr  = 0x12.0

#bit  RD_Ext_ASCII  = 0x13.7

#define COM0 0x00
#define COM1 0x80

#use fast_io(ALL)

void set_baud(int port)
{
    PortC = (port ^ 0x13);
    PortC = 0x00;
    PortC = (port ^ 0x30);
    PortC = 0x01;

    while(~SPI_SR_TF_EF);
}

int1 get_char(int port)
{
    SPI_CR_REn = 1;
    set_tris_C(SPI_CR);
    
    
    PortC = (port ^ 0x60); PortC = 0xFF;
    
    while(~SPI_SR_TF_EF); SPI_DIO_H = PortC;
    while( SPI_SR_RF_EF); SPI_DIO_L = PortC;
    
    return(SPI_DIO_RRdy && ~SPI_DIO_RErr);
}

void put_char(int port)
{
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
        
        PortC = (port ^ 0x50); PortC = SPI_DIO_L;    // Transmit data
        
        while(~SPI_SR_TF_EF);
}


void main()
{
    set_tris_A(0xFF);
    set_tris_B(0xFF);
    
    set_tris_C(0x1E);
    SPI_CR = 0x1E;

    Dly_Cntr = 8;
    while(--Dly_Cntr > 0);
    
    set_baud(COM0);
    set_baud(COM1);
    
    while(TRUE) {
        if(get_char(COM0)) {
            put_char(COM0);
        }    
        
        if(get_char(COM1)) {
            put_char(COM1);
        }    
    }

}
