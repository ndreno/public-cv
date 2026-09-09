#!/usr/bin/env node
// ATS readiness check.
//
// There is no universal "ATS score": Greenhouse, Lever and Workday each parse
// differently. What is checkable is the set of things that reliably break those
// parsers, plus coverage of the keywords a given posting actually asks for.
// Both are deterministic, so this runs as a gate rather than as advice.
//
// Usage: node scripts/ats-check.mjs resumes/us.json jobs/<role>.json [build/us.pdf]
import { readFileSync, existsSync } from "node:fs";

const [resumePath, jobPath, pdfPath] = process.argv.slice(2);
if (!resumePath || !jobPath) {
  console.error("usage: ats-check.mjs <resume.json> <job.json> [resume.pdf]");
  process.exit(2);
}

const resume = JSON.parse(readFileSync(resumePath, "utf8"));
const job = JSON.parse(readFileSync(jobPath, "utf8"));

const errors = [];
const warnings = [];

// --- Structure: what ATS parsers need to find ------------------------------
const b = resume.basics ?? {};
if (!b.email) errors.push("basics.email is missing; every parser keys on it");
if (!b.name) errors.push("basics.name is missing");
if (!b.summary) warnings.push("basics.summary is empty; it is the first thing a recruiter reads");

const networks = (b.profiles ?? []).map((p) => (p.network ?? "").toLowerCase());
for (const n of ["linkedin", "github"]) {
  if (!networks.includes(n)) warnings.push(`no ${n} profile in basics.profiles`);
}

for (const [i, w] of (resume.work ?? []).entries()) {
  const who = w.company ?? w.name ?? `work[${i}]`;
  if (!w.startDate) errors.push(`${who}: no startDate, the role will not be placed on a timeline`);
  if (!/^\d{4}-\d{2}$/.test(w.startDate ?? "")) errors.push(`${who}: startDate must be YYYY-MM`);
  if (w.endDate && !/^\d{4}-\d{2}$/.test(w.endDate)) errors.push(`${who}: endDate must be YYYY-MM`);
  if (!w.position) errors.push(`${who}: no position`);
  if ((w.highlights ?? []).some((h) => !h.trim())) errors.push(`${who}: empty highlight`);
}
if (!(resume.work ?? []).length) errors.push("no work section");
if (!(resume.education ?? []).length) warnings.push("no education section; some parsers expect one");
if (!(resume.skills ?? []).length) errors.push("no skills section");

// --- Keyword coverage against the posting ----------------------------------
const haystack = JSON.stringify(resume).toLowerCase();
const esc = (s) => s.toLowerCase().replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
// A posting says "Go", the resume says "Golang". Synonyms are declared per job
// so the matching stays deterministic and reviewable.
const synonyms = job.synonyms ?? {};
const present = (kw) =>
  [kw, ...(synonyms[kw] ?? [])].some((v) => new RegExp(`\\b${esc(v)}(s|es|ed|ing)?\\b`).test(haystack));

const missingMust = (job.must_have ?? []).filter((k) => !present(k));
const missingNice = (job.nice_to_have ?? []).filter((k) => !present(k));
for (const k of missingMust) errors.push(`required keyword absent from the resume: "${k}"`);

const must = job.must_have ?? [];
const nice = job.nice_to_have ?? [];
const hitMust = must.length - missingMust.length;
const hitNice = nice.length - missingNice.length;
const coverage = must.length + nice.length
  ? Math.round(((hitMust + hitNice) / (must.length + nice.length)) * 100)
  : 100;

// --- Length ----------------------------------------------------------------
const prose = [
  b.summary ?? "",
  ...(resume.work ?? []).flatMap((w) => [w.summary ?? "", ...(w.highlights ?? [])]),
  ...(resume.projects ?? []).flatMap((p) => [p.description ?? "", ...(p.highlights ?? [])]),
].join(" ");
const words = prose.split(/\s+/).filter(Boolean).length;
if (words < 150) errors.push(`only ${words} words of prose; too thin to rank on any keyword`);
else if (words > 900) warnings.push(`${words} words of prose; past 900 the reader skims`);
console.log(`Prose: ${words} words`);

// --- PDF sanity ------------------------------------------------------------
if (pdfPath && existsSync(pdfPath)) {
  const pdf = readFileSync(pdfPath);
  const raw = pdf.toString("latin1");
  const pages = (raw.match(/\/Type\s*\/Page[^s]/g) ?? []).length;
  if (!pdf.includes("/Font")) errors.push("the PDF embeds no font, so its text is not extractable");
  // Small images are how a renderer draws transparency and rounded corners, and
  // carry no text. Only a large one (a logo, a banner, a scanned page) hides
  // content from a parser.
  // Checking the JSON is not enough: a template can silently drop a field. Link
  // annotations store plain URIs, so what actually reached the page is readable.
  const uris = new Set([...raw.matchAll(/\/URI\s*\((.*?)\)/g)].map((m) => m[1]));
  if (b.email && ![...uris].some((u) => u.includes(b.email)))
    errors.push(`the email is in the JSON but not on the page; nobody can reply to this resume`);
  for (const prof of b.profiles ?? []) {
    if (prof.url && !uris.has(prof.url))
      errors.push(`${prof.network} link missing from the PDF`);
  }

  const big = [...raw.matchAll(/\/Subtype\s*\/Image[\s\S]{0,200}?\/Width\s+(\d+)[\s\S]{0,80}?\/Height\s+(\d+)/g)]
    .filter(([, w, h]) => Number(w) > 600 || Number(h) > 600);
  if (big.length) warnings.push(`${big.length} large image(s) in the PDF; a parser reads no text inside them`);
  // Three pages is normal for a career this long. Past four a recruiter stops.
  if (pages > 4) errors.push(`PDF is ${pages} pages; past four nobody reads to the end`);
  else if (pages > 3) warnings.push(`PDF is ${pages} pages; three is the comfortable ceiling`);
  console.log(`PDF: ${pages} page(s), text extractable`);
}

// --- Report ----------------------------------------------------------------
console.log(`\n${job.company} / ${job.title}`);
console.log(`Keyword coverage: ${coverage}%  (required ${hitMust}/${must.length}, preferred ${hitNice}/${nice.length})`);
if (missingNice.length) console.log(`Preferred keywords absent: ${missingNice.join(", ")}`);
for (const w of warnings) console.log(`  warning: ${w}`);
for (const e of errors) console.error(`  error:   ${e}`);

if (errors.length) {
  console.error(`\nFAIL: ${errors.length} blocking issue(s).`);
  process.exit(1);
}
console.log("\nOK");
