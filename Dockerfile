FROM node:22-bookworm

# Install system dependencies (including Homebrew prerequisites)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    unzip \
    build-essential \
    procps \
    file \
    sudo \
    jq \
    chromium \
    python3 \
    python3-pip \
    lsof \
    && rm -rf /var/lib/apt/lists/*

# Install Bun (required for build)
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"


# Install Homebrew (required for first-party skills)
# Create linuxbrew user+group and grant sudo access (required for Homebrew package installations)
RUN groupadd -f linuxbrew && \
    useradd -m -s /bin/bash -g linuxbrew linuxbrew && \
    echo 'linuxbrew ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    mkdir -p /home/linuxbrew/.linuxbrew && \
    chown -R linuxbrew:linuxbrew /home/linuxbrew/.linuxbrew
# Download and install Homebrew manually (shallow clone to reduce image size)
# Note: HOMEBREW_NO_AUTO_UPDATE is set below to disable updates
RUN mkdir -p /home/linuxbrew/.linuxbrew/Homebrew && \
    git clone --depth 1 https://github.com/Homebrew/brew /home/linuxbrew/.linuxbrew/Homebrew && \
    mkdir -p /home/linuxbrew/.linuxbrew/bin && \
    ln -s /home/linuxbrew/.linuxbrew/Homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew && \
    chown -R linuxbrew:linuxbrew /home/linuxbrew/.linuxbrew && \
    chmod -R g+rwX /home/linuxbrew/.linuxbrew
    
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"
ENV HOMEBREW_NO_AUTO_UPDATE=1
ENV HOMEBREW_NO_INSTALL_CLEANUP=1

#Install brew packages as user linuxbrew
USER linuxbrew
RUN brew install uv

USER root

# Install pnpm globally
RUN npm install -g pnpm

# Install openclaw
# Pin to specific version for reproducible builds
RUN npm install -g openclaw@latest \
    && openclaw --version

# Install clawhub
RUN npm i -g clawhub

#install agent browser
#RUN npm install -g agent-browser
#RUN agent-browser install --with-deps

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
COPY openclaw.json.template /home/node/.openclaw-templates/openclaw.json.template

# Set working directory
WORKDIR /root/openclaw

# Expose the gateway port
EXPOSE 18789

CMD ["/usr/local/bin/start-openclaw.sh"]
