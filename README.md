# boosterblaster
A simple game developed in 6502 assembly for the Commodore 64 for the Booster 2020 Conference
by John Christian Lønningdal and Ricki Sickenger

# Installation instructions

1. Install Visual Studio Code

2. Add the Kick Assembler extension by Paul Hocker:
https://marketplace.visualstudio.com/items?itemName=paulhocker.kick-assembler-vscode-ext

3. Create a folder C:/Applications/

4. Download KickAssembler from: http://theweb.dk/KickAssembler
   And unpack it in C:/Applications/KickAssembler

5. Download Vice emulator from: http://vice-emu.sourceforge.net/
   Unpack it in the folder C:/Applications/Vice

6. Download Java JRE/JDK or just adjust settings.json to point to your Java JRE bin folder

Alternatively create another location for your tools and modify settings.json to reflect where they are.

Press F5 to compile and run!

# Folder structure:
```
bin/       Binary output folder
lib/       Library asm files
res/       Resources like charsets and sprites
design/    Design of charsets and sprites
docs/      Some helping documents for coding
examples/  A couple of 6502 code examples
```

# Some tools we recommend

Charpad to edit character/tile sets: http://www.subchristsoftware.com/charpadfree/index.htm

Spritepad to edit sprites: http://www.subchristsoftware.com/spritepad/index.htm

Pixcen to edit bitmaps: http://hammarberg.github.io/pixcen/

Paint.net to edit pixel images using layers (all tools above can import from these if needed): https://www.getpaint.net/

Goattracker for SID Music creation: https://csdb.dk/release/?id=152420

Exomizer for compressing program/data for unpacking on C64: https://csdb.dk/release/?id=173655

