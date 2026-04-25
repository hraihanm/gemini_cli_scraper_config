#!/usr/bin/env node
/**
 * check-tool-drift.js
 *
 * Detects drift between playwright-mcp-mod tool exports and the tool lists
 * documented in CLAUDE.md and .gemini/system.md.
 *
 * Usage:  node scripts/check-tool-drift.js
 * Exit:   0 = no drift, 1 = drift detected or mod repo not found
 */

const fs = require('fs');
const path = require('path');

const REPO_ROOT = path.resolve(__dirname, '..');
const MOD_DIR   = path.resolve(REPO_ROOT, '../playwright-mcp-mod/src/tools/mod');
const CLAUDE_MD = path.resolve(REPO_ROOT, 'CLAUDE.md');
const SYSTEM_MD = path.resolve(REPO_ROOT, '.gemini/system.md');

// Prefixes that identify scraping tool names (avoids false positives from
// other `name:` fields inside TypeScript objects)
const TOOL_PREFIXES = ['browser_', 'parser_', 'scraper_', 'datahen_'];

// Identifiers that look like tool names but are actually parameter names or labels
const NOT_TOOL_NAMES = new Set(['scraper_dir', 'parser_path', 'scraper_name']);

// Standard Playwright MCP tools that are NOT custom mods — they appear in
// markdown docs legitimately but won't be in src/tools/mod/*.ts
const STDLIB_TOOLS = new Set([
  'browser_navigate', 'browser_snapshot', 'browser_screenshot',
  'browser_evaluate', 'browser_click', 'browser_press_key',
  'browser_mouse_click_xy', 'browser_type', 'browser_fill',
  'browser_select_option', 'browser_hover', 'browser_scroll',
  'browser_wait_for_selector', 'browser_close', 'browser_drag',
]);

function isToolName(s) {
  return TOOL_PREFIXES.some(p => s.startsWith(p));
}

// Extract tool names from all .ts files in the mod directory (excluding index.ts)
function extractFromTS(dir) {
  if (!fs.existsSync(dir)) return null;

  const names = new Set();
  const files = fs.readdirSync(dir).filter(f => f.endsWith('.ts') && f !== 'index.ts');

  for (const file of files) {
    const src = fs.readFileSync(path.join(dir, file), 'utf8');
    // Matches:  name: 'tool_name'  or  name: "tool_name"
    for (const m of src.matchAll(/\bname:\s*['"]([^'"]+)['"]/g)) {
      if (isToolName(m[1])) names.add(m[1]);
    }
  }
  return names;
}

// Extract backtick-quoted tool names from a markdown file.
// Strips fenced code blocks first so their triple-backtick delimiters don't
// create a mega-match that consumes all the inline code spans inside tables.
function extractFromMarkdown(filePath) {
  const names = new Set();
  if (!fs.existsSync(filePath)) return names;
  let src = fs.readFileSync(filePath, 'utf8');
  // Remove ``` ... ``` fenced blocks (greedy within single pass)
  src = src.replace(/```[\s\S]*?```/g, '');
  // Only match simple identifiers: letters, digits, underscores — no dots, parens, spaces.
  // This filters out `browser_grep_html()`, `html.ts`, `scraper_dir: "..."` etc.
  for (const m of src.matchAll(/`([a-z][a-z0-9_]+)`/g)) {
    if (isToolName(m[1]) && !NOT_TOOL_NAMES.has(m[1])) names.add(m[1]);
  }
  return names;
}

// ── Main ──────────────────────────────────────────────────────────────────────

console.log('=== Tool Drift Check ===\n');

const tsTools = extractFromTS(MOD_DIR);
if (tsTools === null) {
  console.error(`ERROR: playwright-mcp-mod not found at:\n  ${MOD_DIR}`);
  console.error('Expected sibling repo at ../playwright-mcp-mod');
  process.exit(1);
}

const claudeTools = extractFromMarkdown(CLAUDE_MD);
const systemTools = extractFromMarkdown(SYSTEM_MD);
const docTools = new Set([...claudeTools, ...systemTools]);

console.log(`playwright-mcp-mod tools found  (${tsTools.size}):`);
for (const t of [...tsTools].sort()) console.log(`  + ${t}`);

console.log(`\nDocumented tools (CLAUDE.md + system.md)  (${docTools.size}):`);
for (const t of [...docTools].sort()) console.log(`  + ${t}`);

let hasErrors = false;

// Tools implemented but not documented
const undocumented = [...tsTools].filter(t => !docTools.has(t)).sort();
if (undocumented.length > 0) {
  console.log(`\n❌  UNDOCUMENTED — in playwright-mcp-mod but missing from docs:`);
  for (const t of undocumented) console.log(`     - ${t}`);
  console.log(`   → Add these to the CLAUDE.md "Custom tools" list and/or .gemini/system.md tool glossary.`);
  hasErrors = true;
} else {
  console.log('\n✅  All playwright-mcp-mod tools are documented.');
}

// Tools documented but no longer implemented (stale docs)
// Exclude standard Playwright base tools — they're legitimately mentioned in docs
const stale = [...docTools].filter(t => !tsTools.has(t) && !STDLIB_TOOLS.has(t)).sort();
if (stale.length > 0) {
  console.log(`\n⚠️   STALE — in docs but not found in playwright-mcp-mod source:`);
  for (const t of stale) console.log(`     - ${t}`);
  console.log(`   → Remove or rename these entries in CLAUDE.md / .gemini/system.md.`);
  hasErrors = true;
} else {
  console.log('✅  No stale tool entries in docs.');
}

console.log('');
if (hasErrors) {
  console.log('Tool drift detected. Fix the issues above, then re-run this script.');
  process.exit(1);
} else {
  console.log('No drift. Docs and implementation are in sync.');
  process.exit(0);
}
