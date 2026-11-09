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

## TBD compatibility proposal (revision after maintainer feedback)

Kirb explained that canonical TBD v1 files intentionally support older toolchains. The original in-place migration was rejected as-is. The revised library proposal at `5d8bf04b94f0c2f8fa675fa01729230c46229d47` restores every canonical file to upstream baseline `6f2af307568e6b8c52181d26314b0cd69ffaf188`; its net diff adds only `tbd/`. This layout is not yet approved by maintainers; both PRs remain drafts.

The optional `tbd/modern` linker-only overlay contains 39 stubs requiring both v3 and v4 capability. Twenty-nine v1 stubs gain explicit v3 tags in the overlay, while Cycript uses explicit v4 device/simulator targets. Existing v3/v4 stubs are included, and the two libsubstrate aliases are regular copies to work with Windows clones that disable symlinks. Canonical headers, modules and binary archives stay in their original paths.

The Windows iPhone consumer probes the per-instance `TARGET_LD` (including clang++ selection) for v1/v3/v4 support using SDK-independent ARM64 links. This implementation is intentionally limited to the configured clang/LLD path, rejects custom linker-selection flags, and does not claim support for arbitrary Windows legacy linkers. The probe runs only during instance compile, excluding static subprojects; compile dry-runs still run probes. A v1-capable configured driver retains canonical paths, while a modern-only driver must pass both v3/v4 probes and overlay completeness checks. The link-only overlay is inserted immediately before the canonical vendor slot, after private framework paths; compilation and POSIX search paths remain unchanged. A legacy Windows checkout with nonfunctional text aliases fails with a symlink configuration diagnostic.

Local revised-prototype evidence: 51 tests passed without skips; real rootful/rootless signed package verification passed with the external user SDK; Objective-C++ rootful/rootless package builds passed; both `-lsubstrate` and `-framework CydiaSubstrate` linked with correct scheme-specific install names. A separate local library clone with `core.symlinks=false` selected modern for both schemes and remained clean. All 39 overlay stubs retain the compared install names and symbol sets; this is not a full ABI or all-architecture compatibility proof. Old Apple/cctools linkers, all Cycript architecture/platform combinations, revised public recursive clone and revised hosted CI are not yet verified.

## Historical test results (before compatibility revision)

The results below establish the earlier Windows implementation only; they do not validate the revised overlay or selector.

## Test results

- Windows helper/unit suite: 39 tests passed locally.
- Windows SDK E2E: rootful and rootless packages built and independently checked locally against a user-supplied SDK. Local clean-clone run: rootful SHA-256 `1ab458085c2b68f92f7f182ce46d66facb3aa17d07355dd15b542d8e30017ea8` (2240 bytes); rootless SHA-256 `5c64d64f4a127730bd1fa6ed459ceb7d82644fe8badafb1a7d86e00223e67d38` (2360 bytes). These are local artifacts, not CI artifacts.
- Windows hosted CI: [passed](https://github.com/Nokeew/theos/actions/runs/42369141292/job/128393439389), including 39 tests and SDK-independent ARM64 linker/signing probes.
- macOS hosted CI: [passed](https://github.com/Nokeew/theos/actions/runs/42369141280/job/128393439685), including native macOS tool build/run.
- Linux hosted CI: [passed](https://github.com/Nokeew/theos/actions/runs/42369141280/job/128393439527), including SDK gate and fakeroot/Debian smoke.
- These CI results correspond to commit `ae5db203a9479f2b597dca850de7f375347930bb`.
- Protected-runner SDK E2E jobs: skipped; not executed.
- Public recursive clone of `Nokeew/theos:windows-port-rc`: passed at `e24f0527c8a74a6106b770c4f98266fa36c5ae26`, checking out exact `vendor/lib` commit `300f9e005d2b358ad7da1cb5d96f2cfb7c98ec9a` with a clean checkout.

The hosted POSIX workflow requires no external iPhoneOS SDK: Linux checks the missing-SDK gate and native fakeroot/Debian smoke, while macOS builds/runs a native tool using the runner's installed Xcode macOS SDK. These jobs must not be described as proof of iOS linking/signing on macOS/Linux. Protected opt-in jobs are configured for four target graphs and real rootful/rootless tweak packages; none has yet run. Attach successful real-runner results for any platform compatibility claim.

## SDK and artifacts

No Apple SDK is committed or redistributed. Public CI must not download, cache, upload, or publish SDK files. SDK-dependent tests are opt-in and require operator-controlled runners with a protected SDK path; Linux also requires a complete Theos iOS cross-toolchain in `SDKBINPATH`. Configure the `protected-sdk-e2e` GitHub environment with required reviewers and trusted branch restrictions before use, and do not dispatch untrusted commits. The workflow's branch check does not itself establish trust in code. Verify the applicable Apple agreement before making any SDK available to CI.

## Limitations

- The Windows end-to-end scope is currently a tweak package; other target types and device installation are not verified.
- Rootful/rootless iOS package builds on macOS and Linux remain unverified until real SDK-capable runs are performed.
- Hosted Actions passed, but SDK-dependent CI coverage remains unexecuted.
- The original library commit is public in the fork but was rejected as-is; the replacement overlay commit is published in the fork for draft review. The RC submodule URL temporarily points to `Nokeew/lib`; restore `theos/lib` only after an agreed replacement commit is available upstream.

## Publication order

1. Publish revised `vendor/lib` commit `5d8bf04b94f0c2f8fa675fa01729230c46229d47` to the fork RC branch (done); do not restore the upstream URL before an agreed commit is available there.
2. Confirm a fresh public recursive clone checks out that exact commit.
3. Publish the main RC branch and collect Windows/macOS/Linux workflow URLs.
4. Submit the main PR only after the required platform results are attached and the repository owner approves publication.
