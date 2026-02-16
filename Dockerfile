FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV container=docker

# Install systemd + tools + Node
RUN apt-get update && apt-get install -y \
    systemd \
    systemd-sysv \
    dbus \
    curl \
    git \
    rsync \
    chromium-browser \
    python3 \
    python3-pip \
    build-essential \
    procps \
    file \
    psmisc \
    ca-certificates \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Install Node 22 manually
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs

# Install pnpm + openclaw
RUN npm install -g pnpm openclaw@latest clawhub

# Required for systemd
VOLUME [ "/sys/fs/cgroup" ]

STOPSIGNAL SIGRTMIN+3

EXPOSE 18789

CMD ["/lib/systemd/systemd"]
