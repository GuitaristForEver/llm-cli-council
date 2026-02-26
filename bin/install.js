#!/usr/bin/env node
'use strict';

const fs   = require('fs');
const path = require('path');
const os   = require('os');
const { spawnSync, spawn } = require('child_process');

// ─── Colors ───────────────────────────────────────────────────────────────────
const c = {
  reset:  '\x1b[0m',
  bold:   '\x1b[1m',
  dim:    '\x1b[2m',
  cyan:   '\x1b[36m',
  green:  '\x1b[32m',
  yellow: '\x1b[33m',
  red:    '\x1b[31m',
};

// ─── Banner ───────────────────────────────────────────────────────────────────
function printBanner(version) {
  console.log('');
  console.log(c.cyan + '   ██████╗  ██████╗ ██╗   ██╗███╗  ██╗ ██████╗ ██╗██╗     ' + c.reset);
  console.log(c.cyan + '  ██╔════╝ ██╔═══██╗██║   ██║████╗ ██║██╔════╝ ██║██║     ' + c.reset);
  console.log(c.cyan + '  ██║      ██║   ██║██║   ██║██╔██╗██║██║      ██║██║     ' + c.reset);
  console.log(c.cyan + '  ██║      ██║   ██║██║   ██║██║╚████║██║      ██║██║     ' + c.reset);
  console.log(c.cyan + '  ╚██████╗ ╚██████╔╝╚██████╔╝██║ ╚███║╚██████╗ ██║███████╗' + c.reset);
  console.log(c.cyan + '   ╚═════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚══╝ ╚═════╝ ╚═╝╚══════╝' + c.reset);
  console.log('');
  console.log('  llm-cli-council  ' + c.dim + 'v' + version + c.reset);
  console.log('  Orchestrate multiple LLMs as a review council in Claude Code.');
  console.log('');
}

// ─── Section headers & line items ─────────────────────────────────────────────
function printPhase(n, title) {
  console.log('  ' + c.yellow + 'Phase ' + n + c.reset + '  ' + title);
  console.log('  ' + c.dim + '─'.repeat(38) + c.reset);
}

function printItem(status, label, detail) {
  const sym = status === 'ok'   ? c.green  + '✓' + c.reset
            : status === 'fail' ? c.red    + '✗' + c.reset
            : status === 'warn' ? c.yellow + '⚠' + c.reset
            :                     c.dim    + '·' + c.reset;
  const det = detail ? '  ' + c.dim + detail + c.reset : '';
  console.log('  ' + sym + '  ' + label + det);
}

// ─── Claude directory detection ───────────────────────────────────────────────
function detectClaudeDir() {
  if (process.env.CLAUDE_DIR)        return process.env.CLAUDE_DIR;
  if (process.env.CLAUDE_SKILLS_DIR) return path.dirname(process.env.CLAUDE_SKILLS_DIR);
  return path.join(os.homedir(), '.claude');
}

function ensureDirExists(dirPath) {
  fs.mkdirSync(dirPath, { recursive: true });
}

// ─── File copy ────────────────────────────────────────────────────────────────
const FILE_MAP = [
  { src: 'skills',                dest: 'skills',                type: 'dir'  },
  { src: 'lib',                   dest: 'lib',                   type: 'dir'  },
  { src: 'prompts',               dest: 'prompts',               type: 'dir'  },
  { src: 'rules',                 dest: 'rules',                 type: 'dir'  },
  { src: 'config/providers.json', dest: 'config/providers.json', type: 'file' },
];

const CHMOD_EXEC_FILES = ['lib/platform-utils.sh'];

function copyFiles(claudeDir, dryRun) {
  const pkgRoot = path.join(__dirname, '..');
  const results = [];

  for (const entry of FILE_MAP) {
    const srcPath  = path.join(pkgRoot, entry.src);
    const destPath = path.join(claudeDir, entry.dest);

    if (!dryRun) {
      ensureDirExists(path.dirname(destPath));
      if (entry.type === 'dir') {
        fs.cpSync(srcPath, destPath, { recursive: true });
      } else {
        fs.copyFileSync(srcPath, destPath);
      }
    }

    results.push({ src: entry.src, dest: destPath });
  }

  return results;
}

function chmodExec(claudeDir, dryRun) {
  if (dryRun) return;
  for (const relPath of CHMOD_EXEC_FILES) {
    const fullPath = path.join(claudeDir, relPath);
    if (fs.existsSync(fullPath)) fs.chmodSync(fullPath, 0o755);
  }
}

// ─── Provider detection ───────────────────────────────────────────────────────
const PROVIDER_META = {
  claude:  { label: 'Anthropic Claude', cmd: 'claude',  args: ['-p', 'Reply with one word: ok'],       timeout: 8000 },
  copilot: { label: 'GitHub Copilot',   cmd: 'copilot', args: ['--prompt', 'Reply with one word: ok'], timeout: 8000 },
  codex:   { label: 'OpenAI Codex',     cmd: 'codex',   args: ['Reply with one word: ok'],              timeout: 8000 },
  gemini:  { label: 'Google Gemini',    cmd: 'gemini',  args: ['Reply with one word: ok'],              timeout: 8000 },
  ollama:  { label: 'Local (Ollama)',   cmd: 'ollama',  args: ['list'],                                 timeout: 3000 },
};

function probeProvider(name, meta) {
  return new Promise((resolve) => {
    // Step 1: check binary exists
    const which = spawnSync('which', [meta.cmd], { encoding: 'utf8' });
    if (which.status !== 0) {
      resolve({ name, active: false, reason: 'not found' });
      return;
    }

    // Step 2: real probe with timeout
    const proc = spawn(meta.cmd, meta.args, {
      stdio: ['ignore', 'pipe', 'pipe'],
      env: process.env,
    });

    const timer = setTimeout(() => {
      proc.kill('SIGKILL');
      resolve({ name, active: false, reason: 'timeout' });
    }, meta.timeout);

    proc.on('close', (code) => {
      clearTimeout(timer);
      resolve({ name, active: code === 0, reason: code === 0 ? 'active' : 'auth error' });
    });

    proc.on('error', () => {
      clearTimeout(timer);
      resolve({ name, active: false, reason: 'error' });
    });
  });
}

async function detectProviders() {
  return Promise.all(
    Object.entries(PROVIDER_META).map(([name, meta]) => probeProvider(name, meta))
  );
}

function updateProvidersConfig(claudeDir, results) {
  const configPath = path.join(claudeDir, 'config', 'providers.json');
  if (!fs.existsSync(configPath)) return;
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  for (const r of results) {
    if (config.providers[r.name]) {
      config.providers[r.name].active = r.active;
    }
  }
  fs.writeFileSync(configPath, JSON.stringify(config, null, 2) + '\n');
}

// ─── CLI interface ────────────────────────────────────────────────────────────
function parseArgs(argv) {
  return {
    dryRun:      argv.includes('--dry-run'),
    yes:         argv.includes('--yes') || argv.includes('-y'),
    help:        argv.includes('--help') || argv.includes('-h'),
    skipDetect:  argv.includes('--skip-detect'),
  };
}

function printHelp(version) {
  console.log('');
  console.log('llm-cli-council v' + version + ' — installer');
  console.log('');
  console.log(c.yellow + 'Usage:' + c.reset + '  npx llm-cli-council [options]');
  console.log('');
  console.log(c.yellow + 'Options:' + c.reset);
  console.log('  ' + c.cyan + '--dry-run     ' + c.reset + 'Show what would be installed without installing');
  console.log('  ' + c.cyan + '--yes, -y     ' + c.reset + 'Skip confirmation prompt');
  console.log('  ' + c.cyan + '--skip-detect ' + c.reset + 'Skip LLM provider detection step');
  console.log('  ' + c.cyan + '--help, -h    ' + c.reset + 'Show this help message');
  console.log('');
  console.log(c.yellow + 'Environment:' + c.reset);
  console.log('  ' + c.cyan + 'CLAUDE_DIR         ' + c.reset + 'Override install base directory');
  console.log('  ' + c.cyan + 'CLAUDE_SKILLS_DIR  ' + c.reset + 'Override skills dir (parent used as base)');
  console.log('');
}

function confirm(question) {
  return new Promise((resolve) => {
    if (!process.stdin.isTTY) { resolve(true); return; }
    const rl = require('readline').createInterface({
      input: process.stdin,
      output: process.stdout,
    });
    rl.question('  ' + question + ' ' + c.dim + '[y/N]' + c.reset + ' ', (answer) => {
      rl.close();
      resolve(answer.toLowerCase() === 'y' || answer.toLowerCase() === 'yes');
    });
  });
}

// ─── Main ─────────────────────────────────────────────────────────────────────
async function main() {
  const args = parseArgs(process.argv.slice(2));
  const pkg  = require('../package.json');

  if (args.help) {
    printHelp(pkg.version);
    process.exit(0);
  }

  const claudeDir = detectClaudeDir();

  printBanner(pkg.version);

  if (args.dryRun) {
    console.log('  ' + c.yellow + 'DRY RUN' + c.reset + ' — no files will be written\n');
  }

  console.log('  Installing to: ' + c.cyan + claudeDir + c.reset + '\n');

  // Preview what will be installed
  for (const entry of FILE_MAP) {
    const dest = path.join(claudeDir, entry.dest);
    const homeDir = os.homedir();
    const shortDest = dest.startsWith(homeDir) ? '~' + dest.slice(homeDir.length) : dest;
    console.log('  ' + c.dim + entry.src.padEnd(24) + '→  ' + shortDest + c.reset);
  }
  console.log('');

  // Confirm unless --yes or --dry-run
  if (!args.yes && !args.dryRun) {
    const ok = await confirm('Proceed with installation?');
    if (!ok) {
      console.log('\n  Aborted.\n');
      process.exit(0);
    }
    console.log('');
  }

  // ── Phase 1: Install files ──────────────────────────────────────────────────
  printPhase(1, 'Install plugin files');

  const installed = copyFiles(claudeDir, args.dryRun);
  chmodExec(claudeDir, args.dryRun);

  for (const f of installed) {
    const homeDir = os.homedir();
    const shortDest = f.dest.startsWith(homeDir) ? '~' + f.dest.slice(homeDir.length) : f.dest;
    printItem('ok', f.src.padEnd(24) + c.dim + '→  ' + shortDest + c.reset);
  }
  console.log('');

  if (args.dryRun) {
    console.log('  Dry run complete. ' + installed.length + ' items would be installed.\n');
    return;
  }

  // ── Phase 2: Detect LLM providers ──────────────────────────────────────────
  if (!args.skipDetect) {
    printPhase(2, 'Detect LLM providers');
    console.log('  ' + c.dim + 'Probing ' + Object.keys(PROVIDER_META).length + ' providers in parallel...' + c.reset + '\n');

    const results = await detectProviders();

    for (const r of results) {
      const meta      = PROVIDER_META[r.name];
      const nameCol   = r.name.padEnd(9);
      const labelCol  = meta.label.padEnd(18);
      printItem(r.active ? 'ok' : 'fail', nameCol + '  ' + labelCol, r.reason);
    }
    console.log('');

    const activeCount = results.filter(r => r.active).length;
    updateProvidersConfig(claudeDir, results);

    const configShort = ('~/.claude/config/providers.json');
    console.log('  ' + c.dim + activeCount + ' active provider' + (activeCount !== 1 ? 's' : '') + ' written to ' + configShort + c.reset);
    console.log('');

    if (activeCount === 0) {
      console.log('  ' + c.yellow + '⚠' + c.reset + '  No providers found. Install claude, copilot, gemini, codex, or ollama CLI.');
      console.log('');
    }
  }

  // ── Done ────────────────────────────────────────────────────────────────────
  console.log(c.green + '  Done!' + c.reset + '  Open Claude Code and run ' + c.cyan + '/llm-cli-council' + c.reset + ' to get started.');
  console.log('');
}

if (require.main === module) {
  main().catch((err) => {
    console.error('\n  ' + c.red + '✗' + c.reset + '  Installation failed: ' + err.message + '\n');
    process.exit(1);
  });
}
