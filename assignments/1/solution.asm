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
