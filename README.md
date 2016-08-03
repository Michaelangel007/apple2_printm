#printm - a modular micro printf replacement for 65C02

![printm screenshot](printm.png?raw=true)

Here is a *modular* _micro_ replacement: printm()

* Literals have the high byte set (APPLE text)
* Meta characters have the high bit cleared (ASCII)

```
    $ Hex - print 1 Byte  (2 characters)
    x Hex - print 2 Bytes (4 characters)

    @ Ptr - print hex 1 Byte  at 16-bit pointer
    & Ptr - print hex 2 Bytes at 16-bit pointer

    # Dec - Print 1 Byte  in decimal (max 2 digits)
    d Dec - Print 1 Byte  in decimal (max 3 digits)
    u Dec - Print 2 Bytes in decimal (max 5 digits)
    b Dec - Print signed 1 Byte in decimal

    % Bin - Print 8 bits
    ? Bin - Print 8 bits but 1's in inverse

    o Oct - Print 1 Byte in octal (max 3 digits)
    O Oct - Print 2 Byte in octal (max 6 digits)

    a Str - APPLE text (high bit set), last char is ASCII
    s Str - C string, zero terminated
    p Str - Pascal string, first byte is string length
```

Each option can individually be enabled / disabled
to control the memory footprint since you probably
don't need "every" feature.  Seriously, when was the last time
you _needed_ octal? :-)

printm() has manually been optimized for size. In gcc parlance, `-Os`.
With everything enabled printm() takes up less then 512 bytes.

See the latest code for the exact byte usage!

* By: Michael Pohoreski
* Copyleft {c} Feb, 2016

Special Thanks: 

* Sheldon for his 65C02 printf() source
* qkumba optimizations

Join the discussion in comp.sys.apple2.programmer

* https://groups.google.com/forum/#!topic/comp.sys.apple2.programmer/cXqTp7YLYuo

