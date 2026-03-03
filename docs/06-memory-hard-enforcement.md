# Memory Hard Enforcement Plugin

**Added**: 2026-02-24
**Status**: ✅ Active
**Location**: Bundled with OpenClaw (`extensions/memory-hard-enforcement/`)

---

## Overview

The Memory Hard Enforcement plugin automatically injects relevant memories before every response — no LLM decision required. This transforms memory reliability from ~60-70% (soft enforcement, where the LLM must remember to call `memory_search`) to ~99% (automatic injection).

## Problem It Solves

**Soft Enforcement (Default):**
- LLM is instructed to use `memory_search` tool
- In practice, LLMs "forget" to call it when rushing
- ~60-70% reliability

**Hard Enforcement (This Plugin):**
- Hook intercepts before response generation
- Automatically queries memory
- Injects results as context
- ~99% reliability

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    HARD ENFORCEMENT FLOW                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  User message arrives                                               │
│         ↓                                                           │
│  before_prompt_build hook fires                                     │
│         ↓                                                           │
│  ┌─────────────────┐                                                │
│  │ enabled=false?  │──YES──→ Soft enforcement (LLM calls manually)  │
│  └────────┬────────┘                                                │
│           NO                                                        │
│           ↓                                                         │
│  ┌─────────────────┐                                                │
│  │ Skip pattern?   │──YES──→ Skip (short/greeting messages)         │
│  └────────┬────────┘                                                │
│           NO                                                        │
│           ↓                                                         │
│  ┌─────────────────┐                                                │
│  │ Memory search   │──TIMEOUT→ Log error, fallback to soft          │
│  │ (with timeout)  │──ERROR──→ Log error, fallback to soft          │
│  └────────┬────────┘                                                │
│           SUCCESS                                                   │
│           ↓                                                         │
│  ┌─────────────────┐                                                │
│  │ Results empty?  │──YES──→ No injection (transparent)             │
│  └────────┬────────┘                                                │
│           NO                                                        │
│           ↓                                                         │
│  Format & inject as prependContext                                  │
│  LLM sees memories BEFORE generating response                        │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Failsafe Design

The plugin is designed to **never break** the agent run:

1. **Configurable on/off** — `enabled: false` immediately disables
2. **All errors caught** — Logged, not thrown
3. **Timeout protection** — Falls back gracefully on slow searches
4. **Skip patterns** — Avoids unnecessary queries for "hi", "ok", etc.
5. **Empty results** — No injection, transparent to user

## Configuration

Add to `~/.openclaw/openclaw.json`:

```json
{
  "plugins": {
    "entries": {
      "memory-hard-enforcement": {
        "enabled": true,
        "config": {
          "maxResults": 5,
          "minScore": 0.3,
          "timeoutMs": 15000,
          "skipPatterns": [
            "^hi$", "^hey$", "^hello$", "^ok$", "^okay$",
            "^yes$", "^no$", "^thanks$", "^thank you$",
            "^danke$", "^bitte$", "^done$", "^\\?$"
          ],
          "maxQueryLength": 500
        }
      }
    }
  }
}
```

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `true` | Master on/off switch |
| `maxResults` | number | `5` | Maximum memories to inject |
| `minScore` | number | `0.3` | Minimum similarity score (0-1) |
| `timeoutMs` | number | `15000` | Timeout before fallback (15s for first model load) |
| `skipPatterns` | string[] | [...] | Regex patterns to skip |
| `maxQueryLength` | number | `500` | Truncate long queries |

## Controls

### CLI Commands

```bash
# Show current status
openclaw memory:hard-enforcement status

# Enable hard enforcement
openclaw memory:hard-enforcement enable

# Disable (use soft enforcement)
openclaw memory:hard-enforcement disable

# Toggle on/off
openclaw memory:hard-enforcement toggle
```

### Quick Command

```
/hme
```

Toggles hard enforcement on/off. Returns confirmation message.

## Example Output

When hard enforcement is active and finds relevant memories, you'll see:

```
## 🧠 Auto-Recalled Memory Context

The following relevant memories were automatically retrieved:

### 1. [57% match] `memory/2026-02-24-1548.md#L1-L12`

# Session: 2026-02-24 15:48:33 UTC
...

### 2. [53% match] `memory/2026-02-24-1323.md#L35-L45`
...

---

_Memory search was performed automatically. Cite sources when referencing this information._
```

## Technical Implementation

### Hook Used

- **Hook**: `before_prompt_build`
- **Priority**: 100 (high, runs early)
- **Return**: `{ prependContext: string }` or void

### Memory Search

Uses OpenClaw's native `createMemorySearchTool()` from the plugin runtime:

```typescript
const tool = api.runtime.tools.createMemorySearchTool({
  config: api.config,
  agentSessionKey: sessionKey,
});

const result = await tool.execute("hard-enforcement-auto", {
  query,
  maxResults,
  minScore,
});
```

### Source Location

Bundled with OpenClaw source:
```
/home/user/openclaw/extensions/memory-hard-enforcement/
├── index.ts              # Main implementation
├── openclaw.plugin.json  # Manifest + config schema
└── package.json          # Package definition
```

## Performance

| Metric | Value |
|--------|-------|
| First search (model load) | 5-10 seconds |
| Subsequent searches | < 500ms |
| Memory overhead | Minimal (uses existing embedding cache) |
| Timeout fallback | 15 seconds default |

## Comparison

| Approach | How It Works | Reliability |
|----------|--------------|-------------|
| **Soft** (default) | LLM must call `memory_search` | ~60-70% |
| **Hard** (this plugin) | Hook injects automatically | ~99% |

## Research Background

Based on patterns from:
- [qdrant-mcp-pi5](https://github.com/rockywuest/qdrant-mcp-pi5) — Hard enforcement concept
- OpenClaw plugin SDK — Native tool execution

Key insight: Making memory retrieval automatic rather than optional dramatically improves reliability.

## Troubleshooting

### Plugin Not Loading

```bash
# Check if enabled
openclaw memory:hard-enforcement status

# Verify config
cat ~/.openclaw/openclaw.json | jq '.plugins.entries."memory-hard-enforcement"'

# Restart gateway
systemctl --user restart openclaw-gateway
```

### Timeouts on First Search

First search loads the embedding model (~500MB). This can take 5-15 seconds on Pi 5.

**Solution**: Increase timeout:
```json
{
  "config": {
    "timeoutMs": 20000
  }
}
```

### No Memories Injected

Check:
1. Memory system is configured (`openclaw memory status`)
2. Files are indexed (`openclaw memory index`)
3. Query isn't matching skip patterns

```bash
# Verify memory system
openclaw memory status --deep

# Force re-index
openclaw memory index --force
```

---

**References:**
- [qdrant-mcp-pi5 assessment](./06-qdrant-mcp-pi5-assessment.md)
- OpenClaw Plugin SDK documentation
