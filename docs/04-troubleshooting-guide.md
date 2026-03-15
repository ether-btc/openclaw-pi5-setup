# Troubleshooting Guide

Complete troubleshooting guide for OpenClaw on Raspberry Pi 500 with local embeddings.

---

## Memory System Issues

### Symptom: "Provider: none" in memory status

**Cause:** `memorySearch` configuration not set or not loaded

**Solutions:**

1. **Verify config exists:**
```bash
cat ~/.openclaw/openclaw.json | jq '.agents.defaults.memorySearch'
```

2. **Check config is valid JSON:**
```bash
jq . ~/.openclaw/openclaw.json
```

3. **Restart gateway:**
```bash
killall openclaw-gateway
# Auto-restarts
```

4. **Verify config loaded:**
```bash
openclaw memory status
```

---

### Symptom: "Model not found" (ENOENT)

**Cause:** Model not downloaded or path mismatch

**Solutions:**

1. **Check where model was downloaded:**
```bash
find ~/.node-llama-cpp -name "*.gguf"
```

2. **Verify cache directory:**
```bash
ls -la ~/.node-llama-cpp/models/
```

3. **Check expected path in config:**
```bash
cat ~/.openclaw/openclaw.json | jq '.agents.defaults.memorySearch.local.modelPath'
```

4. **Create symlink if in wrong location:**
```bash
mkdir -p ~/.node-llama-cpp/models/hf_ggml-org_embeddinggemma-300m-qat-q8_0-GGUF/
ln -s /path/to/ACTUAL_MODEL.gguf \
      ~/.node-llama-cpp/models/hf_ggml-org_embeddinggemma-300m-qat-q8_0-GGUF/embeddinggemma-300m-qat-Q8_0.gguf
```

---

### Symptom: "Indexed: 0/16 files · 0 chunks"

**Cause:** Files not indexed or watcher not triggered

**Solutions:**

1. **Trigger manual indexing:**
```bash
openclaw memory index --verbose
```

2. **Force watcher to trigger:**
```bash
touch ~/.openclaw/workspace/MEMORY.md
```

3. **Wait and check again:**
```bash
sleep 10
openclaw memory status
```

4. **Check if files exist:**
```bash
ls -la ~/.openclaw/workspace/
ls -la ~/.openclaw/workspace/memory/
```

---

### Symptom: Slow search responses

**Cause:** First search loads model; slow disk or network

**Solutions:**

1. **Check if model is in memory:**
```bash
# Process will show high memory after first search
ps aux | grep node
```

2. **Check disk performance:**
```bash
# Should be > 100 MB/s for proper performance
hdparm -Tt /dev/mmcblk0
```

3. **Check if SSD is installed (not SD card):**
```bash
lsblk
```

4. **Be patient on first search** - model loads once and stays cached

---

## Gateway Issues

### Symptom: Gateway won't start

**Cause:** Invalid config or dependency missing

**Solutions:**

1. **Check gateway logs:**
```bash
tail -100 ~/.openclaw/logs/gateway.log
```

2. **Verify JSON config:**
```bash
jq . ~/.openclaw/openclaw.json
```

3. **Check if gateway process is stuck:**
```bash
ps aux | grep openclaw-gateway
killall -9 openclaw-gateway
# Auto-restarts
```

4. **Start manually to see errors:**
```bash
openclaw gateway start --verbose
```

---

### Symptom: Gateway crashes repeatedly

**Cause:** Out of memory or configuration error

**Solutions:**

1. **Check available RAM:**
```bash
free -h
```

2. **Check memory usage:**
```bash
ps aux | sort -rk4 | head -10
```

3. **Disable plugins temporarily:**
```bash
# Edit config, set "enabled": false for plugins, restart
```

4. **Reduce embedding cache:**
```json
{
  "agents": {
    "defaults": {
      "memorySearch": {
        "cache": {
          "maxEntries": 10000
        }
      }
    }
  }
}
```

---

### Symptom: Slow response times

**Cause:** High CPU usage from embeddings or indexing

**Solutions:**

1. **Check CPU usage:**
```bash
top
# Look for high CPU from node processes
```

2. **Disable watch temporarily:**
```json
{
  "agents": {
    "defaults": {
      "memorySearch": {
        "sync": {
          "watch": false
        }
      }
    }
  }
}
```

3. **Reduce indexing frequency:**
```json
{
  "agents": {
    "defaults": {
      "memorySearch": {
        "sync": {
          "interval": "1h"
        }
      }
    }
  }
}
```

---

## Backup Issues

### Symptom: Backup script not running via cron

**Cause:** Cron not running or job not scheduled

**Solutions:**

1. **Check cron service:**
```bash
systemctl status cron
ps aux | grep cron
```

2. **Check if job exists:**
```bash
crontab -l | grep backup
```

3. **Check cron activity:**
```bash
grep CRON /var/log/syslog | tail -20
```

4. **Test script manually:**
```bash
~/backup-workspace.sh
tail -10 ~/.openclaw/workspace/memory/backup.log
```

---

### Symptom: Git push fails with "Authentication required"

**Cause:** Needs personal access token or SSH key

**Solutions:**

1. **Create personal access token:**
   - Go to GitHub: Settings → Developer settings → Personal access tokens
   - Generate token with `repo` scope
   - Copy token

2. **Update remote URL with token:**
```bash
git remote set-url origin https://TOKEN@github.com/YOUR_USERNAME/YOUR_REPO.git
```

3. **Test push:**
```bash
cd ~/.openclaw/workspace
echo "test" >> test.txt
git add test.txt
git commit -m "test"
git push origin master
```

---

### Symptom: "Permission denied (publickey)" when pushing

**Cause:** SSH key not configured

**Solutions:**

1. **Generate SSH key:**
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

2. **Copy public key:**
```bash
cat ~/.ssh/id_ed25519.pub
```

3. **Add to GitHub:**
   - Go to: Settings → SSH and GPG keys → New SSH key
   - Paste public key

4. **Update remote to use SSH:**
```bash
git remote set-url origin git@github.com:YOUR_USERNAME/YOUR_REPO.git
```

---

## Plugin Issues

### Symptom: Plugin not loading

**Cause:** Path incorrect or plugin disabled

**Solutions:**

1. **Verify plugin paths exist:**
```bash
ls -la ~/.openclaw-plugins/openclaw-metacognitive-suite/plugins/
```

2. **Check config syntax:**
```bash
jq . ~/.openclaw/openclaw.json | grep -A10 plugins
```

3. **Check logs for errors:**
```bash
grep -i plugin ~/.openclaw/logs/gateway.log | tail -20
```

4. **Verify plugin is enabled:**
```bash
jq '.plugins.entries' ~/.openclaw/openclaw.json
```

---

### Symptom: Continuity database errors

**Cause:** Database corruption or disk full

**Solutions:**

1. **Check disk space:**
```bash
df -h ~/.openclaw/
```

2. **Verify database exists:**
```bash
ls -lh ~/.openclaw/continuity/data/continuity.db
```

3. **Check database integrity:**
```bash
sqlite3 ~/.openclaw/continuity/data/continuity.db "PRAGMA integrity_check;"
```

4. **If corrupted, delete and let plugin recreate:**
```bash
rm ~/.openclaw/continuity/data/continuity.db
# Restart gateway - database will be recreated
```

---

### Symptom: High memory usage from plugins

**Cause:** Continuity embeddings accumulate

**Solutions:**

1. **Check database size:**
```bash
du -sh ~/.openclaw/continuity/data/
```

2. **Configure message retention:**
```json
{
  "continuity": {
    "maxArchivedMessages": 10000,
    "cleanupAfterDays": 90
  }
}
```

3. **Disable plugin temporarily:**
```json
{
  "plugins": {
    "entries": {
      "continuity": { "enabled": false }
    }
  }
}
```

---

## System Resource Issues

### Symptom: Out of memory errors

**Cause:** Too many processes or large model loaded

**Solutions:**

1. **Check memory usage:**
```bash
free -h
ps aux | sort -rk4 | head -10
```

2. **Check swap:**
```bash
swapon --show
free -h | grep Swap
```

3. **Add swap if needed:**
```bash
# 2GB swap file
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

4. **Reduce embedding cache:**
```json
{
  "agents": {
    "defaults": {
      "memorySearch": {
        "cache": {
          "maxEntries": 5000
        }
      }
    }
  }
}
```

---

### Symptom: Disk space running low

**Cause:** Logs, databases, or cache growing

**Solutions:**

1. **Check disk usage:**
```bash
du -sh ~/.openclaw/*
du -sh ~/.node-llama-cpp/*
```

2. **Clean old logs:**
```bash
find ~/.openclaw/logs -name "*.log" -mtime +30 -delete
```

3. **Clean continuity database (archived messages):**
```json
{
  "continuity": {
    "cleanupAfterDays": 30,
    "maxArchivedMessages": 5000
  }
}
```

4. **Rotate git history (if needed):**
```bash
cd ~/.openclaw/workspace
git gc --aggressive --prune=now
```

---

## Network Issues

### Symptom: Model download fails

**Cause:** HuggingFace unreachable or connection issues

**Solutions:**

1. **Check HuggingFace connectivity:**
```bash
curl -I https://huggingface.co
```

2. **Check DNS resolution:**
```bash
nslookup huggingface.co
```

3. **Check firewall rules:**
```bash
sudo iptables -L -n
```

4. **Try manual download:**
```bash
mkdir -p ~/.node-llama-cpp/models/hf_ggml-org_embeddinggemma-300m-qat-q8_0-GGUF/
cd ~/.node-llama-cpp/models/hf_ggml-org_embeddinggemma-300m-qat-q8_0-GGUF/
wget https://huggingface.co/ggml-org/embeddinggemma-300m-qat-q8_0-GGUF/resolve/main/embeddinggemma-300m-qat-Q8_0.gguf
```

---

## Diagnostic Commands

### Full System Check

Run this script to diagnose issues:

```bash
#!/bin/bash
echo "=== OpenClaw Diagnostic ==="
echo ""
echo "1. System Info:"
echo "Arch: $(uname -m)"
echo "RAM: $(free -h | awk '/^Mem:/{print $2}')"
echo "Disk: $(df -h ~ | awk 'NR==2 {print $4 " free"}')"
echo ""
echo "2. OpenClaw Status:"
openclaw --version
echo ""
echo "3. Gateway Process:"
ps aux | grep openclaw-gateway | grep -v grep || echo "Gateway not running"
echo ""
echo "4. Memory Status:"
openclaw memory status
echo ""
echo "5. Config Valid:"
jq . ~/.openclaw/openclaw.json > /dev/null && echo "✅ Valid JSON" || echo "❌ Invalid JSON"
echo ""
echo "6. Plugin Status:"
ls ~/.openclaw-plugins/openclaw-metacognitive-suite/plugins/ 2>/dev/null || echo "No plugins"
echo ""
echo "7. Disk Usage:"
du -sh ~/.openclaw/ ~/.node-llama-cpp/ ~/.openclaw/workspace/
echo ""
echo "8. Recent Errors:"
grep -i error ~/.openclaw/logs/gateway.log | tail -5
```

---

## Getting Help

If issues persist:

1. **Check logs:**
```bash
tail -100 ~/.openclaw/logs/gateway.log
tail -100 ~/.openclaw/logs/*.log
```

2. **System logs:**
```bash
tail -100 /var/log/syslog
```

3. **Resources:**
- OpenClaw docs: https://docs.openclaw.ai
- OpenClaw Discord: https://discord.com/invite/clawd
- GitHub issues: https://github.com/openclaw/openclaw/issues

---

**Last updated:** 2026-02-23
**Platform:** Raspberry Pi 500 (8GB RAM)
**OpenClaw version:** 2026.3.3
