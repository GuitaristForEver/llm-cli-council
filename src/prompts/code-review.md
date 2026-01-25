# Code Review Prompt Template

This template is sent to each council provider for independent code review.

---

## Prompt Template

```
TASK: Review the following code changes for bugs, security issues, performance problems, and maintainability concerns.

EXPECTED OUTCOME: Provide a structured code review with:
- Assessment of code quality (1-10 scale)
- Identified issues categorized by severity
- Specific recommendations with file/line references
- Final verdict: APPROVE, REQUEST CHANGES, or REJECT

CONTEXT:
- This is a code review, not implementation
- Focus on issues that matter, not style nitpicks
- Prioritize: Correctness → Security → Performance → Maintainability

CODE CHANGES:
---
{CODE_CONTENT}
---

FILES AFFECTED:
{FILE_LIST}

CONSTRAINTS:
- You are one voice in a council of reviewers
- Keep feedback actionable and specific
- Reference file:line when possible

MUST DO:
1. Rate code quality on 1-10 scale with justification
2. List issues by severity: CRITICAL | HIGH | MEDIUM | LOW
3. For each issue: file, line (if known), description, suggested fix
4. Provide 3-5 actionable recommendations
5. Give clear verdict: APPROVE | REQUEST CHANGES | REJECT

MUST NOT DO:
- Nitpick formatting (let formatters handle this)
- Flag theoretical concerns unlikely to occur
- Suggest complete rewrites for minor issues
- Be overly verbose

OUTPUT FORMAT:
RATING: [1-10] - [one-line justification]

ISSUES:
CRITICAL:
• [file:line] [Description] → [Suggested fix]

HIGH:
• [file:line] [Description] → [Suggested fix]

MEDIUM:
• [file:line] [Description] → [Suggested fix]

LOW:
• [file:line] [Description] → [Suggested fix]

RECOMMENDATIONS:
1. [Specific recommendation]
2. [Specific recommendation]
3. [Specific recommendation]

VERDICT: [APPROVE / REQUEST CHANGES / REJECT]
CONFIDENCE: [HIGH / MEDIUM / LOW]
REASONING: [1-2 sentences explaining verdict]
```

---

## Variable Substitution

| Variable | Source |
|----------|--------|
| `{CODE_CONTENT}` | Git diff, file contents, or pasted code |
| `{FILE_LIST}` | List of files being reviewed |

---

## Provider-Specific Adjustments

### Claude
No adjustments - template works as-is.

### Codex
Add prefix: "You are an expert code reviewer. Focus on bugs and security issues."

### Copilot
Add prefix: "Review this code from a GitHub PR perspective. Be specific about issues."

### Gemini
Add prefix: "Provide comprehensive code review covering all quality aspects."

### Ollama
Simplify for smaller models - focus on critical issues only.

---

## Response Parsing

Expected response sections to parse:
1. `RATING:` line with number and justification
2. `ISSUES:` with severity categories
3. `RECOMMENDATIONS:` numbered list
4. `VERDICT:` APPROVE, REQUEST CHANGES, or REJECT
5. `CONFIDENCE:` HIGH, MEDIUM, or LOW
6. `REASONING:` explanation

---

## Issue Severity Definitions

| Severity | Definition | Example |
|----------|------------|---------|
| CRITICAL | Security vulnerability, data loss risk, crash | SQL injection, null pointer |
| HIGH | Bug that affects functionality | Wrong calculation, broken feature |
| MEDIUM | Code smell, maintainability issue | Complex function, poor naming |
| LOW | Minor improvement opportunity | Documentation, minor refactor |

---

## Verdict Definitions

| Verdict | When to Use |
|---------|-------------|
| APPROVE | No critical/high issues, code is ready to merge |
| REQUEST CHANGES | Has high issues or multiple medium issues needing fix |
| REJECT | Critical issues or fundamentally flawed approach |
