FROM debian:bookworm

ENV container docker
STOPSIGNAL SIGRTMIN+3

# Install Node 22 from NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get update \
    && apt-get install -y nodejs \
    && apt-get clean

# Install other packages
RUN apt-get update && apt-get install -y \
    git \
    rsync \
    chromium \
    python3 \
    python3-pip \
    build-essential \
    procps \
    file \
    psmisc \
    && apt-get clean

# Install global tools
RUN npm install -g pnpm openclaw@latest clawhub

# Create service file safely
RUN printf '%s\n' \
"[Unit]" \
"Description=OpenClaw Service" \
"After=network.target" \
"" \
"[Service]" \
"Type=simple" \
"ExecStart=/usr/local/bin/start-openclaw.sh" \
"Restart=always" \
"" \
"[Install]" \
"WantedBy=multi-user.target" \
> /etc/systemd/system/openclaw.service

COPY start-openclaw.sh /usr/local/bin/start-openclaw.sh
RUN chmod +x /usr/local/bin/start-openclaw.sh \
    && systemctl enable openclaw.service

EXPOSE 18789

CMD ["/sbin/init"]
