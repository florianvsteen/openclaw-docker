#!/bin/bash

# TradingView automation script
# Runs every 10 minutes

# Navigate to chart
agent-browser open https://www.tradingview.com/chart/

# Click button
agent-browser find role button click --name "Watchlist, details and news"

# US100
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
# Take screenshot
agent-browser screenshot /root/openclaw/screenshots/US100.png
# Send to Discord
curl -X POST --form "content=Screenshot of US100" --form "file=@/root/openclaw/screenshots/US100.png" $DISCORD_WEBHOOK_URL

# US30
agent-browser press Enter
agent-browser press U
agent-browser press S
agent-browser press 3
agent-browser press 0
agent-browser press Enter
agent-browser press Control+r
# Take screenshot
agent-browser screenshot /root/openclaw/screenshots/US30.png
# Send to Discord
curl -X POST --form "content=Screenshot of US30" --form "file=@/root/openclaw/screenshots/US30.png" $DISCORD_WEBHOOK_URL


#XAUUSD
agent-browser press Enter
agent-browser press X
agent-browser press A
agent-browser press U
agent-browser press U
agent-browser press S
agent-browser press D
agent-browser press Enter
agent-browser press Control+r
# Take screenshot
agent-browser screenshot /root/openclaw/screenshots/XAUUSD.png
# Send to Discord
curl -X POST --form "content=Screenshot of XAUUSD" --form "file=@/root/openclaw/screenshots/XAUUSD.png" $DISCORD_WEBHOOK_URL

#Close browser
agent-browser close
