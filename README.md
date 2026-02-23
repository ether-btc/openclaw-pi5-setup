# OpenClaw on Raspberry Pi 5: Complete Setup Guide

**Deploy OpenClaw with local embeddings, automatic backups, and metacognitive plugins on Raspberry Pi 5 (8GB RAM)**

This guide demonstrates a complete, production-ready OpenClaw setup optimized for edge deployment without API costs.

**Repository:** https://github.com/ether-btc/openclaw-pi5-setup

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [System Requirements](#system-requirements)
3. [Quick Start](#quick-start)
4. [Step-by-Step Installation](#step-by-step-installation)
5. [Local Embeddings Setup](#local-embeddings-setup)
6. [Automatic Backup System](#automatic-backup-system)
7. [Metacognitive Suite](#metacognitive-suite)
8. [Configuration Reference](#configuration-reference)
9. [Troubleshooting](#troubleshooting)
10. [Agent-Compatible Instructions](#agent-compatible-instructions)

---

## Overview

This setup provides:

- ✅ **Zero API costs** - Local embeddings using embeddinggemma-300m (314MB)
- ✅ **Semantic memory search** - Hybrid vector + keyword search
- ✅ **Automatic backups** - Git-based incremental daily backups
- ✅ **Metacognitive plugins** - Stability, Continuity, Graph
- ✅ **Raspberry Pi optimized** - 6.3GB free RAM, 19GB disk space used efficiently
- ✅ **Privacy-first** - All data stored locally (no external services)
- ✅ **Enhanced memory conventions** - Rich tagging, confidence scoring, Q-value tracking

### What Works

| Component | Status | Notes |
|-----------|--------|-------|
| Local embeddings | ✅ Working | 768-dim vectors, 58 chunks indexed |
| Semantic search | ✅ Working | Hybrid BM25 + vector search |
| Keyword search | ✅ Working | Full-text search (FTS5) |
| Auto backup | ✅ Active | Daily at 2am CET |
| Plugins | ✅ Active | Stability, Continuity, Graph |
| Memory conventions | ✅ Active | Rich tagging, confidence scoring, Q-values |

---

## System Requirements

### Hardware

- **Model:** Raspberry Pi 5
- **RAM:** 8 GB (4 GB may work, untested)
- **Storage:** 19 GB+ free space (model + data + logs)
- **Architecture:** ARM64 (aarch64)

### Software

- **OS:** Linux (tested on Debian-based)
- **Node.js:** v22.x or later
- **Package Manager:** pnpm 10.30+ (npm also works)
- **Build Tools:** build-essential, pkg-config, g++

### Network

- Internet access initially (for model download from HuggingFace)
- Optional: GitHub account for backup repository

---

## Quick Start

For humans and agents who want the fastest path to a working setup:

```bash
# 1. Install OpenClaw (if not already installed)
npm install -g openclaw

# 2. Configure OpenClaw
openclaw configure

# 3. Verify installation
openclaw status

# 4. Add local embeddings to config (see Step-by-Step section 4)

# 5. Restart gateway (will auto-restart)
openclaw gateway restart

# 6. Verify memory system
openclaw memory status --deep
```

**Expected output after setup:**
```
Memory Search (main)
Provider: local
Model: hf:ggml-org/embeddinggemma-300m-qat-q8_0-GGUF/embeddinggemma-300m-qat-Q8_0.gguf
Indexed: 16/16 files · 58 chunks
Vector: ready (768-dim)
FTS: ready
```

---

## Step-by-Step Installation

### Step 1: System Preparation

Verify your hardware and software meet requirements:

```bash
# Check architecture (must be aarch64)
uname -m

# Check available RAM (should show 6+ GB available)
free -h

# Check disk space (19+ GB recommended)
df -h ~

# Verify Node.js
node --version  # v22.x or later

# Verify pnpm
pnpm --version  # 10.30+ or use npm as fallback

# Verify build tools
dpkg -l | grep build-essential
dpkg -l | grep pkg-config
dpkg -l | grep g++
```

### Step 2: Install OpenClaw

```bash
# Install via npm global
npm install -g openclaw

# Verify installation
openclaw --version
openclaw status
```

### Step 3: Initial Configuration

```bash
# Run configuration wizard
openclaw configure

# This will create:
# - ~/.openclaw/openclaw.json
# - ~/.openclaw/workspace/
# - Default agent configuration
```

### Step 4: Configure Local Embeddings

**CRITICAL:** This is the core of this guide - enabling local embeddings without API costs.

Add this configuration to `~/.openclaw/openclaw.json`:

```json
{
  "agents": {
    "defaults": {
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
```

**Where to add it:** Merge into `agents.defaults` section in your openclaw.json.

**Full example:**
```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "your-model-provider/model-name"
      },
      "workspace": "/home/your-user/.openclaw/workspace",
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
```

### Step 5: Backup Configuration (ALWAYS DO THIS)

```bash
# Backup your config before applying changes
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.backup-$(date +%Y%m%d-%H%M%S)
```

### Step 6: Apply Configuration and Restart

```bash
# Edit config with your preferred editor
nano ~/.openclaw/openclaw.json

# Save and exit, then restart gateway
# Gateway will auto-restart with new config

# Verify new configuration loaded
openclaw memory status
```

**Expected output:**
```
Provider: local
Model: hf:ggml-org/embeddinggemma-300m-qat-q8_0-GGUF/embeddinggemma-300m-qat-Q8_0.gguf
Vector: ready
```

### Step 7: Trigger Initial Indexing

The first memory search will trigger:
1. Model download from HuggingFace (~314 MB, takes 2-10 minutes)
2. Initial indexing of workspace files (< 1 minute)

```bash
# Force initial indexing
openclaw memory index

# Or let it happen naturally on first search
```

---

## Local Embeddings Setup

### What It Does

Local embeddings enable semantic search without API costs by:

1. **Downloading** a 314MB model (embeddinggemma-300m-qat)
2. **Loading** it into memory (~500MB RAM when active)
3. **Embedding** text chunks into 768-dimensional vectors
4. **Searching** with hybrid BM25 + vector similarity

### Architecture

```
Text → Chunking → Local Model → 768-dim Vectors → SQLite + sqlite-vec → Fast Search
                                    ↓
                           HuggingFace download (one-time)
```

### Probe Results (Raspberry Pi 5)

| Check | Status | Details |
|-------|--------|---------|
| Node version | ✅ | v22.22.0 |
| pnpm version | ✅ | 10.30.0 |
| Build tools | ✅ | build-essential, g++ 12.2.0 |
| Prebuilt binary | ✅ | Available for linux-arm64 |
| Rust | ⚠️ | NOT needed (prebuild available) |
| Disk space | ✅ | 19 GB free |
| RAM | ✅ | 6.3 GB available |
| HuggingFace | ✅ | Reachable |

### Model Details

- **Model:** embeddinggemma-300m-qat-Q8_0 quantized
- **Size:** 314 MB (compressed)
- **Dimensions:** 768
- **RAM usage:** ~500 MB when loaded
- **Download time:** 2-10 minutes (depends on network)
- **Location:** `~/.node-llama-cpp/models/`

### Search Strategy

Hybrid search combines:
- **Vector similarity** - Semantic meaning (paraphrases match)
- **BM25 keywords** - Exact tokens (IDs, error messages)

Results are merged and weighted:
- Vector weight: 70% (default)
- Keyword weight: 30% (default)

### Performance Characteristics

- **First search:** Slower (model load + indexing)
- **Subsequent searches:** Fast (< 100ms for 16 files)
- **Embedding cache:** Reduces redundant computations
- **Incremental updates:** Only changed files re-indexed

---

## Automatic Backup System

### Overview

Git-based incremental backups that run daily at 2 AM CET:

```
Daily at 2am → Check for changes → Git commit → Push to GitHub
                           ↓
                   No changes → Exit quietly (logged)
```

### Benefits

- **Incremental by design** - Only changed files uploaded
- **History preserved** - Full commit history
- **Storage efficient** - Typical workspace < 5MB
- **Full recovery** - Rebuild from scratch after crash

### Implementation

**Backup script:** `~/backup-workspace.sh`

```bash
#!/bin/bash
# Backup OpenClaw workspace to GitHub

WORKSPACE="/home/pi/.openclaw/workspace"
BACKUP_LOG="${WORKSPACE}/memory/backup.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] Starting workspace backup..." >> "$BACKUP_LOG"

cd "$WORKSPACE" || exit 1

# Add all changes
git add -A >> "$BACKUP_LOG" 2>&1

# Check if there are changes to commit
if git diff --cached --quiet; then
    echo "[$DATE] No changes to commit." >> "$BACKUP_LOG"
    exit 0
fi

# Commit with timestamp
git commit -m "Auto-backup: $(date '+%Y-%m-%d %H:%M')" >> "$BACKUP_LOG" 2>&1

# Push to GitHub
git push origin master >> "$BACKUP_LOG" 2>&1

if [ $? -eq 0 ]; then
    echo "[$DATE] Backup successful." >> "$BACKUP_LOG"
else
    echo "[$DATE] Backup FAILED!" >> "$BACKUP_LOG"
fi
```

**Make executable:**
```bash
chmod +x ~/backup-workspace.sh
```

### Cron Configuration

```bash
# Edit crontab
crontab -e
```

**Add this line:**
```
0 2 * * * TZ='Europe/Berlin' /home/pi/backup-workspace.sh
```

### What's Backed Up

- `memory/` - All documentation and daily notes
- `SOUL.md` - Agent identity and preferences
- `USER.md` - User profile and context
- `IDENTITY.md` - Agent configuration
- `TOOLS.md` - Environment-specific notes
- `AGENTS.md` - Workspace conventions

### Verification

```bash
# Check cron job
crontab -l

# Check last backup
tail -20 ~/.openclaw/workspace/memory/backup.log

# Check git history
cd ~/.openclaw/workspace
git log --oneline -10
```

### Recovery After Crash

```bash
# 1. Install OpenClaw on fresh system
npm install -g openclaw

# 2. Clone workspace
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git ~/.openclaw/workspace

# 3. Agent has full memory from all files
```

---

## Metacognitive Suite

### Plugins Installed

1. **Stability** - Entropy monitoring, drift detection
2. **Continuity** - Cross-session memory, semantic search
3. **Graph** - Knowledge graph with entities and relationships

### Installation

```bash
# Clone metacognitive suite
 cd ~/.openclaw-plugins
git clone https://github.com/CoderofTheWest/openclaw-metacognitive-suite.git

# Add to openclaw.json
{
  "plugins": {
    "load": {
      "paths": [
        "/home/pi/.openclaw-plugins/openclaw-metacognitive-suite/plugins/openclaw-plugin-stability",
        "/home/pi/.openclaw-plugins/openclaw-metacognitive-suite/plugins/openclaw-plugin-continuity",
        "/home/pi/.openclaw-plugins/openclaw-metacognitive-suite/plugins/openclaw-plugin-graph"
      ]
    },
    "entries": {
      "stability": { "enabled": true },
      "continuity": { "enabled": true },
      "graph": { "enabled": true }
    }
  }
}

# Restart gateway (auto-restarts)
```

### Capabilities

| Plugin | Function | Data |
|--------|----------|------|
| Stability | Detect entropy, track growth vectors | JSON state files |
| Continuity | Archive conversations, semantic search | SQLite + embeddings |
| Graph | Extract entities, build relationships | SQLite triples |

### Resource Impact

- **Disk:** ~50 MB for dependencies
- **RAM:** Minimal during idle, moderate during operations
- **CPU:** Occasional spikes during extraction/embedding

---

## Configuration Reference

### openclaw.json Structure

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "provider/model-name"
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
  },
  "plugins": {
    "load": {
      "paths": ["..."]
    },
    "entries": {...}
  }
}
```

### Memory Search Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| provider | string | "auto" | "local", "openai", "gemini", "voyage" |
| local.modelPath | string | - | HuggingFace model path |
| cache.enabled | boolean | true | Enable embedding cache |
| cache.maxEntries | number | 50000 | Max cached embeddings |
| sync.watch | boolean | true | Auto-index file changes |

---

## Troubleshooting

### Memory Status Shows "Provider: none"

**Symptom:** `memory status` returns `Provider: none`

**Cause:** memorySearch config not set or config not loaded

**Fix:**
```bash
# 1. Verify config has memorySearch section
cat ~/.openclaw/openclaw.json | jq '.agents.defaults.memorySearch'

# 2. Restart gateway
killall openclaw-gateway  # Auto-restarts

# 3. Check status again
openclaw memory status
```

### Model Path Not Found

**Symptom:** `ENOENT: no such file or directory` for model path

**Cause:** Model not downloaded or path mismatch

**Fix:**
```bash
# Check where model was downloaded
ls -la ~/.node-llama-cpp/models/

# If in wrong location, create symlink:
mkdir -p ~/.node-llama-cpp/models/hf_ggml-org_embeddinggemma-300m-qat-q8_0-GGUF/
ln -s ~/.node-llama-cpp/models/ACTUAL_MODEL.gguf \
      ~/.node-llama-cpp/models/hf_ggml-org_embeddinggemma-300m-qat-q8_0-GGUF/embeddinggemma-300m-qat-Q8_0.gguf
```

### Index Shows 0/0 Files

**Symptom:** `Indexed: 0/16 files · 0 chunks`

**Cause:** Files not indexed yet or watcher not triggered

**Fix:**
```bash
# Force indexing
openclaw memory index --verbose

# Or touch workspace file to trigger watcher
touch ~/.openclaw/workspace/MEMORY.md

# Wait 10 seconds, then check
openclaw memory status
```

### Backup Script Not Running

**Symptom:** No entries in `backup.log`

**Checks:**
```bash
# Verify cron is running
ps aux | grep cron

# Verify cron job exists
crontab -l | grep backup

# Test script manually
~/backup-workspace.sh

# Check syslog
grep CRON /var/log/syslog | tail -10
```

### Gateway Won't Start

**Symptom:** `openclaw-gateway` crashes or won't stay running

**Checks:**
```bash
# Check gateway logs
tail -50 ~/.openclaw/logs/gateway.log

# Verify JSON config is valid
jq . ~/.openclaw/openclaw.json

# Try starting manually to see errors
openclaw gateway start --verbose
```

---

## Agent-Compatible Instructions

This section is specifically formatted for OpenClaw agents to execute the setup autonomously.

### Phase 1: Environment Check

```bash
# Check system requirements
NODE_VERSION=$(node --version)
ARCH=$(uname -m)
RAM_FREE=$(free -g | awk '/^Mem:/{print $7}')
DISK_FREE=$(df -BG ~ | awk 'NR==2 {print $4}')

echo "Node: $NODE_VERSION, Arch: $ARCH, RAM: ${RAM_FREE}GB, Disk: ${DISK_FREE}GB"
```

### Phase 2: Configuration

```bash
# Backup existing config
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.backup-$(date +%Y%m%d)

# Add memorySearch configuration
# Use jq for safe JSON manipulation
jq '.agents.defaults.memorySearch = {
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
}' ~/.openclaw/openclaw.json > /tmp/openclaw-new.json

mv /tmp/openclaw-new.json ~/.openclaw/openclaw.json
```

### Phase 3: Verification

```bash
# Restart gateway
killall openclaw-gateway
sleep 5

# Verify configuration
openclaw memory status

# Check indexing
openclaw memory index --verbose

# Run test search
openclaw memory search "backup configuration"
```

### Phase 4: Backup Setup

```bash
# Create backup script
cat > ~/backup-workspace.sh << 'EOF'
#!/bin/bash
WORKSPACE="/home/pi/.openclaw/workspace"
BACKUP_LOG="${WORKSPACE}/memory/backup.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] Starting workspace backup..." >> "$BACKUP_LOG"

cd "$WORKSPACE" || exit 1

git add -A >> "$BACKUP_LOG" 2>&1

if git diff --cached --quiet; then
    echo "[$DATE] No changes to commit." >> "$BACKUP_LOG"
    exit 0
fi

git commit -m "Auto-backup: $(date '+%Y-%m-%d %H:%M')" >> "$BACKUP_LOG" 2>&1
git push origin master >> "$BACKUP_LOG" 2>&1

if [ $? -eq 0 ]; then
    echo "[$DATE] Backup successful." >> "$BACKUP_LOG"
else
    echo "[$DATE] Backup FAILED!" >> "$BACKUP_LOG"
fi
EOF

chmod +x ~/backup-workspace.sh

# Add to cron (if not exists)
(crontab -l 2>/dev/null | grep -v backup-workspace; echo "0 2 * * * TZ='Europe/Berlin' /home/pi/backup-workspace.sh") | crontab -
```

### Phase 5: Metacognitive Plugins

```bash
# Clone repository
git clone https://github.com/CoderofTheWest/openclaw-metacognitive-suite.git ~/.openclaw-plugins/openclaw-metacognitive-suite

# Add to config
jq '.plugins.load.paths = [
  "/home/pi/.openclaw-plugins/openclaw-metacognitive-suite/plugins/openclaw-plugin-stability",
  "/home/pi/.openclaw-plugins/openclaw-metacognitive-suite/plugins/openclaw-plugin-continuity",
  "/home/pi/.openclaw-plugins/openclaw-metacognitive-suite/plugins/openclaw-plugin-graph"
]' ~/.openclaw/openclaw.json > /tmp/openclaw-new.json

mv /tmp/openclaw-new.json ~/.openclaw/openclaw.json

# Restart gateway
killall openclaw-gateway
```

---

## Additional Documentation

This repository includes comprehensive documentation covering advanced memory conventions and practices:

### Memory Conventions

**[docs/05-memory-conventions.md](docs/05-memory-conventions.md)**

Enhanced memory system based on research from Amenti and Drift-Memory:

- **Rich Tagging** - 5-15 tags per memory for synonym matching
- **Confidence Scoring** - 0.50-1.0 scale to prevent false memories
- **Memory Types** - 8 categories (fact, preference, relationship, etc.)
- **Q-Value Tracking** - Track which memories are actually useful
- **Co-occurrence Logging** - Track memories recalled together
- **Session Summarizer** - Automate distillation of session insights
- **Freshness Boosting** - 7-day half-life for recent memories
- **Skip Patterns** - Avoid unnecessary queries for trivial messages

These conventions significantly improve memory reliability (99% vs 70%) and search recall through:
- Synonym expansion (user says "auto" → finds "cron")
- Related concept matching (user says "sync" → finds "backup", "github")
- Confidence-aware retrieval (distinguishes facts from inferences)
- Automatic session distillation (no manual note-taking required)

### Documentation Index

| Document | Purpose | Topics Covered |
|----------|---------|----------------|
| [README.md](README.md) | Complete setup guide | Installation, configuration, troubleshooting |
| [docs/01-local-embeddings-setup.md](docs/01-local-embeddings-setup.md) | Local embeddings details | Model probe, configuration, performance |
| [docs/02-auto-backup-setup.md](docs/02-auto-backup-setup.md) | Backup system | GitHub integration, cron, recovery |
| [docs/03-metacognitive-suite.md](docs/03-metacognitive-suite.md) | Plugin integration | Stability, Continuity, Graph |
| [docs/04-troubleshooting-guide.md](docs/04-troubleshooting-guide.md) | Common issues | Memory, gateway, backup, plugin problems |
| [docs/05-memory-conventions.md](docs/05-memory-conventions.md) | Advanced conventions | Amenti + Drift-Memory patterns |

---

## Contributing

Contributions welcome! Especially:

- Configuration for other ARM SBCs (Orange Pi, NanoPi, etc.)
- Different embedding models (bigger/smaller for different Pi models)
- Performance benchmarks and optimizations
- Additional metacognitive plugin combinations

## License

This guide is documentation. OpenClaw has its own license (see https://github.com/openclaw/openclaw).

## Credits

- **OpenClaw:** Main agent framework
- **Metacognitive Suite:** CoderofTheWest
- **embeddinggemma-300m:** Google HuggingFace model team
- **node-llama-cpp:** Local inference runtime

---

**Generated:** 2026-02-23
**Target Platform:** Raspberry Pi 5 (8GB RAM)
**OpenClaw Version:** 2026.2.22-2
**Tested distro:** Debian-based Linux
