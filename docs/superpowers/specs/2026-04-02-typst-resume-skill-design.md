# Typst Resume Skill Design Spec

## Overview

A Claude Code Skill (`/typst-resume`) that takes a free-form Markdown resume as input, presents a browser-based template selector with real-time SVG previews, and outputs a compiled PDF along with Typst source and JSON data.

- **Trigger**: `/typst-resume` (global, any project)
- **Input**: User-provided free-form Markdown resume file
- **Output**: PDF + .typ + JSON triple in `tpr-output/final/`

## Skill Directory Structure

```
typst-resume/
├── SKILL.md                       # Skill entry point (frontmatter + instructions)
├── scripts/
│   ├── server.py                  # Zero-dependency Python HTTP server
│   └── compile.sh                 # typst compile wrapper
├── references/
│   └── resume-schema.md           # JSON data contract + field descriptions
└── assets/
    ├── templates/
    │   ├── lib/
    │   │   └── markdown.typ       # Shared md→typst converter
    │   ├── classic.typ            # Fork from Mojian - single column, dividers
    │   ├── modern.typ             # Fork from Mojian - dark sidebar + accent
    │   ├── minimal.typ            # Fork from Mojian - whitespace, weight hierarchy
    │   ├── twocolumn.typ          # Fork from Mojian - left info, right content
    │   └── academic.typ           # Fork from Mojian - serif, smallcaps
    └── selector/
        └── index.html             # Template selector page skeleton
```

## Four-Phase Workflow

### Phase 1: Parse

- AI reads the user's free-form Markdown resume
- Extracts structured data following the JSON schema defined in `references/resume-schema.md`
- Long text fields (summary, descriptions) are kept as raw Markdown — conversion to Typst markup happens at render time via `lib/markdown.typ`
- Outputs `resume.json` to `tpr-output/.preview/`

### Phase 2: Preview

- `scripts/compile.sh --preview` compiles all 5 templates with the parsed JSON data
- Each template produces an SVG via `typst compile --format svg --input "resume-data=$(cat resume.json)"`
- Agent injects the 5 SVGs into `assets/selector/index.html`, writes the assembled page to `tpr-output/.preview/selector.html`
- `scripts/server.py` starts serving from `.preview/`, writes connection info to `.preview/server-info.json`

### Phase 3: Select

- Agent prompts user to open the browser URL (e.g., `http://localhost:18420`)
- User sees 5 template cards with real SVG previews of their actual resume data
- User clicks a card → JS sends `POST /api/select` with `{"template": "<id>"}` → server writes `events.json`
- Agent polls `events.json`, reads the selected template ID
- Agent calls `GET /api/shutdown` to gracefully stop the server

### Phase 4: Compile

- `scripts/compile.sh --final` compiles the selected template to PDF
- Copies the corresponding `.typ` source (with data inlined) and `resume.json` to `tpr-output/final/`
- Filename pattern: `resume-{template}-{yyyymmdd}-{HHmmss}.{ext}`
- Deletes `tpr-output/.preview/`

## Output Directory Location

`tpr-output/` is created in the current working directory by default. The user can specify an alternative path as an argument to the skill (e.g., `/typst-resume ~/Desktop`). If the directory already exists, reuse it (new runs append to `final/` without overwriting previous outputs).

## Output Directory Structure

```
tpr-output/
├── .preview/                                      # Staging (deleted after confirmation)
│   ├── classic.svg
│   ├── modern.svg
│   ├── minimal.svg
│   ├── twocolumn.svg
│   ├── academic.svg
│   ├── resume.json
│   ├── selector.html
│   ├── server-info.json
│   └── events.json
│
└── final/                                         # Deliverables
    ├── resume-modern-20260402-154530.pdf
    ├── resume-modern-20260402-154530.typ
    └── resume-modern-20260402-154530.json
```

## Component Design

### server.py

- Python 3 standard library only (`http.server`, `json`)
- Routes:
  - `GET /` → serves `selector.html`
  - `POST /api/select` → writes `{"template": "..."}` to `events.json`, returns 200
  - `GET /api/shutdown` → graceful exit
- Auto-finds available port starting from 18420
- Writes `{"port": N, "url": "http://localhost:N"}` to `server-info.json` on startup

### compile.sh

```bash
# Preview mode: batch compile all 5 templates to SVG
compile.sh --preview --data <path/to/resume.json> --outdir <path/to/.preview/> --templates-dir <path/to/assets/templates/>

# Final mode: compile selected template to PDF
compile.sh --final --template <template-id> --data <path/to/resume.json> --outdir <path/to/final/> --templates-dir <path/to/assets/templates/> --timestamp <yyyymmdd-HHmmss>
```

Core command:
```bash
typst compile --input "resume-data=$(cat "$data_path")" "$template_path" "$output_path"
```

### lib/markdown.typ

Shared Markdown-to-Typst converter, imported by all templates:

```typst
#import "lib/markdown.typ": render-md
```

Conversion rules:

| Markdown | Typst | Notes |
|----------|-------|-------|
| `**bold**` | `*bold*` | Bold |
| `*italic*` | `_italic_` | Italic |
| `***bold italic***` | `*_bold italic_*` | Bold italic |
| `- item` | `- item` | Unordered list (same syntax) |
| `1. item` | `+ item` | Ordered list |
| `[text](url)` | `#link("url")[text]` | Links |
| `#` `$` `@` `\` | `\#` `\$` `\@` `\\` | Special char escaping |

Applied to all long text fields: `personal.summary`, `education[].description`, `work[].description`, `projects[].description`.

### selector/index.html

- Card grid layout displaying 5 template previews
- Each card shows: SVG preview + template name + one-line description
- Click triggers `fetch('/api/select', {method: 'POST', body: JSON.stringify({template: id})})`
- Selected state has visual feedback (border highlight)
- Responsive layout

## JSON Data Contract

Inherited from Mojian, documented in `references/resume-schema.md`:

```json
{
  "personal": {
    "name": "",
    "title": "",
    "email": "",
    "phone": "",
    "location": "",
    "website": "",
    "summary": ""
  },
  "education": [{
    "school": "",
    "degree": "",
    "field": "",
    "startDate": "",
    "endDate": "",
    "description": ""
  }],
  "work": [{
    "company": "",
    "position": "",
    "startDate": "",
    "endDate": "",
    "description": ""
  }],
  "projects": [{
    "name": "",
    "role": "",
    "startDate": "",
    "endDate": "",
    "description": "",
    "url": ""
  }],
  "skills": [{
    "name": "",
    "level": ""
  }],
  "sectionOrder": ["work", "education", "projects", "skills"]
}
```

- `level` values: `"beginner"`, `"intermediate"`, `"advanced"`, `"expert"`
- `description` and `summary` fields contain raw Markdown, converted at render time
- `sectionOrder` controls the rendering order in templates

## Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Template source | Fork from Mojian | Independent evolution, no coupling |
| Input parsing | AI free-form | Zero cognitive load on user |
| Markdown conversion | `lib/markdown.typ` in templates | Rules codified, not AI-dependent |
| Preview format | SVG | Vector-crisp previews |
| HTTP server | Python stdlib | macOS built-in, zero install |
| Event callback | File-based (`events.json`) | Simple, no IPC complexity |
| Output naming | `resume-{template}-{yyyymmdd}-{HHmmss}` | Timestamp to second, no version logic |
| Staging dir | `.preview/` with dot prefix | Signals temporary nature |
| Scope | Global skill, configurable output dir | Usable from any project |
| Target audience | Personal first, extensible for public | Structure supports marketplace publishing |

## SKILL.md Frontmatter

```yaml
---
name: typst-resume
description: >
  Generate polished Typst PDF resumes from free-form Markdown input. Parses any
  Markdown resume, presents browser-based template previews with real resume data
  for click-to-select, and outputs PDF + Typst source + JSON. Use when the user
  mentions making a resume, generating a resume, typst resume, resume formatting,
  resume PDF, or /typst-resume.
---
```

## Dependencies

- `typst` >= 0.14 (installed via `brew install typst`)
- Python 3 (macOS built-in)
- Modern web browser (for template selector)

## Future Extensibility

- New templates: drop a `.typ` file in `assets/templates/`, import `lib/markdown.typ`, follow the JSON data contract
- Custom themes: templates could accept color/font overrides via additional `sys.inputs`
- Marketplace publishing: directory structure follows standard Skill architecture
