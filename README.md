# Automagic CV

## Local dev

### Install

```shell
npm install
```

### Run

```shell
npm run build:en && npm run build:fr
```

## CI

[![Build and Deploy Resume](https://github.com/ndreno/public-cv/actions/workflows/build-resume.yml/badge.svg)](https://github.com/ndreno/public-cv/actions/workflows/build-resume.yml)

## Repo structure

```text
public-cv/
├── resumes/
│   ├── en.json
│   └── fr.json
├── .github/
│   └── workflows/
│       └── build-resume.yml
├── .gitignore
└── package.json  (for json-resume dependencies)
```
## US resume

`resumes/us.json` is a variant targeted at US applications: one headline role per
entry, impact-led highlights, no address or photo, and the earlier roles folded
into a single line. It is **not** published on the site. It is rendered to PDF and
attached to applications by hand.

```shell
npm run build:pdf     # build/us.pdf, rendered with Typst
npm run ats           # ATS readiness gate
```

Rendering uses [Typst](https://github.com/typst/typst) and the unbranded template
in `typst/resume.typ`.

### ATS gate

There is no universal ATS score: Greenhouse, Lever and Workday all parse
differently. `scripts/ats-check.mjs` checks the two things that are actually
deterministic:

- **Parseability**, the failure modes that break real parsers: a missing email,
  dates that are not `YYYY-MM`, a role with no title, an unextractable PDF, or a
  resume running past three pages.
- **Keyword coverage** against a posting described in `jobs/<role>.json`, which
  lists its `must_have` and `nice_to_have` terms. A missing required term fails
  the build.

Add a posting by dropping a new file in `jobs/`. CI checks the resume against all
of them on every change.
