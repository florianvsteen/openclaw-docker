FROM jrei/systemd-ubuntu:22.04

# Install Node.js 22 repository
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash -

# Install basic tools + Chromium for browser automation
RUN apt-get update && apt-get install -y \
    nodejs \
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
    systemd \
    systemd-sysv \
    && rm -rf /var/lib/apt/lists/*

# Prepare Homebrew prefix with correct ownership (root)
RUN mkdir -p /home/linuxbrew/.linuxbrew \
 && useradd -m -s /bin/bash node || true \
 && chown -R node:node /home/linuxbrew

# Install Homebrew as non-root (node)
USER node
RUN NONINTERACTIVE=1 /bin/bash -lc \
  "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Back to root for remaining setup
USER root

# Persist brew on PATH for later layers
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"

# Tell Puppeteer/Playwright to use the system Chromium
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser
ENV CHROME_PATH=/usr/bin/chromium-browser
ENV CHROMIUM_FLAGS="--no-sandbox --disable-gpu --disable-dev-shm-usage --user-agent=\"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36\""

# Optional extra apt packages (set via docker-compose build args)
ARG EXTRA_APT_PACKAGES=""
RUN if [ -n "$EXTRA_APT_PACKAGES" ]; then \
      apt-get update && apt-get install -y $EXTRA_APT_PACKAGES && rm -rf /var/lib/apt/lists/*; \
    fi

# Install pnpm globally
RUN npm install -g pnpm

# Install openclaw
RUN npm install -g openclaw@latest \
    && openclaw --version

# Install clawhub
RUN npm i -g clawhub

# Run user-setup.sh hook for custom toolchains (Rust, Go, Python, etc.)
COPY user-setup.sh /tmp/user-setup.sh
RUN chmod +x /tmp/user-setup.sh && /tmp/user-setup.sh

# Create directories
RUN mkdir -p /root/.openclaw \
    && mkdir -p /root/.openclaw-templates \
    && mkdir -p /root/openclaw \
    && mkdir -p /root/openclaw/skills

# Copy configuration template
COPY openclaw.json.template /root/.openclaw-templates/openclaw.json.template

# Copy systemd service file
COPY openclaw.service /etc/systemd/system/openclaw.service

# Copy startup script (used by systemd service)
COPY start-openclaw.sh /usr/local/bin/start-openclaw.sh
RUN chmod +x /usr/local/bin/start-openclaw.sh

# Enable the openclaw service
RUN systemctl enable openclaw.service

# Set working directory
WORKDIR /root/openclaw

# Expose the gateway port
EXPOSE 18789

# systemd requires these
STOPSIGNAL SIGRTMIN+3

# Start systemd as PID 1
CMD ["/lib/systemd/systemd"]
