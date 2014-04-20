IH2MEM.c
=======================

Copyright (C) 2013, Michael A. Morris <morrisma@mchsi.com>.
All Rights Reserved.

Released under LGPL.

Description
-----------

IH2MEM.exe is a filter program that converts 8-bit Intel HEX PIC programming 
files generated by many PIC-compatible tool suites into Xilinx-compatible MEM 
files. This utility is specifically designed to convert Intel HEX files for the 
original 12-bit instruction width PIC processors into 12-bit Xilinx-compatible 
MEM files.

The Xilinx Bitgen tool, when configured with a BMM configuration file, 
automatically places the designated MEM file into block RAMs using the 
Data2MEM utility program. The result is a programming and debugging 
environment similar to that found in the CCS and MPLAB IDEs. The increased 
productivity with the M16C5x SoC soft-core is substantial.

Usage
-----

The executable provided has been compiled as a filter program using Visual 
Studio 6. In the development environment used, Windows XP SP3, IH2MEM is used 
within a DOS box. Following the compilation/assembly of the source files, 
either in CCS or MPLAB, the *.HEX file must be converted from Intel HEX (8-
bit) format to MEM file format. The IH2MEM utility performs this function 
using STDIN and STDOUT.

A batch file can be used to automate this process, but the commands can be 
readily typed in at the DOS prompt. The commands typically used are shown below:

    C:\project_directory>type Hexfile.HEX | IH2MEM > Memfile.MEM 
    C:\project_directory>copy Memfile.MEM C:\XilinxProjectDirectory\Memfile.MEM
    
  