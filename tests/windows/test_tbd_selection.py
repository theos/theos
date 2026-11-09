"""Capability selection contracts; no Apple SDK or old linker required."""
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("tbd_selection", ROOT / "bin" / "select-windows-tbd.py")
selection = importlib.util.module_from_spec(spec)
spec.loader.exec_module(selection)


class TbdSelectionTests(unittest.TestCase):
    def run_selection(self, capabilities, library=None, scheme=""):
        results = [subprocess.CompletedProcess([], 0, b"", b"")]
        results += [subprocess.CompletedProcess([], 0 if ok else 1, b"", b"unsupported format") for ok in capabilities]
        with mock.patch.object(selection.subprocess, "run", side_effect=results):
            return selection.choose("clang", library or ROOT / "vendor" / "lib", scheme)

    def test_legacy_capable_linker_keeps_canonical_tree(self):
        with tempfile.TemporaryDirectory() as directory:
            library = Path(directory)
            (library / "libsubstrate.tbd").write_text("---\n", encoding="utf-8")
            self.assertEqual(self.run_selection([True, False, False], library), "legacy")

    def test_legacy_checkout_without_symlinks_fails_clearly(self):
        with tempfile.TemporaryDirectory() as directory:
            library = Path(directory)
            (library / "libsubstrate.tbd").write_text("CydiaSubstrate.framework/CydiaSubstrate.tbd", encoding="utf-8")
            with self.assertRaisesRegex(RuntimeError, "enable Git symlinks"):
                self.run_selection([True, False, False], library)

    def test_modern_linker_requires_both_v3_and_v4(self):
        self.assertEqual(self.run_selection([False, True, True]), "modern")
        with self.assertRaises(RuntimeError):
            self.run_selection([False, True, False])

    def test_failed_probe_is_not_assumed_modern(self):
        with self.assertRaises(RuntimeError):
            self.run_selection([False, False, False])

    def test_partial_rootless_overlay_fails_closed(self):
        with tempfile.TemporaryDirectory() as directory:
            library = Path(directory)
            canonical = library / "iphone" / "rootless"
            canonical.mkdir(parents=True)
            (canonical / "libsubstrate.tbd").write_text("alias")
            with self.assertRaisesRegex(RuntimeError, "incomplete"):
                self.run_selection([False, True, True], library, "rootless")

    def test_unknown_scheme_fails_closed(self):
        with self.assertRaisesRegex(RuntimeError, "verified scheme"):
            self.run_selection([False, True, True], scheme="custom")

    def test_overlay_aliases_are_regular_stubs_with_matching_exports(self):
        library = ROOT / "vendor/lib/tbd/modern"
        for tree in (library, library / "iphone/rootless"):
            alias = tree / "libsubstrate.tbd"
            framework = tree / "CydiaSubstrate.framework/CydiaSubstrate.tbd"
            self.assertFalse(alias.is_symlink())
            self.assertEqual(alias.read_bytes(), framework.read_bytes())

    def test_compile_probe_failure_is_reported(self):
        result = subprocess.CompletedProcess([], 1, b"", b"compiler failed")
        with mock.patch.object(selection.subprocess, "run", return_value=result):
            with self.assertRaisesRegex(RuntimeError, "cannot compile"):
                selection.choose("bad-clang", ROOT / "vendor" / "lib")

    def make_instance(self, operation, *extra):
        return subprocess.run([
            "make", "-C", str(ROOT / "tests/windows/project"), "-n",
            f"internal-tool-{operation}", f"THEOS={ROOT}",
            "THEOS_CURRENT_INSTANCE=windows_parse_smoke", "_THEOS_CURRENT_TYPE=tool",
            f"_THEOS_CURRENT_OPERATION={operation}", "THEOS_WINDOWS_ALLOW_NO_SDK=1",
            *extra,
        ], capture_output=True, text=True, timeout=60)

    def test_instance_stage_does_not_probe_missing_link_driver(self):
        result = self.make_instance("stage", "TARGET_LD=definitely-missing.exe")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn("TBD selection failed", result.stderr)

    def test_stale_overlay_does_not_leak_into_stage(self):
        result = self.make_instance("stage", "_THEOS_WINDOWS_TBD_PATH=stale-rootful-overlay")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("stale-rootful-overlay", result.stdout)

    def test_selected_driver_missing_fails_closed(self):
        result = self.make_instance("compile", "_THEOS_TARGET_LDFLAGS=-fuse-ld=lld", "TARGET_LD=definitely-missing.exe")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("TBD capability probe", result.stderr)

    def test_internal_and_architecture_linker_overrides_fail_closed(self):
        for flag in ("_THEOS_INTERNAL_LDFLAGS=--ld-path=bad", "ALL_ARCHFLAGS=-Bbad"):
            result = self.make_instance("compile", "_THEOS_TARGET_LDFLAGS=-fuse-ld=lld", flag)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Custom linker selection flags are unsupported", result.stderr)


if __name__ == "__main__":
    unittest.main()
