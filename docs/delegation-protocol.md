# Verified Delegation Protocol

All OpenClaw delegation models tested and working as of 2026-03-11:

| Task Type | Model | Invocation |
|-----------|-------|------------|
| Coding | qwen3-coder | `agentId: qwen3-coder` |
| Reasoning | kimik2thinking | `agentId: kimik2thinking` |
| Fast tasks | minimax-m2.5:free | `model: kilocode/minimax/...` |
| Heavy reasoning | deepseek-reasoner | `agentId: deepseek-reasoner` |
| Fast reasoning | glm-4.7 | `model: zai/glm-4.7` |

**Critical:** Use `agentId:` for agent-wrapped models, `model:` for provider-integrated models.

## Subagent Spawning

### When to Spawn
- Task >2-3 minutes → spawn subagent
- Task <30 seconds → inline processing
- Parallel work → spawn multiple

### Best Practices
- Always verify output files exist
- Use progress.md for tracking
- Use `cleanup: "delete"` for production, `"keep"` for debugging

## Tool Call Rules
- Use `agentId:` for agent-wrapped models
- Use `model:` for provider-integrated models
- Agent wrappers handle tool execution correctly
