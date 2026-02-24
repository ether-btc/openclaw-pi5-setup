#!/bin/bash
#
# OpenClaw Local Embeddings Setup Script for Raspberry Pi 5
# Repository: https://github.com/ether-btc/openclaw-pi5-setup
#
# Usage:
#   chmod +x scripts/setup-local-embeddings.sh
#   ./scripts/setup-local-embeddings.sh
#
# This script configures OpenClaw with local embeddings using
# embeddinggemma-300m (no API costs, fully local).
#
# Tested on: Raspberry Pi 5, Debian Bookworm, ARM64
# OpenClaw version: 2026.2.24
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Config paths
CONFIG_FILE="$HOME/.openclaw/openclaw.json"
BACKUP_DIR="$HOME/.openclaw/backups"

echo "🦞 OpenClaw Local Embeddings Setup"
echo "=================================="
echo ""

# Check if OpenClaw is installed
if ! command -v openclaw &> /dev/null; then
    echo -e "${RED}Error: OpenClaw is not installed${NC}"
    echo "Install with: npm install -g openclaw"
    exit 1
fi

# Check if config exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}Config not found. Running 'openclaw configure'...${NC}"
    openclaw configure
fi

# Create backup
mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/openclaw.json.backup-$(date +%Y%m%d-%H%M%S)"
cp "$CONFIG_FILE" "$BACKUP_FILE"
echo -e "${GREEN}✓${NC} Backed up config to: $BACKUP_FILE"

# Check if memorySearch already configured
if jq -e '.agents.defaults.memorySearch.provider == "local"' "$CONFIG_FILE" > /dev/null 2>&1; then
    echo -e "${YELLOW}Local embeddings already configured${NC}"
    echo "Current config:"
    jq '.agents.defaults.memorySearch' "$CONFIG_FILE"
    echo ""
    read -p "Reconfigure? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

# Build the memorySearch config
echo ""
echo "Configuring local embeddings..."
echo "  Model: embeddinggemma-300m-qat-Q8_0 (314MB)"
echo "  Provider: local (no API costs)"
echo ""

# Use jq to merge the configuration
jq '.agents.defaults.memorySearch = {
  "provider": "local",
  "local": {
    "modelPath": "hf:ggml-org/embeddinggemma-300m-qat-q8_0-GGUF/embeddinggemma-300m-qat-Q8_0.gguf"
  },
  "sync": {
    "watch": true
  },
  "cache": {
    "enabled": true,
    "maxEntries": 50000
  }
}' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

echo -e "${GREEN}✓${NC} Configuration updated"

# Verify
echo ""
echo "Verifying configuration..."
jq '.agents.defaults.memorySearch' "$CONFIG_FILE"

echo ""
echo -e "${GREEN}✓${NC} Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Restart OpenClaw gateway: openclaw gateway restart"
echo "  2. Verify memory system: openclaw memory status"
echo "  3. First search will download the model (~314MB)"
echo ""
echo "To enable hard enforcement (auto-inject memories):"
echo "  Add to plugins.entries in config:"
echo '  "memory-hard-enforcement": { "enabled": true }'
