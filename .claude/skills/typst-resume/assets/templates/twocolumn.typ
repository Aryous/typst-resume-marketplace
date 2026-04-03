// Two-Column — left sidebar (contact + skills), right main content
// Data: JSON via sys.inputs.at("resume-data")

#import "lib/markdown.typ": render-md

#let data = json(bytes(sys.inputs.at("resume-data")))

#set page(
  paper: "a4",
  margin: (top: 1.5cm, bottom: 1.5cm, left: 1.2cm, right: 1.2cm),
)

#set text(
  font: ("Noto Sans SC", "PingFang SC", "Microsoft YaHei"),
  size: 10pt,
  lang: "zh",
)

#set par(leading: 0.7em)

// ─── Helpers ───────────────────────────
#let section-title(title) = {
  v(0.5em)
  text(size: 11.5pt, weight: "bold")[#title]
  v(0.15em)
  line(length: 100%, stroke: 0.4pt + luma(200))
  v(0.25em)
}

#let date-range(start, end) = {
  if start != "" or end != "" {
    text(size: 8.5pt, fill: luma(130))[#start — #end]
  }
}

// ─── Data ───────────────────────────
#let personal = data.at("personal", default: (:))
#let education = data.at("education", default: ())
#let work = data.at("work", default: ())
#let skills = data.at("skills", default: ())
#let projects = data.at("projects", default: ())
#let section-order = data.at("sectionOrder", default: ("work", "education", "projects", "skills"))

// ─── Header (full width) ──────────────────────
#align(center)[
  #text(size: 18pt, weight: "bold")[#personal.at("name", default: "")]
  #if personal.at("title", default: "") != "" {
    v(0.15em)
    text(size: 10pt, fill: luma(80))[#personal.at("title", default: "")]
  }
]
#v(0.3em)

// ─── Two-column layout ───────────────────────────
#grid(
  columns: (0.32fr, 0.68fr),
  gutter: 1.2em,

  // ─── Left column ─────────────────────────
  {
    section-title("联系方式")
    if personal.at("email", default: "") != "" {
      text(size: 9pt)[#personal.email]
      linebreak()
    }
    if personal.at("phone", default: "") != "" {
      text(size: 9pt)[#personal.phone]
      linebreak()
    }
    if personal.at("location", default: "") != "" {
      text(size: 9pt)[#personal.location]
      linebreak()
    }
    if personal.at("website", default: "") != "" {
      text(size: 9pt)[#personal.website]
      linebreak()
    }

    if personal.at("summary", default: "") != "" {
      section-title("简介")
      {
        set text(size: 9pt)
        render-md(personal.at("summary", default: ""))
      }
    }

    if skills.len() > 0 {
      section-title("技能")
      for item in skills {
        text(size: 9pt)[*#item.at("name", default: "")* \ ]
        text(size: 8pt, fill: luma(120))[#item.at("level", default: "")]
        v(0.3em)
      }
    }
  },

  // ─── Right column ──────────────
  {
    for sec in section-order {
      if sec == "work" and work.len() > 0 {
        section-title("工作经历")
        for item in work {
          grid(
            columns: (1fr, auto),
            [*#item.at("company", default: "")* #h(0.3em) #text(size: 9pt)[#item.at("position", default: "")]],
            date-range(item.at("startDate", default: ""), item.at("endDate", default: "")),
          )
          if item.at("description", default: "") != "" {
            v(0.1em)
            {
              set text(size: 9pt)
              render-md(item.at("description", default: ""))
            }
          }
          v(0.25em)
        }
      } else if sec == "education" and education.len() > 0 {
        section-title("教育经历")
        for item in education {
          grid(
            columns: (1fr, auto),
            [*#item.at("school", default: "")* #h(0.3em) #text(size: 9pt)[#item.at("degree", default: "") · #item.at("field", default: "")]],
            date-range(item.at("startDate", default: ""), item.at("endDate", default: "")),
          )
          if item.at("description", default: "") != "" {
            {
              set text(size: 9pt)
              render-md(item.at("description", default: ""))
            }
          }
          v(0.25em)
        }
      } else if sec == "projects" and projects.len() > 0 {
        section-title("项目经验")
        for item in projects {
          grid(
            columns: (1fr, auto),
            [*#item.at("name", default: "")* #h(0.3em) #text(size: 9pt)[#item.at("role", default: "")]],
            date-range(item.at("startDate", default: ""), item.at("endDate", default: "")),
          )
          if item.at("description", default: "") != "" {
            v(0.1em)
            {
              set text(size: 9pt)
              render-md(item.at("description", default: ""))
            }
          }
          if item.at("url", default: "") != "" {
            text(size: 8pt, fill: rgb("#1B4965"))[#item.url]
          }
          v(0.25em)
        }
      }
    }
  },
)
