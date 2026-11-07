# Native Windows Theos Port: Pull Request Brief

## Summary

Add native Windows support for Theos' iOS tweak-to-Debian-package workflow. Existing project Makefiles remain in use; Windows-specific operations route through `bin/theos-windows.py` and `makefiles/platform/Windows.mk`.

For the verified tweak workflow, Windows builds do not require WSL or Bash and do not disable signing or fakeroot metadata handling.

## Architecture

On Windows, the platform makefile selects helper-backed operations for paths, filesystem commands, Logos preprocessing, SDK/Mach-O checks, staging, signing orchestration, and Debian package creation. The helper uses native Python and subprocess APIs. A real Windows-compatible `ldid` signs the ARM64 Mach-O dylib. The fakeroot backend records requested ownership/mode metadata in a manifest; the native package builder applies it to the `control.tar.gz` and `data.tar.gz` members. POSIX command recipes remain in their non-Windows branches.

## Changed files

- Makefile platform and target plumbing: 24 `makefiles/*.mk` files.
- Windows helper and PowerShell setup/probe scripts under `bin/`.
- Windows helper tests, tweak fixture and independent `.deb` verifier under `tests/windows/`.
- Windows and POSIX host workflows under `.github/workflows/` and POSIX CI smoke scripts under `tests/posix/`.
- Windows installation, build, troubleshooting and progress documentation; README Windows status.
- `vendor/lib` gitlink to the TBD migration commit.

## TBD migration

`ld64.lld` treats legacy TBD v1 stubs beginning with an untagged `---` as an unknown file type. Twenty-nine stub files were migrated to TBD v3 using an explicit tag and otherwise preserving their `archs`/`platform` body. `Cycript.framework/Cycript.tbd` uses v4 `targets:` because its device and simulator architecture set cannot be represented compatibly by the v3 form. The two `libsubstrate.tbd` paths are symlink aliases and inherit the CydiaSubstrate fix.

## Test results to attach before merge

- Windows helper/unit suite: 39 tests passed locally.
- Windows SDK E2E: rootful and rootless packages built and independently checked locally against a user-supplied SDK. Local clean-clone run: rootful SHA-256 `1ab458085c2b68f92f7f182ce46d66facb3aa17d07355dd15b542d8e30017ea8` (2240 bytes); rootless SHA-256 `5c64d64f4a127730bd1fa6ed459ceb7d82644fe8badafb1a7d86e00223e67d38` (2360 bytes). These are local artifacts, not CI artifacts.
- Public Windows workflow URL: pending.
- Public macOS workflow URL: pending.
- Public Linux workflow URL: pending.
- Windows protected-runner SDK E2E URL: pending opt-in execution.

The hosted POSIX workflow requires no external iPhoneOS SDK: Linux checks the missing-SDK gate and native fakeroot/Debian smoke, while macOS builds/runs a native tool using the runner's installed Xcode macOS SDK. These jobs must not be described as proof of iOS linking/signing on macOS/Linux. Protected opt-in jobs are configured for four target graphs and real rootful/rootless tweak packages; none has yet run. Attach successful real-runner results for any platform compatibility claim.

## SDK and artifacts

No Apple SDK is committed or redistributed. Public CI must not download, cache, upload, or publish SDK files. SDK-dependent tests are opt-in and require operator-controlled runners with a protected SDK path; Linux also requires a complete Theos iOS cross-toolchain in `SDKBINPATH`. Configure the `protected-sdk-e2e` GitHub environment with required reviewers and trusted branch restrictions before use, and do not dispatch untrusted commits. The workflow's branch check does not itself establish trust in code. Verify the applicable Apple agreement before making any SDK available to CI.

## Limitations

- The Windows end-to-end scope is currently a tweak package; other target types and device installation are not verified.
- Rootful/rootless iOS package builds on macOS and Linux remain unverified until real SDK-capable runs are performed.
- Public Actions results for the RC branch remain pending.
- The `vendor/lib` commit must be published and fetchable before a public main-repository branch can use its gitlink.

## Publication order

1. Publish `vendor/lib` commit `300f9e005d2b358ad7da1cb5d96f2cfb7c98ec9a` to an approved remote/branch.
2. Confirm a fresh public recursive clone checks out that exact commit.
3. Publish the main RC branch and collect Windows/macOS/Linux workflow URLs.
4. Submit the main PR only after the required platform results are attached and the repository owner approves publication.
