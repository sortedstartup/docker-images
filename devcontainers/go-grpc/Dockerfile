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

RUN apt-get update \
    # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME  \
    && apt-get install -y wget curl git jq python3 python3-pip unzip zip inetutils-ping sqlite3 libsqlite3-dev make postgresql-client \
    && apt clean

USER ${USERNAME}

RUN mkdir ${USER_SW_HOME}

FROM base as dev-go-npm-grpc
# Install Go 1.22.3

RUN wget https://go.dev/dl/go1.22.3.linux-amd64.tar.gz -O - | tar -xz -C ${USER_SW_HOME} && \
echo "export PATH=\$PATH:${USER_SW_HOME}/go/bin">> ${USER_HOME}/profile

# Set environment variable for Go
ENV PATH="${PATH}:${USER_SW_HOME}/bin:${USER_SW_HOME}/go/bin:${USER_HOME}/go/bin"

# Install Node.js using NVM
ENV NVM_DIR=${USER_SW_HOME}/nvm
RUN mkdir $NVM_DIR
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash && \
    . "$NVM_DIR/nvm.sh" && \
    #TODO: install specific version
    nvm install --lts && \
    nvm use --lts && \
    echo "export PATH=\$PATH:/usr/local/nvm/versions/node/$(nvm version --lts)/bin">> ${USER_HOME}/profile

# Install SDKMAN
RUN curl -s "https://get.sdkman.io" | bash
RUN bash -c "source ${HOME}/.sdkman/bin/sdkman-init.sh && sdk version"


# ------- GRPC Tools --------
# Install protoc
RUN wget https://github.com/protocolbuffers/protobuf/releases/download/v26.1/protoc-26.1-linux-x86_64.zip -O ${USER_SW_HOME}/protoc.zip && \
    unzip ${USER_SW_HOME}/protoc.zip -d ${USER_SW_HOME} && \
    rm ${USER_SW_HOME}/protoc.zip

# Install grpc tools , this can be moved to dev container startup steps also as we dont knw what is the GOPATH before hand, we kind of know
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.33.0 && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.3.0 && \
    go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest && \
    # Without this there is ~400 MB in ~/.cache/go-build
    go clean -cache && \
    go clean -modcache

RUN . "$NVM_DIR/nvm.sh" && npm install -g protoc-gen-ts


# ----- add git mod cache, this speeds up the first go run and build ----- 
# but it depennds on the project because every project has different dependencies and versions

# -----

FROM dev-go-npm-grpc as dev-go-npm-grpc-java-android
# ------- Android SDK --------
# TODO: see if we can use latest java 
RUN bash -c "source ${HOME}/.sdkman/bin/sdkman-init.sh  && sdk install java 17.0.11-oracle"

RUN mkdir /home/dev/sw/android_cmdtools && \
    cd /home/dev/sw/android_cmdtools && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip && \
    unzip commandlinetools-linux-11076708_latest.zip && \
    rm commandlinetools-linux-11076708_latest.zip

ENV ANDROID_HOME=/home/dev/sw/androidsdk

# TODO: init sdk man and remove java from path and JAVA_HOME
RUN PATH=$PATH:${USER_SW_HOME}/android_cmdtools/cmdline-tools/bin:/home/dev/.sdkman/candidates/java/current/bin && \
    JAVA_HOME=/home/dev/.sdkman/candidates/java/current && \
    yes|sdkmanager --sdk_root=/home/dev/sw/androidsdk/ --install "platform-tools" "platforms;android-34" "build-tools;34.0.0" && \
    yes|sdkmanager --sdk_root=/home/dev/sw/androidsdk/ --licenses
