# Typst Resume Marketplace

A Claude Code plugin that generates polished PDF resumes from free-form Markdown. Pick from 5 templates in a browser-based selector with real-time SVG previews of your actual resume data.

## How It Works

```
Markdown resume → AI parses → 5 template previews → browser selector → PDF + .typ + JSON
```

### Four-Phase Workflow

1. **Parse** — AI reads your free-form Markdown and extracts structured JSON (no special format required)
2. **Preview** — Compiles all 5 templates to SVG with your real data
3. **Select** — Opens a local browser page where you click to choose a template
4. **Compile** — Outputs the final triple: PDF, Typst source, and JSON data

## Templates

| Template | Style |
|----------|-------|
| Classic | Single column, centered header, horizontal dividers |
| Modern | Dark sidebar + blue accent, skill progress bars |
| Minimal | Generous whitespace, weight/grayscale hierarchy |
| Two-Column | Left sidebar (contact + skills), right main content |
| Academic | Serif fonts, smallcaps section titles, scholarly feel |

## Installation

```bash
/plugin marketplace add Aryous/typst-resume-marketplace
/plugin install typst-resume@typst-resume-marketplace
```

### Prerequisites

- [Typst](https://typst.app/) >= 0.14 (`brew install typst`)
- Python 3 (macOS built-in)

## Usage

```
/typst-resume
```

Or just ask naturally:

> "Help me turn my resume.md into a nice PDF"

The skill triggers when you mention resume generation, typst resume, CV formatting, or similar phrases.

## Output

All deliverables go to `tpr-output/final/` in your working directory:

```
tpr-output/final/
├── resume-modern-20260402-154530.pdf    # Final PDF
├── resume-modern-20260402-154530.typ    # Typst source (editable)
└── resume-modern-20260402-154530.json   # Structured data (reusable)
```

Filename format: `resume-{template}-{yyyymmdd}-{HHmmss}.{ext}`

## Adding Templates

1. Create a `.typ` file in `plugins/typst-resume/skills/typst-resume/assets/templates/`
2. Import the shared converter: `#import "lib/markdown.typ": render-md`
3. Read data via `json(bytes(sys.inputs.at("resume-data")))`
4. Follow the JSON schema in `references/resume-schema.md`

## License

MIT
