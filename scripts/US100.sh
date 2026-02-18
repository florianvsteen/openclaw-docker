#!/bin/bash

# TradingView automation script
# Runs every 10 minutes

# Navigate to chart
agent-browser open https://www.tradingview.com/chart/

# Execute key sequence
agent-browser press Enter
agent-browser press U
agent-browser press S
agent-browser press 1
agent-browser press 0
agent-browser press 0
agent-browser press Enter
agent-browser press Control+r
agent-browser press Enter
agent-browser press 1
agent-browser press Enter

# Click button
agent-browser find role button click --name "Watchlist, details and news"

# Take screenshot
agent-browser screenshot /root/openclaw/screenshots/US100.png

# Send to Discord
curl -X POST --form "content=Screenshot of US100" --form "file=@/root/openclaw/screenshots/US100.png" https://discord.com/api/webhooks/fakeurl
