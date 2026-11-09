import hashlib
import json
import os
import plistlib
import shutil
import subprocess
import gzip
import io
import lzma
import tarfile
import zipfile
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HELPER = ROOT / "bin" / "theos-windows.py"
LOGOS = ROOT / "vendor" / "logos" / "bin" / "logos.pl"


class WindowsHelperTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="theos path with spaces ")
        self.root = Path(self.temp.name)
        self.helper("mkdir", str(self.root / "source tree"))

    def tearDown(self):
        self.temp.cleanup()

    def helper(self, *args, input_bytes=None):
        return subprocess.run([sys.executable, str(HELPER), *args], input=input_bytes, capture_output=True, check=False)

    def test_copy_control_and_control_generation_with_spaces(self):
        source = self.root / "source tree" / "control"
        source.write_text("Package: demo.pkg\nName: Demo\nVersion: 1.2\nArchitecture: iphoneos-arm64\nDescription: ${LIBSWIFT}\n", encoding="utf-8")
        dest = self.root / "staging tree" / "DEBIAN" / "control"
        result = self.helper("control-file", str(source), str(dest), "--architecture", "iphoneos-arm64", "--version", "1.2-1", "--stage", str(self.root / "staging tree"), "--libswift", "org.swift.libswift (>= 5.0)")
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertEqual(self.helper("control-field", str(source), "Package").stdout.strip(), b"demo.pkg")
        content = dest.read_text(encoding="utf-8")
        self.assertIn("Version: 1.2-1", content)
        self.assertIn("Architecture: iphoneos-arm64", content)
        self.assertIn("Description: org.swift.libswift (>= 5.0)", content)
        self.assertNotIn("Version: 1.2\n", content)

    def test_copy_preserves_directory_basename_and_supports_merge(self):
        source = self.root / "bundle tree"
        self.helper("mkdir", str(source / "nested"))
        (source / "nested" / "asset.txt").write_text("asset", encoding="utf-8")
        destination = self.root / "destination"
        self.assertEqual(self.helper("cp", str(source), str(destination)).returncode, 0)
        self.assertEqual((destination / source.name / "nested" / "asset.txt").read_text(encoding="utf-8"), "asset")
        merged = self.root / "merged"
        self.assertEqual(self.helper("cp", "--merge", str(source), str(merged)).returncode, 0)
        self.assertEqual((merged / "nested" / "asset.txt").read_text(encoding="utf-8"), "asset")

    def test_copy_list_copies_files_and_directories(self):
        source = self.root / "resource tree"
        self.helper("mkdir", str(source / "nested"))
        (source / "nested" / "asset.txt").write_text("asset", encoding="utf-8")
        destination = self.root / "bundle resources"
        result = self.helper("copy-list", "--destination", str(destination), str(source), str(self.root / "missing resource"))
        self.assertEqual(result.returncode, 0)
        self.assertEqual((destination / source.name / "nested" / "asset.txt").read_text(encoding="utf-8"), "asset")

    def test_filesystem_and_glob_removal(self):
        source = self.root / "source tree" / "payload.bin"
        source.write_bytes(b"payload")
        destination = self.root / "destination tree" / "payload.bin"
        self.assertEqual(self.helper("cp", str(source), str(destination)).returncode, 0)
        self.assertEqual(destination.read_bytes(), b"payload")
        directory_destination = self.root / "directory destination"
        self.helper("mkdir", str(directory_destination))
        self.assertEqual(self.helper("cp", str(source), str(directory_destination)).returncode, 0)
        self.assertEqual((directory_destination / source.name).read_bytes(), b"payload")
        self.assertEqual(self.helper("touch", str(destination.parent / "marker")).returncode, 0)
        self.assertEqual(self.helper("rm", "-f", str(destination.parent / "*")).returncode, 0)
        self.assertEqual(list(destination.parent.iterdir()), [])

    def test_pe_info_validates_native_x64_executables(self):
        executable = self.root / "clang.exe"
        data = bytearray(0x80)
        data[:2] = b"MZ"
        data[0x3c:0x40] = (0x40).to_bytes(4, "little")
        data[0x40:0x44] = b"PE\0\0"
        data[0x44:0x46] = (0x8664).to_bytes(2, "little")
        executable.write_bytes(data)
        result = self.helper("pe-info", str(executable))
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertEqual(result.stdout.strip().decode(), "x86_64")
        executable.write_bytes(b"not a PE")
        self.assertNotEqual(self.helper("pe-info", str(executable)).returncode, 0)

    def test_move_handles_paths_with_spaces(self):
        source = self.root / "source with spaces" / "artifact.o"
        destination = self.root / "destination with spaces" / "artifact.o"
        self.helper("mkdir", str(source.parent))
        source.write_bytes(b"macho object")
        result = self.helper("mv", str(source), str(destination))
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertEqual(destination.read_bytes(), b"macho object")
        self.assertFalse(source.exists())

    def test_optimize_plists_converts_xml_and_leaves_other_files(self):
        stage = self.root / "plist stage"
        self.helper("mkdir", str(stage / "Library"))
        xml_plist = (
            '<?xml version="1.0" encoding="UTF-8"?>\n'
            '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n'
            '<plist version="1.0"><dict><key>Filter</key><dict><key>Bundles</key>'
            "<array><string>com.apple.springboard</string></array></dict></dict></plist>\n"
        )
        (stage / "Library" / "Probe.plist").write_text(xml_plist, encoding="utf-8")
        binary_plist = b"bplist00" + b"already-binary"
        (stage / "Library" / "Binary.plist").write_bytes(binary_plist)
        strings = '"key" = "value";\n'
        (stage / "Library" / "Localizable.strings").write_text(strings, encoding="utf-8")
        result = self.helper("optimize-plists", "--directory", str(stage))
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        converted = (stage / "Library" / "Probe.plist").read_bytes()
        self.assertTrue(converted.startswith(b"bplist"), "XML plist should become a binary plist")
        self.assertEqual(plistlib.loads(converted)["Filter"]["Bundles"], ["com.apple.springboard"])
        self.assertEqual((stage / "Library" / "Binary.plist").read_bytes(), binary_plist)
        self.assertEqual((stage / "Library" / "Localizable.strings").read_text(encoding="utf-8"), strings)

    def test_aliased_subcommands_dispatch_instead_of_no_opping(self):
        # The makefiles invoke `move`/`copy`; argparse stores the alias as typed, so
        # dispatching only on the canonical name silently did nothing and returned 0.
        source = self.root / "alias source" / "signed.dylib"
        destination = self.root / "alias destination" / "signed.dylib"
        self.helper("mkdir", str(source.parent))
        source.write_bytes(b"signed payload")
        moved = self.helper("move", str(source), str(destination))
        self.assertEqual(moved.returncode, 0, moved.stderr.decode())
        self.assertFalse(source.exists(), "aliased move must not silently no-op")
        self.assertEqual(destination.read_bytes(), b"signed payload")
        copied = self.root / "alias copy" / "signed.dylib"
        result = self.helper("copy", "--ignore-missing", str(destination), str(copied))
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertEqual(copied.read_bytes(), b"signed payload")
        missing = self.helper("copy", "--ignore-missing", str(self.root / "absent"), str(self.root / "unused"))
        self.assertEqual(missing.returncode, 0, missing.stderr.decode())
        strict = self.helper("copy", str(self.root / "absent"), str(self.root / "unused"))
        self.assertNotEqual(strict.returncode, 0)

    def test_hash_and_process_exit_code(self):
        result = self.helper("hash", "md5", input_bytes=b"hello")
        tagged = self.helper("hash", "md5", "--value", "hello", "--length", "8")
        self.assertEqual(tagged.returncode, 0)
        self.assertEqual(tagged.stdout.strip().decode(), hashlib.md5(b"hello").hexdigest()[:8])
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout.strip().decode(), hashlib.md5(b"hello").hexdigest())
        failure = self.helper("run", sys.executable, "-c", "raise SystemExit(23)")
        self.assertEqual(failure.returncode, 23)

    def test_deb_archive_creation_and_members(self):
        stage = self.root / "deb stage"
        self.helper("mkdir", str(stage / "DEBIAN"), str(stage / "usr" / "lib"))
        (stage / "DEBIAN" / "control").write_text("Package: demo\nVersion: 1.0\nArchitecture: iphoneos-arm64\n", encoding="utf-8")
        (stage / "usr" / "lib" / "demo.dylib").write_bytes(b"mach-o test")
        output = self.root / "packages" / "demo.deb"
        result = self.helper("deb", str(stage), str(output))
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        raw = output.read_bytes()
        self.assertTrue(raw.startswith(b"!<arch>\n"))
        members = {}
        offset = 8
        while offset < len(raw):
            header = raw[offset:offset + 60]
            self.assertEqual(header[58:60], b"`\n")
            name = header[:16].decode("ascii").strip().rstrip("/")
            size = int(header[48:58].decode("ascii").strip())
            data_start = offset + 60
            members[name] = raw[data_start:data_start + size]
            offset = data_start + size + (size % 2)
        self.assertEqual(set(members), {"debian-binary", "control.tar.gz", "data.tar.gz"})
        self.assertEqual(members["debian-binary"], b"2.0\n")
        with tarfile.open(fileobj=io.BytesIO(members["control.tar.gz"]), mode="r:gz") as control:
            self.assertIn("control", control.getnames())
        with tarfile.open(fileobj=io.BytesIO(members["data.tar.gz"]), mode="r:gz") as data:
            self.assertIn("usr/lib/demo.dylib", data.getnames())
        inspected = self.helper("deb-info", str(output))
        self.assertEqual(inspected.returncode, 0, inspected.stderr.decode())
        self.assertIn("control.tar.gz", inspected.stdout.decode())
        truncated = self.root / "truncated.deb"
        truncated.write_bytes(output.read_bytes()[:-20])
        self.assertNotEqual(self.helper("deb-info", str(truncated)).returncode, 0)
        incomplete_stage = self.root / "incomplete deb stage"
        self.helper("mkdir", str(incomplete_stage / "DEBIAN"), str(incomplete_stage / "usr"))
        (incomplete_stage / "DEBIAN" / "control").write_text("Package: invalid\n", encoding="utf-8")
        incomplete_deb = self.root / "incomplete.deb"
        self.assertEqual(self.helper("deb", str(incomplete_stage), str(incomplete_deb)).returncode, 0)
        self.assertNotEqual(self.helper("deb-info", str(incomplete_deb)).returncode, 0)

    def test_ipa_archive_creation(self):
        stage = self.root / "ipa stage"
        self.helper("mkdir", str(stage / "Payload" / "Demo.app"))
        (stage / "Payload" / "Demo.app" / "Demo").write_bytes(b"mach-o test")
        output = self.root / "packages" / "demo.ipa"
        result = self.helper("ipa", str(stage), str(output), "--compression", "9")
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        with zipfile.ZipFile(output) as archive:
            self.assertEqual(archive.read("Payload/Demo.app/Demo"), b"mach-o test")

    def test_rpm_spec_generation(self):
        source = self.root / "package.spec"
        source.write_text("Name: demo\nVersion: 1.0\nRelease: 1\nSource0: old.tar.gz\n", encoding="utf-8")
        output = self.root / "obj" / "package.spec"
        result = self.helper("rpm-spec", str(source), str(output), "--release", "2", "--append-files")
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        content = output.read_text(encoding="utf-8")
        self.assertIn("Release: 2", content)
        self.assertNotIn("Source0:", content)
        self.assertIn("%files", content)

    def test_package_version_migrates_legacy_state_and_increments(self):
        project = self.root / "project"
        data = project / ".theos"
        legacy = project / ".debmake"
        legacy.mkdir(parents=True)
        first = self.helper("package-version", str(project), str(data), "com.example.test", "1.0")
        self.assertEqual(first.returncode, 0, first.stderr.decode())
        self.assertEqual(first.stdout.decode().strip(), "1")
        second = self.helper("package-version", str(project), str(data), "com.example.test", "1.0")
        self.assertEqual(second.returncode, 0, second.stderr.decode())
        self.assertEqual(second.stdout.decode().strip(), "2")
        self.assertFalse(legacy.exists())
        state = data / "packages" / "com.example.test-1.0"
        self.assertEqual(state.read_text(), "2")
        state.write_text("release-2+debug")
        third = self.helper("package-version", str(project), str(data), "com.example.test", "1.0")
        self.assertEqual(third.returncode, 0, third.stderr.decode())
        self.assertEqual(third.stdout.decode().strip(), "3")
        self.assertEqual(state.read_text(), "3")

    def test_sdk_info_rejects_incomplete_sdk_layout(self):
        sdk = self.root / "iPhoneOS17.2.sdk"
        sdk.mkdir()
        result = self.helper("sdk-info", str(sdk))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(b"usr/include and usr/lib", result.stderr)

    def test_sdk_versions_sort_numerically(self):
        result = self.helper("sort-versions", "9.3", "17.2", "16.4", "17.10", "17.9")
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertEqual(result.stdout.decode().strip(), "9.3 16.4 17.2 17.9 17.10")
        invalid = self.helper("sort-versions", "latest", "17.2")
        self.assertNotEqual(invalid.returncode, 0)

    def test_macho_validation_accepts_fat_arm64_and_rejects_other_fat(self):
        fat = self.root / "universal.dylib"
        header = b"\xca\xfe\xba\xbe" + (2).to_bytes(4, "big")
        arm64 = (0x0100000C).to_bytes(4, "big") + (0).to_bytes(4, "big") + b"\0" * 12
        x86 = (0x01000007).to_bytes(4, "big") + (3).to_bytes(4, "big") + b"\0" * 12
        fat.write_bytes(header + arm64 + x86)
        self.assertEqual(self.helper("macho-check", str(fat), "--arch", "arm64").returncode, 0)
        only_x86 = self.root / "x86.dylib"
        only_x86.write_bytes(header[:4] + (1).to_bytes(4, "big") + x86)
        self.assertNotEqual(self.helper("macho-check", str(only_x86), "--arch", "arm64").returncode, 0)

    def test_macho_validation_rejects_pe_and_accepts_arm64_header(self):
        macho = self.root / "demo.dylib"
        header = b"\xcf\xfa\xed\xfe" + (0x0100000C).to_bytes(4, "little") + (0).to_bytes(4, "little") + b"\0" * 52
        macho.write_bytes(header)
        result = self.helper("macho-check", str(macho), "--arch", "arm64")
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout.strip(), b"arm64")
        pe = self.root / "demo.exe"
        pe.write_bytes(b"MZ" + b"\0" * 64)
        self.assertNotEqual(self.helper("macho-check", str(pe)).returncode, 0)

    def test_which_and_tool_version(self):
        result = self.helper("which", sys.executable)
        self.assertEqual(result.returncode, 0)
        self.assertTrue(Path(result.stdout.decode().strip()).exists())
        version = self.helper("tool-version", sys.executable, "--version")
        self.assertEqual(version.returncode, 0)
        self.assertIn("Python", version.stdout.decode())

    def test_archive_extraction(self):
        archive = self.root / "archive with spaces.zip"
        with zipfile.ZipFile(archive, "w") as bundle:
            bundle.writestr("payload/data.txt", "archive data")
        destination = self.root / "extracted tree"
        result = self.helper("extract", str(archive), str(destination))
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertEqual((destination / "payload" / "data.txt").read_text(encoding="utf-8"), "archive data")

    def test_subproject_runner_preserves_directory_and_stops_on_error(self):
        subdir = self.root / "Sub Project"
        self.helper("mkdir", str(subdir))
        log = self.root / "make args.txt"
        fake_make = self.root / "fake make.cmd"
        fake_script = self.root / "fake_make_impl.py"
        fake_script.write_text(f"import pathlib,sys; pathlib.Path({str(log)!r}).write_text('\\n'.join(sys.argv[1:])); raise SystemExit(19)\n", encoding="utf-8")
        fake_make.write_text(f'@"{sys.executable}" "{fake_script}" %*\n', encoding="ascii")
        result = self.helper("subprojects", "--make", str(fake_make), "--makefile", "Makefile", "--operation", "all", "--build-dir", str(self.root / "build dir"), "--no-keep-going", "--subprojects", "Sub Project:ignored")
        self.assertEqual(result.returncode, 19)
        arguments = log.read_text(encoding="utf-8").splitlines()
        self.assertIn("Sub Project", arguments)
        self.assertIn("--no-keep-going", arguments)
        self.assertIn(f"THEOS_BUILD_DIR={self.root / 'build dir' / 'Sub Project'}", arguments)

    def test_sign_tree_finds_bundle_and_dylib_with_spaces(self):
        root = self.root / "install root"
        app = root / "Demo.app"
        dylib = root / "Sub" / "Tweak.dylib"
        self.helper("mkdir", str(app), str(dylib.parent))
        (app / "Info.plist").write_bytes(__import__("plistlib").dumps({"CFBundleExecutable": "Demo"}))
        (app / "Demo").write_bytes(b"binary")
        dylib.write_bytes(b"binary")
        log = self.root / "signed paths.txt"
        signer = self.root / "signer.py"
        signer.write_text(f"import pathlib,sys; pathlib.Path({str(log)!r}).open('a').write(sys.argv[-1]+'\\n')\n", encoding="utf-8")
        result = self.helper("sign-tree", str(root), sys.executable, str(signer))
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        signed = set(log.read_text(encoding="utf-8").splitlines())
        self.assertEqual(signed, {str(app / "Demo"), str(dylib)})

    def test_tar_xz_extraction_and_path_traversal_rejection(self):
        archive = self.root / "llvm-portable.tar.xz"
        payload = b"clang placeholder"
        with tarfile.open(archive, "w:xz") as bundle:
            info = tarfile.TarInfo("llvm/bin/clang.exe")
            info.size = len(payload)
            bundle.addfile(info, io.BytesIO(payload))
        destination = self.root / "portable tools"
        result = self.helper("extract", str(archive), str(destination))
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertEqual((destination / "llvm" / "bin" / "clang.exe").read_bytes(), payload)

        malicious = self.root / "malicious.tar.xz"
        with tarfile.open(malicious, "w:xz") as bundle:
            info = tarfile.TarInfo("../escaped.txt")
            info.size = 1
            bundle.addfile(info, io.BytesIO(b"x"))
        rejected = self.helper("extract", str(malicious), str(destination))
        self.assertNotEqual(rejected.returncode, 0)
        self.assertFalse((self.root / "escaped.txt").exists())

    def test_target_args_preserve_positions(self):
        result = self.helper("target-args", "iphone::15.0")
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout.decode().splitlines(), ["export __THEOS_TARGET_ARG_0 := iphone;", "export __THEOS_TARGET_ARG_2 := 15.0;"])

    def test_missing_file_and_process_failure_propagate(self):
        missing = self.helper("check-files", str(self.root / "does-not-exist.c"))
        self.assertNotEqual(missing.returncode, 0)
        failure = self.helper("run", sys.executable, "-c", "raise SystemExit(17)")
        self.assertEqual(failure.returncode, 17)

    def test_logos_adapter_propagates_perl_exit_and_writes_output(self):
        source = self.root / "Tweak.xm"
        source.write_text("int generated_value = 7;\\n", encoding="utf-8")
        output = self.root / "Tweak.mm"
        script = self.root / "fake logos.py"
        script.write_text("import sys; print(open(sys.argv[-1], encoding='utf-8').read(), end='')\n", encoding="utf-8")
        result = self.helper("logos", "--perl", sys.executable, "--script", str(script), "--output", str(output), str(source))
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertIn("generated_value", output.read_text(encoding="utf-8"))

    @unittest.skipUnless(shutil.which("perl") and LOGOS.exists(), "native Perl and vendored Logos are required")
    def test_real_logos_preprocessing(self):
        source = self.root / "Tweak.xm"
        source.write_text("%hook NSObject\n- (id)init { return %orig; }\n%end\n", encoding="utf-8")
        output = self.root / "Tweak.mm"
        result = self.helper("logos", "--perl", "perl", "--script", str(LOGOS), "--output", str(output), str(source))
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        generated = output.read_text(encoding="utf-8")
        self.assertIn("_logos", generated)
        self.assertIn("MSHookMessageEx", generated)

    def test_scheme_stage_preserves_debian_and_moves_payload(self):
        stage = self.root / "stage tree"
        staging_tmp = self.root / "stage tmp"
        scheme = staging_tmp / "var" / "jb"
        self.helper("mkdir", str(stage / "DEBIAN"), str(stage / "usr"), str(scheme))
        (stage / "DEBIAN" / "control").write_text("Package: demo\n", encoding="utf-8")
        (stage / "usr" / "demo.dylib").write_bytes(b"mach-o placeholder")
        result = self.helper("scheme-stage", str(stage), str(scheme), str(staging_tmp))
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertTrue((stage / "DEBIAN" / "control").exists())
        self.assertTrue((stage / "var" / "jb" / "usr" / "demo.dylib").exists())
        self.assertFalse((scheme / "usr").exists())

    def test_codesign_normalizes_mixed_separator_target_path(self):
        # ldid derives its temporary file from the raw path string, so a target that
        # mixes "\" and "/" previously produced an unopenable ".ldid." path.
        signer_dir = Path(tempfile.gettempdir()) / f"theos-codesign-{os.getpid()}"
        if signer_dir.exists():
            shutil.rmtree(signer_dir)
        signer_dir.mkdir(parents=True)
        self.addCleanup(lambda: shutil.rmtree(signer_dir, ignore_errors=True))
        log = signer_dir / "signed.txt"
        signer = signer_dir / "signer.py"
        signer.write_text(
            "import pathlib, sys\n"
            f"pathlib.Path({str(log)!r}).write_text(sys.argv[-1], encoding='utf-8')\n"
            "raise SystemExit(0)\n",
            encoding="utf-8",
        )
        target = self.root / "mixed" / "obj"
        self.helper("mkdir", str(target))
        binary = target / "Probe.dylib.unsigned"
        binary.write_bytes(b"\xcf\xfa\xed\xfe" + b"\0" * 28)
        mixed = str(binary).replace("\\", "/", 1) if "\\" in str(binary) else f"{binary.parent}/{binary.name}"
        mixed = str(binary.parent) + "/" + binary.name
        result = self.helper("codesign", "--signer", sys.executable, "--flags", str(signer), mixed)
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        handed = log.read_text(encoding="utf-8")
        self.assertNotIn("/", handed)
        self.assertEqual(Path(handed), binary)
        self.assertTrue(Path(handed).is_file())

    def test_codesign_reports_missing_target(self):
        signer = self.root / "unused-signer.py"
        signer.write_text("raise SystemExit(0)\n", encoding="utf-8")
        result = self.helper("codesign", "--signer", sys.executable, "--flags", str(signer), str(self.root / "absent.dylib"))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(b"does not exist", result.stderr)

    def test_fakeroot_state_lifecycle_and_command_execution(self):
        state = self.root / "fakeroot state" / "fakeroot"
        manifest = state.with_name(state.name + ".json")
        started = self.helper("fakeroot", "--persistence", str(state))
        self.assertEqual(started.returncode, 0, started.stderr.decode())
        self.assertTrue(state.is_file())
        missing_backend = self.helper("fakeroot", "--persistence", str(state), "--required", sys.executable, "-c", "raise SystemExit(21)")
        self.assertEqual(missing_backend.returncode, 21)
        manifest.write_text("{}\n", encoding="utf-8")
        cleared = self.helper("fakeroot", "--persistence", str(state), "-c")
        self.assertEqual(cleared.returncode, 0, cleared.stderr.decode())
        self.assertFalse(state.exists())
        self.assertFalse(manifest.exists())

    def test_deb_records_root_metadata_and_is_deterministic(self):
        stage = self.root / "metadata stage"
        self.helper("mkdir", str(stage / "DEBIAN"), str(stage / "usr" / "lib"), str(stage / "usr" / "share" / "empty"))
        (stage / "DEBIAN" / "control").write_text(
            "Package: com.example.metadata\nName: Metadata Probe\nVersion: 1.0\nArchitecture: iphoneos-arm64\nDescription: probe\n",
            encoding="utf-8",
        )
        (stage / "DEBIAN" / "postinst").write_text("#!/bin/sh\nexit 0\n", encoding="utf-8")
        # MH_MAGIC_64 + arm64 + MH_DYLIB so the packager marks the binary executable.
        dylib_header = b"\xcf\xfa\xed\xfe" + (0x0100000C).to_bytes(4, "little") + (0).to_bytes(4, "little") + (6).to_bytes(4, "little")
        (stage / "usr" / "lib" / "demo.dylib").write_bytes(dylib_header + b"\0" * 32)
        (stage / "usr" / "share" / "data.txt").write_text("payload\n", encoding="utf-8")

        state = self.root / "fakeroot state" / "fakeroot"
        recorded = self.helper("fakeroot", "--persistence", str(state), "--record-stage", str(stage))
        self.assertEqual(recorded.returncode, 0, recorded.stderr.decode())
        manifest_path = state.with_name(state.name + ".json")
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        self.assertEqual(manifest["paths"]["usr/lib/demo.dylib"]["mode"], 0o755)
        self.assertEqual(manifest["paths"]["usr/share/data.txt"]["mode"], 0o644)
        self.assertEqual(manifest["paths"]["DEBIAN/postinst"]["mode"], 0o755)
        self.assertEqual(manifest["paths"]["DEBIAN/control"]["mode"], 0o644)
        self.assertEqual(manifest["paths"]["usr/share/empty"]["type"], "dir")

        first = self.root / "packages" / "first.deb"
        second = self.root / "packages" / "second.deb"
        for output in (first, second):
            built = self.helper("deb", str(stage), str(output), "--manifest", str(manifest_path))
            self.assertEqual(built.returncode, 0, built.stderr.decode())
        self.assertEqual(first.read_bytes(), second.read_bytes(), "package output must be deterministic")

        members = read_ar(first.read_bytes())
        with tarfile.open(fileobj=io.BytesIO(members["control.tar.gz"]), mode="r:gz") as control:
            self.assertEqual(control.getmember("control").mode & 0o777, 0o644)
            self.assertEqual(control.getmember("postinst").mode & 0o777, 0o755)
            for member in control.getmembers():
                self.assertEqual((member.uid, member.gid), (0, 0))
                self.assertTrue(member.uname in ("root", "") and member.gname in ("wheel", "root", ""))
        with tarfile.open(fileobj=io.BytesIO(members["data.tar.gz"]), mode="r:gz") as data:
            names = data.getnames()
            self.assertIn("usr/lib/demo.dylib", names)
            self.assertNotIn("DEBIAN/control", names)
            self.assertEqual(data.getmember("usr/lib/demo.dylib").mode & 0o777, 0o755)
            self.assertEqual(data.getmember("usr/share/data.txt").mode & 0o777, 0o644)
            empty = data.getmember("usr/share/empty")
            self.assertTrue(empty.isdir())
            self.assertEqual(empty.mode & 0o777, 0o755)
            for member in data.getmembers():
                self.assertEqual((member.uid, member.gid), (0, 0))
                self.assertNotIn("..", member.name.split("/"))
        inspected = self.helper("deb-info", str(first))
        self.assertEqual(inspected.returncode, 0, inspected.stderr.decode())

        control_dir = self.root / "unpacked control"
        data_dir = self.root / "unpacked data"
        extracted = self.helper("deb-extract", str(first), "--control", str(control_dir), "--data", str(data_dir))
        self.assertEqual(extracted.returncode, 0, extracted.stderr.decode())
        self.assertTrue((control_dir / "control").is_file())
        self.assertTrue((control_dir / "postinst").is_file())
        self.assertEqual((data_dir / "usr" / "share" / "data.txt").read_text(encoding="utf-8"), "payload\n")
        self.assertTrue((data_dir / "usr" / "lib" / "demo.dylib").is_file())

    def test_deb_manifest_overrides_default_mode(self):
        stage = self.root / "override stage"
        self.helper("mkdir", str(stage / "DEBIAN"), str(stage / "usr" / "bin"))
        (stage / "DEBIAN" / "control").write_text("Package: demo\nVersion: 1.0\nArchitecture: iphoneos-arm64\n", encoding="utf-8")
        (stage / "usr" / "bin" / "tool").write_bytes(b"#!/bin/sh\n")
        manifest_path = self.root / "override manifest.json"
        manifest_path.write_text(json.dumps({"paths": {"usr/bin/tool": {"mode": 0o700}}}), encoding="utf-8")
        output = self.root / "override.deb"
        built = self.helper("deb", str(stage), str(output), "--manifest", str(manifest_path))
        self.assertEqual(built.returncode, 0, built.stderr.decode())
        with tarfile.open(fileobj=io.BytesIO(read_ar(output.read_bytes())["data.tar.gz"]), mode="r:gz") as data:
            self.assertEqual(data.getmember("usr/bin/tool").mode & 0o777, 0o700)
        non_executable = self.root / "plain.deb"
        self.assertEqual(self.helper("deb", str(stage), str(non_executable)).returncode, 0)
        with tarfile.open(fileobj=io.BytesIO(read_ar(non_executable.read_bytes())["data.tar.gz"]), mode="r:gz") as data:
            self.assertEqual(data.getmember("usr/bin/tool").mode & 0o777, 0o644)

    def test_macho_check_requires_code_signature_load_command(self):
        def header(ncmds, sizeofcmds):
            return (
                b"\xcf\xfa\xed\xfe"
                + (0x0100000C).to_bytes(4, "little")  # CPU_TYPE_ARM64
                + (0).to_bytes(4, "little")
                + (6).to_bytes(4, "little")  # MH_DYLIB
                + (ncmds).to_bytes(4, "little")
                + (sizeofcmds).to_bytes(4, "little")
                + (0).to_bytes(4, "little")
                + (0).to_bytes(4, "little")
            )

        signed = self.root / "signed image.dylib"
        signed.write_bytes(header(1, 16) + (0x1D).to_bytes(4, "little") + (16).to_bytes(4, "little") + (0).to_bytes(8, "little"))
        unsigned = self.root / "unsigned image.dylib"
        unsigned.write_bytes(header(0, 0))

        plain = self.helper("macho-check", str(signed), "--arch", "arm64")
        self.assertEqual(plain.returncode, 0, plain.stderr.decode())
        required = self.helper("macho-check", str(signed), "--arch", "arm64", "--require-signature")
        self.assertEqual(required.returncode, 0, required.stderr.decode())
        self.assertIn(b"LC_CODE_SIGNATURE", required.stdout)
        missing = self.helper("macho-check", str(unsigned), "--arch", "arm64", "--require-signature")
        self.assertNotEqual(missing.returncode, 0, "unsigned image must not report a code signature")
        self.assertIn(b"LC_CODE_SIGNATURE", missing.stderr)

    def test_control_and_data_tars_are_gzip_debian_members(self):
        stage = self.root / "gzip stage"
        self.helper("mkdir", str(stage / "DEBIAN"), str(stage / "Library" / "DynamicLibraries"))
        (stage / "DEBIAN" / "control").write_text(
            "Package: demo\nVersion: 1.0\nArchitecture: iphoneos-arm64\n", encoding="utf-8"
        )
        (stage / "Library" / "DynamicLibraries" / "Demo.dylib").write_bytes(
            b"\xcf\xfa\xed\xfe" + (0x0100000C).to_bytes(4, "little") + (0).to_bytes(4, "little") + (6).to_bytes(4, "little") + b"\0" * 28
        )
        output = self.root / "gzip members.deb"
        built = self.helper("deb", str(stage), str(output))
        self.assertEqual(built.returncode, 0, built.stderr.decode())
        members = read_ar(output.read_bytes())
        self.assertEqual(sorted(members), ["control.tar.gz", "data.tar.gz", "debian-binary"])
        self.assertEqual(members["debian-binary"], b"2.0\n")
        for name in ("control.tar.gz", "data.tar.gz"):
            blob = members[name]
            self.assertTrue(blob.startswith(b"\x1f\x8b"), f"{name} is not gzip")
            self.assertEqual(blob[4:8], b"\0\0\0\0", f"{name} must not embed a timestamp")
        with tarfile.open(fileobj=io.BytesIO(members["control.tar.gz"]), mode="r:gz") as control:
            self.assertIn("control", control.getnames())
        with tarfile.open(fileobj=io.BytesIO(members["data.tar.gz"]), mode="r:gz") as data:
            names = data.getnames()
            self.assertIn("Library/DynamicLibraries/Demo.dylib", names)
            self.assertNotIn("DEBIAN/control", names)

    def test_package_uses_root_wheel_ownership_and_executable_dylib(self):
        stage = self.root / "ownership stage"
        self.helper("mkdir", str(stage / "DEBIAN"), str(stage / "Library" / "MobileSubstrate" / "DynamicLibraries"))
        (stage / "DEBIAN" / "control").write_text(
            "Package: demo\nVersion: 1.0\nArchitecture: iphoneos-arm64\n", encoding="utf-8"
        )
        payload = stage / "Library" / "MobileSubstrate" / "DynamicLibraries"
        (payload / "Demo.dylib").write_bytes(
            b"\xcf\xfa\xed\xfe" + (0x0100000C).to_bytes(4, "little") + (0).to_bytes(4, "little") + (6).to_bytes(4, "little") + b"\0" * 28
        )
        (payload / "Demo.plist").write_text("{ Filter = { }; }\n", encoding="utf-8")
        output = self.root / "ownership.deb"
        self.assertEqual(self.helper("deb", str(stage), str(output)).returncode, 0)
        members = read_ar(output.read_bytes())
        with tarfile.open(fileobj=io.BytesIO(members["data.tar.gz"]), mode="r:gz") as data:
            for member in data.getmembers():
                self.assertEqual((member.uid, member.gid), (0, 0), member.name)
                self.assertEqual((member.uname, member.gname), ("root", "wheel"), member.name)
            self.assertEqual(data.getmember("Library").mode & 0o777, 0o755)
            self.assertTrue(data.getmember("Library/MobileSubstrate/DynamicLibraries").isdir())
            self.assertEqual(data.getmember("Library/MobileSubstrate/DynamicLibraries/Demo.dylib").mode & 0o777, 0o755)
            self.assertEqual(data.getmember("Library/MobileSubstrate/DynamicLibraries/Demo.plist").mode & 0o777, 0o644)
        with tarfile.open(fileobj=io.BytesIO(members["control.tar.gz"]), mode="r:gz") as control:
            entry = control.getmember("control")
            self.assertEqual((entry.uname, entry.gname), ("root", "wheel"))
            self.assertEqual(entry.mode & 0o777, 0o644)

    def test_modern_tbd_overlay_keeps_legacy_stubs(self):
        library = ROOT / "vendor" / "lib"
        self.assertEqual((library / "CydiaSubstrate.framework" / "CydiaSubstrate.tbd").read_text().splitlines()[0], "---")
        stubs = sorted((library / "tbd" / "modern").rglob("*.tbd"))
        self.assertGreater(len(stubs), 0)
        untagged = [
            str(stub.relative_to(ROOT))
            for stub in stubs
            if not stub.read_text(encoding="utf-8").splitlines()[0].strip().startswith("--- !tapi-tbd")
        ]
        self.assertEqual(untagged, [], f"TBD stubs without a linker-recognised tag: {untagged}")
        rootless = [stub for stub in stubs if "rootless" in stub.parts]
        self.assertGreater(len(rootless), 0, "rootless stubs must remain vendored")

    def test_rebuild_is_independent_of_fakeroot_state(self):
        stage = self.root / "rebuild stage"
        self.helper("mkdir", str(stage / "DEBIAN"), str(stage / "Library"))
        (stage / "DEBIAN" / "control").write_text(
            "Package: demo\nVersion: 1.0\nArchitecture: iphoneos-arm64\n", encoding="utf-8"
        )
        (stage / "Library" / "Demo.dylib").write_bytes(
            b"\xcf\xfa\xed\xfe" + (0x0100000C).to_bytes(4, "little") + (0).to_bytes(4, "little") + (6).to_bytes(4, "little") + b"\0" * 28
        )
        state = self.root / "fakeroot state" / "fakeroot"
        manifest = state.with_name(state.name + ".json")
        digests = []
        for index in range(2):
            if state.exists():
                cleared = self.helper("fakeroot", "--persistence", str(state), "-c")
                self.assertEqual(cleared.returncode, 0, cleared.stderr.decode())
            recorded = self.helper("fakeroot", "--persistence", str(state), "--record-stage", str(stage))
            self.assertEqual(recorded.returncode, 0, recorded.stderr.decode())
            output = self.root / f"rebuild{index}.deb"
            built = self.helper("deb", str(stage), str(output), "--manifest", str(manifest))
            self.assertEqual(built.returncode, 0, built.stderr.decode())
            digests.append(hashlib.sha256(output.read_bytes()).hexdigest())
        self.assertEqual(digests[0], digests[1], "a fresh rebuild must be byte-identical")

    def test_makefiles_route_signing_and_fakeroot_through_helper(self):
        # Guards the Windows wiring that made the native pipeline work: signer
        # dispatch through the helper, a native fakeroot backend, and a FAKEROOT
        # default that the platform file can still override.
        rules = (ROOT / "makefiles" / "instance" / "rules.mk").read_text(encoding="utf-8")
        self.assertIn("codesign --signer", rules)
        platform = (ROOT / "makefiles" / "platform" / "Windows.mk").read_text(encoding="utf-8")
        self.assertIn("fakeroot --persistence", platform)
        common = (ROOT / "makefiles" / "common.mk").read_text(encoding="utf-8")
        self.assertIn("ifeq ($(FAKEROOT),)", common)

    def test_sdk_info_reads_version_from_sdksettings_plist(self):
        sdk = self.root / "iPhoneOS.sdk"
        self.helper(
            "mkdir",
            str(sdk / "usr" / "include"),
            str(sdk / "usr" / "lib"),
            str(sdk / "System" / "Library" / "Frameworks"),
        )
        (sdk / "usr" / "lib" / "libSystem.tbd").write_text("--- !tapi-tbd\n", encoding="utf-8")
        for fmt, label in ((plistlib.FMT_XML, "xml"), (plistlib.FMT_BINARY, "binary")):
            with (sdk / "SDKSettings.plist").open("wb") as stream:
                plistlib.dump({"Version": "16.5", "CanonicalName": "iphoneos16.5"}, stream, fmt=fmt)
            result = self.helper("sdk-info", str(sdk), "--version-only")
            self.assertEqual(result.returncode, 0, f"{label}: {result.stderr.decode()}")
            self.assertEqual(result.stdout.strip(), b"16.5", label)

        # A versioned directory name needs no SDKSettings.plist at all.
        versioned = self.root / "iPhoneOS16.5.sdk"
        shutil.copytree(sdk, versioned)
        (versioned / "SDKSettings.plist").unlink()
        self.assertEqual(self.helper("sdk-info", str(versioned), "--version-only").stdout.strip(), b"16.5")

        # An unversioned SDK without SDKSettings.plist must fail loudly.
        (sdk / "SDKSettings.plist").unlink()
        missing = self.helper("sdk-info", str(sdk), "--version-only")
        self.assertNotEqual(missing.returncode, 0)
        self.assertIn(b"SDKSettings.plist", missing.stderr)

        # A layout that is not an SDK at all is rejected, not silently accepted.
        bogus = self.root / "iPhoneOS99.9.sdk"
        self.helper("mkdir", str(bogus))
        rejected = self.helper("sdk-info", str(bogus), "--version-only")
        self.assertNotEqual(rejected.returncode, 0)
        self.assertIn(b"expected usr/include and usr/lib", rejected.stderr)


def read_ar(raw):
    members, offset = {}, 8
    while offset < len(raw):
        size = int(raw[offset + 48:offset + 58].decode("ascii").strip())
        start = offset + 60
        members[raw[offset:offset + 16].decode("ascii").strip()] = raw[start:start + size]
        offset = start + size + (size % 2)
    return members


if __name__ == "__main__":
    unittest.main()
