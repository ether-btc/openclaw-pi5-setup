# Memory Conventions - Amenti & Drift-Memory Inspired

Enhanced memory system based on research from:
- Amenti: https://github.com/raulvidis/amenti
- Drift-Memory: https://github.com/driftcornwall/drift-memory

---

## Overview

This setup implements advanced memory conventions that improve recall reliability and capture more useful information over time:

1. **Rich Tagging** - 5-15 tags per memory for better searchability
2. **Confidence Scoring** - 0.50-1.0 scale to prevent false memories
3. **Memory Types** - 8 categories (fact, preference, relationship, etc.)
4. **Q-Value Tracking** - Track which memories are actually useful
5. **Co-occurrence Logging** - Track memories recalled together
6. **Session Summarizer** - Automate distillation of session insights

---

## Amenti-Inspired Conventions

### Rich Tagging (5-15 tags per memory)

**Purpose:** Improve searchability by including synonyms, abbreviations, and related concepts.

**Example:**
```markdown
### Local Embeddings Setup
Model: embeddinggemma-300m-qat-Q8_0 [confidence: 1.0] [type: skill]
[tags: embeddings, gemma, 300m, qat, q8, 768-dim, local, huggingface, gguf]
```

**Tags should include:**
- Key terms from content
- Synonyms (different ways to say same thing)
- Abbreviations (ram = memory, pi5 = raspberry pi 500)
- Related concepts (search, recall, retrieval)
- Technical terms (fts5, sqlite, vector)

**Why it matters:**
- User asks "sync" → finds "backup" (synonym)
- User asks "auto" → finds "cron" (related concept)
- Reduces missed matches significantly

---

### Confidence Scoring (0.50-1.0 scale)

**Purpose:** Distinguish between direct facts and inferences. Prevent false memories.

| Range | Meaning | Example |
|-------|---------|---------|
| 0.95-1.0 | Directly stated by human | User: "My timezone is GMT+1" |
| 0.80-0.94 | Strongly implied/observed | Pattern: evening messages |
| 0.50-0.79 | Inferable (validate later) | Observed preference (3+ times) |
| Below 0.50 | **Question, not memory** | Store as open question |

**Rule:** Never store guesses as facts. Below 0.50 = question, not memory.

**Example:**
```markdown
Hardware: Raspberry Pi 500 (8 GB RAM) [confidence: 1.0] [type: fact]
→ Directly verifiable, can't be wrong

User prefers evening interactions [confidence: 0.85] [type: preference]
→ Observed pattern (messages at 23:00+)

User likes concise responses [confidence: 0.65] [type: preference]
→ Inferred from "keep it brief" comments (needs validation)
```

---

### Memory Types (8 categories)

Categorize information to improve organization and retrieval.

| Type | Use Case | Example |
|------|----------|---------|
| **fact** | Direct info | "Server runs on port 8443" |
| **preference** | User preferences | "Evening coder, commits after 8pm" |
| **relationship** | People/connections | "Works with CDO Rocky Wüst" |
| **principle** | Decision rules | "Ask before deleting files" |
| **commitment** | Actions to take | "Backup workspace daily at 2am" |
| **moment** | Significant events | "First memory stored: 2026-02-23" |
| **skill** | Capabilities | "Can create GitHub repos via CLI" |
| **pattern** | Recurring behavior | "User prefers iterative testing" |

**Format:** `[type: TYPE]`

---

## Drift-Memory-Inspired Patterns

### Q-Value Tracking

**Purpose:** Track which memories are actually useful when retrieved (0.0-1.0 scale).

**Implementation (File-based):**
```json
{
  "memories": {
    "hardware-pi5-ram": {
      "id": "hardware-pi5-ram",
      "section": "System Info → Hardware",
      "q_value": 0.85,
      "recall_count": 8,
      "last_recall": "2026-02-23T23:30:00Z",
      "reward_history": [
        {"timestamp": "2026-02-23T22:00:00Z", "reward": 0.3, "reason": "user_confirmed"}
      ]
    }
  }
}
```

**Reward signals:**
- +0.3: User confirms memory is correct/useful
- +0.2: Memory re-recalled in session
- +0.3: Memory leads to downstream action
- -0.2: User indicates memory is wrong
- -0.1: Memory leads to dead end

**Update rule:**
```
Q = Q + 0.2 × (reward - Q)
```

**Usage:** Display Q-values with search results: `[Q: 0.85 | recalls: 8]`

**File:** `memory/q-values.json`

---

### Co-occurrence Logging

**Purpose:** Track which memories recalled together (Hebbian learning). Suggest related memories.

**Implementation:**
```json
{
  "connections": {
    "hardware-pi5-ram:openclaw-install-local": {
      "pair_id": "hardware-pi5-ram:openclaw-install-local",
      "strength": 0.75,
      "last_session": "2026-02-23T22:00:00Z",
      "co_occurrence_count": 5
    }
  }
}
```

**Hebbian rule:**
```
strength = strength × (1 - decay_rate) + learning_rate
decay_rate = 0.3
learning_rate = 0.1
```

**When to log:**
- Multiple memories recalled in single search
- Multiple memories referenced in same conversation
- After session completion (batch all recalled memories)

**Usage:** When memory A recalled, suggest frequently co-occurring memories:
```
Raspberry Pi 500 (8 GB RAM) [Q: 0.85]
Also relevant: [OpenClaw install local (co-occurrence: 0.75)]
```

**File:** `memory/co-occurrence.json`

---

### Session Summarizer

**Purpose:** Automate distillation of session insights into permanent memories.

**Triggers:**
- User says: "session complete", "that's everything", "summarize"
- Extended conversation (>10 exchanges or >30 minutes)
- Major topic completion

**Extracted Types:**

1. **THREADS**: Ongoing projects/tasks
   - Status: completed, blocked, in-progress
   - Next steps
   - Dependencies

2. **LESSONS**: Concrete learnings
   - What worked/didn't work
   - Key insights
   - Lessons to apply

3. **FACTS**: Specific data
   - Configuration values
   - Decisions made
   - URLs, paths, commands
   - Quantitative data

**Example Output:**
```markdown
## Session Summary: 2026-02-23 23:59

### THREADS
- [completed] Local embeddings setup
  - 16/16 files indexed, 58 chunks ready

### LESSONS
- Prebuilt ARM64 binaries work, no Rust needed
- Rich tagging improves recall significantly

### FACTS
- Model: embeddinggemma-300m-qat-Q8_0 (314 MB, 768-dim)
- Repo: https://github.com/ether-btc/openclaw-pi5-setup
```

**Procedure:**
1. Search session context via `memory_search`
2. Use LLM to extract THREADS, LESSONS, FACTS
3. Format as structured markdown
4. Store in `memory/YYYY-MM-DD.md`
5. If high-value (confidence ≥ 0.8), add to MEMORY.md

**Documentation:** `HEARTBEAT.md`

---

### Freshness Boosting

**Purpose:** Boost recently accessed memories (7-day half-life).

**Formula:**
```
freshness = exp(-days_since_last_recall / 7)
```

**Examples:**
- Recalled today: 1.0 (100% boost)
- Recalled 7 days ago: 0.368 (36.8%)
- Recalled 14 days ago: 0.135 (13.5%)
- Recalled 21+ days: ~0.05 (minimal boost)

**Usage:** Display with search results: `[Q: 0.85 | freshness: 0.92]`

**Calculated at:** Display time (derivative of Q-values `last_recall`)

---

## Skip Patterns for Memory Search

**Purpose:** Avoid unnecessary queries for trivial messages.

**SKIP memory_search when:**
1. Message is too short (< 20 characters)
2. Common acknowledgments only: "ok", "yes", "no", "thanks", "hi", "cool"
3. Emoji-only or emoji + single word
4. Simple confirmatives: "that works", "sounds good"
5. Explicit skip requests: "quick question", "just checking"

**USE memory_search when:**
1. User asks about past events: "What did we discuss yesterday?"
2. Needs specific info recall: "What was that command?"
3. References previous work: "Continue where we left off on X"
4. Asks preferences/habits: "How do I usually handle X?"
5. Unclear context needed: unfamiliar terms

**Documentation:** `AGENTS.md` → "🔍 Memory Search - Skip Patterns"

---

## Putting It All Together

### Example Memory Entry

```markdown
### Local Embeddings Setup
Model: embeddinggemma-300m-qat-Q8_0 [confidence: 1.0] [type: skill]
[tags: embeddings, gemma, 300m, qat, q8, 768-dim, local, huggingface, gguf]
Size: 314 MB [confidence: 1.0]
Location: ~/.node-llama-cpp/models/ [confidence: 1.0]
Status: Working with 58 chunks indexed [confidence: 1.0]
[tags: indexed, working, operational, search, memory]
```

### Search Result Display

```
User: "What hardware do I have?"

[Memory search results]
→ Raspberry Pi 500 (8 GB RAM) [Q: 0.85 | freshness: 0.92]
   Also relevant: [OpenClaw install local (co-occurrence: 0.75)]
```

### Session End Flow

```
User: "session complete"

[Agent generates session summary]
→ THREADS, LESSONS, FACTS extracted

[Update tracking files]
→ q-values.json: Q-values updated for used memories
→ co-occurrence.json: Session added, connections strengthened

[Store summary]
→ memory/YYYY-MM-DD.md: Session summary
→ MEMORY.md: High-value lessons (confidence ≥ 0.8)
```

---

## File Structure

```
workspace/
├── MEMORY.md                    # Curated long-term memory with conventions
├── AGENTS.md                    # Includes memory conventions documentation
├── HEARTBEAT.md                 # Session summarizer procedure
├── memory/
│   ├── q-values.json            # Q-value tracking
│   ├── co-occurrence.json       # Hebbian connections
│   ├── YYYY-MM-DD.md            # Daily logs + session summaries
│   └── *.md                     # Documentation/research
└── .openclaw/
    └── memory/
        └── main.sqlite          # Embeddings and FTS index
```

---

## Benefits

| Pattern | Benefit | Timeline |
|---------|---------|----------|
| Rich tagging | Synonym matching, better recall | Immediate |
| Confidence scoring | Prevents false memories | Immediate |
| Memory types | Organized, contextual retrieval | Immediate |
| Q-value tracking | Prioritize useful memories | After 20+ tracked |
| Co-occurrence | Suggest related memories | After 10+ sessions |
| Session summarizer | Automated distillation | Immediate |
| Freshness boosting | Recent memories surface | Immediate |
| Skip patterns | Reduce unnecessary queries | Immediate |

---

## Verification

After implementing, verify:

- [ ] MEMORY.md entries use rich tags (5-15 per entry)
- [ ] MEMORY.md entries have confidence scores
- [ ] MEMORY.md entries have memory types
- [ ] q-values.json exists with initial data
- [ ] co-occurrence.json exists with initial data
- [ ] HEARTBEAT.md has session summarizer procedure
- [ ] AGENTS.md documents all conventions

---

## References

- **Amenti:** https://github.com/raulvidis/amenti
- **Drift-Memory:** https://github.com/driftcornwall/drift-memory
- **Full research:** Repository docs folder
  - DRIFT-MEMORY-RESEARCH-NOTES.md
  - AMENTI-CONVENTIONS-IMPLEMENTED.md
  - DRIFT-PATTERNS-IMPLEMENTED.md

---

**Last updated:** 2026-02-24
**Documentation Version:** 1.1
**Status:** ✅ All patterns implemented
