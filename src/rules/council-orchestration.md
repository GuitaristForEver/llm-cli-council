# Council Orchestration Rules

These rules govern how to coordinate multiple LLM providers as a council.

---

## Core Principles

### 1. Independence First
Each provider reviews independently without knowledge of other reviews.
- Never share one provider's output with another during review
- Prevents groupthink and ensures diverse perspectives
- Cross-contamination invalidates the council's value

### 2. Parallel Execution
Always execute provider calls in parallel when possible.
- Reduces total wait time significantly
- Use background processes or async patterns
- Handle timeouts per-provider, not globally

### 3. Graceful Degradation
Council continues even if some providers fail.
- Minimum quorum: 2 providers for meaningful synthesis
- 1 provider: Warn user, present with disclaimer
- 0 providers: Error with troubleshooting guidance

### 4. Chairman Authority
Claude (as Chairman) has final synthesis authority.
- Resolves all conflicts decisively
- Never leaves decision to user
- Provides clear reasoning for resolutions

---

## Provider Selection Algorithm

### Quick Mode (Default)
```
1. Load task routing from providers.json
2. Filter to available providers only
3. Sort by routing priority (lower = better)
4. Select top 2
5. If < 2 available, use all available
```

### Full Mode
```
1. Get all available providers from config
2. Execute all in parallel
3. Require minimum 2 responses for synthesis
```

### Privacy Mode
```
1. Check if Ollama is available
2. If yes, use only Ollama
3. If no, error with installation instructions
```

---

## Execution Patterns

### Parallel CLI Execution (Bash)

```bash
# Source platform utilities
source "${SKILL_DIR}/lib/platform-utils.sh"

# Create temp files for responses (cross-platform)
RESP_CLAUDE=$(make_temp_file "council_claude")
RESP_CODEX=$(make_temp_file "council_codex")

# Execute in parallel
claude -p --print "$PROMPT" > "$RESP_CLAUDE" 2>&1 &
PID_CLAUDE=$!

codex exec "$PROMPT" > "$RESP_CODEX" 2>&1 &
PID_CODEX=$!

# Wait with timeout (cross-platform)
wait_for_pid "$PID_CLAUDE" 120 || kill "$PID_CLAUDE" 2>/dev/null
wait_for_pid "$PID_CODEX" 120 || kill "$PID_CODEX" 2>/dev/null

# Collect results
CLAUDE_RESPONSE=$(cat "$RESP_CLAUDE")
CODEX_RESPONSE=$(cat "$RESP_CODEX")

# Cleanup
rm "$RESP_CLAUDE" "$RESP_CODEX"
```

### Timeout Handling

Per-provider timeouts from `providers.json`:
- Claude: 120s
- Codex: 120s
- Copilot: 90s
- Gemini: 90s
- Ollama: 180s (local execution can be slower)

On timeout:
1. Kill the process
2. Log which provider timed out
3. Continue with remaining responses
4. Include timeout info in synthesis

---

## Response Collection

### Expected Response Structure

```
RATING: [1-10] - [justification]
GAPS: [bullet list]
RISKS: [bullet list]
RECOMMENDATIONS: [numbered list]
VERDICT: [APPROVE/REQUEST CHANGES]
CONFIDENCE: [HIGH/MEDIUM/LOW]
REASONING: [explanation]
```

### Parsing Rules

1. **Strict sections**: Look for exact headers
2. **Flexible content**: Accept variations in formatting
3. **Missing sections**: Mark as "NOT PROVIDED"
4. **Malformed response**: Include raw response in synthesis with warning

### Response Validation

Valid response must have:
- [ ] VERDICT present (APPROVE or REQUEST CHANGES)
- [ ] At least one RECOMMENDATION
- [ ] Parseable structure

Invalid responses:
- Include in synthesis with "[MALFORMED RESPONSE]" tag
- Still count toward quorum
- Chairman can extract useful content manually

---

## Error Recovery

### Provider Auth Failure

```
Provider [name] auth error: [error message]
Continuing with remaining providers.
Fix: Run `[auth command]` to re-authenticate.
```

### Network Timeout

```
Provider [name] timed out after [X]s.
Continuing with remaining providers.
```

### All Providers Fail

```
Council Review Failed
═══════════════════════════════════════════════════════

All providers failed to respond:
• Claude: [error]
• Codex: [error]

Troubleshooting:
1. Check network connectivity
2. Verify provider auth: /llm-cli-council:status
3. Try privacy mode: --mode=privacy

Would you like to proceed without council review?
```

---

## Logging

For debugging, log:
1. Selected providers and selection reasoning
2. CLI commands executed (without full prompt for privacy)
3. Response times per provider
4. Parse success/failure per provider
5. Final synthesis trigger

Log location: `~/.claude/logs/council/` (if logging enabled)

---

## Security Considerations

### Prompt Content
- Plan content is sent to external providers
- For sensitive plans, use `--mode=privacy` (Ollama only)
- Never log full prompt content

### API Keys
- Each CLI manages its own authentication
- Council doesn't store or transmit API keys
- Auth status checked at setup time only
