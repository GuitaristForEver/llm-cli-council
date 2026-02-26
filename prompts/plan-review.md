# Plan Review Prompt Template

This template is sent to each council provider for independent plan review.

---

## Prompt Template

```
TASK: Review the following implementation plan for completeness, clarity, and technical soundness.

EXPECTED OUTCOME: Provide a structured review with:
- Assessment of plan quality (1-10 scale)
- Identified issues or gaps
- Specific recommendations
- Final verdict: APPROVE or REQUEST CHANGES

CONTEXT:
- This is a plan review, not implementation
- Focus on whether the plan is executable as written
- Consider: clarity, completeness, technical feasibility, risk management

PLAN CONTENT:
---
{PLAN_CONTENT}
---

CONSTRAINTS:
- You are one voice in a council of reviewers
- Keep your review focused and specific
- Do not implement or modify - only review

MUST DO:
1. Rate the plan on a 1-10 scale with brief justification
2. List any missing information or unclear sections
3. Identify potential risks not addressed
4. Provide 3-5 specific, actionable recommendations
5. Give a clear APPROVE or REQUEST CHANGES verdict

MUST NOT DO:
- Provide generic advice ("add more detail")
- Suggest complete rewrites
- Overlap with implementation concerns
- Be overly verbose

OUTPUT FORMAT:
RATING: [1-10] - [one-line justification]

GAPS:
• [Gap 1]
• [Gap 2]

RISKS:
• [Risk 1] - [Mitigation suggestion]

RECOMMENDATIONS:
1. [Specific recommendation]
2. [Specific recommendation]
3. [Specific recommendation]

VERDICT: [APPROVE / REQUEST CHANGES]
CONFIDENCE: [HIGH / MEDIUM / LOW]
REASONING: [1-2 sentences explaining verdict]
```

---

## Variable Substitution

| Variable | Source |
|----------|--------|
| `{PLAN_CONTENT}` | Contents of plan file or inline plan text |

---

## Provider-Specific Adjustments

### Claude
No adjustments - template works as-is.

### Codex
Add prefix: "You are reviewing code-related implementation plans. Focus on technical feasibility."

### Copilot
Add prefix: "Review this plan from a GitHub/development workflow perspective."

### Gemini
Add prefix: "Provide a comprehensive review considering multiple perspectives."

### Ollama
Simplify prompt slightly for smaller models - remove "council" context.

---

## Response Parsing

Expected response sections to parse:
1. `RATING:` line with number and justification
2. `GAPS:` bullet list
3. `RISKS:` bullet list with mitigations
4. `RECOMMENDATIONS:` numbered list
5. `VERDICT:` APPROVE or REQUEST CHANGES
6. `CONFIDENCE:` HIGH, MEDIUM, or LOW
7. `REASONING:` explanation

If a section is missing, mark as "NOT PROVIDED" in synthesis.
