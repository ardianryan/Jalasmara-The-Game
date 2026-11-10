#!/usr/bin/env bash
set -euo pipefail

npm ci
node --test scripts/push-remotes.test.mjs
node ci/init-mongo.mjs
npm run typecheck
node --test scripts/game-loading-bridge.test.mjs scripts/godot-preloader-stream.test.mjs scripts/godot-wasm-init-errors.test.mjs scripts/loader-body-fault.test.mjs scripts/pck-stream.test.mjs scripts/pck-identity.test.mjs
node --test scripts/land-view-navigation.test.mjs scripts/left-forest-fixture.test.mjs scripts/calendar-resume-proof.test.mjs scripts/public-smoke-scope.test.mjs
node --test scripts/canopy-route-fixture.test.mjs scripts/gateway-route-fixture.test.mjs scripts/saras-alpha-fixture.test.mjs
node --test scripts/gameplay-api-failure.test.mjs
node --import tsx --test scripts/live-parent-navigation.test.mjs scripts/jahe-cycle-fixture.test.mjs scripts/wardrobe-route-fixture.test.mjs scripts/wardrobe-visibility-fixture.test.mjs scripts/equipment-node-proof.test.mjs
node --test scripts/own-fixture-auth.test.mjs
node --test scripts/performance/*.test.mjs
python3 tools/npc-rig/test_resident_parts.py
python3 scripts/test_package_web_release.py -v
python3 -m unittest discover -s tools/player-gait -p test_check_stair_contacts.py -v
python3 -m unittest discover -s tools/player-gait -p test_facing_recovery.py -v
python3 -m unittest discover -s tools/player-gait -p test_audit_ramp_curve.py -v
python3 -m unittest discover -s tools/player-gait -p test_west_upper_prototype.py -v
python3 tools/player-gait/south-upper-anchors-test.py
python3 tools/player-gait/south-upper-ownership-test.py
python3 tools/player-gait/south-upper-loop-test.py
python3 tools/player-gait/south-explorer-upper-test.py
python3 tools/player-gait/nw-upper-source-audit-test.py
python3 tools/player-gait/nw-explorer-orientation-proposal-test.py
python3 tools/player-gait/nw-explorer-upper-rig-test.py
python3 tools/player-gait/nw-explorer-upper-loop-test.py
python3 tools/player-gait/nw-daily-upper-rig-test.py
python3 tools/player-gait/nw-daily-upper-loop-test.py
python3 tools/player-gait/north-upper-rig-test.py
python3 tools/player-gait/north-upper-loop-test.py
npm run check:worldkit
npm ci --prefix tools/image-to-pixel --ignore-scripts
node --test tools/image-to-pixel/convert.test.mjs
mkdir -p reports
npx tsx --test --test-concurrency=1 --test-reporter=junit --test-reporter-destination=reports/tests.xml apps/api/test/*.test.ts
npm audit --json > reports/dependencies.json
npm ci --prefix tools/img2threejs --ignore-scripts
npm audit --prefix tools/img2threejs --json > reports/asset-tool-dependencies.json
npm audit --prefix tools/image-to-pixel --json > reports/worldkit-image-dependencies.json
