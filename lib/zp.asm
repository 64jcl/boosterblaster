
// Written by John Christian Lønningdal - 2020

//-----------------------------------------------------------------------------------
// The Zero page is the first page of 256 bytes in the machine and is an important
// piece of memory for the 6502 processor. The zero page is used frequently by 
// programs for both speed and to necessary for indirect indexed adressing.
// For example the instruction: lda ($fe),y
//
// Besides the two first addresses ($00 and $01) the whole of ZP is actually free for
// programs to use as they wish. But when the machine powers on, there are two
// ROMs that use almost every byte of it for their own routines, the BASIC ROM and
// the KERNAL ROM. So when the computer is "READY" after a boot, the ROMs both
// use the zero page a lot for absolutely anything you do on the screen editor,
// writing basic programs and all.
//
// Naturally for standalone assembly programs that do not need BASIC and even the
// KERNAL functions, you can turn these ROMs off and redirect interrupts to where
// you want them to go - effectively also enabling your program to also read RAM
// that is normally "shadowed" by the two ROMs. Writing to the addresses where
// these two ROMs are at will actually write to the RAM under them always, even
// when they are turned on, but you will not be able to read or jump to your own
// code residing in these areas unless you have turned off the ROMs. However as
// an interesting feature, the VIC-II graphics chip will always see RAM in these
// areas, making them ideal places for custom graphics if you still need to
// have BASIC/KERNAL turned on. There is an exception though and that is the
// CHARGEN ROM that contains the default character set. The VIC-II will always
// see these charsets on the address ranges $1000-$1FFF and $9000-$9FFF.

.const CPU_DEFAULT            = $30 + %111
.const CPU_NO_BASIC           = $30 + %110
.const CPU_NO_BASIC_KERNAL    = $30 + %101
.const CPU_NO_BASIC_KERNAL_IO = $30 + %001
.const CPU_CHARGEN            = $30 + %011 // char rom can be read at $D000-$DFFF

.namespace ZP {

    // Processor port - configure which parts of memory is visible to the CPU
    // Bits #0-#2: Configuration for memory areas $A000-$BFFF, $D000-$DFFF and $E000-$FFFF. Values:
    //  %x00: RAM visible in all three areas.
    //  %x01: RAM visible at $A000-$BFFF and $E000-$FFFF.
    //  %x10: RAM visible at $A000-$BFFF; KERNAL ROM visible at $E000-$FFFF.
    //  %x11: BASIC ROM visible at $A000-$BFFF; KERNAL ROM visible at $E000-$FFFF.
    //  %0xx: Character ROM visible at $D000-$DFFF. (Except for the value %000, see above.)
    //  %1xx: I/O area visible at $D000-$DFFF. (Except for the value %100, see above.)
    // Bit #3: Datasette output signal level.
    // Bit #4: Datasette button status; 0 = One or more of PLAY, RECORD, F.FWD or REW pressed; 1 = No button is pressed.
    // Bit #5: Datasette motor control; 0 = On; 1 = Off.
    .label CPU_PORT = $01

}