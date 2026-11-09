# Obsolete local delivery-context copies

On 10 November, approximately05.20WIB, root removed three inactive `.runtime` delivery contexts in the original workspace. These were exact Git-archive copies, not live worktrees or unique source candidates. Every file's Git blob hash matched its retained canonical commit, with no missing, added or changed files. Each commit remains an ancestor of integrationHEAD. No `.git` existed in the contexts, none was a registered worktree, and a full `lsof` inventory found no open file or current-directory handle beneath them.

| Removed path under `/Users/ardianryan/Documents/Jalasmara/.runtime/` | Canonical commit | Matching files | Allocated bytes |
| --- | --- | ---: | ---: |
| `release-ed6494b` | `ed6494b` |753|98,402,304|
| `release-f0e7080` | `f0e7080` |627|85,164,032|
| `release-ed70cad` | `ed70cad` |626|84,905,984|

Total268,472,320allocatedbytes. Filesystem free space observed11,970,637,824→12,239,081,472bytes; concurrent filesystem accounting need not equal the allocation sum. Inventories `.runtime/overnight-old-context-source-duplicates.json` and `overnight-old-context-cleanup-0520.json` preserve the exact checks and deletion scope. Initial inspection found these contexts did not contain standalone compiled PCK/WASM payloads, so the report does not label them binary exports. They were redundant delivery snapshots recoverable from their commits.

Original main/source, active candidate worktrees, Git objects, dependency/tool installations, benchmark evidence, Godot cache/runtime, active preview/dist, saves, database, backups and VPS were untouched by this cleanup. [Export4 cleanup](overnight-export4-integration.md) separately records the accepted release's local69MBarchive and remote superseded context/image removal. No broad prune, cache-directory sweep or symlink traversal was used.
