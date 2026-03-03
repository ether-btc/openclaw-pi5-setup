#!/bin/bash
# OpenClaw Fresh Install Script for Raspberry Pi 5
# Usage: curl -sL https://raw.githubusercontent.com/ether-btc/openclaw-pi5-setup/main/scripts/openclaw-install.sh | bash

set -e

echo "🦞 OpenClaw Fresh Install Script"
echo "================================="

# Check running as user (not root)
if [ "$EUID" -eq 0 ]; then
    echo "Error: Don't run as root. Run as pi user with sudo access."
    exit 1
fi

# Check Raspberry Pi
if ! grep -q "Raspberry" /proc/device-tree/model 2>/dev/null; then
    echo "Warning: Not a Raspberry Pi. Continuing anyway..."
fi

echo ""
echo "=== Step 1: Node.js ==="
if command -v node &> /dev/null; then
    echo "Node.js already installed: $(node --version)"
else
    curl -fsSL https://deb.nodesource.com/setup_25.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

echo ""
echo "=== Step 2: OpenClaw CLI ==="
if command -v openclaw &> /dev/null; then
    echo "OpenClaw already installed: $(openclaw --version)"
else
    npm install -g openclaw
fi

echo ""
echo "=== Step 3: Initial Setup ==="
openclaw setup

echo ""
echo "=== Step 4: Add Telegram Channel (optional) ==="
read -p "Add Telegram? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    openclaw configure channels add telegram
fi

echo ""
echo "=== Step 5: Verify Installation ==="
openclaw doctor

echo ""
echo "✅ Installation complete!"
echo "Next steps:"
echo "  - Run: openclaw status"
echo "  - Add models: openclaw models add"
echo "  - Configure more channels: openclaw configure channels"
