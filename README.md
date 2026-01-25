# LLM CLI Council

> **Get diverse AI perspectives on your implementation plans and code reviews**

A Claude Code skill that orchestrates multiple LLM command-line tools (Claude, Copilot, Codex, Gemini, Ollama) to provide comprehensive feedback through a "council" approach. Claude acts as Chairman, synthesizing insights from multiple AI assistants into clear, actionable guidance.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-blue)](https://github.com/username/llm-cli-council)

> **Inspired by:** [karpathy/llm-council](https://github.com/karpathy/llm-council) for the council orchestration concept and [jarrodwatts/claude-delegator](https://github.com/jarrodwatts/claude-delegator) for multi-model delegation patterns.

---

## Why Use a Council?

Single LLMs can be biased toward certain solutions. By consulting multiple AI assistants:

- **🎯 Diverse perspectives** catch blind spots and assumptions
- **✅ Consensus** builds confidence in recommendations
- **⚠️ Dissent** highlights areas needing careful consideration
- **📊 Better coverage** different models excel at different tasks

### The Anti-Paralysis Principle

The council **never overwhelms** with conflicting advice. Instead, it:

- ✨ Synthesizes into **max 5 prioritized recommendations**
- 🎓 Resolves conflicts with **clear reasoning**
- ✅ Always provides a **decisive verdict**: APPROVE or REQUEST CHANGES

No endless debate. Just actionable guidance.

---

## Features

- 🤝 **Multi-LLM orchestration** - Coordinates Claude, Copilot, Codex, Gemini, and Ollama
- 🎭 **Independent reviews** - Each provider reviews without seeing others' opinions
- ⚡ **Parallel execution** - All providers run simultaneously for speed
- 🪑 **Chairman synthesis** - Claude resolves conflicts and provides final verdict
- 🔒 **Privacy mode** - Local-only execution with Ollama (no data leaves your machine)
- 📈 **Smart routing** - Automatically selects best providers for each task type
- 🔧 **Configurable modes** - Quick (2 providers), Full (all providers), or Privacy (local only)
- 🌍 **Cross-platform** - Works on macOS, Linux, and Windows (WSL)

---

## Quick Start

Get your first council review in **5 minutes**:

```bash
# 1. Install (choose one method)

# Method A: Git clone
git clone https://github.com/GuitaristForEver/llm-cli-council.git
cd llm-cli-council
./install.sh

# Method B: One-line install
curl -fsSL https://raw.githubusercontent.com/GuitaristForEver/llm-cli-council/main/install.sh | bash

# 2. Detect your LLM CLI tools
/llm-cli-council:setup

# 3. Review a plan
/llm-cli-council:review-plan PLAN.md
```

That's it! You'll get synthesized feedback from multiple AI perspectives.

---

## Installation

### Method 1: Git Clone (Recommended)

```bash
# Clone repository
git clone https://github.com/GuitaristForEver/llm-cli-council.git
cd llm-cli-council

# Run installer
./install.sh

# Verify installation
/llm-cli-council:status
```

### Method 2: One-Line Install

```bash
curl -fsSL https://raw.githubusercontent.com/GuitaristForEver/llm-cli-council/main/install.sh | bash
```

### Method 3: Custom Installation Path

```bash
# Install to specific directory
./install.sh --skills-dir ~/.local/share/claude/skills

# With custom config directory
CLAUDE_COUNCIL_CONFIG_DIR=~/my-config ./install.sh
```

### Installation Options

| Flag | Description |
|------|-------------|
| `--yes`, `-y` | Auto-confirm all prompts |
| `--skills-dir DIR` | Install to custom skills directory |
| `--dry-run` | Preview installation without making changes |
| `--verbose`, `-v` | Show detailed installation progress |
| `--help`, `-h` | Display help message |

---

## Available Commands

| Command | Description |
|---------|-------------|
| `/llm-cli-council:setup` | Detect and configure available LLM CLIs |
| `/llm-cli-council:review-plan` | Get council review of an implementation plan |
| `/llm-cli-council:review-code` | Get council review of code changes |
| `/llm-cli-council:status` | Show council configuration and provider status |
| `/llm-cli-council:uninstall` | Remove council configuration |

---

## Basic Usage

### Review an Implementation Plan

```bash
# Review with default (quick) mode - 2 best providers
/llm-cli-council:review-plan

# Review specific plan file
/llm-cli-council:review-plan path/to/PLAN.md

# Use all available providers (comprehensive review)
/llm-cli-council:review-plan --mode=full

# Privacy mode - only local Ollama (no data sent externally)
/llm-cli-council:review-plan --mode=privacy
```

### Review Code Changes

```bash
# Review staged changes
/llm-cli-council:review-code

# Review last commit
/llm-cli-council:review-code HEAD

# Review specific file
/llm-cli-council:review-code src/app.js

# Review range of commits
/llm-cli-council:review-code main..HEAD --mode=full
```

### Check Configuration

```bash
# Show current configuration
/llm-cli-council:status

# Re-check provider availability
/llm-cli-council:status --check
```

---

## Council Modes

The council operates in three modes, each balancing speed, comprehensiveness, and privacy:

| Mode | Providers Used | Use Case | Speed |
|------|----------------|----------|-------|
| **quick** (default) | 2 best-match providers | Most reviews, fast feedback | ⚡⚡⚡ Fast |
| **full** | All available providers | High-stakes decisions, comprehensive analysis | ⚡⚡ Slower |
| **privacy** | Ollama only | Sensitive code, air-gapped environments | ⚡⚡⚡ Fast |

**Mode selection example:**

```bash
# Quick mode (default) - 2 providers, ~30-60 seconds
/llm-cli-council:review-plan

# Full mode - all providers, ~60-120 seconds
/llm-cli-council:review-plan --mode=full

# Privacy mode - local only, ~30-90 seconds
/llm-cli-council:review-plan --mode=privacy
```

---

## Supported Providers

The council supports the following LLM CLI tools:

| Provider | CLI Command | Installation | Strengths |
|----------|-------------|--------------|-----------|
| **Claude** | `claude` | [Claude Code](https://github.com/anthropics/claude-code) | Reasoning, analysis, synthesis, planning |
| **Copilot** | `copilot` | `npm install -g @github/copilot-cli` | Code generation, GitHub integration |
| **Codex** | `codex` | [OpenAI Codex CLI](https://github.com/openai/codex-cli) | Code analysis, debugging, implementation |
| **Gemini** | `gemini` | [Gemini CLI](https://github.com/google/gemini-cli) | Multimodal analysis, broad knowledge |
| **Ollama** | `ollama` | [Ollama](https://ollama.ai) | Privacy, offline, local execution |

**Minimum requirement:** At least **2 providers** for meaningful council feedback.
**Recommendation:** Install 3-5 providers for diverse perspectives.

### Provider Setup

Each provider requires separate installation and authentication:

1. **Install the CLI tool** (see links above)
2. **Authenticate** (follow provider-specific instructions)
3. **Run setup:** `/llm-cli-council:setup`
4. **Verify:** `/llm-cli-council:status`

For detailed setup instructions, see [Provider Setup Guide](docs/provider-setup.md).

---

## Configuration

The council uses environment variables for flexible configuration:

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_COUNCIL_CONFIG_DIR` | `~/.config/claude/council/` | Config directory location |
| `CLAUDE_COUNCIL_CONFIG_FILE` | `$CONFIG_DIR/config.json` | Specific config file override |
| `CLAUDE_COUNCIL_LOG_DIR` | `$CONFIG_DIR/logs/` | Log directory |
| `CLAUDE_SKILLS_DIR` | `~/.claude/skills/` | Skills installation directory |
| `CLAUDE_CONFIG_DIR` | `~/.claude/` | Claude's main config directory |

### Path Resolution Priority

When locating configuration, the council checks in this order:

1. `$CLAUDE_COUNCIL_CONFIG_DIR` (explicit override)
2. `$CLAUDE_CONFIG_DIR/council/` (Claude config + council subdir)
3. `$XDG_CONFIG_HOME/claude/council/` (XDG standard on Linux)
4. `~/.config/claude/council/` (XDG fallback)
5. `~/.claude/council/` (legacy compatibility)

### Configuration File

After running setup, your configuration is stored at `$COUNCIL_CONFIG_FILE`:

```json
{
  "version": "1.0.0",
  "providers": {
    "claude": {
      "available": true,
      "path": "/usr/local/bin/claude",
      "authenticated": true
    },
    "codex": {
      "available": true,
      "path": "/usr/local/bin/codex",
      "authenticated": true
    }
  },
  "defaultMode": "quick"
}
```

For detailed configuration options, see [Configuration Guide](docs/configuration.md).

---

## How It Works

The council uses a **three-stage deliberation process**:

```
┌─────────────────────────────────────────────────────────┐
│ Stage 1: Independent Review                            │
├─────────────────────────────────────────────────────────┤
│ • Execute prompts in parallel across providers          │
│ • Each provider reviews independently                   │
│ • No cross-contamination of opinions                    │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ Stage 2: Collection & Analysis                         │
├─────────────────────────────────────────────────────────┤
│ • Gather all provider responses                         │
│ • Extract key recommendations                           │
│ • Identify consensus and dissent                        │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ Stage 3: Chairman Synthesis (Claude)                   │
├─────────────────────────────────────────────────────────┤
│ • Synthesize into max 5 prioritized recommendations     │
│ • Resolve conflicts with clear reasoning                │
│ • Provide decisive verdict: APPROVE / REQUEST CHANGES   │
└─────────────────────────────────────────────────────────┘
```

### Why Claude as Chairman?

Claude serves as Chairman because:
- **Context retention** - Best at synthesizing multiple perspectives
- **Reasoning depth** - Excels at explaining trade-offs and resolutions
- **Clarity** - Provides decisive, actionable guidance without paralysis

---

## Examples

### Example: Plan Review Output

```
╔═══════════════════════════════════════════════════════╗
║ LLM CLI COUNCIL REVIEW                                ║
║ Plan: Implementation Plan for Feature X               ║
║ Mode: quick (2 providers)                            ║
╚═══════════════════════════════════════════════════════╝

VERDICT: REQUEST CHANGES

COUNCIL SYNTHESIS
─────────────────────────────────────────────────────────

Consensus (2/2 providers agree):
✓ Overall approach is sound and well-structured
✓ Clear separation of concerns
✗ Missing error handling strategy
✗ No consideration of database migration

TOP 5 RECOMMENDATIONS (Prioritized):

1. [CRITICAL] Add Database Migration Strategy
   • Plan lacks migration approach for schema changes
   • Risk: Data loss during deployment
   • Suggested: Add migration rollback plan in Phase 2

2. [HIGH] Define Error Handling Approach
   • No consistent error handling across services
   • Both reviewers flagged this independently
   • Suggested: Establish error handling patterns upfront

3. [MEDIUM] Add Performance Benchmarks
   • Consider load testing before production
   • Codex suggests: Define acceptable latency targets

4. [MEDIUM] Clarify Testing Strategy
   • Integration tests mentioned but not detailed
   • Suggested: Specify test coverage goals per phase

5. [LOW] Documentation Plan
   • Consider API documentation approach
   • Minor issue, can be addressed later

REASONING:
Database migration and error handling are architectural
decisions that affect all subsequent phases. Addressing
these upfront prevents costly refactoring later. The plan
is otherwise well-structured—these additions will make it
production-ready.
```

See more examples in the [examples/](examples/) directory.

---

## Troubleshooting

### Common Issues

#### "Council not configured"

**Solution:** Run `/llm-cli-council:setup` to detect providers.

#### "No providers available"

**Cause:** No LLM CLI tools detected.

**Solution:**
1. Install at least 2 providers (see [Supported Providers](#supported-providers))
2. Ensure they're in your `PATH`
3. Run `/llm-cli-council:setup` again

#### "Provider authentication failed"

**Cause:** Provider CLI not authenticated.

**Solution:**
- **Claude:** `claude auth login`
- **Copilot:** `copilot auth login`
- **Codex:** `codex auth`
- **Gemini:** `gemini auth login`
- **Ollama:** No auth needed (ensure models downloaded: `ollama pull model-name`)

#### Timeout errors

**Cause:** Provider taking too long to respond.

**Solution:**
- Check network connection
- Try `--mode=privacy` if network is slow
- Increase timeout in config (advanced)

For more troubleshooting, see [Troubleshooting Guide](docs/troubleshooting.md).

---

## Documentation

Comprehensive documentation is available in the `docs/` directory:

- **[Installation Guide](docs/installation.md)** - Detailed installation instructions
- **[Configuration Reference](docs/configuration.md)** - All configuration options explained
- **[Provider Setup](docs/provider-setup.md)** - Step-by-step setup for each provider
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions
- **[Architecture](docs/architecture.md)** - How the council works internally

---

## Contributing

We welcome contributions! Here's how you can help:

### Ways to Contribute

- 🐛 **Report bugs** - Open an issue with reproduction steps
- 💡 **Suggest features** - Share your ideas in discussions
- 📝 **Improve docs** - Fix typos, add examples, clarify instructions
- 🔧 **Add providers** - Support additional LLM CLI tools
- ✨ **Submit PRs** - Fix bugs or implement features

### Development Setup

```bash
# Clone repository
git clone https://github.com/GuitaristForEver/llm-cli-council.git
cd llm-cli-council

# Install development version
./install.sh --skills-dir ~/.claude/skills-dev

# Make changes to src/

# Test your changes
/llm-cli-council:status
/llm-cli-council:review-plan test/fixtures/sample-plan.md

# Run tests (if available)
./tests/test-setup.sh
```

### Adding a New Provider

See [CONTRIBUTING.md](CONTRIBUTING.md) for step-by-step instructions on adding support for new LLM CLI tools.

---

## Roadmap

### v1.1.0 (Next Release)

- [ ] GitHub Action for automated PR reviews
- [ ] Customizable provider weights and priorities
- [ ] Review history and analytics
- [ ] Support for custom prompt templates

### Future

- [ ] Web UI for review visualization
- [ ] Docker container with pre-installed providers
- [ ] VS Code extension
- [ ] npm package distribution
- [ ] Multi-language support

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- **Anthropic** for Claude and Claude Code CLI
- **GitHub** for Copilot CLI
- **OpenAI** for Codex
- **Google** for Gemini
- **Ollama** team for local LLM infrastructure

Special thanks to the open source community for feedback and contributions.

---

## Support

- **Issues:** [GitHub Issues](https://github.com/username/llm-cli-council/issues)
- **Discussions:** [GitHub Discussions](https://github.com/username/llm-cli-council/discussions)
- **Documentation:** [docs/](docs/)

---

**Built with ❤️ for developers who value diverse perspectives**
