---
name: uninstall
description: Remove council configuration and optionally the skill files
invocable: true
---

# LLM CLI Council - Uninstall

This command removes the council configuration and provides options for complete cleanup.

## Usage

```
/llm-cli-council:uninstall [--full]
```

### Arguments

| Argument | Description |
|----------|-------------|
| `--full` | Also remove skill files (complete uninstall) |

---

## Execution Flow

### Step 1: Confirm Uninstall

```
LLM CLI Council Uninstall
═══════════════════════════════════════════════════════

This will remove:
• Configuration: $COUNCIL_CONFIG_FILE
• Logs (if any): $COUNCIL_LOG_DIR

The skill files will remain unless --full is specified.

Proceed with uninstall? [y/N]
```

### Step 2: Remove Configuration

```bash
rm -f $COUNCIL_CONFIG_FILE
rm -rf $COUNCIL_LOG_DIR
```

### Step 3: Full Uninstall (if --full)

```
Full uninstall requested.

This will ALSO remove:
• Skill directory: $SKILLS_DIR/llm-cli-council/

Are you sure? This cannot be undone. [y/N]
```

If confirmed:
```bash
rm -rf $SKILLS_DIR/llm-cli-council/
```

### Step 4: Confirm Completion

```
LLM CLI Council - Uninstalled
═══════════════════════════════════════════════════════

Removed:
✓ Configuration file
✓ Log directory
[✓ Skill files (--full)]

The underlying CLI tools (claude, codex, copilot, etc.)
were NOT modified. They remain available for direct use.

To reinstall:
1. Copy skill files to $SKILLS_DIR/llm-cli-council/
2. Run /llm-cli-council:setup
```

---

## What Gets Removed

### Standard Uninstall

| Item | Path | Description |
|------|------|-------------|
| Config | `$COUNCIL_CONFIG_FILE` | Provider settings, preferences |
| Logs | `$COUNCIL_LOG_DIR` | Review history (if logging enabled) |

### Full Uninstall (--full)

| Item | Path | Description |
|------|------|-------------|
| Skill | `$SKILLS_DIR/llm-cli-council/` | All skill files |

---

## What Is NOT Removed

The uninstall does NOT affect:

- Individual CLI tools (claude, codex, copilot, gemini, ollama)
- CLI authentication/credentials
- Other Claude Code skills
- Global Claude Code configuration

---

## Re-installation

After uninstalling, to reinstall:

### If skill files remain (standard uninstall):
```
/llm-cli-council:setup
```

### If skill files removed (--full uninstall):
1. Re-download/copy skill files to `$SKILLS_DIR/llm-cli-council/`
2. Run `/llm-cli-council:setup`

---

## Error Handling

### Config Not Found
```
No council configuration found.
Nothing to uninstall.

If you want to remove skill files:
  rm -rf $SKILLS_DIR/llm-cli-council/
```

### Permission Error
```
Error: Permission denied removing configuration.
Manual cleanup required:
  rm $COUNCIL_CONFIG_FILE
  rm -rf $COUNCIL_LOG_DIR
```

---

## Dry Run

To see what would be removed without actually removing:

```
/llm-cli-council:uninstall --dry-run

Would remove:
• $COUNCIL_CONFIG_FILE (exists, 2.1KB)
• $COUNCIL_LOG_DIR (exists, 15 files)

Add --full to also remove:
• $SKILLS_DIR/llm-cli-council/ (exists, 12 files)

No changes made (dry run).
```
