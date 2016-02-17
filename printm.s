; Version 0.3

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

                JSR HOME
                LDX #<DATA  ; Low  Byte of Address
                LDY #>DATA  ; High Byte of Address
                JSR PrintM
                RTS

TEXT
    ; TODO: macro to mark up non-literals as high-byte
    ;.byte  "X=## Y=## $=####:@@ %%%%%%%%~????????"

    APPLE "X="
    .byte   "##"
    APPLE     " Y="
    .byte        "##"
    APPLE          " $="
    .byte             "####"
    APPLE                 ":"
    .byte                  "@@"
    APPLE                    " "
    .byte                     "%%%%%%%%"
    APPLE                             "~" 
    .byte                              "????????"
    .byte 0

DATA
    dw $0400    ; aArg[-1] Screen Dst
    dw TEXT     ; aArg[ 0] text
    dw 39       ; aArg[ 1]
    dw 191      ; aArg[ 2]
    dw $3FF7    ; aArg[ 3]
    dw $3FF7    ; aArg[ 4]

SetArg
    rts

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

PrintHex4
/*
        JSR GetWidth
        JSR GetArgAddr
        LDX #0
        JSR ToHexXY
        JSR PrintBuf
*/
        LDA #5
        BNE _PrintHex2
PrintHex2
        LDA #3
_PrintHex2
        STA _nHexNibbles
/*
        JSR GetWidth
        JSR GetArgAddr
        LDX #0
        JSR ToHexXY
        JSR PrintBuf
*/
        BRA NextFormat  ; always

PrintPtr2
/*
        JSR GetWidth
        JSR GetArgAddr
        STX GetByte+1
        STY GetByte+2
GetByte LDA $C0DE
        JSR ToHexXY
        JSR PrintBuf
*/
        BRA NextFormat  ; always

PrintDec2
/*
        JSR GetWidth
        JSR GetArgAddr
        JSR ToDecX
        JSR PrintBuf
*/
        BRA NextFormat  ; always

PrintBinAsc
/*
        JSR GetWidth
        JSR GetArgAddr
        JSR ToBinX
        JSR PrintBuf
*/
        BRA NextFormat  ; always

PrintBinInv
        BRA NextFormat  ; always


; === Utility ===
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
        BNE @_SamePage
        INC _pFormat+1
@_SamePage
        RTS

ToHexXY
        STX _val+0
        STY _val+1
        LDA _val+0
        LDX #0
_HexDigit
        AND #$F
        CMP #$A         ; n < 10 ?
        BCC @_DecDigit
        ADC #6          ; n += 6    $A -> +6 + (C=1) = $11
@_DecDigit
        ADC #'0'
        ORA #$80
        JSR PutChar
                        ; 16-bit SHR nibble
        LSR _val+1
        ROR _val+0

        LSR _val+1
        ROR _val+0

        LSR _val+1
        ROR _val+0

        LSR _val+1
        ROR _val+0

        INX
HexNibbles
        CPX #5     ; _nHexNibbles NOTE: self-modifying!
        BNE _HexDigit
        RTS

ToDecX
        RTS
ToBin
        RTS

; Hex2/Hex4 temp
_buf    ds  8   ; 8 chars for printing binary
_val    dw  0

MetaChar
        db '?'  ; PrintBinInv
        db '%'  ; PrintBinAsc
        db '#'  ; PrintDec2
        db '$'  ; PrintHex2
;        db 'd'  ; PrintDec5
;        db 'x'  ; PrintHex4

_MetaCharEnd
NumMeta = _MetaCharEnd - MetaChar

MetaFunc
        dw PrintBinInv
        dw PrintBinAsc
        dw PrintDec2
        dw PrintHex4
__END

