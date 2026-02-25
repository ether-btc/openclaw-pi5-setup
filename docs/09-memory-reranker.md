# Memory Reranker

**Feature**: Post-retrieval ranking to improve result quality

## Overview

The reranker boosts memory search results based on multiple signals:
- **Importance score** - From importance-scoring.json
- **Recency** - Newer memories get boosted
- **Anchor matches** - Query matches anchor vocabulary

This improves retrieval quality beyond raw vector similarity.

## Files

- `scripts/memory-rerank.sh` - Reranking script
- `scripts/hybrid-search-reranked.sh` - Combined search + rerank

## Usage

```bash
# Rerank a result file
memory-rerank.sh rerank "query" results.txt

# Test reranker
memory-rerank.sh test

# Use combined search
hybrid-search-reranked.sh "search query"
```

## How It Works

```
Final Score = Original Similarity × Importance × Recency × Anchor

Where:
- Importance: 1.0 + importance_score (from importance-scoring.json)
- Recency: 1.5 (today), 1.3 (3 days), 1.0 (week), 0.8 (month+)
- Anchor: 1.3 if query/path matches anchor vocabulary, else 1.0
```

## Integration

The reranker is available as:
1. Standalone script for ad-hoc queries
2. Integrated into `hybrid-search-reranked.sh`

## Example Output

```
Original: 0.659 → Reranked: 0.989 (imp:1.0 rec:1.5 anc:1.0)
```

This shows MEMORY.md gets boosted because it's recently modified (recency boost).
