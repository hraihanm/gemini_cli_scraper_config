#!/usr/bin/env node
"use strict";
/**
 * DataHen Local Dev Dashboard
 *
 * Standalone HTTP server for iterative scraper development.
 * Provides a visual dashboard for queue/output inspection and a browser
 * fetch proxy so local_runner.rb can serve fetch_type:'browser' pages
 * without deploying to DataHen.
 *
 * Usage:
 *   node lib/scraping_dashboard.js -s /path/to/generated_scraper/mysite [--port 4567]
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const http = __importStar(require("http"));
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
const url = __importStar(require("url"));
const child_process_1 = require("child_process");
// Playwright is loaded lazily so the dashboard can start without it installed.
let playwrightModule = null;
let browser = null;
// Serialize browser fetch requests to avoid concurrent context conflicts.
let browserQueue = Promise.resolve();
// ---------------------------------------------------------------------------
// CLI args
// ---------------------------------------------------------------------------
const args = process.argv.slice(2);
let scraperDir = '';
let port = 4567;
for (let i = 0; i < args.length; i++) {
    if ((args[i] === '-s' || args[i] === '--scraper') && args[i + 1]) {
        scraperDir = path.resolve(args[++i]);
    }
    else if ((args[i] === '--port' || args[i] === '-p') && args[i + 1]) {
        port = parseInt(args[++i], 10);
    }
    else if (args[i].startsWith('--port=')) {
        port = parseInt(args[i].split('=')[1], 10);
    }
    else if (args[i].startsWith('-s=')) {
        scraperDir = path.resolve(args[i].split('=')[1]);
    }
}
if (!scraperDir) {
    console.error('Usage: node lib/scraping_dashboard.js -s <scraper_dir> [--port 4567]');
    process.exit(1);
}
if (!fs.existsSync(scraperDir)) {
    console.error(`Scraper directory not found: ${scraperDir}`);
    process.exit(1);
}
const STATE_DIR = path.join(scraperDir, '.local-state');
const QUEUE_FILE = path.join(STATE_DIR, 'queue.json');
const OUTPUTS_DIR = path.join(STATE_DIR, 'outputs');
const scraperName = path.basename(scraperDir);
// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
function readJson(filePath, fallback = null) {
    try {
        if (fs.existsSync(filePath)) {
            return JSON.parse(fs.readFileSync(filePath, 'utf8'));
        }
    }
    catch { /* ignore */ }
    return fallback;
}
function jsonResponse(res, data, status = 200) {
    const body = JSON.stringify(data);
    res.writeHead(status, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' });
    res.end(body);
}
function readBody(req) {
    return new Promise((resolve, reject) => {
        const chunks = [];
        req.on('data', (c) => chunks.push(c));
        req.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')));
        req.on('error', reject);
    });
}
// ---------------------------------------------------------------------------
// Browser proxy (Playwright)
// ---------------------------------------------------------------------------
async function getPlaywright() {
    if (!playwrightModule) {
        playwrightModule = await Promise.resolve().then(() => __importStar(require('playwright')));
    }
    return playwrightModule;
}
async function getBrowser() {
    if (!browser || !browser.isConnected()) {
        const pw = await getPlaywright();
        browser = await pw.chromium.launch({ headless: true });
    }
    return browser;
}
async function handleBrowserFetch(body) {
    // Enqueue behind previous requests
    let resolve;
    const thisRequest = new Promise(r => { resolve = r; });
    const prev = browserQueue;
    browserQueue = browserQueue.then(() => thisRequest);
    await prev; // Wait for previous request to finish
    try {
        const b = await getBrowser();
        const context = await b.newContext();
        try {
            if (body.headers && Object.keys(body.headers).length > 0) {
                await context.setExtraHTTPHeaders(body.headers);
            }
            const pg = await context.newPage();
            const response = await pg.goto(body.url, {
                waitUntil: 'networkidle',
                timeout: 60000,
            });
            const html = await pg.content();
            const finalUrl = pg.url();
            return { html, status: response?.status() ?? 200, url: finalUrl };
        }
        finally {
            await context.close();
        }
    }
    catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        return { html: '', status: 0, url: body.url, error: msg };
    }
    finally {
        resolve();
    }
}
function loadQueue() {
    return readJson(QUEUE_FILE, []);
}
function loadOutputs(collection) {
    if (!fs.existsSync(OUTPUTS_DIR))
        return [];
    const files = fs.readdirSync(OUTPUTS_DIR).filter(f => f.endsWith('.json'));
    const results = [];
    for (const f of files) {
        const col = path.basename(f, '.json');
        if (collection && col !== collection)
            continue;
        const data = readJson(path.join(OUTPUTS_DIR, f), []);
        if (collection)
            return data;
        results.push(...data);
    }
    return results;
}
function getCollections() {
    if (!fs.existsSync(OUTPUTS_DIR))
        return [];
    return fs.readdirSync(OUTPUTS_DIR)
        .filter(f => f.endsWith('.json'))
        .map(f => path.basename(f, '.json'));
}
function buildStatus() {
    const queue = loadQueue();
    const byType = {};
    for (const p of queue) {
        const pt = p.page_type || 'unknown';
        const st = p.status || 'unknown';
        byType[pt] = byType[pt] || {};
        byType[pt][st] = (byType[pt][st] || 0) + 1;
    }
    const outputSizes = {};
    for (const col of getCollections()) {
        const data = readJson(path.join(OUTPUTS_DIR, `${col}.json`), []);
        outputSizes[col] = data.length;
    }
    return {
        scraper: scraperName,
        queue_total: queue.length,
        queue_by_type: byType,
        outputs: outputSizes,
    };
}
// ---------------------------------------------------------------------------
// Spawn local_runner.rb and stream stdout
// ---------------------------------------------------------------------------
function spawnRunner(action, opts, res) {
    // Find local_runner.rb relative to this script's directory
    const runnerPath = path.resolve(__dirname, '..', 'scraping', 'local_runner.rb');
    const rubyArgs = [runnerPath, '-s', scraperDir, action];
    if (opts.page_type)
        rubyArgs.push('--page-type', opts.page_type);
    if (opts.count)
        rubyArgs.push('--count', String(opts.count));
    rubyArgs.push('--dashboard-port', String(port));
    res.writeHead(200, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' });
    const child = (0, child_process_1.spawn)('ruby', rubyArgs, { env: process.env });
    const lines = [];
    child.stdout.on('data', (chunk) => {
        const text = chunk.toString();
        lines.push(...text.split('\n').filter(Boolean));
        // Stream each line as a JSON event
        for (const line of text.split('\n').filter(Boolean)) {
            res.write(JSON.stringify({ type: 'log', line }) + '\n');
        }
    });
    child.stderr.on('data', (chunk) => {
        const text = chunk.toString();
        for (const line of text.split('\n').filter(Boolean)) {
            res.write(JSON.stringify({ type: 'error', line }) + '\n');
        }
    });
    child.on('close', (code) => {
        res.write(JSON.stringify({ type: 'done', exit_code: code, lines }) + '\n');
        res.end();
    });
}
// ---------------------------------------------------------------------------
// Inline HTML dashboard
// ---------------------------------------------------------------------------
function getDashboardHtml() {
    return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>DataHen Local Dev — ${scraperName}</title>
<style>
  :root {
    --bg: #1a1a1a; --bg2: #242424; --bg3: #2e2e2e;
    --fg: #e0e0e0; --fg2: #a0a0a0; --accent: #4a9eff;
    --green: #4caf50; --red: #f44336; --orange: #ff9800;
    --border: #3a3a3a; --mono: 'Cascadia Mono','Fira Code',monospace;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: var(--bg); color: var(--fg); font-family: var(--mono); font-size: 13px; }
  header { background: var(--bg2); border-bottom: 1px solid var(--border); padding: 10px 16px;
           display: flex; align-items: center; gap: 16px; }
  header h1 { font-size: 15px; font-weight: 600; color: var(--accent); }
  .browser-indicator { margin-left: auto; font-size: 12px; display: flex; align-items: center; gap: 6px; }
  .dot { width: 8px; height: 8px; border-radius: 50%; background: var(--fg2); }
  .dot.ready { background: var(--green); }
  .main { display: grid; grid-template-columns: 280px 1fr; grid-template-rows: auto 1fr; gap: 0; height: calc(100vh - 41px); }
  .sidebar { background: var(--bg2); border-right: 1px solid var(--border); overflow-y: auto; padding: 12px; display: flex; flex-direction: column; gap: 12px; }
  .panel { background: var(--bg3); border: 1px solid var(--border); border-radius: 4px; padding: 10px; }
  .panel h2 { font-size: 11px; text-transform: uppercase; color: var(--fg2); letter-spacing: 1px; margin-bottom: 8px; }
  .status-row { display: flex; justify-content: space-between; padding: 2px 0; }
  .status-row .label { color: var(--fg2); }
  .badge { font-size: 11px; padding: 1px 6px; border-radius: 3px; background: var(--bg); }
  .badge.to_fetch { color: var(--accent); }
  .badge.fetching { color: var(--orange); }
  .badge.parsed { color: var(--green); }
  .badge.failed { color: var(--red); }
  .content-area { display: flex; flex-direction: column; overflow: hidden; }
  .tabs { display: flex; border-bottom: 1px solid var(--border); background: var(--bg2); }
  .tab { padding: 8px 16px; cursor: pointer; color: var(--fg2); border-bottom: 2px solid transparent; font-size: 12px; }
  .tab.active { color: var(--accent); border-bottom-color: var(--accent); }
  .tab-content { display: none; flex: 1; overflow: hidden; padding: 12px; }
  .tab-content.active { display: flex; flex-direction: column; }
  /* Actions panel */
  .actions { display: flex; flex-direction: column; gap: 10px; }
  .action-row { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
  button { background: var(--accent); color: #fff; border: none; border-radius: 3px; padding: 6px 14px;
           cursor: pointer; font-family: var(--mono); font-size: 12px; }
  button:hover { opacity: 0.85; }
  button.secondary { background: var(--bg3); color: var(--fg2); border: 1px solid var(--border); }
  button.danger { background: var(--red); }
  input, select { background: var(--bg3); color: var(--fg); border: 1px solid var(--border); border-radius: 3px;
                  padding: 5px 8px; font-family: var(--mono); font-size: 12px; }
  input { width: 60px; }
  select { min-width: 120px; }
  .log-area { background: var(--bg); border: 1px solid var(--border); border-radius: 3px; padding: 8px;
              overflow-y: auto; flex: 1; font-size: 12px; line-height: 1.5; max-height: 320px; }
  .log-line { color: var(--fg2); }
  .log-line.error { color: var(--red); }
  .log-line.done { color: var(--green); }
  /* Table */
  .table-toolbar { display: flex; gap: 8px; margin-bottom: 8px; align-items: center; }
  .table-toolbar input { width: 200px; }
  .table-wrap { flex: 1; overflow: auto; border: 1px solid var(--border); border-radius: 3px; }
  table { width: 100%; border-collapse: collapse; font-size: 12px; }
  th { background: var(--bg2); color: var(--fg2); text-align: left; padding: 6px 8px;
       position: sticky; top: 0; border-bottom: 1px solid var(--border); white-space: nowrap; }
  td { padding: 5px 8px; border-bottom: 1px solid var(--border); vertical-align: top; max-width: 260px;
       overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  tr:hover td { background: var(--bg3); }
  .empty { color: var(--fg2); text-align: center; padding: 40px; }
  .pager { display: flex; gap: 8px; align-items: center; margin-top: 8px; color: var(--fg2); font-size: 12px; }
</style>
</head>
<body>
<header>
  <h1>DataHen Local Dev &#x2014; ${scraperName}</h1>
  <span id="refresh-status" style="color:var(--fg2);font-size:11px;">auto-refresh</span>
  <div class="browser-indicator">
    <div class="dot" id="browser-dot"></div>
    <span id="browser-label">Browser: checking…</span>
  </div>
</header>
<div class="main">
  <div class="sidebar">
    <div class="panel" id="queue-panel">
      <h2>Queue</h2>
      <div id="queue-summary"><span style="color:var(--fg2)">Loading…</span></div>
    </div>
    <div class="panel" id="outputs-panel">
      <h2>Outputs</h2>
      <div id="outputs-summary"><span style="color:var(--fg2)">Loading…</span></div>
    </div>
  </div>
  <div class="content-area">
    <div class="tabs">
      <div class="tab active" onclick="showTab('actions')">Actions</div>
      <div class="tab" onclick="showTab('outputs')">Outputs</div>
      <div class="tab" onclick="showTab('queue')">Queue</div>
    </div>

    <!-- Actions Tab -->
    <div class="tab-content active" id="tab-actions">
      <div class="actions">
        <div class="action-row">
          <button onclick="doAction('seed')">Seed</button>
          <button class="danger secondary" onclick="doAction('reset')">Reset</button>
        </div>
        <div class="action-row">
          <select id="step-page-type"><option value="">any type</option></select>
          <input id="step-count" type="number" value="1" min="1" max="100">
          <button onclick="doAction('step')">Step</button>
        </div>
        <div style="font-size:11px;color:var(--fg2)">Log output:</div>
        <div class="log-area" id="log-area"></div>
      </div>
    </div>

    <!-- Outputs Tab -->
    <div class="tab-content" id="tab-outputs">
      <div class="table-toolbar">
        <select id="col-picker" onchange="loadOutputTable()"><option value="">all</option></select>
        <input id="search-input" placeholder="search…" oninput="filterTable()">
        <span id="row-count" style="color:var(--fg2);font-size:11px;"></span>
      </div>
      <div class="table-wrap"><table id="outputs-table"><thead></thead><tbody></tbody></table></div>
      <div class="pager">
        <button class="secondary" onclick="prevPage()">&#x2190; Prev</button>
        <span id="page-info">Page 1</span>
        <button class="secondary" onclick="nextPage()">Next &#x2192;</button>
      </div>
    </div>

    <!-- Queue Tab -->
    <div class="tab-content" id="tab-queue">
      <div class="table-toolbar">
        <select id="queue-type-filter" onchange="loadQueueTable()"><option value="">all types</option></select>
        <select id="queue-status-filter" onchange="loadQueueTable()">
          <option value="">all statuses</option>
          <option value="to_fetch">to_fetch</option>
          <option value="fetching">fetching</option>
          <option value="fetched">fetched</option>
          <option value="parsed">parsed</option>
          <option value="failed">failed</option>
        </select>
        <input id="queue-search" placeholder="search URL…" oninput="filterQueueTable()">
      </div>
      <div class="table-wrap"><table id="queue-table">
        <thead><tr>
          <th>Status</th><th>Type</th><th>URL</th><th>Vars</th>
        </tr></thead>
        <tbody id="queue-tbody"></tbody>
      </table></div>
    </div>
  </div>
</div>

<script>
  const API = '';
  let outputsData = [];
  let queueData = [];
  let filteredOutputs = [];
  let outputPage = 0;
  const PAGE_SIZE = 50;

  function showTab(name) {
    document.querySelectorAll('.tab').forEach((t,i) => {
      const tabs = ['actions','outputs','queue'];
      t.classList.toggle('active', tabs[i] === name);
    });
    document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
    document.getElementById('tab-' + name).classList.add('active');
    if (name === 'outputs') loadOutputTable();
    if (name === 'queue') loadQueueTable();
  }

  // ---- Status polling ----
  async function refreshStatus() {
    try {
      const r = await fetch(API + '/api/status');
      const d = await r.json();

      // Queue summary
      const qs = document.getElementById('queue-summary');
      const byType = d.queue_by_type || {};
      if (Object.keys(byType).length === 0) {
        qs.innerHTML = '<span style="color:var(--fg2)">empty</span>';
      } else {
        qs.innerHTML = Object.entries(byType).map(([type, counts]) => {
          const parts = Object.entries(counts).map(([s, n]) =>
            \`<span class="badge \${s}">\${n} \${s}</span>\`).join(' ');
          return \`<div class="status-row"><span class="label">\${type}</span><span>\${parts}</span></div>\`;
        }).join('');
      }

      // Outputs summary
      const os = document.getElementById('outputs-summary');
      const outputs = d.outputs || {};
      if (Object.keys(outputs).length === 0) {
        os.innerHTML = '<span style="color:var(--fg2)">none</span>';
      } else {
        os.innerHTML = Object.entries(outputs).map(([col, n]) =>
          \`<div class="status-row"><span class="label">\${col}</span><span class="badge">\${n}</span></div>\`
        ).join('');
      }

      // Update step page-type selector
      const sel = document.getElementById('step-page-type');
      const existing = Array.from(sel.options).map(o => o.value);
      Object.keys(byType).forEach(t => {
        if (!existing.includes(t)) {
          const o = document.createElement('option');
          o.value = t; o.textContent = t;
          sel.appendChild(o);
        }
      });

      // Update col picker
      const cp = document.getElementById('col-picker');
      const existingCols = Array.from(cp.options).map(o => o.value);
      Object.keys(outputs).forEach(col => {
        if (!existingCols.includes(col)) {
          const o = document.createElement('option');
          o.value = col; o.textContent = col;
          cp.appendChild(o);
        }
      });

      // Queue type filter
      const qtf = document.getElementById('queue-type-filter');
      const existingTypes = Array.from(qtf.options).map(o => o.value);
      Object.keys(byType).forEach(t => {
        if (!existingTypes.includes(t)) {
          const o = document.createElement('option');
          o.value = t; o.textContent = t;
          qtf.appendChild(o);
        }
      });

    } catch(e) {
      document.getElementById('refresh-status').textContent = 'offline';
    }
  }

  // ---- Browser status ----
  async function checkBrowser() {
    try {
      const r = await fetch(API + '/api/browser-status');
      const d = await r.json();
      const dot = document.getElementById('browser-dot');
      const lbl = document.getElementById('browser-label');
      if (d.ready) {
        dot.classList.add('ready');
        lbl.textContent = 'Browser: ready';
      } else {
        dot.classList.remove('ready');
        lbl.textContent = 'Browser: idle';
      }
    } catch {}
  }

  // ---- Actions ----
  async function doAction(action) {
    const log = document.getElementById('log-area');
    log.innerHTML = '';
    const pageType = document.getElementById('step-page-type').value;
    const count = document.getElementById('step-count').value;
    const body = JSON.stringify({ action, page_type: pageType || undefined, count: parseInt(count) || 1 });
    try {
      const r = await fetch(API + '/api/action', { method: 'POST',
        headers: {'Content-Type':'application/json'}, body });
      const reader = r.body.getReader();
      const dec = new TextDecoder();
      while (true) {
        const {value, done} = await reader.read();
        if (done) break;
        const text = dec.decode(value);
        for (const line of text.split('\\n').filter(Boolean)) {
          try {
            const ev = JSON.parse(line);
            const div = document.createElement('div');
            div.className = 'log-line' + (ev.type === 'error' ? ' error' : ev.type === 'done' ? ' done' : '');
            div.textContent = ev.type === 'done' ? \`[done, exit \${ev.exit_code}]\` : ev.line;
            log.appendChild(div);
            log.scrollTop = log.scrollHeight;
          } catch {}
        }
      }
    } catch(e) {
      const div = document.createElement('div');
      div.className = 'log-line error';
      div.textContent = 'Error: ' + e.message;
      log.appendChild(div);
    }
    await refreshStatus();
  }

  // ---- Outputs table ----
  async function loadOutputTable() {
    const col = document.getElementById('col-picker').value;
    const r = await fetch(API + '/api/outputs' + (col ? '?collection=' + encodeURIComponent(col) : ''));
    outputsData = await r.json();
    outputPage = 0;
    filterTable();
  }

  function filterTable() {
    const q = (document.getElementById('search-input').value || '').toLowerCase();
    filteredOutputs = q
      ? outputsData.filter(row => JSON.stringify(row).toLowerCase().includes(q))
      : outputsData;
    document.getElementById('row-count').textContent = filteredOutputs.length + ' rows';
    renderOutputPage();
  }

  function renderOutputPage() {
    const start = outputPage * PAGE_SIZE;
    const slice = filteredOutputs.slice(start, start + PAGE_SIZE);
    document.getElementById('page-info').textContent = \`Page \${outputPage + 1} / \${Math.max(1, Math.ceil(filteredOutputs.length / PAGE_SIZE))}\`;

    if (filteredOutputs.length === 0) {
      document.querySelector('#outputs-table thead').innerHTML = '';
      document.querySelector('#outputs-table tbody').innerHTML = '<tr><td class="empty" colspan="99">No outputs yet</td></tr>';
      return;
    }

    // Collect column keys (max 10 for readability)
    const keys = [...new Set(slice.flatMap(r => Object.keys(r)))].slice(0, 15);
    document.querySelector('#outputs-table thead').innerHTML =
      '<tr>' + keys.map(k => \`<th>\${k}</th>\`).join('') + '</tr>';
    document.querySelector('#outputs-table tbody').innerHTML = slice.map(row =>
      '<tr>' + keys.map(k => {
        const v = row[k] === undefined ? '' : (typeof row[k] === 'object' ? JSON.stringify(row[k]) : String(row[k]));
        return \`<td title="\${v.replace(/"/g,'&quot;')}">\${v}</td>\`;
      }).join('') + '</tr>'
    ).join('');
  }

  function prevPage() { if (outputPage > 0) { outputPage--; renderOutputPage(); } }
  function nextPage() {
    if ((outputPage + 1) * PAGE_SIZE < filteredOutputs.length) { outputPage++; renderOutputPage(); }
  }

  // ---- Queue table ----
  async function loadQueueTable() {
    const type = document.getElementById('queue-type-filter').value;
    const status = document.getElementById('queue-status-filter').value;
    let qstr = '?';
    if (type) qstr += 'page_type=' + encodeURIComponent(type) + '&';
    if (status) qstr += 'status=' + encodeURIComponent(status);
    const r = await fetch(API + '/api/queue' + (qstr.length > 1 ? qstr : ''));
    queueData = await r.json();
    filterQueueTable();
  }

  function filterQueueTable() {
    const q = (document.getElementById('queue-search').value || '').toLowerCase();
    const filtered = q ? queueData.filter(p => (p.url || '').toLowerCase().includes(q)) : queueData;
    const tbody = document.getElementById('queue-tbody');
    if (filtered.length === 0) {
      tbody.innerHTML = '<tr><td class="empty" colspan="4">No pages in queue</td></tr>';
      return;
    }
    tbody.innerHTML = filtered.slice(0, 200).map(p => \`<tr>
      <td><span class="badge \${p.status}">\${p.status || ''}</span></td>
      <td>\${p.page_type || ''}</td>
      <td title="\${(p.url||'').replace(/"/g,'&quot;')}">\${p.url || ''}</td>
      <td style="color:var(--fg2)">\${p.vars ? JSON.stringify(p.vars) : ''}</td>
    </tr>\`).join('');
  }

  // ---- Init ----
  refreshStatus();
  checkBrowser();
  setInterval(refreshStatus, 3000);
  setInterval(checkBrowser, 10000);
</script>
</body>
</html>`;
}
// ---------------------------------------------------------------------------
// Request router
// ---------------------------------------------------------------------------
async function handleRequest(req, res) {
    const parsedUrl = url.parse(req.url || '/', true);
    const pathname = parsedUrl.pathname || '/';
    const method = req.method || 'GET';
    // CORS preflight
    if (method === 'OPTIONS') {
        res.writeHead(204, {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type',
        });
        res.end();
        return;
    }
    // --- GET / → dashboard HTML ---
    if (pathname === '/' && method === 'GET') {
        const html = getDashboardHtml();
        res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
        res.end(html);
        return;
    }
    // --- GET /api/status ---
    if (pathname === '/api/status' && method === 'GET') {
        jsonResponse(res, buildStatus());
        return;
    }
    // --- GET /api/outputs ---
    if (pathname === '/api/outputs' && method === 'GET') {
        const collection = parsedUrl.query['collection'];
        jsonResponse(res, loadOutputs(collection));
        return;
    }
    // --- GET /api/queue ---
    if (pathname === '/api/queue' && method === 'GET') {
        let queue = loadQueue();
        const pt = parsedUrl.query['page_type'];
        const st = parsedUrl.query['status'];
        if (pt)
            queue = queue.filter(p => p.page_type === pt);
        if (st)
            queue = queue.filter(p => p.status === st);
        jsonResponse(res, queue);
        return;
    }
    // --- GET /api/browser-status ---
    if (pathname === '/api/browser-status' && method === 'GET') {
        jsonResponse(res, { ready: browser !== null && browser.isConnected() });
        return;
    }
    // --- POST /api/action ---
    if (pathname === '/api/action' && method === 'POST') {
        const raw = await readBody(req);
        let body = {};
        try {
            body = JSON.parse(raw);
        }
        catch { /* ignore */ }
        const action = body.action || 'status';
        const validActions = ['seed', 'step', 'status', 'reset'];
        if (!validActions.includes(action)) {
            jsonResponse(res, { error: `Unknown action: ${action}` }, 400);
            return;
        }
        spawnRunner(action, { page_type: body.page_type, count: body.count }, res);
        return;
    }
    // --- POST /api/browser-fetch ---
    if (pathname === '/api/browser-fetch' && method === 'POST') {
        const raw = await readBody(req);
        let body = {};
        try {
            body = JSON.parse(raw);
        }
        catch { /* ignore */ }
        if (!body.url) {
            jsonResponse(res, { error: 'url is required' }, 400);
            return;
        }
        try {
            const result = await handleBrowserFetch({
                url: body.url,
                headers: body.headers,
                method: body.method,
                body: body.body,
            });
            jsonResponse(res, result);
        }
        catch (err) {
            const msg = err instanceof Error ? err.message : String(err);
            jsonResponse(res, { html: '', status: 0, url: body.url, error: msg }, 500);
        }
        return;
    }
    // 404
    jsonResponse(res, { error: 'Not found', path: pathname }, 404);
}
// ---------------------------------------------------------------------------
// Start server
// ---------------------------------------------------------------------------
const server = http.createServer((req, res) => {
    handleRequest(req, res).catch(err => {
        console.error('Handler error:', err);
        if (!res.headersSent) {
            jsonResponse(res, { error: String(err) }, 500);
        }
    });
});
server.listen(port, () => {
    console.log(`DataHen Local Dev Dashboard`);
    console.log(`  Scraper : ${scraperDir}`);
    console.log(`  URL     : http://localhost:${port}`);
    console.log(`  Press Ctrl+C to stop`);
});
process.on('SIGINT', async () => {
    console.log('\nShutting down...');
    if (browser)
        await browser.close().catch(() => { });
    server.close(() => process.exit(0));
});
