// Markdown → Typst markup converter
// Shared by all resume templates
// Input: raw Markdown string
// Output: rendered Typst content

#let _escape-typst-chars(s) = {
  // Escape Typst special characters BEFORE markdown conversion
  // Order matters: backslash first to avoid double-escaping
  s = s.replace("\\", "\\\\")
  s = s.replace("#", "\\#")
  s = s.replace("$", "\\$")
  s = s.replace("@", "\\@")
  s
}

#let _convert-inline(s) = {
  // Bold italic: ***text*** → *_text_*
  // Must run before bold and italic to avoid partial matches
  let result = s.replace(
    regex("\*\*\*(.+?)\*\*\*"),
    m => "*_" + m.captures.at(0) + "_*"
  )
  // Bold: **text** → *text*
  result = result.replace(
    regex("\*\*(.+?)\*\*"),
    m => "*" + m.captures.at(0) + "*"
  )
  // Italic: single *text* → _text_
  // After bold conversion, remaining single * pairs are italic
  // Use a simple pattern without lookbehind (unsupported in Typst regex)
  result = result.replace(
    regex("\*([^\*]+?)\*"),
    m => "_" + m.captures.at(0) + "_"
  )
  // Links: [text](url) → #link("url")[text]
  result = result.replace(
    regex("\[(.+?)\]\((.+?)\)"),
    m => "#link(\"" + m.captures.at(1) + "\")[" + m.captures.at(0) + "]"
  )
  result
}

#let render-md(s) = {
  if s == none or s == "" { return }

  let lines = s.split("\n")
  let result = ()
  let in-list = false

  for line in lines {
    let trimmed = line.trim()

    if trimmed == "" {
      if in-list {
        in-list = false
      }
      result.push(v(0.3em))
      continue
    }

    // Ordered list: "1. item" or "2. item" → "+ item"
    let ol-match = trimmed.match(regex("^\d+\.\s+(.+)$"))
    if ol-match != none {
      let content = _escape-typst-chars(ol-match.captures.at(0))
      content = _convert-inline(content)
      result.push(eval("+ " + content, mode: "markup"))
      in-list = true
      continue
    }

    // Unordered list: "- item" or "* item" (at start of line)
    let ul-match = trimmed.match(regex("^[-\*]\s+(.+)$"))
    if ul-match != none {
      let content = _escape-typst-chars(ul-match.captures.at(0))
      content = _convert-inline(content)
      result.push(eval("- " + content, mode: "markup"))
      in-list = true
      continue
    }

    // Regular paragraph
    let content = _escape-typst-chars(trimmed)
    content = _convert-inline(content)
    result.push(eval(content, mode: "markup"))
  }

  result.join()
}
