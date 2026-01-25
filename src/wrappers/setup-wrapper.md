---
name: llm-cli-council:setup
description: Detect and configure available LLM CLIs for the council with authentication testing
invocable: true
---

# LLM CLI Council Setup

Comprehensive setup that detects LLM CLIs, tests authentication, and lets you choose preferred providers.

## Execution Steps

### Step 1: Detect and Test Each Provider

For each provider, perform comprehensive checks:

#### Claude
```bash
# Check if installed
which claude

# Get version
claude --version 2>&1

# Test auth with simple prompt
echo "test" | claude -p --print "Say OK" 2>&1 | grep -q "OK" && echo "AUTH_OK" || echo "AUTH_FAIL"
```

#### Copilot
```bash
# Check if installed
which copilot

# Get version
copilot --version 2>&1

# Test auth - copilot requires interactive session, check config
copilot config get 2>&1 | grep -q "token" && echo "AUTH_OK" || echo "AUTH_FAIL"
```

#### Codex
```bash
# Check if installed
which codex

# Get version
codex --version 2>&1

# Test auth with simple command
codex exec "echo 'OK'" 2>&1 | grep -q "OK" && echo "AUTH_OK" || echo "AUTH_FAIL"
```

#### Gemini
```bash
# Check if installed
which gemini

# Get version
gemini --version 2>&1

# Test auth with simple prompt
echo "Say OK" | gemini 2>&1 | grep -qi "ok" && echo "AUTH_OK" || echo "AUTH_FAIL"
```

#### Ollama
```bash
# Check if installed
which ollama

# Check models
ollama list 2>&1

# Test with simple prompt (check if gpt-oss:20b works)
echo "Say OK" | ollama run gpt-oss:20b 2>&1 | grep -qi "ok" && echo "AUTH_OK" || echo "AUTH_OK"
# Note: Ollama doesn't need auth, mark OK if models exist
```

### Step 2: Display Detection Results

Show comprehensive status table:

```
LLM CLI COUNCIL - DETECTION RESULTS
═══════════════════════════════════════════════════════

Scanning for LLM CLI tools...

Provider     Status          Version       Auth Status
─────────────────────────────────────────────────────────
Claude       FOUND           2.1.19        ✓ Authenticated
Copilot      FOUND           0.0.394       ✓ Authenticated
Codex        FOUND           0.77.0        ✓ Authenticated
Gemini       FOUND           0.24.0        ✓ Authenticated
Ollama       FOUND           models: 2     ✓ Ready

═══════════════════════════════════════════════════════
Total: 5/5 providers detected
```

If there are issues:

```
Provider     Status          Issue                 How to Fix
─────────────────────────────────────────────────────────
Gemini       NOT FOUND       CLI not installed     brew install gemini-cli
Copilot      AUTH FAILED     Not logged in         copilot auth login
Ollama       NO MODELS       No models available   ollama pull gpt-oss:20b
```

### Step 3: Let User Select Preferred Providers

Use AskUserQuestion with multiSelect to let user choose which providers to enable:

```javascript
AskUserQuestion({
  questions: [{
    question: "Which LLM providers would you like to use in the council?",
    header: "Providers",
    multiSelect: true,
    options: [
      {
        label: "Claude (2.1.19) - Recommended for planning",
        description: "Anthropic's Claude via CLI - excellent for reasoning and analysis"
      },
      {
        label: "Codex (0.77.0) - Recommended for code",
        description: "OpenAI's Codex via CLI - specialized for code review and generation"
      },
      {
        label: "Copilot (0.0.394) - Good for code",
        description: "GitHub Copilot CLI - strong code understanding"
      },
      {
        label: "Gemini (0.24.0) - Good for research",
        description: "Google's Gemini CLI - broad knowledge and multimodal"
      },
      {
        label: "Ollama (gpt-oss:20b) - Privacy mode",
        description: "Local LLM runner - no data sent externally, fully private"
      }
    ]
  }]
})
```

### Step 4: Build Configuration

Based on user selection, create `$COUNCIL_CONFIG_FILE`:

```json
{
  "version": "1.0.0",
  "lastSetup": "2025-01-24T19:00:00Z",
  "providers": {
    "claude": {
      "enabled": true,
      "available": true,
      "path": "/usr/local/bin/claude",
      "version": "x.y.z",
      "authenticated": true,
      "invocation": "claude -p --print \"{prompt}\"",
      "lastChecked": "2025-01-24T19:00:00Z"
    },
    "codex": {
      "enabled": true,
      "available": true,
      "path": "/usr/local/bin/codex",
      "version": "x.y.z",
      "authenticated": true,
      "invocation": "codex exec \"{prompt}\"",
      "lastChecked": "2025-01-24T19:00:00Z"
    }
    // ... other providers based on selection
  },
  "defaultMode": "quick",
  "availableCount": 5,
  "enabledCount": 2,
  "preferences": {
    "autoSuggest": true,
    "requirePrivacyFor": ["api", "secret", "password"],
    "skipFor": ["draft", "wip", "test"]
  }
}
```

### Step 5: Display Final Summary

```
LLM CLI COUNCIL - SETUP COMPLETE
═══════════════════════════════════════════════════════

ENABLED PROVIDERS (2 selected):
  ✓ Claude (2.1.19)
  ✓ Codex (0.77.0)

AVAILABLE BUT DISABLED (3 not selected):
  ○ Copilot (0.0.394) - Run setup again to enable
  ○ Gemini (0.24.0) - Run setup again to enable
  ○ Ollama (gpt-oss:20b) - Run setup again to enable

COUNCIL MODES:
  • quick   - Uses your 2 enabled providers
  • full    - Uses all 5 available providers (ignores selection)
  • privacy - Ollama only (if enabled)

NEXT STEPS:
  1. Test the council: /llm-cli-council:review-plan PLAN.md
  2. Change providers: Re-run /llm-cli-council:setup
  3. Check status: /llm-cli-council:status

Configuration saved to: $COUNCIL_CONFIG_FILE
═══════════════════════════════════════════════════════
```

## Authentication Testing Details

### Why Test Auth?

Simply checking `--version` doesn't confirm the CLI can actually make API calls. We test with real prompts to ensure:
- API keys are configured
- Network connectivity works
- Quotas/limits aren't exceeded
- CLI is fully functional

### Auth Test Commands

| Provider | Test Command | Success Check |
|----------|-------------|---------------|
| Claude | `echo "test" \| claude -p --print "Say OK"` | Output contains "OK" |
| Codex | `codex exec "echo 'OK'"` | Output contains "OK" or successful execution |
| Copilot | `copilot config get` | Config contains token |
| Gemini | `echo "Say OK" \| gemini` | Output contains "ok" (case insensitive) |
| Ollama | `ollama list` | Models listed (no external auth needed) |

### Handling Auth Failures

When auth fails:
1. Mark provider as `available: true, authenticated: false`
2. Show specific fix command
3. Allow user to continue setup with working providers
4. Suggest re-running setup after fixing auth

## Re-running Setup

When running setup again:
1. Re-detect all providers (catches new installations)
2. Re-test authentication (catches newly authenticated CLIs)
3. Show current selection and allow changes
4. Preserve preferences from previous config

## Error Handling

### No Providers Found
```
No LLM CLI tools detected.

Install at least one:
• Claude: npm install -g @anthropic-ai/claude-cli
• Codex: npm install -g openai-codex-cli
• Copilot: npm install -g @githubnext/github-copilot-cli
• Gemini: npm install -g @google/gemini-cli
• Ollama: brew install ollama

Then run /llm-cli-council:setup again.
```

### All Providers Unauthenticated
```
All detected providers need authentication:

• Claude: claude auth login
• Codex: codex auth login
• Copilot: copilot auth login
• Gemini: gemini auth login

After authenticating, run /llm-cli-council:setup again.
```

### Partial Success
```
Some providers are ready, others need attention.

Setup will continue with working providers.
You can fix issues and re-run setup later.
```
