#!/usr/bin/env node
// Renders a resume JSON to PDF with Typst.
// The JSON files here use `work[].company` and `certifications`; the template
// expects `work[].name` and `certificates`, so the shape is adapted first.
// Usage: node scripts/build-pdf.mjs resumes/us.json build/us.pdf
import { spawnSync } from "node:child_process";
import { mkdirSync, readFileSync, writeFileSync, rmSync } from "node:fs";
import { dirname, resolve } from "node:path";

const [src, out] = process.argv.slice(2);
if (!src || !out) {
  console.error("usage: build-pdf.mjs <resume.json> <out.pdf>");
  process.exit(2);
}

const r = JSON.parse(readFileSync(src, "utf8"));
for (const w of r.work ?? []) {
  w.name = w.company;
  delete w.company;
  delete w.logo;
}
r.certificates = (r.certifications ?? []).map((c) => ({ ...c, startDate: c.date ?? c.startDate }));
delete r.certifications;
r.interests ??= [];
r.references ??= [];

mkdirSync("build", { recursive: true });
mkdirSync(dirname(out), { recursive: true });
const tmp = resolve("build", ".resume.typst.json");
writeFileSync(tmp, JSON.stringify(r));

const res = spawnSync("typst", [
  "compile",
  "--root", process.cwd(),
  "--font-path", "typst/fonts",
  // Render from the vendored fonts only, so CI and a laptop produce the same PDF.
  "--ignore-system-fonts",
  "--input", "resume=/build/.resume.typst.json",
  "typst/resume.typ",
  out,
], { stdio: "inherit" });

rmSync(tmp, { force: true });
if (res.error) {
  console.error("typst is required: https://github.com/typst/typst");
  process.exit(1);
}
process.exit(res.status ?? 0);
