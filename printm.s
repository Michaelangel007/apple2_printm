; ca65
.feature c_comments

/* Version 15
printm - a printf replacement for 65C02
Michael Pohoreski


Problem:

Ideally we want to print a single line that includes literal and variables
in MIXED ASCII case -- high bit characters would be output "as is"
and ASCII characters would be interpreted as a variable output.

While originally this gives us a nice 1:1 mapping for input:output ...

    .byte "X=## Y=### $=####:@@ %%%%%%%%~????????"

... it has 2 problems:

a) it has to be constructed in pieces
b) and it is bloated.

Is there we can use a more compact printf-style format string
where we don't waste storing the escape character, and
toggle the high bit on characters on/off as needed?

Yes, if we use a macro!

     PRINTM "X=%# Y=%d $=%x:%@ %%~%?"

Thisis why printf() on the 6502 sucks:

- is bloated by using a meta-character '%' instead of the high bit
- doesn't provide a standard way to print binary *facepalm*
- doesn't provide a standard way to print a deferenced pointer
- 2 digit, 3 digit and 5 digit decimals requiring wasting "width" characters
  e.g. %2d, %3d, %5d
  When a single character would work instead.

Solution:

Here is a micro replacement, printm()

* Literals have the high byte set (APPLE text)
* Meta characters have the high bit cleared (ASCII)

    x Hex - print 2 Byte
    $ Hex - print 4 Byte

    @ Ptr - print hex byte at 16-bit pointer
    & Ptr - print hex word at 16-bit pointer

    # Dec - Print 1 Byte in decimal (max 2 digits)
    d Dec - Print 2 Byte in decimal (max 3 digits)
    u Dec - Print 2 Byte in decimal (max 5 digits)
    b Dec - Print signed byte

    % Bin 1 Byte
    ? Bin 1 Byte but 1's are printed in inverse

    a Str - APPLE text (high bit set), last char is ASCII
    s Str - C string, zero terminated
    p Str - Pascal string, first character is string length

Note: The dummy address $C0DE is to force the assembler
to generate a 16-bit address instead of optimizing a ZP operand

The printm with everything enabled takes up 472 bytes

Demo + Library text dump:

4000:20 58 FC A9 D5 A2 45 A0
4008:23 8E BE 40 8C BF 40 8E
4010:C0 40 8C C1 40 8E 1C 40
4018:8C 1D 40 8D DE C0 8D C2
4020:40 20 5C 40 8D C4 40 A0
4028:00 20 67 40 A2 B8 A0 40
4030:20 00 42 A0 02 20 67 40
4038:A2 E1 A0 40 20 00 42 A0
4040:04 20 67 40 A2 FE A0 40
4048:20 00 42 A0 06 20 67 40
4050:A2 2E A0 41 20 00 42 A9
4058:08 4C 5B FB A2 08 85 FF
4060:06 FF 6A CA D0 FA 60 B9
4068:76 40 8D 8C 43 B9 8E 40
4070:09 04 8D 8D 43 60 00 80
4078:00 80 00 80 00 80 28 A8
4080:28 A8 28 A8 28 A8 50 D0
4088:50 D0 50 D0 50 D0 00 00
4090:01 01 02 02 03 03 00 00
4098:01 01 02 02 03 03 00 00
40A0:01 01 02 02 03 03 D8 BD
40A8:23 A0 D9 BD 64 A0 A4 BD
40B0:78 BA 40 A0 25 FE 3F 00
40B8:A6 40 27 00 BF 00 DE C0
40C0:DE C0 1A DA 1A DA C2 F9
40C8:F4 E5 BD 62 A0 62 A0 62
40D0:A0 62 A0 62 00 C8 C5 CC
40D8:CC CF 00 D7 CF D2 CC C4
40E0:00 C6 40 80 00 FF 00 00
40E8:00 01 00 7F 00 D3 F4 F2
40F0:E9 EE E7 F3 BA A0 A7 73
40F8:A7 AC A7 73 A7 00 ED 40
4100:D5 40 DB 40 C8 CF CD 45
4108:0D D3 F4 F2 E9 EE E7 A0
4110:CC E5 EE A0 B1 B3 C1 F0
4118:F0 EC E5 BA A0 A7 61 A7
4120:A0 A0 D0 E1 F3 E3 E1 EC
4128:BA A0 A7 70 A7 00 16 41
4130:04 41 08 41 00 00 00 00
4138:00 00 00 00 00 00 00 00
4140:00 00 00 00 00 00 00 00
4148:00 00 00 00 00 00 00 00
4150:00 00 00 00 00 00 00 00
4158:00 00 00 00 00 00 00 00
4160:00 00 00 00 00 00 00 00
4168:00 00 00 00 00 00 00 00
4170:00 00 00 00 00 00 00 00
4178:00 00 00 00 00 00 00 00
4180:00 00 00 00 00 00 00 00
4188:00 00 00 00 00 00 00 00
4190:00 00 00 00 00 00 00 00
4198:00 00 00 00 00 00 00 00
41A0:00 00 00 00 00 00 00 00
41A8:00 00 00 00 00 00 00 00
41B0:00 00 00 00 00 00 00 00
41B8:00 00 00 00 00 00 00 00
41C0:00 00 00 00 00 00 00 00
41C8:00 00 00 00 00 00 00 00
41D0:00 00 00 00 00 00 00 00
41D8:00 00 00 00 00 00 00 00
41E0:00 00 00 00 00 00 00 00
41E8:00 00 00 00 00 00 00 00
41F0:00 00 00 00 00 00 00 00
41F8:00 00 00 00 00 00 00 00
4200:8E 99 43 8C 9A 43 9C 97
4208:43 20 92 43 8E 83 42 8C
4210:84 42 80 6E A9 04 D0 02
4218:A9 02 8D 52 42 20 92 43
4220:8E AF 43 8C B0 43 A2 00
4228:AD AF 43 29 0F C9 0A 90
4230:02 69 06 69 B0 9D A9 43
4238:4E B0 43 6E AF 43 4E B0
4240:43 6E AF 43 4E B0 43 6E
4248:AF 43 4E B0 43 6E AF 43
4250:E8 E0 00 D0 D3 CA 30 22
4258:BD A9 43 20 8B 43 80 F5
4260:A9 04 D0 02 A9 02 8D 52
4268:42 20 92 43 A0 00 B1 FE
4270:AA C8 B1 FE A8 80 A9 20
4278:8B 43 EE 83 42 D0 03 EE
4280:84 42 AD DE C0 F0 14 30
4288:EE A2 0C DD B1 43 F0 05
4290:CA 10 F8 30 E5 8A 0A AA
4298:7C BE 43 60 A9 05 D0 06
42A0:A9 03 D0 02 A9 02 8D 05
42A8:43 20 92 43 8E AF 43 8C
42B0:B0 43 9C A9 43 9C AA 43
42B8:9C AB 43 A2 10 F8 0E AF
42C0:43 2E B0 43 AD A9 43 6D
42C8:A9 43 8D A9 43 AD AA 43
42D0:6D AA 43 8D AA 43 AD AB
42D8:43 6D AB 43 8D AB 43 CA
42E0:D0 DC D8 A2 02 A0 05 BD
42E8:A9 43 4A 4A 4A 4A 18 69
42F0:B0 99 A9 43 88 BD A9 43
42F8:29 0F 18 69 B0 99 A9 43
4300:88 CA 10 E3 A2 00 4C 55
4308:42 A9 81 D0 02 A9 01 8D
4310:21 43 20 92 43 A0 08 8A
4318:C9 80 2A AA 29 01 F0 02
4320:A9 81 49 B0 20 8B 43 88
4328:D0 ED 4C 7A 42 20 92 43
4330:8A 10 0D A9 AD 20 8B 43
4338:8A 49 FF 29 7F 18 69 01
4340:AA A0 00 A9 03 8D 05 43
4348:4C AC 42 20 92 43 A0 00
4350:B1 FE 10 0A 20 8B 43 C8
4358:D0 F6 E6 FF 80 F2 09 80
4360:4C 77 42 20 92 43 A0 00
4368:B1 FE F0 BE 20 8B 43 C8
4370:D0 F6 E6 FF 80 F2 20 92
4378:43 A0 00 B1 FE F0 AB AA
4380:C8 B1 FE 20 8B 43 CA D0
4388:F7 F0 9F 8D DE C0 EE 8C
4390:43 60 20 96 43 AA A0 00
4398:B9 DE C0 EE 97 43 D0 03
43A0:EE 9A 43 A8 86 FE 84 FF
43A8:60 00 00 00 00 00 00 00
43B0:00 3F 25 62 75 64 23 78
43B8:24 26 40 70 73 61 09 43
43C0:0D 43 2D 43 9C 42 A0 42
43C8:A4 42 14 42 18 42 60 42
43D0:64 42 76 43 63 43 4B 43

To toggle features on / off:

*/

ENABLE_BIN   = 1
ENABLE_DEC   = 1
ENABLE_BYTE  = 1    ; requires ENABLE_DEC
ENABLE_HEX   = 1
ENABLE_PTR   = 1    ; requires ENABLE_HEX
ENABLE_STR   = 1

; more ca65
.feature labels_without_colons
.feature leading_dot_in_identifiers
; 65C02
.PC02

; This will take a printf-style string and compact it
; % is the escape character to output the next byte in ASCII (high bit clear)
; othersise the remaining chars will default to have their high bit set
.macro PRINTM text
    .local h
    h .set $80

    .repeat .strlen(text), I
        .if (.strat(text , I) = '%')
            ; handle special case of last char was %
            .if( h = $00 )
                .byte .strat(text, I) | h
                h .set $80
            .else
                h .set $00
            .endif
        .else
            .byte .strat(text, I) | h
            h .set $80
        .endif
    .endrep
    .byte 0
.endmacro

; Force APPLE 'text' to have high bit on
; Will display as NORMAL characters
.macro APPLE text
    .repeat .strlen(text), I
        .byte   .strat(text, I) | $80
    .endrep
.endmacro

; Force APPLE 'text' with high bit on but last character has high bit off
; Will display as NORMAL characters (last character will appear FLASHING)
; Merlin: Macro Assembler -- Dextral Character Inverted
.macro DCI text
    .repeat .strlen(text)-1, I
        .byte   .strat(text, I) | $80
    .endrep
    .byte   .strat(text, .strlen(text)-1) & $7F
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

.macro PASCAL text
    .byte .strlen(text)
    APPLE text
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

        HOME    = $FC58
        TABV    = $FB5B

; printm pointer for PrintPtr2, PrintPtr4, PrintStrA, PrintStrC, PrintStrP
        _temp   = $FE

        __MAIN = $4000
; DOS3.3 meta -- remove these 2 if running under ProDOS
        .word __MAIN         ; 2 byte BLOAD address
        .word __END - __MAIN ; 2 byte BLOAD size

/*

Output:

X=39 Y=191 $=2345:D5 11010101~10101011

Byte=-128 -001 000 001 127

Strings: 'HELLO','WORLD'

Apple: 'HOME' Pascal: 'String Len 13'

*/

        .org  __MAIN         ; .org must come after header else offsets are wrong
; Demo printm
        JSR HOME

        LDA #$D5

        LDX #$45
        LDY #$23
        STX DATA+6
        STY DATA+7
        STX DATA+8
        STY DATA+9

        STX _HgrAddr+1
        STY _HgrAddr+2
_HgrAddr
        STA $C0DE

        STA DATA+10
        JSR ReverseByte
        STA DATA+12

.if ENABLE_BIN || ENABLE_DEC || ENABLE_HEX
        LDY #0
        JSR VTABY
        LDX #<DATA  ; Low  Byte of Address
        LDY #>DATA  ; High Byte of Address
        JSR PrintM
.endif

.if ENABLE_BYTE
        LDY #2
        JSR VTABY
        LDX #<DATA2
        LDY #>DATA2
        JSR PrintM
.endif  ; ENABLE_BYTE

.if ENABLE_STR
        LDY #4
        JSR VTABY
        LDX #<DATA3
        LDY #>DATA3
        JSR PrintM

        LDY #6
        JSR VTABY
        LDX #<DATA4
        LDY #>DATA4
        JSR PrintM
.endif  ; ENABLE_STR

        LDA #8
        JMP TABV

ReverseByte
        LDX #8
        STA $FF     ; temp working byte
ReverseBit
        ASL $FF     ; temp working byte
        ROR
        DEX
        BNE ReverseBit
        RTS

VTABY
        LDA SCREEN_LO,Y
        STA PutChar+1
        LDA SCREEN_HI,Y
        ORA #$04    ; TXT page 1
        STA PutChar+2
        RTS

; Y Lookup Table for 40x24 Text Screen
SCREEN_LO
        .byte $00, $80, $00, $80
        .byte $00, $80, $00, $80

        .byte $28, $A8, $28, $A8
        .byte $28, $A8, $28, $A8

        .byte $50, $D0, $50, $D0
        .byte $50, $D0, $50, $D0
SCREEN_HI
        .byte $00, $00, $01, $01
        .byte $02, $02, $03, $03

        .byte $00, $00, $01, $01
        .byte $02, $02, $03, $03

        .byte $00, $00, $01, $01
        .byte $02, $02, $03, $03

TEXT
    ;byte "X=## Y=ddd $=xxxx:@@ %%%%%%%%~????????"
    PRINTM "X=%# Y=%d $=%x:%@ %%~%?"

DATA
    dw TEXT     ; aArg[ 0] text
    dw 39       ; aArg[ 1] x
    dw 191      ; aArg[ 2] y
    dw $C0DE    ; aArg[ 3] addr  ScreenAddr
    dw $C0DE    ; aArg[ 4] byte  ScreenAddr pointer
    dw $DA1A    ; aArg[ 5] bits  ScreenByte
    dw $DA1A    ; aArg[ 6] bits  ScreenByte reversed

TEXT2
    PRINTM "Byte=%b %b %b %b %b"

TEXT_HELLO
    APPLE "HELLO"
    db 0

TEXT_WORLD
    APPLE "WORLD"
    db 0

DATA2
    dw TEXT2
    dw $80      ; -128
    dw $FF      ; -1
    dw $00      ;  0
    dw $01      ; +1
    dw $7F      ; +127

TEXT3
    PRINTM "Strings: '%s','%s'"

DATA3
    dw TEXT3
    dw TEXT_HELLO
    dw TEXT_WORLD

TEXT_DCI
    DCI "HOME"

TEXT_PASCAL
    PASCAL "String Len 13"

TEXT4
    PRINTM "Apple: '%a'  Pascal: '%p'"

DATA4
    dw TEXT4
    dw TEXT_DCI
    dw TEXT_PASCAL

; Pad until end of page so PrintM starts on new page
    ds 256 - <*


; self-modifying variable aliases

        _pScreen     = PutChar   +1
        _pFormat     = GetFormat +1
        _iArg        = NxtArgByte+1
        _pArg        = IncArg    +1
.if ENABLE_HEX
        _nHexWidth   = HexWidth  +1
.endif
.if ENABLE_DEC
        _nDecWidth   = DecWidth  +1
.endif ; ENABLE_DEC

; ======================================================================
; printm( format, args, ... )
; ======================================================================
PrintM
        STX _pArg+0
        STY _pArg+1
        STZ _iArg

NextArg
        JSR NxtArgYX
        STX _pFormat+0  ; lo
        STY _pFormat+1  ; hi
        BRA GetFormat   ; always

.if ENABLE_HEX

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
        JSR NxtArgYX

; Print 16-bit Y,X in hex
; Uses _nHexWidth to limit output width
PrintHexYX
        STX _val+0      ; may be tempting to move this to NxtArgYX
        STY _val+1      ; as XYtoVal but others call us

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


    .if ENABLE_PTR
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
        JSR NxtArgToTemp

;       JSR NxtArgYX
; 13 bytes: zero page version
;       STX _temp+0     ; zero-page for (ZP),Y
;       STY _temp+1
        LDY #$0
        LDA (_temp),Y
        TAX
        INY
        LDA (_temp),Y
        TAY

; 20 bytes: self-modifying code version if zero-page not available
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

        BRA PrintHexYX  ; needs XYtoVal setup
    .endif  ; ENABLE_PTR
.endif  ; ENABLE_HEX


; ======================================================================
Print
        JSR PutChar
NextFormat              ; Adjust pointer to next char in format
        INC _pFormat+0
        BNE GetFormat
        INC _pFormat+1
GetFormat
        LDA $C0DE       ; _pFormat NOTE: self-modifying!
        BEQ _Done       ; zero-terminated
        BMI Print       ; neg = literal
; NOTE: If all features are turned off, will get a ca65 Range Error
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

.if ENABLE_DEC
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
        JSR NxtArgYX

PrintDecYX
        STX _val+0      ; may be tempting to move this to NxtArgYX
        STY _val+1      ; as XYtoVal but others call us

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
        LDA _bcd,X  ; __c???    _b_?XX  a_YYXX
        LSR
        LSR
        LSR
        LSR
        CLC
        ADC #'0'+$80
        STA _bcd,Y  ; __c??X    _b_YXX  aZYYXX
        DEY

        LDA _bcd,X  ; __c??X    _b_YXX  aZYYXX
        AND #$F
        CLC
        ADC #'0'+$80
        STA _bcd,Y  ; __c?XX    _bYYXX  ZZYYXX
        DEY
        DEX
        BPL _BCD2Char

DecWidth
        LDX #0      ; _nDecDigits NOTE: self-modifying!
        JMP PrintReverseBCD
.endif  ; ENABLE_DEC


.if ENABLE_BIN
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
        JSR NxtArgYX    ; X = low byte

        LDY #8          ; print 8 bits
_Bit2Asc
        TXA
        CMP #$80        ; C= A>=$80
        ROL             ; C<-76543210<-C
        TAX
        AND #$01        ; 0 -> B0
        BEQ _FlipBit
_PrintBit
        LDA #$81        ; 1 -> 31 NOTE: self-modifying!
_FlipBit
        EOR #$B0
        JSR PutChar
        DEY
        BNE _Bit2Asc
.endif  ; ENABLE_BIN

_JumpNextFormat
;       BRA NextFormat  ; always
        JMP NextFormat  ; JMP :-(

; b Print a signed byte in decimal
; ======================================================================
.if ENABLE_DEC
    .if ENABLE_BYTE
PrintByte
        JSR NxtArgYX    ; X = low byte
        TXA
        BPL PrintBytePos
        LDA #'-' + $80  ; X >= $80 --> $80 (-128) .. $FF (-1)
        JSR PutChar
        TXA
        EOR #$FF        ; 2's complement
        AND #$7F
        CLC
        ADC #$01
PrintBytePos
        TAX

        LDY #00         ; 00XX
        LDA #3          ; 3 digits max
        STA _nDecWidth
        JMP PrintDecYX  ; needs XYtoVal setup
    .endif ; ENABLE_BYTE
.endif  ; ENABLE_DEC


.if ENABLE_STR
; a String (APPLE text, last byte ASCII)
; See: DCI
; ======================================================================
PrintStrA
        JSR NxtArgToTemp

        LDY #$0
_PrintStrA
        LDA (_temp),Y
        BPL @_LastChar
        JSR PutChar
        INY
        BNE _PrintStrA
        INC _temp+1
        BRA _PrintStrA
@_LastChar
; 6 byte:
;        LDX #1
;        ORA #$80
;        BRA _PrintCharA
; 5 byte:
        ORA #$80
        JMP Print

; s String (C,ASCIIZ)
; ======================================================================
PrintStrC
        JSR NxtArgToTemp

        LDY #$0
@_NextByte
        LDA (_temp),Y
        BEQ _JumpNextFormat
        JSR PutChar
        INY
        BNE @_NextByte
        INC _temp+1
        BRA @_NextByte

; p String (Pascal)
; ======================================================================
PrintStrP
        JSR NxtArgToTemp

        LDY #$0
        LDA (_temp),Y
        BEQ _JumpNextFormat
        TAX
_PrintStrP
        INY
        LDA (_temp),Y
_PrintCharA
        JSR PutChar
        DEX
        BNE _PrintStrP
        BEQ _JumpNextFormat ; always
.endif  ; ENABLE_STR

; __________ Utility __________

; ======================================================================
PutChar
        STA $C0DE       ; _pScreen NOTE: self-modifying!
        INC PutChar+1   ; inc lo
        RTS

; ======================================================================
; @return next arg as 16-bit arg value in Y,X
NxtArgToTemp
NxtArgYX
        JSR NxtArgByte
        TAX

; @return _Arg[ _Num ]
NxtArgByte
        LDY #00         ; _iArg NOTE: self-modifying!
IncArg
        LDA $C0DE,Y     ; _pArg NOTE: self-modifying!
        INC _iArg       ;
        BNE @_SamePage
        INC _pArg+1     ;
@_SamePage
        TAY

; Callers of NxtToArgYX don't use _temp
_NxtArgToTemp
        STX _temp+0     ; zero-page for (ZP),Y
        STY _temp+1

;XYtoVal
;        STX _val+0      ; may be tempting to move this to NxtArgYX
;        STY _val+1      ;

        RTS

;
; ======================================================================

_bcd    ds  6   ; 6 chars for printing dec
_val    dw  0   ; PrintHex2 PrintHex4 temp

MetaChar

.if ENABLE_BIN
        db '?'  ; PrintBinInv   NOTE: 1's printed in inverse
        db '%'  ; PrintBinAsc
.endif
.if ENABLE_DEC
    .if ENABLE_BYTE
        db 'b'  ; PrintByte     NOTE: Signed -128 .. +127
    .endif
        db 'u'  ; PrintDec5
        db 'd'  ; PrintDec3
        db '#'  ; PrintDec2
.endif
.if ENABLE_HEX
        db 'x'  ; PrintHex4
        db '$'  ; PrintHex2
    .if ENABLE_PTR
        db '&'  ; PrintPtr4
        db '@'  ; PrintPtr2
    .endif
.endif
.if ENABLE_STR
        db 'p'  ; PrintStrP     NOTE: Pascal string; C printf 'p' is pointer!
        db 's'  ; PrintStrC     NOTE: C string, zero terminated
        db 'a'  ; PrintStrA     NOTE: Last byte is ASCII
.endif

_MetaCharEnd
NumMeta = _MetaCharEnd - MetaChar

MetaFunc

.if ENABLE_BIN
        dw PrintBinInv
        dw PrintBinAsc
.endif
.if ENABLE_DEC
    .if ENABLE_BYTE
        dw PrintByte
    .endif
        dw PrintDec5
        dw PrintDec3
        dw PrintDec2
.endif
.if ENABLE_HEX
        dw PrintHex4
        dw PrintHex2
    .if ENABLE_PTR
        dw PrintPtr4
        dw PrintPtr2
    .endif
.endif
.if ENABLE_STR
        dw PrintStrP
        dw PrintStrC
        dw PrintStrA
.endif

__END

