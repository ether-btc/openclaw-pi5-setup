# Assessment: qdrant-mcp-pi5

**Source**: https://github.com/rockywuest/qdrant-mcp-pi5
**Date**: 2026-02-24
**Purpose**: Identify improvements for local embeddings and memory architecture

---

## Executive Summary

The qdrant-mcp-pi5 repo offers several innovations. The key learnings applied:

- **Hard enforcement plugin** — Implemented in OpenClaw core
- **Hybrid memory architecture** — Concept documented for future
- **Stateless design** — Not needed (OpenClaw has native memory manager)

---

## Current OpenClaw Setup vs qdrant-mcp-pi5

| Component | OpenClaw (Current) | qdrant-mcp-pi5 |
|-----------|-------------------|----------------|
| **Provider** | Native `memorySearch.provider: local` | Qdrant MCP Server |
| **Model** | `embeddinggemma-300m-qat-Q8_0` (300M params) | `all-MiniLM-L6-v2` (22M params) |
| **Dimensions** | ~768 | 384 |
| **Storage** | SQLite + sqlite-vec | Qdrant (SQLite-backed) |
| **Enforcement** | Hard (plugin) | Hard (plugin) |
| **Bridge** | None needed | mcporter |

### Model Comparison

OpenClaw's model is **more capable**:
- 300M parameters vs 22M parameters
- 768 dimensions vs 384 dimensions
- Similar performance characteristics on Pi 500

---

## Key Innovations from qdrant-mcp-pi5

### 1. Hard Enforcement Plugin ✅ Implemented

**Problem**: LLMs "forget" to query memory when rushing to answer.

**Solution**: A plugin that:
- Hooks `before_prompt_build` (OpenClaw) / `before_agent_start` (theirs)
- Extracts user query
- Calls memory search automatically
- Injects results as `prependContext`

**Result**: 99% reliability vs 60-70% for soft enforcement.

### 2. Hybrid Memory Architecture 📋 Documented for Future

**Concept**: Two complementary memory systems:

| System | Good For | Example Query |
|--------|----------|---------------|
| Qdrant (semantic) | Facts, entities | "Who is Martin Grieß?" |
| drift-memory (behavioral) | Patterns, preferences | "What communication style works best?" |

**Implementation**: Could pair OpenClaw's semantic memory with [drift-memory](https://github.com/driftcornwall/drift-memory) for behavioral pattern tracking.

**Status**: Documented, not yet implemented.

### 3. Stateless MCP Server ⚠️ Not Needed

Their approach: Server spawns per-call, exits after work.

OpenClaw approach: Native memory manager with lazy loading and caching.

Both achieve similar RAM efficiency. No change needed.

---

## What Was Implemented

### Memory Hard Enforcement Plugin

**Location**: `/home/user/openclaw/extensions/memory-hard-enforcement/`

**Features**:
- Auto-injects memories before every response
- Configurable on/off switch
- Timeout protection with graceful fallback
- Skip patterns for short messages
- Uses OpenClaw's native `memory_search` tool

**Documentation**: See [06-memory-hard-enforcement.md](./06-memory-hard-enforcement.md)

---

## What Was NOT Implemented

| Feature | Reason |
|---------|--------|
| Switching to Qdrant | Native setup is simpler and working |
| Installing mcporter | Adds complexity without benefit |
| Switching embedding model | Current model is more capable |
| drift-memory integration | Requires separate assessment |

---

## References

- [qdrant-mcp-pi5](https://github.com/rockywuest/qdrant-mcp-pi5) — Source repo
- [drift-memory](https://github.com/driftcornwall/drift-memory) — Behavioral memory system
- [mcporter](https://github.com/steipete/mcporter) — MCP client/bridge
- [all-MiniLM-L6-v2](https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2) — Their embedding model
