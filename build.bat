echo off
rem #######################################################
rem ###                  Build file for Windows         ###
rem ### You need the following:                         ###
rem ### - Java                                          ###
rem ### - KickAssembler                                 ###
rem ### - Vice c64 emulator                             ###
rem ###                                                 ###
rem ### Put KickAssembler and Vice in the tools folder, ###
rem ### or update  paths in this file.                  ###
rem #######################################################


rem Kick assembling.
java -cp ./Tools/kickass/KickAss.jar cml.kickass.KickAssembler main.asm -vicesymbols -showmem -odir ./bin

rem Launch vice
rem d:\Tools\GTK3VICE-3.5-win64\bin\x64sc.exe -logfile ./bin/vicelog.txt -initbreak ready -moncommands ./bin/cart.vs ./bin/cart.crt
.\Tools\vice\bin\x64sc.exe -logfile ./bin/vicelog.txt ./bin/main.prg
