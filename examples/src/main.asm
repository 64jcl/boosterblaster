
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

.pc = $0820 "Data"
// Data can reside anywhere, even between the code, but its often wise to put them
// somewhere you can easily refer to all variables used in the program
//-----------------------------------------------------------------------------------

.pc = $0900 "Main"
// The code can also reside anywhere in memory. This is the main entry part which
// our basic SYS command will call to first.
//-----------------------------------------------------------------------------------
main: {
    
    rts // returns to basic
}
