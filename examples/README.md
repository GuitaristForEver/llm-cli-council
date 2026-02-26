# Examples

Sample files for testing llm-cli-council functionality.

## Files

### sample-plan.md

A sample implementation plan for an authentication system. Includes:
- Multiple tasks with clear descriptions
- Security considerations
- Architecture decisions that need review
- Potential issues to catch

**Test with:**
```bash
/llm-cli-council:review-plan examples/sample-plan.md
```

**Expected council feedback:**
- Identify missing requirements (rate limiting, email verification)
- Suggest improvements to security approach
- Highlight potential issues with session management
- Provide guidance on architecture decisions

### sample-code.ts

A sample TypeScript authentication endpoint with intentional security issues. Includes:
- SQL injection vulnerability
- Hardcoded secrets
- Missing input validation
- Exposed sensitive data
- No rate limiting
- Poor error handling

**Test with:**
```bash
/llm-cli-council:review-code examples/sample-code.ts
```

**Expected council feedback:**
- Identify all security vulnerabilities
- Suggest proper input validation
- Recommend environment variable usage
- Point out missing httpOnly cookies
- Highlight exposed password hash
- Suggest rate limiting implementation

## Using These Examples

### Quick Test

After setting up the council:

```bash
# Setup if not done
/llm-cli-council:setup

# Test plan review
/llm-cli-council:review-plan examples/sample-plan.md

# Test code review
/llm-cli-council:review-code examples/sample-code.ts
```

### Comparing Modes

Test different council modes to see coverage differences:

```bash
# Quick mode (2 providers)
/llm-cli-council:review-plan examples/sample-plan.md --mode=quick

# Full mode (all providers)
/llm-cli-council:review-plan examples/sample-plan.md --mode=full

# Privacy mode (local only)
/llm-cli-council:review-plan examples/sample-plan.md --mode=privacy
```

### What to Look For

**Good council output shows:**
- ✅ Clear consensus on obvious issues
- ✅ Multiple perspectives on architecture decisions
- ✅ Prioritized list of concerns (not overwhelming)
- ✅ Specific, actionable recommendations
- ✅ Clear APPROVE/REQUEST CHANGES verdict

**Red flags (shouldn't happen):**
- ❌ Conflicting recommendations without resolution
- ❌ Vague feedback ("consider best practices")
- ❌ More than 5 top-level recommendations
- ❌ No clear verdict

## Creating Your Own Test Cases

To test with your own files:

1. **For plans:** Create a markdown file with your implementation plan
2. **For code:** Use any source file from your project

The council works with:
- Any markdown file for plan reviews
- Any code file (`.ts`, `.js`, `.py`, `.go`, etc.) for code reviews

## Troubleshooting

**No providers available:**
```bash
/llm-cli-council:status
/llm-cli-council:setup
```

**Provider authentication failed:**
Check individual CLI authentication:
```bash
claude --version && echo "Claude OK"
codex --version && echo "Codex OK"
# etc.
```

**Slow reviews:**
- Try `--mode=quick` (uses 2 providers instead of all)
- Check network connectivity
- Verify providers aren't rate-limited

## Contributing Examples

Have a good test case? Contributions welcome!

1. Create a new example file
2. Add description to this README
3. Include expected council behavior
4. Submit a PR

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.
