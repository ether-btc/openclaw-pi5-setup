# Metacognitive Suite Installation Guide

**Purpose:** Enhanced memory, stability, and knowledge graph for OpenClaw agents

---

## Overview

The metacognitive suite provides autonomous learning loops:

| Plugin | Function | Data |
|--------|----------|------|
| **Stability** | Entropy monitoring, drift detection, growth vectors | JSON state files |
| **Continuity** | Cross-session memory, semantic search, archiving | SQLite + embeddings |
| **Graph** | Entity extraction, relationships, knowledge graph | SQLite triples |

**Note:** This setup installs 3 plugins WITHOUT autonomous behavior modification.

---

## What Was NOT Installed (Intentional)

- **Metabolism** - Autonomous gap extraction and processing
- **Nightshift** - Off-hours task scheduling
- **Contemplation** - Multi-pass reflective inquiry over 24h
- **Crystallization** - Growth vector → permanent trait conversion

**Result:** Enhanced memory and knowledge structure WITHOUT autonomous learning or behavior modification.

---

## Installation

### Step 1: Clone Repository

```bash
cd ~/.openclaw-plugins
git clone https://github.com/CoderofTheWest/openclaw-metacognitive-suite.git
```

### Step 2: Backup Configuration

```bash
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.backup-pre-metacognitive
```

### Step 3: Add to Configuration

Add to `~/.openclaw/openclaw.json`:

```json
{
  "plugins": {
    "load": {
      "paths": [
        "/home/user/.openclaw-plugins/openclaw-metacognitive-suite/plugins/openclaw-plugin-stability",
        "/home/user/.openclaw-plugins/openclaw-metacognitive-suite/plugins/openclaw-plugin-continuity",
        "/home/user/.openclaw-plugins/openclaw-metacognitive-suite/plugins/openclaw-plugin-graph"
      ]
    },
    "entries": {
      "stability": {
        "enabled": true
      },
      "continuity": {
        "enabled": true
      },
      "graph": {
        "enabled": true
      }
    }
  }
}
```

### Step 4: Restart Gateway

```bash
# Kill gateway - it will auto-restart with new config
killall openclaw-gateway

# Or use OpenClaw CLI
openclaw gateway restart
```

### Step 5: Verify Installation

```bash
# Check plugin messages in gateway logs
tail -50 ~/.openclaw/logs/gateway.log | grep -i plugin

# Check agent context includes plugin data
# Stability: Look for "Entropy:" in message headers
# Continuity: Look for "CONTINUITY CONTEXT" in message headers
# Graph: Look for entity extraction logs
```

---

## Plugin Details

### 1. Stability Plugin

**Purpose:** Detect and track conversation quality

**Capabilities:**
- Entropy monitoring (detect chaos/drift)
- Growth vector tracking
- Repetitive loop detection
- Confabulation pattern detection
- Decision framework for heartbeat responses

**Data Structure:**
- `stability/data/` - JSON state files
- Entropy history over time
- Growth vector records

**Hooks:**
- `before_agent_start` - Initialize session state
- `agent_end` - Track session outcomes
- `after_tool_call` - Monitor tool usage patterns
- `before_compaction` - Preserve critical context

**Impact:**
- Minimal RAM overhead (< 10 MB)
- Disk: Grows slowly with usage
- CPU: Negligible

---

### 2. Continuity Plugin

**Purpose:** Cross-session memory and semantic search

**Capabilities:**
- Archives conversations to SQLite
- Creates vector embeddings for semantic search
- Context budgeting for relevant past context injection
- Topics tracking and continuity anchor detection
- Identity and contradiction tracking

**Data Structure:**
- `continuity/data/continuity.db` - SQLite with sqlite-vec
- Tables: messages, embeddings, topics, anchors
- Stores full conversation transcripts with embeddings

**Dependencies:**
- `better-sqlite3` - SQLite database
- `sqlite-vec` - Vector similarity search
- `@chroma-core/default-embed` - Embeddings

**Hooks:**
- `before_agent_start` - Initialize session, load relevant context
- `agent_end` - Archive session with embeddings
- `session_end` - Finalize archive

**Impact:**
- RAM: ~50-100 MB during heavy operations
- Disk: Grows with conversation history
- CPU: Moderate during embedding and search

**Performance:**
- Archive creation: ~1 second per 1-minute conversation
- Semantic search: < 500ms for typical queries
- Context injection: < 100ms

---

### 3. Graph Plugin

**Purpose:** Knowledge graph with entities and relationships

**Capabilities:**
- Extract entities (people, places, things)
- Build relationship triples (entity → predicate → entity)
- Multi-hop traversal for context retrieval
- Pattern discovery for recurring relationships

**Data Structure:**
- `graph/data/graph.db` - SQLite database
- Tables: triples, entities, cooccurrences, meta_patterns
- Stores entities, relationships, and patterns

**Dependencies:**
- `better-sqlite3` - SQLite database
- `compromise` - NLP entity extraction

**Hooks:**
- `before_agent_start` - Initialize graph
- `agent_end` - Extract entities and relationships
- `session_end` - Finalize graph updates
- `heartbeat` - Periodic pattern analysis

**Impact:**
- RAM: ~20-50 MB
- Disk: Grows with entity/relationship count
- CPU: Moderate during entity extraction

**Performance:**
- Entity extraction: < 200ms per message
- Graph traversal: < 100ms for 2-3 hops
- Pattern discovery: Runs in background

---

## System Impact Summary

| Resource | Stability | Continuity | Graph | Total |
|----------|-----------|------------|-------|-------|
| RAM (idle) | < 10 MB | ~30 MB | ~20 MB | ~60 MB |
| RAM (active) | < 10 MB | ~100 MB | ~50 MB | ~160 MB |
| Disk (initial) | ~1 MB | ~15 MB | ~2 MB | ~18 MB |
| Disk (growth) | Slow | Medium | Slow | Medium |
| CPU (peak) | Negligible | Moderate | Moderate | Moderate |

**Total with local embeddings:**
- RAM: ~500 MB (embeddings) + ~60 MB (plugins) = ~560 MB
- Disk: ~314 MB (model) + ~18 MB (plugins) = ~332 MB

**On Pi 5 (8 GB RAM):** Plenty of headroom

---

## Data Privacy

### What Is Processed

- All conversations for entity extraction
- All conversations for continuity archiving
- All conversations for entropy analysis

### What Is Stored Locally

- Full conversation transcripts
- Vector embeddings
- Entity/relationship triples
- Entropy state history

### Remote Usage

- No external APIs used (except embedding model download)
- No data sent to remote services
- Fully offline after initial setup

---

## Verification

### Check Plugin Status

```bash
# Stability check
tail -50 ~/.openclaw/logs/gateway.log | grep -i stability

# Continuity check
tail -50 ~/.openclaw/logs/gateway-debu-*.log | grep -i continuity

# Graph check
tail -50 ~/.openclaw/logs/gateway-debu-*.log | grep -i graph
```

### Check Agent Context

Look for these in message headers:

**Stability:**
```
[STABILITY CONTEXT]
Entropy: 0.00 (nominal)
Principles: integrity, reliability, coherence
```

**Continuity:**
```
[CONTINUITY CONTEXT]
Session: 5 exchanges | Started: 26min ago
Topics: memory (active), backup (active)
```

**Graph:**
(Not directly visible in headers, data stored in graph.db)

### Check Database Files

```bash
# Continuity database
ls -lh ~/.openclaw/continuity/data/continuity.db

# Graph database
ls -lh ~/.openclaw/graph/data/graph.db

# Stability data
ls -lh ~/.openclaw/stability/data/

# SQLite query to verify structure
sqlite3 ~/.openclaw/continuity/data/continuity.db ".schema"
sqlite3 ~/.openclaw/graph/data/graph.db ".schema"
```

---

## Rollback Procedure

If you need to remove the metacognitive suite:

```bash
# 1. Stop gateway
killall openclaw-gateway

# 2. Restore backup config
cp ~/.openclaw/openclaw.json.backup-pre-metacognitive ~/.openclaw/openclaw.json

# 3. Remove plugin directory (optional)
rm -rf ~/.openclaw-plugins/openclaw-metacognitive-suite

# 4. Remove plugin data (optional)
rm -rf ~/.openclaw/continuity/
rm -rf ~/.openclaw/graph/
rm -rf ~/.openclaw/stability/

# 5. Restart gateway
# (will auto-restart or manually: openclaw gateway start)
```

---

## Advanced Configuration

### Disable Individual Plugins

Set `enabled: false` in `openclaw.json`:

```json
{
  "plugins": {
    "entries": {
      "stability": { "enabled": false },
      "continuity": { "enabled": true },
      "graph": { "enabled": true }
    }
  }
}
```

### Configure Continuity Context Budgeting

Add to agent configuration:

```json
{
  "continuity": {
    "maxContextMessages": 50,
    "minRelevanceScore": 0.3,
    "contextBudget": 5000
  }
}
```

### Configure Graph Extraction

Add to agent configuration:

```json
{
  "graph": {
    "minEntityConfidence": 0.6,
    "storeRelationships": true,
    "maxHops": 3
  }
}
```

---

## Troubleshooting

### Plugin Not Loading

**Check:**
```bash
# Verify plugin paths exist
ls -la /home/user/.openclaw-plugins/openclaw-metacognitive-suite/plugins/

# Check config syntax
jq . ~/.openclaw/openclaw.json | grep -A5 plugins

# Check gateway logs
tail -100 ~/.openclaw/logs/gateway.log | grep -i error
```

### Continuity Database Errors

**Check:**
```bash
# Verify SQLite is accessible
sqlite3 ~/.openclaw/continuity/data/continuity.db ".tables"

# Check disk space
df -h ~/.openclaw/

# Check permissions
ls -la ~/.openclaw/continuity/data/
```

### Graph Performance Issues

**Optimize:**
- Reduce entity extraction frequency
- Limit relationship storage
- Increase `minEntityConfidence`

```json
{
  "graph": {
    "minEntityConfidence": 0.8,
    "storeRelationships": false,
    "extractionInterval": 10
  }
}
```

---

## Resources

- **Repository:** https://github.com/CoderofTheWest/openclaw-metacognitive-suite
- **Documentation:** Read plugin-specific docs in the repository
- **Issues:** Report bugs at the GitHub repository

---

**Status:** ✅ Active (Stability + Continuity + Graph)
**Installation Date:** 2026-02-23
**Config Backup:** ~/.openclaw/openclaw.json.backup-pre-metacognitive
