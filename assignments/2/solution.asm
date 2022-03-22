//===================================================================================
// ASSIGNMENT 2
// Read the joystick on CIA1's Port A and move ship right or left or fire a bullet.
// We also constrain movement of ship so it can only move between X values 26 and 240.
// For firing bullets we use a fire_timer that should be counted down until its zero.
// When this happens, call the function addBullet and reset timer.
//===================================================================================
readInput: {
    ldy CIA1.PORTA        // read joystick port 2 (note that zero bits means they switches are connected)
    tya                   // transfer value to A for and operation
    and JOY_LEFT          // check joystick left (if A is 0 after and)
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
    and JOY_RIGHT         // check joystick right (if A is 0 after and)
    bne checkButton       // if not we check button
    ldx VIC.SPRITE0_XPOS  // get sprite 0 x position (ship)
    cpx #240		      // check if x is 240 (right edge of game area)
    bcs checkButton       // when carry is set it means its above 240
    inx
    inx                   // we move ship two pixels right to make it a bit faster
    stx VIC.SPRITE0_XPOS  // set new sprite 0 x position
checkButton:
    tya                   // transfer Y to A as we kept joystick port reading there
    and JOY_BUTTON        // check if button bit is clear
    bne noButton          // if not we exit
    dec fire_timer        // if joystick button was down we count down the fire timer
    bne noButton          // if fire_timer is not zero yet we exit (need to count more)
    lda #FIRE_RATE        // otherwise we load the rate value 
    sta fire_timer        // and store in fire timer for another round
    jsr addBullet         // add bullet
noButton:
    rts
}