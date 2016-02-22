#printm - a modular micro printf replacement for 65C02

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
don't need "every" feature.  Seriously, when was the last time
you _needed_ octal? :-)

printm() has manually been optimized for size. In gcc parlance, `-Os`.
With everything enabled printm() takes up less then 512 bytes.

See the latest code for the exact byte usage!

Michael Pohoreski
Copyleft {c} Feb, 2016
Special Thanks: Sheldon for his 65C02 printf() source, qkumba optimizations

