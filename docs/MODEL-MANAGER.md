# Model Manager

A raspi-config style TUI for managing OpenClaw models with full CRUD operations, health monitoring, and auto-discovery.

---

## Features

| Feature | Description |
|---------|-------------|
| **Add** | Add custom models with provider, base URL, and API key |
| **Test All** | Test connection to all configured models |
| **Test Specific** | Test a specific model by ID |
| **Remove** | Remove models from configuration |
| **Health** | Run health checks on all models |
| **Metadata** | View and edit model metadata |
| **Batch** | Batch add/remove multiple models |
| **Auto-Discover** | Auto-discover available models from providers |

---

## Usage

### Interactive Menu
```bash
./scripts/model-manager.sh
```

### Command Line
```bash
./scripts/model-manager.sh menu     # Interactive TUI (default)
./scripts/model-manager.sh add       # Add a model
./scripts/model-manager.sh test      # Test all models
./scripts/model-manager.sh health    # Run health check
./scripts/model-manager.sh list      # List all models
./scripts/model-manager.sh remove    # Remove a model
./scripts/model-manager.sh discover  # Auto-discover models
```

---

## Menu System

The TUI provides a whiptail-based menu with these options:

```
🦞 OpenClaw Model Manager
-------------------------
1. Add Custom Model
2. List All Models
3. Test All Connections
4. Test Specific Model
5. Set Default Model
6. View Current Model
7. View Model Info (Metadata)
8. Edit Model Info
9. Backup Config
0. Restore Config
R. Remove Model
B. Batch Operations
P. View Providers
D. Auto-Discover Models
H. Run Health Check
L. Health History
Q. Quit
```

---

## Configuration

Models are stored in `~/.openclaw/openclaw.json` under the `models` section.

Example model entry:
```json
{
  "id": "llama3",
  "provider": "ollama",
  "baseUrl": "http://127.0.0.1:11434/v1",
  "apiKey": "none",
  "default": true
}
```

---

## Health Monitoring

Health checks are logged to:
- `~/.openclaw/workspace/memory/model-health.json`
- `~/.openclaw/workspace/memory/model-metadata.json`
