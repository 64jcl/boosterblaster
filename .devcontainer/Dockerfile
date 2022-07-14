# https://gist.github.com/teekaay/39bff8c66cd8e43c2ba57a6b2eef4fa8
FROM ubuntu:latest

RUN apt-get update && \
    apt-get --yes --no-install-recommends install openjdk-8-jre unzip wget git 
RUN wget https://www.badgerpunch.com/booster/kickass.zip
RUN unzip /kickass.zip -d tools