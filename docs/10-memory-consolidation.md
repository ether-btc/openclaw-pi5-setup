# Memory Consolidation

**Feature**: Detect and merge duplicate/similar memories

## Overview

Memory consolidation prevents bloat by detecting similar memories:
1. Uses vector similarity (>0.85 threshold)
2. Flags pairs for review
3. Logs merge decisions

This is a simplified version that doesn't require LLM - uses rule-based detection.

## Files

- `memory/consolidation.json` - Configuration
- `memory/consolidation-log.json` - Decision log
- `scripts/memory-consolidation.sh` - Management script

## Usage

```bash
# Check single memory for similar entries
memory-consolidation.sh check MEMORY.md

# Run full consolidation scan
memory-consolidation.sh run

# Log a manual merge
memory-consolidation.sh merge memory/old.md memory/new.md

# Show statistics
memory-consolidation.sh stats
```

## Merge Strategies

| Strategy | Description |
|----------|-------------|
| ADD | New, unique content - insert as new |
| MERGE | Similar, complementary - combine |
| UPDATE | Newer version - replace old |
| CONFLICT | Contradictory - flag for review |
| SKIP | Already covered - no action |

## Configuration

Edit `memory/consolidation.json`:

```json
{
  "enabled": true,
  "similarity_threshold": 0.85,
  "auto_consolidate": false
}
```

Note: `auto_consolidate` is OFF by default. Merge decisions require manual approval.

## Future Enhancement

With LLM available, can add automatic merge:
1. Send similar memories to LLM
2. Get merged content back
3. Update file automatically

Currently uses rule-based detection only.
