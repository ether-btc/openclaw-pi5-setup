# Smart Monitor

Token-efficient subagent health monitoring that replaces wasteful cron polling with shell-based trigger activation.

---

## Problem: Wasteful Cron Polling

Traditional cron-based monitoring:
- Runs every N minutes regardless of activity
- Consumes tokens on every poll even when idle
- No context of what's happening in the session
- Wastes resources checking when not needed

---

## Solution: Shell-Based + Trigger Activation

Smart Monitor uses a push-based approach:

1. **Event-triggered**: Only runs when needed
2. **Shell-based**: No LLM involved in health checks
3. **Lightweight**: Simple shell scripts, minimal resource usage
4. **Token-efficient**: Only activates on specific triggers

---

## Scripts

### Main Script: `scripts/subagent-health.sh`

A lightweight shell script that checks:
- Gateway health (`/health` endpoint)
- Running subagent processes
- OpenClaw sessions
- Recent errors in logs

```bash
#!/bin/bash
# Subagent Health Check - Shell-based, no LLM

# Check gateway status
curl -s http://127.0.0.1:18789/health

# Check running subagents via process list
ps aux | grep -E "subagent|minimax|openclaw"

# Check session list
curl -s http://127.0.0.1:18789/api/sessions

# Check recent logs for errors
tail -20 ~/.openclaw/logs/gateway.log | grep -i "error"
```

---

## Activation

Smart Monitor starts automatically when project mode is activated:

```bash
./scripts/activate-project-mode.sh [project-name]
```

This spawns a lightweight background monitor:
```bash
nohup ~/.openclaw/workspace/scripts/subagent-health.sh > \
  ~/.openclaw/workspace/memory/subagent-health.log 2>&1 &
```

---

## Benefits

| Aspect | Cron (Old) | Smart Monitor (New) |
|--------|------------|---------------------|
| Resource usage | Constant | On-demand |
| Token cost | High (per poll) | Near-zero |
| Context aware | No | Yes |
| Trigger-based | No | Yes |
| LLM overhead | None | Minimal |

---

## Log Output

Health check results are written to:
- `~/.openclaw/workspace/memory/subagent-health.log`
- `~/.openclaw/workspace/memory/subagent-monitor.log`
