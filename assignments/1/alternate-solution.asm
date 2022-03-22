// This solution is a more generic one that simplifies printing so that it can be reused

// some texts we want to show - but also with X and Y position as first two bytes!
pressButton:	
	.byte 12,5 // y and x position of text
	.text "press button to play"
	.byte 0 // zero terminating string
gameOver:	
	.byte 12,10
	.text "game over"
	.byte 0 // zero terminating string


//-----------------------------------------------------------------------------------
// ASSIGNMENT 1
// We just load a pointer to the address of the text and call the reusable print function
//-----------------------------------------------------------------------------------
printPressButton: {
	ldx #<pressButton // load lo pointer into X
	lda #>pressButton // load hi pointer into Y
	jsr printText
  rts
}

//-----------------------------------------------------------------------------------
// ASSIGNMENT 1
// You can also replace this method then with the call to the reusable code
// Or better just replace the jsr printGameOver with the code in the function
//-----------------------------------------------------------------------------------
printGameOver: {
	ldx #<gameOver
	lda #>gameOver
	jsr printText
  rts
}

//-----------------------------------------------------------------------------------
// Prints on the screen directly
//-----------------------------------------------------------------------------------
printText: {
	stx src         // store lo pointer into zero page for indirect adressing
	sta src+1       // and hi pointer (note that the C64 is low endian so lo byte comes before hi byte in a 16bit address)
	ldy #0
	lda (src),y     // read y position using indirect addressing of the current string to print
	tax             // move to X register
	lda scrptr_lo,x // look up lo pointer of screen row
	sta mod+1       // and store that into the code by self modifying the code below!
	lda scrptr_hi,x // look up hi pointer of screen row
	sta mod+2       // and also store that as new pointer in code
	iny             // advance Y index
	lda (src),y     // read x position from string
	tax             // move to X register (offset into the current line to print on)
loop:
	iny             // advance Y index of string (first call here and it points to first char of string)
	lda (src),y     // load character from string
	beq end         // if its zero we are finished (zero terminated string)
mod:	
	sta SCREEN,x // this address is modified to point to the line on the screen
	inx
	jmp loop
end:
	rts
}
