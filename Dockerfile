# Use Debian base so systemd works properly
FROM node:22-bookworm

ENV container docker

# Install systemd + required tools
RUN apt-get update && apt-get install -y \
    systemd \
    systemd-sysv \
    dbus \
    curl \
    git \
    rsync \
    chromium \
    python3 \
    python3-pip \
    build-essential \
    procps \
    file \
    psmisc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Remove unnecessary systemd services to slim down container
RUN rm -f /lib/systemd/system/multi-user.target.wants/* \
    && rm -f /etc/systemd/system/*.wants/* \
    && rm -f /lib/systemd/system/local-fs.target.wants/* \
    && rm -f /lib/systemd/system/sockets.target.wants/*udev* \
    && rm -f /lib/systemd/system/sockets.target.wants/*initctl* \
    && rm -f /lib/systemd/system/basic.target.wants/* \
    && rm -f /lib/systemd/system/anaconda.target.wants/*

# Prepare Homebrew prefix
RUN mkdir -p /home/linuxbrew/.linuxbrew \
 && chown -R node:node /home/linuxbrew

USER node
RUN NONINTERACTIVE=1 /bin/bash -lc \
  "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"

USER root

# Chromium environment
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
ENV CHROME_PATH=/usr/bin/chromium
ENV CHROMIUM_FLAGS="--no-sandbox --disable-gpu --disable-dev-shm-usage"

ARG EXTRA_APT_PACKAGES=""
RUN if [ -n "$EXTRA_APT_PACKAGES" ]; then \
      apt-get update && apt-get install -y $EXTRA_APT_PACKAGES && rm -rf /var/lib/apt/lists/*; \
    fi

# Install pnpm
RUN npm install -g pnpm

# Install openclaw + clawhub
RUN npm install -g openclaw@latest \
    && openclaw --version

RUN npm install -g clawhub

# Run custom setup
COPY user-setup.sh /tmp/user-setup.sh
RUN chmod +x /tmp/user-setup.sh && /tmp/user-setup.sh

# Directories
RUN mkdir -p /root/.openclaw \
    && mkdir -p /root/.openclaw-templates \
    && mkdir -p /root/openclaw/skills

COPY openclaw.json.template /root/.openclaw-templates/openclaw.json.template

WORKDIR /root/openclaw

# ---------------------------
# Create systemd service
# ---------------------------
RUN bash -c 'cat > /etc/systemd/system/openclaw.service <<EOF
[Unit]
Description=OpenClaw Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/start-openclaw.sh
Restart=always
User=root
Environment=PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
Environment=CHROME_PATH=/usr/bin/chromium
Environment=CHROMIUM_FLAGS=--no-sandbox --disable-gpu --disable-dev-shm-usage

[Install]
WantedBy=multi-user.target
EOF'

COPY start-openclaw.sh /usr/local/bin/start-openclaw.sh
RUN chmod +x /usr/local/bin/start-openclaw.sh

# Enable service
RUN systemctl enable openclaw.service

EXPOSE 18789

STOPSIGNAL SIGRTMIN+3

CMD ["/sbin/init"]
