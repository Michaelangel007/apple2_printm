; ca65
.feature c_comments

/* Version 19
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

With everything enabled printm() takes up $207 = 519 bytes
(Plus 2 bytes in zero page.)

Whoa! I thought you said this was micro!?

With all 15 features turned OFF the core routines use $62 = 98 bytes.

With the common setting (default):
    BinAsc, Dec2, Dec3, Dec5, Hex2, Hex4, and StrA
the size is $162 = 354 bytes

To toggle features on / off change USE_* to 0 or 1:

*/

; NOTE: The Size *also* includes the core routines
;       so the actual implementation size for each feature
;       is actually smaller the size leads you to believe.
;       Also, "common functionality" is also included in the count..

;            core _PrintDec routine.
;
;           Feature  Size Bytes Total            Notes
USE_BIN_ASC     = 1 ; $84 132 \
USE_BIN_INV     = 1 ; $86 134 /  $8B (139 bytes)
USE_DEC_2       = 1 ; $D7 215 \
USE_DEC_3       = 1 ; $D9 217   $106 (262 bytes)
USE_DEC_5       = 1 ; $D9 217
USE_DEC_BYTE    = 1 ; $F3 243 /                  sets ENABLE_DEC
USE_HEX_2       = 1 ; $AF 175 \
USE_HEX_4       = 1 ; $B1 177 /  $B6 (182 bytes)
USE_OCT_3       = 1 ; $9C 156 \
USE_OCT_6       = 1 ; $9E 158 /  $A3 (163 bytes)
USE_PTR_2       = 1 ; $C0 192 \                  sets ENABLE_HEX
USE_PTR_4       = 1 ; $C2 194 /  $C7 (199 bytes)
USE_STR_A       = 1 ; $7A 122 \
USE_STR_C       = 1 ; $7A 122    $A8 (168 bytes)
USE_STR_PASCAL  = 1 ; $7C 124 /

/*

Demo + Library text dump:

4000:20 58 FC A9 D5 8D 00 20
4008:A9 AA 8D 01 20 AD E9 41
4010:A2 00 A0 00 20 11 F4 18
4018:A5 26 6D E7 41 85 26 AA
4020:A4 27 8E EB 41 8C EC 41
4028:8E ED 41 8C EE 41 AD 00
4030:20 A0 00 91 26 8D EF 41
4038:9C F0 41 8D 0B 42 8D 0F
4040:42 20 B4 41 8D F1 41 9C
4048:F2 41 A0 00 20 C4 41 A2
4050:E5 A0 41 20 27 43 A0 01
4058:20 C4 41 A2 09 A0 42 20
4060:27 43 A0 02 20 C4 41 A2
4068:0D A0 42 20 27 43 A0 03
4070:20 C4 41 A2 38 A0 42 20
4078:27 43 A0 04 20 C4 41 A2
4080:3C A0 42 20 27 43 A0 05
4088:20 C4 41 A2 40 A0 42 20
4090:27 43 A0 06 20 C4 41 A2
4098:44 A0 42 20 27 43 A0 07
40A0:20 C4 41 A2 74 A0 42 20
40A8:27 43 A0 08 20 C4 41 A2
40B0:78 A0 42 20 27 43 A0 09
40B8:20 C4 41 A2 7C A0 42 20
40C0:27 43 A0 0A 20 C4 41 A2
40C8:82 A0 42 20 27 43 A0 0B
40D0:20 C4 41 A2 98 A0 42 20
40D8:27 43 A0 0C 20 C4 41 A2
40E0:9C A0 42 20 27 43 A0 0D
40E8:20 C4 41 A2 EC A0 42 20
40F0:27 43 A0 0E 20 C4 41 A2
40F8:E6 A0 42 20 27 43 A0 0F
4100:20 C4 41 A2 F0 A0 42 20
4108:27 43 A9 11 20 5B FB A2
4110:F4 A0 42 20 A3 41 AD 22
4118:43 85 FF 20 DA FD AD 21
4120:43 85 FE 20 DA FD 20 BF
4128:41 20 50 41 A2 06 A0 43
4130:20 A3 41 AE C2 43 E8 86
4138:FE 64 FF 8A 20 DA FD 20
4140:BF 41 20 50 41 A9 8D 4C
4148:ED FD 00 00 00 00 00 00
4150:A2 4A A0 41 86 FC 84 FD
4158:9C 4A 41 9C 4B 41 9C 4C
4160:41 A0 00 A2 10 F8 06 FE
4168:26 FF B1 FC 71 FC 91 FC
4170:C8 B1 FC 71 FC 91 FC C8
4178:B1 FC 71 FC 91 FC C8 A0
4180:00 CA D0 E2 D8 A2 02 BD
4188:4A 41 4A 4A 4A 4A 18 69
4190:B0 20 ED FD BD 4A 41 29
4198:0F 18 69 B0 20 ED FD CA
41A0:10 E5 60 86 FC 84 FD A0
41A8:00 B1 FC F0 06 20 ED FD
41B0:C8 D0 F6 60 A2 08 85 FE
41B8:06 FE 6A CA D0 FA 60 A9
41C0:A0 4C ED FD 98 20 C1 FB
41C8:A6 28 A4 29 8E D8 44 8C
41D0:D9 44 60 D8 BD 23 A0 D9
41D8:BD 64 A0 A4 BD 78 BA 40
41E0:A0 25 FE 3F 00 D3 41 27
41E8:00 BF 00 DE C0 DE C0 1A
41F0:DA 1A DA C2 E9 EE A0 C1
41F8:D3 C3 BA A0 25 00 C2 E9
4200:EE A0 C9 CE D6 BA A0 3F
4208:00 F3 41 1A DA FE 41 1A
4210:DA C4 E5 E3 B2 BA A0 23
4218:00 C4 E5 E3 B3 BA A0 64
4220:00 C4 E5 E3 B5 BA A0 75
4228:00 C2 F9 F4 E5 BD 62 A0
4230:62 A0 62 A0 62 A0 62 00
4238:11 42 63 00 19 42 E7 03
4240:21 42 69 FF 29 42 80 00
4248:FF 00 00 00 01 00 7F 00
4250:C8 E5 F8 B2 BA A0 24 00
4258:C8 E5 F8 B4 BA A0 78 00
4260:D0 F4 F2 B2 BA A0 78 BA
4268:40 00 D0 F4 F2 B4 BA A0
4270:78 BA 26 00 50 42 34 12
4278:58 42 34 12 60 42 00 20
4280:00 20 6A 42 00 20 00 20
4288:CF E3 F4 B3 BA A0 6F 00
4290:CF E3 F4 B6 BA A0 4F 00
4298:88 42 B6 01 90 42 DF 32
42A0:C8 C5 CC CC CF 00 D7 CF
42A8:D2 CC C4 00 C8 CF CD 45
42B0:0D D0 E1 F3 E3 E1 EC A0
42B8:CC E5 EE A0 B1 B3 C3 A0
42C0:A0 A0 A0 A0 BA A0 A7 73
42C8:A7 AC A7 73 A7 00 C1 F0
42D0:F0 EC E5 A0 BA A0 A7 61
42D8:A7 00 D0 E1 F3 E3 E1 EC
42E0:BA A0 A7 70 A7 00 BE 42
42E8:A0 42 A6 42 CE 42 AC 42
42F0:DA 42 B0 42 F0 F2 E9 EE
42F8:F4 ED A8 A9 AE F3 E9 FA
4300:E5 A0 BD A0 A4 00 A0 E2
4308:F9 F4 E5 F3 8D A0 A0 A0
4310:A0 AE E6 E5 E1 F4 F5 F2
4318:E5 F3 A0 BD A0 A4 A0 A0
4320:00 07 02 A9 04 D0 16 8E
4328:E5 44 8C E6 44 9C E3 44
4330:20 DE 44 8E BB 43 8C BC
4338:43 80 7F A9 02 8D 75 43
4340:20 DE 44 8E FB 44 8C FC
4348:44 A2 00 AD FB 44 29 0F
4350:C9 0A 90 02 69 06 69 B0
4358:9D F5 44 4E FC 44 6E FB
4360:44 4E FC 44 6E FB 44 4E
4368:FC 44 6E FB 44 4E FC 44
4370:6E FB 44 E8 E0 04 D0 D3
4378:CA 30 37 BD F5 44 20 D7
4380:44 80 F5 A9 04 D0 02 A9
4388:02 8D 75 43 20 DE 44 A0
4390:00 B1 FE AA C8 B1 FE A8
4398:80 A9 20 DE 44 A0 00 B1
43A0:FE 10 0A 20 D7 44 C8 D0
43A8:F6 E6 FF 80 F2 09 80 20
43B0:D7 44 EE BB 43 D0 03 EE
43B8:BC 43 AD DE C0 F0 12 30
43C0:EE A2 0F CA 30 EC DD FD
43C8:44 D0 F8 8A 0A AA 7C 0C
43D0:45 60 A9 05 D0 06 A9 03
43D8:D0 02 A9 02 8D 3B 44 20
43E0:DE 44 8E FB 44 8C FC 44
43E8:9C F5 44 9C F6 44 9C F7
43F0:44 A2 10 F8 0E FB 44 2E
43F8:FC 44 AD F5 44 6D F5 44
4400:8D F5 44 AD F6 44 6D F6
4408:44 8D F6 44 AD F7 44 6D
4410:F7 44 8D F7 44 CA D0 DC
4418:D8 A2 02 A0 05 BD F5 44
4420:4A 4A 4A 4A 18 69 B0 99
4428:F5 44 88 BD F5 44 29 0F
4430:18 69 B0 99 F5 44 88 CA
4438:10 E3 A2 00 4C 78 43 A9
4440:81 D0 02 A9 01 8D 57 44
4448:20 DE 44 A0 08 8A C9 80
4450:2A AA 29 01 F0 02 A9 81
4458:49 B0 20 D7 44 88 D0 ED
4460:4C B2 43 20 DE 44 8A 10
4468:0D A9 AD 20 D7 44 8A 49
4470:FF 29 7F 18 69 01 AA A0
4478:00 A9 03 8D 3B 44 4C E2
4480:43 A9 06 D0 02 A9 03 8D
4488:AB 44 20 DE 44 A2 00 A5
4490:FE 29 07 18 69 B0 9D F5
4498:44 46 FF 66 FE 46 FF 66
44A0:FE 46 FF 66 FE E8 E0 06
44A8:D0 E5 A2 06 4C 78 43 20
44B0:DE 44 A0 00 B1 FE F0 A8
44B8:20 D7 44 C8 D0 F6 E6 FF
44C0:80 F2 20 DE 44 A0 00 B1
44C8:FE F0 95 AA C8 B1 FE 20
44D0:D7 44 CA D0 F7 F0 89 8D
44D8:DE C0 EE D8 44 60 20 E2
44E0:44 AA A0 00 B9 DE C0 EE
44E8:E3 44 D0 03 EE E6 44 A8
44F0:86 FE 84 FF 60 00 00 00
44F8:00 00 00 00 00 3F 25 62
4500:75 64 23 78 24 26 40 4F
4508:6F 70 73 61 3F 44 43 44
4510:63 44 D2 43 D6 43 DA 43
4518:23 43 3B 43 83 43 87 43
4520:81 44 85 44 C2 44 AF 44
4528:9A 43

*/


; more ca65 features
.linecont +
.feature labels_without_colons
.feature leading_dot_in_identifiers
; 65C02
.PC02

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
_digits ds 6

; Print demotmp in Decimal
PrintDec
        LDX #<_digits
        LDY #>_digits
        STX demoptr+0
        STY demoptr+1

        STZ _digits+0
        STZ _digits+1
        STZ _digits+2

        LDY #0
        LDX #16         ; 16 bits
        SED             ; Double Dabble
@Hex2BCD:
        ASL demotmp+0
        ROL demotmp+1

.if 1
.repeat 3
        LDA (demoptr),Y
        ADC (demoptr),Y
        STA (demoptr),Y
        INY
.endrep
.else
        LDA _digits+0
        ADC _digits+0
        STA _digits+0

        LDA _digits+1
        ADC _digits+1
        STA _digits+1

        LDA _digits+2
        ADC _digits+2
        STA _digits+2
.endif
        LDY #0
        DEX
        BNE @Hex2BCD
        CLD

        LDX #2
@PrintBCD
        LDA _digits, X
        LSR
        LSR
        LSR
        LSR
        CLC
        ADC #'0'+$80
        JSR COUT
        LDA _digits, X
        AND #$F
        CLC
        ADC #'0'+$80
        JSR COUT
        DEX
        BPL @PrintBCD
        RTS

; Can't use printm PrintStr*() as it may not be enabled/available
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

    ; Moved here so NextArg can reach GetFormat
    .if USE_HEX_4
DEBUG .sprintf( "PrintHex4() @ %X", * )
        PrintHex4:
                LDA #4
                BNE _PrintHex
    .endif
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
.if 0
                LDY #3
        @HexShr:
                LSR _val+1      ; 16-bit SHR nibble
                ROR _val+0
                DEY
                BNE @HexShr
.else
                LSR _val+1      ; 16-bit SHR nibble
                ROR _val+0

                LSR _val+1
                ROR _val+0

                LSR _val+1
                ROR _val+0

                LSR _val+1
                ROR _val+0
.endif
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
                BNE _PrintPtr
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
                BNE _PrintDec   ; always
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
        _Dec2BCD:               ; https://en.wikipedia.org/wiki/Double_dabble
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
        _BCD2Char:          ; NOTE: Digits are reversed!
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

; % Bin 1 Byte normal  ones, normal zeroes
; ? Bin 1 Byte inverse ones, normal zeroes
; ======================================================================
.if ENABLE_BIN
    .if USE_BIN_INV
DEBUG .sprintf( "PrintBinI() @ %X", * )
        PrintBinInv:
                LDA #$81
                BNE _PrintBin
    .endif  ; USE_BIN_INV

    .if USE_BIN_ASC
DEBUG .sprintf( "PrintBinA() @ %X", * )
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

; o Print byte in octal (max 3 digits)
; O Print word in octal (max 6 digits)
; ======================================================================
.if ENABLE_OCT
    .if USE_OCT_6
DEBUG .sprintf( "PrintOct6() @ %X", * )
        PrintOct6:
                LDA #6
                BNE _PrintOct
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
        @_Oct2Asc:
                LDA _temp
                AND #7
                CLC
                ADC #'0'+$80
                STA _bcd,x      ; NOTE: Digits are reversed!

                LSR _temp+1
                ROR _temp+0

                LSR _temp+1
                ROR _temp+0

                LSR _temp+1
                ROR _temp+0

                INX
                CPX #6
                BNE @_Oct2Asc
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

DEBUG .sprintf( "Lib   Size: %X (%d bytes)", __LIB_SIZE  , __LIB_SIZE  )
DEBUG .sprintf( "Total Size: %X (%d bytes)", __END-__MAIN, __END-__MAIN)

