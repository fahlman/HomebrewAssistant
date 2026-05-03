# Security Policy

Homebrew Assistant is a safety-focused macOS utility that prepares removable SD cards for selected Wii homebrew workflows. Security issues may involve recipe trust, payload source validation, removable-storage safety, macOS permission handling, staging, archive extraction, checksum/signature verification, or signed recipe-index behavior.

## Supported Versions

Homebrew Assistant is in early development. Until the first public release, security reports should target the current `main` branch unless a release branch is explicitly documented.

After public releases begin, supported versions will be documented here.

## Reporting a Vulnerability

Please do not disclose security vulnerabilities publicly before they have been reviewed.

Report suspected vulnerabilities by opening a private security advisory if GitHub Security Advisories are enabled for this repository. If advisories are not enabled, contact the project maintainer privately through the communication channel listed in the repository profile or project documentation.

When reporting, include as much detail as practical:

- A summary of the issue
- Steps to reproduce
- Affected files, features, or workflow steps
- Expected behavior
- Actual behavior
- Impact or possible exploit path
- Any proof-of-concept files or URLs, if safe to share privately
- macOS version and Homebrew Assistant version or commit

Please avoid including private signing keys, personal secrets, private user data, or unrelated sensitive files in reports.

## Security-Sensitive Areas

The following areas are especially important:

- User-selected SD card volume validation and rejection of non-Secure Digital media
- Full Disk Access detection and fail-safe permission handling
- Recipe source validation
- Payload source validation
- Signed recipe-index verification
- Ed25519 public key and key identifier handling
- Private recipe-signing key handling
- SHA-256 checksum verification
- Archive extraction safety, including Zip Slip prevention
- Path traversal, absolute path, symlink, hard-link, and outside-destination rejection
- Temporary staging boundaries and cleanup
- Final SD card write and post-copy verification
- Eject behavior
- Diagnostic logging and privacy

## Out of Scope

The following are generally out of scope unless they lead to a concrete Homebrew Assistant vulnerability:

- Vulnerabilities in third-party homebrew projects themselves
- Issues requiring physical access to an unlocked Mac and full user control without bypassing any Homebrew Assistant trust checks
- Reports that depend on intentionally modifying the app source and rebuilding it as a different app
- Social engineering attacks unrelated to Homebrew Assistant behavior
- macOS vulnerabilities that do not involve Homebrew Assistant-specific handling

## Core Security Expectations

Homebrew Assistant must fail safe when trust, disk identity, permission state, recipe metadata, payload source, checksum, signature, archive contents, or write results are ambiguous.

Homebrew Assistant must never:

- Format, erase, repartition, repair, or destructively modify disks.
- Modify internal disks.
- Execute arbitrary recipe scripts.
- Trust user-selected local recipes, drag-and-drop recipes, manually entered URLs, forks, mirrors, rehosts, or loose cached recipe files.
- Write recipe files directly to the SD card during individual recipe steps.
- Write outside app-controlled staging directories or the user-approved, validated SD card volume.
- Automatically eject the SD card.
- Mutate macOS TCC.db or any macOS permission database.
- Store, log, bundle, or commit private recipe-signing keys.

## Recipe and Payload Trust

Recipes are declarative app-defined instructions, not executable scripts.

Version 1 uses bundled recipe definitions only. Future dynamic recipes must be trusted only through the official Homebrew Assistant Recipes repository and a verified signed Ed25519 recipe index.

Dynamic recipe files are trusted only when:

1. The signed index verifies.
2. The recipe is listed in the verified index.
3. The recipe bytes match the SHA-256 checksum in the verified index.
4. The recipe schema is supported.
5. SourcePolicy approves the recipe source and payload source.

Loose cached recipes, unsigned indexes, invalid signatures, mismatched checksums, alternate repositories, forks, mirrors, and user-selected recipe files must be rejected.

Wilbrand and HackMii are app-owned internal/bootstrap workflows. Homebrew Assistant Recipes updates must never add, replace, override, or modify them.

## Signing Keys

The public Ed25519 verification key and key identifier may be committed and compiled into Homebrew Assistant.

The private signing key must never be:

- Committed to Git
- Bundled with Homebrew Assistant
- Logged
- Stored in the app repository
- Stored in `AppConstants.swift`
- Included in public test fixtures

If a private signing key is suspected to be compromised, dynamic recipe trust must be considered compromised until the app rotates to a new public key and revokes trust in the compromised key.

## App Sandbox

Homebrew Assistant should remain sandbox-friendly even if the App Sandbox is not required during early development.

Future versions may adopt the macOS App Sandbox as a hardening measure for direct distribution, even if Mac App Store distribution is not a primary goal. The purpose of sandboxing is to limit filesystem access and help prevent accidental or malicious writes outside app-controlled directories and the user-approved, validated SD card volume.

Sandboxing must not be enabled casually. Before adoption, it must be tested against Homebrew Assistant’s required behavior:

- Disk Arbitration metadata access for a user-selected mounted volume
- Secure Digital validation after the user selects a mounted volume
- Full Disk Access detection
- Wilbrand archive selection through a controlled file picker
- Temporary staging directories
- Final writes to the user-approved, validated SD card volume
- Post-copy verification
- User-initiated eject/unmount behavior
- Opening System Settings, Disk Utility, and approved browser URLs

The app should be designed so sandbox adoption remains practical:

- Keep staging inside app-controlled temporary or application-support directories.
- Use controlled file pickers for user-selected files.
- Use a sandbox-compatible user selection flow for the intended SD card volume, then validate that exact selected volume with Disk Arbitration before enabling writes.
- Avoid arbitrary path input.
- Avoid shell commands where native APIs are available and reliable.
- Route SD card writes through `SDWriteService.swift`.
- Keep filesystem access centralized and auditable.

If sandboxing prevents required safety checks or verified SD card writes, the app must not weaken those checks to satisfy sandbox constraints. The correct response is to redesign the access flow, use appropriate macOS security-scoped access where safe, or defer sandbox adoption. The preferred sandbox-compatible SD flow is: the user selects the intended mounted SD card volume once through a system access flow, Homebrew Assistant validates that exact selected volume using Disk Arbitration, and writes are enabled only when the selected volume is confirmed as Secure Digital and writable.

## Disk Safety

A selected SD-card volume must be accepted only when native macOS Disk Arbitration metadata for that exact selected mounted volume reports the protocol name exactly as:

```text
Secure Digital
```

Removable, ejectable, external, or writable traits may support diagnostics but are not sufficient by themselves.

The preferred selection model is user selection followed by app validation: the user identifies the intended mounted SD card volume through a sandbox-compatible access flow, and Homebrew Assistant confirms that the selected volume is eligible before enabling progression or writes. The app must not trust a volume merely because the user selected it.

Homebrew Assistant must never perform destructive disk operations. Disk Utility is the appropriate tool for formatting, erasing, repartitioning, or repairing disks.

## Archive Extraction and Zip Slip

Homebrew Assistant downloads and extracts archive files, so archive extraction must treat every archive as potentially hostile until validated.

`ArchiveExtractor.swift` must prevent Zip Slip and related archive traversal attacks. Every extracted file’s final resolved destination must remain inside the intended session staging directory.

Archive extraction must reject entries that include or resolve to:

- `..` path traversal
- Absolute paths
- Symlinks
- Hard links
- Paths that normalize outside the extraction destination
- Unsafe or ambiguous path components
- Malformed archive entries that cannot be safely classified

Sandboxing is defense in depth, not the primary Zip Slip defense. Archive validation and path containment checks must still be enforced before writing extracted files.

## Full Disk Access

Full Disk Access detection uses the proven read-only sqlite3/TCC.db approach described in the project documentation.

Homebrew Assistant must never write to, modify, reset, repair, or otherwise change TCC.db. If Full Disk Access status is unavailable, inconclusive, blocked, or contradictory, the app must fail safe and block progression until access is verified by the approved non-mutating strategy or a deliberately adopted replacement proven during implementation.

## Disclosure and Fix Process

Security reports will be reviewed as quickly as practical. Confirmed issues will be prioritized according to impact, exploitability, and risk to user data, removable media, recipe trust, or signing infrastructure.

Fixes should include tests or documented verification steps when possible.

Public disclosure should wait until a fix or mitigation is available, unless the issue is already public or active exploitation requires a different response.
