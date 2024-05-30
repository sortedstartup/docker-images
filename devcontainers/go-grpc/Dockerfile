# This docker image can be used to produce 3 docker images
# 
# - base            : only has ubuntu and utilities like zip, sql clients etc.
# - dev-go-npm-grpc : has go lang, npm, grpc tools for both languages
# - dev-go-npm-grpc : java-android -> has go lang, npm, grpc tools for both languages, java and android sdk

# Build commands
# docker build . --target base -t sortedstartup/dev/base:0.1
# docker build . --target dev-go-npm-grpc -t sortedstartup/dev/dev-go-npm-grpc:0.1
# docker build . --target dev-go-npm-grpc-java-android -t sortedstartup/dev/dev-go-npm-grpc-java-android:0.1

# Use Ubuntu as the base image
FROM ubuntu:jammy as base

# uid=1000 and gid=1000, because github codespaces rely on this
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# All softwares are to be installed in sw
ENV USER_HOME=/home/${USERNAME}
ENV USER_SW_HOME=${USER_HOME}/sw
ENV SHELL=/bin/bash 

# Mount for docker-in-docker
VOLUME [ "/var/lib/docker" ]

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME


RUN apt-get update && apt-get install -y \
    apt-utils \
    sudo \
    curl \
    lsb-release \
    && apt-get clean


