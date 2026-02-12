FROM node:22

# Install basic tools + Chromium for browser automation
# Chromium needs --no-sandbox when running as root in Docker;
# clawdbot handles this via its CHROMIUM_FLAGS / puppeteer config
RUN apt-get update && apt-get install -y \
    curl \
    git \
    rsync \
    chromium \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# We use --break-system-packages because Debian/Ubuntu now block global pip installs by default
RUN pip3 install --no-cache-dir yfinance>=0.2.40 --break-system-packages

# Tell Puppeteer/Playwright to use the system Chromium instead of downloading their own
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
ENV CHROME_PATH=/usr/bin/chromium
ENV CHROMIUM_FLAGS="--no-sandbox --disable-gpu --disable-dev-shm-usage"

# Optional extra apt packages (set via docker-compose build args)
ARG EXTRA_APT_PACKAGES=""
RUN if [ -n "$EXTRA_APT_PACKAGES" ]; then \
      apt-get update && apt-get install -y $EXTRA_APT_PACKAGES && rm -rf /var/lib/apt/lists/*; \
    fi

# Install pnpm globally
RUN npm install -g pnpm

# Install openclaw
# Pin to specific version for reproducible builds
RUN npm install -g openclaw@latest \
    && openclaw --version

# Install clawdhub
RUN npm install -g clawdhub undici

# Run user-setup.sh hook for custom toolchains (Rust, Go, Python, etc.)
COPY user-setup.sh /tmp/user-setup.sh
RUN chmod +x /tmp/user-setup.sh && /tmp/user-setup.sh

# Create directories
# Templates are stored separately so we can detect first-run vs existing config
RUN mkdir -p /root/.clawdbot \
    && mkdir -p /root/.clawdbot-templates \
    && mkdir -p /root/clawd \
    && mkdir -p /root/clawd/skills

# Copy startup script
COPY start-openclaw.sh /usr/local/bin/start-openclaw.sh
RUN chmod +x /usr/local/bin/start-openclaw.sh

# Copy default configuration template
COPY openclaw.json.template /root/.clawdbot-templates/openclaw.json.template

# Set working directory
WORKDIR /root/clawd

# Expose the gateway port
EXPOSE 18789

CMD ["/usr/local/bin/start-openclaw.sh"]
