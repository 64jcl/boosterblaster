#import "lib/zp.asm"
#import "lib/io.asm"
#import "lib/kernal.asm"

//-----------------------------------------------------------------------------------
:BasicUpstart2(main)

.pc = $fe "Zeropage" virtual
//-----------------------------------------------------------------------------------
src: .word 0

.pc = $0900 "Data"
//-----------------------------------------------------------------------------------
hellotxt:
    .text "HELLO WORLD"
    .byte 0


.pc = $0a00 "Main"
//-----------------------------------------------------------------------------------
main: {    
    lda #BLACK
    sta IO.BORDER
    sta IO.BACKGROUND
    jsr KERNAL.CLEARSCREEN
    ldx #<hellotxt
    lda #>hellotxt
    jsr print
    rts
}

//-----------------------------------------------------------------------------------
// Prints on the screen using the Kernal screen function
//-----------------------------------------------------------------------------------
print: {
    stx src
    sta src+1
    ldy #0
loop:
    lda (src),y
    beq end
    jsr KERNAL.CHROUT
    iny
    jmp loop
end:
    rts
}
