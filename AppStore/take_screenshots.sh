#!/bin/bash
# Script to capture App Store screenshots for iClaudius

SCREENSHOTS_DIR="$(dirname "$0")/screenshots"
mkdir -p "$SCREENSHOTS_DIR"

echo "=== iClaudius Screenshot Capture ==="
echo "Please position the app window and press Enter when ready for each screenshot."
echo ""

# Function to capture a screenshot
capture() {
    local name=$1
    local caption=$2
    echo "Screenshot: $caption"
    echo "Press Enter when ready..."
    read -r
    screencapture -w "$SCREENSHOTS_DIR/${name}.png"
    echo "Saved: $SCREENSHOTS_DIR/${name}.png"
    echo ""
}

echo "Launching iClaudius..."
open ~/xcode_projects/iClaudius/iClaudius.app
sleep 2

echo ""
echo "Position the window and navigate to each section as prompted."
echo ""

capture "01_overview" "Dashboard Overview - Show main dashboard with health bar and stats"
capture "02_claudemd" "CLAUDE.md Files - Show the file list with one selected"
capture "03_commands" "Custom Slash Commands - Show command list with search"
capture "04_cronjobs" "Cron Jobs - Show job list with Add Job dialog open"
capture "05_suggestions" "Suggestions - Show overview with suggestion card visible"

echo "=== Screenshot capture complete! ==="
echo "Screenshots saved to: $SCREENSHOTS_DIR"
echo ""
echo "Remember to resize for App Store requirements:"
echo "  - 1280 x 800 (MacBook)"
echo "  - 2560 x 1600 (MacBook Retina)"
echo "  - 1920 x 1080 (iMac)"
