---
name: setup
description: Detect and configure available LLM CLIs for the council
invocable: true
---

# LLM CLI Council Setup

This command detects available LLM CLI tools and configures the council.

## Execution Steps

### Step 1: Detect Available CLIs

Run detection for each provider in parallel:

```bash
# Claude
which claude && claude --version 2>/dev/null || echo "not-found"

# Copilot
which copilot && copilot --version 2>/dev/null || echo "not-found"

# Codex
which codex && codex --version 2>/dev/null || echo "not-found"

# Gemini
which gemini && gemini --version 2>/dev/null || echo "not-found"

# Ollama
which ollama && ollama list 2>/dev/null || echo "not-found"
```

### Step 2: Build Configuration

For each detected CLI, record:
- `available`: boolean - whether CLI is found
- `path`: string - full path to CLI
- `version`: string - version if detectable
- `authenticated`: boolean - whether auth check passed

### Step 3: Write Configuration

Before writing config, initialize path variables:

```bash
# Source platform utilities
source "${SKILL_DIR}/lib/platform-utils.sh"

# Path resolution
COUNCIL_CONFIG_DIR="${CLAUDE_COUNCIL_CONFIG_DIR:-${CLAUDE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/claude}/council}"
COUNCIL_CONFIG_FILE="${CLAUDE_COUNCIL_CONFIG_FILE:-$COUNCIL_CONFIG_DIR/config.json}"
COUNCIL_LOG_DIR="${CLAUDE_COUNCIL_LOG_DIR:-$COUNCIL_CONFIG_DIR/logs}"

# Ensure directories exist
ensure_dir "$COUNCIL_CONFIG_DIR"
ensure_dir "$COUNCIL_LOG_DIR"
```

Write results to `$COUNCIL_CONFIG_FILE`:

```json
{
  "version": "1.0.0",
  "lastSetup": "<ISO timestamp>",
  "providers": {
    "claude": {
      "available": true,
      "path": "/path/to/claude",
      "version": "x.y.z",
      "authenticated": true
    }
    // ... other providers
  },
  "defaultMode": "quick",
  "availableCount": 5
}
```

### Step 4: Display Status Table

Present results in a clear table format:

```
LLM CLI COUNCIL - SETUP COMPLETE
═══════════════════════════════════════════════════════

Provider     Status      Path                  Version
─────────────────────────────────────────────────────────
Claude       READY       /usr/local/bin/claude 1.0.0
Copilot      READY       /usr/local/bin/copilot 2.1.0
Codex        READY       /usr/local/bin/codex  1.5.0
Gemini       READY       /usr/local/bin/gemini 0.8.0
Ollama       READY       /usr/local/bin/ollama 0.1.30

═══════════════════════════════════════════════════════
Total: 5/5 providers available

Council Modes Available:
• quick   - 2 providers (fast feedback)
• full    - 5 providers (comprehensive)
• privacy - Ollama only (local execution)

Configuration saved to: $COUNCIL_CONFIG_FILE
Run /llm-cli-council:status to view current configuration.
```

### Step 5: Handle Missing Providers

If a provider is not found or not authenticated:

```
Provider     Status      Issue                 Fix
─────────────────────────────────────────────────────────
Gemini       NOT FOUND   CLI not installed     brew install gemini-cli
Copilot      AUTH ERROR  Not logged in         copilot auth login
```

## Error Handling

- **No providers found**: Display error with installation instructions for each CLI
- **Only 1 provider**: Warn that council requires minimum 2 for quorum, but setup can continue
- **Auth failures**: Log warning but mark provider as available (may work for some commands)

## Post-Setup

After successful setup:
1. Council configuration is stored persistently
2. Commands can auto-detect mode based on available providers
3. Run `/llm-cli-council:review-plan` to test the council

## Re-running Setup

Running setup again will:
1. Re-detect all providers (catches new installations)
2. Update configuration with current status
3. Preserve any custom settings from previous config
