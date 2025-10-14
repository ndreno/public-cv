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