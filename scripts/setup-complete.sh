#!/bin/bash
# OpenClaw Complete Setup Script for Raspberry Pi 500
# Usage: curl -sL https://raw.githubusercontent.com/USER/openclaw-pi5-setup/main/scripts/setup-complete.sh | bash
#
# This script automates the ENTIRE setup process:
# 1. System preparation
# 2. Node.js installation
# 3. OpenClaw CLI install
# 4. Workspace setup
# 5. Local embeddings configuration
# 6. Backup setup
# 7. Telegram channel (optional)
# 8. Gateway start
# 9. Verification

set -euo pipefail

# Configuration - EDIT THESE
OPENCLAW_USER="user"              # Your username (not root)
GITHUB_REPO="your-username/openclaw-workspace"  # Your backup repo
TIMEZONE="UTC"                   # Your timezone

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Pre-flight checks
check_prerequisites() {
    log_info "Running pre-flight checks..."
    
    # Check not root
    if [ "$EUID" -eq 0 ]; then
        log_error "Don't run as root. Run as regular user with sudo access."
        exit 1
    fi
    
    # Check Raspberry Pi
    if grep -q "Raspberry" /proc/device-tree/model 2>/dev/null; then
        log_info "Detected Raspberry Pi"
    else
        log_warn "Not a Raspberry Pi - continuing anyway"
    fi
    
    # Check internet
    if ! curl -s --max-time 5 https://github.com > /dev/null; then
        log_error "No internet connection"
        exit 1
    fi
    
    # Check disk space (need 20GB)
    avail=$(df -BG ~ | awk 'NR==2 {print $4}' | tr -d 'G')
    if [ "$avail" -lt 20 ]; then
        log_error "Need at least 20GB free, have ${avail}GB"
        exit 1
    fi
    
    log_info "Pre-flight checks passed"
}

# Step 1: System Preparation
prepare_system() {
    log_info "Step 1: Preparing system..."
    
    sudo apt update
    sudo apt install -y build-essential pkg-config git curl
    
    log_info "System prepared"
}

# Step 2: Node.js Installation
install_nodejs() {
    log_info "Step 2: Installing Node.js..."
    
    if command -v node &> /dev/null; then
        log_info "Node.js already installed: $(node --version)"
    else
        curl -fsSL https://deb.nodesource.com/setup_25.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
    
    # Verify
    NODE_VER=$(node --version)
    if [[ "$NODE_VER" != v25* ]]; then
        log_warn "Expected Node.js 25.x, got $NODE_VER"
    fi
    
    log_info "Node.js installed: $(node --version)"
}

# Step 3: OpenClaw CLI
install_openclaw() {
    log_info "Step 3: Installing OpenClaw CLI..."
    
    if command -v openclaw &> /dev/null; then
        log_info "OpenClaw already installed: $(openclaw --version)"
    else
        npm install -g openclaw
    fi
    
    log_info "OpenClaw installed: $(openclaw --version)"
}

# Step 4: Workspace Setup
setup_workspace() {
    log_info "Step 4: Setting up workspace..."
    
    WORKSPACE="$HOME/.openclaw/workspace"
    
    # Create workspace directory
    mkdir -p "$WORKSPACE"
    
    # Initialize git if not already
    if [ ! -d "$WORKSPACE/.git" ]; then
        cd "$WORKSPACE"
        git init
        git config user.name "OpenClaw"
        git config user.email "openclaw@localhost"
        
        # Create initial files
        cat > "$WORKSPACE/AGENTS.md" << 'EOF'
# AGENTS.md - Workspace Conventions

_Edit this file to define how the AI assistant should behave._

## Core Principles
- Be helpful but not intrusive
- Prefer action over questions
- Document decisions
EOF
        
        cat > "$WORKSPACE/SOUL.md" << 'EOF'
# SOUL.md - AI Identity

_Define the AI's personality and values._

## Name
Assistant

## Nature
Helpful AI assistant running on Raspberry Pi 500
EOF
        
        cat > "$WORKSPACE/USER.md" << 'EOF'
# USER.md - About the User

_Edit with information about the user._

- Name: User
- Timezone: UTC
EOF
        
        git add -A
        git commit -m "Initial workspace setup"
    fi
    
    log_info "Workspace ready at $WORKSPACE"
}

# Step 5: Local Embeddings
setup_embeddings() {
    log_info "Step 5: Configuring local embeddings..."
    
    CONFIG_FILE="$HOME/.openclaw/openclaw.json"
    
    # Backup existing
    if [ -f "$CONFIG_FILE" ]; then
        cp "$CONFIG_FILE" "${CONFIG_FILE}.backup-$(date +%Y%m%d)"
    fi
    
    # Create config with local embeddings
    mkdir -p "$HOME/.openclaw"
    
    cat > "$CONFIG_FILE" << 'EOF'
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "kilocode/minimax/minimax-m2.5:free"
      },
      "workspace": "/home/user/.openclaw/workspace",
      "memorySearch": {
        "provider": "local",
        "local": {
          "modelPath": "hf:ggml-org/embeddinggemma-300m-qat-q8_0-GGUF/embeddinggemma-300m-qat-Q8_0.gguf"
        },
        "cache": {
          "enabled": true,
          "maxEntries": 50000
        },
        "sync": {
          "watch": true
        }
      }
    }
  }
}
EOF
    
    log_info "Local embeddings configured (model will download on first use)"
}

# Step 6: Backup Setup
setup_backup() {
    log_info "Step 6: Setting up automatic backups..."
    
    # Create backup script
    cat > "$HOME/backup-workspace.sh << 'EOF'
#!/bin/bash
# OpenClaw Workspace Backup Script

WORKSPACE="$HOME/.openclaw/workspace"
BACKUP_LOG="$WORKSPACE/memory/backup.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] Starting backup..." >> "$BACKUP_LOG"

cd "$WORKSPACE" || exit 1

git add -A >> "$BACKUP_LOG" 2>&1

if git diff --cached --quiet; then
    echo "[$DATE] No changes to commit." >> "$BACKUP_LOG"
    exit 0
fi

git commit -m "Auto-backup: $(date '+%Y-%m-%d %H:%M')" >> "$BACKUP_LOG" 2>&1
git push origin main >> "$BACKUP_LOG" 2>&1

if [ $? -eq 0 ]; then
    echo "[$DATE] Backup successful." >> "$BACKUP_LOG"
else
    echo "[$DATE] Backup FAILED!" >> "$BACKUP_LOG"
fi
EOF
    
    chmod +x "$HOME/backup-workspace.sh"
    
    # Add to crontab (daily at 2am)
    (crontab -l 2>/dev/null | grep -v backup-workspace; echo "0 2 * * * $HOME/backup-workspace.sh") | crontab -
    
    log_info "Backup configured (daily at 2am UTC)"
}

# Step 7: Gateway Start
start_gateway() {
    log_info "Step 7: Starting OpenClaw gateway..."
    
    # Kill existing if running
    pkill -f openclaw-gateway 2>/dev/null || true
    sleep 2
    
    # Start gateway
    openclaw gateway start
    
    # Wait for startup
    sleep 5
    
    log_info "Gateway started"
}

# Step 8: Verification
verify_installation() {
    log_info "Step 8: Verifying installation..."
    
    # Check gateway
    if curl -s --max-time 5 http://127.0.0.1:18789/ > /dev/null 2>&1; then
        log_info "Gateway: OK"
    else
        log_warn "Gateway not responding yet"
    fi
    
    # Check memory
    openclaw memory status || log_warn "Memory not configured yet"
    
    log_info "Verification complete"
}

# Main
main() {
    echo "============================================"
    echo "  OpenClaw Complete Setup for Raspberry Pi 500"
    echo "============================================"
    echo ""
    
    check_prerequisites
    prepare_system
    install_nodejs
    install_openclaw
    setup_workspace
    setup_embeddings
    setup_backup
    start_gateway
    verify_installation
    
    echo ""
    echo "============================================"
    echo "  ✅ Setup Complete!"
    echo "============================================"
    echo ""
    echo "Next steps:"
    echo "  1. openclaw status          # Check status"
    echo "  2. openclaw models list    # List models"
    echo "  3. openclaw configure       # Configure channels"
    echo ""
    echo "First memory search will download embeddings model (~314MB)"
}

main "$@"
```
```bash
# Backup existing config
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.backup

# Add exec security configuration using jq
jq '.tools = {
  "profile": "full",
  "allow": ["*"],
  "exec": {
    "host": "gateway",
    "security": "full",
    "ask": "off"
  },
  "web": {
    "search": {
      "enabled": true,
      "apiKey": "YOUR_BRAVE_API_KEY"
    },
    "fetch": {
      "enabled": true
    }
  }
}' ~/.openclaw/openclaw.json > /tmp/openclaw.json && mv /tmp/openclaw.json ~/.openclaw/openclaw.json
```
```bash
# Restart to apply new config
openclaw gateway restart

# Verify exec is working
openclaw doctor
```
```bash
# Test exec
exec echo "Exec is working!"

# Test web search
openclaw search "test query"

# Check status
openclaw status
