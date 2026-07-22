#!/usr/bin/env python3
"""render_spec.py -- render SDD markdown documents to styled, self-contained HTML.

Usage:
    python scripts/render_spec.py <file.md | directory> [more paths...] [--assets DIR] [--out FILE]

    - A directory argument renders every *.md file directly inside it that has
      YAML frontmatter (other .md files are skipped).
    - Output is written next to each source file as <name>.html, unless --out
      is given with a single input file.
    - --assets DIR points at the directory holding spec.css, spec.js and
      spec-shell.html.template. Default: walk up from each source file looking
      for .claude/skills/sdd-workflow/templates/, falling back to the kit
      layout (templates/specs/ next to this script).

The markdown conventions this renderer understands are documented in
skills/sdd-workflow/spec-format.md (vendored to
.claude/skills/sdd-workflow/spec-format.md in installed projects).

KEEP IN SYNC with scripts/render-spec.mjs -- both renderers must accept the
same input conventions and produce equivalent HTML.

Zero dependencies: standard library only.
"""

import os
import re
import sys

# ── Shared vocabulary ──────────────────────────────────────────────

BADGE_KEYS = {
    "status", "approval", "human_approval", "review_status", "decision",
    "documentation_status",
}

CODE_KEY_SUFFIXES = ("_id", "_slug", "_document", "_path", "_command", "_date")
CODE_KEYS = {"task_id", "feature_slug", "source_document", "created", "spec"}

BADGE_VARIANTS = {
    "draft": "draft", "spec_draft": "draft",
    "pending": "pending", "spec_ready": "pending", "in_progress": "pending", "todo": "pending",
    "ok": "ok", "approved": "approved", "accepted": "ok", "resolved": "ok", "done": "ok",
    "human_approved": "ok", "updated": "ok", "pass": "ok", "passed": "ok", "not_required": "ok",
    "blocking": "blocking", "rejected": "rejected", "failed": "blocking", "fail": "blocking",
    "spec_revision_required": "blocking",
    "warning": "warning", "needs_changes": "warning", "deferred": "warning", "blocked": "warning",
}

REQ_ID_CLASSES = [
    (re.compile(r"^NFR"), "nfr"),
    (re.compile(r"^EDGE"), "edge"),
    (re.compile(r"^(ERR|BLK)"), "err"),
    (re.compile(r"^AT-EDGE"), "edge"),
    (re.compile(r"^AT-ERR"), "err"),
    (re.compile(r"^(AC|UI|IMG)"), "ac"),
    (re.compile(r"^NBK"), "edge"),
    (re.compile(r"^T\d"), "t"),
]

ID_TOKEN = re.compile(r"^([A-Z]{1,4}(?:-[A-Z]{1,4})?-?\d+)$")
REQ_ROW = re.compile(r"^([A-Z]{1,4}(?:-[A-Z]{1,4})?-?\d+):\s+(.+)$")
INLINE_BADGE = re.compile(
    r"\[!(draft|pending|ok|approved|blocking|rejected|warning)\s+([^\]]+)\]")
CELL_VERDICT = re.compile(r"^!(ok|warning|blocking|pending)(?:\s+(.*))?$")
ITEM_STATUS = re.compile(r"^\[([ x>!])\]\s+")
ITEM_STATUS_CLASS = {"x": "done", ">": "in-progress", "!": "blocked", " ": ""}

LIST_ITEM = re.compile(r"^(\s*)([-*]|\d+\.)\s+(.*)$")

# ── Small helpers ──────────────────────────────────────────────────


def escape_html(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def slugify(s):
    s = s.lower().replace("`", "")
    s = re.sub(r"[^a-z0-9]+", "-", s)
    return s.strip("-")


def req_id_class(rid):
    for rx, cls in REQ_ID_CLASSES:
        if rx.match(rid):
            return cls
    return ""


def req_id_span(rid):
    cls = req_id_class(rid)
    cls_attr = " " + cls if cls else ""
    return '<span class="req-id%s">%s</span>' % (cls_attr, escape_html(rid))


def badge_span(word):
    variant = BADGE_VARIANTS.get(word.lower(), "draft")
    return '<span class="badge badge-%s">%s</span>' % (variant, escape_html(word))


# ── Inline markdown ────────────────────────────────────────────────


def inline(text):
    # Protect code spans from further processing (NUL sentinels cannot
    # collide with document text).
    codes = []

    def stash(m):
        codes.append("<code>%s</code>" % escape_html(m.group(1)))
        return "\x00%d\x00" % (len(codes) - 1)

    s = re.sub(r"`([^`]+)`", stash, text)
    s = escape_html(s)
    s = INLINE_BADGE.sub(
        lambda m: '<span class="badge badge-%s">%s</span>' % (m.group(1), m.group(2)), s)
    s = re.sub(r"\[([^\]]+)\]\(([^)\s]+)\)", r'<a href="\2">\1</a>', s)
    s = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", s)
    s = re.sub(r"\*([^*]+)\*", r"<em>\1</em>", s)
    s = re.sub(r"\x00(\d+)\x00", lambda m: codes[int(m.group(1))], s)
    return s


# ── Frontmatter ────────────────────────────────────────────────────


def parse_frontmatter(text):
    meta = []
    if not text.startswith("---"):
        return meta, text
    lines = text.split("\n")
    end = -1
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            end = i
            break
    if end == -1:
        return meta, text
    for i in range(1, end):
        line = lines[i]
        if not line.strip() or line.strip().startswith("#"):
            continue
        m = re.match(r"^([A-Za-z0-9_-]+):\s*(.*)$", line)
        if m:
            meta.append((m.group(1), m.group(2).strip()))
    return meta, "\n".join(lines[end + 1:])


def meta_value(key, value):
    if key in BADGE_KEYS:
        return badge_span(value)
    if key in CODE_KEYS or key.endswith(CODE_KEY_SUFFIXES):
        return "<code>%s</code>" % escape_html(value)
    return inline(value)


def meta_table(meta):
    rows = []
    for k, v in meta:
        if k in ("title", "doc"):
            continue
        label = escape_html(k.replace("_", " ").capitalize())
        rows.append("          <tr><th>%s</th><td>%s</td></tr>" % (label, meta_value(k, v)))
    if not rows:
        return ""
    return ('      <table class="meta-table">\n        <tbody>\n%s\n'
            "        </tbody>\n      </table>" % "\n".join(rows))


# ── Block-level markdown ───────────────────────────────────────────


def parse_blocks(lines, out, container):
    i = 0
    n = len(lines)

    card_state = {"header_done": False, "body_open": False} \
        if container and container.get("type") == "card" else None

    def ensure_card_body():
        if card_state and not card_state["body_open"]:
            out.append('<div class="card-body">')
            card_state["body_open"] = True

    while i < n:
        line = lines[i]
        trimmed = line.strip()

        if not trimmed:
            i += 1
            continue

        # Fenced code block
        if trimmed.startswith("```"):
            ensure_card_body()
            lang = trimmed[3:].strip()
            code = []
            i += 1
            while i < n and not lines[i].strip().startswith("```"):
                code.append(lines[i])
                i += 1
            i += 1  # closing fence
            cls = ' class="language-%s"' % escape_html(lang) if lang else ""
            out.append("<pre><code%s>%s</code></pre>" % (cls, escape_html("\n".join(code))))
            continue

        # Container: ::: name [classes...]  /  ::: closes
        if trimmed.startswith(":::"):
            spec = trimmed[3:].strip()
            if not spec:
                i += 1
                continue  # stray close, handled by caller
            inner = []
            depth = 1
            i += 1
            while i < n:
                t = lines[i].strip()
                if t.startswith(":::") and t[3:].strip():
                    depth += 1
                elif t == ":::":
                    depth -= 1
                    if depth == 0:
                        break
                inner.append(lines[i])
                i += 1
            i += 1  # closing :::
            ensure_card_body()
            render_container(spec, inner, out)
            continue

        # Raw HTML block (passes through untouched until a blank line)
        if trimmed.startswith("<"):
            ensure_card_body()
            raw = []
            while i < n and lines[i].strip():
                raw.append(lines[i])
                i += 1
            out.append("\n".join(raw))
            continue

        # Heading
        h = re.match(r"^(#{1,4})\s+(.*)$", trimmed)
        if h:
            level = len(h.group(1))
            text = h.group(2).strip()
            # Inside a card, a leading #### becomes the card header.
            if card_state and level == 4 and not card_state["header_done"] \
                    and not card_state["body_open"]:
                out.append(render_card_header(text))
                card_state["header_done"] = True
                i += 1
                continue
            ensure_card_body()
            hid = slugify(text)
            out.append('<h%d id="%s">%s</h%d>' % (level, hid, inline(text), level))
            i += 1
            continue

        # Horizontal rule
        if re.match(r"^(-{3,}|\*{3,})$", trimmed):
            ensure_card_body()
            out.append("<hr>")
            i += 1
            continue

        # Table
        if trimmed.startswith("|") and i + 1 < n \
                and re.match(r"^\|[\s:|-]+\|?$", lines[i + 1].strip()):
            ensure_card_body()
            tbl = []
            while i < n and lines[i].strip().startswith("|"):
                tbl.append(lines[i].strip())
                i += 1
            out.append(render_table(tbl))
            continue

        # List
        if LIST_ITEM.match(line):
            block = []
            while i < n and lines[i].strip() != "":
                if not LIST_ITEM.match(lines[i]) and not re.match(r"^\s{2,}\S", lines[i]):
                    break
                block.append(lines[i])
                i += 1
            ensure_card_body()
            out.append(render_list(block, container))
            continue

        # Blockquote
        if trimmed.startswith(">"):
            ensure_card_body()
            quote = []
            while i < n and lines[i].strip().startswith(">"):
                quote.append(re.sub(r"^>\s?", "", lines[i].strip()))
                i += 1
            out.append("<blockquote><p>%s</p></blockquote>" % inline(" ".join(quote)))
            continue

        # Requirement row: "REQ-001: text"
        req = REQ_ROW.match(trimmed)
        if req:
            ensure_card_body()
            cls = req_id_class(req.group(1))
            cls_attr = " " + cls if cls else ""
            out.append('<div class="req-row%s">%s<span>%s</span></div>'
                       % (cls_attr, req_id_span(req.group(1)), inline(req.group(2))))
            i += 1
            continue

        # Paragraph
        ensure_card_body()
        para = []
        while i < n and lines[i].strip() \
                and not re.match(r"^(#{1,4}\s|```|:::|\||[-*]\s|\d+\.\s|>|<)", lines[i].strip()) \
                and not REQ_ROW.match(lines[i].strip()) \
                and not re.match(r"^(-{3,}|\*{3,})$", lines[i].strip()):
            para.append(lines[i].strip())
            i += 1
        if para:
            out.append("<p>%s</p>" % inline(" ".join(para)))
        else:
            i += 1

    if card_state and card_state["body_open"]:
        out.append("</div>")


# ── Containers ─────────────────────────────────────────────────────


def render_container(spec, inner_lines, out):
    parts = spec.split()
    kind = parts[0]

    if kind == "collapse":
        title = spec[len("collapse"):].strip() or "Details"
        out.append('<div class="collapsible-section">')
        out.append('<button class="collapse-btn" type="button">'
                   '<span class="arrow">▾</span> %s</button>' % inline(title))
        out.append('<div class="collapse-body">')
        parse_blocks(inner_lines, out, {"type": "collapse"})
        out.append("</div></div>")
        return

    if kind == "card":
        extra = " ".join(c for c in parts[1:] if re.match(r"^[a-z0-9-]+$", c))
        out.append('<div class="card%s">' % (" " + extra if extra else ""))
        parse_blocks(inner_lines, out, {"type": "card"})
        out.append("</div>")
        return

    if kind == "note":
        out.append('<div class="claude-note">')
        parse_blocks(inner_lines, out, {"type": "note"})
        out.append("</div>")
        return

    if kind == "diagram":
        out.append('<div class="diagram-container">')
        parse_blocks(inner_lines, out, {"type": "diagram"})
        out.append("</div>")
        return

    # Generic: treat the words as CSS classes.
    out.append('<div class="%s">' % escape_html(spec))
    parse_blocks(inner_lines, out, {"type": "generic"})
    out.append("</div>")


def render_card_header(text):
    # "#### A1 — Title [!pending Pending]" → card header
    rest = text
    id_span = ""
    id_match = re.match(r"^([A-Z]{1,4}(?:-[A-Z]{1,4})?-?\d+)\s*[—-]\s*", rest)
    if id_match:
        id_span = req_id_span(id_match.group(1))
        rest = rest[id_match.end():]
    badge = ""
    badge_match = re.search(
        r"\[!(draft|pending|ok|approved|blocking|rejected|warning)\s+([^\]]+)\]\s*$", rest)
    if badge_match:
        badge = '<span class="badge badge-%s">%s</span>' % (
            badge_match.group(1), escape_html(badge_match.group(2)))
        rest = rest[:badge_match.start()].strip()
    return '<div class="card-header">%s<span class="card-title">%s</span>%s</div>' % (
        id_span, inline(rest), badge)


# ── Tables ─────────────────────────────────────────────────────────


def split_row(row):
    cells = []
    cur = ""
    in_code = False
    body = re.sub(r"^\|", "", re.sub(r"\|$", "", row))
    for ch in body:
        if ch == "`":
            in_code = not in_code
        if ch == "|" and not in_code:
            cells.append(cur.strip())
            cur = ""
        else:
            cur += ch
    cells.append(cur.strip())
    return cells


def render_cell(raw, tag):
    cls = ""
    content = raw
    verdict = CELL_VERDICT.match(raw)
    if verdict:
        cls = ' class="%s"' % verdict.group(1)
        content = verdict.group(2) or verdict.group(1)
    id_tok = ID_TOKEN.match(content)
    html = req_id_span(id_tok.group(1)) if id_tok else inline(content)
    return "<%s%s>%s</%s>" % (tag, cls, html, tag)


def render_table(rows):
    header = split_row(rows[0])
    body = [split_row(r) for r in rows[2:]]
    thead = "<thead>\n<tr>%s</tr>\n</thead>" % "".join(
        "<th>%s</th>" % inline(c) for c in header)
    if body:
        tbody = "\n<tbody>\n%s\n</tbody>" % "\n".join(
            "<tr>%s</tr>" % "".join(render_cell(c, "td") for c in r) for r in body)
    else:
        tbody = ""
    return "<table>\n%s%s\n</table>" % (thead, tbody)


# ── Lists ──────────────────────────────────────────────────────────


def parse_list_items(lines):
    # Returns [{"marker": "-"|"1.", "text": str, "children": [lines]}]
    items = []
    base_indent = None
    for line in lines:
        m = LIST_ITEM.match(line)
        if m and (base_indent is None or len(m.group(1)) <= base_indent):
            if base_indent is None:
                base_indent = len(m.group(1))
            if len(m.group(1)) == base_indent:
                items.append({"marker": m.group(2), "text": m.group(3), "children": []})
                continue
        if items:
            items[-1]["children"].append(line)
    return items


def render_list(lines, container):
    items = parse_list_items(lines)
    if not items:
        return ""
    ordered = bool(re.match(r"^\d+\.$", items[0]["marker"]))

    # Task timeline: ordered list whose items carry a status marker.
    if ordered and all(ITEM_STATUS.match(it["text"]) for it in items):
        return render_timeline(items)
    # Checklist: unordered list whose items carry a "[ ]"-style marker.
    if not ordered and all(ITEM_STATUS.match(it["text"]) for it in items):
        lis = ["<li>%s</li>" % inline(ITEM_STATUS.sub("", it["text"])) for it in items]
        return '<ul class="checklist">\n%s\n</ul>' % "\n".join(lis)
    # Field list inside a card: every item "**Key:** value" → dl.card-fields
    if container and container.get("type") == "card" \
            and all(re.match(r"^\*\*[^*]+:\*\*\s", it["text"]) for it in items):
        rows = []
        for it in items:
            m = re.match(r"^\*\*([^*]+):\*\*\s+(.*)$", it["text"])
            rows.append("<dt>%s</dt><dd>%s</dd>" % (inline(m.group(1)), inline(m.group(2))))
        return '<dl class="card-fields">\n%s\n</dl>' % "\n".join(rows)

    tag = "ol" if ordered else "ul"
    lis = []
    for it in items:
        inner = inline(it["text"])
        if it["children"]:
            dedented = dedent(it["children"])
            if any(LIST_ITEM.match(l) for l in dedented):
                child = render_list(dedented, container)
            else:
                child = "<p>%s</p>" % inline(" ".join(dedented).strip())
            inner += "\n" + child
        lis.append("<li>%s</li>" % inner)
    return "<%s>\n%s\n</%s>" % (tag, "\n".join(lis), tag)


def dedent(lines):
    indents = [len(re.match(r"^\s*", l).group(0)) for l in lines if l.strip()]
    mn = min(indents) if indents else 0
    return [l[mn:] for l in lines]


def render_timeline(items):
    lis = []
    for it in items:
        status_ch = ITEM_STATUS.match(it["text"]).group(1)
        status = ITEM_STATUS_CLASS[status_ch]
        rest = ITEM_STATUS.sub("", it["text"])
        chip = ""
        idm = re.match(r"^(T\d+):\s*", rest)
        if idm:
            chip = req_id_span(idm.group(1))
            rest = rest[idm.end():]
        parts = rest.split(" — ")
        title = parts[0]
        body = " — ".join(parts[1:])
        body_html = '\n<div class="task-item-body">%s</div>' % inline(body) if body else ""
        status_cls = " " + status if status else ""
        lis.append('<li class="task-item%s">\n<div class="task-item-header">%s<strong>%s'
                   "</strong></div>%s\n</li>" % (status_cls, chip, inline(title), body_html))
    return '<ol class="task-timeline">\n%s\n</ol>' % "\n".join(lis)


# ── Document assembly ──────────────────────────────────────────────


def render_document(md_text, assets):
    meta, body = parse_frontmatter(md_text)
    meta_map = dict(meta)
    title = meta_map.get("title", "SDD document")
    out = []
    parse_blocks(body.replace("\r\n", "\n").split("\n"), out, None)
    html = assets["shell"]
    html = html.replace("{{TITLE}}", escape_html(title))  # appears in <title> and <h1>
    html = html.replace("{{CSS}}", assets["css"], 1)
    html = html.replace("{{META_TABLE}}", meta_table(meta), 1)
    html = html.replace("{{BODY}}", "\n".join(out), 1)
    html = html.replace("{{JS}}", assets["js"], 1)
    return html


# ── Asset resolution ───────────────────────────────────────────────


def find_assets_dir(start_dir, explicit):
    candidates = []
    if explicit:
        candidates.append(os.path.abspath(explicit))
    d = os.path.abspath(start_dir)
    for _ in range(12):
        candidates.append(os.path.join(d, ".claude", "skills", "sdd-workflow", "templates"))
        parent = os.path.dirname(d)
        if parent == d:
            break
        d = parent
    script_dir = os.path.dirname(os.path.abspath(__file__))
    candidates.append(os.path.join(script_dir, "..", "templates", "specs"))  # kit layout
    for c in candidates:
        if os.path.exists(os.path.join(c, "spec.css")):
            return c
    return None


def load_assets(directory):
    shell_path = None
    for name in ("spec-shell.html.template", "spec-shell.html"):
        p = os.path.join(directory, name)
        if os.path.exists(p):
            shell_path = p
            break
    if not shell_path:
        raise RuntimeError("spec-shell.html.template not found in %s" % directory)

    def read(p):
        with open(p, encoding="utf-8") as f:
            return f.read()

    return {
        "shell": read(shell_path),
        "css": read(os.path.join(directory, "spec.css")),
        "js": read(os.path.join(directory, "spec.js")),
    }


# ── CLI ────────────────────────────────────────────────────────────


def collect_sources(paths):
    files = []
    for p in paths:
        ap = os.path.abspath(p)
        if not os.path.exists(ap):
            print("skip (not found): %s" % p, file=sys.stderr)
            continue
        if os.path.isdir(ap):
            for name in sorted(os.listdir(ap)):
                if not name.endswith(".md"):
                    continue
                f = os.path.join(ap, name)
                with open(f, encoding="utf-8") as fh:
                    if fh.read(3) == "---":
                        files.append(f)
        else:
            files.append(ap)
    return files


def main():
    args = sys.argv[1:]
    paths = []
    assets_dir = None
    out_file = None
    i = 0
    while i < len(args):
        if args[i] == "--assets":
            i += 1
            assets_dir = args[i]
        elif args[i] == "--out":
            i += 1
            out_file = args[i]
        else:
            paths.append(args[i])
        i += 1
    if not paths:
        print("Usage: python render_spec.py <file.md | dir> [...] [--assets DIR] [--out FILE]",
              file=sys.stderr)
        sys.exit(1)
    files = collect_sources(paths)
    if not files:
        print("No markdown sources found.", file=sys.stderr)
        sys.exit(1)
    if out_file and len(files) > 1:
        print("--out requires a single input file.", file=sys.stderr)
        sys.exit(1)
    for f in files:
        directory = find_assets_dir(os.path.dirname(f), assets_dir)
        if not directory:
            print("assets not found for %s (use --assets)" % f, file=sys.stderr)
            sys.exit(1)
        assets = load_assets(directory)
        with open(f, encoding="utf-8") as fh:
            html = render_document(fh.read(), assets)
        target = os.path.abspath(out_file) if out_file else re.sub(r"\.md$", ".html", f)
        with open(target, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(html)
        print("rendered %s -> %s" % (os.path.basename(f), target))


if __name__ == "__main__":
    main()
