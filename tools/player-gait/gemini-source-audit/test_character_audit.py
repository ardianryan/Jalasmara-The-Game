"""Unit tests for Gemini character source audit tool.

Verifies:
- Selection of exactly 10 specified sets
- Generation and presence of 80 canonical direction records
- Canonical direction ordering (0..7)
- Path validation and output boundary enforcement
- Curated gallery size limit (<= 1 MiB)
- Source files and production atlases remain untouched (hash immutability)
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(Path(__file__).resolve().parent))

from audit_character_sources import (
    DIRECTIONS,
    TARGET_SETS,
    validate_output_path,
    sha256_file,
)


def test_target_sets_scope():
    """Verify exactly 10 sets are targeted and male_nusantara daily/explorer are excluded."""
    assert len(TARGET_SETS) == 10, f"Expected 10 target sets, found {len(TARGET_SETS)}"
    identities_outfits = {(s["identity"], s["outfit"]) for s in TARGET_SETS}
    assert ("male_nusantara", "daily") not in identities_outfits, "male_nusantara/daily must be excluded"
    assert ("male_nusantara", "explorer") not in identities_outfits, "male_nusantara/explorer must be excluded"
    assert ("male_nusantara", "diving") in identities_outfits, "male_nusantara/diving must be included"
    print("PASS: target sets scope verification (10 sets, 2 excluded)")


def test_canonical_directions_order():
    """Verify 8 canonical directions match Godot runtime contract."""
    expected = [
        "east",
        "south_east",
        "south",
        "south_west",
        "west",
        "north_west",
        "north",
        "north_east",
    ]
    assert DIRECTIONS == expected, f"Direction mismatch: {DIRECTIONS} vs {expected}"
    print("PASS: canonical direction order verification (8 directions)")


def test_output_path_validation_and_guards():
    """Verify boundary checks prevent writing to forbidden runtime or source paths."""
    # Allowed paths
    allowed_file = ROOT / "docs/reviews/gemini-character-source-audit.json"
    assert validate_output_path(ROOT, allowed_file) == allowed_file.resolve()

    allowed_vis = ROOT / "docs/visual/gemini-character-source-audit/test.png"
    assert validate_output_path(ROOT, allowed_vis) == allowed_vis.resolve()

    # Forbidden paths
    forbidden_godot = ROOT / "client-godot/resources/art/player-gait/hack.png"
    try:
        validate_output_path(ROOT, forbidden_godot)
        assert False, "Should have rejected writing to client-godot/"
    except ValueError:
        pass

    forbidden_source = ROOT / "assets/source-2d/nala-eightway-batch/hack.png"
    try:
        validate_output_path(ROOT, forbidden_source)
        assert False, "Should have rejected writing to assets/"
    except ValueError:
        pass

    forbidden_outside = Path("/tmp/outside-repo.png")
    try:
        validate_output_path(ROOT, forbidden_outside)
        assert False, "Should have rejected writing outside repo"
    except ValueError:
        pass

    print("PASS: output path validation and boundary guards")


def test_audit_json_contents():
    """Verify generated JSON has 80 direction records and expected schema."""
    json_path = ROOT / "docs/reviews/gemini-character-source-audit.json"
    assert json_path.exists(), f"JSON file missing: {json_path}"
    data = json.loads(json_path.read_text())

    # Check top-level keys
    for k in ["audit_meta", "summary", "unknowns", "set_summaries", "records", "curated_proofs"]:
        assert k in data, f"Missing key: {k}"

    summary = data["summary"]
    assert summary["total_sets_audited"] == 10
    assert summary["total_directions_audited"] == 80
    assert summary["total_walk_frames_audited"] == 640
    assert summary["total_idle_poses_audited"] == 80

    records = data["records"]
    assert len(records) == 80, f"Expected 80 records, found {len(records)}"

    # Check each record has canonical direction index 0..7
    for idx, r in enumerate(records):
        expected_d_idx = idx % 8
        assert r["direction_index"] == expected_d_idx
        assert r["direction_name"] == DIRECTIONS[expected_d_idx]
        assert r["status"] in ["reviewed_no_obvious_issue", "issue", "unknown"]
        if r["status"] == "issue":
            assert len(r["issues"]) > 0
            assert r["priority"] in ["P0", "P1", "P2"]

    print("PASS: audit JSON contents verification (80 records valid)")


def test_curated_gallery_size_limit():
    """Verify total size of docs/visual/gemini-character-source-audit/ <= 1 MiB."""
    vis_dir = ROOT / "docs/visual/gemini-character-source-audit"
    assert vis_dir.exists(), "Gallery directory missing"
    images = list(vis_dir.glob("*.png"))
    assert len(images) >= 5, f"Expected at least 5 evidence images, found {len(images)}"

    total_bytes = sum(f.stat().st_size for f in images)
    max_bytes = 1024 * 1024  # 1 MiB
    assert total_bytes <= max_bytes, f"Gallery exceeds 1 MiB: {total_bytes} bytes"
    print(f"PASS: curated gallery size limit ({len(images)} images, {total_bytes} bytes = {total_bytes / 1024:.1f} KiB <= 1024 KiB)")


def test_source_immutability():
    """Verify input source files and production atlases match baseline hashes."""
    # Check manifest.json
    manifest_batch_path = ROOT / "assets/source-2d/nala-eightway-batch/manifest.json"
    manifest_batch = json.loads(manifest_batch_path.read_text())

    # Check each set in manifest
    for item in manifest_batch.get("sets", []):
        for rec in item.get("sources", []) + item.get("outputs", []):
            p = ROOT / rec["path"]
            actual_sha = sha256_file(p)
            assert actual_sha == rec["sha256"], f"File mutated: {rec['path']} ({actual_sha} vs {rec['sha256']})"

    # Check daily source
    daily_source_json = json.loads((ROOT / "assets/source-2d/nala-daily-eightway/source.json").read_text())
    for d in daily_source_json.get("directions", []):
        dp = ROOT / "assets/source-2d/nala-daily-eightway" / d["source"]
        assert sha256_file(dp) == d["sha256"], f"Daily source mutated: {dp}"

    print("PASS: source files and production atlases immutability verified")


if __name__ == "__main__":
    test_target_sets_scope()
    test_canonical_directions_order()
    test_output_path_validation_and_guards()
    test_audit_json_contents()
    test_curated_gallery_size_limit()
    test_source_immutability()
    print("\nALL 6 CHARACTER AUDIT TESTS PASSED SUCCESSFULLY.")
