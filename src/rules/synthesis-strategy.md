# Synthesis Strategy Rules

These rules govern how Claude (as Chairman) synthesizes multiple provider reviews into unified guidance.

---

## Anti-Paralysis Mandate

The council exists to **clarify**, not **confuse**. Every synthesis must:

1. **Resolve conflicts** - Never present contradictions without resolution
2. **Prioritize clearly** - Numbered list, most important first
3. **Limit scope** - Maximum 5 recommendations
4. **Decide definitively** - Clear APPROVE or REQUEST CHANGES, never "maybe"
5. **Explain reasoning** - Users should understand WHY

---

## Categorization Framework

### CONSENSUS
Points where 2+ providers agree (explicitly or implicitly).

Identification:
- Same issue mentioned by multiple providers
- Same recommendation (even if worded differently)
- Same verdict

Handling:
- Present as established fact
- High confidence in these points
- List provider count: "All 3 agree" or "2 of 3 agree"

### CONCERNS
Points raised by at least one provider that merit attention.

Identification:
- Valid technical concern
- Risk or gap not addressed elsewhere
- Reasonable recommendation

Handling:
- Present with attribution: "Raised by: [Provider]"
- Include Chairman assessment of validity/priority
- Don't dismiss single-provider concerns automatically

### DISSENT
Where providers explicitly disagree.

Identification:
- Opposite verdicts (APPROVE vs REQUEST CHANGES)
- Contradictory recommendations
- Different assessments of same issue

Handling:
- Present both positions clearly
- Chairman MUST resolve with reasoning
- Never leave user to decide between contradictions

---

## Conflict Resolution

### Verdict Disagreement

**Majority Rule (2+ providers agree):**
```
PROVIDER VERDICTS:
  Claude: APPROVE (HIGH)
  Codex: REQUEST CHANGES (MEDIUM)
  Gemini: APPROVE (HIGH)

FINAL VERDICT: APPROVE
Reasoning: 2 of 3 providers approve with high confidence.
Codex's concerns are valid but addressed in recommendations.
```

**Tie (equal split):**
Apply task-type weighting:
- Code plans: Codex, Copilot weighted higher
- Architecture plans: Claude weighted higher
- General plans: Equal weight, Chairman decides

```
PROVIDER VERDICTS:
  Claude: APPROVE (HIGH)
  Codex: REQUEST CHANGES (HIGH)

FINAL VERDICT: REQUEST CHANGES
Reasoning: For code-heavy plans, Codex's concerns carry more weight.
The testing gap they identified is significant.
```

### Recommendation Conflict

When providers recommend opposite actions:

1. **Evaluate merit** - Which recommendation is better reasoned?
2. **Consider context** - Which fits the project better?
3. **Pick one** - Present the chosen recommendation
4. **Explain** - Brief note on why this over the alternative

```
DISSENTING VIEWS:
• Deployment: Claude recommends blue-green, Codex recommends canary
  Resolution: Blue-green deployment. Simpler for current team size,
  and the plan doesn't require gradual rollout capabilities.
```

---

## Weighting by Task Type

### Plan Review Weights

| Provider | Architecture | Code-heavy | General |
|----------|--------------|------------|---------|
| Claude | 1.5x | 1.0x | 1.0x |
| Codex | 1.2x | 1.5x | 1.0x |
| Copilot | 0.8x | 1.3x | 1.0x |
| Gemini | 1.0x | 0.8x | 1.2x |
| Ollama | 0.8x | 0.8x | 0.8x |

Apply weighting to:
- Verdict tie-breaking
- Recommendation prioritization (weighted votes)
- Confidence assessment

### Code Review Weights

| Provider | Security | Performance | Style |
|----------|----------|-------------|-------|
| Claude | 1.2x | 1.0x | 1.0x |
| Codex | 1.3x | 1.3x | 1.2x |
| Copilot | 1.0x | 1.2x | 1.5x |
| Gemini | 1.0x | 0.8x | 0.8x |
| Ollama | 0.8x | 0.8x | 0.8x |

---

## Recommendation Prioritization

### Priority Factors

1. **Consensus weight** - More providers = higher priority
2. **Severity** - Blockers before nice-to-haves
3. **Effort** - Quick wins before large efforts (when equal severity)
4. **Provider expertise** - Weight by task type

### Priority Algorithm

```
For each unique recommendation:
  score = 0

  # Consensus bonus
  score += (provider_count - 1) * 2

  # Severity (from recommendation wording)
  if "must" or "critical" or "blocker": score += 3
  if "should" or "important": score += 2
  if "could" or "consider": score += 1

  # Expertise weight
  score *= task_weight[provider][task_type]

Sort by score descending
Take top 5
```

### Effort Estimation

Standardize provider effort estimates to:
- **Quick**: < 1 hour of work
- **Short**: 1-4 hours
- **Medium**: 1-2 days
- **Large**: 3+ days

If providers disagree on effort, use highest estimate (conservative).

---

## Output Structure

### Required Sections

1. **Header** - Mode, providers consulted
2. **CONSENSUS** - Points all/most agree on
3. **CONCERNS** - Valid points from any provider
4. **DISSENT** - Conflicts with resolution
5. **RECOMMENDATIONS** - Max 5, prioritized
6. **VERDICTS** - Each provider's verdict
7. **FINAL VERDICT** - Chairman's decision

### Optional Sections

- **WARNINGS** - If quorum not met or responses malformed
- **NOTES** - Additional context Chairman deems relevant

---

## Quality Gates

Before presenting synthesis, verify:

- [ ] No more than 5 recommendations
- [ ] All dissent has resolution (no "user should decide")
- [ ] Final verdict is binary (APPROVE or REQUEST CHANGES)
- [ ] Reasoning references specific provider input
- [ ] No raw provider output passed through unchanged
- [ ] Effort estimates are standardized

If any gate fails, fix before presenting.

---

## Edge Cases

### Single Provider Response
```
NOTE: Only [Provider] responded. This lacks council diversity.

[Present provider's review directly with minimal synthesis]

Consider: Run with --mode=full for comprehensive feedback.
```

### All Approve, No Recommendations
```
UNANIMOUS APPROVAL

All providers approve this plan without significant concerns.

Minor suggestions (for consideration, not required):
[List any minor points mentioned]
```

### All Request Changes
```
STRONG CONSENSUS: Changes Required

All providers identified issues requiring attention.
Critical items are prioritized below.

[Prioritized recommendations - may exceed 5 for critical issues]
```
