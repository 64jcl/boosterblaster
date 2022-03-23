
// Written by John Christian Lønningdal - 2022

//-----------------------------------------------------------------------------------
// The Commodore IO resides in the memory area $d000-$dfff (4kb)
//
// Through this address range you can control the VIC-II video chip, the SID sound
// chip and the two CIA's that is connected to the keyboard, joystick ports, user
// port and serial port. The CIA's also have built in timers that can generate
// interrupts (as well as the VIC-II that can generate raster interrupts).
// Any extra special hardware like a REU (Ram Expansion) connected to the machine 
// would often map into the free areas of the IO range.
//
// Some notes about the VIC-II:
// Since the screen contains more than 256 pixels in both with and height there are
// some registers that also have a 9th bit stored in another register.
// For sprites this only affects the X position where the highest bit for each
// sprite is stored together in one byte, SPRITE_XMSB.
// For current raster line the 9th bit is stored in SCREEN_CONTROL.
// Note that even though there is more than 256 lines on the screen, the actual
// visible area with characters is only 200 lines. Since sprites will be hidden
// by the borders (unless they are turned off with a trick) the Y position of
// a sprite is only one byte where the first visible line on the screen is position 50.
// A sprite at position 250 will therefore be totally covered by the bottom border.
// For the x direction the left area of the screen has 24 pixels of border meaning
// that a sprite at position 0 will be totally covered by the border.
// A sprite moving left to right will at x position 255 have to reset this to 0
// and set the XMSB (9th bit) for it to be displayed on the 256th x position.
// At position 344 (XMSB set and X pos at 88) the sprite will be totally covered
// by the border on the right hand side.
// 
// A big advantage of the VIC-IIs ability to report and generate interrupts based
// on which raster line it is drawing, is that you can modify the registers during
// one screen refresh to e.g. move a sprite to another Y position, effectively
// enabling the machine to show more than 8 sprites! This is used a lot in many
// games, and you could also use it to toggle the screen to another screen/charset/
// or even a bitmap if you want.
//
// The VIC-II can also do smooth scrolling in all directions, although the actual
// scrolling is only 8 pixels in any direction. After that you need to redraw the
// whole screen (or switch to another screen, also called double buffering).
// While it is easy to switch a pointer for the character screen, the VIC-II only 
// has one fixed colour attributes area (at $d800) so one will also have to redraw 
// all of that. (There is a trick you can use called VSP for the advanced programmer!)
//-----------------------------------------------------------------------------------

// VIC-II Screen memory selection (used for CHAR_PTR)
.const SCR_0000 = %00000000
.const SCR_0400 = %00010000
.const SCR_0800 = %00100000
.const SCR_0C00 = %00110000
.const SCR_1000 = %01000000
.const SCR_1400 = %01010000
.const SCR_1800 = %01100000
.const SCR_1C00 = %01110000
.const SCR_2000 = %10000000
.const SCR_2400 = %10010000
.const SCR_2800 = %10100000
.const SCR_2C00 = %10110000
.const SCR_3000 = %11000000
.const SCR_3400 = %11010000
.const SCR_3800 = %11100000
.const SCR_3C00 = %11110000

// VIC-II Character memory selection (used for CHAR_PTR)
// Add this to the scr value above when setting CHAR_PTR
.const CHAR_0000 = %00000000
.const CHAR_0800 = %00000010
.const CHAR_1000 = %00000100
.const CHAR_1800 = %00000110
.const CHAR_2000 = %00001000
.const CHAR_2800 = %00001010
.const CHAR_3000 = %00001100
.const CHAR_3800 = %00001110

// A list of bits for SCREEN_CONTROL1 - Note that the _AND are masks
// for the bits in order to clear that value so for example to set screen to 24 rows you do: 
//   lda SCREEN_CONTROL1 - and #CTRL1_24ROWS_AND - sta SCREEN_CONTROL1
.const CTRL1_YSCROLL_AND    = %11111000 // add bits 0-2 for values 0-7
.const CTRL1_24ROWS_AND     = %11110111 // bit 3 cleared
.const CTRL1_25ROWS         = %00001000 // bit 3 set
.const CTRL1_SCREEN_OFF_AND = %11101111 // bit 4 cleared
.const CTRL1_SCREEN_ON      = %00010000 // bit 4 set
.const CTRL1_TEXT_AND       = %11011111 // bit 5 cleared
.const CTRL1_BITMAP         = %00100000 // bit 5 set
.const CTRL1_EXTENDED_AND   = %10111111 // bit 6 cleared
.const CTRL1_EXTENDED       = %01000000 // bit 6 set
.const CTRL1_RASTER8_AND    = %01111111 // bit 7 cleared
.const CTRL1_RASTER8        = %10000000 // bit 7 set

// and similar list for SCREEN_CONTROL2
.const CTRL2_XSCROLL_AND    = %11111000 // add bits 0-2 for values 0-7
.const CTRL2_38COLS_AND     = %11110111 // bit 3 cleared
.const CTRL2_40COLS         = %00001000 // bit 3 set
.const CTRL2_HIGHRES_AND    = %11101111 // bit 4 cleared
.const CTRL2_MULTICOLOUR    = %00010000 // bit 4 set

// some constants to the bits on the joystick port
.const JOY_BUTTON = %00010000
.const JOY_UP     = %00000001
.const JOY_DOWN   = %00000010
.const JOY_LEFT   = %00000100
.const JOY_RIGHT  = %00001000

// Convenience macro for loading a value, AND with flag, then store it again
//-----------------------------------------------------------------------------------
.macro AND(reg,flag) 
{
    lda reg
    and #flag
    sta reg
}
.macro CLEAR(reg,flag) 
{
    :AND(reg,255-flag)
}

// Convenience macro for loading a value, OR with flag, then store it again
//-----------------------------------------------------------------------------------
.macro OR(reg,flag) 
{
    lda reg
    ora #flag
    sta reg
}
.macro SET(reg,flag) 
{
    :OR(reg,flag)
}

//-----------------------------------------------------------------------------------
// THE VIC-II video registers
//-----------------------------------------------------------------------------------
.namespace VIC {

    // sprite X and Y positions for each of the 8 sprites
    .label SPRITE0_XPOS = $d000
    .label SPRITE0_YPOS = $d001
    .label SPRITE1_XPOS = $d002
    .label SPRITE1_YPOS = $d003
    .label SPRITE2_XPOS = $d004
    .label SPRITE2_YPOS = $d005
    .label SPRITE3_XPOS = $d006
    .label SPRITE3_YPOS = $d007
    .label SPRITE4_XPOS = $d008
    .label SPRITE4_YPOS = $d009
    .label SPRITE5_XPOS = $d00a
    .label SPRITE5_YPOS = $d00b
    .label SPRITE6_XPOS = $d00c
    .label SPRITE6_YPOS = $d00d
    .label SPRITE7_XPOS = $d00e
    .label SPRITE7_YPOS = $d00f

    // Sprite #0-#7 X-coordinates (bit #8). Bits:
    //  Bit #x: Sprite #x X-coordinate bit #8.
    .label SPRITE_XMSB = $d010

    // Screen control register #1. Bits:
    //  Bits #0-#2: Vertical raster scroll.
    //  Bit #3: Screen height; 0 = 24 rows; 1 = 25 rows.
    //  Bit #4: 0 = Screen off, complete screen is covered by border; 1 = Screen on, normal screen contents are visible.
    //  Bit #5: 0 = Text mode; 1 = Bitmap mode.
    //  Bit #6: 1 = Extended background mode on.
    //  Bit #7: Read:  Current raster line (bit #8).
    //          Write: Raster line to generate interrupt at (bit #8).
    .label SCREEN_CONTROL1 = $d011

    // raster position 8 lower (read to get current raster or write to set raster irq)
    .label RASTER = $d012

    // light pen x coordinate (read only)
    .label LIGHTPEN_X = $d013
    // light pen y coordinate (read only)
    .label LIGHTPEN_Y = $d014

    // set which of the 8 sprites are enabled
    .label SPRITE_ENABLE = $d015

    // Screen control register #2. Bits:
    //  Bits #0-#2: Horizontal raster scroll.
    //  Bit #3: Screen width; 0 = 38 columns; 1 = 40 columns.
    //  Bit #4: 1 = Multicolor mode on. 0 = high res mode
    .label SCREEN_CONTROL2 = $d016

    // sprite vertical expand for each of the 8 sprites
    .const SPRITE_VERTICAL_EXPAND = $d017

    // screen and charset pointer - add the SCR_ and CHAR_ constants to set screen and charset pointers
    .label SCREEN_CHARSET_PTR = $d018

    // Interrupt status register. Read bits:
    //  Bit #0: 1 = Current raster line is equal to the raster line to generate interrupt at.
    //  Bit #1: 1 = Sprite-background collision occurred.
    //  Bit #2: 1 = Sprite-sprite collision occurred.
    //  Bit #3: 1 = Light pen signal arrived.
    //  Bit #7: 1 = An event (or more events), that may generate an interrupt, occurred and it has not been (not all of them have been) acknowledged yet.
    // Write bits:
    //  Bit #0: 1 = Acknowledge raster interrupt.
    //  Bit #1: 1 = Acknowledge sprite-background collision interrupt.
    //  Bit #2: 1 = Acknowledge sprite-sprite collision interrupt.
    //  Bit #3: 1 = Acknowledge light pen interrupt.
    .label IRQ_STATUS = $d019
    // note that in code examples you often see "asl $d019" used to acknowledge raster IRQ
    // any write to $d019 will acknowledge the interrupts

    // Interrupt control register. Bits:
    //  Bit #0: 1 = Raster interrupt enabled.
    //  Bit #1: 1 = Sprite-background collision interrupt enabled.
    //  Bit #2: 1 = Sprite-sprite collision interrupt enabled.
    //  Bit #3: 1 = Light pen interrupt enabled.
    .label IRQ_CONTROL = $d01a

    // Sprite priority register. Bits:
    // Bit #x: 0 = Sprite #x is drawn in front of screen contents; 1 = Sprite #x is behind screen contents.
    .label SPRITE_CHAR_PRI = $d01b
    // sprite multicolour mode for each of the 8 sprites
    .label SPRITE_MULTICOLOUR = $d01c
    // sprite horizontal expand for each of the 8 sprites
    .label SPRITE_HORIZONTAL_EXPAND = $d01d

    // sprite to sprite collision register. 
    // Read:  Bit #x: 1 = Sprite #x collided with another sprite.
    // Write: Enable further detection of sprite-sprite collisions.
    .label SPRITE_SPRITE_COLLISION = $d01e

    // sprite to background collision register. 
    // Read:  Bit #x: 1 = Sprite #x collided with background.
    // Write: Enable further detection of sprite-background collisions.
    .label SPRITE_BG_COLLISION = $d01f

    // border colour
    .label BORDER      = $d020
    // screen/background colour
    .label BACKGROUND  = $d021
    .label BACKGROUND0 = $d021
    // character multi colour 1 / extended char mode colour 1
    .label BACKGROUND1 = $d022
    // character multi colour 2 / extended char mode colour 1
    .label BACKGROUND2 = $d023
    // extended char mode colour 3
    .label BACKGROUND3 = $d024

    // sprite multi colours which are common for all sprites
    .label SPRITE_COLOUR1 = $d025
    .label SPRITE_COLOUR2 = $d026

    // sprite colours for each of the 8 sprites
    .label SPRITE0_COLOUR = $d027
    .label SPRITE1_COLOUR = $d028
    .label SPRITE2_COLOUR = $d029
    .label SPRITE3_COLOUR = $d02a
    .label SPRITE4_COLOUR = $d02b
    .label SPRITE5_COLOUR = $d02c
    .label SPRITE6_COLOUR = $d02d
    .label SPRITE7_COLOUR = $d02e

    // 1000 bytes area with colour attribute information (actually 512 bytes)
    // note that only the lower 4 nibbles are used (the upper ones are garbage)
    .label COLOUR_RAM = $d800
    .label SCREEN_COLOUR = COLOUR_RAM

}

.const SID_SIZE = 7

//-----------------------------------------------------------------------------------
// THE SID sound registers
// There are 3 channels each with 7 registers. The registers below only adress
// the first channel. So in order to e.g. set frequency on channel 2 just do
// "sta FREQUENCY_LO+7". It is common to use indexed adressing by e.g. setting
// x register to 0,7 or 14 depending on which channel to address and just set
// values using "sta CONTROL,x" to set the value for that channel.
//-----------------------------------------------------------------------------------
.namespace SID {
    .label CHANNEL1 = $d400
    .label CHANNEL2 = $d400+SID_SIZE
    .label CHANNEL3 = $d400+[SID_SIZE*2]

    .label FREQUENCY_LO   = $d400
    .label FREQUENCY_HI   = $d401

    // Pulse width for when sound is pulse waveform
    .label PULSE_WIDTH_LO = $d402
    .label PULSE_WIDTH_HI = $d403

    // Control register. Bits:
    //  Bit #0: 0 = Voice off, Release cycle; 1 = Voice on, Attack-Decay-Sustain cycle.
    //  Bit #1: 1 = Synchronization enabled.
    //  Bit #2: 1 = Ring modulation enabled.
    //  Bit #3: 1 = Disable voice, reset noise generator.
    //  Bit #4: 1 = Triangle waveform enabled.
    //  Bit #5: 1 = Saw waveform enabled.
    //  Bit #6: 1 = Pulse waveform enabled.
    //  Bit #7: 1 = Noise enabled.
    .label CONTROL = $d404

    // Attack and Decay length. Bits:
    //  Bits #0-#3: Decay length. Values:
    //   6ms,24ms,48ms,72ms,114ms,168ms,204ms,240ms,300ms,750ms,1.5s,2.4s,3s,9s,15s,24s
    //  Bits #4-#7: Attack length. Values:
    //   2ms,8ms,16ms,24ms,38ms,56ms,68ms,80ms,100ms,250ms,500ms,800ms,1s,3s,5s,8s
    .label ATTACK_DELAY = $d405
    .label AD = ATTACK_DELAY

    // Sustain volume and Release length. Bits:
    //  Bits #0-#3: Release length. Values:
    //   6ms,24ms,48ms,72ms,114ms,168ms,204ms,240ms,300ms,750ms,1.5s,2.4s,3s,9s,15s,24s
    //  Bits #4-#7: Sustain volume.
    .label SUSTAIN_RELEASE = $d406
    .label SR = SUSTAIN_RELEASE

    // Channel 2: $d407-$d40d - Channel 3: $d40e-$d413

    // These registers below are not per channel but globally affect all

    // Filter cut off frequency (bits #0-#2). NOTE! Only 3 first bits used!
    .label FILTER_CUTOFF_LO = $d415
    // Filter cut off frequency (bits #3-#10).
    .label FILTER_CUTOFF_HI = $d416
    // Filter control. Bits:
    //  Bit #0: 1 = Voice #1 filtered.
    //  Bit #1: 1 = Voice #2 filtered.
    //  Bit #2: 1 = Voice #3 filtered.
    //  Bit #3: 1 = External voice filtered.
    //  Bits #4-#7: Filter resonance.
    .label FILTER_CONTROL   = $d417
    // Volume and filter modes. Bits:
    // Bits #0-#3: Volume.
    //  Bit #4: 1 = Low pass filter enabled.
    //  Bit #5: 1 = Band pass filter enabled.
    //  Bit #6: 1 = High pass filter enabled.
    //  Bit #7: 1 = Voice #3 disabled.
    .label VOLUME_MODE      = $d418
}

//-----------------------------------------------------------------------------------
// THE CIA registers
//-----------------------------------------------------------------------------------

// The CIA1 is connected to the Keyboard and Joystick ports
// It also has two timers and a real time clock
.namespace CIA1 {

    // Data Port A, keyboard matrix columns and joystick #2. 
    // Read bits:
    //  Bit #0: 0 = Port 2 joystick up pressed.
    //  Bit #1: 0 = Port 2 joystick down pressed.
    //  Bit #2: 0 = Port 2 joystick left pressed.
    //  Bit #3: 0 = Port 2 joystick right pressed.
    //  Bit #4: 0 = Port 2 joystick fire pressed.
    // Write bits:
    //  Bit #x: 0 = Select keyboard matrix column #x.
    //  Bits #6-#7: Paddle selection; %01 = Paddle #1; %10 = Paddle #2.
    .label PORTA = $dc00

    // Data Port B, keyboard matrix rows and joystick #1. 
    // Bits:
    //  Bit #x: 0 = A key is currently being pressed in keyboard matrix row #x, in the column selected at memory address $DC00.
    //  Bit #0: 0 = Port 1 joystick up pressed.
    //  Bit #1: 0 = Port 1 joystick down pressed.
    //  Bit #2: 0 = Port 1 joystick left pressed.
    //  Bit #3: 0 = Port 1 joystick right pressed.
    //  Bit #4: 0 = Port 1 joystick fire pressed.
    .label PORTB = $dc01 

    // Port A data direction register.
    // Bit #x: 
    //  0 = Bit #x in port A can only be read
    //  1 = Bit #x in port A can be read and written
    .label PORTA_DIR = $dc02

    // Port B data direction register.
    // Bit #x: 
    //  0 = Bit #x in port B can only be read
    //  1 = Bit #x in port B can be read and written
    .label PORTB_DIR = $dc03

    // Timer A.
    //  Read: Current timer value.
    //  Write: Set timer start value.
    .label TIMER_A   = $dc04
    // Timer B.
    //  Read: Current timer value.
    //  Write: Set timer start value.
    .label TIMER_B   = $dc06

    // Time of Day, tenth seconds (in BCD). Values: $00-$09. 
    //  Read: Current TOD value.
    //  Write: Set TOD or alarm time.
    .label TOD_10THS = $dc08
    // Time of Day, seconds (in BCD). Values: $00-$59. 
    //  Read: Current TOD value.
    //  Write: Set TOD or alarm time.
    .label TOD_SECS  = $dc09
    // Time of Day, minutes (in BCD). Values: $00-$59. 
    //  Read: Current TOD value.
    //  Write: Set TOD or alarm time.
    .label TOD_MINS  = $dc0a
    // Time of Day, minutes (in BCD).
    //  Read bits:
    //   Bits #0-#5: Hours.
    //   Bit #7: 0 = AM; 1 = PM.
    //  Write: Set TOD or alarm time.
    .label TOD_HOURS = $dc0b

    // Serial shift register. (Bits are read and written upon every positive edge of the CNT pin.)
    .label SERIAL_SHIFT = $dc0c

    // Interrupt control and status register. On interrupt it jumps to the vector at $fffe-$ffff.
    //  Read bits:
    //   Bit #0: 1 = Timer A underflow occurred.
    //   Bit #1: 1 = Timer B underflow occurred.
    //   Bit #2: 1 = TOD is equal to alarm time.
    //   Bit #3: 1 = A complete byte has been received into or sent from serial shift register.
    //   Bit #4: Signal level on FLAG pin, datasette input.
    //   Bit #7: An interrupt has been generated.
    //  Write bits:
    //   Bit #0: 1 = Enable interrupts generated by timer A underflow.
    //   Bit #1: 1 = Enable interrupts generated by timer B underflow.
    //   Bit #2: 1 = Enable TOD alarm interrupt.
    //   Bit #3: 1 = Enable interrupts generated by a byte having been received/sent via serial shift register.
    //   Bit #4: 1 = Enable interrupts generated by positive edge on FLAG pin.
    //   Bit #7: Fill bit; bits #0-#6, that are set to 1, get their values from this bit; bits #0-#6, that are set to 0, are left unchanged.    
    .label IRQ_CTRL_STATUS = $dc0d

    // Timer A control register. Bits:
    //  Bit #0: 0 = Stop timer; 1 = Start timer.
    //  Bit #1: 1 = Indicate timer underflow on port B bit #6.
    //  Bit #2: 0 = Upon timer underflow, invert port B bit #6; 1 = upon timer underflow, generate a positive edge on port B bit #6 for 1 system cycle.
    //  Bit #3: 0 = Timer restarts upon underflow; 1 = Timer stops upon underflow.
    //  Bit #4: 1 = Load start value into timer.
    //  Bit #5: 0 = Timer counts system cycles; 1 = Timer counts positive edges on CNT pin.
    //  Bit #6: Serial shift register direction; 0 = Input, read; 1 = Output, write.
    //  Bit #7: TOD speed; 0 = 60 Hz; 1 = 50 Hz.
    .label TIMER_A_CTRL = $dc0e

    // Timer B control register. Bits:
    //  Bit #0: 0 = Stop timer; 1 = Start timer.
    //  Bit #1: 1 = Indicate timer underflow on port B bit #7.
    //  Bit #2: 0 = Upon timer underflow, invert port B bit #7; 1 = upon timer underflow, generate a positive edge on port B bit #7 for 1 system cycle.
    //  Bit #3: 0 = Timer restarts upon underflow; 1 = Timer stops upon underflow.
    //  Bit #4: 1 = Load start value into timer.
    //  Bits #5-#6: %00 = Timer counts system cycles; %01 = Timer counts positive edges on CNT pin; %10 = Timer counts underflows of timer A; %11 = Timer counts underflows of timer A occurring along with a positive edge on CNT pin.
    //  Bit #7: 0 = Writing into TOD registers sets TOD; 1 = Writing into TOD registers sets alarm time.
    .label TIMER_B_CTRL = $dc0f
    
}

// The CIA2 is connected to the VIC-II chip and controls which 16KB bank it can access RAM
// It it also connected to the serial port and the user port (RS232)
.namespace CIA2 {

    // Port A, serial bus access. Bits:
    //  Bits #0-#1: VIC bank. Values:
    //   %00, 0: Bank #3, $C000-$FFFF, 49152-65535.
    //   %01, 1: Bank #2, $8000-$BFFF, 32768-49151.
    //   %10, 2: Bank #1, $4000-$7FFF, 16384-32767.
    //   %11, 3: Bank #0, $0000-$3FFF, 0-16383. 
    //  Bit #2: RS232 TXD line, output bit.
    //  Bit #3: Serial bus ATN OUT; 0 = High; 1 = Low.
    //  Bit #4: Serial bus CLOCK OUT; 0 = High; 1 = Low.
    //  Bit #5: Serial bus DATA OUT; 0 = High; 1 = Low.
    //  Bit #6: Serial bus CLOCK IN; 0 = Low; 1 = High.
    //  Bit #7: Serial bus DATA IN; 0 = Low; 1 = High.
    .label PORTA = $dd00

    // Port B, RS232 access. 
    //  Read bits:
    //   Bit #0: RS232 RXD line, input bit.
    //   Bit #3: RS232 RI line.
    //   Bit #4: RS232 DCD line.
    //   Bit #5: User port H pin.
    //   Bit #6: RS232 CTS line; 1 = Sender is ready to send.
    //   Bit #7: RS232 DSR line; 1 = Receiver is ready to receive.
    //  Write bits:
    //   Bit #1: RS232 RTS line. 1 = Sender is ready to send.
    //   Bit #2: RS232 DTR line. 1 = Receiver is ready to receive.
    //   Bit #3: RS232 RI line.
    //   Bit #4: RS232 DCD line.
    //   Bit #5: User port H pin.
    .label PORTB = $dd01

    // Port A data direction register.
    // Bit #x: 
    //  0 = Bit #x in port A can only be read
    //  1 = Bit #x in port A can be read and written
    .label PORTA_DIR = $dd02

    // Port B data direction register.
    // Bit #x: 
    //  0 = Bit #x in port B can only be read
    //  1 = Bit #x in port B can be read and written
    .label PORTB_DIR = $dd03

    // Timer A.
    //  Read: Current timer value.
    //  Write: Set timer start value.
    .label TIMER_A   = $dd04
    // Timer B.
    //  Read: Current timer value.
    //  Write: Set timer start value.
    .label TIMER_B   = $dd06

    // Time of Day, tenth seconds (in BCD). Values: $00-$09. 
    //  Read: Current TOD value.
    //  Write: Set TOD or alarm time.
    .label TOD_10THS = $dd08
    // Time of Day, seconds (in BCD). Values: $00-$59. 
    //  Read: Current TOD value.
    //  Write: Set TOD or alarm time.
    .label TOD_SECS  = $dd09
    // Time of Day, minutes (in BCD). Values: $00-$59. 
    //  Read: Current TOD value.
    //  Write: Set TOD or alarm time.
    .label TOD_MINS  = $dd0a
    // Time of Day, minutes (in BCD).
    //  Read bits:
    //   Bits #0-#5: Hours.
    //   Bit #7: 0 = AM; 1 = PM.
    //  Write: Set TOD or alarm time.
    .label TOD_HOURS = $dd0b

    // Serial shift register. (Bits are read and written upon every positive edge of the CNT pin.)
    .label SERIAL_SHIFT = $dd0c

    // Interrupt control and status register. NOTE: CIA2 has a NON-MASKABLE IRQ! On interrupt it jumps to the vector at $fffa-$fffb
    //  Read bits:
    //   Bit #0: 1 = Timer A underflow occurred.
    //   Bit #1: 1 = Timer B underflow occurred.
    //   Bit #2: 1 = TOD is equal to alarm time.
    //   Bit #3: 1 = A complete byte has been received into or sent from serial shift register.
    //   Bit #4: Signal level on FLAG pin, datasette input.
    //   Bit #7: An non-maskable interrupt has been generated.
    //  Write bits:
    //   Bit #0: 1 = Enable non-maskable interrupts generated by timer A underflow.
    //   Bit #1: 1 = Enable non-maskable interrupts generated by timer B underflow.
    //   Bit #2: 1 = Enable TOD alarm non-maskable interrupt.
    //   Bit #3: 1 = Enable non-maskable interrupts generated by a byte having been received/sent via serial shift register.
    //   Bit #4: 1 = Enable non-maskable interrupts generated by positive edge on FLAG pin.
    //   Bit #7: Fill bit; bits #0-#6, that are set to 1, get their values from this bit; bits #0-#6, that are set to 0, are left unchanged.    
    .label IRQ_CTRL_STATUS = $dd0d

    // Timer A control register. Bits:
    //  Bit #0: 0 = Stop timer; 1 = Start timer.
    //  Bit #1: 1 = Indicate timer underflow on port B bit #6.
    //  Bit #2: 0 = Upon timer underflow, invert port B bit #6; 1 = upon timer underflow, generate a positive edge on port B bit #6 for 1 system cycle.
    //  Bit #3: 0 = Timer restarts upon underflow; 1 = Timer stops upon underflow.
    //  Bit #4: 1 = Load start value into timer.
    //  Bit #5: 0 = Timer counts system cycles; 1 = Timer counts positive edges on CNT pin.
    //  Bit #6: Serial shift register direction; 0 = Input, read; 1 = Output, write.
    //  Bit #7: TOD speed; 0 = 60 Hz; 1 = 50 Hz.
    .label TIMER_A_CTRL = $dd0e

    // Timer B control register. Bits:
    //  Bit #0: 0 = Stop timer; 1 = Start timer.
    //  Bit #1: 1 = Indicate timer underflow on port B bit #7.
    //  Bit #2: 0 = Upon timer underflow, invert port B bit #7; 1 = upon timer underflow, generate a positive edge on port B bit #7 for 1 system cycle.
    //  Bit #3: 0 = Timer restarts upon underflow; 1 = Timer stops upon underflow.
    //  Bit #4: 1 = Load start value into timer.
    //  Bits #5-#6: %00 = Timer counts system cycles; %01 = Timer counts positive edges on CNT pin; %10 = Timer counts underflows of timer A; %11 = Timer counts underflows of timer A occurring along with a positive edge on CNT pin.
    //  Bit #7: 0 = Writing into TOD registers sets TOD; 1 = Writing into TOD registers sets alarm time.
    .label TIMER_B_CTRL = $dd0f    

}

// These are the major vectors used for the hardware to act on when
// powering on/reset or when an IRQ interrupt is generated from CIA1 or VIC-II,
// or an NMI interrupt is generated from CIA2.
.const NMI_VECTOR   = $fffa
.const RESET_VECTOR = $fffc
.const IRQ_VECTOR   = $fffe
