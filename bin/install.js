#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');
const os = require('os');

/**
 * Detect the Claude Code base directory.
 * Priority: CLAUDE_DIR env > CLAUDE_SKILLS_DIR parent > ~/.claude
 */
function detectClaudeDir() {
  if (process.env.CLAUDE_DIR) {
    return process.env.CLAUDE_DIR;
  }
  if (process.env.CLAUDE_SKILLS_DIR) {
    // CLAUDE_SKILLS_DIR points to skills/ subdirectory — parent is claude dir
    return path.dirname(process.env.CLAUDE_SKILLS_DIR);
  }
  return path.join(os.homedir(), '.claude');
}

/**
 * Ensure a directory exists, creating it and all parents if needed.
 */
function ensureDirExists(dirPath) {
  fs.mkdirSync(dirPath, { recursive: true });
}

/**
 * Map of plugin files/dirs to install.
 * src: path relative to package root (where install.js lives, i.e., __dirname + '/..')
 * dest: path relative to claudeDir
 * type: 'dir' copies entire directory recursively; 'file' copies single file
 */
const FILE_MAP = [
  { src: 'skills',                dest: 'skills',               type: 'dir'  },
  { src: 'lib',                   dest: 'lib',                  type: 'dir'  },
  { src: 'prompts',               dest: 'prompts',              type: 'dir'  },
  { src: 'rules',                 dest: 'rules',                type: 'dir'  },
  { src: 'config/providers.json', dest: 'config/providers.json', type: 'file' },
];

/**
 * Copy all plugin files to claudeDir.
 * @param {string} claudeDir - Target base directory
 * @param {boolean} dryRun   - If true, log what would happen without copying
 * @returns {string[]}       - List of files/dirs installed (for progress reporting)
 */
function copyFiles(claudeDir, dryRun) {
  const pkgRoot = path.join(__dirname, '..');
  const installed = [];

  for (const entry of FILE_MAP) {
    const srcPath  = path.join(pkgRoot, entry.src);
    const destPath = path.join(claudeDir, entry.dest);

    if (dryRun) {
      installed.push(destPath);
      continue;
    }

    // Ensure parent directory exists
    ensureDirExists(path.dirname(destPath));

    if (entry.type === 'dir') {
      // fs.cpSync with recursive:true (Node 18+) — do NOT hand-roll recursive copy
      fs.cpSync(srcPath, destPath, { recursive: true });
    } else {
      fs.copyFileSync(srcPath, destPath);
    }

    installed.push(destPath);
  }

  return installed;
}

/**
 * List of files (relative to claudeDir) that need chmod 755 after install.
 * Shell scripts must be executable — fs.cpSync preserves source permissions
 * on Linux but may not on all systems, so we set explicitly.
 */
const CHMOD_EXEC_FILES = [
  'lib/platform-utils.sh',
];

/**
 * Set executable permission on shell scripts.
 * @param {string} claudeDir - Base Claude directory
 * @param {boolean} dryRun   - If true, skip chmod
 */
function chmodExec(claudeDir, dryRun) {
  if (dryRun) return;
  for (const relPath of CHMOD_EXEC_FILES) {
    const fullPath = path.join(claudeDir, relPath);
    if (fs.existsSync(fullPath)) {
      fs.chmodSync(fullPath, 0o755);
    }
  }
}

/**
 * Parse process.argv for supported flags.
 * @returns {{ dryRun: boolean, yes: boolean, help: boolean }}
 */
function parseArgs(argv) {
  return {
    dryRun: argv.includes('--dry-run'),
    yes:    argv.includes('--yes') || argv.includes('-y'),
    help:   argv.includes('--help') || argv.includes('-h'),
  };
}

/**
 * Print usage information and exit.
 */
function printHelp() {
  const pkg = require('../package.json');
  console.log('');
  console.log('llm-cli-council v' + pkg.version + ' — installer');
  console.log('');
  console.log('Usage:');
  console.log('  npx llm-cli-council [options]');
  console.log('');
  console.log('Options:');
  console.log('  --dry-run   Show what would be installed without installing');
  console.log('  --yes, -y   Skip confirmation prompt');
  console.log('  --help, -h  Show this help message');
  console.log('');
  console.log('Environment:');
  console.log('  CLAUDE_DIR          Override install base directory');
  console.log('  CLAUDE_SKILLS_DIR   Override skills directory (parent used as base)');
  console.log('');
}

/**
 * Ask user a yes/no question. Returns true if yes.
 * Skipped (returns true) if --yes flag or non-interactive (piped) stdin.
 * @param {string} question
 * @returns {Promise<boolean>}
 */
function confirm(question) {
  return new Promise((resolve) => {
    // Non-interactive (piped stdin) → auto-yes
    if (!process.stdin.isTTY) {
      resolve(true);
      return;
    }
    const rl = require('readline').createInterface({
      input: process.stdin,
      output: process.stdout,
    });
    rl.question(question + ' [y/N] ', (answer) => {
      rl.close();
      resolve(answer.toLowerCase() === 'y' || answer.toLowerCase() === 'yes');
    });
  });
}

/**
 * Main installer entry point.
 */
async function main() {
  const args = parseArgs(process.argv.slice(2));

  if (args.help) {
    printHelp();
    process.exit(0);
  }

  const pkg = require('../package.json');
  const claudeDir = detectClaudeDir();

  console.log('');
  console.log('llm-cli-council v' + pkg.version + ' installer');
  console.log('');

  if (args.dryRun) {
    console.log('DRY RUN — no files will be written');
    console.log('');
  }

  console.log('Installing to: ' + claudeDir + '/');
  console.log('');

  // Show what will be installed
  for (const entry of FILE_MAP) {
    const destPath = path.join(claudeDir, entry.dest);
    console.log('  → ' + destPath);
  }
  console.log('');

  // Confirm unless --yes or dry-run
  if (!args.yes && !args.dryRun) {
    const ok = await confirm('Proceed with installation?');
    if (!ok) {
      console.log('Aborted.');
      process.exit(0);
    }
    console.log('');
  }

  // Install
  const installed = copyFiles(claudeDir, args.dryRun);
  chmodExec(claudeDir, args.dryRun);

  // Report results
  for (const dest of installed) {
    console.log('  ✓ ' + dest);
  }
  console.log('');

  if (args.dryRun) {
    console.log('Dry run complete. ' + installed.length + ' items would be installed.');
  } else {
    console.log('✅ Installed! Open Claude Code and run /llm-cli-council to get started.');
  }
  console.log('');
}

if (require.main === module) {
  main().catch((err) => {
    console.error('Installation failed: ' + err.message);
    process.exit(1);
  });
}
