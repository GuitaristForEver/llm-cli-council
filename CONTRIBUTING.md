# Contributing to LLM CLI Council

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing.

## Getting Started

### Prerequisites

- Claude Code CLI installed
- One or more LLM CLIs installed (Claude, Codex, Copilot, Gemini, or Ollama)
- Git for version control

### Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/GuitaristForEver/llm-cli-council.git
   cd llm-cli-council
   ```

2. **Add as local marketplace**
   ```bash
   claude /plugin marketplace add .
   ```

3. **Install from local marketplace**
   ```bash
   claude /plugin install llm-cli-council@llm-cli-council-dev
   ```

4. **Restart Claude Code** to load the plugin

5. **Run setup**
   ```bash
   /llm-cli-council:setup
   ```

## Making Changes

### Plugin Structure

```
llm-cli-council/
├── .claude-plugin/
│   ├── plugin.json         # Plugin manifest
│   └── marketplace.json    # Dev marketplace
├── skills/                 # Command skills
├── rules/                  # Delegation rules
├── prompts/                # Review templates
├── config/                 # Provider routing
└── lib/                    # Utility scripts
```

### Coding Guidelines

**Skills (Markdown files in `skills/`)**
- Use frontmatter with `name`, `description`, `invocable`
- Follow existing skill structure
- Document execution steps clearly
- Use `${CLAUDE_PLUGIN_ROOT}` for all paths

**Rules (Markdown files in `rules/`)**
- Keep rules focused and specific
- Document trigger conditions
- Avoid conflicting with other plugins

**Prompts (Markdown files in `prompts/`)**
- Use structured format for LLM consumption
- Include clear instructions and expected output
- Test with multiple providers

### Testing Changes

1. **Uninstall current version**
   ```bash
   /llm-cli-council:uninstall
   claude /plugin uninstall llm-cli-council@llm-cli-council-dev
   ```

2. **Reinstall with changes**
   ```bash
   claude /plugin install llm-cli-council@llm-cli-council-dev
   ```

3. **Restart Claude Code**

4. **Test affected commands**
   ```bash
   /llm-cli-council:setup
   /llm-cli-council:status
   # Test review commands with sample files
   ```

## Submitting Changes

### Pull Request Process

1. **Fork the repository** on GitHub

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes** following the guidelines above

4. **Test thoroughly** - Ensure all skills work as expected

5. **Update documentation**
   - Update README.md if adding features
   - Add entry to CHANGELOG.md
   - Update skill documentation if changing behavior

6. **Commit with conventional commits**
   ```bash
   git commit -m "feat: add new feature"
   git commit -m "fix: resolve issue with X"
   git commit -m "docs: update README"
   ```

7. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

8. **Open a Pull Request** on GitHub
   - Describe what changed and why
   - Reference any related issues
   - Include testing steps

### Commit Convention

We use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `refactor:` - Code refactoring
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks

## Adding New Providers

To add support for a new LLM CLI:

1. **Add provider detection** in `skills/setup.md`
   ```bash
   which new-llm-cli
   new-llm-cli --version
   # Auth test
   ```

2. **Add provider config** in `config/providers.json`
   ```json
   {
     "new-provider": {
       "taskRouting": {
         "plan-review": 3,
         "code-review": 2
       }
     }
   }
   ```

3. **Add invocation pattern** in setup skill
   ```json
   "new-provider": {
     "invocation": "new-llm-cli execute \"{prompt}\""
   }
   ```

4. **Test with multiple review types**

5. **Update documentation** in README.md

## Reporting Issues

### Bug Reports

Include:
- Claude Code version
- LLM CLI versions
- Steps to reproduce
- Expected vs actual behavior
- Error messages (if any)

### Feature Requests

Describe:
- The problem you're trying to solve
- Proposed solution
- Alternative approaches considered
- Impact on existing functionality

## Questions?

- Open an issue on GitHub
- Tag it with `question` label
- We'll respond as soon as possible

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow
- Assume good intentions

Thank you for contributing! 🎉
