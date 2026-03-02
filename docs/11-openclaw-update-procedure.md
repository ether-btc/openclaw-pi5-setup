# OpenClaw Update Best Practices

## The Failsafe Update Procedure

**Always follow this sequence:**

### Step 1: Preview (Dry Run)
```bash
openclaw update --dry-run
```

### Step 2: Backup Config
```bash
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.backup-$(date +%Y%m%d-%H%M%S)
```

### Step 3: Update (No Restart)
```bash
openclaw update --no-restart
```
- Updates code but keeps gateway running
- Lets you verify before going live

### Step 4: Verify
```bash
openclaw doctor --non-interactive
```

### Step 5: Restart (When Ready)
```bash
openclaw gateway restart
```

## Key Flags

| Flag | Purpose |
|------|---------|
| `--dry-run` | Preview without changes |
| `--no-restart` | Update but don't restart |
| `--yes` | Non-interactive (auto-confirm) |
| `--channel stable\|beta\|dev` | Switch update channel |

## Important Notes

1. **Skip if dirty**: OpenClaw refuses to update if there are uncommitted changes
   - Solution: Move untracked files or commit changes first

2. **Downgrades require confirmation**: OpenClaw warns you if downgrading

3. **Check channel first**:
   ```bash
   openclaw update status
   ```

## Troubleshooting

### "Working directory has uncommitted changes"
```bash
# Move untracked files out temporarily
mv some-folder /tmp/
openclaw update --no-restart
mv /tmp/some-folder ./
```

### Gateway won't restart
```bash
# Check logs
openclaw logs --lines 50

# Or manual restart
openclaw gateway stop
openclaw gateway start
```

## Rollback

If update breaks things:
```bash
# Find backup
ls -t ~/.openclaw/openclaw.json.backup-* | head -1

# Restore
cp ~/.openclaw/openclaw.json.backup-YYYYMMDD-HHMMSS ~/.openclaw/openclaw.json
openclaw gateway restart
```

---

*Procedure verified: 2026-03-02 (OpenClaw 2026.2.27 → 2026.3.2)*
