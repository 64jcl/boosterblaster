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
