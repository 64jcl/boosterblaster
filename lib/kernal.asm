
// Written by John Christian Lønningdal - 2020

//-----------------------------------------------------------------------------------
// The Commodore KERNAL (yes spelled with an A) is a ROM containing large portions of
// the equivalent of an operating system. It has IO management that can talk to disk
// drives, tape drives, printers and modems as well as reading from the keyboard and
// print to the screen. The ROM also contains the default vectors set up for a lot of
// features that are enabled when the machine is turned on so that you can start
// typing BASIC immediately after powerup. It sets up the IRQ so that it can scan
// the keyboard and echo letters onto the screen as well as trigger the BASIC parser
// when you press enter, and blinking a cursor.
//
// Most programs and games needs to focus on speed over versatility so they tend to
// bank out both BASIC and KERNAL ROMs after startup in order to gain access to the
// memory that sits behind it. But the KERNAL still contains some routines that
// can be used to simplify making some programs where you dont want to handle all
// the input/output yourself. It is common for many to still call the keyboard scan
// routines (even in games) to get the key that is being pressed, even though the
// ROM code have some bugs and is not particularly efficient.
//
// It is common to use the KERNAL for simple disk IO, although many choose to swap
// these out as well with fast loading routines since the Commodore 64 was released
// with very slow disk routines (due to timing troubles). Many use a fast loader
// cartridge which will simply replace the vectors used for disk io after installing a
// better loading routine into the drives memory (yes the disks are computers in themselves!).
//-----------------------------------------------------------------------------------

.namespace KERNAL {
    // Clears the screen
    .label CLEAR_SCREEN = $e544

    // Read byte from default input (for keyboard, read a line from the screen). (If not keyboard, must call OPEN and CHKIN beforehands.)
    // Output: A = Byte read.
    .label KERNAL_CHRIN = $ffcf

    // Write byte to default output. (If not screen, must call OPEN and CHKOUT beforehands.)
    // Input: A = Byte to write.
    .label CHROUT = $ffd2

    // Save or restore cursor position.
    // Input: Carry: 0 = Restore from input, 1 = Save to output; X = Cursor column (if Carry = 0); Y = Cursor row (if Carry = 0).
    // Output: X = Cursor column (if Carry = 1); Y = Cursor row (if Carry = 1).
    .label PLOT = $fff0
}
