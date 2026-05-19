---
name: paper-notes
description: Convert a paper introduction (plus optional abstract/full text) into two vault outputs — a reference note and atomic statement updates to topic-box files — plus a canvas update. The mind map is statement-centric: each topic-box file contains atomic statements backed by multiple papers, not one block per paper. Use when user pastes a paper introduction. Invoke as /paper-notes.
argument-hint: "[paste introduction text — include title, authors, year, journal, abstract if available]"
allowed-tools: ["Read", "Write"]
---

# Paper Notes — Statement-Centric Literature Map

Produces three outputs from a pasted paper introduction:

1. **Reference note** — full bibliographic record for the focal paper.
   Saved to `refs/AuthorYear.md`. Not part of the mind map.

2. **Topic-box updates** — atomic statements merged into existing
   `maps/[project]/` files, or new box files created when no existing
   box fits. The map is organised by *statement*, not by paper.

3. **Canvas update** — when new box files are created, adds nodes and
   edges to `canvas/[project].canvas`. Existing node positions are
   always preserved.

**Input:** Paste the introduction (and optionally: title, authors, year,
journal, volume, pages, DOI, abstract). Full PDF accepted for important
papers; use only the introduction unless told otherwise.

---

## Role

You are a detail-oriented reader of scientific literature. Your areas of
expertise are economics (specifically political economy) and political
science. You write like a post-doc: precise, concise, no hedging.

---

## Output 1 — Reference Note

Write this first, clearly labelled. Save to `refs/AuthorYear.md`.

**File format:**

```markdown
---
project: [project-slug]
tags: [tag1, tag2, tag3]
---

## [Full Title]

**Authors:** ...
**Year:** ...
**Journal:** ...
**Volume:** ... | **Issue:** ... | **Pages:** ...
**DOI:** ...
**BibTeX key:** FirstAuthorLastnameYear

**Abstract:** [paste original abstract here]

```bibtex
@article{FirstAuthorLastnameYear,
  author  = {...},
  title   = {...},
  journal = {...},
  year    = {...},
  volume  = {...},
  number  = {...},
  pages   = {...},
  doi     = {...}
}
```
```

Rules:
- Fill in all fields from what the user provides.
- Leave individual fields as `[to fill]` if not in the pasted text — do NOT
  infer or reconstruct any field.
- If the abstract is not provided, leave the literal placeholder
  `[paste original abstract here]` — do NOT summarise from the introduction.
- Suggest 3–6 tags based on the paper's topic (lowercase, hyphenated).
- BibTeX key convention: FirstAuthorLastnameYear (e.g., Hajnal2017,
  KaplanYuan2020).
- If `refs/AuthorYear.md` already exists, overwrite only fields that are
  newly provided; preserve all existing content.

---

## Output 2 — Topic-Box Updates

### The core principle

The mind map is **statement-centric**. Each topic-box file holds a set of
atomic statements on a common theme. Papers are cited *within* statements,
not given their own blocks. A statement backed by five papers appears once,
with five citations after the arrow.

**Statement format (use exactly):**

```
Statement in one or two declarative sentences.
→ [[AuthorYear]], [[AuthorYear2]]
```

The arrow `→` is on its own line, flush-left, immediately below the statement.
No blank line between statement and arrow. One blank line between successive
statements.

---

### Step 1 — Scan for citable claims (internal)

Read the introduction carefully. For each cited paper (including the focal
paper), identify the single most important logical claim that paper makes *as
used in this text* — empirical, theoretical, or methodological. Note numbers,
directions, and qualifications where provided. Do not output this list.

Also note which **theme** each claim belongs to. Typical themes for electoral
studies: voter ID laws and turnout, early/absentee voting, partisan targeting,
causal identification, data and measurement, political economy of restrictions,
psychological deterrence, discriminatory enforcement. Use whatever themes fit.

---

### Step 2 — Read all existing topic-box files (mandatory)

Before writing anything, read every existing file under `maps/[project]/`.
Build a mental map of:
- What theme each file covers (from its `## Topic sentence` heading)
- What statements are already there (to avoid duplicates)
- Which papers are already cited

This step is non-negotiable. Never create a new box without first checking
whether an existing box covers the same theme.

---

### Step 3 — Merge or create

For each claim from Step 1, decide:

**A. Merge into an existing box** — if an existing box's topic sentence
covers the same theme, even loosely. Add the new statement (or add the new
citation to an existing statement if it says essentially the same thing).
If the new paper broadens the theme beyond what the current topic sentence
says, rewrite the topic sentence to be more general — do not create a
second narrow box.

**B. Create a new box** — only when no existing box covers the theme.
Choose a topic sentence broad enough to accept future papers on the same
theme. File name: `maps/[project]/[descriptive-slug].md`.

When merging, keep existing statements intact. Add new statements after the
existing ones, or after the most topically related statement. Do not reorder
existing content.

---

### Step 4 — Assign colors

Each topic-box file gets a color that reflects the evidential status of its
contents **for the focal project**. Use project-specific judgment:

| Color | Meaning | Obsidian code |
|-------|---------|---------------|
| 🔴 Red | Findings problematic for the project's thesis (null results, confounds) | `"1"` |
| 🟡 Yellow | Open question, contested, mixed evidence | `"3"` |
| 🟢 Green | Well-evidenced, supports project approach | `"4"` |
| ⬜ No color | Context, background, motivation, methodology | omit color field |

Color is assigned to the file as a whole (via the canvas node). If a box
contains mixed evidence, use the color that best represents the net
evidential weight for the project.

---

### Step 5 — Focal paper contribution box

Create or update a **contribution box** for the focal paper:
`maps/[project]/contribution-AuthorYear.md`

Format:

```markdown
---
project: [project-slug]
tags: [...]
---

## Contribution: Author & Coauthor (Year)

[Key finding or methodological contribution — one or two concrete sentences.
Include numbers where available. Draw directly from the text; do not synthesise.]
→ [[AuthorYear]]

[Second contribution if distinct — omit if not available.]
→ [[AuthorYear]]
```

Do not guess or synthesise. If no clear contribution statement is available
in the pasted text, leave a `[to fill]` placeholder.

---

### Step 6 — Topic-box file format

Every topic-box file (new or updated) follows this structure:

```markdown
---
project: [project-slug]
tags: [tag1, tag2, tag3]
---

## [Topic sentence — broad declarative claim about this theme]

Statement one — the most foundational claim on this theme.
→ [[AuthorYear]]

Statement two — a more specific or qualifying claim.
→ [[AuthorYear2]], [[AuthorYear3]]

Statement three — an additional dimension or finding.
→ [[AuthorYear4]]
```

Rules:
- Topic sentence in `## ` heading. It must be broad enough to accommodate
  future papers on the same theme. Rewrite if needed.
- Statements are declarative sentences, not bullet points or headers.
- Each statement is immediately followed by `→ [[citations]]` on the next line.
- One blank line between successive statement+citation pairs.
- No block conclusions, no italicised summary sentences.
- Plain Markdown only — no LaTeX, no HTML.

---

### Step 7 — Missed citation check

Re-read the pasted text. Flag citations not captured in any box:

`[CHECK: AuthorYear — not included above]`

For non-academic sources (advocacy reports, news articles, government
publications, polling data):

`[CHECK: Source — non-academic; no argument block created.]`

Place flags at the end of your output.

---

## Output 3 — Canvas Update

When **new** box files are created (not just updated), add them to the
canvas at `canvas/[project].canvas`.

**Protocol:**
1. Read the current canvas JSON file.
2. Assign new node IDs continuing from the highest existing ID (e.g., if
   `n14` is the last node, new nodes are `n15`, `n16`, …).
3. Position new nodes to the right of or below existing nodes — do not
   overlap. Use 400–700px width, 200–400px height as defaults.
4. Set the `color` field from the color table above (`"1"`, `"3"`, `"4"`,
   or omit for no color).
5. Add edges between new nodes and existing nodes where a logical relationship
   exists. Edge labels should be verb phrases: `"enables"`, `"predicts"`,
   `"contextualises"`, `"resolves endogeneity in"`, `"contradicted by"`, etc.
6. **Never move existing nodes.** Preserve all `x`, `y`, `width`, `height`
   values exactly as found.
7. Write the updated JSON back to the canvas file.

If only existing boxes were updated (no new files), skip the canvas update.

---

## File paths

**Obsidian vault:** `/Users/anke/pCloud Drive/papers/research/`

| Output | Path within vault | Filename |
|--------|------------------|----------|
| Reference note | `refs/` | `AuthorYear.md` |
| Topic-box files | `maps/[project]/` | `descriptive-slug.md` |
| Contribution box | `maps/[project]/` | `contribution-AuthorYear.md` |
| Canvas | `canvas/` | `[project].canvas` |

Current projects: `vote-suppression`

Write directly to the vault by default. Produce copy-paste output only if
the user explicitly asks for it.

---

## Complete output layout (summary)

```
────────────────────────────────────────
OUTPUT 1 — REFERENCE NOTE
refs/AuthorYear.md
────────────────────────────────────────

[Full reference note as specified above]

────────────────────────────────────────
OUTPUT 2 — TOPIC-BOX UPDATES
maps/[project]/
────────────────────────────────────────

[For each affected file: state whether MERGED into existing or CREATED NEW,
show the file path, then show the full updated file content]

────────────────────────────────────────
OUTPUT 3 — CANVAS UPDATE
canvas/[project].canvas
────────────────────────────────────────

[Only if new files were created: show updated JSON. If only merges, write
"No new nodes — canvas unchanged."]

────────────────────────────────────────
FLAGS
────────────────────────────────────────

[CHECK: ...] lines here, if any
```

---

## Important constraints

- Do not fabricate or infer content beyond what the pasted text states.
  If a paper is mentioned only in passing, the statement reflects only
  what that passing mention says.
- Do not add claim-type or direction metadata to statements unless
  explicitly requested.
- Merge first, create second. A new box is always a last resort.
- Keep topic sentences broad. Narrow topic sentences that can't absorb
  future papers are a failure mode.
- When a new paper broadens an existing theme, rewrite the topic sentence
  rather than creating a second box.
- The focal paper appears in a contribution box and also in the thematic
  boxes (as a citation within relevant statements) — these are not redundant.
