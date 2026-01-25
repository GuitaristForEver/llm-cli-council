# Council Triggers

These rules define when to automatically invoke the council without explicit command.

---

## Trigger Patterns

### Explicit Triggers (Highest Priority)

User explicitly requests council:

| Pattern | Action |
|---------|--------|
| "council review" | Invoke review command |
| "get council feedback" | Auto-detect type, execute |
| "ask the council" | Auto-detect type, execute |
| "llm council" | Auto-detect type, execute |
| "/llm-cli-council:*" | Execute specified command |

### Contextual Triggers

When these contexts are detected:

| Context | Trigger | Command |
|---------|---------|---------|
| Plan exists + "review" mentioned | Auto-suggest | review-plan |
| Code diff + "review" mentioned | Auto-suggest | review-code |
| High-stakes decision keywords | Suggest council | review-plan |

### High-Stakes Keywords

When these appear, suggest council review:
- "production deployment"
- "breaking change"
- "major refactor"
- "security"
- "architecture decision"
- "before we proceed"

---

## Auto-Detection Logic

### Plan vs Code Detection

```
If user mentions "review":
  If PLAN.md exists OR "plan" in request:
    → review-plan
  Else if code diff exists OR file paths mentioned:
    → review-code
  Else:
    → Ask user what to review
```

### Mode Detection

```
If "sensitive" or "private" or "confidential" in request:
  → Suggest --mode=privacy

If "thorough" or "comprehensive" or "all" in request:
  → Use --mode=full

Default:
  → Use --mode=quick
```

---

## Proactive Suggestions

### When to Suggest Council

Suggest (don't auto-invoke) when:

1. **Plan created** - "Would you like council feedback on this plan?"
2. **Major PR** - "This is a significant change. Council review recommended."
3. **Before execution** - "Plan ready. Get council review before executing?"

### Suggestion Format

```
Council Review Available
─────────────────────────
This [plan/code] could benefit from multi-perspective review.

Run: /llm-cli-council:review-[type]

Options:
• --mode=quick (default) - 2 providers, fast feedback
• --mode=full - All available providers
• --mode=privacy - Local only, no data sent externally
```

---

## Non-Triggers

Do NOT invoke council for:

- Simple syntax questions
- Single-file edits
- Bug fixes with obvious solutions
- User explicitly declines ("skip council", "no review needed")
- Already reviewed content
- Draft/WIP explicitly marked

---

## Mode Selection Guide

### Quick Mode (Default)

Use when:
- Standard reviews
- Time-sensitive feedback needed
- Plan is straightforward

### Full Mode

Suggest when:
- "thorough" or "comprehensive" requested
- High-stakes keywords detected
- User seems uncertain
- Complex architectural decisions

### Privacy Mode

Require when:
- "sensitive", "private", "confidential" mentioned
- API keys or secrets in content
- Proprietary business logic
- User preference set in config

---

## Integration Points

### With Planning Skills

If user is using planning skills (e.g., `/gsd:plan-phase`):
- Suggest council review after plan completion
- Don't interrupt planning flow

### With Code Review Skills

If another code review is active:
- Don't stack reviews
- Offer council as alternative or supplement

### With Execution

Before plan execution:
- Check if council review was done
- If not, offer quick review opportunity
- Don't block execution (user choice)

---

## User Preferences

Stored in `~/.claude/council-config.json`:

```json
{
  "preferences": {
    "autoSuggest": true,
    "defaultMode": "quick",
    "requirePrivacyFor": ["api", "secret", "password"],
    "skipFor": ["draft", "wip", "test"]
  }
}
```

### Preference Overrides

- `autoSuggest: false` - Never suggest, only respond to explicit commands
- `defaultMode` - Change default from "quick"
- `requirePrivacyFor` - Patterns that force privacy mode
- `skipFor` - Patterns that suppress suggestions
