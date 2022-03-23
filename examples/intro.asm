

//-------------------------------------------------------------------------------
// A 6502 instruction consist of the OPCODE and an optional VALUE that is either
// 8 bit or 16 bit. Some examples of each length below:

  txa         // 1 byte
  lda #1      // 2 bytes
  sta $1000   // 3 bytes


//-------------------------------------------------------------------------------
// Load immediate value 5 and store it at address $1000
// Note that the # on the value is in fact a symbol that indicates the adressing
// mode of the instruction LDA. 

  lda #5      // Opcode: LDA immediate , Value: 5 (the actual value to load A with)
  sta $1000   // Opcode: STA absolute, Value: $1000 (an address to store A to)


//-------------------------------------------------------------------------------
// Load a value from memory address 5 and store at $1001
// The size of the value decides if the opcode is of type absolute zero page (8 bit)
// or normal absolute (16 bit). The size of an instruction is often an indicator
// of how fast it is (how many CPU clock cycles it takes). For more details about
// this look at web sites showing the full instruction set including cycle count.

  lda $5      // Opcode: LDA absolute zero page, Value: $5
  sta $1001   // Opcode: STA absolute, Value: $1001


//-------------------------------------------------------------------------------
// Load a value using index X to offset absolute address and same for storing value
// in this example it will load a value from $1010 and store at $2010
// You can use both X and Y for this kind of indexing as well as zero page.

  ldx #$10      // note the $ meaning this is hex value $10 which is 16 decimal
  lda $1000,x   // address we load from is at $1000 + $10 = $1010
  sta $2000,x   // address we load from is at $2000 + $10 = $2010


//-------------------------------------------------------------------------------
// Normally one would store variables defining them a place in the source and
// refer them through the label so the code below is the same as this code in most
// languages: data[3] = 100;

data: .byte 0,0,0,0,0 // an array of 5 values

{
  ldx #3
  lda #100
  sta data,x
  rts
}


//-------------------------------------------------------------------------------
// The most complex adressing mode on the 6502 is the indirect Y indexed adressing.
// Look at it as if working with pointers to an array in C or C++.
// The code below will load the value in memory address $1006 into A
// Note that the 6502 is low-endian so the low byte of an 16 bit address is
// stored before the high byte! Also note that all indirect adressing modes
// only work on zero page addresses. Finally only index register Y can be
// used for this type of adressing.

  lda #$01      // load low byte of pointer address $01 into A
  sta $fe       // store A in zero page address $fe
  lda #$10      // load high byte of pointer address $10 into A
  sta $ff       // store A in zero page address $ff
  ldy #5        // load the index register Y with 5
                // this will load the value from $fe and $ff to make it into a
  lda ($fe),y   // 16 bit pointer, then add Y to this to for actual address $1006

                
//-------------------------------------------------------------------------------
// The second type of indirect adressing is the X indexed indirect one which
// adds the index X to the zero page address used before resolving it into
// a pointer. This adressing mode is rarely used and only X register can be used.
// The example below will load the value of that the address in zero page 
// $84 and $85 points to into A.

  ldx #4        // load the index register Y with 4
                // this will add the value in Y to the zero page address of the
  lda ($80,x)   // instruction and use that as pointer, in this case $80+4 = $84,
                // and then load the value that this points to


//-------------------------------------------------------------------------------
// Note that there is no difference in writing to an IO address
// the code below will load the value #1 and store that at the IO address that
// control the border colour, in this case #1 is the white colour

  lda #1
  sta $d020


//-------------------------------------------------------------------------------
// Jumping to code is easy, just jmp and the label
  jmp code

code: {
  // more code
}


//-------------------------------------------------------------------------------
// A subroutine is similar but the address you called from is stored on the stack
// so that whenever it reaches an rts it will return
  jsr func
// code flow will be here when returned

func: {
  // do something here
  rts
}


//-------------------------------------------------------------------------------
// A loop that iterates from 0 to 9 (exits at 10) loading values at $1000-$1009
// and storing them at $2000-$2009

  ldx #0
loop:
  lda $1000,x
  sta $2000,x
  inx
  cpx #10  // this actually subtracts 10 from X and updates flags Z and N
  bne loop // this actually checks if Z flag is 0 and jumps if so


//-------------------------------------------------------------------------------
// Loading A with value 5 and adding value 5 to it storing the result at address $1000
// note that adc always also adds the carry flag so its important to clear this unless
// you actually want to carry over from one byte to another (see next example)

  lda #5
  clc
  adc #5
  sta $1000


//-------------------------------------------------------------------------------
// Subtracting is the same but where you need to set the carry before as that is
// used as borrow and its value will be inverted. A - M - !C -> A
// The value 5 is loaded into A, carry set and we then subtract 5 which means A
// will have the value 0 that ist stored at address $1000.

  lda #5
  sec
  sbc #5
  sta $1000


//-------------------------------------------------------------------------------
// Adding two 16 bit numbers in memory at $2000 and $3000 and store result in $3000
// note that clc is only done on the first add as we want the carry if the sum
// was over 255 to be added into the next byte (carry will then be set)
// also note that on the C64 values are often stored little-endian so the low
// byte of a 16 bit value is stored before the high byte

  lda $1000
  clc
  adc $2000
  sta $3000
  lda $1001
  adc $2001
  sta $3001


//-------------------------------------------------------------------------------
// The 6502 has 4 bit rotation operations, their difference lie in whether they
// are circular or will feed the other size with 0's.

  sec             // set carry for this example (C = 1)
  lda #%00001000  // load A with value 8
  rol             // rotate A left,  bit0 = C (1) and C = bit7 (0). A = %00010001
  ror             // rotate A right, bit7 = C (0) and C = bit0 (1), A = %00001000
  asl             // shift A left,   bit0 = 0     and C = bit7 (0), A = %00010000
  lsr             // shift A right,  bit7 = 0     and C = bit0 (0), A = %00001000


//-------------------------------------------------------------------------------
// The two shift operations ASL and LSR are often called arithmetic shifting and
// is often used as a way to multiply or divide a value by 2. Note that the 6502
// does not have any multiply or divide instruction!

  lda #64   // load value 64 in A
  asl       // shift bits 1 up   => A = 64*2 = 128
  lsr       // shift bits 1 down => A = 128/2 = 64


//-------------------------------------------------------------------------------
// Logical operations are important and the processor supports AND, OR, XOR
// These are respectively named: and, ora, eor

  lda #%00001111    // load A with value 15 (here specified as binary)
  and #%00011000    // AND the value 24 with A and store result in A (which will now be 8)
//     %00001000    // result of the AND operation

  lda #%01010101    // load A with value 15 (here specified as binary)
  ora #%10101010    // OR the value 24 with A and store result in A (which will now be 255)
//     %11111111    // result of the AND operation


//-------------------------------------------------------------------------------
// AND is often used to test and branch based on bit values of a byte as any
// operation that modifies the a register will always update the Z and N CPU flags
// which we can then branch upon. (Some modify C and V flags too like the arithmetic ones)

.const MONSTER = %00001000;  // value 8 in binary

mobType: .byte MONSTER

{
  //...
  lda mobType     // load the value in address mobType
  and #MONSTER    // AND value with bit mask in constant MONSTER (note the # for immediate!)
                  // The AND operation will also adjust Z flag. Z = 0 if A != 0, Z = 1 if A == 0
  bne killMonster // Since mobType in this example is set to same value as we test this 
                  // means Z = 1 and the branch is executed
  //...
}

killMonster: {  }


//-------------------------------------------------------------------------------
// Conditional branches can be difficult to understand at first but they are basically
// just testing the value of a CPU flag and jumps depending if its testing for 0 or 1.
// The names of the instructions are not always intuitive unfortunately as they tried
// to make them easier whenever there was a compare instruction (cmp, cpx, cpy)

  lda mobType       // load value at address of mobType
  cmp #MONSTER      // compare with value of constant MONSTER (8)
  beq killMonster   // branch if these are equal - actually the branch is because Z = 1

// Whats actually happening in the code above is that the CMP instruction take the value
// 8 and subtracts that from the value in A (which is also 8). This results in the value 0
// which will then set the Z flag to 1. So BEQ actually means jump of Z = 1.
// Note that the compare instructions never actually modifies the register they test ofc.
// That means that the code below will also jump.

  ldx #1            // load X register with 1
  dex               // decrease X register with 1 - X now has value 0 and Z flag is set to 1
  beq killMonster   // the branch happens because Z = 1


//-------------------------------------------------------------------------------
// Some branches are more intuitive because they actually specifiy the flag they
// test for whether its true or false. These are:

  bcc   // branch if carry flag 0
  bcs   // branch if carry flag 1
  bvc   // branch if overflow flag 0
  bvs   // branch if overflow flag 1
        // the two below a bit less inutitive but still close
  bpl   // branch if positive / negative flag 0
  bmi   // branch if negative / negative flag 1


//-------------------------------------------------------------------------------
// The negative flag is set whenever the result of an instruction resulted in
// bit7 being set as that is regarded as a sign bit.

  ldy #%01111111    // load value 127 in register Y
  iny               // increase Y by 1 (it now has value 128 or %10000000 binary) - N flag is set to 1
  bmi killMonster   // branch since N flag is 1


