#!/usr/bin/env node
/* render-spec.mjs — render SDD markdown documents to styled, self-contained HTML.
 *
 * Usage:
 *   node scripts/render-spec.mjs <file.md | directory> [more paths...] [--assets DIR] [--out FILE]
 *
 *   - A directory argument renders every *.md file directly inside it that has
 *     YAML frontmatter (other .md files are skipped).
 *   - Output is written next to each source file as <name>.html, unless --out
 *     is given with a single input file.
 *   - --assets DIR points at the directory holding spec.css, spec.js and
 *     spec-shell.html.template. Default: walk up from each source file looking
 *     for .claude/skills/sdd-workflow/templates/, falling back to the kit
 *     layout (templates/specs/ next to this script).
 *
 * The markdown conventions this renderer understands are documented in
 * skills/sdd-workflow/spec-format.md (vendored to
 * .claude/skills/sdd-workflow/spec-format.md in installed projects).
 *
 * KEEP IN SYNC with scripts/render_spec.py — both renderers must accept the
 * same input conventions and produce equivalent HTML.
 */

import { readFileSync, writeFileSync, existsSync, statSync, readdirSync } from 'node:fs';
import { dirname, join, resolve, basename } from 'node:path';
import { fileURLToPath } from 'node:url';

/* ── Shared vocabulary ─────────────────────────────────────────── */

// Frontmatter keys whose values render as status badges.
const BADGE_KEYS = new Set([
  'status', 'approval', 'human_approval', 'review_status', 'decision',
  'documentation_status',
]);

// Frontmatter keys whose values render as <code>.
const CODE_KEY_SUFFIXES = ['_id', '_slug', '_document', '_path', '_command', '_date'];
const CODE_KEYS = new Set(['task_id', 'feature_slug', 'source_document', 'created', 'spec']);

// status word → badge variant
const BADGE_VARIANTS = {
  draft: 'draft', spec_draft: 'draft',
  pending: 'pending', spec_ready: 'pending', in_progress: 'pending', todo: 'pending',
  ok: 'ok', approved: 'approved', accepted: 'ok', resolved: 'ok', done: 'ok',
  human_approved: 'ok', updated: 'ok', pass: 'ok', passed: 'ok', not_required: 'ok',
  blocking: 'blocking', rejected: 'rejected', failed: 'blocking', fail: 'blocking',
  spec_revision_required: 'blocking',
  warning: 'warning', needs_changes: 'warning', deferred: 'warning', blocked: 'warning',
};

// requirement-ID prefix → .req-id variant class ('' = default orange)
const REQ_ID_CLASSES = [
  [/^NFR/, 'nfr'],
  [/^EDGE/, 'edge'],
  [/^(ERR|BLK)/, 'err'],
  [/^AT-EDGE/, 'edge'],
  [/^AT-ERR/, 'err'],
  [/^(AC|UI|IMG)/, 'ac'],
  [/^NBK/, 'edge'],
  [/^T-?\d/, 't'],
];

// A standalone requirement-style ID token (REQ-001, AT-EDGE-1, Q1, T3, R2 …)
const ID_TOKEN = /^([A-Z]{1,4}(?:-[A-Z]{1,4})?-?\d+(?:\.\d+)*)$/;
// A block-level requirement row: "REQ-001: text"
const REQ_ROW = /^([A-Z]{1,4}(?:-[A-Z]{1,4})?-?\d+(?:\.\d+)*):\s+(.+)$/;
// Inline badge: [!ok text]
const INLINE_BADGE = /\[!(draft|pending|ok|approved|blocking|rejected|warning)\s+([^\]]+)\]/g;
// Cell verdict marker: "!ok Yes"
const CELL_VERDICT = /^!(ok|warning|blocking|pending)(?:\s+(.*))?$/;
// Task/checklist status marker at start of a list item
const ITEM_STATUS = /^\[([ x>!])\]\s+/;
const ITEM_STATUS_CLASS = { x: 'done', '>': 'in-progress', '!': 'blocked', ' ': '' };

/* ── Small helpers ─────────────────────────────────────────────── */

function escapeHtml(s) {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

function slugify(s) {
  return s.toLowerCase().replace(/`/g, '').replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
}

function reqIdClass(id) {
  for (const [re, cls] of REQ_ID_CLASSES) if (re.test(id)) return cls;
  return '';
}

function reqIdSpan(id) {
  const cls = reqIdClass(id);
  return `<span class="req-id${cls ? ' ' + cls : ''}">${escapeHtml(id)}</span>`;
}

function badgeSpan(word) {
  const variant = BADGE_VARIANTS[word.toLowerCase()] || 'draft';
  return `<span class="badge badge-${variant}">${escapeHtml(word)}</span>`;
}

/* ── Inline markdown ───────────────────────────────────────────── */

function inline(text) {
  // Protect code spans from further processing (NUL sentinels cannot
  // collide with document text).
  const codes = [];
  let s = text.replace(/`([^`]+)`/g, (_, code) => {
    codes.push(`<code>${escapeHtml(code)}</code>`);
    return `\x00${codes.length - 1}\x00`;
  });
  s = escapeHtml(s);
  s = s.replace(INLINE_BADGE, (_, variant, label) =>
    `<span class="badge badge-${variant}">${label}</span>`);
  s = s.replace(/\[([^\]]+)\]\(([^)\s]+)\)/g, '<a href="$2">$1</a>');
  s = s.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
  s = s.replace(/\*([^*]+)\*/g, '<em>$1</em>');
  s = s.replace(/\x00(\d+)\x00/g, (_, i) => codes[Number(i)]);
  return s;
}

/* ── Frontmatter ───────────────────────────────────────────────── */

function parseFrontmatter(text) {
  const meta = [];
  if (!text.startsWith('---')) return { meta, body: text };
  const lines = text.split(/\r?\n/);
  let end = -1;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i].trim() === '---') { end = i; break; }
  }
  if (end === -1) return { meta, body: text };
  for (let i = 1; i < end; i++) {
    const line = lines[i];
    if (!line.trim() || line.trim().startsWith('#')) continue;
    const m = line.match(/^([A-Za-z0-9_-]+):\s*(.*)$/);
    if (m) meta.push([m[1], m[2].trim()]);
  }
  return { meta, body: lines.slice(end + 1).join('\n') };
}

function metaValue(key, value) {
  if (BADGE_KEYS.has(key)) return badgeSpan(value);
  if (CODE_KEYS.has(key) || CODE_KEY_SUFFIXES.some((suf) => key.endsWith(suf))) {
    return `<code>${escapeHtml(value)}</code>`;
  }
  return inline(value);
}

function metaTable(meta) {
  const rows = meta
    .filter(([k]) => k !== 'title' && k !== 'doc')
    .map(([k, v]) => {
      const label = escapeHtml(k.replace(/_/g, ' ').replace(/^./, (c) => c.toUpperCase()));
      return `          <tr><th>${label}</th><td>${metaValue(k, v)}</td></tr>`;
    });
  if (!rows.length) return '';
  return `      <table class="meta-table">\n        <tbody>\n${rows.join('\n')}\n        </tbody>\n      </table>`;
}

/* ── Block-level markdown ──────────────────────────────────────── */

function parseBlocks(lines, out, container) {
  let i = 0;
  const n = lines.length;

  const cardState = container && container.type === 'card'
    ? { headerDone: false, bodyOpen: false } : null;

  function ensureCardBody() {
    if (cardState && !cardState.bodyOpen) {
      out.push('<div class="card-body">');
      cardState.bodyOpen = true;
    }
  }

  while (i < n) {
    const line = lines[i];
    const trimmed = line.trim();

    if (!trimmed) { i++; continue; }

    // Fenced code block
    if (trimmed.startsWith('```')) {
      ensureCardBody();
      const lang = trimmed.slice(3).trim();
      const code = [];
      i++;
      while (i < n && !lines[i].trim().startsWith('```')) { code.push(lines[i]); i++; }
      i++; // closing fence
      const cls = lang ? ` class="language-${escapeHtml(lang)}"` : '';
      out.push(`<pre><code${cls}>${escapeHtml(code.join('\n'))}</code></pre>`);
      continue;
    }

    // Container: ::: name [classes...]  /  ::: closes
    if (trimmed.startsWith(':::')) {
      const spec = trimmed.slice(3).trim();
      if (!spec) { i++; continue; } // stray close, handled by caller
      const inner = [];
      let depth = 1;
      i++;
      while (i < n) {
        const t = lines[i].trim();
        if (t.startsWith(':::') && t.slice(3).trim()) depth++;
        else if (t === ':::') { depth--; if (depth === 0) break; }
        inner.push(lines[i]);
        i++;
      }
      i++; // closing :::
      ensureCardBody();
      renderContainer(spec, inner, out);
      continue;
    }

    // Raw HTML block (passes through untouched until a blank line)
    if (/^</.test(trimmed)) {
      ensureCardBody();
      const raw = [];
      while (i < n && lines[i].trim()) { raw.push(lines[i]); i++; }
      out.push(raw.join('\n'));
      continue;
    }

    // Heading
    const h = trimmed.match(/^(#{1,4})\s+(.*)$/);
    if (h) {
      const level = h[1].length;
      const text = h[2].trim();
      // Inside a card, a leading #### becomes the card header.
      if (cardState && level === 4 && !cardState.headerDone && !cardState.bodyOpen) {
        out.push(renderCardHeader(text));
        cardState.headerDone = true;
        i++;
        continue;
      }
      ensureCardBody();
      const id = slugify(text);
      out.push(`<h${level} id="${id}">${inline(text)}</h${level}>`);
      i++;
      continue;
    }

    // Horizontal rule
    if (/^(-{3,}|\*{3,})$/.test(trimmed)) { ensureCardBody(); out.push('<hr>'); i++; continue; }

    // Table
    if (trimmed.startsWith('|') && i + 1 < n && /^\|[\s:|-]+\|?$/.test(lines[i + 1].trim())) {
      ensureCardBody();
      const tbl = [];
      while (i < n && lines[i].trim().startsWith('|')) { tbl.push(lines[i].trim()); i++; }
      out.push(renderTable(tbl));
      continue;
    }

    // List
    if (/^(\s*)([-*]|\d+\.)\s+/.test(line)) {
      const block = [];
      while (i < n && lines[i].trim() !== '') {
        if (!/^(\s*)([-*]|\d+\.)\s+/.test(lines[i]) && !/^\s{2,}\S/.test(lines[i])) break;
        block.push(lines[i]);
        i++;
      }
      ensureCardBody();
      out.push(renderList(block, container));
      continue;
    }

    // Blockquote
    if (trimmed.startsWith('>')) {
      ensureCardBody();
      const quote = [];
      while (i < n && lines[i].trim().startsWith('>')) {
        quote.push(lines[i].trim().replace(/^>\s?/, ''));
        i++;
      }
      out.push(`<blockquote><p>${inline(quote.join(' '))}</p></blockquote>`);
      continue;
    }

    // Requirement row: "REQ-001: text"
    const req = trimmed.match(REQ_ROW);
    if (req) {
      ensureCardBody();
      const cls = reqIdClass(req[1]);
      out.push(`<div class="req-row${cls ? ' ' + cls : ''}">${reqIdSpan(req[1])}<span>${inline(req[2])}</span></div>`);
      i++;
      continue;
    }

    // Paragraph
    ensureCardBody();
    const para = [];
    while (i < n && lines[i].trim() && !/^(#{1,4}\s|```|:::|\||[-*]\s|\d+\.\s|>|<)/.test(lines[i].trim())
      && !REQ_ROW.test(lines[i].trim()) && !/^(-{3,}|\*{3,})$/.test(lines[i].trim())) {
      para.push(lines[i].trim());
      i++;
    }
    if (para.length) out.push(`<p>${inline(para.join(' '))}</p>`);
    else i++;
  }

  if (cardState && cardState.bodyOpen) out.push('</div>');
}

/* ── Containers ────────────────────────────────────────────────── */

function renderContainer(spec, innerLines, out) {
  const parts = spec.split(/\s+/);
  const kind = parts[0];

  if (kind === 'collapse') {
    const title = spec.slice('collapse'.length).trim() || 'Details';
    out.push('<div class="collapsible-section">');
    out.push(`<button class="collapse-btn" type="button"><span class="arrow">▾</span> ${inline(title)}</button>`);
    out.push('<div class="collapse-body">');
    parseBlocks(innerLines, out, { type: 'collapse' });
    out.push('</div></div>');
    return;
  }

  if (kind === 'card') {
    const extra = parts.slice(1).filter((c) => /^[a-z0-9-]+$/.test(c)).join(' ');
    out.push(`<div class="card${extra ? ' ' + extra : ''}">`);
    parseBlocks(innerLines, out, { type: 'card' });
    out.push('</div>');
    return;
  }

  if (kind === 'note') {
    out.push('<div class="claude-note">');
    parseBlocks(innerLines, out, { type: 'note' });
    out.push('</div>');
    return;
  }

  if (kind === 'diagram') {
    out.push('<div class="diagram-container">');
    parseBlocks(innerLines, out, { type: 'diagram' });
    out.push('</div>');
    return;
  }

  // Generic: treat the words as CSS classes.
  out.push(`<div class="${escapeHtml(spec)}">`);
  parseBlocks(innerLines, out, { type: 'generic' });
  out.push('</div>');
}

// "#### A1 — Title [!pending Pending]" → card header
function renderCardHeader(text) {
  let rest = text;
  let idSpan = '';
  const idMatch = rest.match(/^([A-Z]{1,4}(?:-[A-Z]{1,4})?-?\d+)\s*[—-]\s*/);
  if (idMatch) {
    idSpan = reqIdSpan(idMatch[1]);
    rest = rest.slice(idMatch[0].length);
  }
  let badge = '';
  const badgeMatch = rest.match(/\[!(draft|pending|ok|approved|blocking|rejected|warning)\s+([^\]]+)\]\s*$/);
  if (badgeMatch) {
    badge = `<span class="badge badge-${badgeMatch[1]}">${escapeHtml(badgeMatch[2])}</span>`;
    rest = rest.slice(0, badgeMatch.index).trim();
  }
  return `<div class="card-header">${idSpan}<span class="card-title">${inline(rest)}</span>${badge}</div>`;
}

/* ── Tables ────────────────────────────────────────────────────── */

function splitRow(row) {
  const cells = [];
  let cur = '';
  let inCode = false;
  for (const ch of row.replace(/^\|/, '').replace(/\|$/, '')) {
    if (ch === '`') inCode = !inCode;
    if (ch === '|' && !inCode) { cells.push(cur.trim()); cur = ''; }
    else cur += ch;
  }
  cells.push(cur.trim());
  return cells;
}

function renderCell(raw, tag) {
  let cls = '';
  let content = raw;
  const verdict = raw.match(CELL_VERDICT);
  if (verdict) {
    cls = ` class="${verdict[1]}"`;
    content = verdict[2] || verdict[1];
  }
  const idTok = content.match(ID_TOKEN);
  const html = idTok ? reqIdSpan(idTok[1]) : inline(content);
  return `<${tag}${cls}>${html}</${tag}>`;
}

function renderTable(rows) {
  const header = splitRow(rows[0]);
  const body = rows.slice(2).map(splitRow);
  const thead = `<thead>\n<tr>${header.map((c) => `<th>${inline(c)}</th>`).join('')}</tr>\n</thead>`;
  const tbody = body.length
    ? `\n<tbody>\n${body.map((r) => `<tr>${r.map((c) => renderCell(c, 'td')).join('')}</tr>`).join('\n')}\n</tbody>`
    : '';
  return `<table>\n${thead}${tbody}\n</table>`;
}

/* ── Lists ─────────────────────────────────────────────────────── */

function parseListItems(lines) {
  // Returns [{marker: '-'|'1.', text, children: [lines]}]
  const items = [];
  let baseIndent = null;
  for (const line of lines) {
    const m = line.match(/^(\s*)([-*]|\d+\.)\s+(.*)$/);
    if (m && (baseIndent === null || m[1].length <= baseIndent)) {
      if (baseIndent === null) baseIndent = m[1].length;
      if (m[1].length === baseIndent) {
        items.push({ marker: m[2], text: m[3], children: [] });
        continue;
      }
    }
    if (items.length) items[items.length - 1].children.push(line);
  }
  return items;
}

function renderList(lines, container) {
  const items = parseListItems(lines);
  if (!items.length) return '';
  const ordered = /^\d+\.$/.test(items[0].marker);

  // Task timeline: ordered list whose items carry a status marker.
  if (ordered && items.every((it) => ITEM_STATUS.test(it.text))) {
    return renderTimeline(items);
  }
  // Checklist: unordered list whose items carry a "[ ]"-style marker.
  if (!ordered && items.every((it) => ITEM_STATUS.test(it.text))) {
    const lis = items.map((it) => `<li>${inline(it.text.replace(ITEM_STATUS, ''))}</li>`);
    return `<ul class="checklist">\n${lis.join('\n')}\n</ul>`;
  }
  // Field list inside a card: every item "**Key:** value" → dl.card-fields
  if (container && container.type === 'card'
    && items.every((it) => /^\*\*[^*]+:\*\*\s/.test(it.text))) {
    const rows = items.map((it) => {
      const m = it.text.match(/^\*\*([^*]+):\*\*\s+(.*)$/);
      return `<dt>${inline(m[1])}</dt><dd>${inline(m[2])}</dd>`;
    });
    return `<dl class="card-fields">\n${rows.join('\n')}\n</dl>`;
  }

  const tag = ordered ? 'ol' : 'ul';
  const lis = items.map((it) => {
    let inner = inline(it.text);
    if (it.children.length) {
      const childOut = [];
      const dedented = dedent(it.children);
      if (dedented.some((l) => /^(\s*)([-*]|\d+\.)\s+/.test(l))) {
        childOut.push(renderList(dedented, container));
      } else {
        childOut.push(`<p>${inline(dedented.join(' ').trim())}</p>`);
      }
      inner += '\n' + childOut.join('\n');
    }
    return `<li>${inner}</li>`;
  });
  return `<${tag}>\n${lis.join('\n')}\n</${tag}>`;
}

function dedent(lines) {
  const indents = lines.filter((l) => l.trim()).map((l) => l.match(/^\s*/)[0].length);
  const min = indents.length ? Math.min(...indents) : 0;
  return lines.map((l) => l.slice(min));
}

function renderTimeline(items) {
  const lis = items.map((it) => {
    const statusCh = it.text.match(ITEM_STATUS)[1];
    const status = ITEM_STATUS_CLASS[statusCh];
    let rest = it.text.replace(ITEM_STATUS, '');
    let chip = '';
    const idm = rest.match(/^(T-?\d+(?:\.\d+)*):\s*/);
    if (idm) { chip = reqIdSpan(idm[1]); rest = rest.slice(idm[0].length); }
    const parts = rest.split(' — ');
    const title = parts[0];
    const body = parts.slice(1).join(' — ');
    const bodyHtml = body ? `\n<div class="task-item-body">${inline(body)}</div>` : '';
    return `<li class="task-item${status ? ' ' + status : ''}">\n<div class="task-item-header">${chip}<strong>${inline(title)}</strong></div>${bodyHtml}\n</li>`;
  });
  return `<ol class="task-timeline">\n${lis.join('\n')}\n</ol>`;
}

/* ── Document assembly ─────────────────────────────────────────── */

function renderDocument(mdText, assets) {
  const { meta, body } = parseFrontmatter(mdText);
  const metaMap = Object.fromEntries(meta);
  const title = metaMap.title || 'SDD document';
  const out = [];
  parseBlocks(body.split(/\r?\n/), out, null);
  return assets.shell
    .replaceAll('{{TITLE}}', escapeHtml(title)) // appears in <title> and <h1>
    .replace('{{CSS}}', assets.css)
    .replace('{{META_TABLE}}', metaTable(meta))
    .replace('{{BODY}}', out.join('\n'))
    .replace('{{JS}}', assets.js);
}

/* ── Asset resolution ──────────────────────────────────────────── */

function findAssetsDir(startDir, explicit) {
  const candidates = [];
  if (explicit) candidates.push(resolve(explicit));
  let dir = resolve(startDir);
  for (let hops = 0; hops < 12; hops++) {
    candidates.push(join(dir, '.claude', 'skills', 'sdd-workflow', 'templates'));
    const parent = dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }
  const scriptDir = dirname(fileURLToPath(import.meta.url));
  candidates.push(join(scriptDir, '..', 'templates', 'specs')); // kit layout
  for (const c of candidates) {
    if (existsSync(join(c, 'spec.css'))) return c;
  }
  return null;
}

function loadAssets(dir) {
  const shellPath = [join(dir, 'spec-shell.html.template'), join(dir, 'spec-shell.html')]
    .find((p) => existsSync(p));
  if (!shellPath) throw new Error(`spec-shell.html.template not found in ${dir}`);
  const read = (p) => readFileSync(p, 'utf8').replace(/\r\n/g, '\n');
  return {
    shell: read(shellPath),
    css: read(join(dir, 'spec.css')),
    js: read(join(dir, 'spec.js')),
  };
}

/* ── CLI ───────────────────────────────────────────────────────── */

function collectSources(paths) {
  const files = [];
  for (const p of paths) {
    const abs = resolve(p);
    if (!existsSync(abs)) { console.error(`skip (not found): ${p}`); continue; }
    if (statSync(abs).isDirectory()) {
      for (const name of readdirSync(abs)) {
        if (!name.endsWith('.md')) continue;
        const f = join(abs, name);
        if (readFileSync(f, 'utf8').startsWith('---')) files.push(f);
      }
    } else {
      files.push(abs);
    }
  }
  return files;
}

function main() {
  const args = process.argv.slice(2);
  const paths = [];
  let assetsDir = null;
  let outFile = null;
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--assets') assetsDir = args[++i];
    else if (args[i] === '--out') outFile = args[++i];
    else paths.push(args[i]);
  }
  if (!paths.length) {
    console.error('Usage: node render-spec.mjs <file.md | dir> [...] [--assets DIR] [--out FILE]');
    process.exit(1);
  }
  const files = collectSources(paths);
  if (!files.length) { console.error('No markdown sources found.'); process.exit(1); }
  if (outFile && files.length > 1) {
    console.error('--out requires a single input file.');
    process.exit(1);
  }
  for (const file of files) {
    const dir = findAssetsDir(dirname(file), assetsDir);
    if (!dir) { console.error(`assets not found for ${file} (use --assets)`); process.exit(1); }
    const assets = loadAssets(dir);
    const html = renderDocument(readFileSync(file, 'utf8'), assets);
    const target = outFile ? resolve(outFile) : file.replace(/\.md$/, '.html');
    writeFileSync(target, html);
    console.log(`rendered ${basename(file)} -> ${target}`);
  }
}

main();
