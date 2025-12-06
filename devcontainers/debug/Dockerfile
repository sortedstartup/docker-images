FROM ubuntu:jammy

RUN apt-get update && apt-get install -y --no-install-recommends \
    sqlite3 \
    net-tools \
    iproute2 \
    iputils-ping \
    dnsutils \
    curl \
    wget \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

CMD [ "bash" ]