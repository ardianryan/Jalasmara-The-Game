# Staging startup and PCK payload audit — 11 November 2026

## Scope and release identity

This is a read-only audit of the active public staging build, not a new game release. The active runtime source remains `4980d6b172e7524fad8dbef3ea02e3916c4ea3c3`, image `sha256:10bcbab5484c0943a970f8d83819609138c016b5445c57d704414f7358d44a79`, and PCK `cb5bd527bca632c66f2d23f7dc1a87758d2e4d057249a28d5efc4a40e3516b27` (86,885,700 bytes). The repository `main` was `221d3ce8b032dd17b38f640c34a8bb29499b6703` at the start of this audit. Gitea CI 17 completed successfully for that documentation head. No source, export, server, container, or staging configuration was changed.

## Observed startup

The public host-only smoke completed its six checks: real account login, game READY/HUD, reload and clock ownership, saved position, no Admin chunk on player routes, and mock-owner Admin chunk rendering. It reported no failures or errors. Temporary test records were removed: zero players, receipts, shifts, and Redis keys remain. The ignored local trace is `.runtime/staging-startup-trace-20261111.log`; the ignored browser result is `artifacts/browser/staging-plan06-6ba39ac4-c726-4e13-bbbc-6b3a98cc0ccb/results.json`. Neither contains a released artifact.

The trace recorded 83 successful HTTP/2 PCK part responses on initial load and another 83 after page reload. Each set decoded exactly 86,885,700 bytes and matched the release manifest. No request for the unsplit `/game/index.pck` was observed. Initial part transfer spanned 31,689 ms; the second spanned 31,574 ms. READY and HUD appeared about 42 seconds after the first game HTML navigation and about 42 seconds after the reload navigation. The loading display showed real decoded-byte progress over approximately 126.4 MB of PCK plus WASM. These are two runs inside one desktop browser session, not a representative latency distribution or a Windows/Samsung S23 result.

The CDP trace marked all 166 part responses `fromDiskCache=false`. A separate controlled request proved that an individual part can be served from the browser disk cache on repeated fetches. Fetching all 83 parts caused at least the earliest part to miss on immediate re-fetch while middle and late parts hit. Fetching the parts together with WASM caused additional early and middle misses. **Inference:** cache pressure plausibly explains the repeated PCK transfer; the exact eviction policy, quota and device behavior were not established. Cache-control for a hashed part was `public, max-age=31536000, immutable`, so changing that header alone is not supported by this evidence.

## Verified PCK contents

`scripts/performance/pck-inventory.py` verified the standalone Godot 4.7.2 PCK, including all 703 payload MD5 values and the whole-file SHA-256. The inventory is ignored locally at `.runtime/pck-inventory-20261111.json`. Its largest groups are:

| Resource group | Files | Stored bytes | Share of PCK |
| --- | ---: | ---: | ---: |
| Imported textures `.ctex` | 146 | 44,007,882 | 50.7% |
| Imported music `.mp3str` | 10 | 38,565,574 | 44.4% |
| Imported audio samples `.sample` | 61 | 1,931,147 | 2.2% |
| Other payload and pack metadata | — | 2,381,097 | 2.7% |

The six owner-supplied files added in the recent audio package account for five new BGM tracks and one victory MP3; the current pack has ten imported MP3 streams in total. The older [06-P inventory](../performance/06p-payload-audit.md) had four MP3 streams and a 64,249,828-byte PCK. The PCK grew by **22,635,872 bytes**. Audio is the dominant new category, although exact per-commit attribution requires comparing exports built from each source revision. The separate victory file lasts about 62.7 seconds; ducking currently lasts until its `finished` signal, so its musical role and intended duck duration should be reviewed by ear before shortening or cutting it.

## Next implementation gate

The strongest size candidate is to serve BGM separately and load only the requested track on Web. That is a **proposal, not an implemented optimization**. It needs a versioned asset manifest and hash checks, a native/Web resource path split, asynchronous loading with safe context changes, title and cave/music fallback behavior, package verification, cache/rollback rules, and a browser audio regression. Reducing or deleting textures by filename alone would risk scene references and is not justified by this audit. CacheStorage for the whole PCK also needs quota and eviction evidence on the target phones before adoption.

Suggested order: (1) implement and test BGM externalization in an isolated worktree; (2) compare cold and reload bytes/time with the same staging smoke and verify title, forest, village hall, dusk, cave, boss, kedai, mute and victory recovery; (3) test actual Samsung S23 and Windows performance with the owner; (4) only then consider additional texture or PCK caching work. Keep the current image and verified rollback until the replacement has a healthy deployment and smoke evidence.

## Reproduction and limitations

```sh
RUN_STAGING_SMOKE=plan06-public PLAN06_EXPECT_PCK=cb5bd527bca632c66f2d23f7dc1a87758d2e4d057249a28d5efc4a40e3516b27 PLAN06_EXPECT_PCK_BYTES=86885700 STAGING_HOST_ONLY=1 STAGING_STARTUP_TRACE=1 node --import tsx scripts/staging-plan06-smoke.mjs
python3 scripts/performance/pck-inventory.py apps/web/public/game/index.pck --expected-sha256 cb5bd527bca632c66f2d23f7dc1a87758d2e4d057249a28d5efc4a40e3516b27
```

Tools actually used: the repository's staging Playwright/CDP smoke, Python 3 PCK inventory, public HTTP/2 response inspection, `afinfo` for MP3 duration/format, and Git. No Sprite AI, Imagen, external pixel engine, new art asset, or new dependency was used. The original music provenance and usage rights remain in [asset provenance](../assets/provenance.md); this audit does not change them. It proves transfer, hashes and host startup for this browser run. It does not prove device FPS, listening quality, natural gait, or a gameplay playthrough.
