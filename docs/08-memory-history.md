# Memory History & Audit Trail

**Feature**: Track all memory mutations for debugging and rollback

## Overview

Memory history tracks every change to your memory system:
- Memory additions
- Updates
- Deletions
- Merges (future)
- Decay operations
- Recall events

This provides an audit trail similar to Mem0's history store.

## Files

- `memory/memory-history.json` - Mutation log
- `scripts/memory-history.sh` - Management script

## Usage

```bash
# Record a mutation (automatic via plugin)
memory-history.sh record add "memory/notes.md" "Initial note"

# Query history
memory-history.sh query

# Show statistics
memory-history.sh stats

# Cleanup old entries (>90 days)
memory-history.sh cleanup
```

## Integration

The hard enforcement plugin (v1.6.0+) automatically records:
- Memory retrievals (recalls)
- Search results count

## Configuration

Edit `memory/memory-history.json`:

```json
{
  "config": {
    "max_entries": 10000,
    "cleanup_after_days": 90
  }
}
```

## Heartbeat

Memory history cleanup runs automatically via heartbeat (item #15).
