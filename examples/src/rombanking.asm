
// We can split up code in several files and import them as needed
// Import some to simplify coding the C64 zp/io/kernal
//-----------------------------------------------------------------------------------
#import "lib/zp.asm"
#import "lib/io.asm"
#import "lib/kernal.asm"

// Adds a short basic program that does as SYS basic command to the start
//-----------------------------------------------------------------------------------
:BasicUpstart2(main)

.pc = $fb "Zeropage" virtual
// Zero page is used frequently for faster code and indirect adressing ( e.g. lda ($fb),y )
//-----------------------------------------------------------------------------------

.pc = $0810 "Data"
// Data can reside anywhere, even between the code, but its often wise to put them
// somewhere you can easily refer to all variables used in the program
//-----------------------------------------------------------------------------------

.const SCREEN = $0400 // this is the default screen that the VIC-II is showing on startup

.pc = $0840 "Main"
// The code can also reside anywhere in memory. This is the main entry part which
// our basic SYS command will call to first.
//-----------------------------------------------------------------------------------
main: {

    // A simple program to demonstrate that data can be written to ram
    // even when ROMs are 'shadowing' the ram under them, but can only be
    // read if you turn them off. Notice that when you run the program
    // the two top corner letters are 'TE' inverted and not the letter 'A'
    // we wrote in the two addresses. Only after we banked out the ROMs
    // could the CPU read these back and display those on the line under.

    // store letter 'A' where BASIC ROM and KERNAL ROM resides
    lda #1
    sta $a000
    sta $e000

    // read back value at $a000 and store in top left corner
    lda $a000
    sta SCREEN

    // read back value at $e000 and store in top left corner+1
    lda $e000
    sta SCREEN+1

    // turn off BASIC and KERNAL ROM
    lda #CPU_NO_BASIC_KERNAL
    sta ZP.CPU_PORT

    // read back value at $a000 and store in top left corner+40 (next line)
    lda $a000
    sta SCREEN+40

    // read back value at $e000 and store in top left corner+41 (next line)
    lda $e000
    sta SCREEN+41

    // turn back on BASIC and KERNAL ROM before returning
    lda #CPU_DEFAULT
    sta ZP.CPU_PORT
    
    rts
}
