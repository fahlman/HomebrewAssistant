# Recipe Trust Model

Homebrew Assistant treats recipes, downloaded payloads, archives, and selected filesystem locations as security-sensitive inputs. The app must never trust a recipe, payload, archive, or selected destination merely because it exists on disk, was downloaded successfully, was chosen by the user, or appears to come from a familiar website.

This document defines how recipe definitions, recipe updates, and third-party payload downloads are trusted.

## Core Rule

Homebrew Assistant trusts only approved recipe metadata and approved payload sources.

```text
Trusted recipe metadata
        ↓
SourcePolicy approval
        ↓
Download into staging
        ↓
Checksum/signature verification
        ↓
Safe extraction into app-controlled staging
        ↓
Review Setup
        ↓
Final Write and Verify Files
```

Recipes are declarative app-defined instructions. They are not executable scripts and must never contain arbitrary code, shell commands, executable hooks, or disk-management operations.

Recipes describe intended staged outputs. They do not directly add, remove, or modify files. File writes are performed only by focused app services: `StagingManager.swift` for app-controlled staging and `SDWriteService.swift` for the final write to the user-approved, validated SD card volume.

## Version 1 Trust Model

Version 1 uses bundled recipe definitions only.

Allowed recipe sources in v1:

- Bundled app resources shipped with Homebrew Assistant.

Rejected recipe sources in v1:

- User-selected local recipe files
- Drag-and-drop recipe files
- Manually entered recipe URLs
- Alternative repositories
- Forks
- Mirrors
- Rehosted recipes
- Loose cached recipe files
- Recipes from arbitrary websites

Homebrew Assistant does not bundle third-party homebrew payloads. Payload files are downloaded from each trusted recipe’s declared approved upstream source and verified before extraction or staging.

## Public Recipes

Public recipes may describe only safe app-defined operations, such as:

- Download
- Verify checksum or metadata
- Extract
- Copy file or directory
- Create folder when supported by the app
- Show localized instructions

Public recipes must not:

- Execute scripts
- Run shell commands
- Include executable hooks
- Format, erase, repartition, repair, or otherwise manage disks
- Ask the user to drag files into the app
- Accept user-selected local payloads
- Declare browser-based exploit/bootstrap flows
- Modify app-owned internal/bootstrap workflows
- Write outside app-controlled staging or the user-approved, validated SD card volume

## Wilbrand and HackMii

Wilbrand and HackMii are app-owned internal/bootstrap workflows.

They are not public Homebrew Assistant Recipes recipes. They must remain controlled by bundled Homebrew Assistant app releases and must never be added, replaced, overridden, or modified by Homebrew Assistant Recipes updates.

Only the Homebrew Assistant app developer controls the approved URLs and behavior for these workflows.

Homebrew Assistant Recipes recipes must not:

- Provide Wilbrand or HackMii replacements
- Override Wilbrand or HackMii metadata
- Provide exploit/bootstrap URLs
- Declare `openBrowser` actions
- Request user-selected files
- Modify app-owned exploit/bootstrap workflow behavior

## SourcePolicy.swift

`SourcePolicy.swift` is the trust gatekeeper.

It owns:

- Recipe-source trust decisions
- Payload-source trust decisions
- Approval of bundled recipe sources
- Approval of future Homebrew Assistant Recipes repository sources through a verified signed index
- Official upstream host/repository checks
- Browser-only source handling
- Internal-only capability restrictions
- Wilbrand and HackMii restrictions
- Fail-safe source rejection
- Actionable rejection reasons

It does not own:

- Choosing official upstream sources at runtime
- Downloading files
- Parsing recipe plists
- Calculating checksums
- Extracting archives
- Navigating workflow steps
- Presenting recipe UI
- Signing recipe indexes
- Storing private signing keys

Human review determines which upstream source is official when a recipe is authored or reviewed. The trusted recipe records that decision. `SourcePolicy.swift` enforces the recorded decision.

## Payload Source Rules

A payload URL is allowed only when it matches the trusted recipe’s approved source metadata and `SourcePolicy.swift` approves it.

The app must reject payloads from:

- Unofficial mirrors
- Rehosted files
- Random GitHub forks
- Wrong repositories on otherwise trusted hosts
- Local file URLs
- Manually entered URLs
- User-selected payload archives
- Any source that cannot be confidently classified as approved


A broad host check is not enough. For example, `github.com` is not automatically trusted. The URL must match the approved repository, release page, or direct download pattern declared by the trusted recipe metadata.

## Archive Extraction and Zip Slip

Downloaded archives are not trusted merely because the payload URL and checksum are approved. Archive contents must still be validated before extraction.

`ArchiveExtractor.swift` must prevent Zip Slip and related path traversal attacks. Every extracted file’s final resolved destination must remain inside the intended app-controlled session staging directory.

Archive extraction must reject entries that include or resolve to:

- `..` path traversal
- Absolute paths
- Symlinks
- Hard links
- Paths that normalize outside the extraction destination
- Unsafe or ambiguous path components
- Malformed archive entries that cannot be safely classified

Sandboxing is defense in depth, not the primary archive-safety control. Archive validation and path containment checks must happen before writing extracted files.
## SD Card Destination Trust

The selected SD card volume is also a trust boundary.

The preferred sandbox-compatible model is user selection followed by app validation:

1. The user selects the intended mounted SD card volume once through a system access flow.
2. The app receives scoped access to that selected volume.
3. `DiskManager.swift` validates that exact selected mounted volume using Disk Arbitration metadata.
4. The workflow proceeds only when the selected volume is confirmed as Secure Digital and writable.
5. `SDWriteService.swift` writes only to that approved volume during Write and Verify Files.

The app must not trust a volume merely because the user selected it. Selection grants access; Disk Arbitration validation determines eligibility.

Recipes must never choose destinations directly. Recipe copy actions may describe intended relative paths within the approved SD card layout, but `SDWriteService.swift` owns final destination resolution, containment checks, copying, and verification.

## Future Dynamic Recipe Updates

Future Homebrew Assistant Recipes support should use a signed recipe index rather than trusting loose local recipe files.

The future dynamic recipe flow is:

```text
Contributor opens pull request in Homebrew Assistant Recipes
        ↓
Homebrew Assistant developer reviews and merges it
        ↓
Release process generates recipes.index.json
        ↓
Release process signs the exact index bytes with Ed25519 private key
        ↓
Homebrew Assistant.app downloads the index and signature
        ↓
App verifies the index using compiled-in Ed25519 public key
        ↓
App loads only listed recipes whose SHA-256 checksums match the index
```

Ordinary eligible recipe additions or updates should not require a Homebrew Assistant app update when the signed index validates.

App updates are required for:

- Trust-system changes
- Public key rotation
- Incompatible schema changes
- New recipe capabilities
- App-owned internal/bootstrap workflow changes such as Wilbrand or HackMii

## Signed Recipe Index

The signed index protects the recipe catalog.

`recipes.index.json` should list:

- Approved recipe IDs
- Recipe paths
- Expected SHA-256 checksums
- Recipe versions
- Supported schema versions
- Source metadata
- Revocation or deprecation metadata when needed

The index is signed with an Ed25519 private key held outside the app.

Homebrew Assistant.app ships with the matching public Ed25519 verification key compiled into the signed app.

The app may load a dynamic recipe only when:

1. The index signature verifies.
2. The recipe is listed in the verified index.
3. The recipe file matches the SHA-256 checksum in the verified index.
4. The recipe schema is supported.
5. `SourcePolicy.swift` approves the recipe source and payload source.

The app must reject:

- Unsigned indexes
- Invalid signatures
- Mismatched recipe checksums
- Recipes not listed in the verified index
- Loose cached recipes
- Stale, revoked, or deprecated recipes when marked unusable
- Alternate repositories
- Forks
- Mirrors
- User-selected recipe files

## Recipe Signing Tool

The recipe signing tool should be a small Swift command-line utility used by the Homebrew Assistant Recipes release process.

It should not be part of the shipped Homebrew Assistant.app runtime.

Recommended location:

```text
Homebrew Assistant Recipes/
└── Tools/
    └── RecipeSigner/
        ├── Package.swift
        └── Sources/
            └── RecipeSigner/
                └── main.swift
```

The tool should use CryptoKit Ed25519 signing through `Curve25519.Signing` to:

- Generate signing keys
- Sign `recipes.index.json`
- Verify signatures during release checks

The signature file should use a simple documented format containing at least:

- Algorithm
- Key ID
- Base64 signature

The tool must sign the exact index bytes that the app later verifies. It must not reserialize or pretty-print JSON during signing or verification.

## Key Handling

The public verification key and key identifier may be committed and compiled into Homebrew Assistant.

The private signing key must never be:

- Committed to Git
- Bundled with the app
- Logged
- Stored in the app repository
- Stored in `AppConstants.swift`
- Included in test fixtures that ship publicly

If the private key is lost, recipe updates cannot be signed with that key. If the private key is compromised, the app must rotate to a new public key through an app update and revoke trust in the compromised key.

## Local Cache Rules

The app may cache downloaded recipe metadata for performance and offline resilience, but cached recipes are not trusted merely because they are present on disk.

Before loading a cached dynamic recipe, the app must verify that:

- The signed index is valid.
- The recipe is listed in the verified index.
- The cached recipe bytes match the checksum in the verified index.
- The recipe has not been revoked or deprecated in a way that blocks use.

Manual local replacement of cached recipe files must fail verification.

## Failure Behavior

Recipe trust failures must fail safe.

When trust cannot be established, the app should:

- Reject the recipe or payload.
- Avoid downloading or staging untrusted content.
- Avoid extracting unsafe archive entries.
- Avoid writing outside app-controlled staging or the user-approved, validated SD card volume.
- Present an actionable user-facing error when the workflow is affected.
- Log a diagnostic event without leaking secrets or unnecessary personal data.

The app must not guess, fall back to loose local files, trust unvalidated selected volumes, or silently continue with unverified recipe metadata, unsafe archive contents, or unapproved destinations.
