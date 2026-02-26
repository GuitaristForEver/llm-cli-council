---
name: llm-cli-council:review-plan
description: Get council review of an implementation plan from multiple LLM providers
invocable: true
---

# LLM CLI Council - Review Plan

This command orchestrates multiple LLM CLIs to review an implementation plan and synthesizes their feedback.

## Usage

```
/llm-cli-council:review-plan [plan-file] [--mode=quick|full|privacy]
```

### Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `plan-file` | Path to plan file | Auto-detect PLAN.md in current/project directory |
| `--mode` | Council mode | `quick` (2 providers) |

---

## Execution Flow

### Step 1: Load Configuration

Read council configuration from `$COUNCIL_CONFIG_FILE`.

If config doesn't exist:
```
Council not configured. Run /llm-cli-council:setup first.
```

### Step 2: Locate Plan Content

Priority order:
1. Explicit file path argument
2. `PLAN.md` in current directory
3. `PLAN.md` in `.planning/` directory
4. Ask user to provide plan content

### Step 3: Select Providers

Based on mode:

**quick (default):**
- Read `${CLAUDE_PLUGIN_ROOT}/config/providers.json` task routing for `plan-review`
- Select top 2 available providers by routing priority
- Preferred: Claude, Codex. Fallback: Gemini

**full:**
- Use all available providers from config

**privacy:**
- Use only Ollama (if available)
- Error if Ollama not configured

### Step 4: Build Review Prompts

For each selected provider:
1. Load `${CLAUDE_PLUGIN_ROOT}/prompts/plan-review.md` template
2. Substitute `{PLAN_CONTENT}` with actual plan
3. Apply provider-specific prefix adjustments
4. Prepare CLI invocation command

### Step 5: Execute Parallel Reviews

Run all provider CLIs in parallel using background execution:

```bash
# Example parallel execution
claude -p --print "{prompt}" &
codex exec "{prompt}" &
wait
```

Timeout handling:
- Default: 120 seconds per provider
- On timeout: Log warning, continue with remaining providers
- Minimum quorum: 2 providers must respond

### Step 6: Collect Responses

Parse each provider response:
1. Extract structured sections (RATING, GAPS, RISKS, RECOMMENDATIONS, VERDICT)
2. Handle malformed responses gracefully
3. Track which providers responded successfully

### Step 7: Chairman Synthesis

1. Load `${CLAUDE_PLUGIN_ROOT}/prompts/chairman-synthesis.md`
2. Format all provider reviews into synthesis prompt
3. Claude (as Chairman) synthesizes into unified guidance
4. Apply anti-paralysis rules (max 5 recommendations, clear verdict)

### Step 8: Present Results

Display formatted council review:

```
COUNCIL REVIEW
═══════════════════════════════════════════════════════

Providers consulted: Claude, Codex
Mode: quick

CONSENSUS (Both agree):
• Plan lacks error handling section
• Database migration strategy is solid

CONCERNS (Raised by at least one):
• Testing strategy unclear — Raised by: Codex
  Assessment: Valid - add testing section

DISSENTING VIEWS:
• Deployment approach: Claude prefers blue-green, Codex prefers canary
  Resolution: Blue-green is simpler for this scale - go with Claude's recommendation

RECOMMENDATIONS (prioritized):
1. Add error handling section [Quick]
2. Clarify testing strategy [Quick]
3. Consider adding rollback plan [Short]

PROVIDER VERDICTS:
  Claude: APPROVE (HIGH)
  Codex: REQUEST CHANGES (MEDIUM)

FINAL VERDICT: REQUEST CHANGES
Reasoning: While the plan is solid, the missing testing strategy
is a significant gap that should be addressed before implementation.

═══════════════════════════════════════════════════════
```

---

## Error Handling

### No Providers Available
```
Error: No council providers available.
Run /llm-cli-council:setup to configure providers.
```

### Single Provider Only
```
Warning: Only 1 provider responded. Results may lack diversity.
Consider running with --mode=full or checking provider status.

[Present single review with disclaimer]
```

### All Providers Timeout
```
Error: All providers timed out.
- Check network connectivity
- Verify provider authentication: /llm-cli-council:status
- Try privacy mode with local Ollama: --mode=privacy
```

### Plan Not Found
```
No plan found. Please provide:
1. Path to plan file: /llm-cli-council:review-plan ./my-plan.md
2. Create PLAN.md in current directory
3. Paste plan content when prompted
```

---

## CLI Invocation Reference

| Provider | Command |
|----------|---------|
| Claude | `claude -p --print "{prompt}"` |
| Codex | `codex exec "{prompt}"` |
| Copilot | `copilot --prompt "{prompt}" --allow-all-tools` |
| Gemini | `gemini "{prompt}"` |
| Ollama | `ollama run gpt-oss:20b "{prompt}"` |

---

## Output Options

Future enhancement ideas:
- `--json` - Output as JSON for programmatic use
- `--brief` - Only show verdict and top 3 recommendations
- `--save` - Save full council review to file
