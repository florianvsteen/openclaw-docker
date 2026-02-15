FROM node:22

# Install basic tools + Chromium for browser automation
# Chromium needs --no-sandbox when running as root in Docker;
# openclaw handles this via its CHROMIUM_FLAGS / puppeteer config
RUN apt-get update && apt-get install -y \
    curl \
    git \
    rsync \
    chromium \
    python3 \
    python3-pip \
    build-essential \
    procps \
    file \
    && rm -rf /var/lib/apt/lists/*

# --- HOMEBREW INSTALLATION ---
# Brew requires a non-root user to install, but we can set it up for root 
# by installing to /home/linuxbrew/.linuxbrew
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add Brew to the PATH for all subsequent layers
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"
# Set typical Brew env vars
ENV HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
ENV HOMEBREW_CELLAR="/home/linuxbrew/.linuxbrew/Cellar"
ENV HOMEBREW_REPOSITORY="/home/linuxbrew/.linuxbrew/Homebrew"

# Optional: Disable Brew analytics to speed up builds
ENV HOMEBREW_NO_ANALYTICS=1
# --

# Tell Puppeteer/Playwright to use the system Chromium instead of downloading their own
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
ENV CHROME_PATH=/usr/bin/chromium
ENV CHROMIUM_FLAGS="--no-sandbox --disable-gpu --disable-dev-shm-usage --user-agent=\"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36\""

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

# Install clawhub
RUN npm i -g clawhub

# Run user-setup.sh hook for custom toolchains (Rust, Go, Python, etc.)
COPY user-setup.sh /tmp/user-setup.sh
RUN chmod +x /tmp/user-setup.sh && /tmp/user-setup.sh

# Create directories
# Templates are stored separately so we can detect first-run vs existing config
RUN mkdir -p /root/.openclaw \
    && mkdir -p /root/.openclaw-templates \
    && mkdir -p /root/openclaw \
    && mkdir -p /root/openclaw/skills

# Copy startup script
COPY start-openclaw.sh /usr/local/bin/start-openclaw.sh
RUN chmod +x /usr/local/bin/start-openclaw.sh

# Copy default configuration template
COPY openclaw.json.template /root/.openclaw-templates/openclaw.json.template

# Set working directory
WORKDIR /root/openclaw

# Expose the gateway port
EXPOSE 18789

CMD ["/usr/local/bin/start-openclaw.sh"]
