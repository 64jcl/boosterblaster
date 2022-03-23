#!/bin/sh

# Kick assembling
java -cp ./tools/kickass/KickAss.jar cml.kickass.KickAssembler main.asm -vicesymbols -showmem -odir ./bin

# Launch vice
/usr/local/bin/x64sc -logfile ./bin/vicelog.txt ./bin/main.prg

