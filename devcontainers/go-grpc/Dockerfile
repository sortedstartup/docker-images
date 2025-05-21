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
FROM ubuntu:jammy AS base

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

# Without this the tzdata will ask for input and hand the docker image build forever 
ARG DEBIAN_FRONTEND=noninteractive

RUN apt update \
    # Only for installing gh tools from github
    && apt install -y wget \
    && mkdir -p -m 755 /etc/apt/keyrings \
    && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg |  tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt clean

# [Optional] Add sudo support. Omit if you don't need to install software after connecting.
RUN  apt update \
     && apt install -y sudo wget \
                          net-tools \
                          jq graphviz\
			              vim nano\
                          tmux screen \
                          tree htop \
                          pgcli \
                          ruby ruby-dev \
                          gh \
                          neovim \
    && apt clean

RUN echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME  \
    && apt update \
    && apt install -y wget curl git jq python3 python3-pip unzip zip inetutils-ping sqlite3 libsqlite3-dev make postgresql-client \
    && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \ 
    && mv ./kubectl /usr/local/bin \
    && sudo gem install fastlane \
    && apt clean

RUN apt update \
    && apt install -y fzf telnet lsof tree bc traceroute dnsutils netcat nmap tcpdump tmux \
    && apt clean
RUN curl -L https://github.com/stripe/stripe-cli/releases/download/v1.27.0/stripe_1.27.0_linux_x86_64.tar.gz | tar -zxvf - -C /usr/local/bin

USER ${USERNAME}

RUN mkdir ${USER_SW_HOME}

RUN git clone https://github.com/LazyVim/starter ~/.config/nvim
RUN curl -L https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/FiraCode.zip -o /tmp/FiraCode.zip
RUN mkdir -p ${USER_SW_HOME}/.local/share/fonts
RUN unzip /tmp/FiraCode.zip -d ${USER_SW_HOME}/.local/share/fonts
RUN fc-cache -fv

FROM base AS dev-go-npm-grpc
# Install Go 1.24.3
RUN wget https://go.dev/dl/go1.24.3.linux-amd64.tar.gz -O - | tar -xz -C ${USER_SW_HOME} && \
echo "export PATH=\$PATH:${USER_SW_HOME}/go/bin">> ${USER_HOME}/profile

# Set environment variable for Go
ENV PATH="${PATH}:${USER_SW_HOME}/bin:${USER_SW_HOME}/go/bin:${USER_HOME}/go/bin"

# Install Node.js using NVM
ENV NVM_DIR=${USER_SW_HOME}/nvm
RUN mkdir $NVM_DIR
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash && \
    . "$NVM_DIR/nvm.sh" && \
    #TODO: install specific version
    nvm install --lts && \
    nvm use --lts && \
    NODE_DIR=$(dirname $(dirname $(nvm which current))) && \
    ln -s $NODE_DIR /home/dev/sw/node-current && \
    echo "export PATH=\$PATH:/usr/local/nvm/versions/node/$(node --version)/bin">> ${USER_HOME}/profile

# Install SDKMAN
RUN curl -s "https://get.sdkman.io" | bash
RUN bash -c "source ${HOME}/.sdkman/bin/sdkman-init.sh && sdk version"


# ------- GRPC Tools --------
# Install protoc
RUN wget https://github.com/protocolbuffers/protobuf/releases/download/v31.0/protoc-31.0-linux-x86_64.zip -O ${USER_SW_HOME}/protoc.zip && \
    unzip ${USER_SW_HOME}/protoc.zip -d ${USER_SW_HOME} && \
    rm ${USER_SW_HOME}/protoc.zip

# Install grpc tools , this can be moved to dev container startup steps also as we dont knw what is the GOPATH before hand, we kind of know
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.36.6 && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.5.1 && \
    go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest && \
    # For debugging go programs
    go install -v github.com/go-delve/delve/cmd/dlv@latest && \
    go install golang.org/x/tools/gopls@latest && \
    go install golang.org/x/lint/golint@latest && \
    go install honnef.co/go/tools/cmd/staticcheck@latest && \
    # Without this there is ~400 MB in ~/.cache/go-build
    go clean -cache && \
    go clean -modcache

RUN . "$NVM_DIR/nvm.sh" && npm install -g protoc-gen-ts


# ----- add git mod cache, this speeds up the first go run and build ----- 
# but it depennds on the project because every project has different dependencies and versions
# This can doen in the post create step of dev containers

# -----

FROM dev-go-npm-grpc AS dev-go-npm-grpc-java-android
# ------- Android SDK --------
# TODO: see if we can use latest java 
# Installing Java 
RUN bash -c "source ${HOME}/.sdkman/bin/sdkman-init.sh  && sdk install java 21.0.2-open"

RUN mkdir /home/dev/sw/android_cmdtools && \
    cd /home/dev/sw/android_cmdtools && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip && \
    unzip commandlinetools-linux-13114758_latest.zip && \
    rm commandlinetools-linux-13114758_latest.zip

ENV ANDROID_HOME=/home/dev/sw/androidsdk

# TODO: init sdk man and remove java from path and JAVA_HOME
RUN PATH=$PATH:${USER_SW_HOME}/android_cmdtools/cmdline-tools/bin:/home/dev/.sdkman/candidates/java/current/bin && \
    JAVA_HOME=/home/dev/.sdkman/candidates/java/current && \
    yes|sdkmanager --sdk_root=/home/dev/sw/androidsdk/ --install "platform-tools" "platforms;android-34" "build-tools;34.0.0" && \
    yes|sdkmanager --sdk_root=/home/dev/sw/androidsdk/ --licenses && \
    echo "export PATH=\$PATH:${ANDROID_HOME}/platform-tools">> ${USER_HOME}/profile

ENV PATH="${PATH}:${ANDROID_HOME}/platform-tools"
