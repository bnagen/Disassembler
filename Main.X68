*-----------------------------------------------------------
* Title      : Disassembler by NEED THIRD
* Written by : Connor Browne, David Exton, Branavan Nagendiram
* Date       : 11/23/18
* Description: Disassemble instructions from a user specified starting
*              and ending memory address from the Motorola 68k architecture.
*-----------------------------------------------------------

INPSTART    EQU $500
INPEND      EQU $520
STRHEXOUT   EQU $540
BUFF        EQU $580
    ORG    $1000
START:                
    
* MAIN PROGRAM LOOP
* NOTES:
*   WARNING: A5, A6, and D7 MUST not be overwritten by subroutines. They are system reserved currently.
*__________________    
MAIN:
    LEA INPSTART,A5
    LEA INPEND,A6
    LEA INPSTART,A2
    MOVE.B  #30,D7
MAINBADRANGE:
    LEA M_INPSTARTRANGE,A1
    JSR USRINPUT
    LEA M_INPENDRANGE,A1
    LEA INPEND,A2
    JSR USRINPUT
    MOVEA.L (A5),A5
    MOVEA.L (A6),A6
    CMP.L A6,A5
    BGE MAINBADRANGE
    
MAINLOOP:
    CMP.B   #0,D7
    BEQ     MAINLOOP_HOLD
    CMP.L   A5,A6         *Check for End of Range
    BLT     EXIT          *Branch to Exit
    MOVE.W  (A5),D6       * Get and move instruction and increment
    
                   
    AND.W   #$F000,D6   *AND to get the first 4 bits
    MOVE.L  #10,D4
    LSR.L   D4,D6
    MOVE.L  D6,A0

    MOVE.L  table(A0),A0    *load address of jump point from table using OPCODE
    SUBI.B  #1,D7
    JMP     (A0)   *jump to corresponding section
                    
MAINLOOP_HOLD:
    MOVE.B  #14,D0      *output enter message
    LEA     M_HOLD,A1
    TRAP    #15
ENTER_HOLD:
    MOVE.B  #5,D0       *Wait for user to press enter
    TRAP    #15
    
    CMP.B   #$D,D1
    BNE     ENTER_HOLD
    
    MOVE.W  #$FF00,D1   *Clear Terminal
    MOVE.B  #11,D0
    TRAP    #15
    
    MOVE.B  #30,D7      *Reset Counter
    BRA MAINLOOP
    

*----------------------------------------------------------
*Table that will use the 4 bits to jump to the correct instruction
*-----------------------------------------------------------
table       dc.l    value0000
            dc.l    value0001
            dc.l    value0010
            dc.l    value0011
            dc.l    value0100
            dc.l    value0101
            dc.l    value0110
            dc.l    value0111
            dc.l    value1000
            dc.l    value1001
            dc.l    value1010
            dc.l    value1011
            dc.l    value1100
            dc.l    value1101
            dc.l    value1110
            dc.l    value1111
            
            
value0000   MOVE.W (A5),D1          *Check for CMPI OPWORD.
            ANDI.W #$0C00,D1
            CMP.W #$0C00,D1
            BNE N_CMPI
            JSR SR_CMPI
            BRA MAINLOOP
            
N_CMPI:   
            
            EOR.L D1,D1
            MOVE.W (A5),D1
            AND.W #$FFC0,D1
            CMP.W #$0880,D1
            BEQ BCLR
            MOVE.W (A5),D1
            AND.W #$0180,D1       *BITWISE AND TO CHECK IF = 111 = BCLR  
            CMP.W #$0180,D1       *CHECK FOR  BCLR  WORD
            BEQ BCLR
            BRA N_BCLR
BCLR:
            JSR SR_BCLR
            BRA MAINLOOP 
N_BCLR:
            EOR.L D1,D1
            MOVE.W (A5),D1
            ANDI.W #$0F00,D1
            CMP.W #$0,D1                  *Check for ORI OPWORD. CHANGE HEX!
            BNE N_ORI
            JSR SR_ORI
            BRA MAINLOOP
N_ORI:
            JSR SR_DATA
            BRA MAINLOOP
 
         
value0001
            MOVE.L (A5),D1
            LEA N_MOVE_0001,A4
            JSR SR_MOVE                     *INSTRUCTION = MOVE.B
            BRA MAINLOOP
N_MOVE_0001:
            
value0010
            LEA MOVE_0010,A4
            MOVE.W (A5),D1
            AND.W #$01C0,D1
            CMP.W #$0040,D1
            BNE MOVE_0010
            JSR SR_MOVEA                     *INSTRUCTION IS EITHER MOVE.L OR MOVEA.L
            BRA MAINLOOP
           
MOVE_0010   
            LEA N_MOVE_0010,A4  
            JSR SR_MOVE
            BRA MAINLOOP
N_MOVE_0010
            JSR SR_DATA
            BRA MAINLOOP
            
            
value0011
            LEA MOVE_0011,A4
            MOVE.W (A5),D1
            AND.W #$40,D1
            CMP.W #$40,D1
            BNE MOVE_0011        *INSTRUCTION IS MOVE.W OR MOVEA.W
            JSR SR_MOVEA
            BRA MAINLOOP
            
MOVE_0011:  
            LEA N_MOVE_0011,A4
            JSR SR_MOVE
            BRA MAINLOOP
N_MOVE_0011:
            JSR SR_DATA
            BRA MAINLOOP
            
value0100   CMP.W #$4E71,(A5)    *Check for NOP OPWORD
            BNE N_NOP
            JSR SR_NOP
            BRA MAINLOOP
            
N_NOP:
            CMP.W #$4E75,(A5)     *Check for RTS OPWORD
            BNE N_RTS
            JSR SR_RTS
            BRA MAINLOOP
            
N_RTS:
            EOR.L D1,D1
            MOVE.W (A5),D1
            AND.W #$FF00,D1
            CMP.W #$4400,D1        *Check for NEG OPWORD
            BNE N_NEG
            JSR SR_NEG
            BRA MAINLOOP
            
N_NEG:      EOR.L D1,D1
            MOVE.W (A5),D1
            AND.W #$01C0,D1        * BITWISE AND TO CHECK IF = 111 = LEA  
            CMP.W #$01C0,D1        * CHECK FOR  LEA WORD
            BNE N_LEA
            JSR SR_LEA
            BRA MAINLOOP
                       
N_LEA:      EOR.L D1,D1
            MOVE.W (A5),D1
            AND.W  #$0FC0,D1
            CMP.W  #$0E80,D1      *Check for JSR OPWORD.
            BNE N_JSR
            JSR SR_JSR
            BRA MAINLOOP
                     
N_JSR:      
            JSR SR_DATA
            BRA MAINLOOP      
                        
            
value0101   MOVE.W (A5),D1
            AND.W #$0100,D1
            CMP.W #$0100,D1
            BNE N_SUBQ
            JSR SR_SUBQ
            BRA MAINLOOP
N_SUBQ:
            JSR SR_DATA
            BRA MAINLOOP
            
value0110   EOR.L D1,D1
            MOVE.W (A5),D1
            ANDI.W #$FF00,D1
            CMP.W #$6000,D1       *Check for BCC OPWORD. CHANGE HEX!
            BNE N_BRA
            JSR SR_BRA
            BRA MAINLOOP                   

N_BRA:      

            JSR SR_BCC
            BRA MAINLOOP
N_BCC:
                
            JSR SR_DATA            
            BRA MAINLOOP          
            
            
value0111
            JSR SR_DATA
            BRA MAINLOOP
            
value1000   
            MOVE.W (A5),D1
            AND.W #$01C0,D1      * BITWISE AND TO CHECK IF = 111 = DIVS  
            CMP.W #$01C0,D1        *CHECK FOR  DIVS OPWORD
            BNE N_DIVS
            JSR SR_DIVS
            BRA MAINLOOP
            

N_DIVS:     
            JSR SR_OR
            BRA MAINLOOP
            
N_OR:            
            JSR SR_DATA
            BRA MAINLOOP 
            
                      
value1001   
            JSR SR_SUB
            BRA MAINLOOP 
            
N_SUB:
            JSR SR_DATA
            BRA MAINLOOP 

            
value1010
            JSR SR_DATA
            BRA MAINLOOP
            
value1011   MOVE.W (A5),D1
            AND.W #$0100,D1           *check for EOR opword
            CMP.W #$0100,D1
            BNE CMP
            JSR SR_EOR
            BRA MAINLOOP
            
CMP:
            JSR SR_CMP                *must be CMP
            BRA MAINLOOP   


N_CMP:
            JSR SR_DATA              *needed for SR_CMP 
            BRA MAINLOOP           
         
         
N_EOR:
             JSR SR_DATA              *needed for SR_EOR 
             BRA MAINLOOP           
         
                    
value1100
            MOVE.W (A5),D1
            AND.W #$01C0,D1      * BITWISE AND TO CHECK IF = 111 = MULS  
            CMP.W #$01C0,D1        *CHECK FOR  MULS WORD
            BNE N_MULS
            JSR SR_MULS
            BRA MAINLOOP
N_MULS:
            JSR SR_DATA
            BRA MAINLOOP
            

value1101   

            JSR SR_ADD            *Must be ADD
            BRA MAINLOOP
            
N_ADD:
            JSR SR_ADDA          *must be ADDA
            BRA MAINLOOP

         
N_ADDA: 
            JSR SR_DATA
            BRA MAINLOOP                
            
                       
value1110   
            MOVE.W (A5),D1
            AND.W #$FEC0,D1                   
            CMP.W #$E2C0,D1
            BEQ LS
            MOVE.W (A5),D1
            AND.W #$FEC0,D1                   
            CMP.W #$E0C0,D1
            BEQ AS
            EOR.L D1,D1
            MOVE.W (A5),D1
            AND.W #$FEC0,D1
            CMP.W #$E6C0,D1                   
            BEQ RO
            
            MOVE.W (A5),D1
            AND.W #$F018,D1                   
            CMP.W #$E008,D1
            BEQ LS
            EOR.L D1,D1
            MOVE.W (A5),D1
            AND.W #$F018,D1
            CMP.W #$E000,D1                   
            BEQ AS
            EOR.L D1,D1
            MOVE.W (A5),D1
            AND.W #$F018,D1
            CMP.W #$E018,D1
            BEQ RO
            JSR SR_DATA
            BRA MAINLOOP
LS:
            JSR SR_LS
            BRA MAINLOOP
  
AS:            
            JSR SR_AS
            BRA MAINLOOP
RO:
            JSR SR_RO
            BRA MAINLOOP
            
value1111
            JSR SR_DATA
            BRA MAINLOOP

* USER INPUT
* __________
USRINPUT:
    MOVE.B  #14,D0          *displays input message
    TRAP    #15
    BRA     INPSTR
    
BADINPUT:
    LEA     M_INPINVALID, A1
    MOVE.B  #14,D0
    TRAP    #15
    BRA     INPSTR 

INPSTR:
    MOVEA.L A2,A1
    MOVE.B  #2,D0
    TRAP    #15

    CMP.B   #$0,(A1)
    BEQ     BADINPUT
    CMP.B   #6,D1
    BGT     BADINPUT
    MOVE.B  D1,D2
INPSTR_01:
    CMP.B   #0,D1
    BEQ     INPSTR_02
    CMP.B   #$46,(A1)
    BGT     BADINPUT
    CMP.B   #$30,(A1)
    BLT     BADINPUT
    SUBI.B  #1,D1
    ADDA.W  #1,A1
    BRA     INPSTR_01
INPSTR_02:    
    MOVEA.L A2,A1
    MOVE.B  D2,D1
    JSR STRING_HEX
    MOVE.L  (A1),D4
    CMP.L   #$1000,D4
    BLT     BADINPUT
    RTS
    
    
*STRING TO HEX
*PRECONDITIONS:
*   Memory location of string must be loaded into A1
*   Length of string must be loaded into D1
*REGISTERS USED:
*   D0,D1,D2,D3,D4,A1,A2
*POSTCONDITIONS:
*   Hex equivalent of string is located at A1 with null character terminating in memory
*NOTES:
*   D0 Counts from 0 to string length
*   D2 is the current working value converted from string
*   D3 is the sum of all the working values
*   D4 is the multiplier for the logical shift left on the current working value
*   A2 Holds the starting address if A1
*_____________
STRING_HEX:
    MOVE.B  #0,D0
    MOVE.L  #0,D3
    MOVEA.L A1,A2 
STRING_HEX_01:
    MOVE.L  #0,D2
    CMP.B   D0,D1
    BNE     STRING_HEX_02
    MOVEA.L A2,A1
    MOVE.L  D3,(A2)
    ADDA.W  #4,A2
    MOVE.B  #$FF,(A2)
    RTS
STRING_HEX_02:
    MOVE.B  (A1),D2
    SUBI.B  #$30,D2     
    CMP.B   #$9,D2
    BLE     NSUB11
    SUBI.B  #$7,D2   
NSUB11: 
    LSL.L   #4,D3
    OR.L    D2,D3
    ADDQ.B  #1,D0 
    ADDA.W  #1,A1          *increment pointer
    BRA     STRING_HEX_01   
    
    
*HEX TO STRING LONG
*PRECONDITIONS:
*   Long Hex Address to be converted located in D1
*REGISTERS USED:
*   D1,D2,D3,D4,D5,A1,A2
*POSTCONDITIONS:
*   String conversion of Long Address Located at memory location $540
*NOTES:
*   CLEARS Two long lengths worth of memory at $540
*   Converts a Long Hex Address into a string for display
*_____________
HEX_STRING_L:
    MOVEM.L D0-A6,-(sp)
    MOVE.L  LONGNIBBLEMASK,D2
    MOVE.B  #8,D4
    LEA     STRHEXOUT,A2
    
HEX_STRING_L_01:
    MOVE.L  D2,D3 *Make a copy of the mask
    AND.L   D1,D3 *And the address with the copy of the mask, overwriting the mask
    MOVE.L  D4,D5
    SUBI.L  #1,D5
    MULS.W  #4,D5
    LSR.L   D5,D3 *Shift the resultant value to the LSB
    CMP.B   #$9,D3
    BLE     HEX_STRING_L_03
    ADDI.B  #$7,D3
HEX_STRING_L_03:
    ADDI.B  #$30,D3
    MOVE.B  D3,(A2)
    ROR.L   #4,D2 *Rotate the original mask
    SUBI.B  #1,D4 *Move the counter
    ADDA.W  #1,A2 *Move the address pointer
    CMP.B   #0,D4
    BNE     HEX_STRING_L_02
    MOVE.B  #$0,(A2)
    MOVEM.L (sp)+,D0-A6
    RTS
HEX_STRING_L_02:
    BRA     HEX_STRING_L_01


*NOP SUBROUTINE
*______________
SR_NOP:
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JSR to DATA and then RTS here.)
        *Reading OPWORD is pointless here, so it is skipped
        *As this must be exactly NOP to get here, no validation is necessary.
    
    *OUTPUT MEMORY ADDRESS AND OPERATION NAME
    MOVE.L  A5,D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVE.B  #14,D0 *TRAP TASK 14, Output A1 with no Carriage Return of Line Feed
    TRAP    #15
    MOVE.L  #$094E4F50,(A1)
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.B  #$0,(A2)
    MOVE.B  #13,D0
    TRAP    #15
    
    *BRANCH FOR <EA> MODE AND OUTPUT ARGUMENTS
        *No branching is necessary as there are no arguments for NOP
    
    *MOVE ADDRESS POINTER TO NEXT OPWORD
    ADDA.W  #2,A5
    
    *RTS
    RTS   
 
 
*MOVE SUBROUTINE
*______________
SR_MOVE:
MOVE_SIZE   DC.L    SR_DATA,SIZE_BYTE,SIZE_LONG,SIZE_WORD
MOVE_EA_SRC DC.L    EA_DATA,EA_ADDR,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_SHORT,EA_ABS_LONG,SR_DATA,SR_DATA,EA_IMM
MOVE_EA_DST DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_SHORT,EA_ABS_LONG,SR_DATA,SR_DATA,SR_DATA       
        *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
        LEA OP_BUFFER,A0
        MOVEA.L A5,A2
        EOR.L D2,D2
        MOVE.W (A2),D2                                
        ANDI.W #$3000,D2                       *VALIDATION
        MOVE.L #10,D1
        LSR.L  D1,D2
        LEA SR_DATA, A3
        MOVE.L D2,A1
        CMPA.L MOVE_SIZE(A1),A3
        BEQ    SR_MOVE_INVALID
        MOVE.L MOVE_SIZE(A1),(A0)+
        
SR_MOVE_EA1: 
                
        ******************
        *SOURCE MODE CALCULATION
        ******************  
        EOR.L   D3,D3
        EOR.L   D4,D4
        MOVE.W  (A2),D3 *Move OPWORD to D3
        MOVE.W  D3,D4   *MOVE OPWORD to D4
        ANDI.W  #$0038,D3 *Bitmask EA Mode
        ANDI.W  #$0007,D4 *Bitmask EA Register
        LSR.L   #1,D3
        LSL.L   #2,D4
        
        CMP.L   #$1C,D3
        BNE     SR_MOVE_EA1_NOT_111
        ADD.B   D4,D3             *GOES TO RIGHT SIDE OF TABLE (HAVE TO ADD REGISTERS TO MODE)
        CMP.B   #44,D3
        BGT     SR_DATA
        MOVE.L  D3,A1
        CMPA.L  MOVE_EA_SRC(A1),A3
        BEQ     SR_MOVE_INVALID
        MOVE.L  MOVE_EA_SRC(A1),(A0)+
        MOVE.L  D4,(A0)+
        BRA     SR_MOVE_EA2
SR_MOVE_EA1_NOT_111:
        MOVE.L  D3,A1
        CMPA.L  MOVE_EA_SRC(A1),A3  *LEFT SIDE OF TABLE   (REGISTER VALUE IS REGISTER NUMBER)
        BEQ     SR_MOVE_INVALID
        MOVE.L  MOVE_EA_SRC(A1),(A0)+
        MOVE.L  D4,(A0)+

SR_MOVE_EA2       
        ******************
        *DESTINATION MODE CALCULATION
        ******************  
        EOR.L   D3,D3
        EOR.L   D4,D4
        MOVE.W  (A2),D3 *Move OPWORD to D3
        MOVE.W  D3,D4   *MOVE OPWORD to D4
        ANDI.W  #$01C0,D3 *Bitmask EA Mode
        ANDI.W  #$0E00,D4 *Bitmask EA Register
        LSR.L   #4,D3
        LSR.L   #7,D4
    
        CMP.L   #$1C,D3
        BNE     SR_MOVE_EA2_NOT_111
        ADD.B   D4,D3 
        CMP.B   #44,D3
        BGT     SR_DATA           *GOES TO RIGHT SIDE OF TABLE (HAVE TO ADD REGISTERS TO MODE)
        MOVE.L  D3,A1
        CMPA.L  MOVE_EA_DST(A1),A3
        BEQ     SR_MOVE_INVALID
        MOVE.L  MOVE_EA_DST(A1),(A0)+
        MOVE.L  D4,(A0)+
        BRA     SR_MOVE_OUT
SR_MOVE_EA2_NOT_111:
        MOVE.L  D3,A1
        CMPA.L  MOVE_EA_DST(A1),A3  *LEFT SIDE OF TABLE   (REGISTER VALUE IS REGISTER NUMBER)
        BEQ     SR_MOVE_INVALID
        MOVE.L  MOVE_EA_DST(A1),(A0)+
        MOVE.L  D4,(A0)+
        ******************
        *PRINT OUT
        ******************
SR_MOVE_OUT        
        MOVE.L  A5,D1
        JSR     HEX_STRING_L
        LEA     STRHEXOUT,A1
        MOVE.B  #14,D0          *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
        TRAP    #15
        MOVE.L  #$094D4F56,(A1) *Store hex value of ASCII output
        MOVEA.L A1,A2
        ADDA.W  #4,A2
        MOVE.W  #$4500,(A2)     *Last 2 values of ASCII (since 4 letter OP)
        TRAP    #15
        
        EOR.L   D1,D1
        MOVE.W  (A5),D1
        ADDA.W  #2,A5
        LEA     OP_BUFFER,A0
        MOVE.L  (A0)+,A1
        JSR     (A1)
        
        EOR.L   D5,D5
        MOVE.B  #1,D6
        MOVE.L  (A0)+,A1
        ADDA.W  #4,A0
        JSR     (A1)
        
        MOVE.B  D6,D5
        EOR.L   D6,D6
        MOVE.L  (A0),A1
        JSR     (A1)
        
        LEA STRHEXOUT,A1
        MOVE.B  #14,D0
        MOVE.L  #$0D0A0000,(A1)   *ASCII for CR,LF,0
        TRAP    #15
        RTS
        
SR_MOVE_INVALID:
        ADDA.W  #4,sp *Reset the Stack location to not include the jump to this location.
        JMP    (A4)

*MOVEA SUBROUTINE
*______________    
SR_MOVEA:
MOVEA_SIZE   DC.L    SR_DATA,SR_DATA,SIZE_LONG,SIZE_WORD
MOVEA_EA_SRC DC.L    EA_DATA,EA_ADDR,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_SHORT,EA_ABS_LONG,SR_DATA,SR_DATA,EA_IMM
        *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
        LEA OP_BUFFER,A0
        MOVEA.L A5,A2
        EOR.L D2,D2
        MOVE.W (A2),D2                                *VALIDATION
        ANDI.W #$3000,D2
        MOVE.L #10,D1
        LSR.L  D1,D2
        LEA SR_DATA, A3
        MOVE.L D2,A1
        CMPA.L MOVEA_SIZE(A1),A3
        BEQ    SR_MOVE_INVALID
        MOVE.L MOVEA_SIZE(A1),(A0)+
        
SR_MOVEA_EA1: 
                
        ******************
        *SOURCE MODE CALCULATION
        ******************  
        EOR.L   D3,D3
        EOR.L   D4,D4
        MOVE.W  (A2),D3 *Move OPWORD to D3
        MOVE.W  D3,D4   *MOVE OPWORD to D4
        ANDI.W  #$0038,D3 *Bitmask EA Mode
        ANDI.W  #$0007,D4 *Bitmask EA Register
        LSR.L   #1,D3
        LSL.L   #2,D4
        
        CMP.L   #$1C,D3
        BNE     SR_MOVEA_EA1_NOT_111
        ADD.B   D4,D3            *GOES TO RIGHT SIDE OF TABLE (HAVE TO ADD REGISTERS TO MODE)
        CMP.B   #44,D3
        BGT     SR_DATA
        MOVE.L  D3,A1
        CMPA.L  MOVEA_EA_SRC(A1),A3
        BEQ     SR_MOVE_INVALID
        MOVE.L  MOVEA_EA_SRC(A1),(A0)+
        MOVE.L  D4,(A0)+
        BRA     SR_MOVEA_OUT
SR_MOVEA_EA1_NOT_111:
        MOVE.L  D3,A1
        CMPA.L  MOVEA_EA_SRC(A1),A3  *LEFT SIDE OF TABLE   (REGISTER VALUE IS REGISTER NUMBER)
        BEQ     SR_MOVEA_INVALID
        MOVE.L  MOVEA_EA_SRC(A1),(A0)+
        MOVE.L  D4,(A0)+

        ******************
        *PRINT OUT
        ******************
SR_MOVEA_OUT        
        MOVE.L  A5,D1
        JSR     HEX_STRING_L
        LEA     STRHEXOUT,A1
        MOVE.B  #14,D0          *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
        TRAP    #15
        MOVE.L  #$094D4F56,(A1) *Store hex value of ASCII output
        MOVEA.L A1,A2
        ADDA.W  #4,A2
        MOVE.L  #$45410000,(A2)     *Last 2 values of ASCII (since 4 letter OP)
        TRAP    #15
        
        EOR.L   D1,D1
        MOVE.W  (A5),D1
        ADDA.W  #2,A5
        LEA     OP_BUFFER,A0
        MOVE.L  (A0)+,A1
        JSR     (A1)
        
        EOR.L   D5,D5
        MOVE.B  #1,D6
        MOVE.L  (A0)+,A1
        ADDA.W  #4,A0
        JSR     (A1)
        
        MOVE.B  D6,D5
        EOR.L   D6,D6
        JSR     EA_ADDR
        
        LEA STRHEXOUT,A1
        MOVE.B  #14,D0
        MOVE.L  #$0D0A0000,(A1)   *ASCII for CR,LF,0
        TRAP    #15
        RTS
        
SR_MOVEA_INVALID:
        ADDA.W  #4,sp *Reset the Stack location to not include the jump to this location.
        JMP    (A4) 

 
*MOVEM SUBROUTINE
*______________
SR_MOVEM:
MOVEM_SIZE    DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
MOVEM_EA      DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_LONG,EA_ABS_SHORT,SR_DATA,SR_DATA,SR_DATA
        *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
         MOVEA.L A5,A2
         ADDA.W #1,A2
         EOR.L D2,D2
         MOVE.B (A2),D2                                *UPDATE VALIDITY 
         ANDI.B #$C0,D2
         LSR.B  #4,D2
         LEA SR_DATA, A3
         CMPA.L MOVEM_SIZE(PC,D2),A3
         BEQ    SR_DATA
         BRA SR_MOVEM_OUT
         
        
        ******************
        *EA MODE CALCULATION
        ******************
         EOR.L   D3,D3
         EOR.L   D4,D4
         MOVE.B  (A2),D3 *Move OPWORD to D3
         MOVE.B  D3,D4   *MOVE OPWORD to D4
         ANDI.B  #$38,D3 *BITMASK TO FIND EA MODE
         ANDI.B  #$07,D4 *BITMASK TO FIND REGISTER VALUE
        
        ******************
        *PRINT OUT
        ******************
SR_MOVEM_OUT        
        MOVE.L  A5,D1
        JSR     HEX_STRING_L
        LEA     STRHEXOUT,A1
        MOVE.B  #14,D0 *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
        TRAP    #15
        MOVE.L  #$094F5645,(A1) *Store hex value of ASCII output
        MOVEA.L A1,A2
        ADDA.W  #4,A2
        MOVE.W  #$454D,(A2)     *Last 2 values of ASCII (since 4 letter OP)
        TRAP    #15
        MOVE.L  D2,A4
        MOVEA.L MOVEM_SIZE(A4),A4
        JSR     (A4)
        
        ADDA.W  #2,A5
        
        RTS   
        
        
*ADD SUBROUTINE
*______________  
SR_ADD:
ADD_SIZE   DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
ADD_EA_SRC DC.L    EA_DATA,EA_ADDR,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_SHORT,EA_ABS_LONG,SR_DATA,SR_DATA,EA_IMM
ADD_EA_DST DC.L    SR_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_SHORT,EA_ABS_LONG,SR_DATA,SR_DATA,SR_DATA       
        *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
        LEA OP_BUFFER,A0
        MOVEA.L A5,A2
        EOR.L   D2,D2
        MOVE.W  (A2),D2                                *VALIDATION
        ANDI.W  #$01C0,D2
        LSR.L   #4,D2
        MOVE.W  D2,D3
        ANDI.W  #$000C,D2
        LEA SR_DATA, A3
        MOVE.L D2,A1
        CMPA.L ADD_SIZE(A1),A3
        BEQ    SR_ADD_INVALID
        MOVE.L ADD_SIZE(A1),(A0)+
        
        
        ANDI.W  #$0010,D3
        CMP.W   #$0000,D3
        BEQ     SR_ADD_DST_EA
        LEA     EA_DATA,A1
        MOVE.L  A1,(A0)+
        MOVE.W  (A2),D4
        ANDI.W  #$0E00,D4 *Bitmask EA Register
        LSR.L   #7,D4
        MOVE.L  D4,(A0)+
  
        ******************
        *EA MODE CALCULATION
        ******************
        EOR.L   D3,D3
        EOR.L   D4,D4
        MOVE.W  (A2),D3 *Move OPWORD to D3
        MOVE.W  D3,D4   *MOVE OPWORD to D4
        ANDI.W  #$0038,D3 *Bitmask EA Mode
        ANDI.W  #$0007,D4 *Bitmask EA Register
        LSR.L   #1,D3
        LSL.L   #2,D4

        MOVE.L  #1,D5
        CMP.L   #$1C,D3
        BNE     SR_ADD_DST_DN_NOT_111
        ADD.B   D4,D3 
        CMP.B   #44,D3
        BGT     SR_DATA           *GOES TO RIGHT SIDE OF TABLE (HAVE TO ADD REGISTERS TO MODE)
        MOVE.L  D3,A1
        CMPA.L  ADD_EA_DST(A1),A3
        BEQ     SR_ADD_INVALID
        MOVE.L  ADD_EA_DST(A1),(A0)+
        MOVE.L  D4,(A0)+
        BRA     SR_ADD_OUT
SR_ADD_DST_DN_NOT_111:
        MOVE.L  D3,A1
        CMPA.L  ADD_EA_DST(A1),A3  *LEFT SIDE OF TABLE   (REGISTER VALUE IS REGISTER NUMBER)
        BEQ     SR_ADD_INVALID
        MOVE.L  ADD_EA_DST(A1),(A0)+
        MOVE.L  D4,(A0)+
        BRA     SR_ADD_OUT
SR_ADD_DST_EA:
  
        EOR.L   D3,D3
        EOR.L   D4,D4
        MOVE.W  (A2),D3 *Move OPWORD to D3
        MOVE.W  D3,D4   *MOVE OPWORD to D4
        ANDI.W  #$0038,D3 *Bitmask EA Mode
        ANDI.W  #$0007,D4 *Bitmask EA Register
        LSR.L   #1,D3
        LSL.L   #2,D4
    
        CMP.L   #$1C,D3
        BNE     SR_ADD_DST_EA_NOT_111
        ADD.B   D4,D3 
        CMP.B   #44,D3
        BGT     SR_DATA           *GOES TO RIGHT SIDE OF TABLE (HAVE TO ADD REGISTERS TO MODE)
        MOVE.L  D3,A1
        CMPA.L  ADD_EA_SRC(A1),A3
        BEQ     SR_ADD_INVALID
        MOVE.L  ADD_EA_SRC(A1),(A0)+
        MOVE.L  D4,(A0)+
        BRA     SR_ADD_DST_EA_2
SR_ADD_DST_EA_NOT_111:
        MOVE.L  D3,A1
        CMPA.L  ADD_EA_SRC(A1),A3  *LEFT SIDE OF TABLE   (REGISTER VALUE IS REGISTER NUMBER)
        BEQ     SR_ADD_INVALID
        MOVE.L  ADD_EA_SRC(A1),(A0)+
        MOVE.L  D4,(A0)+
SR_ADD_DST_EA_2:
        LEA     EA_DATA,A1
        MOVE.L  A1,(A0)+
        MOVE.W  (A2),D4
        ANDI.W  #$0E00,D4 *Bitmask EA Register
        LSR.L   #7,D4
        MOVE.L  D4,(A0)+
        EOR.L   D5,D5

        ******************
        *PRINT OUT
        ******************
SR_ADD_OUT        
        MOVE.L  A5,D1
        JSR     HEX_STRING_L
        LEA     STRHEXOUT,A1
        MOVE.B  #14,D0          *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
        TRAP    #15
        MOVE.L  #$09414444,(A1) *Store hex value of ASCII output
        MOVEA.L A1,A2
        ADDA.W  #4,A2
        MOVE.W  #$00,(A2)     *Last 2 values of ASCII (since 4 letter OP)
        TRAP    #15
        
        EOR.L   D1,D1
        MOVE.W  (A5),D1
        ADDA.W  #2,A5
        LEA     OP_BUFFER,A0
        MOVE.L  (A0)+,A1
        JSR     (A1)
        
        MOVE.B  #1,D6
        MOVE.L  (A0)+,A1
        ADDA.W  #4,A0
        JSR     (A1)
        
        CMP.B   #1,D5
        BEQ     SR_ADD_OUT_2
        MOVE.B  #2,D5
SR_ADD_OUT_2:
        SUBQ    #1,D5
        EOR.L   D6,D6
        MOVE.L  (A0),A1
        JSR     (A1)
        
        LEA STRHEXOUT,A1
        MOVE.B  #14,D0
        MOVE.L  #$0D0A0000,(A1)   *ASCII for CR,LF,0
        TRAP    #15
        RTS
        
SR_ADD_INVALID:
        ADDA.W  #4,sp *Reset the Stack location to not include the jump to this location.
        JMP    N_ADD 
  


     
*ADDA SUBROUTINE
*______________  
SR_ADDA:
ADDA_SIZE   DC.L    SIZE_WORD,SIZE_LONG
ADDA_EA_SRC DC.L    EA_DATA,EA_ADDR,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_SHORT,EA_ABS_LONG,SR_DATA,SR_DATA,EA_IMM      
        *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
        LEA OP_BUFFER,A0
        MOVEA.L A5,A2
        EOR.L   D2,D2
        MOVE.W  (A2),D2                              
        ANDI.W  #$0100,D2                       *VALIDATION
        LSR.L   #6,D2
        MOVE.W  D2,D3
        LEA SR_DATA, A3
        MOVE.L D2,A1
        MOVE.L ADDA_SIZE(A1),(A0)+

  
        EOR.L   D3,D3
        EOR.L   D4,D4
        MOVE.W  (A2),D3 *Move OPWORD to D3
        MOVE.W  D3,D4   *MOVE OPWORD to D4
        ANDI.W  #$0038,D3 *Bitmask EA Mode
        ANDI.W  #$0007,D4 *Bitmask EA Register
        LSR.L   #1,D3
        LSL.L   #2,D4
    
        CMP.L   #$1C,D3
        BNE     SR_ADDA_DST_EA_NOT_111
        ADD.B   D4,D3 
        CMP.B   #44,D3
        BGT     SR_DATA           *GOES TO RIGHT SIDE OF TABLE (HAVE TO ADD REGISTERS TO MODE)
        MOVE.L  D3,A1
        CMPA.L  ADDA_EA_SRC(A1),A3
        BEQ     SR_ADDA_INVALID
        MOVE.L  ADDA_EA_SRC(A1),(A0)+
        MOVE.L  D4,(A0)+
        BRA     SR_ADDA_DST_EA_2
SR_ADDA_DST_EA_NOT_111:
        MOVE.L  D3,A1
        CMPA.L  ADDA_EA_SRC(A1),A3  *LEFT SIDE OF TABLE   (REGISTER VALUE IS REGISTER NUMBER)
        BEQ     SR_ADDA_INVALID
        MOVE.L  ADDA_EA_SRC(A1),(A0)+
        MOVE.L  D4,(A0)+
SR_ADDA_DST_EA_2:
        LEA     EA_ADDR,A1
        MOVE.L  A1,(A0)+
        MOVE.W  (A2),D4
        ANDI.W  #$0E00,D4 *Bitmask EA Register
        LSR.L   #7,D4
        MOVE.L  D4,(A0)+

        ******************
        *PRINT OUT
        ******************
SR_ADDA_OUT        
        MOVE.L  A5,D1
        JSR     HEX_STRING_L
        LEA     STRHEXOUT,A1
        MOVE.B  #14,D0          *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
        TRAP    #15
        MOVE.L  #$09414444,(A1) *Store hex value of ASCII output
        MOVEA.L A1,A2
        ADDA.W  #4,A2
        MOVE.W  #$4100,(A2)     *Last 2 values of ASCII (since 4 letter OP)
        TRAP    #15
        
        EOR.L   D1,D1
        MOVE.W  (A5),D1
        ADDA.W  #2,A5
        LEA     OP_BUFFER,A0
        MOVE.L  (A0)+,A1
        JSR     (A1)
        
        MOVE.L  #0,D5
        MOVE.B  #1,D6
        MOVE.L  (A0)+,A1
        ADDA.W  #4,A0
        JSR     (A1)
        
        MOVE.L  #1,D5
        EOR.L   D6,D6
        MOVE.L  (A0),A1
        JSR     (A1)
        
        LEA STRHEXOUT,A1
        MOVE.B  #14,D0
        MOVE.L  #$0D0A0000,(A1)   *ASCII for CR,LF,0
        TRAP    #15
        RTS
        
SR_ADDA_INVALID:
        ADDA.W  #4,sp *Reset the Stack location to not include the jump to this location.
        JMP    N_ADDA 
    
*SUB SUBROUTINE
*______________  
SR_SUB:
SUB_SIZE   DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
SUB_EA_SRC DC.L    EA_DATA,EA_ADDR,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_SHORT,EA_ABS_LONG,SR_DATA,SR_DATA,EA_IMM
SUB_EA_DST DC.L    SR_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_SHORT,EA_ABS_LONG,SR_DATA,SR_DATA,SR_DATA       
        *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
        LEA OP_BUFFER,A0
        MOVEA.L A5,A2
        EOR.L   D2,D2
        MOVE.W  (A2),D2                                *Validation
        ANDI.W  #$01C0,D2
        LSR.L   #4,D2
        MOVE.W  D2,D3
        ANDI.W  #$000C,D2
        LEA SR_DATA, A3
        MOVE.L D2,A1
        CMPA.L SUB_SIZE(A1),A3
        BEQ    SR_SUB_INVALID
        MOVE.L SUB_SIZE(A1),(A0)+
        
        ANDI.W  #$0010,D3
        CMP.W   #$0000,D3
        BEQ     SR_SUB_DST_EA
        LEA     EA_DATA,A1
        MOVE.L  A1,(A0)+
        MOVE.W  (A2),D4
        ANDI.W  #$0E00,D4 *Bitmask EA Register
        LSR.L   #7,D4
        MOVE.L  D4,(A0)+
  
        EOR.L   D3,D3
        EOR.L   D4,D4
        MOVE.W  (A2),D3 *Move OPWORD to D3
        MOVE.W  D3,D4   *MOVE OPWORD to D4
        ANDI.W  #$0038,D3 *Bitmask EA Mode
        ANDI.W  #$0007,D4 *Bitmask EA Register
        LSR.L   #1,D3
        LSL.L   #2,D4
        MOVE.L  #1,D5
        CMP.L   #$1C,D3
        BNE     SR_SUB_DST_DN_NOT_111
        ADD.B   D4,D3 
        CMP.B   #44,D3
        BGT     SR_DATA           *GOES TO RIGHT SIDE OF TABLE (HAVE TO ADD REGISTERS TO MODE)
        MOVE.L  D3,A1
        CMPA.L  SUB_EA_DST(A1),A3
        BEQ     SR_SUB_INVALID
        MOVE.L  SUB_EA_DST(A1),(A0)+
        MOVE.L  D4,(A0)+
        BRA     SR_SUB_OUT
SR_SUB_DST_DN_NOT_111:
        MOVE.L  D3,A1
        CMPA.L  ADD_EA_DST(A1),A3  *LEFT SIDE OF TABLE   (REGISTER VALUE IS REGISTER NUMBER)
        BEQ     SR_SUB_INVALID
        MOVE.L  SUB_EA_DST(A1),(A0)+
        MOVE.L  D4,(A0)+
        BRA     SR_SUB_OUT
SR_SUB_DST_EA:  
        EOR.L   D3,D3
        EOR.L   D4,D4
        MOVE.W  (A2),D3 *Move OPWORD to D3
        MOVE.W  D3,D4   *MOVE OPWORD to D4
        ANDI.W  #$0038,D3 *Bitmask EA Mode
        ANDI.W  #$0007,D4 *Bitmask EA Register
        LSR.L   #1,D3
        LSL.L   #2,D4
    
        CMP.L   #$1C,D3
        BNE     SR_SUB_DST_EA_NOT_111
        ADD.B   D4,D3 
        CMP.B   #44,D3
        BGT     SR_DATA           *GOES TO RIGHT SIDE OF TABLE (HAVE TO ADD REGISTERS TO MODE)
        MOVE.L  D3,A1
        CMPA.L  SUB_EA_SRC(A1),A3
        BEQ     SR_SUB_INVALID
        MOVE.L  SUB_EA_SRC(A1),(A0)+
        MOVE.L  D4,(A0)+
        BRA     SR_SUB_DST_EA_2
SR_SUB_DST_EA_NOT_111:
        MOVE.L  D3,A1
        CMPA.L  SUB_EA_SRC(A1),A3  *LEFT SIDE OF TABLE   (REGISTER VALUE IS REGISTER NUMBER)
        BEQ     SR_SUB_INVALID
        MOVE.L  SUB_EA_SRC(A1),(A0)+
        MOVE.L  D4,(A0)+
SR_SUB_DST_EA_2:
        LEA     EA_DATA,A1
        MOVE.L  A1,(A0)+
        MOVE.W  (A2),D4
        ANDI.W  #$0E00,D4 *Bitmask EA Register
        LSR.L   #7,D4
        MOVE.L  D4,(A0)+
        MOVE.L  #0,D5

SR_SUB_OUT        
        MOVE.L  A5,D1
        JSR     HEX_STRING_L
        LEA     STRHEXOUT,A1
        MOVE.B  #14,D0          *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
        TRAP    #15
        MOVE.L  #$09535542,(A1) *Store hex value of ASCII output
        MOVEA.L A1,A2
        ADDA.W  #4,A2
        MOVE.W  #$00,(A2)        *Last 2 values of ASCII (since 4 letter OP)
        TRAP    #15
        
        EOR.L   D1,D1            *Clears D1
        MOVE.W  (A5),D1
        ADDA.W  #2,A5
        LEA     OP_BUFFER,A0
        MOVE.L  (A0)+,A1
        JSR     (A1)
        
        
        MOVE.B  #1,D6
        MOVE.L  (A0)+,A1
        ADDA.W  #4,A0
        JSR     (A1)
        
        CMP.B   #1,D5
        BEQ     SR_SUB_OUT_2
        MOVE.B  #2,D5
SR_SUB_OUT_2:
        SUBQ    #1,D5
        EOR.L   D6,D6
        MOVE.L  (A0),A1
        JSR     (A1)
        
        LEA STRHEXOUT,A1
        MOVE.B  #14,D0
        MOVE.L  #$0D0A0000,(A1)   *ASCII for CR,LF,0
        TRAP    #15
        RTS
        
SR_SUB_INVALID:
        ADDA.W  #4,sp *Reset the Stack location to not include the jump to this location.
        JMP    N_SUB    

*SUBQ SUBROUTINE
*______________
SR_SUBQ:
SUBQ_SIZE    DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
SUBQ_EA      DC.L    EA_DATA,EA_ADDR,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_SHORT,EA_ABS_LONG,SR_DATA,SR_DATA,SR_DATA
        *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
        LEA OP_BUFFER,A0
        MOVEA.L A5,A2
        EOR.L D2,D2
        MOVE.W (A2),D2                                *Validation
        ANDI.W #$00C0,D2
        LSR.L  #4,D2
        LEA SR_DATA, A3
        MOVE.L D2,A1
        CMPA.L SUBQ_SIZE(A1),A3
        BEQ    SR_SUBQ_INVALID
        MOVE.L SUBQ_SIZE(A1),(A0)+
         
        
        ******************
        *DESTINATION MODE CALCULATION
        ******************  
        EOR.L   D3,D3
        EOR.L   D4,D4
        MOVE.W  (A2),D3 *Move OPWORD to D3
        MOVE.W  D3,D4   *MOVE OPWORD to D4
        ANDI.W  #$0038,D3 *Bitmask EA Mode
        ANDI.W  #$0007,D4 *Bitmask EA Register
        LSR.L   #1,D3
        LSL.L   #2,D4
        
        CMP.L   #$1C,D3
        BNE     SR_SUBQ_DST_NOT_111
        ADD.B   D4,D3            *GOES TO RIGHT SIDE OF TABLE (HAVE TO ADD REGISTERS TO MODE)
        CMP.B   #44,D3
        BGT     SR_DATA
        MOVE.L  D3,A1
        CMPA.L  SUBQ_EA(A1),A3
        BEQ     SR_SUBQ_INVALID
        MOVE.L  SUBQ_EA(A1),(A0)+
        MOVE.L  D4,(A0)+
        BRA     SR_SUBQ_OUT
SR_SUBQ_DST_NOT_111:
        MOVE.L  D3,A1
        CMPA.L  SUBQ_EA(A1),A3  *LEFT SIDE OF TABLE   (REGISTER VALUE IS REGISTER NUMBER)
        BEQ     SR_SUBQ_INVALID
        MOVE.L  SUBQ_EA(A1),(A0)+
        MOVE.L  D4,(A0)+

        
        ******************
        *PRINT OUT
        ******************
SR_SUBQ_OUT        
        MOVE.L  A5,D1
        JSR     HEX_STRING_L
        LEA     STRHEXOUT,A1
        MOVE.B  #14,D0          *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
        TRAP    #15
        MOVE.L  #$09535542,(A1) **store "   SUB" ASCII ouput

        MOVEA.L A1,A2
        ADDA.W  #4,A2
        MOVE.W  #$5100,(A2)     *stores "Q" and 0 for null termination
        TRAP    #15
        
        EOR.L   D1,D1
        MOVE.W  (A5),D1
        
        LEA     OP_BUFFER,A0
        MOVE.L  (A0)+,A1
        JSR     (A1)
        
        LEA     STRHEXOUT,A1
        MOVE.B  #$23,(A1)+
        MOVE.W  (A5),D1
        AND.W   #$0E00,D1
        MOVE.B  #9,D3
        LSR.W   D3,D1
        CMP.B   #0,D1
        BNE SR_SUBQ_OUT_2
        MOVE.B  #8,D1
SR_SUBQ_OUT_2:
        ADD.B   #$30,D1
        MOVE.B  D1,(A1)+
        MOVE.W  #$2C00,(A1)+
        MOVE.B  #14,D0
        LEA     STRHEXOUT,A1
        TRAP    #15
        MOVE.W  (A5),D1
        ADDA.W  #2,A5
        
        MOVE.L  #0,D5
        EOR.L   D6,D6
        MOVE.L  (A0),A1
        JSR     (A1)
        
        LEA STRHEXOUT,A1
        MOVE.B  #14,D0
        MOVE.L  #$0D0A0000,(A1)   *ASCII for CR,LF,0
        TRAP    #15
        RTS    
        
SR_SUBQ_INVALID:
        ADDA.W  #4,sp *Reset the Stack location to not include the jump to this location.
        JMP     N_SUB  

*CMP SUBROUTINE
*______________
SR_CMP:
CMP_SIZE    DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA,SR_DATA,SR_DATA,SR_DATA,SR_DATA
CMP_EA      DC.L    EA_DATA,EA_ADDR,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_SHORT,EA_ABS_LONG,SR_DATA,SR_DATA,EA_IMM
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)   
    LEA OP_BUFFER,A0
    MOVEA.L A5,A2
    EOR.L D2,D2
    MOVE.W (A2),D2                                 
    ANDI.W #$01C0,D2                *Validation
    LSR.L  #4,D2
    LEA SR_DATA,A3
    MOVE.L D2,A1
    CMPA.L CMP_SIZE(A1),A3
    BEQ    SR_CMP_INVALID
    MOVE.L CMP_SIZE(A1),(A0)+  

    ********************
    *EA MODE CALCULATION
    ******************
    EOR.L   D3,D3
    EOR.L   D4,D4
    MOVE.W  (A2),D3   *Move OPWORD to D3
    MOVE.W  D3,D4     *MOVE OPWORD to D4
    ANDI.W  #$0038,D3 *Bitmask EA Mode
    ANDI.W  #$0007,D4 *Bitmask EA Register
    LSR.L   #1,D3
    LSL.L   #2,D4

    CMP.L   #$1C,D3
    BNE     SR_CMP_NOT_111
    ADD.B   D4,D3            *GOES TO RIGHT SIDE OF TABLE (HAVE TO ADD REGISTERS TO MODE)

    CMP.B   #44,D3
    BGT     SR_DATA
    MOVE.L  D3,A1
    CMPA.L  CMP_EA(A1),A3
    BEQ     SR_CMP_INVALID
    MOVE.L  CMP_EA(A1),(A0)+
    MOVE.L  D4,(A0)+
    BRA     SR_CMP_OUT   
       
SR_CMP_NOT_111:      
    MOVE.L  D3,A1
    CMPA.L  CMP_EA(A1),A3  *LEFT SIDE OF TABLE   (REGISTER VALUE IS REGISTER NUMBER)
    BEQ     SR_CMP_INVALID
    MOVE.L  CMP_EA(A1),(A0)+
    MOVE.L  D4,(A0)+
       
    ******************
    *PRINT OUT
    ******************

SR_CMP_OUT:     
    MOVE.L  A5,D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVE.B  #14,D0 *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
    TRAP    #15
    MOVE.L  #$09434D50,(A1) *store "CMP" ASCII ouput
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.B  #$0,(A2)
    TRAP    #15
    
    EOR.L   D1,D1
    MOVE.W  (A5),D1
    ADDA.W  #2,A5
    LEA     OP_BUFFER,A0
    MOVE.L  (A0)+,A1
    JSR     (A1)

    EOR.L   D5,D5
    MOVE.L  #1,D6
    MOVE.L  (A0)+,A1
    ADDA.W  #4,A0
    JSR     (A1)
        
    MOVE.B  D6,D5
    EOR.L   D6,D6
    MOVE.L  (A0),A1
    JSR     (A1)
    LEA STRHEXOUT,A1
    MOVE.B  #14,D0
    MOVE.L  #$0D0A0000,(A1)   *ASCII for CR,LF,0
    TRAP    #15

    RTS
   
SR_CMP_INVALID:
        ADDA.W  #4,sp *Reset the Stack location to not include the jump to this location.
        JMP    N_CMP 
 
 
*CMPI SUBROUTINE
*______________
SR_CMPI:
CMPI_SIZE    DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
CMPI_EA      DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_SHORT,EA_ABS_LONG,SR_DATA,SR_DATA,EA_IMM
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)   
    LEA OP_BUFFER,A0
    MOVEA.L A5,A2
    EOR.L D2,D2
    MOVE.W (A2),D2                                 
    ANDI.W #$00C0,D2      *VALIDATION
    LSR.L  #4,D2
    LEA SR_DATA,A3
    MOVE.L D2,A1
    CMPA.L CMPI_SIZE(A1),A3
    BEQ    SR_CMPI_INVALID
    MOVE.L CMPI_SIZE(A1),(A0)+  

    ********************
    *EA MODE CALCULATION
    ******************
    EOR.L   D3,D3
    EOR.L   D4,D4
    MOVE.W  (A2),D3   *Move OPWORD to D3
    MOVE.W  D3,D4     *MOVE OPWORD to D4
    ANDI.W  #$0038,D3 *Bitmask EA Mode
    ANDI.W  #$0007,D4 *Bitmask EA Register
    LSR.L   #1,D3
    LSL.L   #2,D4

    CMP.L   #$1C,D3
    BNE     SR_CMPI_NOT_111
    ADD.B   D4,D3            *GOES TO RIGHT SIDE OF TABLE (HAVE TO ADD REGISTERS TO MODE)

    CMP.B   #44,D3
    BGT     SR_DATA
    MOVE.L  D3,A1
    CMPA.L  CMPI_EA(A1),A3
    BEQ     SR_CMPI_INVALID
    MOVE.L  CMPI_EA(A1),(A0)+
    MOVE.L  D4,(A0)+
    BRA     SR_CMPI_OUT   
       
SR_CMPI_NOT_111:      
    MOVE.L  D3,A1
    CMPA.L  CMPI_EA(A1),A3  *LEFT SIDE OF TABLE   (REGISTER VALUE IS REGISTER NUMBER)
    BEQ     SR_CMPI_INVALID
    MOVE.L  CMPI_EA(A1),(A0)+
    MOVE.L  D4,(A0)+
       
    ******************
    *PRINT OUT
    ******************

SR_CMPI_OUT:     
    MOVE.L  A5,D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVE.B  #14,D0           *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
    TRAP    #15
    MOVE.L  #$09434D50,(A1)  *STORE CMP for ASCII
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.W  #$4900,(A2)      *Last value of ASCII (since 4 letter OP)
    TRAP    #15
    
    EOR.L   D1,D1
    MOVE.W  (A5),D1
    ADDA.W  #2,A5
    LEA     OP_BUFFER,A0
    MOVE.L  (A0)+,A1
    JSR     (A1)

    EOR.L   D5,D5
    MOVE.L  #1,D6
    MOVE.L  (A0)+,A1
    ADDA.W  #4,A0
    JSR     (A1)
        
    MOVE.B  D6,D5
    EOR.L   D6,D6
    MOVE.L  (A0),A1
    JSR     (A1)
    LEA STRHEXOUT,A1
    MOVE.B  #14,D0
    MOVE.L  #$0D0A0000,(A1)   *ASCII for CR,LF,0
    TRAP    #15

    RTS
   
SR_CMPI_INVALID:
        ADDA.W  #4,sp *Reset the Stack location to not include the jump to this location.
        JMP    N_CMPI


*MULS SUBROUTINE
*______________
SR_MULS:
MULS_EA      DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_SHORT,EA_ABS_LONG,SR_DATA,SR_DATA,EA_IMM
*READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
        LEA OP_BUFFER,A0
        MOVEA.L A5,A2
        MOVE.W  D2,D3
        LEA SIZE_WORD,A1
        MOVE.L A1,(A0)+
        

  
        EOR.L   D3,D3
        EOR.L   D4,D4
        MOVE.W  (A2),D3 *Move OPWORD to D3
        MOVE.W  D3,D4   *MOVE OPWORD to D4
        ANDI.W  #$0038,D3 *Bitmask EA Mode
        ANDI.W  #$0007,D4 *Bitmask EA Register
        LSR.L   #1,D3
        LSL.L   #2,D4
    
        CMP.L   #$1C,D3
        BNE     SR_MULS_DST_EA_NOT_111
        ADD.B   D4,D3 
        CMP.B   #44,D3
        BGT     SR_DATA           *GOES TO RIGHT SIDE OF TABLE (HAVE TO ADD REGISTERS TO MODE)
        MOVE.L  D3,A1
        CMPA.L  MULS_EA(A1),A3
        BEQ     SR_MULS_INVALID
        MOVE.L  MULS_EA(A1),(A0)+
        MOVE.L  D4,(A0)+
        BRA     SR_MULS_DST_EA_2
SR_MULS_DST_EA_NOT_111:
        MOVE.L  D3,A1
        CMPA.L  MULS_EA(A1),A3  *LEFT SIDE OF TABLE   (REGISTER VALUE IS REGISTER NUMBER)
        BEQ     SR_MULS_INVALID
        MOVE.L  MULS_EA(A1),(A0)+
        MOVE.L  D4,(A0)+
SR_MULS_DST_EA_2:
        LEA     EA_DATA,A1
        MOVE.L  A1,(A0)+
        MOVE.W  (A2),D4
        ANDI.W  #$0E00,D4 *Bitmask EA Register
        LSR.L   #7,D4
        MOVE.L  D4,(A0)+

SR_MULS_OUT        
        MOVE.L  A5,D1
        JSR     HEX_STRING_L
        LEA     STRHEXOUT,A1
        MOVE.B  #14,D0          *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
        TRAP    #15
        MOVE.L  #$094D554C,(A1) *Store hex value of ASCII output
        MOVEA.L A1,A2
        ADDA.W  #4,A2
        MOVE.W  #$5300,(A2)     *Last 2 values of ASCII (since 4 letter OP)
        TRAP    #15
        
        EOR.L   D1,D1
        MOVE.W  (A5),D1
        ADDA.W  #2,A5
        LEA     OP_BUFFER,A0
        MOVE.L  (A0)+,A1
        JSR     (A1)
        
        MOVE.L  #0,D5
        MOVE.B  #1,D6
        MOVE.L  (A0)+,A1
        ADDA.W  #4,A0
        JSR     (A1)
        
        MOVE.L  #1,D5
        EOR.L   D6,D6
        MOVE.L  (A0),A1
        JSR     (A1)
        
        LEA STRHEXOUT,A1
        MOVE.B  #14,D0
        MOVE.L  #$0D0A0000,(A1)   *ASCII for CR,LF,0
        TRAP    #15
        RTS
        
SR_MULS_INVALID:
        *MOVE.L  (sp)+,D0
        ADDA.W  #4,sp *Reset the Stack location to not include the jump to this location.
        JMP    N_MULS   

*DIVS SUBROUTINE
*______________
SR_DIVS:
DIVS_EA      DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_SHORT,EA_ABS_LONG,SR_DATA,SR_DATA,EA_IMM
*READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
        LEA OP_BUFFER,A0
        MOVEA.L A5,A2
        MOVE.W  D2,D3
        LEA SIZE_WORD,A1
        MOVE.L A1,(A0)+
         
    ********************
    *EA MODE CALCULATION
    ******************
        EOR.L   D3,D3
        EOR.L   D4,D4
        MOVE.W  (A2),D3 *Move OPWORD to D3
        MOVE.W  D3,D4   *MOVE OPWORD to D4
        ANDI.W  #$0038,D3 *Bitmask EA Mode
        ANDI.W  #$0007,D4 *Bitmask EA Register
        LSR.L   #1,D3
        LSL.L   #2,D4
    
        CMP.L   #$1C,D3
        BNE     SR_DIVS_DST_EA_NOT_111
        ADD.B   D4,D3 
        CMP.B   #44,D3
        BGT     SR_DATA           *GOES TO RIGHT SIDE OF TABLE (HAVE TO ADD REGISTERS TO MODE)
        MOVE.L  D3,A1
        CMPA.L  DIVS_EA(A1),A3
        BEQ     SR_DIVS_INVALID
        MOVE.L  DIVS_EA(A1),(A0)+
        MOVE.L  D4,(A0)+
        BRA     SR_DIVS_DST_EA_2
SR_DIVS_DST_EA_NOT_111:
        MOVE.L  D3,A1
        CMPA.L  DIVS_EA(A1),A3  *LEFT SIDE OF TABLE   (REGISTER VALUE IS REGISTER NUMBER)
        BEQ     SR_DIVS_INVALID
        MOVE.L  DIVS_EA(A1),(A0)+
        MOVE.L  D4,(A0)+
SR_DIVS_DST_EA_2:
        LEA     EA_DATA,A1
        MOVE.L  A1,(A0)+
        MOVE.W  (A2),D4
        ANDI.W  #$0E00,D4 *Bitmask EA Register
        LSR.L   #7,D4
        MOVE.L  D4,(A0)+

SR_DIVS_OUT        
        MOVE.L  A5,D1
        JSR     HEX_STRING_L
        LEA     STRHEXOUT,A1
        MOVE.B  #14,D0          *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
        TRAP    #15
        MOVE.L  #$09444956,(A1) *Store hex value of ASCII output
        MOVEA.L A1,A2
        ADDA.W  #4,A2
        MOVE.W  #$5300,(A2)     *Last 2 values of ASCII (since 4 letter OP)
        TRAP    #15
        
        EOR.L   D1,D1
        MOVE.W  (A5),D1
        ADDA.W  #2,A5
        LEA     OP_BUFFER,A0
        MOVE.L  (A0)+,A1
        JSR     (A1)
        
        MOVE.L  #0,D5
        MOVE.B  #1,D6
        MOVE.L  (A0)+,A1
        ADDA.W  #4,A0
        JSR     (A1)
        
        MOVE.L  #1,D5
        EOR.L   D6,D6
        MOVE.L  (A0),A1
        JSR     (A1)
        
        LEA STRHEXOUT,A1
        MOVE.B  #14,D0
        MOVE.L  #$0D0A0000,(A1)   *ASCII for CR,LF,0
        TRAP    #15
        RTS
        
SR_DIVS_INVALID:
        *MOVE.L  (sp)+,D0
        ADDA.W  #4,sp *Reset the Stack location to not include the jump to this location.
        JMP    N_DIVS 


*LEA SUBROUTINE
*______________
SR_LEA:
LEA_EA DC.L    SR_DATA,SR_DATA,EA_ADDRIND,SR_DATA,SR_DATA,SR_DATA,SR_DATA,EA_ABS_SHORT,EA_ABS_LONG,SR_DATA,SR_DATA,SR_DATA      
        *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)

        LEA OP_BUFFER,A0
        MOVEA.L A5,A2
        MOVE.W  D2,D3
        LEA SIZE_LONG,A1
        MOVE.L A1,(A0)+

  
        EOR.L   D3,D3
        EOR.L   D4,D4
        MOVE.W  (A2),D3 *Move OPWORD to D3
        MOVE.W  D3,D4   *MOVE OPWORD to D4
        ANDI.W  #$0038,D3 *Bitmask EA Mode
        ANDI.W  #$0007,D4 *Bitmask EA Register
        LSR.L   #1,D3
        LSL.L   #2,D4
    
        CMP.L   #$1C,D3
        BNE     SR_LEA_DST_EA_NOT_111
        ADD.B   D4,D3 
        CMP.B   #44,D3
        BGT     SR_DATA           *GOES TO RIGHT SIDE OF TABLE (HAVE TO ADD REGISTERS TO MODE)
        MOVE.L  D3,A1
        CMPA.L  LEA_EA(A1),A3
        BEQ     SR_LEA_INVALID
        MOVE.L  LEA_EA(A1),(A0)+
        MOVE.L  D4,(A0)+
        BRA     SR_LEA_DST_EA_2
SR_LEA_DST_EA_NOT_111:
        MOVE.L  D3,A1
        CMPA.L  LEA_EA(A1),A3  *LEFT SIDE OF TABLE   (REGISTER VALUE IS REGISTER NUMBER)
        BEQ     SR_LEA_INVALID
        MOVE.L  LEA_EA(A1),(A0)+
        MOVE.L  D4,(A0)+
SR_LEA_DST_EA_2:
        LEA     EA_ADDR,A1
        MOVE.L  A1,(A0)+
        MOVE.W  (A2),D4
        ANDI.W  #$0E00,D4 *Bitmask EA Register
        LSR.L   #7,D4
        MOVE.L  D4,(A0)+

SR_LEA_OUT        
        MOVE.L  A5,D1
        JSR     HEX_STRING_L
        LEA     STRHEXOUT,A1
        MOVE.B  #14,D0          *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
        TRAP    #15
        MOVE.L  #$094C4541,(A1) *Store hex value of ASCII output
        MOVEA.L A1,A2
        ADDA.W  #4,A2
        MOVE.W  #$00,(A2)     *Last 2 values of ASCII (since 4 letter OP)
        TRAP    #15
        
        EOR.L   D1,D1
        MOVE.W  (A5),D1
        ADDA.W  #2,A5
        LEA     OP_BUFFER,A0
        MOVE.L  (A0)+,A1
        JSR     (A1)
        
        MOVE.L  #0,D5
        MOVE.B  #1,D6
        MOVE.L  (A0)+,A1
        ADDA.W  #4,A0
        JSR     (A1)
        
        *EOR.L   D5,D5
        MOVE.L  #1,D5
        EOR.L   D6,D6
        MOVE.L  (A0),A1
        JSR     (A1)
        
        LEA STRHEXOUT,A1
        MOVE.B  #14,D0
        MOVE.L  #$0D0A0000,(A1)   *ASCII for CR,LF,0
        TRAP    #15
        RTS
        
SR_LEA_INVALID:
        *MOVE.L  (sp)+,D0
        ADDA.W  #4,sp *Reset the Stack location to not include the jump to this location.
        JMP    N_LEA 
        
        
*NEG SUBROUTINE
*______________
SR_NEG:
    *DEFINE RELEVANT LISTS
NEG_SIZE    DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
NEG_EA      DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_SHORT,EA_ABS_LONG,SR_DATA,SR_DATA,SR_DATA
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
    MOVEA.L A5,A2
    ADDA.W  #1,A2
    EOR.L   D2,D2
    MOVE.B  (A2),D2 *Size Code
    ANDI.B  #$C0,D2
    LSR.B   #4,D2
    LEA     SR_DATA,A3
    CMPA.L  NEG_SIZE(PC,D2),A3
    BEQ     SR_DATA
    
    EOR.L   D3,D3
    EOR.L   D4,D4
    MOVE.B  (A2),D3 *Move OPWORD to D3
    MOVE.B  D3,D4   *MOVE OPWORD to D4
    ANDI.B  #$38,D3 *Bitmask EA Mode
    ANDI.B  #$07,D4 *Bitmask EA Register
    LSR.B   #1,D3
    LSL.B   #2,D4
    
    CMP.B   #$1C,D3
    BNE     SR_NEG_NOT_111
    *MOVE.B  D4,D5
    *LSL.B   #2,D5
    ADD.B   D4,D3            *GOES TO RIGHT SIDE OF TABLE (HAVE TO ADD REGISTERS TO MODE)
    CMPA.L  NEG_EA(PC,D3),A3
    BEQ     SR_DATA
    BRA     SR_NEG_OUT
SR_NEG_NOT_111:
    CMPA.L  NEG_EA(PC,D3),A3  *LEFT SIDE OF TABLE   (REGISTER VALUE IS REGISTER NUMBER)
    BEQ     SR_DATA
SR_NEG_OUT:
        
    *OUTPUT MEMORY ADDRESS AND OPERATION NAME
    MOVE.L  A5,D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVE.B  #14,D0 *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
    TRAP    #15
    MOVE.L  #$094E4547,(A1)
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.B  #$0,(A2)   *ADD FOR NULL TERMINATION
    *MOVE.B  #13,D0
    TRAP    #15         *OUTPUT ASCII 
    EOR.L   D1,D1
    MOVE.W  (A5),D1
    ADDA.W  #2,A5
    MOVE.L  D2,A4
    MOVEA.L NEG_SIZE(A4),A4
    JSR     (A4)
    MOVE.L  D3,A4
    MOVEA.L NEG_EA(A4),A4
    EOR.L   D5,D5     
    JSR     (A4)
    
    
    *MOVE ADDRESS POINTER TO NEXT OPWORD
    *ADDA.W  #2,A5
    *OUTPUT FINAL CR,LF
    LEA STRHEXOUT,A1
    MOVE.B  #14,D0
    MOVE.L  #$0D0A0000,(A1)   *ASCII for CR,LF,0
    TRAP    #15
    
    *RTS
    RTS  
    
    
*OR SUBROUTINE
*______________
SR_OR:
OR_SIZE   DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
OR_EA_SRC DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_SHORT,EA_ABS_LONG,SR_DATA,SR_DATA,EA_IMM
OR_EA_DST DC.L    SR_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_SHORT,EA_ABS_LONG,SR_DATA,SR_DATA,SR_DATA       
        *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
        LEA OP_BUFFER,A0
        MOVEA.L A5,A2
        EOR.L   D2,D2
        MOVE.W  (A2),D2                                
        ANDI.W  #$01C0,D2
        LSR.L   #4,D2
        MOVE.W  D2,D3
        ANDI.W  #$000C,D2
        LEA SR_DATA, A3
        MOVE.L D2,A1
        CMPA.L OR_SIZE(A1),A3
        BEQ    SR_OR_INVALID
        MOVE.L OR_SIZE(A1),(A0)+
        
        
        ANDI.W  #$0010,D3
        CMP.W   #$0000,D3
        BEQ     SR_OR_DST_EA
        LEA     EA_DATA,A1
        MOVE.L  A1,(A0)+
        MOVE.W  (A2),D4
        ANDI.W  #$0E00,D4 *Bitmask EA Register
        LSR.L   #7,D4
        MOVE.L  D4,(A0)+
  
        EOR.L   D3,D3
        EOR.L   D4,D4
        MOVE.W  (A2),D3 *Move OPWORD to D3
        MOVE.W  D3,D4   *MOVE OPWORD to D4
        ANDI.W  #$0038,D3 *Bitmask EA Mode
        ANDI.W  #$0007,D4 *Bitmask EA Register
        LSR.L   #1,D3
        LSL.L   #2,D4
        MOVE.L  #1,D5
        CMP.L   #$1C,D3
        BNE     SR_OR_DST_DN_NOT_111
        ADD.B   D4,D3 
        CMP.B   #44,D3
        BGT     SR_DATA           *GOES TO RIGHT SIDE OF TABLE (HAVE TO ADD REGISTERS TO MODE)
        MOVE.L  D3,A1
        CMPA.L  OR_EA_DST(A1),A3
        BEQ     SR_OR_INVALID
        MOVE.L  OR_EA_DST(A1),(A0)+
        MOVE.L  D4,(A0)+
        BRA     SR_OR_OUT
SR_OR_DST_DN_NOT_111:
        MOVE.L  D3,A1
        CMPA.L  OR_EA_DST(A1),A3  *LEFT SIDE OF TABLE   (REGISTER VALUE IS REGISTER NUMBER)
        BEQ     SR_OR_INVALID
        MOVE.L  OR_EA_DST(A1),(A0)+
        MOVE.L  D4,(A0)+
        BRA     SR_OR_OUT
SR_OR_DST_EA:
 
        EOR.L   D3,D3
        EOR.L   D4,D4
        MOVE.W  (A2),D3 *Move OPWORD to D3
        MOVE.W  D3,D4   *MOVE OPWORD to D4
        ANDI.W  #$0038,D3 *Bitmask EA Mode
        ANDI.W  #$0007,D4 *Bitmask EA Register
        LSR.L   #1,D3
        LSL.L   #2,D4
    
        CMP.L   #$1C,D3
        BNE     SR_OR_DST_EA_NOT_111
        ADD.B   D4,D3 
        CMP.B   #44,D3
        BGT     SR_DATA           *GOES TO RIGHT SIDE OF TABLE (HAVE TO ADD REGISTERS TO MODE)
        MOVE.L  D3,A1
        CMPA.L  OR_EA_SRC(A1),A3
        BEQ     SR_OR_INVALID
        MOVE.L  OR_EA_SRC(A1),(A0)+
        MOVE.L  D4,(A0)+
        BRA     SR_OR_DST_EA_2
SR_OR_DST_EA_NOT_111:
        MOVE.L  D3,A1
        CMPA.L  OR_EA_SRC(A1),A3  *LEFT SIDE OF TABLE   (REGISTER VALUE IS REGISTER NUMBER)
        BEQ     SR_OR_INVALID
        MOVE.L  OR_EA_SRC(A1),(A0)+
        MOVE.L  D4,(A0)+
SR_OR_DST_EA_2:
        LEA     EA_DATA,A1
        MOVE.L  A1,(A0)+
        MOVE.W  (A2),D4
        ANDI.W  #$0E00,D4 *Bitmask EA Register
        LSR.L   #7,D4
        MOVE.L  D4,(A0)+
        EOR.L   D5,D5

SR_OR_OUT        
        MOVE.L  A5,D1
        JSR     HEX_STRING_L
        LEA     STRHEXOUT,A1
        MOVE.B  #14,D0          *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
        TRAP    #15
        MOVE.L #$094F5200,(A1) *stores "OR" IN ASCI, WITH SPACE AT END
        TRAP    #15
        
        EOR.L   D1,D1
        MOVE.W  (A5),D1
        ADDA.W  #2,A5
        LEA     OP_BUFFER,A0
        MOVE.L  (A0)+,A1
        JSR     (A1)
        
        *EOR.L   D5,D5
        MOVE.B  #1,D6
        MOVE.L  (A0)+,A1
        ADDA.W  #4,A0
        JSR     (A1)
        
        CMP.B   #1,D5
        BEQ     SR_OR_OUT_2
        MOVE.B  #2,D5
SR_OR_OUT_2:
        SUBQ    #1,D5
        EOR.L   D6,D6
        MOVE.L  (A0),A1
        JSR     (A1)
        
        LEA STRHEXOUT,A1
        MOVE.B  #14,D0
        MOVE.L  #$0D0A0000,(A1)   *ASCII for CR,LF,0
        TRAP    #15
        RTS
        
SR_OR_INVALID:
        *MOVE.L  (sp)+,D0
        ADDA.W  #4,sp *Reset the Stack location to not include the jump to this location.
        JMP    N_OR
  
    

*ORI SUBROUTINE
*______________
SR_ORI:
ORI_SIZE   DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
ORI_EA DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_SHORT,EA_ABS_LONG,SR_DATA,SR_DATA,SR_DATA     
        *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
        LEA OP_BUFFER,A0
        MOVEA.L A5,A2
        EOR.L   D2,D2
        MOVE.W  (A2),D2                                *Validation 
        ANDI.W  #$00C0,D2
        LSR.L   #4,D2
        MOVE.W  D2,D3
        LEA SR_DATA, A3
        MOVE.L D2,A1
        MOVE.L ORI_SIZE(A1),(A0)+
        
        LEA     EA_IMM,A1
        MOVE.L  A1,(A0)+
        MOVE.W  (A2),D4
        ANDI.W  #$000E,D4 *Bitmask EA Register
        LSL.L   #2,D4
        MOVE.L  D4,(A0)+

  
        EOR.L   D3,D3
        EOR.L   D4,D4
        MOVE.W  (A2),D3 *Move OPWORD to D3
        MOVE.W  D3,D4   *MOVE OPWORD to D4
        ANDI.W  #$0038,D3 *Bitmask EA Mode
        ANDI.W  #$0007,D4 *Bitmask EA Register
        LSR.L   #1,D3
        LSL.L   #2,D4
    
        CMP.L   #$1C,D3
        BNE     SR_ORI_EA_NOT_111
        ADD.B   D4,D3 
        CMP.B   #44,D3
        BGT     SR_DATA           *GOES TO RIGHT SIDE OF TABLE (HAVE TO ADD REGISTERS TO MODE)
        MOVE.L  D3,A1
        CMPA.L  ORI_EA(A1),A3
        BEQ     SR_ORI_INVALID
        MOVE.L  ORI_EA(A1),(A0)+
        MOVE.L  D4,(A0)+
        BRA     SR_ORI_OUT
SR_ORI_EA_NOT_111:
        MOVE.L  D3,A1
        CMPA.L  ORI_EA(A1),A3  *LEFT SIDE OF TABLE   (REGISTER VALUE IS REGISTER NUMBER)
        BEQ     SR_ORI_INVALID
        MOVE.L  ORI_EA(A1),(A0)+
        MOVE.L  D4,(A0)+

SR_ORI_OUT        
        MOVE.L  A5,D1
        JSR     HEX_STRING_L
        LEA     STRHEXOUT,A1
        MOVE.B  #14,D0          *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
        TRAP    #15
        MOVE.L  #$094F5249,(A1) *Store hex value of ASCII output
        MOVEA.L A1,A2
        ADDA.W  #4,A2
        MOVE.W  #$0000,(A2)     *Last 2 values of ASCII (since 4 letter OP)
        TRAP    #15
        
        EOR.L   D1,D1
        MOVE.W  (A5),D1
        ADDA.W  #2,A5
        LEA     OP_BUFFER,A0
        MOVE.L  (A0)+,A1
        JSR     (A1)
        
        MOVE.L  #0,D5
        MOVE.B  #1,D6
        MOVE.L  (A0)+,A1
        ADDA.W  #4,A0
        JSR     (A1)
        
        *EOR.L   D5,D5
        MOVE.L  #1,D5
        EOR.L   D6,D6
        MOVE.L  (A0),A1
        JSR     (A1)
        
        LEA STRHEXOUT,A1
        MOVE.B  #14,D0
        MOVE.L  #$0D0A0000,(A1)   *ASCII for CR,LF,0
        TRAP    #15
        RTS
        
SR_ORI_INVALID:
        *MOVE.L  (sp)+,D0
        ADDA.W  #4,sp *Reset the Stack location to not include the jump to this location.
        JMP    N_ORI
*EOR SUBROUTINE
*______________
SR_EOR:
EOR_SIZE   DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
EOR_EA_SRC DC.L    EA_DATA,EA_ADDR,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_SHORT,EA_ABS_LONG,SR_DATA,SR_DATA,EA_IMM
EOR_EA_DST DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_SHORT,EA_ABS_LONG,SR_DATA,SR_DATA,SR_DATA       
        *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
        LEA OP_BUFFER,A0
        MOVEA.L A5,A2
        EOR.L   D2,D2
        MOVE.W  (A2),D2                                *Validation
        ANDI.W  #$01C0,D2
        LSR.L   #4,D2
        MOVE.W  D2,D3
        ANDI.W  #$000C,D2
        LEA SR_DATA, A3
        MOVE.L D2,A1
        CMPA.L EOR_SIZE(A1),A3
        BEQ    SR_EOR_INVALID
        MOVE.L EOR_SIZE(A1),(A0)+
        
        ANDI.W  #$0010,D3
        CMP.W   #$0000,D3
        BEQ     SR_EOR_DST_EA
        LEA     EA_DATA,A1
        MOVE.L  A1,(A0)+
        MOVE.W  (A2),D4
        ANDI.W  #$0E00,D4 *Bitmask EA Register
        LSR.L   #7,D4
        MOVE.L  D4,(A0)+
  
        EOR.L   D3,D3
        EOR.L   D4,D4
        MOVE.W  (A2),D3 *Move OPWORD to D3
        MOVE.W  D3,D4   *MOVE OPWORD to D4
        ANDI.W  #$0038,D3 *Bitmask EA Mode
        ANDI.W  #$0007,D4 *Bitmask EA Register
        LSR.L   #1,D3
        LSL.L   #2,D4
        MOVE.L  #1,D5
        CMP.L   #$1C,D3
        BNE     SR_EOR_DST_DN_NOT_111
        ADD.B   D4,D3 
        CMP.B   #44,D3
        BGT     SR_DATA           *GOES TO RIGHT SIDE OF TABLE (HAVE TO ADD REGISTERS TO MODE)
        MOVE.L  D3,A1
        CMPA.L  EOR_EA_DST(A1),A3
        BEQ     SR_EOR_INVALID
        MOVE.L  EOR_EA_DST(A1),(A0)+
        MOVE.L  D4,(A0)+
        BRA     SR_EOR_OUT
SR_EOR_DST_DN_NOT_111:
        MOVE.L  D3,A1
        CMPA.L  EOR_EA_DST(A1),A3  *LEFT SIDE OF TABLE   (REGISTER VALUE IS REGISTER NUMBER)
        BEQ     SR_EOR_INVALID
        MOVE.L  EOR_EA_DST(A1),(A0)+
        MOVE.L  D4,(A0)+
        BRA     SR_EOR_OUT
SR_EOR_DST_EA:  
        EOR.L   D3,D3
        EOR.L   D4,D4
        MOVE.W  (A2),D3 *Move OPWORD to D3
        MOVE.W  D3,D4   *MOVE OPWORD to D4
        ANDI.W  #$0038,D3 *Bitmask EA Mode
        ANDI.W  #$0007,D4 *Bitmask EA Register
        LSR.L   #1,D3
        LSL.L   #2,D4
    
        CMP.L   #$1C,D3
        BNE     SR_SUB_DST_EA_NOT_111
        ADD.B   D4,D3 
        CMP.B   #44,D3
        BGT     SR_DATA           *GOES TO RIGHT SIDE OF TABLE (HAVE TO ADD REGISTERS TO MODE)
        MOVE.L  D3,A1
        CMPA.L  EOR_EA_SRC(A1),A3
        BEQ     SR_EOR_INVALID
        MOVE.L  EOR_EA_SRC(A1),(A0)+
        MOVE.L  D4,(A0)+
        BRA     SR_EOR_DST_EA_2
SR_EOR_DST_EA_NOT_111:
        MOVE.L  D3,A1
        CMPA.L  EOR_EA_SRC(A1),A3  *LEFT SIDE OF TABLE   (REGISTER VALUE IS REGISTER NUMBER)
        BEQ     SR_EOR_INVALID
        MOVE.L  EOR_EA_SRC(A1),(A0)+
        MOVE.L  D4,(A0)+
SR_EOR_DST_EA_2:
        LEA     EA_DATA,A1
        MOVE.L  A1,(A0)+
        MOVE.W  (A2),D4
        ANDI.W  #$0E00,D4 *Bitmask EA Register
        LSR.L   #7,D4
        MOVE.L  D4,(A0)+
        MOVE.L  #0,D5

SR_EOR_OUT        
        MOVE.L  A5,D1
        JSR     HEX_STRING_L
        LEA     STRHEXOUT,A1
        MOVE.B  #14,D0          *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
        TRAP    #15
        MOVE.L  #$09454F52,(A1) *Store hex value of ASCII output
        MOVEA.L A1,A2
        ADDA.W  #4,A2
        MOVE.W  #$00,(A2)        *Last 2 values of ASCII (since 4 letter OP)
        TRAP    #15
        
        EOR.L   D1,D1            *Clears D1
        MOVE.W  (A5),D1
        ADDA.W  #2,A5
        LEA     OP_BUFFER,A0
        MOVE.L  (A0)+,A1
        JSR     (A1)
        
        
        MOVE.B  #1,D6
        MOVE.L  (A0)+,A1
        ADDA.W  #4,A0
        JSR     (A1)
        
        CMP.B   #1,D5
        BEQ     SR_EOR_OUT_2
        MOVE.B  #2,D5
SR_EOR_OUT_2:
        SUBQ    #1,D5
        EOR.L   D6,D6
        MOVE.L  (A0),A1
        JSR     (A1)
        
        LEA STRHEXOUT,A1
        MOVE.B  #14,D0
        MOVE.L  #$0D0A0000,(A1)   *ASCII for CR,LF,0
        TRAP    #15
        RTS
        
SR_EOR_INVALID:
        ADDA.W  #4,sp *Reset the Stack location to not include the jump to this location.
        JMP    N_EOR    

*LS SUBROUTINE
*______________
SR_LS:
LS_SIZE    DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
LS_EA      DC.L    SR_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_LONG,EA_ABS_SHORT,SR_DATA,SR_DATA,SR_DATA
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
    MOVEA.L A5,A2
    MOVE.W  (A2),D2
    AND.W   #$00C0,D2
    LEA     OP_BUFFER,A0
    CMP.W   #$00C0,D2
    BEQ     SR_LS_EA
    
    LSR.L   #4,D2
    MOVE.W  D2,D3
    LEA     SR_DATA, A3
    MOVE.L  D2,A1
    CMPA.L  LS_SIZE(A1),A3
    BEQ     SR_LS_INVALID
    MOVE.L  LS_SIZE(A1),(A0)+
    JSR     SR_LS_OUT_1
    MOVE.W  (A5),D2
    ANDI.W  #$0020,D2
    CMP.W   #$0020,D2
    BEQ     SR_LS_DATA
    LEA     STRHEXOUT,A1
    MOVE.B  #$23,(A1)+
    MOVE.W  (A5),D2
    ANDI.W  #$0E00,D2
    MOVE.B  #9,D0
    LSR.L   D0,D2
    CMP.W   #0,D2
    BNE     SR_LS_IMM_N0
    MOVE.B  #8,D2
SR_LS_IMM_N0:
    ADDI.B  #$30,D2
    MOVE.B  D2,(A1)+
    MOVE.W  #$2C00,(A1)
    MOVE.B  #14,D0
    LEA     STRHEXOUT,A1
    TRAP    #15
    MOVE.W  (A5),D1
    EOR.L   D5,D5
    EOR.L   D6,D6
    JSR     EA_DATA
    ADDA.W  #2,A5
    BRA     SR_LS_OUT_2
SR_LS_DATA:
    MOVE.B  #1,D5
    MOVE.B  #1,D6
    JSR     EA_DATA
    EOR.L   D5,D5
    EOR.L   D6,D6
    JSR     EA_DATA
    ADDA.W  #2,A5
    BRA     SR_LS_OUT_2
SR_LS_EA: 
    LEA SIZE_WORD,A3
    MOVE.L A3,(A0)+
    JSR SR_LS_OUT_1
    
    
    EOR.L   D3,D3
    EOR.L   D4,D4
    MOVE.W  (A5),D3 *Move OPWORD to D3
    MOVE.W  D3,D4   *MOVE OPWORD to D4
    ANDI.W  #$0038,D3 *Bitmask EA Mode
    ANDI.W  #$0007,D4 *Bitmask EA Register
    LSR.L   #1,D3
    LSL.L   #2,D4
    
    CMP.L   #$1C,D3
    BNE     SR_LS_EA_NOT_111
    ADD.B   D4,D3 
    CMP.B   #44,D3
    BGT     SR_DATA           *GOES TO RIGHT SIDE OF TABLE (HAVE TO ADD REGISTERS TO MODE)
    MOVE.L  D3,A1
    CMPA.L  LS_EA(A1),A3
    BEQ     SR_LS_INVALID
    MOVE.L  LS_EA(A1),(A0)+
    MOVE.L  D4,(A0)+
    BRA     SR_LS_EA_OUT
SR_LS_EA_NOT_111:
    MOVE.L  D3,A1
    CMPA.L  LS_EA(A1),A3  *LEFT SIDE OF TABLE   (REGISTER VALUE IS REGISTER NUMBER)
    BEQ     SR_LS_INVALID
    MOVE.L  LS_EA(A1),(A0)
SR_LS_EA_OUT:
    EOR.L   D6,D6
    EOR.L   D5,D5
    ADDA.W  #2,A5
    MOVE.L  (A0),A1
    JSR     (A1)
    BRA     SR_LS_OUT_2
    
SR_LS_OUT_1:
    MOVE.L  A5,D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVE.B  #14,D0          *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
    TRAP    #15
    MOVE.L  #$094C5300,(A1) *Store hex value of ASCII output
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.W  #$0000,(A2)     *Last 2 values of ASCII (since 4 letter OP)
    MOVEA.L A1,A2
    ADDA.W  #3,A2
    MOVE.W  (A5),D1
    ANDI.W  #$0100,D1
    CMPI.W  #$0100,D1
    BEQ SR_LS_L
    MOVE.B  #$52,(A2)
    BRA SR_LS_OUT_3
SR_LS_L:
    MOVE.B  #$4C,(A2)
SR_LS_OUT_3:
    TRAP    #15
       
    EOR.L   D1,D1
    MOVE.W  (A5),D1
    LEA     OP_BUFFER,A0
    MOVE.L  (A0)+,A1
    JSR     (A1)
    RTS

SR_LS_OUT_2:
    LEA STRHEXOUT,A1
    MOVE.B  #14,D0
    MOVE.L  #$0D0A0000,(A1)   *ASCII for CR,LF,0
    TRAP    #15
    RTS
SR_LS_INVALID:
    ADDA.W  #4,sp *Reset the Stack location to not include the jump to this location.
    JMP    SR_DATA

*AS SUBROUTINE
*______________
SR_AS:
AS_SIZE    DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
AS_EA      DC.L    SR_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_LONG,EA_ABS_SHORT,SR_DATA,SR_DATA,SR_DATA
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
    MOVEA.L A5,A2
    MOVE.W  (A2),D2
    AND.W   #$00C0,D2
    LEA     OP_BUFFER,A0
    CMP.W   #$00C0,D2
    BEQ     SR_AS_EA
    
    LSR.L   #4,D2
    MOVE.W  D2,D3
    LEA     SR_DATA, A3
    MOVE.L  D2,A1
    CMPA.L  AS_SIZE(A1),A3
    BEQ     SR_AS_INVALID
    MOVE.L  AS_SIZE(A1),(A0)+
    JSR     SR_AS_OUT_1
    MOVE.W  (A5),D2
    ANDI.W  #$0020,D2
    CMP.W   #$0020,D2
    BEQ     SR_AS_DATA
    LEA     STRHEXOUT,A1
    MOVE.B  #$23,(A1)+
    MOVE.W  (A5),D2
    ANDI.W  #$0E00,D2
    MOVE.B  #9,D0
    LSR.L   D0,D2
    CMP.W   #0,D2
    BNE     SR_AS_IMM_N0
    MOVE.B  #8,D2
SR_AS_IMM_N0:
    ADDI.B  #$30,D2
    MOVE.B  D2,(A1)+
    MOVE.W  #$2C00,(A1)
    MOVE.B  #14,D0
    LEA     STRHEXOUT,A1
    TRAP    #15
    MOVE.W  (A5),D1
    EOR.L   D5,D5
    EOR.L   D6,D6
    JSR     EA_DATA
    ADDA.W  #2,A5
    BRA     SR_AS_OUT_2
SR_AS_DATA:
    MOVE.B  #1,D5
    MOVE.B  #1,D6
    JSR     EA_DATA
    EOR.L   D5,D5
    EOR.L   D6,D6
    JSR     EA_DATA
    ADDA.W  #2,A5
    BRA     SR_AS_OUT_2
SR_AS_EA: 
    LEA SIZE_WORD,A3
    MOVE.L A3,(A0)+
    JSR SR_AS_OUT_1
    
    
    EOR.L   D3,D3
    EOR.L   D4,D4
    MOVE.W  (A5),D3 *Move OPWORD to D3
    MOVE.W  D3,D4   *MOVE OPWORD to D4
    ANDI.W  #$0038,D3 *Bitmask EA Mode
    ANDI.W  #$0007,D4 *Bitmask EA Register
    LSR.L   #1,D3
    LSL.L   #2,D4
    
    CMP.L   #$1C,D3
    BNE     SR_AS_EA_NOT_111
    ADD.B   D4,D3 
    CMP.B   #44,D3
    BGT     SR_DATA           *GOES TO RIGHT SIDE OF TABLE (HAVE TO ADD REGISTERS TO MODE)
    MOVE.L  D3,A1
    CMPA.L  AS_EA(A1),A3
    BEQ     SR_AS_INVALID
    MOVE.L  AS_EA(A1),(A0)+
    MOVE.L  D4,(A0)+
    BRA     SR_AS_EA_OUT
SR_AS_EA_NOT_111:
    MOVE.L  D3,A1
    CMPA.L  AS_EA(A1),A3  *LEFT SIDE OF TABLE   (REGISTER VALUE IS REGISTER NUMBER)
    BEQ     SR_AS_INVALID
    MOVE.L  AS_EA(A1),(A0)
SR_AS_EA_OUT:
    EOR.L   D6,D6
    EOR.L   D5,D5
    ADDA.W  #2,A5
    MOVE.L  (A0),A1
    JSR     (A1)
    BRA     SR_AS_OUT_2
    
SR_AS_OUT_1:
    MOVE.L  A5,D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVE.B  #14,D0          *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
    TRAP    #15
    MOVE.L  #$09415300,(A1) *Store hex value of ASCII output
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.W  #$0000,(A2)     *Last 2 values of ASCII (since 4 letter OP)
    MOVEA.L A1,A2
    ADDA.W  #3,A2
    MOVE.W  (A5),D1
    ANDI.W  #$0100,D1
    CMPI.W  #$0100,D1
    BEQ SR_AS_L
    MOVE.B  #$52,(A2)
    BRA SR_AS_OUT_3
SR_AS_L:
    MOVE.B  #$4C,(A2)
SR_AS_OUT_3:
    TRAP    #15
       
    EOR.L   D1,D1
    MOVE.W  (A5),D1
    LEA     OP_BUFFER,A0
    MOVE.L  (A0)+,A1
    JSR     (A1)
    RTS

SR_AS_OUT_2:
    LEA STRHEXOUT,A1
    MOVE.B  #14,D0
    MOVE.L  #$0D0A0000,(A1)   *ASCII for CR,LF,0
    TRAP    #15
    RTS
SR_AS_INVALID:
    ADDA.W  #4,sp *Reset the Stack location to not include the jump to this location.
    JMP    SR_DATA

 
*RO SUBROUTINE
*______________
SR_RO:
RO_SIZE    DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
RO_EA      DC.L    SR_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_LONG,EA_ABS_SHORT,SR_DATA,SR_DATA,SR_DATA
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
    MOVEA.L A5,A2
    MOVE.W  (A2),D2
    AND.W   #$00C0,D2
    LEA     OP_BUFFER,A0
    CMP.W   #$00C0,D2
    BEQ     SR_RO_EA
    
    LSR.L   #4,D2
    MOVE.W  D2,D3
    LEA     SR_DATA, A3
    MOVE.L  D2,A1
    CMPA.L  RO_SIZE(A1),A3
    BEQ     SR_RO_INVALID
    MOVE.L  RO_SIZE(A1),(A0)+
    JSR     SR_RO_OUT_1
    MOVE.W  (A5),D2
    ANDI.W  #$0020,D2
    CMP.W   #$0020,D2
    BEQ     SR_RO_DATA
    LEA     STRHEXOUT,A1
    MOVE.B  #$23,(A1)+
    MOVE.W  (A5),D2
    ANDI.W  #$0E00,D2
    MOVE.B  #9,D0
    LSR.L   D0,D2
    CMP.W   #0,D2
    BNE     SR_RO_IMM_N0
    MOVE.B  #8,D2
SR_RO_IMM_N0:
    ADDI.B  #$30,D2
    MOVE.B  D2,(A1)+
    MOVE.W  #$2C00,(A1)
    MOVE.B  #14,D0
    LEA     STRHEXOUT,A1
    TRAP    #15
    MOVE.W  (A5),D1
    EOR.L   D5,D5
    EOR.L   D6,D6
    JSR     EA_DATA
    ADDA.W  #2,A5
    BRA     SR_RO_OUT_2
SR_RO_DATA:
    MOVE.B  #1,D5
    MOVE.B  #1,D6
    JSR     EA_DATA
    EOR.L   D5,D5
    EOR.L   D6,D6
    JSR     EA_DATA
    ADDA.W  #2,A5
    BRA     SR_RO_OUT_2
SR_RO_EA: 
    LEA SIZE_WORD,A3
    MOVE.L A3,(A0)+
    JSR SR_RO_OUT_1
    
    
    EOR.L   D3,D3
    EOR.L   D4,D4
    MOVE.W  (A5),D3 *Move OPWORD to D3
    MOVE.W  D3,D4   *MOVE OPWORD to D4
    ANDI.W  #$0038,D3 *Bitmask EA Mode
    ANDI.W  #$0007,D4 *Bitmask EA Register
    LSR.L   #1,D3
    LSL.L   #2,D4
    
    CMP.L   #$1C,D3
    BNE     SR_RO_EA_NOT_111
    ADD.B   D4,D3 
    CMP.B   #44,D3
    BGT     SR_DATA           *GOES TO RIGHT SIDE OF TABLE (HAVE TO ADD REGISTERS TO MODE)
    MOVE.L  D3,A1
    CMPA.L  RO_EA(A1),A3
    BEQ     SR_RO_INVALID
    MOVE.L  RO_EA(A1),(A0)+
    MOVE.L  D4,(A0)+
    BRA     SR_RO_EA_OUT
SR_RO_EA_NOT_111:
    MOVE.L  D3,A1
    CMPA.L  RO_EA(A1),A3  *LEFT SIDE OF TABLE   (REGISTER VALUE IS REGISTER NUMBER)
    BEQ     SR_RO_INVALID
    MOVE.L  RO_EA(A1),(A0)
SR_RO_EA_OUT:
    EOR.L   D6,D6
    EOR.L   D5,D5
    ADDA.W  #2,A5
    MOVE.L  (A0),A1
    JSR     (A1)
    BRA     SR_RO_OUT_2
    
SR_RO_OUT_1:
    MOVE.L  A5,D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVE.B  #14,D0          *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
    TRAP    #15
    MOVE.L  #$09524F00,(A1) *Store hex value of ASCII output
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.W  #$0000,(A2)     *Last 2 values of ASCII (since 4 letter OP)
    MOVEA.L A1,A2
    ADDA.W  #3,A2
    MOVE.W  (A5),D1
    ANDI.W  #$0100,D1
    CMPI.W  #$0100,D1
    BEQ SR_RO_L
    MOVE.B  #$52,(A2)
    BRA SR_RO_OUT_3
SR_RO_L:
    MOVE.B  #$4C,(A2)
SR_RO_OUT_3:
    TRAP    #15
       
    EOR.L   D1,D1
    MOVE.W  (A5),D1
    LEA     OP_BUFFER,A0
    MOVE.L  (A0)+,A1
    JSR     (A1)
    RTS

SR_RO_OUT_2:
    LEA STRHEXOUT,A1
    MOVE.B  #14,D0
    MOVE.L  #$0D0A0000,(A1)   *ASCII for CR,LF,0
    TRAP    #15
    RTS
SR_RO_INVALID:
    ADDA.W  #4,sp *Reset the Stack location to not include the jump to this location.
    JMP    SR_DATA

*BCC SUBROUTINE
*______________
SR_BCC:
BCC_CODE    DC.L    $0000,$0000,$0000,$0000,CC,CS,EQ,GE,GT,HI,LE,LS1,LT,MI,NE,PL,VC,VS                   
        MOVE.L  A5,D1
        JSR     HEX_STRING_L
        LEA     STRHEXOUT,A1
        MOVE.B  #14,D0          *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
        TRAP    #15
        MOVE.L  #$09420000,(A1) *Store hex value of ASCII output
        MOVEA.L A1,A2
        ADDA.W  #2,A2
        EOR.L   D1,D1
        MOVE.W  (A5),D1
        ANDI.W  #$0F00,D1
        EOR.L   D2,D2
        MOVE.B  #6,D2
        LSR.W   D2,D1
        LEA  BCC_CODE(PC,D1),A3
        MOVE.L  (A3),D2
        MOVE.W  D2,(A2)
        ADDA.W  #2,A2
        MOVE.W  #$0900,(A2)     *Last 2 values of ASCII (since 4 letter OP)
        TRAP    #15
        
        MOVE.W  (A5),D1
        ANDI.W  #$00FF,D1
        CMPI.B  #00,D1
        BEQ     SR_BCC_WORD
        MOVE.L  A5,A1
        ADDA.L  D1,A1
        MOVE.L  A1,D1
        JSR     HEX_STRING_L
        LEA     STRHEXOUT,A1
        SUBQ    #1,A1
        MOVE.B  #$24,(A1)
        MOVE.B  #14,D0
        TRAP    #15
        ADDA.W  #2,A5
        BRA     SR_BCC_OUT
        
SR_BCC_WORD
        MOVE.L  A5,A2
        ADDA.L  #2,A2
        MOVE.W  (A2),D2
        MOVE.L  A5,A2
        ADDA.L  D2,A2
        MOVE.L  A1,D1
        JSR     HEX_STRING_L
        LEA     STRHEXOUT,A1
        SUBQ    #1,A1
        MOVE.B  #24,(A1)
        MOVE.B  #14,D0
        ADDA.W  #4,A5
        TRAP    #15
        
SR_BCC_OUT       
        LEA STRHEXOUT,A1
        MOVE.B  #14,D0
        MOVE.L  #$0D0A0000,(A1)   *ASCII for CR,LF,0
        TRAP    #15
        
        RTS

  
  
*BCLR SUBROUTINE
*______________
SR_BCLR:
BCLR_SIZE    DC.L    SIZE_BYTE,SIZE_LONG,SR_DATA
BCLR_EA      DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_SHORT,EA_ABS_LONG,SR_DATA,SR_DATA,EA_IMM
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)   
    LEA OP_BUFFER,A0
    MOVEA.L A5,A2
    EOR.L D2,D2
    MOVE.W (A2),D2                                 
    ANDI.W #$0038,D2      
    LSR.L  #3,D2
    CMP.B  #0,D2
    BEQ    BCLR_SIZE_LONG
    MOVE.B #0,D2
    BRA BCLR_SIZE_2
BCLR_SIZE_LONG:
    MOVE.B #4,D2
BCLR_SIZE_2:
    LEA SR_DATA,A3
    MOVE.L D2,A1
    CMPA.L BCLR_SIZE(A1),A3
    BEQ    SR_BCLR_INVALID
    MOVE.L BCLR_SIZE(A1),(A0)+  

    ********************
    *EA MODE CALCULATION
    ******************
    EOR.L   D3,D3
    EOR.L   D4,D4
    MOVE.W  (A2),D3   *Move OPWORD to D3
    MOVE.W  D3,D4     *MOVE OPWORD to D4
    ANDI.W  #$0038,D3 *Bitmask EA Mode
    ANDI.W  #$0007,D4 *Bitmask EA Register
    LSR.L   #1,D3
    LSL.L   #2,D4

    CMP.L   #$1C,D3
    BNE     SR_BCLR_NOT_111
    ADD.B   D4,D3            *GOES TO RIGHT SIDE OF TABLE (HAVE TO ADD REGISTERS TO MODE)

    CMP.B   #44,D3
    BGT     SR_DATA
    MOVE.L  D3,A1
    CMPA.L  BCLR_EA(A1),A3
    BEQ     SR_BCLR_INVALID
    MOVE.L  BCLR_EA(A1),(A0)+
    MOVE.L  D4,(A0)+
    BRA     SR_BCLR_OUT   
       
SR_BCLR_NOT_111:      
    MOVE.L  D3,A1
    CMPA.L  BCLR_EA(A1),A3  *LEFT SIDE OF TABLE   (REGISTER VALUE IS REGISTER NUMBER)
    BEQ     SR_BCLR_INVALID
    MOVE.L  BCLR_EA(A1),(A0)+
    MOVE.L  D4,(A0)+
       
    ******************
    *PRINT OUT
    ******************

SR_BCLR_OUT:     
    MOVE.L  A5,D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVE.B  #14,D0           *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
    TRAP    #15
    MOVE.L  #$0942434C,(A1)  *Store hex value of ASCII output
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.W  #$5200,(A2)      *Last value of ASCII (since 4 letter OP)
    TRAP    #15
    
    EOR.L   D1,D1
    MOVE.W  (A5),D1
    
    LEA     OP_BUFFER,A0
    MOVE.L  (A0)+,A1
    JSR     (A1)

    MOVE.W  (A5),D1
    ANDI.W  #$01C0,D1
    CMP.W   #$0080,D1
    BEQ     SR_BCLR_IMM
SR_BCLR_DATA:
    MOVE.L  #1,D5
    MOVE.L  #1,D6
    MOVE.W  (A5),D1
    JSR     EA_DATA
    ADDA.W  #2,A5
    BRA SR_BCLR_OUT_2
SR_BCLR_IMM:
    MOVE.W  (A5),D1
    ADDA.W  #2,A5
    MOVE.L  #1,D6
    LEA     OP_BUFFER,A2
    LEA     SIZE_BYTE,A3
    MOVE.L  A3,(A2)
    JSR     EA_IMM
SR_BCLR_OUT_2:

    
  
    EOR.L   D5,D5
    EOR.L   #1,D6
    MOVE.L  (A0),A1
    ADDA.W  #4,A0
    JSR     (A1)
        
    LEA STRHEXOUT,A1
    MOVE.B  #14,D0
    MOVE.L  #$0D0A0000,(A1)   *ASCII for CR,LF,0
    TRAP    #15

    RTS
   
SR_BCLR_INVALID:
        ADDA.W  #4,sp *Reset the Stack location to not include the jump to this location.
        JMP    N_BCLR 
 
    
    
*BRA SUBROUTINE
*______________
SR_BRA:
BRA_SIZE    DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
BRA_EA      DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_LONG,EA_ABS_SHORT,SR_DATA,SR_DATA,SR_DATA
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
    MOVEA.L A5,A2
    ADDA.W #1,A2
    EOR.L D2,D2
    MOVE.B (A2),D2
    ANDI.B #$C0,D2                      *UPDATE VALIDITY 
    LSR.B  #4,D2                 
    LEA SR_DATA, A3
    CMPA.L BRA_SIZE(PC,D2),A3
    BEQ    SR_DATA
    BRA SR_BRA_OUT
    ********************
    *EA MODE CALCULATION
    ******************
    EOR.L   D3,D3
    EOR.L   D4,D4
    MOVE.B  (A2),D3 *Move OPWORD to D3
    MOVE.B  D3,D4   *MOVE OPWORD to D4
    ANDI.B  #$38,D3 *BITMASK TO FIND EA MODE
    ANDI.B  #$07,D4 *BITMASK TO FIND REGISTER VALUE
        
    ******************
    *PRINT OUT
    ******************
SR_BRA_OUT        
    MOVE.L  A5,D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVE.B  #14,D0 *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
    TRAP    #15
    MOVE.L  #$09425241,(A1) 
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.B  #$0,(A2)
    TRAP    #15
    MOVE.L  D2,A4
    MOVEA.L BRA_SIZE(A4),A4
    JSR     (A4)
        
    ************************
    * GET EA TO PRINT OUT
    ************************
    *MOVE ADDRESS POINTER TO NEXT OPWORD
    ADDA.W  #4,A5
    *OUTPUT FINAL CR,LF
    LEA STRHEXOUT,A1
    MOVE.B  #14,D0
    MOVE.L  #$0D0A0000,(A1)
    TRAP    #15

    RTS 
  
    
    
*JSR SUBROUTINE                              *NOT SURE IF THIS IS RIGHT 
*______________
SR_JSR:
JSR_EA      DC.L    SR_DATA,SR_DATA,EA_ADDRIND,SR_DATA,SR_DATA,SR_DATA,SR_DATA,EA_ABS_SHORT,EA_ABS_LONG,SR_DATA,SR_DATA,SR_DATA    
    
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
    MOVEA.L A5,A2
    ADDA.W #1,A2
    EOR.L D2,D2
    MOVE.B (A2),D2
    ANDI.B #$38,D2                     *VALIDATING FOR EAMODE BITS 
    LSR.B  #1,D2
    LEA SR_DATA, A3
    CMPA.L JSR_EA(PC,D2),A3
    BEQ    SR_DATA

    ********************
    *EA MODE CALCULATION
    ******************
    MOVEA.L A5,A2
    LEA     OP_BUFFER,A0
    EOR.L   D3,D3
    EOR.L   D4,D4
    MOVE.W  (A2),D3 *Move OPWORD to D3
    MOVE.W  D3,D4   *MOVE OPWORD to D4
    ANDI.W  #$0038,D3 *Bitmask EA Mode
    ANDI.W  #$0007,D4 *Bitmask EA Register
    LSR.L   #1,D3
    LSL.L   #2,D4
    
    CMP.L   #$1C,D3
    BNE     SR_JSR_DST_EA_NOT_111
    ADD.B   D4,D3 
    CMP.B   #44,D3
    BGT     SR_DATA           *GOES TO RIGHT SIDE OF TABLE (HAVE TO ADD REGISTERS TO MODE)
    MOVE.L  D3,A1
    CMPA.L  JSR_EA(A1),A3
    BEQ     SR_DATA
    MOVE.L  JSR_EA(A1),(A0)
    BRA     SR_JSR_OUT
SR_JSR_DST_EA_NOT_111:
    MOVE.L  D3,A1
    CMPA.L  JSR_EA(A1),A3  *LEFT SIDE OF TABLE   (REGISTER VALUE IS REGISTER NUMBER)
    BEQ     SR_DATA
    MOVE.L  JSR_EA(A1),(A0)


   
    ******************
    *PRINT OUT
    ******************
SR_JSR_OUT        
    MOVE.L  A5,D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVE.B  #14,D0 *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
    TRAP    #15
    MOVE.L  #$094A5352,(A1) 
    MOVEA.L A1,A2
    ADDA.W  #2,A5
    ADDA.W  #4,A2
    MOVE.W  #$0900,(A2)
    TRAP    #15
    MOVE.L  D2,A4
    MOVE.L  (A0),A4
    JSR     (A4)
        
    ************************
    * GET EA TO PRINT OUT
    ************************
    *MOVE ADDRESS POINTER TO NEXT OPWORD
    
    *OUTPUT FINAL CR,LF
    LEA STRHEXOUT,A1
    MOVE.B  #14,D0
    MOVE.L  #$0D0A0000,(A1)
    TRAP    #15

    RTS 
    
    
*RTS SUBROUTINE
*______________
SR_RTS:
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JSR to DATA and then RTS here.)
        *Reading OPWORD is pointless here, so it is skipped
        *As this must be exactly NOP to get here, no validation is necessary.
    
    *OUTPUT MEMORY ADDRESS AND OPERATION NAME
    MOVE.L  A5,D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVE.B  #14,D0 *TRAP TASK 14, Output A1 with no Carriage Return of Line Feed
    TRAP    #15
    *MOVE.L  #$094E4F50,(A1)
    MOVE.L  #$09525453,(A1)
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.B  #$0,(A2)
    MOVE.B  #13,D0
    TRAP    #15
    
    *BRANCH FOR <EA> MODE AND OUTPUT ARGUMENTS
        *No branching is necessary as there are no arguments for RTS  
  
    *MOVE ADDRESS POINTER TO NEXT OPWORD
    ADDA.W  #2,A5
    
    *RTS
    RTS       


*DATA SUBROUTINE
*_______________ 
SR_DATA:  
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JSR to DATA and then RTS here.)
        *Reading OPWORD is pointless here, so it is skipped
        *DATA requires no validation as it is, well Data.
    
    *OUTPUT MEMORY ADDRESS AND OPERATION NAME
    MOVE.L  A5,D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVE.B  #14,D0
    TRAP    #15             *Output Address
    MOVE.L  #$09444154,(A1)
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.L  #$41090000,(A2)
    TRAP    #15             *Output Operation name
    
    
    
    *BRANCH FOR <EA> MODE AND OUTPUT ARGUMENTS
        *No EA for DATA, thus no branching here
    MOVE.W  (A5),D1
    SWAP    D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.B  #$0,(A2)
    MOVE.B  #13,D0
    TRAP    #15             *Output Invalid Data found at current working word to terminal
    *MOVE ADDRESS POINTER TO NEXT OPWORD
    ADDA.W  #2,A5
    
    *RTS
    RTS 


size_byte:
            LEA STRHEXOUT,A1
            MOVE.L  #$2E420900,(A1)
            MOVE.B  #14,D0
            TRAP    #15
            RTS
size_long:
            LEA STRHEXOUT,A1
            MOVE.L  #$2E4C0900,(A1)
            MOVE.B  #14,D0
            TRAP    #15
            RTS
size_word:
            LEA STRHEXOUT,A1
            MOVE.L  #$2E570900,(A1) 
            MOVE.B  #14,D0
            TRAP    #15
            RTS

*EFFECTIVE ADDRESSING MODE FOR DATA REGISTER DIRECT
*USES VALUE IN D5 TO CHOOSE 1ST or 2ND ARGUMENT, AND D6 TO OUTPUT COMMA AFTER.
EA_DATA:
    MOVEM.L D0-A6,-(sp)
    LEA STRHEXOUT,A1
    *MOVE.W  (A5),D2
    CMP.B   #1,D5
    BEQ EA_DATA_2ND
    AND.W   #$0007,D1
    BRA EA_DATA_2
EA_DATA_2ND:
    AND.W   #$0E00,D1
    MOVE.B  #9,D0
    LSR.W   D0,D1

EA_DATA_2:
    MOVE.B  #$44,(A1)+
    *ADDA.W  #2,A1
    ADD.B   #$30,D1
    MOVE.B  D1,(A1)+
    *ADDA.W  #2,A1
    CMP.B   #1,D6
    BNE     EA_DATA_NOCOMMA
    MOVE.B  #$2C,(A1)+
EA_DATA_NOCOMMA
    MOVE.B  #0,(A1)
    MOVE.B  #14,D0
    LEA     STRHEXOUT,A1
    TRAP    #15
    MOVEM.L (sp)+,D0-A6
    
    RTS
EA_ADDR:
    MOVEM.L D0-A6,-(sp)
    LEA STRHEXOUT,A1
    *MOVE.W  (A5),D2
    CMP.B   #1,D5
    BEQ EA_ADDR_2ND
    AND.W   #$0007,D1
    BRA EA_ADDR_2
EA_ADDR_2ND:
    AND.W   #$0E00,D1
    MOVE.B  #9,D0
    LSR.W   D0,D1

EA_ADDR_2:
    MOVE.B  #$41,(A1)+
    *ADDA.W  #2,A1
    ADD.B   #$30,D1
    MOVE.B  D1,(A1)+
    *ADDA.W  #2,A1
    CMP.B   #1,D6
    BNE     EA_ADDR_NOCOMMA
    MOVE.B  #$2C,(A1)+
EA_ADDR_NOCOMMA
    MOVE.B  #0,(A1)
    MOVE.B  #14,D0
    LEA     STRHEXOUT,A1
    TRAP    #15
    MOVEM.L (sp)+,D0-A6
    RTS

EA_ADDRIND:
    MOVEM.L D0-A6,-(sp)
    LEA STRHEXOUT,A1
    *MOVE.W  (A5),D2
    CMP.B   #1,D5
    BEQ EA_ADDRIND_2ND
    AND.W   #$0007,D1
    BRA EA_ADDRIND_2
EA_ADDRIND_2ND:
    AND.W   #$0E00,D1
    MOVE.B  #9,D0
    LSR.W   D0,D1

EA_ADDRIND_2:
    MOVE.L  #$28410029,(A1)
    ADDA.W  #2,A1
    ADD.B   #$30,D1
    MOVE.B  D1,(A1)
    ADDA.W  #2,A1
    CMP.B   #1,D6
    BNE     EA_ADDRIND_NOCOMMA
    MOVE.B  #$2C,(A1)+
EA_ADDRIND_NOCOMMA
    MOVE.B  #0,(A1)
    MOVE.B  #14,D0
    LEA     STRHEXOUT,A1
    TRAP    #15
    MOVEM.L (sp)+,D0-A6
    RTS

EA_ADDRIND_PINC:
    MOVEM.L D0-A6,-(sp)
    LEA STRHEXOUT,A1
    *MOVE.W  (A5),D2
    CMP.B   #1,D5
    BEQ EA_ADDRIND_PINC_2ND
    AND.W   #$0007,D1
    BRA EA_ADDRIND_PINC_2
EA_ADDRIND_PINC_2ND:
    AND.W   #$0E00,D1
    MOVE.B  #9,D0
    LSR.W   D0,D1

EA_ADDRIND_PINC_2:
    MOVE.L  #$28410029,(A1)
    ADDA.W  #2,A1
    ADD.B   #$30,D1
    MOVE.B  D1,(A1)
    ADDA.W  #2,A1
    MOVE.B  #$2B,(A1)+
    CMP.B   #1,D6
    BNE     EA_ADDRIND_PINC_NOCOMMA
    MOVE.B  #$2C,(A1)+
EA_ADDRIND_PINC_NOCOMMA
    MOVE.B  #0,(A1)
    MOVE.B  #14,D0
    LEA     STRHEXOUT,A1
    TRAP    #15
    MOVEM.L (sp)+,D0-A6
    RTS

EA_ADDRIND_PDEC:
    MOVEM.L D0-A6,-(sp)
    LEA STRHEXOUT,A1
    *MOVE.W  (A5),D2
    CMP.B   #1,D5
    BEQ EA_ADDRIND_PDEC_2ND
    AND.W   #$0007,D1
    BRA EA_ADDRIND_PDEC_2
EA_ADDRIND_PDEC_2ND:
    AND.W   #$0E00,D1
    MOVE.B  #9,D0
    LSR.W   D0,D1

EA_ADDRIND_PDEC_2:
    MOVE.L  #$2D284100,(A1)
    ADDA.W  #3,A1
    ADD.B   #$30,D1
    MOVE.B  D1,(A1)+
    *ADDA.W  #2,A1
    MOVE.B  #$29,(A1)+
    CMP.B   #1,D6
    BNE     EA_ADDRIND_PDEC_NOCOMMA
    MOVE.B  #$2C,(A1)+
EA_ADDRIND_PDEC_NOCOMMA
    MOVE.B  #0,(A1)
    MOVE.B  #14,D0
    LEA     STRHEXOUT,A1
    TRAP    #15
    MOVEM.L (sp)+,D0-A6
    RTS
EA_ABS_LONG:
    MOVEM.L D0-A4,-(sp)
    LEA STRHEXOUT,A1
    SUBA.W  #1,A1
    MOVE.B  #$24,(A1)+
    MOVE.L  (A5),D1
    JSR HEX_STRING_L
    ADDA.W  #8,A1
    CMP.B   #1,D6
    BNE     EA_ABS_LONG_NOCOMMA
    MOVE.B  #$2C,(A1)+
EA_ABS_LONG_NOCOMMA
    MOVE.B  #0,(A1)
    MOVE.B  #14,D0
    LEA     STRHEXOUT,A1
    SUBA.W  #1,A1
    TRAP    #15
    ADDA.W  #4,A5
    MOVEM.L (sp)+,D0-A4
    RTS
    
EA_ABS_SHORT:
    MOVEM.L D0-A4,-(sp)
    LEA STRHEXOUT,A1
    SUBA.W  #1,A1
    MOVE.B  #$24,(A1)+
    EOR.L   D1,D1
    MOVE.W  (A5),D1
    JSR HEX_STRING_L
    ADDA.W  #4,A1
    MOVE.L  (A1),D4
    CMP.B   #1,D6
    BNE     EA_ABS_SHORT_NOCOMMA
    MOVE.B  #$2C,(A1)+
EA_ABS_SHORT_NOCOMMA
    MOVE.B  #0,(A1)
    MOVE.B  #14,D0
    LEA     STRHEXOUT,A1
    MOVE.L  D4,(A1)
    SUBA.W  #1,A1
    TRAP    #15
    ADDA.W  #2,A5
    MOVEM.L (sp)+,D0-A4
    RTS
*Size (First argument, of the OP_Buffer must be set for EA_IMM!
EA_IMM:
    MOVEM.L D0-A4,-(sp)
    LEA     STRHEXOUT,A1
    SUBA.W  #2,A1
    MOVE.W  #$2324,(A1)
    LEA     OP_BUFFER,A0
    LEA     size_byte,A1
    LEA     size_word,A2
    LEA     size_long,A3
    EOR.L   D1,D1
    CMPA.L  (A0),A1
    BEQ EA_IMM_BYTE
    CMPA.L  (A0),A2
    BEQ EA_IMM_WORD
    CMPA.L  (A0),A3
    BEQ EA_IMM_LONG
    
EA_IMM_BYTE:
    LEA     STRHEXOUT,A1
    MOVE.W  (A5),D1
    JSR     HEX_STRING_L
    ADDA.W  #6,A1
    EOR.L   D2,D2
    MOVE.W  (A1),D2
    *MOVE.L  A1,A2
    LEA     STRHEXOUT,A1
    MOVE.W  D2,(A1)
    ADDA.W  #2,A1
    *MOVEA.L A2,A1
    ADDA.W  #2,A5
    BRA     EA_IMM_OUT
EA_IMM_WORD:
    LEA     STRHEXOUT,A1
    MOVE.W  (A5),D1
    JSR     HEX_STRING_L
    ADDA.W  #4,A1
    MOVEA.L A1,A2
    EOR.L   D2,D2
    MOVE.L  (A1),D2
    LEA     STRHEXOUT,A1
    MOVE.L  D2,(A1)
    MOVEA.L A2,A1
    ADDA.W  #2,A5
    BRA     EA_IMM_OUT
EA_IMM_LONG:
    LEA     STRHEXOUT,A1
    MOVE.L  (A5),D1
    JSR     HEX_STRING_L
    ADDA.W  #8,A1
    ADDA.W  #4,A5
EA_IMM_OUT:
    CMP.B   #1,D6
    BNE     EA_IMM_NOCOMMA
    MOVE.B  #$2C,(A1)+
EA_IMM_NOCOMMA
    MOVE.B  #0,(A1)
    MOVE.B  #14,D0
    LEA     STRHEXOUT,A1
    SUBA.W  #2,A1
    TRAP    #15

    MOVEM.L (sp)+,D0-A4
    RTS
    
            
   
*EXIT
*____
EXIT:
    LEA     STRHEXOUT,A1
    MOVE.L  #$454F4600,(A1)
    MOVE.B  #14,D0
    TRAP    #15
    SIMHALT

    
    
*CONSTANTS AND PARAMETERS
*________________________
CR      EQU    $0D
LF      EQU    $0A
CC      EQU    $4343
CS      EQU    $4353
EQ      EQU    $4551
GE      EQU    $4745
GT      EQU    $4754
HI      EQU    $4849
LE      EQU    $4C45
LS1      EQU    $4C53
LT      EQU    $4C54
MI      EQU    $4D49
NE      EQU    $4E45
PL      EQU    $504C
VC      EQU    $5643
VS      EQU    $5653
                    *SIZE,EA1MODE,EA1REG,EA2MODE,EA2REG
OP_BUFFER   DC.L    $00,$00,$00,$00,$00

ASCII   DC.B    $30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$41,$42,$43,$44,$45,$46
LONGNIBBLEMASK      DC.L    $F0000000
M_INPSTARTRANGE     DC.B    'Enter Start Range of Memory',CR,LF,0
M_INPENDRANGE       DC.B    'Enter End Range of Memory',CR,LF,0
M_INPINVALID        DC.B    'Input is invalid, try again',CR,LF,0
M_HOLD              DC.B    'Press Enter to scroll',0
    ORG     $500
    DC.L    8
    ORG     $520
    DC.L    8
    END     START










*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~




















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
