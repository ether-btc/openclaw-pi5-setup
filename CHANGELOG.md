# Changelog

## 2026-02-24

### Added

- **Memory Hard Enforcement Plugin** — Auto-injects relevant memories before every response
  - Bundled with OpenClaw (`extensions/memory-hard-enforcement/`)
  - ~99% memory reliability (vs ~60-70% soft enforcement)
  - Failsafe design: errors caught, logged, graceful fallback
  - Configurable: enabled, maxResults, minScore, timeoutMs, skipPatterns
  - CLI: `openclaw memory:hard-enforcement [status|enable|disable|toggle]`
  - Quick command: `/hme` to toggle
  - Documentation: [docs/06-memory-hard-enforcement.md](docs/06-memory-hard-enforcement.md)

- **Research Assessment** — Evaluated qdrant-mcp-pi5 for improvements
  - Key insight: Hard enforcement dramatically improves memory reliability
  - Hybrid memory architecture concept documented for future
  - Documentation: [docs/07-qdrant-mcp-pi5-assessment.md](docs/07-qdrant-mcp-pi5-assessment.md)

### Changed

- **OpenClaw Version** — Updated from 2026.2.23 to 2026.2.24
- **Embedding Model** — Confirmed working: `embeddinggemma-300m-qat-Q8_0` (superior to MiniLM-L6-v2)
- **Plugin Configuration** — Added memory-hard-enforcement to active plugins

### Fixed

- **Workspace backup** — Committed all workspace files to charon-toshiba-BU
- **BOOTSTRAP.md** — Removed after first-day setup completed
- **Plugin config validation** — Fixed `timeoutMs` placement in config structure

## Unreleased

- **Fix**: Patch tool call id validation to ensure strict 9-char alphanumeric format when using function calls.
  - **Workaround**: Middleware `~/openclaw/middleware/toolcall-id-sanitizing.js` ensures tool call IDs match OpenAI's a-z,A-Z,0-9[9] requirements to prevent 400 errors in strict providers.
  - **Details**: Squashed transient `id was but must be a-z, A-Z, 0-9, with a length of 9` failures by sanitizing every outbound tool call ID before invoking `ctx.tools.invoke`.
