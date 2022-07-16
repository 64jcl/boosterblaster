cd tools
wget https://www.badgerpunch.com/booster/kickass.zip -OutFile kickass.zip
wget https://www.badgerpunch.com/booster/vice.zip -OutFile vice.zip
Expand-Archive kickass.zip
Expand-Archive vice.zip
del kickass.zip
del vice.zip
cd ..