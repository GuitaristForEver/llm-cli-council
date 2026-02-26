# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-01-28

### Added

- **Plugin Architecture**: Converted from skills-based installation to native Claude Code plugin
  - Plugin manifest with skill registry
  - Development marketplace for local testing
  - Proper namespacing (llm-cli-council:*)

- **Skills**:
  - `/llm-cli-council:setup` - Detect and configure LLM CLIs
  - `/llm-cli-council:status` - Display configuration and provider status
  - `/llm-cli-council:review-plan` - Council review of implementation plans
  - `/llm-cli-council:review-code` - Council review of code changes
  - `/llm-cli-council:uninstall` - Clean removal of configuration and rules

- **Global Delegation Rules**: Proactive delegation checking
  - Automatically installed to `~/.claude/rules/delegator/`
  - Triggers for high-stakes decisions
  - Multi-LLM orchestration patterns
  - Chairman synthesis strategy

- **Provider Support**:
  - Claude CLI (Anthropic)
  - Codex CLI (OpenAI)
  - Copilot CLI (GitHub)
  - Gemini CLI (Google)
  - Ollama (local LLMs)

- **Council Modes**:
  - `quick` - 2 providers for fast feedback (default)
  - `full` - All available providers for comprehensive review
  - `privacy` - Ollama only (no external API calls)

- **Documentation**:
  - Comprehensive README with installation and usage
  - TESTING.md with testing procedures
  - Plugin-based installation instructions

### Changed

- Migrated from shell script installation to plugin system
- Updated paths to use `CLAUDE_PLUGIN_ROOT` for portability
- Simplified installation: `claude /plugin install` instead of `./install.sh`

### Removed

- Legacy `install.sh` script (superseded by plugin installation)
- `src/` directory structure (migrated to plugin root)

## [Unreleased]

### Planned

- Hook-based integration for proactive council suggestions
- Automated testing with sample plans
- CI/CD pipeline for releases
- Example plans and code for testing
- Video demo/tutorial

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to contribute to this project.

## Acknowledgments

- [karpathy/llm-council](https://github.com/karpathy/llm-council) - Council orchestration concept
- [jarrodwatts/claude-delegator](https://github.com/jarrodwatts/claude-delegator) - Multi-model delegation patterns
