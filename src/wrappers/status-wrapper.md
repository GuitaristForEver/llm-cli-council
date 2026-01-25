---
name: llm-cli-council:status
description: Show council configuration and provider availability status
invocable: true
---

# LLM CLI Council - Status

This command displays the current council configuration and checks provider availability.

## Usage

```
/llm-cli-council:status [--check]
```

### Arguments

| Argument | Description |
|----------|-------------|
| `--check` | Re-check provider availability (live test) |

---

## Execution Flow

### Step 1: Load Configuration

Read `$COUNCIL_CONFIG_FILE`.

If not found:
```
Council not configured.
Run /llm-cli-council:setup to detect and configure providers.
```

### Step 2: Display Status

```
LLM CLI COUNCIL STATUS
═══════════════════════════════════════════════════════

Configuration: $COUNCIL_CONFIG_FILE
Last Setup: 2024-01-15T10:30:00Z
Version: 1.0.0

PROVIDERS
─────────────────────────────────────────────────────────
Provider     Status      Version    Last Used
─────────────────────────────────────────────────────────
Claude       READY       1.0.5      2024-01-15
Copilot      READY       2.1.0      2024-01-14
Codex        READY       1.5.2      2024-01-15
Gemini       READY       0.8.1      2024-01-10
Ollama       READY       0.1.30     2024-01-12

Total: 5/5 providers available

MODES AVAILABLE
─────────────────────────────────────────────────────────
• quick   - 2 providers (Claude, Codex for plans; Codex, Copilot for code)
• full    - 5 providers (all available)
• privacy - 1 provider (Ollama only)

PREFERENCES
─────────────────────────────────────────────────────────
Default Mode: quick
Auto-Suggest: enabled
Privacy Required For: api, secret, password

═══════════════════════════════════════════════════════
```

### Step 3: Live Check (if --check)

When `--check` is specified, actively test each provider:

```bash
# Test each provider with simple prompt
claude --version
copilot --version
codex --version
gemini --version
ollama list
```

Display results:

```
LIVE CHECK RESULTS
─────────────────────────────────────────────────────────
Provider     Check           Result
─────────────────────────────────────────────────────────
Claude       Version         OK (1.0.5)
Copilot      Version         OK (2.1.0)
Codex        Version         OK (1.5.2)
Gemini       Version         FAIL (auth required)
Ollama       Model List      OK (3 models available)

Issues Found:
• Gemini: Authentication required
  Fix: gemini auth login

Would you like to re-run setup? [y/N]
```

---

## Status Indicators

| Status | Meaning |
|--------|---------|
| READY | Provider available and authenticated |
| AUTH ERROR | CLI found but authentication failed |
| NOT FOUND | CLI not installed |
| TIMEOUT | CLI found but not responding |
| UNKNOWN | Unable to determine status |

---

## Troubleshooting Output

When issues detected:

```
TROUBLESHOOTING
─────────────────────────────────────────────────────────

Provider Issues:

1. Gemini - AUTH ERROR
   The Gemini CLI requires authentication.
   Fix: Run `gemini auth login`

2. Ollama - NO MODELS
   Ollama is installed but no models are available.
   Fix: Run `ollama pull gpt-oss:20b`

Quick Fixes:
• Re-run setup: /llm-cli-council:setup
• Check individual CLI: which <cli-name>
• Manual auth: <cli-name> auth login
```

---

## Configuration Details

### Show Full Config (if requested)

```
FULL CONFIGURATION
─────────────────────────────────────────────────────────

providers:
  claude:
    available: true
    path: /usr/local/bin/claude
    version: x.y.z
    authenticated: true
    invocation: claude -p --print "{prompt}"

  codex:
    available: true
    path: /usr/local/bin/codex
    version: x.y.z
    authenticated: true
    invocation: codex exec "{prompt}"

  # ... etc

taskRouting:
  plan-review:
    preferred: [claude, codex]
    fallback: [gemini]

  code-review:
    preferred: [codex, copilot]
    fallback: [claude]

defaults:
  mode: quick
  minQuorum: 2
  timeoutMs: 120000
```

---

## Output Formats

### Default (Human-readable)

Formatted table with colors (if terminal supports).

### JSON (--json flag)

```json
{
  "configured": true,
  "configPath": "$COUNCIL_CONFIG_FILE",
  "lastSetup": "2024-01-15T10:30:00Z",
  "providers": {
    "claude": {"available": true, "version": "x.y.z"},
    "codex": {"available": true, "version": "x.y.z"}
  },
  "availableCount": 5,
  "modes": ["quick", "full", "privacy"]
}
```

---

## Common Issues

| Issue | Solution |
|-------|----------|
| Config not found | Run `/llm-cli-council:setup` |
| All providers unavailable | Check CLI installations, network |
| Auth errors | Run auth command for specific CLI |
| Privacy mode unavailable | Install Ollama: `brew install ollama` |
