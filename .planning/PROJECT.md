# llm-cli-council

## What This Is

A Claude Code plugin that orchestrates multiple LLM CLIs (Claude, Copilot, Codex, Gemini, Ollama) to review implementation plans and code changes through a "council" approach. Claude acts as Chairman, synthesizing independent perspectives from multiple AI assistants into prioritized, actionable guidance with a decisive APPROVE/REQUEST CHANGES verdict.

## Core Value

Frictionless installation — a single `npx` command gets users from zero to their first council review in under 5 minutes.

## Requirements

### Validated

- ✓ Multi-provider orchestration (Claude, Copilot, Codex, Gemini, Ollama) — existing
- ✓ Three review modes: quick (2 providers), full (all), privacy (Ollama only) — existing
- ✓ Chairman synthesis: max 5 prioritized recommendations + APPROVE/REQUEST CHANGES verdict — existing
- ✓ Skills: setup, review-plan, review-code, status, uninstall — existing
- ✓ Cross-platform lib/platform-utils.sh — existing
- ✓ providers.json with task routing and defaults — existing
- ✓ Plugin manifest (.claude-plugin/plugin.json) — existing
- ✓ Test suite (tests/test-setup.sh) — existing

### Active

- [ ] npm/npx installer — `npx llm-cli-council` sets up the plugin in one command
- [ ] package.json — proper Node.js project for npm distribution
- [ ] bin/ — installer entry point
- [ ] scripts/ — utility scripts (uninstall, update, validate)
- [ ] docs/ — fill the 5 documented-but-missing guides (installation, configuration, provider-setup, troubleshooting, architecture)
- [ ] SECURITY.md — security policy
- [ ] .github/workflows/ — GitHub Actions: test on PR, release automation
- [ ] README CI badge — green passing-tests badge signals maintained project

### Out of Scope

- Web UI for review visualization — future roadmap, not v1.1 scope
- VS Code extension — future roadmap
- New providers beyond current 5 (Claude, Copilot, Codex, Gemini, Ollama) — defer to v2.0
- npm package for runtime use (vs. npm as installer distribution only) — separate concern

## Context

The plugin already works well technically. The gap vs. top-notch plugins like babysitter (a5c-ai/babysitter) and GSD (gsd-build/get-shit-done) is entirely about polish and infrastructure:
- babysitter: docs/, e2e-tests/, scripts/, active CI/CD (92 releases), monorepo structure
- GSD: .github/ Actions, bin/ installer, hooks/, scripts/, package.json, SECURITY.md, 20.9k stars

README already links to docs/ pages that don't exist yet (docs/installation.md, docs/configuration.md, docs/provider-setup.md, docs/troubleshooting.md, docs/architecture.md) — filling these closes an immediate credibility gap.

The original install.sh was removed in the refactor; npm/npx is the preferred replacement.

## Constraints

- **Distribution**: npm/npx as primary installer — no shell-only approach
- **Scope**: No new providers in this milestone — focus is infrastructure quality, not feature expansion
- **Compatibility**: Must remain a valid .claude-plugin/ installable plugin (plugin.json contract unchanged)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| npm/npx over curl\|bash for installer | More familiar to devs, handles deps, cleaner UX | — Pending |
| Fill existing docs/ links rather than rewrite README | README already has the right structure; docs 404 is the bug | — Pending |
| GitHub Actions before npm publish | CI green = confidence before public distribution | — Pending |

---
*Last updated: 2026-02-26 after initialization*
