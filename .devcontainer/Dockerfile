FROM ubuntu:latest

RUN apt-get update && \
    apt-get --yes --no-install-recommends install openjdk-8-jre unzip wget git 
RUN wget https://www.badgerpunch.com/booster/kickass.zip
RUN unzip /kickass.zip -d tools