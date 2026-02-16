FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV container=docker

# Install systemd + tools + Node
RUN apt-get update

RUN apt-get install -y systemd
RUN apt-get install -y systemd-sysv
RUN apt-get install -y dbus
RUN apt-get install -y curl
RUN apt-get install -y git
RUN apt-get install -y rsync
RUN apt-get install -y chromium-browser
RUN apt-get install -y python3
RUN apt-get install -y python3-pip
RUN apt-get install -y build-essential
RUN apt-get install -y procps
RUN apt-get install -y file
RUN apt-get install -y psmisc
RUN apt-get install -y ca-certificates
RUN apt-get install -y gnupg
RUN apt-get install -y lsb-release

RUN rm -rf /var/lib/apt/lists/*

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
