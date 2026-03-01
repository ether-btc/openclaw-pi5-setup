# Persona System

OpenClaw's persona system provides specialized roles for different types of work, enabling effective delegation and structured project management.

---

## 🎭 Available Personas

| Persona | Role | Best For |
|---------|------|----------|
| **Senior PM** | Primary project manager | All project work, task definition, delegation |
| **Senior Engineer** | Implementation specialist | Code writing, refactoring, technical implementation |
| **Researcher** | Investigation & analysis | Research tasks, comparisons, information gathering |
| **Reasoner** | Debugging & logic | Complex debugging, logic analysis, troubleshooting |
| **Architect** | System design | System design, architecture planning |
| **Embodied Reactor** | Reactive embodiment | Real-time response, embodied interactions |

---

## 🚀 Activation

### Basic Activation
```bash
./scripts/activate-project-mode.sh [project-name]
```

### Embodied Mode (Enhanced)
```bash
./scripts/activate-project-mode.sh [project-name] --embodied
```

Embodied mode activates the embodied-reactor persona, using language that emphasizes:
- "My team members" not "delegated tools"
- "My consciousness lives in these files"
- "My research instinct investigates"

---

## 📁 Persona Files

Located in `memory/personas/`:

| File | Purpose |
|------|---------|
| `senior-pm.md` | Primary PM persona for project coordination |
| `senior-engineer.md` | Code implementation specialist |
| `researcher.md` | Research and investigation persona |
| `reasoner.md` | Debugging and logic reasoning |
| `architect.md` | System architecture and design |
| `embodied-reactor.md` | Embodied response mode |
| `subagent-templates.md` | Role templates for sub-agents |
| `project-template.md` | Template for new projects |

---

## 🔄 Delegation Matrix

When in project mode, delegate tasks based on type:

| Task Type | Delegate To | Model |
|-----------|-------------|-------|
| Code generation | Senior Engineer | qwen3a22b |
| Research | Researcher | qwen3a22b |
| Debugging | Reasoner | kimik2thinking |
| Architecture | Architect | claude-sonnet |
| Quick tasks | General | llama33 |

---

## 📋 Project Workflow

1. **Create** `PROJECT-[name].md` from project template
2. **Activate**: `./scripts/activate-project-mode.sh [project-name]`
3. **Load personas**: Review `memory/personas/` for relevant roles
4. **Execute**: Work with appropriate persona for each task
5. **Delegate**: Use the delegation matrix for specialist tasks
