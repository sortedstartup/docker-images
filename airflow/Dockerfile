# Start with the official Airflow image
FROM apache/airflow:3.3.0

# Switch to root to install system dependencies
USER root

# Install dependencies required to download and use Go
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    iputils-ping \
    curl \
    git \
    zip \
    unzip \
    build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ARG TARGETARCH is automatically populated by Docker Buildx (e.g., "amd64" or "arm64")
ARG TARGETARCH
# Set your desired Go version here
ARG GO_VERSION=1.26.0

# Dynamically download the correct Go binary based on the target architecture
RUN echo "Building for architecture: ${TARGETARCH}" && \
    curl -L -o go.tar.gz "https://go.dev/dl/go${GO_VERSION}.linux-${TARGETARCH}.tar.gz" && \
    tar -C /usr/local -xzf go.tar.gz && \
    rm go.tar.gz

# Install AWS CLI v2
RUN if [ "$TARGETARCH" = "amd64" ]; then AWS_ARCH="x86_64"; elif [ "$TARGETARCH" = "arm64" ]; then AWS_ARCH="aarch64"; else echo "Unsupported architecture: $TARGETARCH"; exit 1; fi && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip

# Update the PATH environment variable so 'go' is globally accessible
ENV PATH="/usr/local/go/bin:${PATH}"

# Verify installation (useful for build logs)
RUN go version

# Switch back to the airflow user for security (Standard Airflow practice)
USER airflow
