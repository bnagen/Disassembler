*-----------------------------------------------------------
* Title      : Disassembler Test Program
* Written by : Connor Browne
* Date       : 11/23/18
* Description: Used to test the disassembler program
*-----------------------------------------------------------
    ORG    $7000
START:                  ; first instruction of program

* MOVE
    MOVE.L $1111,A0
    MOVE.B #1,D0
    MOVE.B D0,D1
* MOVEA    
    MOVEA.L A0,A1
    MOVEA.W -(A0),A2
* MOVEM    
    *MOVEM.L A0-A2,$5000
    *MOVEM.L $4980,A0-A2
* ADD and ADDA    
    ADD.B D2,D1
    *ADD.B #100,D1
    ADD.L A2,D1
    ADD.L (A2),D1
    ADD.L (A2)+,D1
    ADD.L -(A2),D1
    ADD.L $1000,D1
    ADD.L $10001000,D1
    ADD.W D2,(A1)
    ADD.W D2,(A1)+
    ADD.W D2,-(A1)
    ADD.W D2,$1000
    ADD.W D2,$10001000
    ADDA.L A2,A1
    ADDA.L D2,A1
    ADDA.W (A2),A1
    ADDA.W (A2)+,A1
    ADDA.W -(A2),A1
    ADDA.W $1000,A1
    ADDA.W $10001000,A1
* SUB and SUBQ    
    SUB.B D2,D1
    SUB.W A2,D1
    SUB.L (A2),D1
    SUB.W (A2)+,D1
    SUB.B -(A2),D1
    SUB.W $2000,D1
    SUB.L $10001000,D1
    
    SUB.B D2,(A1)
    SUB.B D2,(A1)+
    SUB.W D2,-(A1)
    SUB.L D2,$2000
    SUB.L D2,$20010001
    
    SUBQ.B #1,D2
    SUBQ.W #2,A3
    SUBQ.W #3,(A3)
    SUBQ.L #4,(A3)+
    SUBQ.L #5,-(A3)
    SUBQ.L #6,$1000
    SUBQ.L #7,$10001000
    
* MULS    
    MULS.W D1,D2
    MULS.W (A1),D2
    MULS.W (A1)+,D2
    MULS.W -(A1),D2
    MULS.W $1000,D2
    MULS.W $20001000,D2
    MULS.W #$0000FFFF,D2
    MULS.W #4,D2
    
* DIVS    
    DIVS.W D1,D2
    DIVS.W (A1),D2
    DIVS.W (A1)+,D2
    DIVS.W -(A1),D2
    DIVS.W $1000,D2
    DIVS.W $20001000,D2
    DIVS.W #$100,D2
    DIVS.W #2,D0
* LEA
    LEA (A0),A2
    LEA $5000,A2
    LEA $20001000,A2    
* OR
    OR.B D0,D2
    OR.W (A0),D2
    OR.W (A0)+,D2
    OR.W -(A0),D2
    OR.W $1000,D2
    OR.L $20001000,D2
    OR.L #$FFFFFFFF, D2
    OR.B #1,D2
    OR.L D0,(A2)
    OR.L D0,(A2)+
    OR.L D0,-(A2)
    OR.L D2,$1000
    OR.L D2,$20001000
* ORI
    ORI.B #1,D2
    ORI.B #2,(A2)
    ORI.W #3,(A2)+
    ORI.W #4,-(A2)
    ORI.L #5,$1000
    ORI.L #6,$20001000
    
    
* NEG
    NEG.L D2
    NEG.L (A2)
    NEG.L -(A2)
    NEG.L (A2)+
    NEG.L $4000
    NEG.L $00FF5000
    NEG.W $3000
    
    NEG.B D2
    
* EOR
    EOR.B D1,D2
    EOR.L D2,(A2)
    EOR.L D1,(A1)+
    EOR.L D2,-(A2)
* LSR
    LSR.B #2,D0
    LSR.B D2,D0
    LSR.W (A0)
    LSR.W -(A0)
    LSR.W (A0)+
* LSL
    LSL.B #3,D1
    LSL.B D2,D1
    LSL.W (A1)
    LSL.W -(A1)
    LSL.W (A1)+
* ASR
    ASR.B #3,D1
    ASR.B D2,D1
    ASR.W (A1)
    ASR.W -(A1)
    ASR.W (A1)+
* ASL
    ASR.B #3,D1
    ASR.B D2,D1
    ASR.W (A1)
    ASR.W -(A1)
    ASR.W (A1)+
* ROL
    ROL.B #3,D1
    ROL.B D0,D1
    ROL.W (A0)
    ROL.W (A0)+
    ROL.W -(A0)
* ROR
    ROL.B #3,D0
    ROL.B D0,D1
    ROL.W (A1)
    ROL.W (A1)+
    ROL.W -(A1)
* BCLR
    BCLR.L D0,D1
    BCLR.L #1,D1
    BCLR.B D0,(A0)
    BCLR.B #1,(A0)
    BCLR.B D0,(A0)+
    BCLR.B #2,(A0)+
    BCLR.B D0,-(A0)
    BCLR.B #4,-(A0)
* CMP
    CMP.B D0,D1
    CMP.B #1,D1
    CMP.B (A0),D1
    CMP.B (A0)+,D1
    CMP.B -(A0),D1
    
    CMP.W D0,D1
    CMP.W #1,D1
    CMP.W (A0),D1
    CMP.W (A0)+,D1
    CMP.W -(A0),D1
    CMP.W A0,D1
    
    CMP.L D0,D1
    CMP.L #1,D1
    CMP.L (A0),D1
    CMP.L (A0)+,D1
    CMP.L -(A0),D1
    CMP.L A0,D1
* CMPI
    CMPI.B #1,D0
    CMPI.B #1,(A0)
    CMPI.B #1,(A0)+
    CMPI.B #1,-(A0)
    CMPI.B #1,$4000
    CMPI.B #1,$00005000
    
    CMPI.W #1,D0
    CMPI.W #1,(A0)
    CMPI.W #1,(A0)+
    CMPI.W #1,-(A0)
    CMPI.W #1,$4000
    CMPI.W #1,$00005000
    
    CMPI.L #1,D0
    CMPI.L #1,(A0)
    CMPI.L #1,(A0)+
    CMPI.L #1,-(A0)
    CMPI.L #1,$4000
    CMPI.L #1,$00005000

* NOP
    NOP
* Bcc
    BCC CC
CC:
    BCS CS
CS:
    BEQ EQ
EQ:
    BGE GE
GE:
    BGT GT
GT:
    BHI HI
HI:
    BLE LE
LE:
    BLS LS
LS:
    BLT LT
LT:
    BMI MI
MI:
    BNE NE
NE:
    BPL PL
PL:
    BVC VC
VC:
    BVS VS
VS:
* BRA
    BRA BRA
BRA:
* JSR
    JSR SUB
    JSR (A2)
    JSR $1000
    JSR $20001000
    BRA END
* RTS
SUB:     
    RTS
    
* Put variables and constants here
END:
    END    START        ; last line of source







*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
