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
