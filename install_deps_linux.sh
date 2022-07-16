#!/bin/sh

# Java 8 is enough for kickassembler, but retro studio complained and wanted 11 
sudo apt-get -y install openjdk-11-jre-headless unzip

cd tools
wget https://www.badgerpunch.com/booster/kickass.zip
wget https://www.badgerpunch.com/booster/vice.zip
unzip kickass.zip
unzip vice.zip
rm kickass.zip
rm vice.zip
cd ..
chmod +x tools/vice/bin/x64sc.exe
chmod +x tools/kickass/kickassembler-5.19.jar