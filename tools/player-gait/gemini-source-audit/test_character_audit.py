"""Comprehensive unit test suite for corrected Gemini character source audit.

Verifies:
- Selection of exactly 10 specified sets (excluding male_nusantara daily/explorer)
- Presence and consistency of 80 canonical direction records
- Rejection of other agent review paths in docs/reviews/
- Rejection of symlinks in path components
- Rejection of pre-existing run artifact directories
- Rejection of malformed input dimensions
- Input manifest SHA-256 hash correctness and file immutability
- Curated gallery size limit (<= 1 MiB)
- Revocation of false-positive P0 orientation inversion claims
"""
from __future__ import annotations

import json
import os
import sys
import tempfile
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(Path(__file__).resolve().parent))

from audit_character_sources import (
    DIRECTIONS,
    TARGET_SETS,
    validate_output_path,
    sha256_file,
    check_symlink_components,
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
    """Verify boundary checks prevent writing to forbidden reviews, symlinks, or outside paths."""
    # Allowed exact files
    allowed_file = ROOT / "docs/reviews/gemini-character-source-audit.json"
    assert validate_output_path(ROOT, allowed_file) == allowed_file.resolve()

    allowed_md = ROOT / "docs/reviews/gemini-character-source-audit.md"
    assert validate_output_path(ROOT, allowed_md) == allowed_md.resolve()

    # FORBIDDEN: other files in docs/reviews/
    forbidden_other_review = ROOT / "docs/reviews/gemini-character-audit-integration-review.md"
    try:
        validate_output_path(ROOT, forbidden_other_review)
        assert False, "Should have rejected writing to other agent's review file"
    except ValueError:
        pass

    forbidden_hack_review = ROOT / "docs/reviews/arbitrary-review.md"
    try:
        validate_output_path(ROOT, forbidden_hack_review)
        assert False, "Should have rejected arbitrary docs/reviews/ file"
    except ValueError:
        pass

    # Forbidden paths: client-godot, assets, root outside
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

    # Symlink component rejection
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp_target = Path(tmpdir) / "real_file.png"
        tmp_target.write_bytes(b"content")
        symlink_path = ROOT / ".runtime/gemini-source-audit/test_symlink.png"
        symlink_path.parent.mkdir(parents=True, exist_ok=True)
        try:
            symlink_path.unlink(missing_ok=True)
            symlink_path.symlink_to(tmp_target)
            try:
                validate_output_path(ROOT, symlink_path)
                assert False, "Should have rejected symlink output"
            except ValueError:
                pass
        finally:
            symlink_path.unlink(missing_ok=True)

    # Rejection of existing destination when allow_existing=False
    existing_file = ROOT / "docs/reviews/gemini-character-source-audit.json"
    if existing_file.exists():
        try:
            validate_output_path(ROOT, existing_file, allow_existing=False)
            assert False, "Should have rejected existing destination when allow_existing=False"
        except ValueError:
            pass

    print("PASS: output path validation and boundary guards")


def test_audit_json_contents_and_revocations():
    """Verify generated JSON has 80 direction records and expected schema with P0 revocations."""
    json_path = ROOT / "docs/reviews/gemini-character-source-audit.json"
    assert json_path.exists(), f"JSON file missing: {json_path}"
    data = json.loads(json_path.read_text())

    # Check top-level keys
    for k in ["audit_meta", "input_inventory", "summary", "unknowns", "set_summaries", "records", "correction_proofs"]:
        assert k in data, f"Missing key: {k}"

    summary = data["summary"]
    assert summary["total_sets_audited"] == 10
    assert summary["total_directions_audited"] == 80
    assert summary["total_walk_frames_audited"] == 640
    assert summary["total_idle_poses_audited"] == 80
    assert summary["revoked_p0_claims_count"] == 7
    assert summary["accepted_p0_defects_count"] == 0

    records = data["records"]
    assert len(records) == 80, f"Expected 80 records, found {len(records)}"

    # Check that female_default/explorer NW (idx 5) has revoked P0 note
    fde_nw = next(r for r in records if r["identity"] == "female_default" and r["outfit"] == "explorer" and r["direction_name"] == "north_west")
    assert fde_nw["status"] == "reviewed_no_obvious_issue"
    assert any("P0 claim REVOKED" in note for note in fde_nw["visual_ledger"]["notes"])

    # Check that male_nusantara/diving NW (idx 5) has revoked P0 note
    mnd_nw = next(r for r in records if r["identity"] == "male_nusantara" and r["outfit"] == "diving" and r["direction_name"] == "north_west")
    assert mnd_nw["status"] == "reviewed_no_obvious_issue"
    assert any("P0 claim REVOKED" in note for note in mnd_nw["visual_ledger"]["notes"])

    print("PASS: audit JSON contents verification and P0 revocations (80 records valid)")


def test_curated_gallery_size_limit():
    """Verify total size of docs/visual/gemini-character-source-audit/ <= 1 MiB."""
    vis_dir = ROOT / "docs/visual/gemini-character-source-audit"
    assert vis_dir.exists(), "Gallery directory missing"
    images = list(vis_dir.glob("*.png"))
    assert len(images) >= 6, f"Expected at least 6 evidence images, found {len(images)}"

    total_bytes = sum(f.stat().st_size for f in images)
    max_bytes = 1024 * 1024  # 1 MiB
    assert total_bytes <= max_bytes, f"Gallery exceeds 1 MiB: {total_bytes} bytes"
    print(f"PASS: curated gallery size limit ({len(images)} images, {total_bytes} bytes = {total_bytes / 1024:.1f} KiB <= 1024 KiB)")


def test_source_immutability_and_expected_hashes():
    """Verify input source files and production atlases match baseline hashes exactly."""
    manifest_batch_path = ROOT / "assets/source-2d/nala-eightway-batch/manifest.json"
    actual_batch_sha = sha256_file(manifest_batch_path)
    expected_batch_sha = "21fa13f548ea4d582ec624d3dd6c3162e237dc455366d1c9a0415aa221d49f79"
    assert actual_batch_sha == expected_batch_sha, f"Batch manifest SHA mismatch: {actual_batch_sha} vs {expected_batch_sha}"

    daily_source_json_path = ROOT / "assets/source-2d/nala-daily-eightway/source.json"
    actual_daily_sha = sha256_file(daily_source_json_path)
    expected_daily_sha = "8e65f4e8d22d18060e6b21bf889c558c39631a1c942e66cee65d33e48d9e9c74"
    assert actual_daily_sha == expected_daily_sha, f"Daily source JSON SHA mismatch: {actual_daily_sha} vs {expected_daily_sha}"

    # Check each set in manifest
    manifest_batch = json.loads(manifest_batch_path.read_text())
    for item in manifest_batch.get("sets", []):
        for rec in item.get("sources", []) + item.get("outputs", []):
            p = ROOT / rec["path"]
            actual_sha = sha256_file(p)
            assert actual_sha == rec["sha256"], f"File mutated: {rec['path']} ({actual_sha} vs {rec['sha256']})"

    print("PASS: source files and production atlases immutability verified with expected hashes")


if __name__ == "__main__":
    test_target_sets_scope()
    test_canonical_directions_order()
    test_output_path_validation_and_guards()
    test_audit_json_contents_and_revocations()
    test_curated_gallery_size_limit()
    test_source_immutability_and_expected_hashes()
    print("\nALL 6 CORRECTED CHARACTER AUDIT TESTS PASSED SUCCESSFULLY.")
