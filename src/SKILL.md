---
name: llm-cli-council
description: Orchestrate multiple LLM CLIs (Claude, Copilot, Codex, Gemini, Ollama) as a "council" to provide diverse perspectives on plans and code
version: 1.0.0
author: LLM CLI Council
---

# LLM CLI Council

A Claude Code skill that leverages multiple LLM command-line tools to provide diverse perspectives through a "council" approach. Claude acts as Chairman, synthesizing insights from multiple AI assistants into clear, actionable guidance.

## Why Use a Council?

Single LLMs can be biased toward certain solutions. By consulting multiple AI assistants:
- **Diverse perspectives** catch blind spots
- **Consensus** builds confidence in recommendations
- **Dissent** highlights areas needing careful consideration

## Anti-Paralysis Principle

The council NEVER overwhelms with conflicting advice. Instead, it:
- Synthesizes into max 5 prioritized recommendations
- Resolves conflicts with clear reasoning
- Always provides a decisive APPROVE/REQUEST CHANGES verdict

## Available Commands

| Command | Description |
|---------|-------------|
| `/llm-cli-council:setup` | Detect and configure available LLM CLIs |
| `/llm-cli-council:review-plan` | Get council review of a plan |
| `/llm-cli-council:review-code` | Get council review of code changes |
| `/llm-cli-council:status` | Show council configuration and provider status |
| `/llm-cli-council:uninstall` | Remove council configuration |

## Council Modes

| Mode | Providers Used | Use Case |
|------|----------------|----------|
| `quick` (default) | 2 best-match providers | Most reviews, fast feedback |
| `full` | All available providers | High-stakes decisions |
| `privacy` | Ollama only | Sensitive code, no data leaves machine |

## Supported Providers

- **Claude** (`claude`) - Anthropic's CLI
- **Copilot** (`copilot`) - GitHub Copilot CLI
- **Codex** (`codex`) - OpenAI Codex CLI
- **Gemini** (`gemini`) - Google Gemini CLI
- **Ollama** (`ollama`) - Local LLM runner

## Configuration

The council uses environment variables for flexible path configuration:

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_COUNCIL_CONFIG_DIR` | `~/.config/claude/council/` | Config directory location |
| `CLAUDE_COUNCIL_CONFIG_FILE` | `$COUNCIL_CONFIG_DIR/config.json` | Specific config file |
| `CLAUDE_COUNCIL_LOG_DIR` | `$COUNCIL_CONFIG_DIR/logs/` | Log directory |
| `CLAUDE_SKILLS_DIR` | `~/.claude/skills/` | Skills installation directory |
| `CLAUDE_CONFIG_DIR` | `~/.claude/` | Claude's main config directory |

**Path Resolution Priority:**
1. `$CLAUDE_COUNCIL_CONFIG_DIR` (explicit override)
2. `$CLAUDE_CONFIG_DIR/council/` (Claude config + council subdir)
3. `$XDG_CONFIG_HOME/claude/council/` (XDG standard on Linux)
4. `~/.config/claude/council/` (XDG fallback)
5. `~/.claude/council/` (legacy compatibility)

## Quick Start

1. Run `/llm-cli-council:setup` to detect available CLIs
2. Run `/llm-cli-council:review-plan` on your PLAN.md
3. Receive synthesized council feedback with clear recommendations

## Usage Examples

```
# Review current plan with 2 providers (quick mode)
/llm-cli-council:review-plan

# Full council review with all providers
/llm-cli-council:review-plan --mode=full

# Privacy mode - only local Ollama
/llm-cli-council:review-plan --mode=privacy

# Review specific file
/llm-cli-council:review-plan path/to/plan.md
```

## How It Works

```
Stage 1: Independent Review
├── Execute prompts in parallel across providers
├── Each provider reviews independently
└── No cross-contamination of opinions

Stage 2: Collect & Analyze
├── Gather all responses
├── Identify: CONSENSUS | CONCERNS | DISSENT
└── Weight responses by domain expertise

Stage 3: Chairman Synthesis (Claude)
├── Resolve conflicts with reasoning
├── Create max 5 prioritized recommendations
├── Provide clear APPROVE/REQUEST CHANGES verdict
└── Present unified guidance
```

## Configuration

Council configuration is stored in `~/.claude/council-config.json` after running setup.

## Rules

The council follows strict rules defined in:
- `rules/council-orchestration.md` - How to coordinate multiple LLMs
- `rules/synthesis-strategy.md` - How to merge conflicting opinions
- `rules/triggers.md` - When to automatically invoke council
