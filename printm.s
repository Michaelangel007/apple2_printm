; Version 0.4

; ca65
.feature c_comments
.feature labels_without_colons
.feature leading_dot_in_identifiers
; 65C02
.PC02

; Force APPLE 'text' to have high bit on
; Will display as NORMAL characters
.macro APPLE text
    .repeat .strlen(text), I
        .byte   .strat(text, I) | $80
    .endrep
.endmacro

; Force ASCII 'text' to be control chars: $00..$1F
; Will display as INVERSE characters
.macro CTRL text
    .repeat .strlen(text), I
        .byte   .strat(text, I) & $1F
    .endrep
.endmacro

; Force ASCII 'text' to be control chars: $00..$3F
; Will display as INVERSE characters
.macro INV text
    .repeat .strlen(text), I
        .byte   .strat(text, I) & $3F
    .endrep
.endmacro

.macro db val
    .byte val
.endmacro

.macro dw val
    .word val
.endmacro

.macro ds bytes
    .res bytes
.endmacro


/*

    ;     "X=## Y=## $=####:## %%%%%%%%~%%%%%%%%"
    APPLE "            SAVE:?? 76543210 "
    INV                                 "12345678"


@ 4-Byte Hex 4 chars
$ 2-Byte Hex 2 chars
# 1-Byte Dec 3 chars
& 4-Byte Ptr 1 char
* 4-Byte Dec 5 chars
% 1-Byte Bin 8 chars
? 1-byte Bin inverse 1, normal 0

*/


        __MAIN = $4000
        .include "dos33.inc"

        HOME = $FC58
        temp = $FF

        JSR HOME

        LDA #$D5
        STA $2345
        STA DATA + $0C
        JSR ReverseByte
        STA DATA + $0E

        LDX #<DATA  ; Low  Byte of Address
        LDY #>DATA  ; High Byte of Address
        JSR PrintM
        RTS

ReverseByte
        LDX #8
        STA temp
ReverseBit
        ASL temp
        ROR
        DEX
        BNE ReverseBit
        RTS

TEXT
    ; TODO: macro to mark up non-literals as high-byte
    ;.byte  "X=## Y=## $=####:@@ %%%%%%%%~????????"
    ;APPLE "X="
    ;.byte   "$$"
    ;APPLE     " Y="
    ;.byte        "$$"
    ;APPLE          " $="
    ;.byte             "$$$$"
    ;APPLE                 ":"
    ;.byte                  "@@"
    ;APPLE                    " "
    ;.byte                     "%%%%%%%%"
    ;APPLE                             "~" 
    ;.byte                              "????????"
    ;.byte 0

    APPLE "X="
    .byte   "#"
    APPLE    " Y="
    .byte       "#"
    APPLE        " $="
    .byte           "x"
    APPLE            ":"
    .byte             "@"
    APPLE              " "
    .byte               "%"
    APPLE                "~" 
    .byte                 "?"
    .byte 0

DATA
    dw $0400    ; aArg[-1] Screen Dst
    dw TEXT     ; aArg[ 0] text
    dw 39       ; aArg[ 1] x
    dw 191      ; aArg[ 2] y
    dw $2345    ; aArg[ 3] addr
    dw $2345    ; aArg[ 4] byte
    dw $DA1A    ; aArg[ 5] bits
    dw $DA1A    ; aArg[ 6] bits

    ds 256 - <*

/*
printf() on the 6502

- is bloated by using a meta-character '%' instead of the high bit
- doesn't provide a standard way to print binary
- doesn't provide a standard way to print a deferenced pointer

Here is a micro replacement:

* Literals have the high byte set (APPLE text)
* Meta characters have the high bit cleared (ASCII)

  $ print 2 byte hex
  # print 3 char dec

The dummy address $C0DE is to force
a 16-bit address for the assembler
  

*/


; Self-Modifying variable aliases

        _pScreen     = PutChar   +1
        _pFormat     = GetFormat +1
        _iArg        = NxtArgByte+1
        _pArg        = IncArg    +1
        _nHexNibbles = HexNibbles+1

; printm( format, args, ... )
; =-=-=-=-=-=-=-=-=-=-
PrintM
        STX _pArg+0
        STY _pArg+1
        STZ _iArg    

        JSR NxtArgXY
        STX _pScreen+0  ; lo
        STY _pScreen+1  ; hi
NextArg
        JSR NxtArgXY
        STX _pFormat+0  ; lo
        STY _pFormat+1  ; hi
        BRA GetFormat   ; always

; x Hex 2 Byte
; $ Hex 4 Byte
; =-=-=-=-=-=-=-=-=-=-
PrintHex4
        LDA #4
        BNE _PrintHex
PrintHex2
        LDA #2
_PrintHex
        STA _nHexNibbles
        JSR NxtArgXY
_PrintHexXY
        STX _val+0
        STY _val+1
        LDX #0
_HexDigit
        LDA _val+0
        AND #$F
        CMP #$A         ; n < 10 ?
        BCC _Hex2Asc
        ADC #6          ; n += 6    $A -> +6 + (C=1) = $11
_Hex2Asc
        ADC #'0' + $80  ; inverse=remove #$80
        STA _bcd, X     ; NOTE: Digits are reversed!

        LSR _val+1      ; 16-bit SHR nibble
        ROR _val+0

        LSR _val+1
        ROR _val+0

        LSR _val+1
        ROR _val+0

        LSR _val+1
        ROR _val+0

        INX
HexNibbles
        CPX #0     ; _nHexNibbles NOTE: self-modifying!
        BNE _HexDigit

PrintHexDigit
        DEX
        BMI NextFormat
        LDA _bcd, X
        JSR PutChar
        BRA PrintHexDigit

; @ Ptr 2 Byte
; & Ptr 4 Byte
; =-=-=-=-=-=-=-=-=-=-
PrintPtr4
        LDA #4
        BNE _PrintPtr
PrintPtr2
        LDA #2
_PrintPtr
        STA _nHexNibbles
        JSR NxtArgXY

;STX $500
;STY $501

        STX $01
        STY $02
        LDY #$0
        LDA ($01),Y
        TAX
        INY
        LDA ($01),Y
        TAY

;STX $502
;STY $503
        BRA _PrintHexXY ; always

Print
        JSR PutChar
NextFormat
        JSR IncFormat
GetFormat
        LDA $C0DE       ; _pFormat NOTE: self-modifying!
        BEQ _Done
        BMI Print       ; neg = literal
        LDX #NumMeta-1  ; pos = meta
FindMeta
        CMP MetaChar,X
        BEQ CallMeta
        DEX
        BPL FindMeta
        BMI NextFormat  ; always = invalid meta; ignore
CallMeta
        TXA
        ASL
        TAX
        JMP (MetaFunc,X)
_Done
        RTS

; === Meta Ops ===

; # Dec 1 Byte (max 3 digits)
; d Dec 2 Byte (max 5 digits)
; =-=-=-=-=-=-=-=-=-=-
PrintDec2
        LDA #2      ; skip first 2 digits
_PrintDec
        STA DecDigits+1
        JSR NxtArgXY
PrintDecXY
        STX _val+0
        STY _val+1

        STZ _bcd+0
        STZ _bcd+1
        STZ _bcd+2

Dec2BCD
        LDX   #16
        SED
_Dec2BCD
        ASL _val+0
        ROl _val+1

        LDA _bcd+0
        ADC _bcd+0
        STA _bcd+0

        LDA _bcd+1
        ADC _bcd+1
        STA _bcd+1

        LDA _bcd+2
        ADC _bcd+2
        STA _bcd+2

        DEX
        BNE _Dec2BCD
        CLD

BCD2Char
        LDX #2
        LDY #5
_BCD2Char
        LDA _bcd,X  ; ab?def    a?_dXX  ?_YYXX
        LSR
        LSR
        LSR
        LSR
        CLC
        ADC #'0' + $80
        STA _bcd,Y  ; ab?deX    a?_YXX  ?ZYYXX
        DEY

        LDA _bcd,X  ; ab?deX    a?_YXX  ?ZYYXX
        AND #$F
        CLC
        ADC #'0' + $80
        STA _bcd,Y  ; ab?dXX    a?YYXX  ZZYYXX
        DEY
        DEX
        BPL _BCD2Char

LDX _bcd+0
LDY _bcd+1
LDA _bcd+2
STX $600
STY $601
STA $602
RTS

DecDigits
        LDY #0      ; _DecDigits
_PrintDecDigit
        LDA _bcd,Y       
        JSR PutChar
        INY
        CPY #6
        BNE _PrintDecDigit
_JumpNextFormat
;        BRA NextFormat  ; always
        JMP NextFormat  ; JMP :-(

PrintDec4
        LDA #0          ; skip 0 digits
        BNE _PrintDec   ; always

; % Bin 1 Byte normal  1
; d Bin 1 Byte inverse 1
; =-=-=-=-=-=-=-=-=-=-
PrintBinInv
        LDA #$81
        BNE _PrintBin
PrintBinAsc
        LDA #$01
_PrintBin
        STA _PrintBit+1
        JSR NxtArgXY

        LDY #8          ; print 8 bits
        TXA
_Bit2Asc
        AND #$01            ; 0 -> B0
        BEQ _FlipBit
_PrintBit
        LDA #$81            ; 1 -> 31 NOTE: self-modifying!
_FlipBit
        EOR #$B0
        JSR PutChar
        TXA
        LSR
        TAX
        DEY
        BNE _Bit2Asc
        BRA _JumpNextFormat ; always
        
/*
        JSR GetWidth
        JSR NxtArgXY GetArgAddr
        JSR ToBinX
        JSR PrintBuf
*/

; === Utility ===
/*
_CmpMeta = CmpMeta+1

GetWidth
        STA _CmpMeta    ; save last meta
        LDA _pFormat+0  ; Src.Lo
        LDY _pFormat+1  ; Src.Hi
        STA IncWidth+1  ; Dst.Lo
        STY IncWidth+2  ; Dst.Hi

        LDY #0
IncWidth
        LDA $C0DE,Y     ; NOTE: self-modifying!
        STY _nHexNibbles
CmpMeta
        CMP #$00        ; _CmpMeta NOTE: self-modifying!
        BNE _Done       ; optimization: re-use RTS
        INY
        BRA IncWidth
*/

PutChar
        STA $400        ; NOTE: self-modifying!
        INC PutChar+1   ; inc lo
        RTS

; @return &aArg[ iArg ] -> XY
GetArgAddr
        LDX _pArg+0  ; Low  Byte
        LDY _pArg+1  ; High Byte
        RTS

; @return _Arg[ _Num ]
NxtArgByte
        LDY #00         ; _iArg  NOTE: self-modifying!
IncArg
        LDA $C0DE,Y     ; _pArg NOTE: self-modifying!
        INC _iArg       ;       
        BNE @_SamePage
        INC _pArg+1     ;
@_SamePage
        RTS

; @return X,Y 16-bit arg value
NxtArgXY
        JSR NxtArgByte
        TAX
        JSR NxtArgByte
        TAY
        RTS

; printf( format, ... )
; Adjust pointer to next char in format
IncFormat
        INC _pFormat+0
        BNE _SamePage
        INC _pFormat+1
_SamePage
        RTS

ToHexXY
; Hex2/Hex4 temp
_bcd    ds  6   ; 6 chars for printing dec
_val    dw  0

MetaChar
        db '&'  ; PrintPtr4
        db '@'  ; PrintPtr2
        db '?'  ; PrintBinInv
        db '%'  ; PrintBinAsc
        db 'd'  ; PrintDec4
        db '#'  ; PrintDec2
        db '$'  ; PrintHex2
        db 'x'  ; PrintHex4

_MetaCharEnd
NumMeta = _MetaCharEnd - MetaChar

MetaFunc
        dw PrintPtr4
        dw PrintPtr2
        dw PrintBinInv
        dw PrintBinAsc
        dw PrintDec4
        dw PrintDec2
        dw PrintHex2
        dw PrintHex4
__END

