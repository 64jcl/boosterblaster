
// Written for the BOOSTER Conference Bergen 2020 
// by John Christian Lønningdal and Ricky Sickenger

// Adds a short basic program that does as SYS basic command to the start
//-----------------------------------------------------------------------------------
:BasicUpstart2(main)


// We can split up code in several files and import them as needed.
// Remember these can contain code so you need to import them where you
// want to place them unless they also set the .pc directive themselves.
// Import some to simplify coding the C64 zp/io/kernal
//-----------------------------------------------------------------------------------
.import source "lib/zp.asm"
.import source "lib/io.asm"
.import source "lib/kernal.asm"


// Zero page is used frequently for faster code and indirect adressing ( e.g. lda ($fb),y )
//-----------------------------------------------------------------------------------
.pc = $fc "Zeropage" virtual

src: .word 0 // a source word pointer so we can use indirect adressing
dst: .word 0 // a destination word pointer so we can use indirect adressing

// We load a screen into address 2000
//-----------------------------------------------------------------------------------
.const SCREEN = $2800 // define a constant we can use later
.pc = SCREEN "Screen"
.import binary "res/screen.bin"

// We load a custom charset into address 3000
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

.const COUNTDOWN_TIME = 100

// Data can reside anywhere, even between the code, but its often wise to put them
// somewhere you can easily refer to all variables used in the program
//-----------------------------------------------------------------------------------
.pc = $0820 "Data"

// colour information per character position
attribs:		.import binary "res/attribs.bin"

// some texts we want to show
pressButton:	.byte 12,5 // y and x position of text
		.text "press button to play"
		.byte 0 // we null terminate these
gameOver:	.byte 12,10
		.text "game over"
		.byte 0

// two lookup tables so that we can quickly get the pointer to each line on the screen!
scrptr_lo:	.fill 25,<[SCREEN+[i*40]] // lo pointer (<)
scrptr_hi:	.fill 25,>[SCREEN+[i*40]] // hi pointer (>)

// some joystick bit positions we can use the bit opcode to check directions and button
JOY_BUTTON: .byte %00010000
JOY_UP: 	   .byte %00000001
JOY_DOWN:   .byte %00000010
JOY_LEFT:   .byte %00000100
JOY_RIGHT:  .byte %00001000

fire_timer: .byte 0              // a timer that we count down to zero for each fire
cur_bullet: .byte 0              // position of the bullet to add to table
bullets_x:  .fill MAX_BULLETS,0  // x position of bullet
bullets_y:  .fill MAX_BULLETS,-1 // y position of bullet (-1 means not active)

// colours of the enemies
mobcols: .byte GREEN,LIGHT_GREEN,RED,LIGHT_RED,BLUE,LIGHT_BLUE,ORANGE

tick:	.byte 0 // a frame counter
cntdown: .byte 0 // a countdown on game start or life lost
lives:	.byte 0 // number of lives

.pc = $1000 "Main"
// The code can also reside anywhere in memory. This is the main entry part which
// our generated basic program with a SYS command will call.
//-----------------------------------------------------------------------------------
main: {
	//sei
	jsr initGraphics
loop:
	jsr drawIntroScreen
!:	jsr readJoystickButton
	bcc !-
	jsr drawGameScreen
	jsr playGame
	jsr drawGameOver
!:	jsr readJoystickButton
	bcc !-
	jmp loop	
}

// Set border and background colour and switch VIC-II to a custom character set and screen
//-----------------------------------------------------------------------------------
initGraphics: {
	lda #DARK_GREY
	sta VIC.BORDER
	lda #BLACK
	sta VIC.BACKGROUND

	// set up the VIC-II so it points to our custom charset + screen
	lda #SCR_2800+CHAR_3000
	sta VIC.SCREEN_CHARSET_PTR
	
	jsr drawScreenColours
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

// Atm we just we just show some text on the intro screen
//-----------------------------------------------------------------------------------
drawIntroScreen: {
	ldx #<pressButton
	lda #>pressButton
	jsr printText
	rts
}

//-----------------------------------------------------------------------------------
// Prints on the screen directly
//-----------------------------------------------------------------------------------
printText: {
	stx src
	sta src+1
	ldy #0
	lda (src),y // read y position
	tax
	lda scrptr_lo,x
	sta mod+1 // self modifying code - lo pointer
	lda scrptr_hi,x
	sta mod+2 // self modifying code - hi pointer
	iny
	lda (src),y // read x position
	tax
loop:
	iny
	lda (src),y
	beq end
mod:	sta SCREEN,x // this address is modified to point to the line on the screen
	inx
	jmp loop
end:
	rts
}

// Read the joystick button.
// Return: Carry = 0 if no button or just pressed, Carry = 1 when button is released.
//-----------------------------------------------------------------------------------
arm: .byte 0
readJoystickButton: {
	lda CIA1.PORTA
	ldx arm
	bne release	
	bit JOY_BUTTON
	bne exit	
	inc arm
exit:
	clc
	rts
release:	
	bit JOY_BUTTON
	beq exit
	lda #0
	sta arm
	sec
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
	
	lda #1 // only player is multicolour
	sta VIC.SPRITE_MULTICOLOUR
	lda #GREY
	sta VIC.SPRITE0_COLOUR
	lda #DARK_GREY
	sta VIC.SPRITE_COLOUR1
	lda #LIGHT_GREY
	sta VIC.SPRITE_COLOUR2
	lda #SPRITE_PLAYER
	sta SPRITE0_POINTER
	
	jmp initGame
}
	
// Initialize a new game. Also called every time you loose a life to restart.
//-----------------------------------------------------------------------------------
initGame: {
	lda #0
	sta SID.VOLUME_MODE

	lda #COUNTDOWN_TIME
	sta cntdown

	lda #1 // enable only player sprite first
	sta VIC.SPRITE_ENABLE
	lda #130
	sta VIC.SPRITE0_XPOS
	lda #217
	sta VIC.SPRITE0_YPOS
	
	ldx #7
	ldy #14
more:
	lda #SPRITE_ENEMY
	sta SPRITE0_POINTER,x
	jsr getNewEnemyX
	sta VIC.SPRITE0_XPOS,y
	lda starty-1,x
	sta VIC.SPRITE0_YPOS,y // x/y are staggered so need its own index!
	lda mobcols-1,x
	sta VIC.SPRITE0_COLOUR,x
	dey
	dey
	dex
	bne more
	
	rts
}

starty: .byte 251,0,5,10,15,20,25,30

// The main loop where the game playing code is run.
//-----------------------------------------------------------------------------------
playGame: {
	inc tick	// a frame counter used for e.g. animation

	lda #250		// wait for screen raster to reach line 250 (at the bottom border)
!:	cmp VIC.RASTER	// this will effectly make our game logic run 50 times a second (PAL)
	bne !-			// this is the brute force method - normally one would set up a raster irq
	
	ldx cntdown
	beq action
	dex
	stx cntdown
	beq ready
	txa
	lsr
	lsr
	lsr
	lsr
	and #1
	sta VIC.SPRITE_ENABLE
	jmp playGame
ready:
	lda #255
	sta VIC.SPRITE_ENABLE
	
action:
	jsr updateSfx

	lda CIA1.PORTA
	bit JOY_LEFT
	bne checkRight
	ldx VIC.SPRITE0_XPOS
	cpx #26		// check if we can move further to the left
	bcc checkButton
	dex
	dex
	stx VIC.SPRITE0_XPOS
	jmp checkButton
	
checkRight:
	bit JOY_RIGHT
	bne checkButton
	ldx VIC.SPRITE0_XPOS
	cpx #240		// check if we can move further to the right
	bcs checkButton
	inx
	inx
	stx VIC.SPRITE0_XPOS
checkButton:
	//lda CIA1.PORTA // we read value again as we have likely clobbered A register
	bit JOY_BUTTON
	bne noButton
	dec fire_timer  // count down fire timer
	bpl noButton
	lda #FIRE_RATE
	sta fire_timer  // restore fire timer
	jsr addBullet

noButton:
	//inc VIC.BORDER
	jsr moveAndDrawBullets
	jsr moveEnemies
	jsr checkBulletCollision
	jsr checkPlayerCollision
	bcs exit // check will return C = 1 when game over
	//dec VIC.BORDER	
	
	jmp playGame // loop until game over
exit:
	
	rts
}

// Add a bullet to the bullets tables
//-----------------------------------------------------------------------------------
addBullet: {
	ldx cur_bullet
	
	lda VIC.SPRITE0_XPOS // get player x position directly from sprite xpos
	sec
	sbc #24-10 // subtract left border area + approx half sprite
	lsr
	lsr
	lsr // divide by 8
	sta bullets_x,x // set x char position
	
	lda #21
	sta bullets_y,x // set y char position
	
	inx
	cpx #MAX_BULLETS
	bne exit
	ldx #0
exit:
	stx cur_bullet
	ldx #0 // shoot sfx
	jsr playSfx
	rts
}

// A simple macro that assumes line we want to set dst to is in Y register
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
	ldx #MAX_BULLETS-1
loop:
	ldy bullets_y,x
	bmi skip		// if y position = 0 we just skip this bullet
here:
	:SetScreenDst()	
	lda #0
	ldy bullets_x,x	// get the x position
	sta (dst),y	// clear the bullet
	ldy bullets_y,x
	dey
	tya
	sta bullets_y,x // move bullet one char up
	bmi skip
	:SetScreenDst()
	ldy bullets_x,x	// get the x position
	lda #CHAR_BULLET
	sta (dst),y	// draw the bullet
skip:
	dex
	bpl loop
	rts
}

// Move all enemies down the screen and animate between their two frames.
//-----------------------------------------------------------------------------------
moveEnemies: {
	ldy #7
	ldx #14
loop:
	inc VIC.SPRITE0_YPOS,x
	bne nonew
	jsr getNewEnemyX
	sta VIC.SPRITE0_XPOS,x
nonew:
	// animate enemy
	lda tick
	lsr
	lsr
	lsr
	and #1
	clc
	adc #SPRITE_ENEMY
	sta SPRITE0_POINTER,y

	dex
	dex
	dey
	bne loop
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

// Will add the score in A (0-9) to the score chars on the screen
//-----------------------------------------------------------------------------------
addScore: {
	ldx #6
loop:
	clc
	adc SCREEN_SCORE,x
	cmp #'9'+1
	bcc setexit
	sec
	sbc #10
	sta SCREEN_SCORE,x
	dex
	beq exit
	lda #1 // add 1 to next position
	jmp loop
setexit:
	sta SCREEN_SCORE,x
exit:
	rts
}

// Show a game over message on the screen.
//-----------------------------------------------------------------------------------
drawGameOver: {
	lda #0
	sta VIC.SPRITE_ENABLE
	ldx #<gameOver
	lda #>gameOver
	jsr printText
	rts
}

// Get a random X position for enemy entry at top
//-----------------------------------------------------------------------------------
getNewEnemyX: {
again:
	jsr getrnd
	cmp #210	 
	bcs again // if number is above right side we try again
	clc
	adc #26 // add left border and some
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

sidchannel: .byte 0,7,14

sfx_wave:.byte $20,$80
sfx_ad:  .byte $0f,$0f
sfx_sr:  .byte $ff,$ff
sfx_freq:.byte 40 ,10
sfx_dec: .byte  4 ,1

freq:.byte 0,0

//-----------------------------------------------------------------------------------
updateSfx: {
	ldx #1
loop:
	ldy sidchannel,x
	lda freq,x
	beq next
	sec
	sbc sfx_dec,x
	bpl notminus
	lda #0
notminus:
	sta freq,x
	sta SID.FREQUENCY_HI,y
	lda sfx_wave,x
	sta SID.CONTROL,y // turn off gate bit (trigger decay)
next:
	dex
	bpl loop
	rts
}

// Play a sound effect. Pass sfx to play in X register (also used as channel)
//-----------------------------------------------------------------------------------
playSfx: {
	lda #15
	sta SID.VOLUME_MODE

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
