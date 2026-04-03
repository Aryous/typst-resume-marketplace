---
name: typst-resume
description: >
  Generate polished Typst PDF resumes from free-form Markdown input. Parses any
  Markdown resume into structured data, launches a browser-based template selector
  with real SVG previews of the user's actual resume, and compiles the chosen template
  to PDF + Typst source + JSON. Use when the user mentions making a resume, generating
  a resume, typst resume, resume formatting, resume PDF, CV generation, 简历制作,
  简历排版, or /typst-resume. Even if the user just says "help me with my resume"
  and has a markdown file, this skill applies.
---

# Typst Resume Skill

Generate professional PDF resumes from free-form Markdown through a four-phase workflow:
**Parse → Preview → Select → Compile**.

## Prerequisites

- `typst` CLI installed (`brew install typst`, requires >= 0.14)
- Python 3 (macOS built-in)
- A modern web browser

## Quick Reference

| Phase | What happens | Key tool |
|-------|-------------|----------|
| Parse | AI extracts structured JSON from user's Markdown | `references/resume-schema.md` |
| Preview | Batch compile 5 SVG previews | `scripts/compile.sh --preview` |
| Select | User picks template in browser | `scripts/server.py` |
| Compile | Final PDF + source + JSON | `scripts/compile.sh --final` |

## Output Location

All outputs go to `tpr-output/` in the current working directory (or user-specified path).
If the user provides a path argument, use that instead.

---

## Phase 1: Parse

Read the user's Markdown resume file and extract structured data.

1. Read the entire Markdown file the user provides
2. Read `references/resume-schema.md` for the target JSON schema and parsing guidelines
3. Extract all resume data into the schema structure:
   - Map headings and content to the appropriate fields
   - Keep long text fields (summary, descriptions) as **raw Markdown** — do not convert to Typst
   - Infer `sectionOrder` from the heading sequence in the original document
   - For skills without explicit levels, default to `"intermediate"`
4. Create the output directory: `tpr-output/.preview/`
5. Write the JSON to `tpr-output/.preview/resume.json`
6. Show the user a summary of what was extracted (name, section counts) and ask them to confirm the data looks correct before proceeding

## Phase 2: Preview

Generate SVG previews for all 5 templates using the parsed data.

1. Determine the absolute path to this skill's `assets/templates/` directory
2. Run the preview compilation:
   ```bash
   bash <skill-path>/scripts/compile.sh \
     --preview \
     --data tpr-output/.preview/resume.json \
     --outdir tpr-output/.preview/ \
     --templates-dir <skill-path>/assets/templates/
   ```
3. If any template fails to compile, log the error but continue with the others
4. Read `assets/selector/index.html` as a template
5. For each successfully compiled SVG, generate a card element:
   ```html
   <div class="card" data-template="<id>" onclick="selectTemplate('<id>', '<name>')">
     <div class="card-preview">
       <img src="/<id>.svg" alt="<name>">
     </div>
     <div class="card-info">
       <h3><name></h3>
       <p><description></p>
     </div>
   </div>
   ```
6. Replace `<!-- TPR_CARDS_PLACEHOLDER: ... -->` in the HTML template with the generated cards
7. Write the assembled HTML to `tpr-output/.preview/selector.html`

Template metadata for card generation:

| ID | Name | Description |
|----|------|-------------|
| classic | 经典 | 单栏布局，简洁大方，分隔线分区 |
| modern | 现代 | 深色侧栏 + 蓝色强调，商务专业 |
| minimal | 极简 | 大量留白，字重灰度建立层次 |
| twocolumn | 双栏 | 左右分栏，信息密度更高 |
| academic | 学术 | 衬线字体，适合学术研究背景 |

## Phase 3: Select

Launch the HTTP server and let the user choose a template in their browser.

1. Start the server in the background:
   ```bash
   python3 <skill-path>/scripts/server.py \
     --preview-dir tpr-output/.preview/ &
   ```
2. Read `tpr-output/.preview/server-info.json` to get the URL
3. Tell the user: "请在浏览器中打开 {url} 选择模板。选好后点击「确认选择」。"
4. Poll `tpr-output/.preview/events.json` until it exists and contains a valid template selection
   - Check every 2 seconds
   - Timeout after 5 minutes — if no selection, ask the user what happened
5. Read the selected template ID from `events.json`
6. Kill the server process (read PID from `server-info.json`):
   ```bash
   kill <pid> 2>/dev/null
   ```

## Phase 4: Compile

Generate the final deliverables.

1. Create `tpr-output/final/` if it doesn't exist
2. Generate the timestamp: `date +%Y%m%d-%H%M%S`
3. Run the final compilation:
   ```bash
   bash <skill-path>/scripts/compile.sh \
     --final \
     --template <selected-template> \
     --data tpr-output/.preview/resume.json \
     --outdir tpr-output/final/ \
     --templates-dir <skill-path>/assets/templates/ \
     --timestamp <yyyymmdd-HHmmss>
   ```
4. Verify the PDF was created successfully
5. Clean up the staging directory:
   ```bash
   rm -rf tpr-output/.preview/
   ```
6. Report to the user:
   - PDF path
   - Typst source path (for manual editing)
   - JSON path (for re-generation with a different template)

## Error Handling

- **Typst not installed**: Tell the user to run `brew install typst`
- **Compilation failure**: Show the typst error output, suggest checking font availability
- **Server port conflict**: server.py auto-finds available ports, but if all fail, tell the user
- **No browser access**: Offer to let the user specify the template by name in the terminal instead

## Templates

5 templates are available in `assets/templates/`, all sharing `lib/markdown.typ` for Markdown-to-Typst conversion. Each template:
- Reads JSON data via `sys.inputs.at("resume-data")`
- Supports `sectionOrder` for user-controlled section ordering
- Handles missing fields gracefully with defaults

To add a new template: create a `.typ` file in `assets/templates/`, import `lib/markdown.typ`, follow the same JSON data contract, and add its metadata to the table in Phase 2.
