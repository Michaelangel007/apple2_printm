; ca65
.feature c_comments
.linecont +
.feature labels_without_colons
.feature leading_dot_in_identifiers
.PC02 ; 65C02

/* Version 29
printm - a modular micro printf replacement for 65C02
Michael Pohoreski
Copyleft {c} Feb, 2016
Special Thanks: Sheldon for his 65C02 printf() source, qkumba optimizations

Problem:

Ideally we want to print an 1:1 mapping of input:output text that includes
literal and variables. We could do this by using mixed ASCII case:

 - high bit characters would be output "as is"
 - ASCII characters would be interpreted as a variable output.

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

Can we fix (a) ?

Can we use a more compact printf-style format string
where we don't waste storing the escape character AND
toggle the high bit on characters on/off as needed?

Yes, if we use a macro!

     PRINTM "X=%# Y=%d $=%x:%@ %%~%?"

Can we fix (b) ?

Yes, by using an unique meta character that has the width associated with it.

This is why the cannonical printf() on the 6502 sucks:

- is bloated by using a meta-character '%' instead of the high bit
- doesn't provide a standard way to print binary *facepalm*
- doesn't provide a standard way to print a dereferenced pointer
- 2 digit, 3 digit and 5 digit decimals requiring wasting "width" characters
  e.g. %2d, %3d, %5d
  When a single character would work instead.
- printf() is notorious for being bloated. If you don't use
  features you can't turn them off to reclaim the memory used
  by the code (or data)

Solution:

Here is a *modular* _micro_ replacement: printm()

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

    o Oct - Print 1 Byte in octal (max 3 digits)
    O Oct - Print 2 Byte in octal (max 6 digits)

    a Str - APPLE text (high bit set), last char is ASCII
    s Str - C string, zero terminated
    p Str - Pascal string, first character is string length


Each option can individually be enabled / disabled
to control the memory footprint since you probably
don't need "every" feature. Seriously, when was the last time
you _needed_ octal? :-)

printm() has manually been optimized for size. In gcc parlance, `-Os`.
With everything enabled printm() takes up $1DC = 476 bytes
(Plus 2 bytes in zero page.)

Whoa! I thought you said this was micro!?

With all 15 features turned OFF the core routines use $62 = 98 bytes.

With the common setting (default):
    BinAsc, Dec2, Dec3, Dec5, Hex2, Hex4, and StrA
the size is $15E = 350 bytes

To toggle features on / off change USE_* to 0 or 1:

*/

; NOTE: The Size *also* includes the core routines
;       so the actual implementation size for each feature
;       is actually smaller the size leads you to believe.
;       Also, "common functionality" is also included in the count..

;            core _PrintDec routine.
;
;           Feature  Size Bytes  Total           Notes
USE_BIN_ASC     = 1 ; $7E 126 \. $85 (134 bytes)
USE_BIN_INV     = 1 ; $80 128 /
USE_DEC_2       = 1 ; $C7 199 \
USE_DEC_3       = 1 ; $C9 201  \.$F2 (242 bytes)
USE_DEC_5       = 1 ; $C9 201  /
USE_DEC_BYTE    = 1 ; $DF 223 /                  sets ENABLE_DEC
USE_HEX_2       = 1 ; $A0 160 \. $A7 (167 bytes)
USE_HEX_4       = 1 ; $A2 162 /
USE_OCT_3       = 1 ; $97 151 \. $9E (158 bytes)
USE_OCT_6       = 1 ; $99 153 /
USE_PTR_2       = 1 ; $B1 177 \. $B8 (184 bytes) sets ENABLE_HEX
USE_PTR_4       = 1 ; $B3 179 /
USE_STR_A       = 1 ; $78 120 \
USE_STR_C       = 1 ; $78 120  > $A6 (166 bytes)
USE_STR_PASCAL  = 1 ; $7A 122 /

/*

Demo + Library text dump:

4000:20 58 FC A9 D5 8D 00 20
4008:A9 AA 8D 01 20 AD D2 41
4010:A2 00 A0 00 20 11 F4 18
4018:A5 26 6D D0 41 85 26 AA
4020:A4 27 8E D4 41 8C D5 41
4028:8E D6 41 8C D7 41 AD 00
4030:20 A0 00 91 26 8D D8 41
4038:9C D9 41 8D F4 41 8D F8
4040:41 20 9D 41 8D DA 41 9C
4048:DB 41 A0 00 20 AD 41 A2
4050:CE A0 41 20 0C 43 A0 01
4058:20 AD 41 A2 F2 A0 41 20
4060:0C 43 A0 02 20 AD 41 A2
4068:F6 A0 41 20 0C 43 A0 03
4070:20 AD 41 A2 21 A0 42 20
4078:0C 43 A0 04 20 AD 41 A2
4080:25 A0 42 20 0C 43 A0 05
4088:20 AD 41 A2 29 A0 42 20
4090:0C 43 A0 06 20 AD 41 A2
4098:2D A0 42 20 0C 43 A0 07
40A0:20 AD 41 A2 5D A0 42 20
40A8:0C 43 A0 08 20 AD 41 A2
40B0:61 A0 42 20 0C 43 A0 09
40B8:20 AD 41 A2 65 A0 42 20
40C0:0C 43 A0 0A 20 AD 41 A2
40C8:6B A0 42 20 0C 43 A0 0B
40D0:20 AD 41 A2 81 A0 42 20
40D8:0C 43 A0 0C 20 AD 41 A2
40E0:85 A0 42 20 0C 43 A0 0D
40E8:20 AD 41 A2 D5 A0 42 20
40F0:0C 43 A0 0E 20 AD 41 A2
40F8:CF A0 42 20 0C 43 A0 0F
4100:20 AD 41 A2 D9 A0 42 20
4108:0C 43 A9 11 20 5B FB A2
4110:DD A0 42 20 8C 41 AD 0B
4118:43 85 FF 20 DA FD AD 0A
4120:43 85 FE 20 DA FD 20 A8
4128:41 20 49 41 A2 EF A0 42
4130:20 8C 41 AE 9E 43 86 FE
4138:64 FF 8A 20 DA FD 20 A8
4140:41 20 49 41 A9 8D 4C ED
4148:FD 9C B8 44 9C B9 44 9C
4150:BA 44 A2 10 F8 06 FE 26
4158:FF A0 FD B9 BB 43 79 BB
4160:43 99 BB 43 C8 D0 F4 CA
4168:D0 EB D8 A2 05 88 B9 BB
4170:43 4A 4A 4A 4A 18 69 B0
4178:20 ED FD CA B9 BB 43 29
4180:0F 18 69 B0 20 ED FD 88
4188:CA 10 E3 60 86 FC 84 FD
4190:A0 00 B1 FC F0 06 20 ED
4198:FD C8 D0 F6 60 A2 08 85
41A0:FE 06 FE 6A CA D0 FA 60
41A8:A9 A0 4C ED FD 98 20 C1
41B0:FB A6 28 A4 29 8E 9B 44
41B8:8C 9C 44 60 D8 BD 23 A0
41C0:D9 BD 64 A0 A4 BD 78 BA
41C8:40 A0 25 FE 3F 00 BC 41
41D0:27 00 BF 00 DE C0 DE C0
41D8:1A DA 1A DA C2 E9 EE A0
41E0:C1 D3 C3 BA A0 25 00 C2
41E8:E9 EE A0 C9 CE D6 BA A0
41F0:3F 00 DC 41 1A DA E7 41
41F8:1A DA C4 E5 E3 B2 BA A0
4200:23 00 C4 E5 E3 B3 BA A0
4208:64 00 C4 E5 E3 B5 BA A0
4210:75 00 C2 F9 F4 E5 BD 62
4218:A0 62 A0 62 A0 62 A0 62
4220:00 FA 41 63 00 02 42 E7
4228:03 0A 42 69 FF 12 42 80
4230:00 FF 00 00 00 01 00 7F
4238:00 C8 E5 F8 B2 BA A0 24
4240:00 C8 E5 F8 B4 BA A0 78
4248:00 D0 F4 F2 B2 BA A0 78
4250:BA 40 00 D0 F4 F2 B4 BA
4258:A0 78 BA 26 00 39 42 34
4260:12 41 42 34 12 49 42 00
4268:20 00 20 53 42 00 20 00
4270:20 CF E3 F4 B3 BA A0 6F
4278:00 CF E3 F4 B6 BA A0 4F
4280:00 71 42 B6 01 79 42 DF
4288:32 C8 C5 CC CC CF 00 D7
4290:CF D2 CC C4 00 C8 CF CD
4298:45 0D D0 E1 F3 E3 E1 EC
42A0:A0 CC E5 EE A0 B1 B3 C3
42A8:A0 A0 A0 A0 A0 BA A0 A7
42B0:73 A7 AC A7 73 A7 00 C1
42B8:F0 F0 EC E5 A0 BA A0 A7
42C0:61 A7 00 D0 E1 F3 E3 E1
42C8:EC BA A0 A7 70 A7 00 A7
42D0:42 89 42 8F 42 B7 42 95
42D8:42 C3 42 99 42 F0 F2 E9
42E0:EE F4 ED A8 A9 AE F3 E9
42E8:FA E5 A0 BD A0 A4 00 A0
42F0:E2 F9 F4 E5 F3 8D A0 A0
42F8:A0 A0 AE E6 E5 E1 F4 F5
4300:F2 E5 F3 A0 BD A0 A4 A0
4308:A0 00 E1 01 8E A8 44 8C
4310:A9 44 9C A6 44 20 A1 44
4318:8E 97 43 8C 98 43 80 76
4320:A9 04 D0 02 A9 02 8D 51
4328:43 20 A1 44 8E BE 44 8C
4330:BF 44 A2 00 AD BE 44 29
4338:0F C9 0A 90 02 69 06 69
4340:B0 9D B8 44 A0 04 4E BF
4348:44 6E BE 44 88 D0 F7 E8
4350:E0 04 D0 E0 CA 30 37 BD
4358:B8 44 20 9A 44 80 F5 A9
4360:04 D0 02 A9 02 8D 51 43
4368:20 A1 44 A0 00 B1 FE AA
4370:C8 B1 FE A8 80 B6 20 A1
4378:44 A0 00 B1 FE 10 0A 20
4380:9A 44 C8 D0 F6 E6 FF 80
4388:F2 09 80 20 9A 44 EE 97
4390:43 D0 03 EE 98 43 AD DE
4398:C0 F0 12 30 EE A2 0F CA
43A0:30 EC DD C0 44 D0 F8 8A
43A8:0A AA 7C CF 44 60 A9 05
43B0:D0 06 A9 03 D0 02 A9 02
43B8:8D 09 44 20 A1 44 8E BE
43C0:44 8C BF 44 9C B8 44 9C
43C8:B9 44 9C BA 44 A2 10 F8
43D0:0E BE 44 2E BF 44 A0 FD
43D8:B9 BB 43 79 BB 43 99 BB
43E0:43 C8 D0 F4 CA D0 E9 D8
43E8:A2 05 88 B9 BB 43 4A 4A
43F0:4A 4A 18 69 B0 9D B8 44
43F8:CA B9 BB 43 29 0F 18 69
4400:B0 9D B8 44 88 CA 10 E3
4408:A2 00 4C 54 43 A9 31 D0
4410:02 A9 B1 8D 23 44 20 A1
4418:44 A0 08 8A 0A AA A9 B0
4420:90 02 A9 B1 20 9A 44 88
4428:D0 F1 4C 8E 43 20 A1 44
4430:8A 10 0A A9 AD 20 9A 44
4438:8A 49 FF AA E8 A0 00 A9
4440:03 8D 09 44 4C BE 43 A9
4448:06 D0 02 A9 03 8D 6E 44
4450:20 A1 44 A2 00 A5 FE 29
4458:07 18 69 B0 9D B8 44 A0
4460:03 46 FF 66 FE 88 D0 F9
4468:E8 E0 06 D0 E8 A2 06 4C
4470:54 43 20 A1 44 A0 00 B1
4478:FE F0 AF 20 9A 44 C8 D0
4480:F6 E6 FF 80 F2 20 A1 44
4488:A0 00 B1 FE F0 9C AA C8
4490:B1 FE 20 9A 44 CA D0 F7
4498:F0 90 8D DE C0 EE 9B 44
44A0:60 20 A5 44 AA A0 00 B9
44A8:DE C0 EE A6 44 D0 03 EE
44B0:A9 44 A8 86 FE 84 FF 60
44B8:00 00 00 00 00 00 00 00
44C0:3F 25 62 75 64 23 78 24
44C8:26 40 4F 6F 70 73 61 0D
44D0:44 11 44 2D 44 AE 43 B2
44D8:43 B6 43 20 43 24 43 5F
44E0:43 63 43 47 44 4B 44 85
44E8:44 72 44 76 43

*/



; Assemble-time diagnostic information
.macro DEBUG text
.if 0
    .out text
.endif
.endmacro

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

; Include necessary components based on features requested
    ENABLE_BIN      = USE_BIN_ASC || USE_BIN_INV
    ENABLE_DEC      = USE_DEC_2   || USE_DEC_3 || USE_DEC_5 || USE_DEC_BYTE
    ENABLE_HEX      = USE_HEX_2   || USE_HEX_4 || USE_PTR_2 || USE_PTR_4
    ENABLE_OCT      = USE_OCT_3   || USE_OCT_6
    ENABLE_PTR      = USE_PTR_2   || USE_PTR_4
    ENABLE_STR      = USE_STR_A   || USE_STR_C || USE_STR_PASCAL

NumMeta         = 0 + \
    USE_BIN_ASC     + \
    USE_BIN_INV     + \
    USE_DEC_2       + \
    USE_DEC_3       + \
    USE_DEC_5       + \
    USE_DEC_BYTE    + \
    USE_HEX_2       + \
    USE_HEX_4       + \
    USE_OCT_3       + \
    USE_OCT_6       + \
    USE_PTR_2       + \
    USE_PTR_4       + \
    USE_STR_A       + \
    USE_STR_C       + \
    USE_STR_PASCAL
DEBUG .sprintf( "Features enabled: %d", NumMeta )


; Only used by demo
        BASL    = $28   ; TXT pointer to cursor
        BASH    = $29
        GBASL   = $26   ; HGR pointer to cursor
        GBASH   = $27
        HGRPAGE = $E6   ; used by HPOSN
        HPOSN   = $F411 ; A=row, X=col.lo,Y=col.hi, sets GBASL, GBASH
        BASCALC = $FBC1 ; A=row, sets BASL, BASH
        HOME    = $FC58
        TABV    = $FB5B
        COUT    = $FDED
        PRBYTE  = $FDDA ; print A in hex
        demoptr = $FC
        demotmp = $FE

        __MAIN = $4000
; DOS3.3 meta -- remove these 2 if running under ProDOS
        .word __MAIN         ; 2 byte BLOAD address
        .word __END - __MAIN ; 2 byte BLOAD size

/*

Output:

X=39 Y=191 $=3FF7:D5 11010101~10101011
Bin ASC: 11010101
Bin INV: 11010101
Dec2: 99
Dec3: 999
Dec5: 65385
Byte=-128 -001 000 001 127
Hex2: 34
Hex4: 1234
Ptr2: 2000:D5
Ptr4: 2000:AAD5
Oct3: 666
Oct6: 031337
Apple : 'HOME'
C     : 'HELLO','WORLD'
Pascal: 'Pascal Len 13'

printm().size = $0209 000521 bytes
    .features = $  0F 000015
*/

        .org  __MAIN        ; .org must come after header else offsets are wrong

; Demo printm
        JSR HOME

        LDA #$20
        STA HGRPAGE

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
        STA ARGS_BIN_INV+2

        JSR ReverseByte
        STA ARGS_DEMO+12    ; aArg[6]
        STZ ARGS_DEMO+13

.if ENABLE_BIN && ENABLE_DEC && ENABLE_HEX
        LDY #0
        JSR VTABY
        LDX #<ARGS_DEMO     ; Low  Byte of Address
        LDY #>ARGS_DEMO     ; High Byte of Address
        JSR PrintM
.endif

.if ENABLE_BIN
DEBUG "+BIN"
    .if USE_BIN_ASC
DEBUG "____:ASC"
        LDY #1
        JSR VTABY
        LDX #<ARGS_BIN_ASC
        LDY #>ARGS_BIN_ASC
        JSR PrintM
    .endif
    .if USE_BIN_INV
DEBUG "____:INV"
        LDY #2
        JSR VTABY
        LDX #<ARGS_BIN_INV
        LDY #>ARGS_BIN_INV
        JSR PrintM
    .endif
.endif

.if ENABLE_DEC
DEBUG "+DEC"
    .if USE_DEC_2
DEBUG "____:Dec2"
        LDY #3
        JSR VTABY
        LDX #<ARGS_DEC_2
        LDY #>ARGS_DEC_2
        JSR PrintM
    .endif
    .if USE_DEC_3
DEBUG "____:Dec3"
        LDY #4
        JSR VTABY
        LDX #<ARGS_DEC_3
        LDY #>ARGS_DEC_3
        JSR PrintM
    .endif
    .if USE_DEC_5
DEBUG "____:Dec5"
        LDY #5
        JSR VTABY
        LDX #<ARGS_DEC_5
        LDY #>ARGS_DEC_5
        JSR PrintM
    .endif
    .if USE_DEC_BYTE
DEBUG "____:DecB"
        LDY #6
        JSR VTABY
        LDX #<ARGS_DEC_BYTE
        LDY #>ARGS_DEC_BYTE
        JSR PrintM
    .endif  ; USE_DEC_BYTE
.endif

.if ENABLE_HEX
DEBUG "+HEX"
    .if USE_HEX_2
DEBUG "____:Hex2"
        LDY #7
        JSR VTABY
        LDX #<ARGS_HEX_2
        LDY #>ARGS_HEX_2
        JSR PrintM
    .endif
    .if USE_HEX_4
DEBUG "____:Hex4"
        LDY #8
        JSR VTABY
        LDX #<ARGS_HEX_4
        LDY #>ARGS_HEX_4
        JSR PrintM
    .endif
    .if USE_PTR_2
DEBUG "____:Ptr2"
        LDY #9
        JSR VTABY
        LDX #<ARGS_PTR_2
        LDY #>ARGS_PTR_2
        JSR PrintM
    .endif
    .if USE_PTR_4
DEBUG "____:Ptr4"
        LDY #10
        JSR VTABY
        LDX #<ARGS_PTR_4
        LDY #>ARGS_PTR_4
        JSR PrintM
    .endif
.endif

.if ENABLE_OCT
DEBUG "+OCT"
    .if USE_OCT_3
DEBUG "____:Oct3"
        LDY #11
        JSR VTABY
        LDX #<ARGS_OCT_3
        LDY #>ARGS_OCT_3
        JSR PrintM
    .endif
    .if USE_OCT_6
DEBUG "____:Oct6"
        LDY #12
        JSR VTABY
        LDX #<ARGS_OCT_6
        LDY #>ARGS_OCT_6
        JSR PrintM
    .endif
.endif

.if ENABLE_STR
DEBUG "+STR"

    .if USE_STR_A
DEBUG "____:StrA"
        LDY #13
        JSR VTABY
        LDX #<ARGS_STR_A
        LDY #>ARGS_STR_A
        JSR PrintM
    .endif

    .if USE_STR_C
DEBUG "____:StrC"
        LDY #14
        JSR VTABY
        LDX #<ARGS_STR_C
        LDY #>ARGS_STR_C
        JSR PrintM
    .endif

    .if USE_STR_PASCAL
DEBUG "____:StrP"
        LDY #15
        JSR VTABY
        LDX #<ARGS_STR_PASCAL
        LDY #>ARGS_STR_PASCAL
        JSR PrintM
    .endif
.endif  ; ENABLE_STR

        LDA #17
        JSR TABV

; "old-skool" text/hex printing: use ROM funcs
        LDX #<PRINTM_TEXT
        LDY #>PRINTM_TEXT
        JSR PrintStringZ

        LDA PRINTM_SIZE+1
        STA demotmp+1
        JSR PRBYTE
        LDA PRINTM_SIZE+0
        STA demotmp+0
        JSR PRBYTE

        JSR PrintSpc
        JSR PrintDec

        LDX #<PRINTM_CMDS
        LDY #>PRINTM_CMDS
        JSR PrintStringZ

        LDX GetNumFeatures+1
        STX demotmp+0
        STZ demotmp+1
        TXA
        JSR PRBYTE

        JSR PrintSpc
        JSR PrintDec

        LDA #$8D
        JMP COUT

; ======================================================================

;        ds 256 - <*

; Print demotmp in Decimal
; NOTE: Can't use printm PrintDec5 as it may not be enabled/available
PrintDec
        STZ _bcd+0
        STZ _bcd+1
        STZ _bcd+2

        LDX #16         ; 16 bits
        SED             ; Double Dabble
@Dec2BCD:
        ASL demotmp+0
        ROL demotmp+1

        LDY #$FD
@DoubleDabble:
        LDA _bcd-$FD,Y
        ADC _bcd-$FD,Y
        STA _bcd-$FD,Y
        INY
        BNE @DoubleDabble

        DEX
        BNE @Dec2BCD
        CLD

        LDX #5          ; was Y
        DEY             ; $FF - $FD = 2
@BCD2Char:              ; NOTE: Digits are reversed!
        LDA _bcd-$FD,Y  ; __c???   _b_?XX   a_YYXX
        LSR
        LSR
        LSR
        LSR
        CLC
        ADC #'0'+$80
        JSR COUT
        DEX
        LDA _bcd-$FD,Y  ; __c??X   _b_YXX   aZYYXX
        AND #$F
        CLC
        ADC #'0'+$80
        JSR COUT
        DEY
        DEX
        BPL @BCD2Char
        RTS

; NOTE: Can't use printm PrintStr*() as it may not be enabled/available
PrintStringZ
        STX demoptr+0
        STY demoptr+1
        LDY #0
@_Text
        LDA (demoptr),Y
        BEQ @_Done
        JSR COUT
        INY
        BNE @_Text
@_Done
        RTS

ReverseByte
        LDX #8
        STA demotmp     ; temp working byte
ReverseBit
        ASL demotmp     ; temp working byte
        ROR
        DEX
        BNE ReverseBit
        RTS

PrintSpc
        LDA #' '+$80
        JMP COUT

VTABY   TYA
        JSR BASCALC
        LDX BASL
        LDY BASH
        STX PutChar+1
        STY PutChar+2
        RTS

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

TEXT_OCT_3  PRINTM "Oct3: %o", 0
TEXT_OCT_6  PRINTM "Oct6: %O", 0

ARGS_OCT_3
    dw TEXT_OCT_3
    dw 438

ARGS_OCT_6
    dw TEXT_OCT_6
    dw 13023

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

PRINTM_CMDS APPLE " bytes"
            db $8D
            APPLE "    .features = $  "
            db 0

__LIB_SIZE = __END - __PRINTM

PRINTM_SIZE
            dw __LIB_SIZE

; Pad until end of page so PrintM starts on new page
;    ds (256 - <*) & 7
;    ds (256 - <*) & 15
;    ds (256 - <*)


; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
;
; printm() library code starts here
;
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
__PRINTM

; pointer for PrintPtr2, PrintPtr4, PrintStrA, PrintStrC, PrintStrP
        _temp   = $FE

; self-modifying variable aliases
        _pScreen     = PutChar   +1
        _pFormat     = GetFormat +1
        _iArg        = NxtArgByte+1
        _pArg        = IncArg    +1
.if ENABLE_DEC
        _nDecWidth   = DecWidth  +1
.endif
.if ENABLE_OCT
        _nOctWidth   = OctWidth  +1
.endif
.if ENABLE_HEX
        _nHexWidth   = HexWidth  +1
.endif

; Entry Point
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


; $ Hex 2 Byte
; x Hex 4 Byte
; ======================================================================
.if ENABLE_HEX

    .if USE_HEX_4
DEBUG .sprintf( "PrintHex4() @ %X", * )
        PrintHex4:
                LDA #4
                ;BNE _PrintHex
                db $2C          ; BIT $abs skip next instruction
    .endif

    .if USE_HEX_2
DEBUG .sprintf( "PrintHex2() @ %X", * )
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
                BCC @Hex2Asc
                ADC #6          ; n += 6    $A -> +6 + (C=1) = $11
        @Hex2Asc:
                ADC #'0' + $80  ; inverse=remove #$80
                STA _bcd, X     ; NOTE: Digits are reversed!

                LDY #4
        @HexShr:
                LSR _val+1      ; 16-bit SHR nibble
                ROR _val+0
                DEY
                BNE @HexShr

                INX
        HexWidth:
                CPX #4          ; _nHexWidth NOTE: self-modifying!
                BNE _HexDigit
                                ; Intentional fall into reverse BCD
.endif

; On Entry: X number of chars to print in buffer _bcd
; ======================================================================
.if ENABLE_HEX || ENABLE_DEC || ENABLE_OCT
PrintReverseBCD
        DEX
        BMI NextFormat
        LDA _bcd, X
        JSR PutChar
        BRA PrintReverseBCD

.endif

; @ Ptr 2 Byte
; & Ptr 4 Byte
; ======================================================================
.if ENABLE_PTR

    .if USE_PTR_4
DEBUG .sprintf( "PrintPtr4() @ %X", * )
        PrintPtr4:
                LDA #4
                ;BNE _PrintPtr
                db $2C          ; BIT $abs skip next instruction
    .endif

    .if USE_PTR_2
DEBUG .sprintf( "PrintPtr2() @ %X", * )
        PrintPtr2:
                LDA #2
    .endif

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


; a String (APPLE text, last byte ASCII)
; See: DCI
; ======================================================================
.if ENABLE_STR
    .if USE_STR_A
DEBUG .sprintf( "PrintStrA() @ %X", * )
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

; ======================================================================
; Main Read/Eval/Print/Loop of printm()
; ======================================================================
; Note: The dummy address $C0DE is to force the assembler
; to generate a 16-bit address instead of optimizing a ZP operand

ForceAPPLE
        ORA #$80
Print                   ; print literal chars
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
GetNumFeatures
.if (NumMeta > 0)
        LDX #NumMeta  ; pos = meta
.else
        .out "INFO: No meta commands, defaulting to text"
        BRA ForceAPPLE
.endif

FindMeta
        DEX
        BMI NextFormat
        CMP MetaChar,X
        BNE FindMeta
CallMeta
        TXA
        ASL
        TAX
        JMP (MetaFunc,X)
_Done
        RTS

; ______________________________________________________________________

; # Dec 1 Byte (max 2 digits)
; d Dec 2 Byte (max 3 digits)
; u Dec 2 Byte (max 5 digits)
; ======================================================================
.if ENABLE_DEC
    .if USE_DEC_5
DEBUG .sprintf( "PrintDec5() @ %X", * )
        PrintDec5:
                LDA #5
                BNE _PrintDec   ; always
    .endif

    .if USE_DEC_3
DEBUG .sprintf( "PrintDec3() @ %X", * )
        PrintDec3:
                LDA #3
                ;BNE _PrintDec   ; always
                db $2C          ; BIT $abs skip next instruction
    .endif

    .if USE_DEC_2
DEBUG .sprintf( "PrintDec2() @ %X", * )
        PrintDec2:
                LDA #2          ; 2 digits
    .endif

    ; no .if USE_DEC_BYTE here because ENABLE_DEC already covers that
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
                LDX   #16       ; 16 bits
                SED             ; "Double Dabble"
        @Dec2BCD:               ; https://en.wikipedia.org/wiki/Double_dabble
                ASL _val+0
                ROL _val+1

                LDY #$FD
        @DoubleDabble:
                LDA _bcd-$FD,Y
                ADC _bcd-$FD,Y
                STA _bcd-$FD,Y
                INY
                BNE @DoubleDabble

                DEX
                BNE @Dec2BCD
                CLD

NEW_PRINT_DEC = 0
.if NEW_PRINT_DEC
        DecWidth:
.endif
                LDX #5          ; was Y
                DEY             ; $FF - $FD = 2
        @BCD2Char:              ; NOTE: Digits are reversed!
                LDA _bcd-$FD,Y  ; __c???   _b_?XX   a_YYXX
                LSR
                LSR
                LSR
                LSR
                CLC
                ADC #'0'+$80
.if NEW_PRINT_DEC
                JSR PutChar
.else
                STA _bcd,X      ; __c??X   _b_YXX   aZYYXX
.endif
                DEX             ; was Y
.if NEW_PRINT_DEC
                BMI NextFormat
.endif
                LDA _bcd-$FD,Y  ; __c??X   _b_YXX   aZYYXX
                AND #$F
                CLC
                ADC #'0'+$80
.if NEW_PRINT_DEC
                JSR PutChar
.else
                STA _bcd,X      ; __c?XX   _bYYXX   ZZYYXX
.endif
                DEY
                DEX
                BPL @BCD2Char

.if NEW_PRINT_DEC
                BMI NextFormat  ; always
.else
        DecWidth:
                LDX #0      ; _nDecDigits NOTE: self-modifying!
                JMP PrintReverseBCD
.endif
.endif  ; ENABLE_DEC

; ______________________________________________________________________

; % Bin 1 Byte normal  ones, normal zeroes
; ? Bin 1 Byte inverse ones, normal zeroes
; ======================================================================
.if ENABLE_BIN
    .if USE_BIN_INV
DEBUG .sprintf( "PrintBinI() @ %X", * )
        PrintBinInv:
                LDA #$31
                ;BNE _PrintBin
                db $2C          ; BIT $abs skip next instruction
    .endif  ; USE_BIN_INV

    .if USE_BIN_ASC
DEBUG .sprintf( "PrintBinA() @ %X", * )
        PrintBinAsc:
                LDA #$B1
    .endif  ; USE_BIN_ASC

        _PrintBin:
                STA _PrintBit+1
                JSR NxtArgYX    ; X = low byte

                LDY #8          ; print 8 bits
        _Bit2Asc:
                TXA
                ASL             ; C= A>=$80
                TAX
                LDA #$B0
                BCC _FlipBit
        _PrintBit:
                LDA #$B1        ; 1 -> 31 NOTE: self-modifying!
        _FlipBit:
                JSR PutChar
                DEY
                BNE _Bit2Asc
.endif  ; ENABLE_BIN

; Left as exercise for the reader to optimize the jump size :-)
_JumpNextFormat
;       BRA NextFormat  ; always
        JMP NextFormat  ; JMP :-(

; b Print a signed byte in decimal
; ======================================================================
.if ENABLE_DEC
    .if USE_DEC_BYTE
DEBUG .sprintf( "PrintDecB() @ %X", * )
        PrintByte:
                JSR NxtArgYX    ; X = low byte
                TXA
                BPL PrintBytePos
                LDA #'-' + $80  ; X >= $80 --> $80 (-128) .. $FF (-1)
                JSR PutChar
                TXA
                EOR #$FF        ; 2's complement
                TAX
                INX
        PrintBytePos:

                LDY #00         ; 00XX
                LDA #3          ; 3 digits max
                STA _nDecWidth
                JMP PrintDecYX  ; needs XYtoVal setup
    .endif ; USE_DEC_BYTE
.endif  ; ENABLE_DEC

; ______________________________________________________________________

; o Print byte in octal (max 3 digits)
; O Print word in octal (max 6 digits)
; ======================================================================
.if ENABLE_OCT
    .if USE_OCT_6
DEBUG .sprintf( "PrintOct6() @ %X", * )
        PrintOct6:
                LDA #6
                ;BNE _PrintOct
                db $2C          ; BIT $abs skip next instruction
    .endif
    .if USE_OCT_3
DEBUG .sprintf( "PrintOct3() @ %X", * )
        PrintOct3:
                LDA #3
    .endif
        _PrintOct:
                STA _nOctWidth
                JSR NxtArgYX    ; X = low byte

                LDX #0
        @Oct2Asc:
                LDA _temp
                AND #7
                CLC
                ADC #'0'+$80
                STA _bcd,x      ; NOTE: Digits are reversed!

                LDY #3
        @OctShr:
                LSR _temp+1
                ROR _temp+0
                DEY
                BNE @OctShr

                INX
                CPX #6
                BNE @Oct2Asc
        OctWidth:
                LDX #6      ; _nOctDigits NOTE: self-modifying!
                JMP PrintReverseBCD
.endif  ; ENABLE_OCT

; ______________________________________________________________________

; s String (C,ASCIIZ)
; ======================================================================
.if ENABLE_STR
    .if USE_STR_C
DEBUG .sprintf( "PrintStrC() @ %X", * )
        PrintStrC:
                JSR NxtArgToTemp

                LDY #$0
        @_NextByte:
                LDA (_temp),Y
                BEQ _JumpNextFormat
                JSR PutChar
                INY
                BNE @_NextByte
                INC _temp+1     ; support strings > 256 chars
                BRA @_NextByte
    .endif
.endif

; p String (Pascal)
; ======================================================================
.if ENABLE_STR
    .if USE_STR_PASCAL
DEBUG .sprintf( "PrintStrP() @ %X", * )
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

; ----------------------------------------------------------------------
; Utility
; ----------------------------------------------------------------------

; ======================================================================
;
PutChar
.if 1
        STA $C0DE       ; _pScreen NOTE: self-modifying!
        INC PutChar+1   ; inc lo
        RTS
.else   ; Alternatively use the monitor ROM char output
        JMP COUT
.endif

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
    .if USE_BIN_ASC
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
.if ENABLE_OCT
    .if USE_OCT_6
        db 'O'  ; PrintOct6
    .endif
    .if USE_OCT_3
        db 'o'  ; PrintOct3
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
.if ENABLE_OCT
    .if USE_OCT_6
        dw PrintOct6
    .endif
    .if USE_OCT_3
        dw PrintOct3
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

DEBUG .sprintf( "Total  size: %X (%d bytes)", __END   -__MAIN, __END   -__MAIN)
DEBUG .sprintf( "Demo   size: %X (%d bytes)", __PRINTM-__MAIN, __PRINTM-__MAIN)
DEBUG .sprintf( "printm size: %X (%d bytes)", __LIB_SIZE     , __LIB_SIZE     )

