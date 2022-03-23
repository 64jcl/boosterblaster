
// Written for the BOOSTER Conference Bergen 2022
// by John Christian Lønningdal and Ricki Sickenger

// Adds a short basic program that adds a SYS basic command to the main code address
// All C64 prg files are loaded at address $0801 (start of basic) hence the first
// bytes of the binary will be this short basic program to call the assembly code.
//-----------------------------------------------------------------------------------
:BasicUpstart2(main)

// We can split up code in several files and import them as needed.
// Remember these can contain code so you need to import them where you
// want to place them unless they also set the .pc directive themselves.
// If files only has constants or labels you generally add them to the top.
// Import some constants and labels to simplify coding the C64 zp/io/kernal
//-----------------------------------------------------------------------------------
.import source "lib/zp.asm"
.import source "lib/io.asm"
.import source "lib/kernal.asm"

// Zero page is used frequently for faster code and indirect adressing ( e.g. lda ($fb),y )
// Here we just place these at the 4 unused bytes at the end of zero page but if basic/kernal
// is not used everything besides the first 2 bytes of zero page can be used freely.
//-----------------------------------------------------------------------------------
.pc = ZP.UNUSED "Zeropage" virtual

src: .word 0 // a source word pointer so we can use indirect adressing
dst: .word 0 // a destination word pointer so we can use indirect adressing

// We load a screen into address $2800
//-----------------------------------------------------------------------------------
.const SCREEN = $2800 // define a constant we can use later in code
.pc = SCREEN "Screen"
.import binary "res/screen.bin"

// We load a custom charset into address $3000
//-----------------------------------------------------------------------------------
.pc = $3000 "Charset"
.import binary "res/chars.bin"

// And finally some sprites into $3800
//-----------------------------------------------------------------------------------
.pc = $3800 "Sprites"
.const SPRITE_IDX = mod(*/64,256) // calculate the index to be set in VIC registers
.import binary "res/sprites.bin"

// Sprite pointers start at 16 bytes after the screen end
.const SPRITE0_POINTER = SCREEN+1016
.const SPRITE1_POINTER = SPRITE0_POINTER+1
.const SPRITE2_POINTER = SPRITE0_POINTER+2
.const SPRITE3_POINTER = SPRITE0_POINTER+3
.const SPRITE4_POINTER = SPRITE0_POINTER+4
.const SPRITE5_POINTER = SPRITE0_POINTER+5
.const SPRITE6_POINTER = SPRITE0_POINTER+6
.const SPRITE7_POINTER = SPRITE0_POINTER+7

// some constants just in case we need to adjust charset etc.
// makes it much easier to adjust things to tweak game

.const CHAR_LIFE   = 65
.const CHAR_BULLET = 66

.const MAX_BULLETS = 20
.const FIRE_RATE   = 10

.const SPRITE_PLAYER = SPRITE_IDX
.const SPRITE_ENEMY  = SPRITE_IDX+1

// some screen positions that we update in the code
.const SCREEN_SCORE  = SCREEN+[12*40]+32
.const SCREEN_LIVES  = SCREEN+[18*40]+33

// number of frames (2 seconds) to countdown on start and when life lost
.const COUNTDOWN_TIME = 100

// Data can reside anywhere, even between the code, but its often wise to put them
// somewhere you can easily refer to all variables used in the program
//-----------------------------------------------------------------------------------
.pc = $0820 "Data"

// colour information per character position
attribs:	.import binary "res/attribs.bin"

// some texts we want to print on the screen (ASSIGNMENT 1)
// note that lower case chars are char indexes from 0 and up (a = 1)
// while upper cases will be 64 char indexes higher (A = 65)
pressButton:
    .text "press button to play"
    .byte 0 // zero terminating string
gameOver:
    .text "game over"
    .byte 0 // zero terminating string

// two lookup tables so that we can quickly get the pointer to each line on the screen!
scrptr_lo:	.fill 25,<[SCREEN+[i*40]] // lo pointer (<)
scrptr_hi:	.fill 25,>[SCREEN+[i*40]] // hi pointer (>)

fire_timer: .byte FIRE_RATE      // a timer that we count down to zero for each fire
cur_bullet: .byte 0              // position of the bullet to add to table
bullets_x:  .fill MAX_BULLETS,0  // x position of bullet
bullets_y:  .fill MAX_BULLETS,-1 // y position of bullet (-1 means not active)

// colours of the player ship and each of the enemies
mobcols: .byte GREY, GREEN,LIGHT_GREEN,RED,LIGHT_RED,BLUE,LIGHT_BLUE,ORANGE

// init y position for each sprite on screen when game starts
moby:    .byte 217, 0,5,10,15,20,25,30

tick:    .byte 0 // a frame counter
cntdown: .byte 0 // a countdown on game start or life lost
lives:   .byte 0 // number of lives

//-----------------------------------------------------------------------------------
// Code can reside anywhere in memory. This is the main entry part which
// our generated basic program with a SYS command will call.
// Our main function contains the screen init and the main loop with a simple state 
// machine where it waits for a joystick button to start game. It then draws the
// game screen and jumps to a the game loop. When that returns it will draw game over
// and wait for joystick press to go back to the top.
//-----------------------------------------------------------------------------------
.pc = $1000 "Main"
main: {
    jsr initGraphicsAndSound
loop:
    jsr drawIntroScreen

waitForButton:	
    jsr readJoystickButton
    bcc waitForButton

    jsr drawGameScreen
    jsr playGameLoop
    jsr drawGameOver

waitAgainForButton:	
    jsr readJoystickButton    
    bcc waitAgainForButton

    jmp loop	
}

// Set border and background colour and switch VIC-II to a custom character set and screen
//-----------------------------------------------------------------------------------
initGraphicsAndSound: {
    lda #DARK_GREY
    sta VIC.BORDER
    lda #BLACK
    sta VIC.BACKGROUND

    // set up the VIC-II so it points to our custom charset + screen
    // note that by default the C64 VIC-II points to bank 0 which is $0000-$3999
    // so there is no need to switch the bank as our screen/charset/sprites is there
    lda #SCR_2800+CHAR_3000
    sta VIC.SCREEN_CHARSET_PTR
    
    jsr drawScreenColours

    lda #15
    sta SID.VOLUME_MODE
    rts
}

// This routine will go through every character on the screen, read its value
// and use that to look up a colour value in a table (attribs), and then write
// that to COLOUR_RAM at $d800 on the VIC-II video chip. Since we only have
// 8 bit registers, we can only index 0 to 255, so we divide the screens 1000
// characters into 4 blocks of 250 chars each and just do 4 separate lookups.
//-----------------------------------------------------------------------------------
drawScreenColours: {
    ldx #0
loop:
    ldy SCREEN,x
    lda attribs,y
    sta VIC.COLOUR_RAM,x
    ldy SCREEN+250,x
    lda attribs,y
    sta VIC.COLOUR_RAM+250,x
    ldy SCREEN+500,x
    lda attribs,y
    sta VIC.COLOUR_RAM+500,x
    ldy SCREEN+750,x
    lda attribs,y
    sta VIC.COLOUR_RAM+750,x
    inx
    cpx #250
    bne loop
    rts
}

// At the moment we just we just show some text on the intro screen
//-----------------------------------------------------------------------------------
drawIntroScreen: {
    jsr printPressButton
    rts
}

//===================================================================================
// ASSIGNMENT 1
// Prints PRESS BUTTON TO START in the middle of the game area (row 12, column 5)
//===================================================================================
printPressButton: {
    ldx #0                   // init X index to zero
loop:
    lda pressButton,x        // load char from string (absolute indexed by X)
    beq end                  // if its zero the string is ended
    sta SCREEN+(12*40)+5,x   // print char to screen at row 12 and starting at column 5
    inx                      // increase X index by one
    jmp loop                 // jump to loop for another character
end:
    rts                      // return from subroutine
}

// Read the joystick button.
// Return: Carry = 0 if no button or just pressed, Carry = 1 when button is released.
//-----------------------------------------------------------------------------------
arm: .byte 0
readJoystickButton: {
    lda CIA1.PORTA  // read Joystick Port 2 (note that a 0 value means a switch on joystick is down)
    ldx arm         // check if already armed (down)
    bne release	    // if so check for release
    and #JOY_BUTTON // otherwise and with button bit to check if its set
    bne exit	    // if not exit
    inc arm         // otherwise we set arm state
exit:
    clc             // clear carry means button is not yet pressed and released
    rts
release:	
    and #JOY_BUTTON // and with button bit to check if its set 
    beq exit        // if not exit
    dec arm         // clear out arm state
    sec             // set carry means button has been pressed and released
    rts
}

// Clear the main game area to the left of the score/status area.
//-----------------------------------------------------------------------------------
clearGameScreen: {
    ldx #0
line:
    lda scrptr_lo,x
    sta dst
    lda scrptr_hi,x
    sta dst+1
    lda #0
    ldy #29
col:
    sta (dst),y
    dey
    bpl col
    inx
    cpx #25
    bne line
    rts
}

// Draw the main game screen, setting up sprites etc.
//-----------------------------------------------------------------------------------
drawGameScreen: {
    jsr clearGameScreen // first clear the game area
    
    // set lives and draw ships on status area
    ldx #3
    stx lives
    ldy #4
lloop:
    lda #CHAR_LIFE
    sta SCREEN_LIVES,y
    dey
    dey
    bpl lloop
    
    // reset score to all zeros
    ldy #6
sloop:
    lda #'0'
    sta SCREEN_SCORE,y
    dey
    bpl sloop
    
    lda #1  // only player is multicolour (enemies are high res)
    sta VIC.SPRITE_MULTICOLOUR
    lda #DARK_GREY
    sta VIC.SPRITE_COLOUR1 // multi colour 1
    lda #LIGHT_GREY
    sta VIC.SPRITE_COLOUR2 // multi colour 2
    
    jmp initGame
}
    
// Initialize a new game. Also called every time you loose a life to restart.
//-----------------------------------------------------------------------------------
initGame: {
    lda #COUNTDOWN_TIME
    sta cntdown
    
    // set sprite indexes and their Y position by copying from moby table and colour from mobcols
    ldx #7
    ldy #14
more:
    lda #SPRITE_ENEMY
    sta SPRITE0_POINTER,x     // all sprites set to enemy
    jsr getRandomX
    sta VIC.SPRITE0_XPOS,y    // get a random X position and set that for sprite
    lda moby,x
    sta VIC.SPRITE0_YPOS,y    // x/y are staggered so need its own index!
    lda mobcols,x
    sta VIC.SPRITE0_COLOUR,x
    dey
    dey
    dex
    bpl more // until X index i 255 (-1) - so this means we also set ship sprite values too
    
    // we need to write some ship sprite values as only colour and X position is correct from the loop above 
    lda #SPRITE_PLAYER
    sta SPRITE0_POINTER    // set sprite 0 to ship sprite
    lda #1                 
    sta VIC.SPRITE_ENABLE  // enable only ship sprite first 
    lda #130
    sta VIC.SPRITE0_XPOS   // set ship start X position

    rts
}

// The main loop where the game playing code is run.
//-----------------------------------------------------------------------------------
playGameLoop: {
    inc tick	    // a frame counter used for e.g. animation

    lda #250		// wait for screen raster to reach line 250 (at the bottom border)
!:	cmp VIC.RASTER	// this will effectly make our game logic run 50 times a second (PAL)
    bne !-			// this is the brute force method - normally one would set up a raster irq
    
    ldx cntdown
    beq action      // if cntdown is zero the gameplay is active

    dex
    stx cntdown     // if not we decrease countdown and store it
    beq ready       // when it reaches zero we jump to ready (enabling enemy sprites)
    txa             // transfer X to A as shift operations can only be done on A
    lsr
    lsr
    lsr              // divide cntdown value by 8
    and #1           // and that with 1 so that value toggles between 0 and 1 for blinking ship
    sta VIC.SPRITE_ENABLE
    jsr updateSfx
    jmp playGameLoop

ready:
    lda #255
    sta VIC.SPRITE_ENABLE  // turn on all sprites so that enemies will also be visible
    
action:
    jsr updateSfx
    jsr readInput
    jsr moveAndDrawBullets
    jsr moveAnimateEnemies
    jsr checkBulletCollision
    jsr checkPlayerCollision
    bcs exit          // check will return C = 1 when game over    
    jmp playGameLoop  // loop until game over
exit:
    
    rts
}

//===================================================================================
// ASSIGNMENT 2
// Read the joystick on CIA1's Port A and move ship right or left or fire a bullet.
// We also constrain movement of ship so it can only move between X values 26 and 240.
// For firing bullets we use a fire_timer that should be counted down until its zero.
// When this happens, call the function addBullet and reset the timer.
// Remember that the joystick ports have zero bit value for any switch that is active!
//===================================================================================
readInput: {
    ldy CIA1.PORTA        // read joystick port 2 (note that zero bits means they switches are connected)
    tya                   // transfer value to A for and operation
    and #JOY_LEFT         // check joystick left (if A is 0 after and)
    bne checkRight        // if not we check right
    ldx VIC.SPRITE0_XPOS  // get sprite 0 x position (ship)
    cpx #26		          // check if x is 26 (left edge of game area)
    bcc checkButton       // when carry is clear it means it is equal or lower than 26
    dex
    dex                   // we move ship two pixels left to make it a bit faster
    stx VIC.SPRITE0_XPOS  // set new sprite 0 x position
    jmp checkButton	      // then check button (no need to check right)
checkRight:
    tya                   // transfer Y to A as we kept joystick port reading there
    and #JOY_RIGHT        // check joystick right (if A is 0 after and)
    bne checkButton       // if not we check button
    ldx VIC.SPRITE0_XPOS  // get sprite 0 x position (ship)
    cpx #240		      // check if x is 240 (right edge of game area)
    bcs checkButton       // when carry is set it means its above 240
    inx
    inx                   // we move ship two pixels right to make it a bit faster
    stx VIC.SPRITE0_XPOS  // set new sprite 0 x position
checkButton:
    tya                   // transfer Y to A as we kept joystick port reading there
    and #JOY_BUTTON       // check if button bit is clear
    bne noButton          // if not we exit
    dec fire_timer        // if joystick button was down we count down the fire timer
    bne noButton          // if fire_timer is not zero yet we exit (need to count more)
    lda #FIRE_RATE        // otherwise we load the rate value 
    sta fire_timer        // and store in fire timer for another round
    jsr addBullet         // add bullet
noButton:
    rts
}

// Add a bullet to the bullet x,y tables
//-----------------------------------------------------------------------------------
addBullet: {
    ldx cur_bullet
    
    lda VIC.SPRITE0_XPOS // get player x position directly from sprite xpos
    sec
    sbc #24-10      // subtract left border area + approx half sprite
    lsr
    lsr
    lsr             // 3 x lsr => divide by 8 to find char column
    sta bullets_x,x // set x char column
    lda #21
    sta bullets_y,x // set y char row    
    inx
    cpx #MAX_BULLETS
    bne exit
    ldx #0
exit:
    stx cur_bullet
    ldx #0             
    jsr playSfx    // play shoot sfx
    rts
}

// A simple macro that assumes line we want to set dst to is in Y register
// This is just to demonstrate that a macro can be used to inline code wherever you want.
// This is often done to speed up as a jsr/rts costs a bit of CPU time so its common
// to optimize an expensive loop like our moveAndDrawBullets with inline code
//-----------------------------------------------------------------------------------
.macro SetScreenDst() {
    lda scrptr_lo,y
    sta dst
    lda scrptr_hi,y
    sta dst+1
}

// First clears out bullets last position, move it up one character, and then draws it again.
//-----------------------------------------------------------------------------------
moveAndDrawBullets: {
    //inc VIC.BORDER // uncomment this to measure time visually to see how much raster time a routine takes
    ldx #MAX_BULLETS-1
loop:
    ldy bullets_y,x
    bmi skip		 // if y position = 0 we just skip this bullet
    :SetScreenDst()
    lda #0
    ldy bullets_x,x	 // get the x position
    sta (dst),y	     // clear the bullet
    ldy bullets_y,x
    dey
    tya
    sta bullets_y,x  // move bullet one char up
    bmi skip
    :SetScreenDst()
    ldy bullets_x,x  // get the x position
    lda #CHAR_BULLET
    sta (dst),y	     // draw the bullet
skip:
    dex
    bpl loop
    //dec VIC.BORDER // uncomment this to measure time visually to see how much raster time a routine takes
    rts
}

//===================================================================================
// ASSIGNMENT 3
// Move all enemies down the screen and animate between their two frames.
// Each enemy Y position is stored in VIC.SPRITE0_YPOS, VIC.SPRITE1_YPOS, etc
// Note that these addresses in the IO are staggered as X is also stored before each
// As a bonus also check when enemy has reached bottom (or wraps around to Y position 0)
// and call the function "getRandomX" to get a new X position to adjust it.
// Finally to make it nicer, animate the sprites by alternating their sprite pointer
// between #SPRITE_ENEMY and #SPRITE_ENEMY+1. You might want to only change this every
// 8th frame to make the animation a bit slower. Every refresh in the game loop we
// count a variable called "tick" up by one, which is useful for this.
//===================================================================================
moveAnimateEnemies: {
    ldy #7                  // Y index used to iterate over 7 enemy sprites
    ldx #14                 // use X index as sprite number x 2 for easier access to sprite X and Y VIC-II registers
loop:
    inc VIC.SPRITE0_YPOS,x  // set Y position of the Y'th sprite using X index as that counted down 2 each loop
    bne nonew               // check if Y position wrapped to zero, if not skip repositioning of X
    jsr getRandomX          // if Y was zero we call a subroutine to get a new X position
    sta VIC.SPRITE0_XPOS,x  // set X position of the Y'th sprite using X index as that counted down 2 each loop
nonew:

    // animate enemy
    lda tick                // get tick value (counted up each frame)
    lsr                     
    lsr
    lsr                     // shift value left 3 times to effectively divide it by 8
    and #1                  // AND the value with 1 so that we end up with 0 or 1 in A
    clc                     // clear carry so we add zero as carry value in the adc below
    adc #SPRITE_ENEMY       // add sprite pointer of enemy, A will now be either #SPRITE_ENEMY or #SPRITE_ENEMY+1
    sta SPRITE0_POINTER,y   // set sprite pointer of the Y'th sprite (here we use Y as pointers are consecutive)

    dex
    dex                     // decrease X register by two so that we can use it for X and Y sprite adjustment
    dey                     // decrease Y register by one
    bne loop                // if Y is not zero we loop again for next sprite (sprite 0 is your ship and should not be moved!)
    rts
}

washit: .byte 0

// Check VIC-II sprite to char collision registers to check if any enemy has been hit.
// If we do we add 1 point to the score per enemy hit.
//-----------------------------------------------------------------------------------
checkBulletCollision: {
    lda VIC.SPRITE_BG_COLLISION
    and #$fe // we dont need to check player
    beq exit

    // go through each bit in the collision register to check which one was hit
    ldx #0
    stx washit
    ldy #14
loop:
    asl
    bcc next
    pha // stash A with the collision flags
    lda #250
    sta VIC.SPRITE0_YPOS,y // move to bottom of screen
    inc washit
    pla // bring them back into A
next:
    dey
    dey
    bne loop
nohit:

    lda washit
    beq exit
    jsr addScore
    ldx #1 // explosion sfx
    jsr playSfx
exit:
    rts
}

// Check if player sprite hit an enemy sprite.
// We also return C = 0 if not hit as a game over flag.
//-----------------------------------------------------------------------------------
// ASSIGNMENT?
checkPlayerCollision: {
    lda VIC.SPRITE_SPRITE_COLLISION
    and #1
    bne lostLife
exit:
    clc
    rts
}

// We lost a life, decrease number of lives and if game over we set C = 1
//-----------------------------------------------------------------------------------
lostLife: {
    //ldx #2  // ship explosion sfx
    //jsr playSfx    

    lda #0
    sta VIC.SPRITE_ENABLE // hide all sprites
    ldx lives
    dex
    txa
    asl // multiply by 2
    tay
    lda #0
    sta SCREEN_LIVES,y // remove ship on screen
    stx lives
    cpx #0	
    beq over
    jsr initGame
    clc
    rts
over:
    sec
    rts
}

//===================================================================================
// ASSIGNMENT 4
// Add the score in A (0-9) to the score chars on the screen. To simplify this we
// only allow the score added to be max 9. The position of the scores leftmost
// number is at the address SCREEN_SCORE and the score consist of 7 digits.
// Add the value to the rightmost number, if it overflows the character #'9'+1
// we can increase the next number to its left. Loop through all from right to left
// so that overflows spills over from right to left.
//===================================================================================
addScore: {
    ldx #6                  // set X to number of digits - 1 (we index 0 to 6)
loop:
    clc                     // clear carry for the adc below
    adc SCREEN_SCORE,x      // add the value of A to the digit char at the screen offset by X
    cmp #'9'+1              // compare the value by the char #'9'+1 (so char as if it was 10)
    bcc setexit             // if it is not equal or above we jump to storing on screen and exiting
    sec                     // if not we need to subtract the value by 10, first set carry for sbc
    sbc #10                 // then perform sbc to subtract 10
    sta SCREEN_SCORE,x      // store this value in the current screen position
    dex                     // decrease X by one (our screen digit index)
    beq exit                // if its zero we are finished
    lda #1                  // set A to 1 as that is what we add to the next digit when it overflowed
    jmp loop                // jump to loop for another digit
setexit:
    sta SCREEN_SCORE,x      // store digit in current screen position (used when there was no overflow)
exit:
    rts
}

// Turns off sprites and show a game over message on the screen.
//-----------------------------------------------------------------------------------
drawGameOver: {
    lda #0
    sta VIC.SPRITE_ENABLE

    jsr printGameOver
    rts
}

//===================================================================================
// ASSIGNMENT 1
// Prints GAME OVER in the middle of the screen (row 12, column 10)
//===================================================================================
printGameOver: {
    ldx #0
loop:
    lda gameOver,x
    beq end
    sta SCREEN+(12*40)+10,x
    inx
    jmp loop
end:
    rts
}

// Get a random X position for enemy entry at top
// Note that this is a very inefficient way to get this and can be improved
// by perhaps making a table of random values between the two boundaries and just
// return the next one from that table.
//-----------------------------------------------------------------------------------
getRandomX: {
again:
    jsr getrnd
    cmp #210	 
    bcs again  // if number is above right side of game area we try again
    clc
    adc #26   // add left border and some to get X position visible in game area
    rts
}

//-----------------------------------------------------------------------------------
// Simple RND function using ASL and EOR
// Will return all possible bytes (0-255)
//-----------------------------------------------------------------------------------
seed:	.byte 0
getrnd: {
    lda seed
    beq doEor
    clc
    asl
    beq noEor    // if the input was $80, skip the EOR
    bcc noEor
doEor:	eor #$1d
noEor:	sta seed
    rts
}


//-----------------------------------------------------------------------------------
// Some variables used by the sfx routine to set SID registers
//-----------------------------------------------------------------------------------

sidchannel: .byte 0,7,14      // IO offsets to each SID sound channel
freq:       .byte 0,0,0       // current frequency per channel (SID IO is write only, so we need to store these)


sfx_wave: .byte $20, $80, $80 // wave of sound ($10 = Triangle, $20 = Sawtooth, $40 = Pulse, $80 = Noise)
sfx_ad:   .byte $0f, $0f, $0f // attack decay
sfx_sr:   .byte $ff, $ff, $42 // sustain release
sfx_freq: .byte 40,  20,  10  // frequency hi byte (note these can be max 127 due to nature of code)
sfx_op:   .byte -4,  -2,  -1  // modify freqency per frame

//-----------------------------------------------------------------------------------
// Play a sound effect. Pass sfx to play in X register (also used as channel now)
//-----------------------------------------------------------------------------------
playSfx: {
    ldy sidchannel,x // get offset to which channel registers to set
    
    lda sfx_ad,x
    sta SID.ATTACK_DELAY,y
    lda sfx_sr,x
    sta SID.SUSTAIN_RELEASE,y
    lda sfx_freq,x
    sta freq,x
    sta SID.FREQUENCY_HI,y
    
    lda sfx_wave,x
    ora #1
    sta SID.CONTROL,y // turn on gate bit (trigger attack/decay/sustain)
        
    rts
}

//-----------------------------------------------------------------------------------
// Every screen frame we update the each channel to control frequency of notes
//-----------------------------------------------------------------------------------
updateSfx: {
    ldx #2    
loop:
    ldy sidchannel,x
    lda freq,x
    beq next  // when zero there is no sound
    clc
    adc sfx_op,x
    bpl notminus  // we terminate sound when frequency wraps around (very simple logic)
    lda #0
notminus:
    sta freq,x
    sta SID.FREQUENCY_HI,y
    lda sfx_wave,x
    sta SID.CONTROL,y // turn off gate bit (trigger release)
next:
    dex
    bpl loop
    rts
}
