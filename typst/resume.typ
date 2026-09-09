// ============================================================================
// Resume template, Typst.
// Reads a JSON Resume file and produces an unbranded PDF.
//
// Usage:
//   typst compile --root . --font-path typst/fonts \
//     --input resume=/content/collaborateurs/X/resume.json \
//     typst/cv.typ static/cv/X.pdf
// ============================================================================

// --- Data ---
#let data = json(sys.inputs.at("resume", default: "/content/collaborateurs/nicolas-dreno/resume.json"))
#let basics = data.at("basics", default: (:))
#let work = data.at("work", default: ())
#let education = data.at("education", default: ())
#let skills = data.at("skills", default: ())
#let projects = data.at("projects", default: ())
#let languages = data.at("languages", default: ())
#let certifications = data.at("certificates", default: ())
#let references = data.at("references", default: ())
#let interests = data.at("interests", default: ())

// --- Brand Colors ---
#let navy = rgb("#041214")
#let blue = rgb("#1716ff")
#let purple = rgb("#7841fc")
#let lavender = rgb("#f5f5fa")
#let color-gray = rgb("#a7a7a7")
#let teal = rgb("#2f3b3d")
#let light-gray = rgb("#dedede")

// --- Helpers ---
#let resolve-path(p) = {
  if type(p) == str and p.starts-with("./") {
    "/typst/assets/" + p.slice(2)
  } else {
    str(p)
  }
}

#let months = ("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")

#let format-date(d) = {
  if d == none or str(d) == "" { return "" }
  let s = str(d)
  let parts = s.split("-")
  if parts.len() >= 2 {
    months.at(int(parts.at(1)) - 1) + " " + parts.at(0)
  } else {
    s
  }
}

#let date-range(start, end) = {
  if start != none and end != none {
    format-date(start) + " to " + format-date(end)
  } else if start != none {
    format-date(start) + " to Present"
  } else if end != none {
    "Avant " + format-date(end)
  } else {
    ""
  }
}

// --- Page Setup ---
#set page(
  paper: "a4",
  margin: (top: 16mm, bottom: 14mm, left: 18mm, right: 18mm),
  footer: context {
    let total = counter(page).final().first()
    grid(
      columns: (1fr, auto, 1fr),
      [],
      [],
      align(right, text(size: 7pt, fill: color-gray)[
        #counter(page).display() / #total
      ]),
    )
  },
)

#set text(
  font: "Inter",
  size: 9.5pt,
  fill: teal,
  lang: "fr",
)

#set par(leading: 0.65em, justify: true)
#show link: set text(fill: blue)

// --- Heading Styles ---
#show heading.where(level: 2): it => {
  v(6pt)
  block(below: 8pt, {
    text(
      font: "Rethink Sans",
      size: 13pt,
      weight: 600,
      fill: navy,
      it.body,
    )
    v(2pt)
    line(length: 100%, stroke: 1.5pt + lavender)
  })
}

// --- Components ---

#let skill-bar(name, level) = {
  let pct = calc.min(int(level), 5) * 20%
  grid(
    columns: (110pt, 1fr, 20pt),
    column-gutter: 6pt,
    align(horizon, text(size: 8pt, name)),
    align(horizon, {
      let h = 5pt
      box(width: 100%, height: h, {
        place(top + left, rect(width: 100%, height: h, radius: 2.5pt, fill: lavender))
        place(top + left, rect(width: pct, height: h, radius: 2.5pt, fill: purple))
      })
    }),
    align(horizon + right, text(size: 7pt, fill: color-gray, str(int(level)) + "/5")),
  )
}

#let tech-tag(body) = {
  box(
    inset: (x: 5pt, y: 2pt),
    radius: 3pt,
    fill: blue.lighten(92%),
    text(size: 7pt, fill: blue.darken(10%), body),
  )
}

#let badge(body) = {
  box(
    inset: (x: 6pt, y: 3pt),
    radius: 4pt,
    fill: lavender,
    text(size: 8pt, fill: teal, body),
  )
}

// ============================================================================
// CONTENT
// ============================================================================

// --- Banner ---

// --- Header ---
#align(center, {
  text(
    font: "Rethink Sans",
    size: 22pt,
    weight: 700,
    fill: navy,
    basics.at("name", default: ""),
  )
  linebreak()
  v(2pt)
  text(size: 12pt, fill: purple, weight: 500, basics.at("label", default: ""))
  linebreak()
  v(4pt)
  {
    let parts = ()
    if "yearsOfExperience" in basics {
      parts.push(str(basics.yearsOfExperience) + " ans d'expérience")
    }
    if "location" in basics {
      let loc = basics.location
      parts.push(("city", "country").map(k => loc.at(k, default: "")).filter(v => v != "").join(", "))
    }
    if parts.len() > 0 {
      text(size: 9pt, fill: color-gray, parts.join("  ·  "))
    }
  }
})
#v(4pt)
#line(length: 100%, stroke: 1pt + lavender)
#v(4pt)

// --- Summary ---
#if "summary" in basics and basics.summary != "" {
  [== Summary]
  text(size: 9.5pt, basics.summary)
}

// --- Industries ---
#if "industries" in basics and basics.industries.len() > 0 {
  [== Industries]
  for industry in basics.industries {
    tech-tag(industry)
    h(3pt)
  }
}

// --- Work Experience ---
#if work.len() > 0 {
  [== Experience]

  for (i, job) in work.enumerate() {
    let has-logo = "logo" in job and job.at("logo", default: none) != none and job.at("logo", default: "") != ""

    // Company header
    if has-logo {
      grid(
        columns: (28pt, 1fr),
        column-gutter: 8pt,
        image(resolve-path(job.logo), width: 28pt, height: 28pt, fit: "contain"),
        {
          text(size: 11pt, weight: 600, fill: navy, job.at("name", default: ""))
          linebreak()
          text(size: 9.5pt, fill: purple, job.at("position", default: ""))
          h(6pt)
          text(size: 8pt, fill: color-gray, {
            date-range(job.at("startDate", default: none), job.at("endDate", default: none))
            if "location" in job { [ · #job.location] }
          })
        },
      )
    } else {
      text(size: 11pt, weight: 600, fill: navy, job.at("name", default: ""))
      linebreak()
      text(size: 9.5pt, fill: purple, job.at("position", default: ""))
      h(6pt)
      text(size: 8pt, fill: color-gray, {
        date-range(job.at("startDate", default: none), job.at("endDate", default: none))
        if "location" in job { [ · #job.location] }
      })
    }

    v(3pt)

    // Summary
    if "summary" in job and job.summary != "" {
      text(size: 9pt, job.summary)
      v(2pt)
    }

    // Highlights
    if "highlights" in job and job.highlights.len() > 0 {
      for hl in job.highlights {
        grid(
          columns: (12pt, 1fr),
          text(size: 8pt, fill: purple, "▸"),
          text(size: 8.5pt, hl),
        )
        v(1pt)
      }
    }

    // Technologies
    if "technologies" in job and job.technologies.len() > 0 {
      v(3pt)
      for t in job.technologies {
        tech-tag(t)
        h(2pt)
      }
    }

    v(6pt)
    if i < work.len() - 1 {
      line(length: 100%, stroke: 0.5pt + light-gray)
      v(4pt)
    }
  }
}

// --- Projects ---
#if projects.len() > 0 {
  [== Projects]

  for (i, proj) in projects.enumerate() {
    text(size: 11pt, weight: 600, fill: navy, proj.at("name", default: ""))
    linebreak()
    text(size: 9.5pt, fill: purple, proj.at("roles", default: ()).join(", "))
    h(6pt)
    text(size: 8pt, fill: color-gray, {
      date-range(proj.at("startDate", default: none), proj.at("endDate", default: none))
      if "url" in proj { [ · #link(proj.url)[#proj.url]] }
    })

    v(3pt)

    if "description" in proj and proj.description != "" {
      text(size: 9pt, proj.description)
      v(2pt)
    }

    if "highlights" in proj and proj.highlights.len() > 0 {
      for hl in proj.highlights {
        grid(
          columns: (12pt, 1fr),
          text(size: 8pt, fill: purple, "▸"),
          text(size: 8.5pt, hl),
        )
        v(1pt)
      }
    }

    if "keywords" in proj and proj.keywords.len() > 0 {
      v(3pt)
      for k in proj.keywords {
        tech-tag(k)
        h(2pt)
      }
    }

    v(6pt)
    if i < projects.len() - 1 {
      line(length: 100%, stroke: 0.5pt + light-gray)
      v(4pt)
    }
  }
}

// --- Skills ---
#if skills.len() > 0 {
  [== Skills]

  for group in skills {
    text(size: 10pt, weight: 600, fill: navy, group.name)
    v(4pt)

    let profs = group.at("proficiencies", default: ())
    if profs.len() > 0 {
      // Render as bars in a 2-column grid
      let items = profs.map(p => skill-bar(p.keyword, p.level))
      grid(
        columns: (1fr, 1fr),
        column-gutter: 16pt,
        row-gutter: 4pt,
        ..items,
      )
    } else {
      // Render as keyword tags
      let kws = group.at("keywords", default: ())
      for kw in kws {
        tech-tag(kw)
        h(3pt)
      }
    }
    v(8pt)
  }
}

// --- Education ---
#if education.len() > 0 {
  [== Education]

  for edu in education {
    text(size: 10pt, weight: 600, fill: navy, edu.at("institution", default: ""))
    linebreak()
    text(size: 9pt, fill: purple, {
      edu.at("studyType", default: "")
      if "area" in edu { [ — #edu.area] }
    })
    if "startDate" in edu or "endDate" in edu {
      linebreak()
      text(size: 8pt, fill: color-gray, {
        if "startDate" in edu and "endDate" in edu {
          format-date(edu.startDate) + " — " + format-date(edu.endDate)
        } else if "startDate" in edu {
          format-date(edu.startDate)
        }
      })
    }
    v(6pt)
  }
}

// --- Certifications ---
#if certifications.len() > 0 {
  [== Certifications]

  for cert in certifications {
    text(size: 10pt, weight: 600, fill: navy, cert.at("title", default: ""))
    linebreak()
    text(size: 9pt, fill: color-gray, {
      cert.at("issuer", default: "")
      if "date" in cert { [ · #format-date(cert.date)] }
    })
    if "credentialUrl" in cert {
      linebreak()
      text(size: 8pt, link(cert.credentialUrl)[Voir le certificat ↗])
    }
    v(6pt)
  }
}

// --- Languages ---
#if languages.len() > 0 {
  [== Languages]

  for lang in languages {
    badge(lang.language + " — " + lang.at("fluency", default: ""))
    h(4pt)
  }
}

// --- References ---
#if references.len() > 0 {
  [== Recommandations]

  for ref in references {
    block(
      width: 100%,
      inset: 10pt,
      radius: 4pt,
      fill: lavender,
      stroke: (left: 3pt + purple),
      {
        text(size: 9pt, style: "italic", ref.at("text", default: ""))
        v(4pt)
        text(size: 8pt, fill: color-gray, {
          [— ]
          ref.at("name", default: "")
          if "company" in ref { [, #ref.company] }
        })
      },
    )
    v(6pt)
  }
}

// --- Interests ---
#if interests.len() > 0 {
  [== Interests]

  for interest in interests {
    badge(interest.name)
    h(4pt)
  }
}
