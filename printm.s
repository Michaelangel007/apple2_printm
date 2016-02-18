; Version 9

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

        __MAIN = $4000

; DOS3.3 meta -- remove these 2 if running under ProDOS
        .word __MAIN         ; 2 byte BLOAD address
        .word __END - __MAIN ; 2 byte BLOAD size

        .org  __MAIN         ; .org must come after header else offsets are wrong

        HOME = $FC58
        temp = $FE

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

    APPLE "X="
    .byte   "#"
    APPLE    " Y="
    .byte       "d"
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

/*
Problem:

We want to print this ...
    
    .byte "X=## Y=### $=####:@@ %%%%%%%%~????????"

... without having to waste marking up literals with an escape character


printf() on the 6502

- is bloated by using a meta-character '%' instead of the high bit
- doesn't provide a standard way to print binary *facepalm*
- doesn't provide a standard way to print a deferenced pointer
- 2 digit, 3 digit and 5 digit decimals requiring wasting a "width" character
  e.g. %2d, %3d, %5d


Solution:

Here is a micro replacement, printm()

* Literals have the high byte set (APPLE text)
* Meta characters have the high bit cleared (ASCII)

    x Hex 2 Byte
    $ Hex 4 Byte

    @ Ptr 2 Byte
    & Ptr 4 Byte

    # Dec 1 Byte (max 2 digits)
    d Dec 2 Byte (max 3 digits)
    u Dec 2 Byte (max 5 digits)

    % Bin 1 Byte normal  one's and zeros
    ? Bin 1 Byte inverse one's, normal zeroes

    s Str - Zero terminated
    p Str - Pascall

Note: The dummy address $C0DE is to force the assembler
to generate a 16-bit address instead of optimizing a ZP operand

*/


; Self-Modifying variable aliases

        _pScreen     = PutChar   +1
        _pFormat     = GetFormat +1
        _iArg        = NxtArgByte+1
        _pArg        = IncArg    +1
        _nHexWidth   = HexWidth  +1
        _nDecWidth   = DecWidth  +1

; printm( format, args, ... )
; ======================================================================
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
; ======================================================================
PrintHex4
        LDA #4
        BNE _PrintHex
PrintHex2
        LDA #2
_PrintHex
        STA _nHexWidth
        JSR NxtArgXY

; Print 16-bit Y,X in hex
; Uses _nHexWidth to limit output width
_PrintHexYX
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
HexWidth
        CPX #0          ; _nHexWidth NOTE: self-modifying!
        BNE _HexDigit
                        ; Intentional fall into reverse BCD

; On Entry: X number of chars to print in buffer _bcd
; ======================================================================
PrintReverseBCD
        DEX
        BMI NextFormat
        LDA _bcd, X
        JSR PutChar
        BRA PrintReverseBCD


; @ Ptr 2 Byte
; & Ptr 4 Byte
; ======================================================================
PrintPtr4
        LDA #4
        BNE _PrintPtr
PrintPtr2
        LDA #2
_PrintPtr
        STA _nHexWidth
        JSR NxtArgXY

; 13 bytes - zero page version
        STX temp+0      ; zero-page for (ZP),Y
        STY temp+1
        LDY #$0
        LDA (temp),Y
        TAX
        INY
        LDA (temp),Y
        TAY

; 20 bytes - self modifying code version if zero-page not available
;        STX PtrVal+1
;        STY PtrVal+2
;        LDY #0          ; 0: A->X
;PrtVal
;        TAX             ; 1: A->Y
;        LDA $C0DE, Y
;        INY
;        CPY #2
;        BEQ _JumpPrintHexXY
;        BNE _PtrVal
;_JumpPrintHexXY
;        TAY

        BRA _PrintHexYX ; always

; ======================================================================
Print
        JSR PutChar

; Adjust pointer to next char in format
NextFormat
        INC _pFormat+0
        BNE GetFormat
        INC _pFormat+1
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

; # Dec 1 Byte (max 2 digits)
; d Dec 2 Byte (max 3 digits)
; u Dec 2 Byte (max 5 digits)
; ======================================================================
PrintDec5
        LDA #5
        BNE _PrintDec   ; always
PrintDec3
        LDA #3
        BNE _PrintDec   ; always
PrintDec2
        LDA #2          ; 2 digits
_PrintDec
        STA _nDecWidth
        JSR NxtArgXY

PrintDecYX
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

DecWidth
        LDX #0      ; _nDecDigits NOTE: self modifying!
        JMP PrintReverseBCD


; % Bin 1 Byte normal  one's and zeros
; ? Bin 1 Byte inverse one's, normal zeroes
; ======================================================================
PrintBinInv
        LDA #$81
        BNE _PrintBin
PrintBinAsc
        LDA #$01
_PrintBin
        STA _PrintBit+1
        JSR NxtArgXY    ; X = low byte

        LDY #8          ; print 8 bits
_Bit2Asc
        TXA
        CMP #$80        ; C= A>=$80
        ROL             ; C<-76543210<-C
        TAX
        AND #$01            ; 0 -> B0
        BEQ _FlipBit
_PrintBit
        LDA #$81            ; 1 -> 31 NOTE: self-modifying!
_FlipBit
        EOR #$B0
        JSR PutChar
        DEY
        BNE _Bit2Asc
_JumpNextFormat
;       BRA NextFormat  ; always
        JMP NextFormat  ; JMP :-(

; ___ Utility ___

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
        STY _nHexWidth
CmpMeta
        CMP #$00        ; _CmpMeta NOTE: self-modifying!
        BNE _Done       ; optimization: re-use RTS
        INY
        BRA IncWidth
*/

; ======================================================================
PutChar
        STA $400        ; NOTE: self-modifying!
        INC PutChar+1   ; inc lo
        RTS

; @return &aArg[ iArg ] -> XY
; ======================================================================
GetArgAddr
        LDX _pArg+0  ; Low  Byte
        LDY _pArg+1  ; High Byte
        RTS

; ======================================================================
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

; ======================================================================
; @return X,Y 16-bit arg value
NxtArgXY
        JSR NxtArgByte
        TAX
        JSR NxtArgByte
        TAY
        RTS

                ; Hex2/Hex4 temp
_bcd    ds  6   ; 6 chars for printing dec
_val    dw  0

MetaChar
        db '&'  ; PrintPtr4
        db '@'  ; PrintPtr2
        db '?'  ; PrintBinInv
        db '%'  ; PrintBinAsc
        db 'u'  ; PrintDec5
        db 'd'  ; PrintDec3
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
        dw PrintDec5
        dw PrintDec3
        dw PrintDec2
        dw PrintHex2
        dw PrintHex4
__END

