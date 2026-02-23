# Automatic Backup System - Complete Guide

**Purpose:** Git-based incremental daily backups for OpenClaw workspace

---

## Overview

Automated backup system that runs daily at 2 AM CET:

- **Incremental by design** - Only changed files uploaded
- **Git-based** - Full commit history preserved
- **Zero maintenance** - Runs silently, logs everything
- **Full recovery** - Rebuild from scratch after system failure

---

## Architecture

```
Daily at 2am CET → Check for changes → Git commit → Push to GitHub
                           ↓
                   No changes → Exit quietly (logged to backup.log)
```

---

## Implementation

### Backup Script

Create `~/backup-workspace.sh`:

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

---

## Cron Configuration

### Add to Crontab

```bash
crontab -e
```

**Add this line:**
```
0 2 * * * TZ='Europe/Berlin' /home/pi/backup-workspace.sh
```

### Cron Schedule Explanation

| Field | Value | Meaning |
|-------|-------|---------|
| Minute | 0 | At the top of the hour |
| Hour | 2 | 2 AM |
| Day of month | * | Every day |
| Month | * | Every month |
| Day of week | * | Every day of week |
| TZ | Europe/Berlin | Use CET/CEST timezone |

---

## What's Backed Up

All workspace files tracked by git:

- `memory/` - All documentation and daily notes
- `SOUL.md` - Agent identity and preferences
- `USER.md` - User profile and context
- `IDENTITY.md` - Agent configuration
- `TOOLS.md` - Environment-specific notes
- `AGENTS.md` - Workspace conventions
- Any custom files you add

### What's NOT Backed Up

- OpenClaw configuration (`.openclaw/` - contains API keys)
- Plugin data (`continuity/data/`, `graph/data/`, `stability/data/`)
- System logs

**Tip:** Store these in a separate, private backup repository if needed.

---

## Verification

### Check Crontab

```bash
crontab -l
```

**Expected output:**
```
0 2 * * * TZ='Europe/Berlin' /home/pi/backup-workspace.sh
```

### Check Last Backup

```bash
tail -20 ~/.openclaw/workspace/memory/backup.log
```

**Expected output:**
```
[2026-02-23 22:03:43] Starting workspace backup...
[2026-02-23 22:03:43] Backup successful.
[2026-02-24 02:00:01] Starting workspace backup...
[2026-02-24 02:00:03] No changes to commit.
```

### Check Git History

```bash
cd ~/.openclaw/workspace
git log --oneline -10
```

### Check Cron Activity

```bash
grep CRON /var/log/syslog | tail -10
```

---

## Manual Backup

Run anytime to force immediate backup:

```bash
~/backup-workspace.sh
```

Or use git directly:

```bash
cd ~/.openclaw/workspace
git add -A
git commit -m "Manual backup: $(date)"
git push origin master
```

---

## GitHub Repository Setup

### Initial Setup (One-time)

```bash
# Create new repository on GitHub first
# Then:

cd ~/.openclaw/workspace
git init
git add -A
git commit -m "Initial backup setup"
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -u origin master
```

### Using Personal Access Token

If password authentication fails:

1. Go to GitHub → Settings → Developer settings → Personal access tokens
2. Generate new token with `repo` scope
3. Configure git to use it:

```bash
git remote set-url origin https://TOKEN@github.com/YOUR_USERNAME/YOUR_REPO.git
```

---

## Recovery After Crash

### On Fresh System:

```bash
# 1. Install OpenClaw
npm install -g openclaw

# 2. Configure OpenClaw
openclaw configure

# 3. Clone workspace
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git ~/.openclaw/workspace

# 4. Agent has full memory from all files
```

### What Is Recovered

- All documentation (`memory/*.md`)
- Agent identity (`SOUL.md`, `IDENTITY.md`)
- User preferences (`USER.md`)
- Configuration notes (`TOOLS.md`, `AGENTS.md`)
- Daily notes and conversations

### What Is NOT Recovered

- API keys and credentials (need to re-enter)
- Plugin databases (will rebuild on first run)
- System logs

---

## Troubleshooting

### Backup Not Running

**Check cron service:**
```bash
systemctl status cron
ps aux | grep cron
```

**Check crontab:**
```bash
crontab -l | grep backup
```

**Test manually:**
```bash
~/backup-workspace.sh
tail -5 ~/.openclaw/workspace/memory/backup.log
```

### Push Fails with Authentication Required

**Cause:** Needs personal access token or SSH key

**Fix:**
```bash
# Use token
git remote set-url origin https://TOKEN@github.com/YOUR_USERNAME/YOUR_REPO.git

# Or set up SSH keys
ssh-keygen -t ed25519 -C "your_email@example.com"
# Add to GitHub: Settings → SSH and GPG keys → New SSH key
git remote set-url origin git@github.com:YOUR_USERNAME/YOUR_REPO.git
```

### Push Fails with Permission Denied

**Check:**
- You have write access to the repo
- Repo is not read-only
- Token has `repo` scope

### Repository Not Found

**Check:**
- URL is correct
- Repository exists
- You have access

### Script Permission Denied

**Fix:**
```bash
chmod +x ~/backup-workspace.sh
```

---

## Storage Impact

### Disk Usage

- Git repo: ~5 MB (text-heavy workspace)
- Daily commits: Minimal (incremental)
- GitHub free tier: More than sufficient

### Network Usage

- Only changed files transmitted
- Typical daily change: < 1 MB
- Initial commit: ~5 MB

---

## Advanced Configuration

### More Frequent Backups

Every 6 hours:

```
0 */6 * * * TZ='Europe/Berlin' /home/pi/backup-workspace.sh
```

Every 2 hours:

```
0 */2 * * * TZ='Europe/Berlin' /home/pi/backup-workspace.sh
```

### Multiple Repositories

Backup workspace and config separately:

```bash
# Workspace docs (public repo)
echo "0 2 * * * TZ='Europe/Berlin' ~/backup-workspace.sh" >> /tmp/cronfile

# Config (private repo)
cat >> ~/backup-config.sh << 'EOF'
#!/bin/bash
cd ~/.openclaw
git add -A
git commit -m "Auto-backup config: $(date)"
git push origin master
EOF
chmod +x ~/backup-config.sh
echo "0 2 * * * TZ='Europe/Berlin' ~/backup-config.sh" >> /tmp/cronfile

crontab /tmp/cronfile
```

---

**Status:** ✅ Active and tested
**Schedule:** Daily at 2 AM CET
**Location:** ~/.openclaw/workspace/memory/backup.log
