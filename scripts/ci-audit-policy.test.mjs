import { test } from "node:test";
import assert from "node:assert/strict";
import { checkAuditReports } from "./ci-audit-policy.mjs";

const issue = { severity: "high", via: [{ url: "https://github.com/advisories/GHSA-fc5q-39xc-vjpf", range: "<=4.0.7" }] };
const full = { vulnerabilities: {
  fdir: { severity: "high", via: ["picomatch"] },
  picomatch: issue,
  tinyglobby: { severity: "high", via: ["fdir", "picomatch"] },
  vite: { severity: "high", via: ["fdir", "picomatch", "tinyglobby"] },
} };
const production = { metadata: { vulnerabilities: { total: 0 } } };
const lock = { packages: Object.fromEntries(["fdir", "picomatch", "tinyglobby", "vite"].map(name => [`node_modules/${name}`, { dev: true, version: name === "picomatch" ? "4.0.7" : "1" }])) };

test("only the known build-time advisory is temporarily accepted", () => {
  assert.match(checkAuditReports(full, production, lock), /Production audit clean/);
  assert.match(checkAuditReports({ vulnerabilities: {} }, production, lock), /audits are clean/);
  assert.throws(() => checkAuditReports({ vulnerabilities: { ...full.vulnerabilities, surprise: issue } }, production, lock));
  assert.throws(() => checkAuditReports(full, { metadata: { vulnerabilities: { total: 1 } } }, lock));
  assert.throws(() => checkAuditReports(full, production, { packages: { ...lock.packages, "node_modules/picomatch": { dev: false, version: "4.0.7" } } }));
  assert.throws(() => checkAuditReports({ vulnerabilities: { ...full.vulnerabilities, picomatch: { ...issue, via: [...issue.via, { url: "another" }] } } }, production, lock));
});
