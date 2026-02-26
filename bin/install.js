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

// Phase 2 Plan 02-02 adds: FILE_MAP, copyFiles(), chmodExec()
// Phase 2 Plan 02-03 adds: parseArgs(), confirm(), main()

if (require.main === module) {
  // Entry point — full logic in Plan 02-03
  const claudeDir = detectClaudeDir();
  console.log('llm-cli-council installer');
  console.log('Claude dir: ' + claudeDir);
  console.log('(Full installer coming in Plan 02-03)');
}
