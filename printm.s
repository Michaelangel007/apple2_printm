; ca65
.feature c_comments

/* Version 17
printm - a printf replacement for 65C02
Michael Pohoreski


Problem:

Ideally we want to print a single line that includes literal and variables
in MIXED ASCII case -- high bit characters would be output "as is"
and ASCII characters would be interpreted as a variable output.

             __   ___   ____ __ ________ ________
    .byte "X=## Y=### $=$$$$:@@ %%%%%%%%~????????"

Legend:

    # Print Dec Num
    $ Print Hex Num
    % Print Bin Num
    ? Print Bin Num but with 1's in inverse
    @ Print Ptr Val
    _ Chars with underscore represents ASCII characters

While originally this gives us a nice 1:1 mapping for input:output ...

... it has 2 problems:

a) it has to be constructed in pieces
b) and it is bloated.

Can we use a more compact printf-style format string
where we don't waste storing the escape character AND
toggle the high bit on characters on/off as needed?

Yes, if we use a macro!

     PRINTM "X=%# Y=%d $=%x:%@ %%~%?"

This is why printf() on the 6502 sucks:

- is bloated by using a meta-character '%' instead of the high bit
- doesn't provide a standard way to print binary *facepalm*
- doesn't provide a standard way to print a dereferenced pointer
- 2 digit, 3 digit and 5 digit decimals requiring wasting "width" characters
  e.g. %2d, %3d, %5d
  When a single character would work instead.

Solution:

Here is a micro replacement, printm()

* Literals have the high byte set (APPLE text)
* Meta characters have the high bit cleared (ASCII)

    $ Hex - print 2 Byte
    x Hex - print 4 Byte

    @ Ptr - print hex byte at 16-bit pointer
    & Ptr - print hex word at 16-bit pointer

    # Dec - Print 1 Byte in decimal (max 2 digits)
    d Dec - Print 2 Byte in decimal (max 3 digits)
    u Dec - Print 2 Byte in decimal (max 5 digits)
    b Dec - Print signed byte in decimal

    % Bin - Print 8 bits
    ? Bin - Print 8 bits but 1's in inverse

    a Str - APPLE text (high bit set), last char is ASCII
    s Str - C string, zero terminated
    p Str - Pascal string, first character is string length

Each option can invidivually be enabled / disabled
to control the memory footprint.

With everything enabled printm() takes up $1D1 = 465 bytes
(Plus 2 bytes in zero page.)

With all features turned off the core routines use $64 = 100 bytes.

With Bin, Dec2, Dec5, Hex2, Hex4, and StrA
the size is $154 = 340 bytes

To toggle features on / off, change USE_*:

*/

; NOTE: The Size *also* includes the core routines
;       so the actual implementation size for each feature
;       is actually smaller the size leads you to believe.
;
;           Feature  Size Total Notes
USE_BIN_ASC     = 1 ; $81 \
USE_BIN_INV     = 1 ; $87 / $8B
USE_DEC_2       = 1 ; $D7 \
USE_DEC_3       = 1 ; $D9  $106
USE_DEC_5       = 1 ; $D9
USE_DEC_BYTE    = 1 ; $F3 /     sets ENABLE_DEC
USE_HEX_2       = 1 ; $AE \
USE_HEX_4       = 1 ; $AE / $B2
USE_PTR_2       = 1 ; $C0       sets ENABLE_HEX
USE_PTR_4       = 1 ; $C3       sets ENABLE_HEX
USE_STR_A       = 1 ; $7A \
USE_STR_C       = 1 ; $7A   $A8
USE_STR_PASCAL  = 1 ; $7C /

/*

Demo + Library text dump:

4000:20 58 FC A9 D5 8D 00 20
4008:A9 AA 8D 01 20 AD 6F 41
4010:A2 00 A0 00 20 11 F4 18
4018:A5 26 6D 6D 41 85 26 AA
4020:A4 27 8E 71 41 8C 72 41
4028:8E 73 41 8C 74 41 AD 00
4030:20 A0 00 91 26 8D 75 41
4038:9C 76 41 20 0F 41 8D 77
4040:41 9C 78 41 A0 00 20 1A
4048:41 A2 6B A0 41 20 04 43
4050:A0 01 20 1A 41 A2 8F A0
4058:41 20 04 43 A0 02 20 1A
4060:41 A2 93 A0 41 20 04 43
4068:A0 03 20 1A 41 A2 BE A0
4070:41 20 04 43 A0 04 20 1A
4078:41 A2 C2 A0 41 20 04 43
4080:A0 05 20 1A 41 A2 C6 A0
4088:41 20 04 43 A0 06 20 1A
4090:41 A2 CA A0 41 20 04 43
4098:A0 07 20 1A 41 A2 FE A0
40A0:41 20 04 43 A0 08 20 1A
40A8:41 A2 02 A0 42 20 04 43
40B0:A0 09 20 1A 41 A2 06 A0
40B8:42 20 04 43 A0 0A 20 1A
40C0:41 A2 0C A0 42 20 04 43
40C8:A0 0B 20 1A 41 A2 58 A0
40D0:42 20 04 43 A0 0C 20 1A
40D8:41 A2 5E A0 42 20 04 43
40E0:A0 0D 20 1A 41 A2 62 A0
40E8:42 20 04 43 A9 0E 20 5B
40F0:FB A0 00 B9 66 42 F0 06
40F8:20 ED FD C8 D0 F5 AD 75
4100:42 20 D3 FD AD 74 42 20
4108:DA FD A9 8D 4C ED FD A2
4110:08 85 FF 06 FF 6A CA D0
4118:FA 60 B9 29 41 8D 89 44
4120:B9 41 41 09 04 8D 8A 44
4128:60 00 80 00 80 00 80 00
4130:80 28 A8 28 A8 28 A8 28
4138:A8 50 D0 50 D0 50 D0 50
4140:D0 00 00 01 01 02 02 03
4148:03 00 00 01 01 02 02 03
4150:03 00 00 01 01 02 02 03
4158:03 D8 BD 23 A0 D9 BD 64
4160:A0 A4 BD 78 BA 40 A0 25
4168:FE 3F 00 59 41 27 00 BF
4170:00 DE C0 DE C0 1A DA 1A
4178:DA C2 E9 EE A0 C1 D3 C3
4180:BA A0 25 00 C2 E9 EE A0
4188:C9 CE D6 BA A0 3F 00 79
4190:41 75 41 84 41 75 41 C4
4198:E5 E3 B2 BA A0 23 00 C4
41A0:E5 E3 B3 BA A0 64 00 C4
41A8:E5 E3 B5 BA A0 75 00 C2
41B0:F9 F4 E5 BD 62 A0 62 A0
41B8:62 A0 62 A0 62 00 97 41
41C0:63 00 9F 41 E7 03 A7 41
41C8:69 FF AF 41 80 00 FF 00
41D0:00 00 01 00 7F 00 C8 E5
41D8:F8 B2 BA A0 A4 24 00 C8
41E0:E5 F8 B4 BA A0 A4 78 00
41E8:D0 F4 F2 B2 BA A0 A4 78
41F0:BA 40 00 D0 F4 F2 B4 BA
41F8:A0 A4 78 BA 26 00 D6 41
4200:34 12 DF 41 34 12 E8 41
4208:00 20 00 20 F3 41 00 20
4210:00 20 C8 C5 CC CC CF 00
4218:D7 CF D2 CC C4 00 C8 CF
4220:CD 45 0D D0 E1 F3 E3 E1
4228:EC A0 CC E5 EE A0 B1 B3
4230:C3 A0 A0 A0 A0 A0 BA A0
4238:A7 73 A7 AC A7 73 A7 00
4240:C1 F0 F0 EC E5 A0 BA A0
4248:A7 61 A7 00 D0 E1 F3 E3
4250:E1 EC BA A0 A7 70 A7 00
4258:30 42 12 42 18 42 40 42
4260:1E 42 4C 42 22 42 F0 F2
4268:E9 EE F4 ED A8 A9 AE F3
4270:E9 FA E5 00 D1 01 00 00
4278:00 00 00 00 00 00 00 00
4280:00 00 00 00 00 00 00 00
4288:00 00 00 00 00 00 00 00
4290:00 00 00 00 00 00 00 00
4298:00 00 00 00 00 00 00 00
42A0:00 00 00 00 00 00 00 00
42A8:00 00 00 00 00 00 00 00
42B0:00 00 00 00 00 00 00 00
42B8:00 00 00 00 00 00 00 00
42C0:00 00 00 00 00 00 00 00
42C8:00 00 00 00 00 00 00 00
42D0:00 00 00 00 00 00 00 00
42D8:00 00 00 00 00 00 00 00
42E0:00 00 00 00 00 00 00 00
42E8:00 00 00 00 00 00 00 00
42F0:00 00 00 00 00 00 00 00
42F8:00 00 00 00 00 00 00 00
4300:A9 04 D0 16 8E 96 44 8C
4308:97 44 9C 94 44 20 8F 44
4310:8E 98 43 8C 99 43 80 7F
4318:A9 02 8D 52 43 20 8F 44
4320:8E AC 44 8C AD 44 A2 00
4328:AD AC 44 29 0F C9 0A 90
4330:02 69 06 69 B0 9D A6 44
4338:4E AD 44 6E AC 44 4E AD
4340:44 6E AC 44 4E AD 44 6E
4348:AC 44 4E AD 44 6E AC 44
4350:E8 E0 04 D0 D3 CA 30 37
4358:BD A6 44 20 88 44 80 F5
4360:A9 04 D0 02 A9 02 8D 52
4368:43 20 8F 44 A0 00 B1 FE
4370:AA C8 B1 FE A8 80 A9 20
4378:8F 44 A0 00 B1 FE 10 0A
4380:20 88 44 C8 D0 F6 E6 FF
4388:80 F2 09 80 20 88 44 EE
4390:98 43 D0 03 EE 99 43 AD
4398:DE C0 F0 14 30 EE A2 0C
43A0:DD AE 44 F0 05 CA 10 F8
43A8:30 E5 8A 0A AA 7C BB 44
43B0:60 A9 05 D0 06 A9 03 D0
43B8:02 A9 02 8D 1A 44 20 8F
43C0:44 8E AC 44 8C AD 44 9C
43C8:A6 44 9C A7 44 9C A8 44
43D0:A2 10 F8 0E AC 44 2E AD
43D8:44 AD A6 44 6D A6 44 8D
43E0:A6 44 AD A7 44 6D A7 44
43E8:8D A7 44 AD A8 44 6D A8
43F0:44 8D A8 44 CA D0 DC D8
43F8:A2 02 A0 05 BD A6 44 4A
4400:4A 4A 4A 18 69 B0 99 A6
4408:44 88 BD A6 44 29 0F 18
4410:69 B0 99 A6 44 88 CA 10
4418:E3 A2 00 4C 55 43 A9 81
4420:D0 02 A9 01 8D 36 44 20
4428:8F 44 A0 08 8A C9 80 2A
4430:AA 29 01 F0 02 A9 81 49
4438:B0 20 88 44 88 D0 ED 4C
4440:8F 43 20 8F 44 8A 10 0D
4448:A9 AD 20 88 44 8A 49 FF
4450:29 7F 18 69 01 AA A0 00
4458:A9 03 8D 1A 44 4C C1 43
4460:20 8F 44 A0 00 B1 FE F0
4468:D6 20 88 44 C8 D0 F6 E6
4470:FF 80 F2 20 8F 44 A0 00
4478:B1 FE F0 C3 AA C8 B1 FE
4480:20 88 44 CA D0 F7 F0 B7
4488:8D DE C0 EE 89 44 60 20
4490:93 44 AA A0 00 B9 DE C0
4498:EE 94 44 D0 03 EE 97 44
44A0:A8 86 FE 84 FF 60 00 00
44A8:00 00 00 00 00 00 3F 25
44B0:62 75 64 23 78 24 26 40
44B8:70 73 61 1E 44 22 44 42
44C0:44 B1 43 B5 43 B9 43 00
44C8:43 18 43 60 43 64 43 73
44D0:44 60 44 77 43

*/


; Include necessary components based on features requested
ENABLE_BIN      = USE_BIN_ASC || USE_BIN_INV
ENABLE_DEC      = USE_DEC_2   || USE_DEC_3 || USE_DEC_5 || USE_DEC_BYTE
ENABLE_HEX      = USE_HEX_2   || USE_HEX_4 || USE_PTR_2 || USE_PTR_4
ENABLE_PTR      = USE_PTR_2   || USE_PTR_4
ENABLE_STR      = USE_STR_A   || USE_STR_C || USE_STR_PASCAL

; more ca65
.linecont +
NumMeta         = 0 + \
    USE_BIN_ASC     + \
    USE_BIN_INV     + \
    USE_DEC_2       + \
    USE_DEC_3       + \
    USE_DEC_5       + \
    USE_DEC_BYTE    + \
    USE_HEX_2       + \
    USE_HEX_4       + \
    USE_PTR_2       + \
    USE_PTR_4       + \
    USE_STR_A       + \
    USE_STR_C       + \
    USE_STR_PASCAL
;.out .sprintf( "Commands: %d", NumMeta )
.linecont -

.feature labels_without_colons
.feature leading_dot_in_identifiers
; 65C02
.PC02

; This will take a printf-style string and compact it. The '%' is the escape
; character to output the next byte in ASCII (high bit clear) and print a var.
; Otherwise the remaining chars will default to literals having their high bit
; set. To output a literal '%' you will need to manually add it
; as the %% outputs confusingly enough is a single ASCII '%' which is print binary
.macro PRINTM text, endbyte ; text2, text3, text4, text5, text6
    .local h
    h .set $80

    .repeat .strlen(text), I
        .if (.strat(text , I) = '%')
            ; handle special case of last char was %
            .if( h = $00 )
                .byte .strat(text, I) ; ASCII % = PrintBin
                h .set $80
            .else
                h .set $00
            .endif
        .else
            .byte .strat(text, I) | h
            h .set $80
        .endif
    .endrep

    .ifnblank endbyte
        .byte endbyte
    .endif
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

        GBASL   = $26
        GBASH   = $27
        HPOSN   = $F411 ; A= Y, X=lo,Y=hi, sets GBASL, GBASH
        HOME    = $FC58
        TABV    = $FB5B
        COUT    = $FDED
        PREQHEX = $FDD3 ; print '=', then A in hex
        PRBYTE  = $FDDA

; printm pointer for PrintPtr2, PrintPtr4, PrintStrA, PrintStrC, PrintStrP
        _temp   = $FE

        __MAIN = $4000
; DOS3.3 meta -- remove these 2 if running under ProDOS
        .word __MAIN         ; 2 byte BLOAD address
        .word __END - __MAIN ; 2 byte BLOAD size

/*

Output:

X=39 Y=191 $=2345:D5 11010101~10101011
Bin ASC: 01010111 <- ???
Bin REV: 01010111 <- FIXME: Bin INV, Bin REV
Dec2: 99
Dec3: 999
Dec5: 65385
Byte=-128 -001 000 001 127
Hex2: $34
Hex4: $1234
Ptr2: $2000:D5
Ptr4: $2000:AAD5
C     : 'HELLO','WORLD'
Apple : 'HOME'
Pascal: 'Pascal Len 13'

*/

        .org  __MAIN        ; .org must come after header else offsets are wrong

; Demo printm
        JSR HOME

        LDA #$D5
        STA $2000
        LDA #$AA
        STA $2001

        LDA ARGS_DEMO+4     ;HGR Y row
        LDX #$00            ; HGR x.col_lo = 0
        LDY #$00            ;     x.col_hi = 0
        JSR HPOSN
        CLC
        LDA GBASL
        ADC ARGS_DEMO+2     ; HGR x col
        STA GBASL
        TAX
        LDY GBASH

        STX ARGS_DEMO+6     ; aArg[3]
        STY ARGS_DEMO+7
        STX ARGS_DEMO+8     ; aArg[4]
        STY ARGS_DEMO+9

        LDA $2000
        LDY #0
        STA (GBASL),Y
        STA ARGS_DEMO+10    ; aArg[5]
        STZ ARGS_DEMO+11
        STA ARGS_BIN_ASC+2

        JSR ReverseByte
        STA ARGS_DEMO+12    ; aArg[6]
        STZ ARGS_DEMO+13
        STA ARGS_BIN_INV+2

.if ENABLE_BIN && ENABLE_DEC && ENABLE_HEX
        LDY #0
        JSR VTABY
        LDX #<ARGS_DEMO     ; Low  Byte of Address
        LDY #>ARGS_DEMO     ; High Byte of Address
        JSR PrintM
.endif

.if ENABLE_BIN
    .if USE_BIN_ASC
        LDY #1
        JSR VTABY
        LDX #<ARGS_BIN_ASC
        LDY #>ARGS_BIN_ASC
        JSR PrintM
    .endif
    .if USE_BIN_INV
        LDY #2
        JSR VTABY
        LDX #<ARGS_BIN_INV
        LDY #>ARGS_BIN_INV
        JSR PrintM
    .endif
.endif

.if ENABLE_DEC
    .if USE_DEC_2
        LDY #3
        JSR VTABY
        LDX #<ARGS_DEC_2
        LDY #>ARGS_DEC_2
        JSR PrintM
    .endif
    .if USE_DEC_3
        LDY #4
        JSR VTABY
        LDX #<ARGS_DEC_3
        LDY #>ARGS_DEC_3
        JSR PrintM
    .endif
    .if USE_DEC_5
        LDY #5
        JSR VTABY
        LDX #<ARGS_DEC_5
        LDY #>ARGS_DEC_5
        JSR PrintM
    .endif
    .if USE_DEC_BYTE
        LDY #6
        JSR VTABY
        LDX #<ARGS_DEC_BYTE
        LDY #>ARGS_DEC_BYTE
        JSR PrintM
    .endif  ; USE_DEC_BYTE
.endif

.if ENABLE_HEX
    .if USE_HEX_2
        LDY #7
        JSR VTABY
        LDX #<ARGS_HEX_2
        LDY #>ARGS_HEX_2
        JSR PrintM
    .endif
    .if USE_HEX_4
        LDY #8
        JSR VTABY
        LDX #<ARGS_HEX_4
        LDY #>ARGS_HEX_4
        JSR PrintM
    .endif
    .if USE_PTR_2
        LDY #9
        JSR VTABY
        LDX #<ARGS_PTR_2
        LDY #>ARGS_PTR_2
        JSR PrintM
    .endif
    .if USE_PTR_4
        LDY #10
        JSR VTABY
        LDX #<ARGS_PTR_4
        LDY #>ARGS_PTR_4
        JSR PrintM
    .endif
.endif

.if ENABLE_STR
    .if USE_STR_C
        LDY #11
        JSR VTABY
        LDX #<ARGS_STR_C
        LDY #>ARGS_STR_C
        JSR PrintM
    .endif

    .if USE_STR_A
        LDY #12
        JSR VTABY
        LDX #<ARGS_STR_A
        LDY #>ARGS_STR_A
        JSR PrintM
    .endif

    .if USE_STR_PASCAL
        LDY #13
        JSR VTABY
        LDX #<ARGS_STR_PASCAL
        LDY #>ARGS_STR_PASCAL
        JSR PrintM
    .endif
.endif  ; ENABLE_STR

        LDA #14
        JSR TABV

; old-skool text/hex printing
        LDY #0
@_Text
        LDA PRINTM_TEXT,Y
        BEQ @_Size
        JSR COUT
        INY
        BNE @_Text
@_Size

        LDA PRINTM_SIZE+1
        JSR PRBYTE
        LDA PRINTM_SIZE+0
        JSR PRBYTE
        LDA #$8D
        JMP COUT

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

; Pad until end of page so data starts on new page
;    ds 256 - <*

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

; ______________________________________________________________________

TEXT_DEMO
    ;byte "X=## Y=ddd $=xxxx:@@ %%%%%%%%~????????"
    PRINTM "X=%# Y=%d $=%x:%@ %%~%?", 0

ARGS_DEMO
    dw TEXT_DEMO; aArg[ 0] text
    dw 39       ; aArg[ 1] x
    dw 191      ; aArg[ 2] y
    dw $C0DE    ; aArg[ 3] addr  ScreenAddr
    dw $C0DE    ; aArg[ 4] byte  ScreenAddr pointer
    dw $DA1A    ; aArg[ 5] bits  ScreenByte
    dw $DA1A    ; aArg[ 6] bits  ScreenByte reversed

; ______________________________________________________________________

TEXT_BIN_ASC    PRINTM "Bin ASC: %%", 0
TEXT_BIN_INV    PRINTM "Bin INV: %?", 0

ARGS_BIN_ASC
    dw TEXT_BIN_ASC
    dw $DA1A

ARGS_BIN_INV
    dw TEXT_BIN_INV
    dw $DA1A

; ______________________________________________________________________

TEXT_DEC_2      PRINTM "Dec2: %#", 0
TEXT_DEC_3      PRINTM "Dec3: %d", 0
TEXT_DEC_5      PRINTM "Dec5: %u", 0
TEXT_DEC_BYTE   PRINTM "Byte=%b %b %b %b %b", 0

ARGS_DEC_2
    dw TEXT_DEC_2
    dw 99       ;

ARGS_DEC_3
    dw TEXT_DEC_3
    dw 999      ;

ARGS_DEC_5
    dw TEXT_DEC_5
    dw $FF69    ; $FF69 = 65385

ARGS_DEC_BYTE
    dw TEXT_DEC_BYTE
    dw $80      ; -128
    dw $FF      ; -001
    dw $00      ;  000
    dw $01      ; +001
    dw $7F      ; +127

; ______________________________________________________________________

TEXT_HEX_2  PRINTM "Hex2: %$", 0
TEXT_HEX_4  PRINTM "Hex4: %x", 0
TEXT_PTR_2  PRINTM "Ptr2: %x:%@", 0
TEXT_PTR_4  PRINTM "Ptr4: %x:%&", 0

ARGS_HEX_2
    dw TEXT_HEX_2
    dw $1234

ARGS_HEX_4
    dw TEXT_HEX_4
    dw $1234

ARGS_PTR_2
    dw TEXT_PTR_2
    dw $2000
    dw $2000

ARGS_PTR_4
    dw TEXT_PTR_4
    dw $2000
    dw $2000

; ______________________________________________________________________

TEXT_HELLO
    APPLE "HELLO"
    db 0

TEXT_WORLD
    APPLE "WORLD"
    db 0

TEXT_DCI
    DCI "HOME"

TEXT_PASCAL
    PASCAL "Pascal Len 13"


TEXT_STR_C
    PRINTM "C     : '%s','%s'", 0
TEXT_STR_A
    PRINTM "Apple : '%a'", 0
TEXT_STR_PASCAL
    PRINTM "Pascal: '%p'", 0

ARGS_STR_C
    dw TEXT_STR_C
    dw TEXT_HELLO
    dw TEXT_WORLD


ARGS_STR_A
    dw TEXT_STR_A
    dw TEXT_DCI

ARGS_STR_PASCAL
    dw TEXT_STR_PASCAL
    dw TEXT_PASCAL

; ______________________________________________________________________

PRINTM_TEXT APPLE "printm().size = $"
            db 0
PRINTM_SIZE
            dw __END - PrintM


; Pad until end of page so PrintM starts on new page
    ds 256 - <*


; self-modifying variable aliases

        _pScreen     = PutChar   +1
        _pFormat     = GetFormat +1
        _iArg        = NxtArgByte+1
        _pArg        = IncArg    +1
.if ENABLE_DEC
        _nDecWidth   = DecWidth  +1
.endif ; ENABLE_DEC
.if ENABLE_HEX
        _nHexWidth   = HexWidth  +1

    .if USE_HEX_4
        PrintHex4:
                LDA #4
                BNE _PrintHex
    .endif
.endif


; Note: The dummy address $C0DE is to force the assembler
; to generate a 16-bit address instead of optimizing a ZP operand
;
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

; $ Hex 2 Byte
; x Hex 4 Byte
; ======================================================================
    .if USE_HEX_2
        PrintHex2:
                LDA #2
    .endif

        _PrintHex:
                STA _nHexWidth
                JSR NxtArgYX

        ; Print 16-bit Y,X in hex
        ; Uses _nHexWidth to limit output width
        PrintHexYX:
                STX _val+0      ; may be tempting to move this to NxtArgYX
                STY _val+1      ; as XYtoVal but others call us

                LDX #0
        _HexDigit:
                LDA _val+0
                AND #$F
                CMP #$A         ; n < 10 ?
                BCC _Hex2Asc
                ADC #6          ; n += 6    $A -> +6 + (C=1) = $11
        _Hex2Asc:
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
        HexWidth:
                CPX #4          ; _nHexWidth NOTE: self-modifying!
                BNE _HexDigit
                                ; Intentional fall into reverse BCD
.endif

.if ENABLE_HEX || ENABLE_DEC
; On Entry: X number of chars to print in buffer _bcd
; ======================================================================
PrintReverseBCD
        DEX
        BMI NextFormat
        LDA _bcd, X
        JSR PutChar
        BRA PrintReverseBCD

.endif

.if ENABLE_HEX
; @ Ptr 2 Byte
; & Ptr 4 Byte
; ======================================================================
    .if USE_PTR_4
        PrintPtr4:
                LDA #4
                BNE _PrintPtr
    .endif

    .if USE_PTR_2
        PrintPtr2:
                LDA #2
    .endif

    .if ENABLE_PTR
        _PrintPtr:
                STA _nHexWidth
                JSR NxtArgToTemp

                LDY #$0
                LDA (_temp),Y
                TAX
                INY
                LDA (_temp),Y
                TAY

                BRA PrintHexYX  ; needs XYtoVal setup
    .endif  ; ENABLE_PTR
.endif  ; ENABLE_HEX


.if ENABLE_STR
; a String (APPLE text, last byte ASCII)
; See: DCI
; ======================================================================
    .if USE_STR_A
        PrintStrA:
                JSR NxtArgToTemp

                LDY #$0
        _PrintStrA:
                LDA (_temp),Y
                BPL @_LastChar
                JSR PutChar
                INY
                BNE _PrintStrA
                INC _temp+1
                BRA _PrintStrA
        @_LastChar:             ; intentional fall into Print
    .endif ; USE_STR_A
.endif  ; ENABLE_STR

; Main loop of printm() ... print literal chars
; ======================================================================
ForceAPPLE
        ORA #$80
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

; NOTE: If all features are turned off LDX #-1 ca65 throws Range Error
;             NumMeta = _MetaCharEnd - MetaChar
;        LDX #NumMeta-1  ; pos = meta
; We can't use this equation since it is not const due to the assembler
; not having defined _MetaCharEnd yet
; Instead we count the number of features enabled
.if (NumMeta > 0)
        LDX #NumMeta-1  ; pos = meta
.else
        .out "INFO: No meta commands, defaulting to text"
        BRA ForceAPPLE
.endif

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
    .if USE_DEC_5
        PrintDec5:
                LDA #5
                BNE _PrintDec   ; always
    .endif

    .if USE_DEC_3
        PrintDec3:
                LDA #3
                BNE _PrintDec   ; always
    .endif

    .if USE_DEC_2
        PrintDec2:
                LDA #2          ; 2 digits
    .endif

        _PrintDec:
                STA _nDecWidth
                JSR NxtArgYX

        PrintDecYX:
                STX _val+0      ; may be tempting to move this to NxtArgYX
                STY _val+1      ; as XYtoVal but others call us

                STZ _bcd+0
                STZ _bcd+1
                STZ _bcd+2

        Dec2BCD:
                LDX   #16
                SED
        _Dec2BCD:
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

        BCD2Char:
                LDX #2
                LDY #5
        _BCD2Char:
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

        DecWidth:
                LDX #0      ; _nDecDigits NOTE: self-modifying!
                JMP PrintReverseBCD
.endif  ; ENABLE_DEC

; ______________________________________________________________________

.if ENABLE_BIN
; % Bin 1 Byte normal  ones, normal zeroes
; ? Bin 1 Byte inverse ones, normal zeroes
; ======================================================================
    .if USE_BIN_INV
        PrintBinInv:
                LDA #$81
                BNE _PrintBin
    .endif  ; USE_BIN_INV

    .if USE_BIN_ASC
        PrintBinAsc:
                LDA #$01
    .endif  ; USE_BIN_ASC

        _PrintBin:
                STA _PrintBit+1
                JSR NxtArgYX    ; X = low byte

                LDY #8          ; print 8 bits
        _Bit2Asc:
                TXA
                CMP #$80        ; C= A>=$80
                ROL             ; C<-76543210<-C
                TAX
                AND #$01        ; 0 -> B0
                BEQ _FlipBit
        _PrintBit:
                LDA #$81        ; 1 -> 31 NOTE: self-modifying!
        _FlipBit:
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
    .if USE_DEC_BYTE
        PrintByte:
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
        PrintBytePos:
                TAX

                LDY #00         ; 00XX
                LDA #3          ; 3 digits max
                STA _nDecWidth
                JMP PrintDecYX  ; needs XYtoVal setup
    .endif ; USE_DEC_BYTE
.endif  ; ENABLE_DEC

; ______________________________________________________________________


.if ENABLE_STR

; s String (C,ASCIIZ)
; ======================================================================
    .if USE_STR_C
        PrintStrC:
                JSR NxtArgToTemp

                LDY #$0
        @_NextByte:
                LDA (_temp),Y
                BEQ _JumpNextFormat
                JSR PutChar
                INY
                BNE @_NextByte
                INC _temp+1
                BRA @_NextByte
    .endif

; p String (Pascal)
; ======================================================================
    .if USE_STR_PASCAL
        PrintStrP:
                JSR NxtArgToTemp

                LDY #$0
                LDA (_temp),Y
                BEQ _JumpNextFormat
                TAX
        _PrintStrP:
                INY
                LDA (_temp),Y
                JSR PutChar
                DEX
                BNE _PrintStrP
                BEQ _JumpNextFormat ; always
    .endif
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
    .if USE_BIN_INV
        db '?'  ; PrintBinInv   NOTE: 1's printed in inverse
    .endif
    .if USE_BIN_INV
        db '%'  ; PrintBinAsc
    .endif
.endif
.if ENABLE_DEC
    .if USE_DEC_BYTE
        db 'b'  ; PrintByte     NOTE: Signed -128 .. +127
    .endif
    .if USE_DEC_5
        db 'u'  ; PrintDec5
    .endif
    .if USE_DEC_3
        db 'd'  ; PrintDec3
    .endif
    .if USE_DEC_2
        db '#'  ; PrintDec2
    .endif
.endif
.if ENABLE_HEX
    .if USE_HEX_4
        db 'x'  ; PrintHex4
    .endif
    .if USE_HEX_2
        db '$'  ; PrintHex2
    .endif
    .if USE_PTR_4
        db '&'  ; PrintPtr4
    .endif
    .if USE_PTR_2
        db '@'  ; PrintPtr2
    .endif
.endif
.if ENABLE_STR
    .if USE_STR_PASCAL
        db 'p'  ; PrintStrP     NOTE: Pascal string; C printf 'p' is pointer!
    .endif
    .if USE_STR_C
        db 's'  ; PrintStrC     NOTE: C string, zero terminated
    .endif
    .if USE_STR_A
        db 'a'  ; PrintStrA     NOTE: Last byte is ASCII
    .endif
.endif

_MetaCharEnd

MetaFunc

.if ENABLE_BIN
    .if USE_BIN_INV
        dw PrintBinInv
    .endif
    .if USE_BIN_ASC
        dw PrintBinAsc
    .endif
.endif
.if ENABLE_DEC
    .if USE_DEC_BYTE
        dw PrintByte
    .endif
    .if USE_DEC_5
        dw PrintDec5
    .endif
    .if USE_DEC_3
        dw PrintDec3
    .endif
    .if USE_DEC_2
        dw PrintDec2
    .endif
.endif
.if ENABLE_HEX
    .if USE_HEX_4
        dw PrintHex4
    .endif
    .if USE_HEX_2
        dw PrintHex2
    .endif
    .if USE_PTR_4
        dw PrintPtr4
    .endif
    .if USE_PTR_2
        dw PrintPtr2
    .endif
.endif
.if ENABLE_STR
    .if USE_STR_PASCAL
        dw PrintStrP
    .endif
    .if USE_STR_C
        dw PrintStrC
    .endif
    .if USE_STR_A
        dw PrintStrA
    .endif
.endif

__END

