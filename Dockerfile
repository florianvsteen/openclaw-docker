# Use Ubuntu 24.04 LTS as the base image
FROM ubuntu:24.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Define build argument for extra packages (Official compatibility)
ARG OPENCLAW_DOCKER_APT_PACKAGES=""

# Install dependencies
# - dumb-init: handles PID 1 signals correctly
# - libvips-dev: for sharp (image processing) optimization
# - ffmpeg: for media processing capabilities
# - jq: useful for JSON manipulation in scripts
# - cron: for scheduling periodic tasks
# - gosu: for easy step-down from root
RUN apt-get update && apt-get install -y \
    curl \
    git \
    ca-certificates \
    gnupg \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    iproute2 \
    dumb-init \
    libvips-dev \
    ffmpeg \
    jq \
    cron \
    gosu \
    procps \
    file \
    zip \
    unzip \
    wget \
    iputils-ping \
    dnsutils \
    net-tools \
    $OPENCLAW_DOCKER_APT_PACKAGES \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 22
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g pnpm \
    && rm -rf /var/lib/apt/lists/*

# Install pnpm + openclaw
RUN npm install -g pnpm openclaw@latest clawhub

# Required for systemd
VOLUME [ "/sys/fs/cgroup" ]

STOPSIGNAL SIGRTMIN+3

EXPOSE 18789

CMD ["/lib/systemd/systemd"]
