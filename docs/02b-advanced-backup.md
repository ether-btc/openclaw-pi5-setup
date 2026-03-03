# Advanced Backup System (Phoenix Shield Pattern)

**For production systems that need maximum reliability.**

---

## Overview

The Phoenix Shield pattern adds resilience to basic backup:

- **Pre-flight checks** — Verify system health before backup
- **Retry logic** — Retry failed pushes automatically
- **Config file** — Centralized settings
- **Exclusion patterns** — Never backup sensitive files
- **Archive rotation** — Keep last N tarballs
- **Health check** — Verify system after backup

---

## Components

### 1. Backup Config File

`~/.openclaw/backup-config.json`:

```json
{
  "backup_dir": "~/.openclaw/backups",
  "backup_count": 5,
  "workspace_path": "~/.openclaw/workspace",
  "log_file": "~/.openclaw/workspace/memory/backup.log",
  "max_log_lines": 1000,
  "thresholds": {
    "min_disk_free_gb": 5,
    "min_memory_mb": 500,
    "gateway_timeout_s": 10
  },
  "git": {
    "remote": "origin",
    "branch": "main",
    "push_retries": 3,
    "push_retry_delay_s": 5
  },
  "notifications": {
    "enabled": false
  },
  "_note": "Exclude patterns are handled by ~/.openclaw/workspace/.gitignore"
}
```

### 2. Workspace Gitignore

`~/.openclaw/workspace/.gitignore`:

```gitignore
# Dependencies
node_modules/

# Logs
*.log

# Cache
.cache/

# Temporary files
*.tmp
*.temp

# OS files
.DS_Store
Thumbs.db

# Editor files
*.swp
*.swo
*~

# Build outputs
dist/
build/

# Environment files (security)
.env
.env.local
.env.*.local

# IDE
.idea/
.vscode/
```

### 3. Backup Script (v3)

Features:
- Pre-flight checks (disk, memory, gateway, git remote)
- Dry-run mode (`--dry-run`)
- Check-before-backup (skip if nothing changed)
- Retry logic for push failures
- Post-backup health check

**Installation:**

```bash
# Download from repository
curl -o ~/backup-workspace.sh \
  https://raw.githubusercontent.com/ether-btc/openclaw-pi5-setup/main/scripts/backup-workspace-v3.sh

chmod +x ~/backup-workspace.sh
```

**Usage:**

```bash
# Normal backup
~/backup-workspace.sh

# Preview only (no changes made)
~/backup-workspace.sh --dry-run
```

---

## Pre-flight Checks

Before each backup, verify:

| Check | Threshold | Action |
|-------|-----------|--------|
| Disk space | ≥ 5 GB free | Warn if low, proceed |
| Memory | ≥ 500 MB available | Warn if low, proceed |
| Gateway | Responding on 18789 | Warn only (non-fatal) |
| Git remote | Configured | Fail if missing |

---

## Retry Logic

If git push fails:

1. Wait 5 seconds
2. Retry push
3. Repeat up to 3 times
4. Log failure if all retries exhausted

---

## Schedule

Recommended: Twice daily for safety

```bash
crontab -e
```

```
0 2 * * * TZ='UTC' /home/user/backup-workspace.sh
0 14 * * * TZ='UTC' /home/user/backup-workspace.sh
```

---

## Verification

```bash
# Check pre-flight passed
grep "PREFLIGHT" ~/.openclaw/workspace/memory/backup.log | tail -5

# Check backup status
grep "BACKUP" ~/.openclaw/workspace/memory/backup.log | tail -5

# Check health
grep "HEALTH" ~/.openclaw/workspace/memory/backup.log | tail -5
```

---

## Recovery

Same as basic backup. The gitignore ensures sensitive files are never committed.

```bash
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git ~/.openclaw/workspace
```

---

**Status:** ✅ Active on this system
**Version:** v3 (Phoenix Shield + Update Plus)
