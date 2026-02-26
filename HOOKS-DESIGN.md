# Hooks Integration Design

This document outlines how to integrate Claude Code hooks with llm-cli-council for proactive council suggestions.

## Overview

**Current Approach**: Global rules in `~/.claude/rules/delegator/` influence Claude's thinking
**With Hooks**: Proactive automation - detect triggers and take action automatically

Hooks provide a MORE powerful integration because they can:
- Execute commands automatically
- Show notifications
- Analyze context in real-time
- Take action without waiting for Claude to decide

## Proposed Hooks

### 1. UserPromptSubmit Hook (High-Stakes Detection)

**Trigger**: User submits a message
**Action**: Detect high-stakes keywords and auto-suggest council review

```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "matcher": ".*",
      "hooks": [{
        "type": "prompt",
        "prompt": "Analyze this user message: $ARGUMENTS. Does it contain high-stakes keywords like 'production deployment', 'breaking change', 'major refactor', 'security', 'architecture decision'? If YES and a PLAN.md exists in .planning/, respond with: 'SUGGEST_COUNCIL_REVIEW'. Otherwise respond: 'NO_ACTION'.",
        "statusMessage": "Checking for council triggers..."
      }]
    }]
  }
}
```

**Behavior**:
- Runs on every user message submission
- LLM analyzes message for high-stakes keywords
- If detected + plan exists → suggests council review
- Non-blocking (user can proceed anyway)

### 2. PostToolUse Hook (Plan Creation Detection)

**Trigger**: After Write tool creates a file ending in `PLAN.md`
**Action**: Auto-suggest council review of the new plan

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write",
      "hooks": [{
        "type": "command",
        "command": "if echo \"$ARGUMENTS\" | jq -r '.file_path' | grep -q 'PLAN\\.md$'; then echo '✨ Plan created! Consider running: /llm-cli-council:review-plan'; fi",
        "statusMessage": "Checking for new plans..."
      }]
    }]
  }
}
```

**Behavior**:
- Runs after every Write tool call
- Checks if written file is a PLAN.md
- If yes → displays suggestion message
- Non-intrusive notification

### 3. PreToolUse Hook (Major Commit Detection)

**Trigger**: Before Bash tool runs a git commit
**Action**: Detect major commits and suggest council review

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "if echo \"$ARGUMENTS\" | jq -r '.command' | grep -q 'git commit.*feat\\|refactor\\|BREAKING'; then echo '⚠️  Major commit detected. Consider council review first: /llm-cli-council:review-code'; fi",
        "statusMessage": "Analyzing commit..."
      }]
    }]
  }
}
```

**Behavior**:
- Runs before git commits
- Checks commit type (feat, refactor, BREAKING)
- Suggests council review before committing
- User can ignore and proceed

### 4. SessionStart Hook (Council Status Reminder)

**Trigger**: When Claude Code session starts
**Action**: Show council availability status

```json
{
  "hooks": {
    "SessionStart": [{
      "matcher": ".*",
      "hooks": [{
        "type": "command",
        "command": "if [ -f ~/.config/claude/council/config.json ]; then echo '🎭 LLM Council ready - Run /llm-cli-council:status to view providers'; fi",
        "async": true
      }]
    }]
  }
}
```

**Behavior**:
- Runs once per session start
- Checks if council is configured
- Displays availability notification
- Async (doesn't block startup)

## Implementation Options

### Option A: Plugin-Provided Hooks (Recommended)

Add a `hooks` section to `.claude-plugin/plugin.json`:

```json
{
  "name": "llm-cli-council",
  "version": "1.0.0",
  "hooks": {
    "UserPromptSubmit": [...],
    "PostToolUse": [...],
    "PreToolUse": [...],
    "SessionStart": [...]
  }
}
```

**Pros**:
- Bundled with plugin
- Auto-installed on plugin install
- Auto-removed on plugin uninstall
- Version-controlled

**Cons**:
- Requires Claude Code to support plugin-provided hooks (may not be implemented yet)

### Option B: Setup Skill Installs Hooks

The `/llm-cli-council:setup` skill writes hooks to user's settings:

```bash
# In skills/setup.md - Step 6: Install Hooks
cat >> ~/.claude/settings.json <<'EOF'
{
  "hooks": {
    "UserPromptSubmit": [...],
    ...
  }
}
EOF
```

**Pros**:
- Works with current Claude Code
- User can customize
- Immediate availability

**Cons**:
- Manual removal needed
- Can conflict with existing hooks
- Harder to version

### Option C: Hybrid Approach

1. Plugin ships with hooks in `hooks/` directory
2. Setup skill offers to install them
3. Uninstall skill removes them

**Example structure**:
```
llm-cli-council/
├── hooks/
│   ├── user-prompt-submit.json
│   ├── post-tool-use.json
│   └── pre-tool-use.json
└── skills/
    ├── setup.md (asks to install hooks)
    └── uninstall.md (removes hooks)
```

## Hook Testing Strategy

### Testing High-Stakes Detection

```bash
# Test 1: Should trigger suggestion
echo "I'm planning a breaking change to the auth system" | claude

# Expected: "Consider council review: /llm-cli-council:review-plan"

# Test 2: Should NOT trigger
echo "Fix typo in README" | claude

# Expected: No suggestion
```

### Testing Plan Creation Hook

```bash
# Create a test plan
echo "---\nphase: 01-test\n---\n\n# Test Plan" > .planning/test-PLAN.md

# Expected: "✨ Plan created! Consider running: /llm-cli-council:review-plan"
```

### Testing Commit Hook

```bash
# Test major commit
git commit -m "feat: add new authentication system"

# Expected: "⚠️  Major commit detected. Consider council review first"

# Test minor commit
git commit -m "docs: update README"

# Expected: No suggestion
```

## Performance Considerations

**Hook Execution Time**:
- UserPromptSubmit: ~100-300ms (LLM prompt analysis)
- PostToolUse: ~10-50ms (file path check)
- PreToolUse: ~10-50ms (commit message check)
- SessionStart: ~5-10ms (config file check)

**Optimization**:
- Use simple bash checks where possible
- Only use LLM prompts when necessary
- Make hooks async when they don't block workflow
- Cache config checks for multiple invocations

## User Control

Users can disable hooks globally:

```json
{
  "disableAllHooks": true
}
```

Or disable specific plugin hooks:

```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "matcher": "llm-cli-council-high-stakes",
      "hooks": []
    }]
  }
}
```

## Migration Path

**Phase 1: Keep Rules**
- Current rules continue working
- Hooks added as opt-in enhancement
- Users can choose rules-only or rules+hooks

**Phase 2: Hooks Default**
- Hooks installed by default in setup
- Rules remain as fallback
- Users can disable either

**Phase 3: Hooks Primary**
- Hooks become primary integration
- Rules simplified or deprecated
- Better user experience overall

## Next Steps

1. **Decide on implementation option** (A, B, or C)
2. **Create hook definitions** in chosen format
3. **Update setup skill** to install hooks
4. **Update uninstall skill** to remove hooks
5. **Test thoroughly** with all hook types
6. **Document in README** how hooks enhance the experience
7. **Update CHANGELOG** with hooks integration

## Questions for User

1. Which implementation option do you prefer? (A, B, or C)
2. Should hooks be installed by default or opt-in?
3. Any specific triggers you'd like hooks to detect?
4. Preferred notification style (console output, status messages, etc.)?
