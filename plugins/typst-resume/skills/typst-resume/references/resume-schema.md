# Resume JSON Schema

This document defines the target JSON structure for AI parsing. When extracting data from a user's free-form Markdown resume, produce JSON conforming to this schema.

## Schema

```json
{
  "personal": {
    "name": "string (required)",
    "title": "string — job title or tagline",
    "email": "string",
    "phone": "string",
    "location": "string — city or region",
    "website": "string — URL, LinkedIn, GitHub, etc.",
    "summary": "string — personal summary or objective (raw Markdown)"
  },
  "education": [
    {
      "school": "string (required)",
      "degree": "string — e.g. Bachelor, Master, PhD",
      "field": "string — major or field of study",
      "startDate": "string — e.g. 2020-09, 2020, Sept 2020",
      "endDate": "string — e.g. 2024-06, Present, 至今",
      "description": "string — details, honors, GPA (raw Markdown)"
    }
  ],
  "work": [
    {
      "company": "string (required)",
      "position": "string (required)",
      "startDate": "string",
      "endDate": "string",
      "description": "string — responsibilities, achievements (raw Markdown)"
    }
  ],
  "projects": [
    {
      "name": "string (required)",
      "role": "string — role in the project",
      "startDate": "string",
      "endDate": "string",
      "description": "string — project details (raw Markdown)",
      "url": "string — project link"
    }
  ],
  "skills": [
    {
      "name": "string (required) — skill name",
      "level": "string — one of: beginner, intermediate, advanced, expert"
    }
  ],
  "sectionOrder": ["string — ordered array of section keys to render"]
}
```

## Parsing Guidelines

### General Rules
- All fields default to empty string `""` if not found in the source
- Arrays default to empty `[]` if no matching content exists
- Preserve the user's original wording — do not rephrase or embellish
- Date formats: keep the user's original format (e.g., "2020.9", "Sep 2020", "2020-09" are all valid)

### Long Text Fields
These fields may contain raw Markdown and will be converted to Typst at render time:
- `personal.summary`
- `education[].description`
- `work[].description`
- `projects[].description`

Supported Markdown syntax in these fields:
- `**bold**`, `*italic*`, `***bold italic***`
- `- unordered list items`
- `1. ordered list items`
- `[link text](url)`
- Blank lines as paragraph separators

### sectionOrder
Infer the order from the user's Markdown heading sequence. Common patterns:
- Work-first: `["work", "education", "projects", "skills"]`
- Education-first: `["education", "work", "projects", "skills"]`
- If ambiguous, default to: `["work", "education", "projects", "skills"]`

### Skill Level Mapping
Map qualitative descriptions to level values:
- `expert`: "proficient", "expert", "advanced", "5+ years", "精通"
- `advanced`: "strong", "experienced", "3-5 years", "熟练"
- `intermediate`: "familiar", "working knowledge", "1-3 years", "熟悉"
- `beginner`: "basic", "learning", "exposure", "<1 year", "了解"
- If no level is indicated, default to `"intermediate"`
