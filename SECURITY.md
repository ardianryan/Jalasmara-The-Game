# Security policy

Jalasmara `0.1.0` is an early-development prototype. **No independent security audit or penetration test has been completed.** Passing CI, dependency checks, CodeQL, or a staging smoke test must not be read as a security certification. The staging service may change without a compatibility guarantee.

## Reporting a vulnerability

Do not publish exploit steps, tokens, account data, or database dumps in an issue or pull request. Contact the repository owner through a private channel shown on the owner's profile. If no private channel is available, open a public issue asking only for a secure contact method; omit technical details until a private channel is established.

Include the affected commit/version and endpoint or component, prerequisites, impact, and a minimal reproduction using accounts and data you control. Avoid destructive tests, denial-of-service traffic, or accessing other players' data. The maintainer will acknowledge and triage reports as capacity allows; no response-time or bounty commitment is offered.

## Current boundaries

The API owns game progress and economy. Production sessions use secure cookie settings, and administrative actions require server-side authorization. These design measures do not replace an audit. Never put credentials into source, reports, screenshots, or logs. Use isolated fixtures for tests and follow the [release procedure](docs/operations.md) for backup and rollback.
