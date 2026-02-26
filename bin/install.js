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

// Phase 2 Plan 02-03 adds: parseArgs(), confirm(), main()

if (require.main === module) {
  // Entry point — full logic in Plan 02-03
  const claudeDir = detectClaudeDir();
  console.log('llm-cli-council installer');
  console.log('Claude dir: ' + claudeDir);
  console.log('(Full installer coming in Plan 02-03)');
}
