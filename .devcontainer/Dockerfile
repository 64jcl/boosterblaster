FROM ubuntu:latest

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN apt-get update \
    && groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME\
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && apt-get --yes --no-install-recommends install openjdk-8-jre unzip wget git 
RUN wget https://www.badgerpunch.com/booster/kickass.zip
RUN wget https://www.badgerpunch.com/booster/vice.zip
RUN unzip /kickass.zip -d tools
RUN unzip /vice.zip -d tools
USER $USERNAME