wget https://www.badgerpunch.com/booster/kickass.zip -OutFile kickass.zip
wget https://www.badgerpunch.com/booster/vice.zip -OutFile vice.zip
Expand-Archive -DestinationPath tools kickass.zip
Expand-Archive -DestinationPath tools vice.zip
del kickass.zip
del vice.zip