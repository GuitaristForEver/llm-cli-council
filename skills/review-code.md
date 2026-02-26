---
name: llm-cli-council:review-code
description: Get council review of code changes from multiple LLM providers
invocable: true
---

# LLM CLI Council - Review Code

This command orchestrates multiple LLM CLIs to review code changes and synthesizes their feedback.

## Usage

```
/llm-cli-council:review-code [target] [--mode=quick|full|privacy]
```

### Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `target` | File path, git ref, or "staged" | Staged changes (`git diff --cached`) |
| `--mode` | Council mode | `quick` (2 providers) |

### Target Options

| Target | Description |
|--------|-------------|
| `staged` | Review staged git changes |
| `HEAD` | Review last commit |
| `HEAD~3..HEAD` | Review last 3 commits |
| `main..HEAD` | Review all commits since main |
| `path/to/file.js` | Review specific file |
| `path/to/dir/` | Review all files in directory |

---

## Execution Flow

### Step 1: Load Configuration

Read council configuration from `$COUNCIL_CONFIG_FILE`.

If config doesn't exist:
```
Council not configured. Run /llm-cli-council:setup first.
```

### Step 2: Get Code Content

Based on target:

**Staged changes (default):**
```bash
git diff --cached
```

**Git ref:**
```bash
git diff {ref}
# or
git show {ref}
```

**File/directory:**
```bash
cat {file}
# or
find {dir} -type f -exec cat {} \;
```

### Step 3: Select Providers

Based on mode and task routing for `code-review`:
- **quick**: Codex, Copilot (preferred) or Claude (fallback)
- **full**: All available
- **privacy**: Ollama only

### Step 4: Build Review Prompts

For each selected provider:
1. Load `${CLAUDE_PLUGIN_ROOT}/prompts/code-review.md` template
2. Substitute `{CODE_CONTENT}` with diff/code
3. Substitute `{FILE_LIST}` with affected files
4. Apply provider-specific prefix adjustments

### Step 5: Execute Parallel Reviews

Same pattern as review-plan - parallel execution with timeout handling.

### Step 6: Collect & Parse Responses

Parse structured sections:
- RATING
- ISSUES (by severity)
- RECOMMENDATIONS
- VERDICT

### Step 7: Chairman Synthesis

Synthesize with code-review-specific weighting:
- Codex and Copilot weighted higher for code issues
- Severity aggregation across providers
- Deduplicate same issue found by multiple providers

### Step 8: Present Results

```
COUNCIL CODE REVIEW
═══════════════════════════════════════════════════════

Target: staged changes (3 files)
Providers: Codex, Copilot
Mode: quick

FILES REVIEWED:
• src/api/auth.ts
• src/utils/validation.ts
• tests/auth.test.ts

CRITICAL ISSUES:
• src/api/auth.ts:45 - SQL injection vulnerability
  Found by: Codex, Copilot (CONSENSUS)
  Fix: Use parameterized queries

HIGH ISSUES:
• src/utils/validation.ts:23 - Missing null check
  Found by: Codex
  Fix: Add guard clause before access

MEDIUM ISSUES:
• src/api/auth.ts:78 - Complex function (cyclomatic: 12)
  Found by: Copilot
  Assessment: Valid but not blocking

RECOMMENDATIONS (prioritized):
1. Fix SQL injection immediately [Quick]
2. Add null check in validation [Quick]
3. Consider splitting auth function [Short]

PROVIDER VERDICTS:
  Codex: REQUEST CHANGES (HIGH) - Security issue
  Copilot: REQUEST CHANGES (HIGH) - Security issue

FINAL VERDICT: REQUEST CHANGES
Reasoning: Critical SQL injection vulnerability must be fixed
before merge. Both providers flagged this with high confidence.

═══════════════════════════════════════════════════════
```

---

## Issue Aggregation

### Same Issue, Multiple Providers

When providers identify the same issue:
1. Mark as CONSENSUS
2. Use most specific file:line reference
3. Combine fix suggestions
4. Elevate severity if any provider rates higher

### Conflicting Severity

If providers disagree on severity:
- Security issues: Use highest severity (conservative)
- Style issues: Use lowest severity (pragmatic)
- Other: Chairman decides based on context

---

## Error Handling

### No Git Repository
```
Error: Not in a git repository.
For non-git code review, specify file path:
  /llm-cli-council:review-code path/to/file.js
```

### No Changes to Review
```
No staged changes found. Options:
1. Stage changes: git add <files>
2. Review specific commit: /llm-cli-council:review-code HEAD
3. Review file directly: /llm-cli-council:review-code path/to/file
```

### Large Diff Warning
```
Warning: Diff is large (>1000 lines).
This may result in incomplete reviews or timeouts.

Options:
1. Continue anyway
2. Review specific files instead
3. Split into smaller chunks
```

---

## Integration

### With Git Workflow

```bash
# Review before commit
git add .
/llm-cli-council:review-code staged

# Review before push
/llm-cli-council:review-code main..HEAD

# Review specific PR
/llm-cli-council:review-code origin/main..feature-branch
```

### With Other Review Tools

Council review complements (doesn't replace):
- Linters (ESLint, Pylint)
- Type checkers (TypeScript, mypy)
- Security scanners (Snyk, CodeQL)

Run automated tools first, then council for logic review.
