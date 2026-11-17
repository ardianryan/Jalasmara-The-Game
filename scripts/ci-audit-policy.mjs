import { readFileSync } from "node:fs";
import { pathToFileURL } from "node:url";

const advisory = "https://github.com/advisories/GHSA-fc5q-39xc-vjpf";
const affected = ["fdir", "picomatch", "tinyglobby", "vite"];

export function checkAuditReports(full, production, lock) {
  if (production?.metadata?.vulnerabilities?.total !== 0) {
    throw new Error("Production dependency audit is not clean.");
  }
  const vulnerabilities = full?.vulnerabilities;
  if (!vulnerabilities || typeof vulnerabilities !== "object") {
    throw new Error("Full dependency audit is missing vulnerabilities.");
  }
  const names = Object.keys(vulnerabilities).sort();
  if (names.length === 0) return "Full and production dependency audits are clean.";
  if (JSON.stringify(names) !== JSON.stringify([...affected].sort())) {
    throw new Error(`Unexpected dependency vulnerabilities: ${names.join(", ")}`);
  }
  const picomatch = vulnerabilities.picomatch;
  if (
    picomatch.severity !== "high" ||
    picomatch.via.length !== 1 ||
    picomatch.via[0]?.url !== advisory ||
    picomatch.via[0]?.range !== "<=4.0.7"
  ) {
    throw new Error("The picomatch advisory differs from the reviewed exception.");
  }
  const expectedVia = {
    fdir: ["picomatch"],
    tinyglobby: ["fdir", "picomatch"],
    vite: ["fdir", "picomatch", "tinyglobby"],
  };
  for (const [name, via] of Object.entries(expectedVia)) {
    const issue = vulnerabilities[name];
    if (issue.severity !== "high" || JSON.stringify([...issue.via].sort()) !== JSON.stringify([...via].sort())) {
      throw new Error(`${name} has an unreviewed advisory chain.`);
    }
  }
  for (const name of affected) {
    const entry = lock?.packages?.[`node_modules/${name}`];
    if (!entry?.dev) throw new Error(`${name} is no longer confined to development dependencies.`);
  }
  if (lock.packages["node_modules/picomatch"].version !== "4.0.7") {
    throw new Error("The reviewed picomatch version changed; re-evaluate the audit.");
  }
  return `Production audit clean; only reviewed build-time picomatch advisory ${advisory} remains.`;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const [fullPath, productionPath, lockPath] = process.argv.slice(2);
  if (!fullPath || !productionPath || !lockPath) throw new Error("Usage: ci-audit-policy.mjs FULL PROD LOCK");
  console.log(checkAuditReports(
    JSON.parse(readFileSync(fullPath, "utf8")),
    JSON.parse(readFileSync(productionPath, "utf8")),
    JSON.parse(readFileSync(lockPath, "utf8")),
  ));
}
