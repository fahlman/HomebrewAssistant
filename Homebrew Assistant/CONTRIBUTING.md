#  <#Title#>


# Contributing to Homebrew Assistant

Thank you for your interest in Homebrew Assistant.

Homebrew Assistant is a safety-focused macOS utility. Contributions are welcome, but changes must preserve the project’s core guarantees: no destructive disk operations, no arbitrary script execution, no unsafe recipe intake, and no guessing when trust or device identity is ambiguous.

## Start Here

Before opening a pull request, read the project docs:

- `Docs/ProjectSpec.md` — project goals, scope, and safety rules
- `Docs/Architecture.md` — file responsibilities and dependency boundaries
- `Docs/RecipeTrustModel.md` — recipe, payload, signed-index, and key-handling rules
- `Docs/Workflow.md` — workflow steps, gating, button behavior, and session state
- `Docs/ProjectStructure.md` — planned folder and file layout

If your change affects architecture, workflow, security, recipes, disk behavior, or user trust, update the relevant documentation in the same pull request.

## What Contributions Are Welcome?

Good contributions include:

- Native macOS SwiftUI UI improvements
- Accessibility improvements
- Documentation improvements
- Tests for workflow, staging, source policy, checksum, extraction, disk detection, and permission behavior
- Safer diagnostics and clearer user-facing errors
- Refactors that improve separation of concerns without changing safety behavior
- Bug fixes that preserve fail-safe behavior

Future recipe contributions belong in the separate **Homebrew Assistant Recipes** repository, not directly in this app repository, unless the app itself needs schema, validation, UI, or trust-model changes.

## Core Safety Rules

Homebrew Assistant must never:

- Format, erase, repartition, repair, or destructively modify disks.
- Modify internal disks.
- Install directly to a console.
- Execute arbitrary recipe scripts.
- Trust arbitrary local recipes, drag-and-drop recipes, manually entered URLs, forks, mirrors, or rehosts.
- Write recipe files directly to the SD card during individual recipe steps.
- Automatically eject the SD card.
- Guess when disk, permission, recipe, source, checksum, archive, or signature metadata is ambiguous.

When in doubt, fail safe.

## Architecture Expectations

Swift files should have a focused purpose. Use the file header format from `Docs/Architecture.md` when useful:

```swift
//  Purpose: ...
//  Owns: ...
//  Does not own: ...
//  Delegates to: ...
```

Views should present state and collect user intent. Business logic belongs in coordinators, services, models, or utilities.

Avoid:

- Views that scan disks, download files, parse recipes, or write to storage
- Services that mix unrelated responsibilities
- `WorkflowCoordinator` performing service work directly instead of coordinating it
- `DownloadService` owning source trust, checksum policy, extraction policy, or workflow decisions
- `SourcePolicy` guessing official upstream sources at runtime
- Shell commands where native macOS APIs are available and reliable

## UI Guidelines

Homebrew Assistant should feel like a native macOS utility: calm, clear, opinionated, and difficult to misuse.

UI contributions should:

- Use SwiftUI-first native macOS patterns.
- Use a sidebar/detail workflow layout where appropriate.
- Keep non-passive or risky actions from becoming default buttons.
- Communicate state with text, SF Symbols, layout, and accessibility labels, not color alone.
- Use asset-catalog colors and icons.
- Use localization resources for user-facing text.
- Avoid emoji as icons, graphics, or status indicators.

## Disk and Permission Changes

Disk and permission behavior is security-sensitive.

Disk-related changes must preserve the rule that a valid SD-card candidate is accepted only when native Disk Arbitration metadata reports the protocol name exactly as:

```text
Secure Digital
```

Removable, ejectable, external, or writable traits may inform diagnostics, but they are not enough by themselves.

Full Disk Access detection uses the proven read-only sqlite3/TCC.db approach described in the docs. Contributions must never write to, modify, reset, repair, or otherwise change TCC.db.

## Recipe and Trust Changes

Recipe-related changes must follow `Docs/RecipeTrustModel.md`.

Important boundaries:

- Recipes are declarative app-defined instructions, not executable scripts.
- Public recipes must not declare browser-based exploit/bootstrap flows.
- Wilbrand and HackMii are app-owned internal/bootstrap workflows.
- Homebrew Assistant Recipes updates must never add, replace, override, or modify Wilbrand or HackMii.
- Future dynamic recipes must be trusted only through a verified signed Ed25519 recipe index.
- Loose cached recipes must not be trusted merely because they exist on disk.
- Private signing keys must never be committed, bundled, logged, or stored in the app repository.

## Tests

Add or update tests when changing logic-heavy or safety-sensitive code.

Prioritize tests for:

- Disk classification using injected or fixture metadata
- Full Disk Access state mapping and fail-safe behavior
- Workflow gating and navigation
- SourcePolicy trust decisions
- Signed-index validation behavior
- RecipeLoader validation and rejection behavior
- Checksum verification
- Archive extraction safety
- Staging cleanup boundaries
- SD write planning and verification
- Persistence boundaries
- Localization coverage

Tests should not require physical SD cards, USB drives, external SSDs, disk images, or network volumes when fixture metadata can verify the behavior.

## Pull Request Checklist

Before opening a pull request, check that your change:

- Preserves the core safety rules.
- Keeps file responsibilities focused.
- Updates docs when behavior or architecture changes.
- Uses localized strings for user-facing text.
- Avoids raw colors outside asset catalogs.
- Avoids shell commands unless a native API is unavailable or clearly unsuitable.
- Adds tests for safety-sensitive or logic-heavy behavior.
- Does not introduce arbitrary recipe execution or untrusted recipe intake.
- Does not add destructive disk operations.
- Does not persist session-scoped workflow state across launches.
- Does not include secrets, private keys, or sensitive local paths.

## Commit Messages

Use concise, descriptive commit messages.

Examples:

```text
Create initial SwiftUI app shell
Document recipe trust model
Add disk metadata fixture tests
Refine workflow step state model
```

## Reporting Security Concerns

If you notice a possible security issue, unsafe trust path, disk-safety problem, recipe-tampering path, or privacy concern, raise it clearly before implementation proceeds.

Security concerns are not bikeshedding. They are part of the product design.

# Contributing to Homebrew Assistant

Thank you for your interest in Homebrew Assistant.

Homebrew Assistant is a safety-focused macOS utility. Contributions are welcome, but changes must preserve the project’s core guarantees: no destructive disk operations, no arbitrary script execution, no unsafe recipe intake, no broad filesystem access by default, and no guessing when trust, scoped access, verification, archive safety, or device identity is ambiguous.

## Start Here

Before opening a pull request, read the project docs:

- `Docs/Specification.md` — product goals, scope, non-goals, major design decisions, and documentation sources of truth
- `Docs/Architecture.md` — file responsibilities, dependency direction, and responsibility boundaries
- `Docs/Structure.md` — planned folder and file layout
- `Docs/Workflow.md` — generated workflow behavior, step behavior, button behavior, retry behavior, and session state
- `Docs/RecipeTrustModel.md` — recipe, payload, signed-index, archive-safety, internal workflow, source-policy, and key-handling rules
- `SECURITY.md` — public security posture and vulnerability reporting guidance

Each topic should have one source of truth. Do not duplicate detailed rules across documents. If your change affects architecture, workflow, security, recipes, disk behavior, scoped access, or user trust, update the relevant source-of-truth document in the same pull request.

## What Contributions Are Welcome?

Good contributions include:

- Native macOS SwiftUI UI improvements
- Accessibility improvements
- Documentation improvements
- Tests for workflow, staging, source policy, signed index verification, checksum verification, extraction safety, disk validation, scoped access, and persistence boundaries
- Safer diagnostics and clearer user-facing errors
- Refactors that improve separation of concerns without changing safety behavior
- Bug fixes that preserve fail-safe behavior

Public recipe contributions belong in the separate **Homebrew Assistant Recipes** repository, not directly in this app repository, unless the app itself needs schema, validation, UI, source-policy, signing, or trust-model changes.

## Core Safety Rules

Homebrew Assistant must never:

- Require Full Disk Access for the preferred workflow.
- Inspect or depend on private TCC database state.
- Format, erase, repartition, repair, or destructively modify disks.
- Modify internal disks.
- Install directly to a console.
- Execute arbitrary recipe scripts.
- Trust arbitrary local recipes, drag-and-drop recipes, manually entered URLs, forks, mirrors, rehosts, or loose cached recipe files.
- Allow public recipes to add, replace, override, or modify app-owned internal/bootstrap workflows such as Wilbrand or HackMii.
- Write recipe or prepared files directly to the SD card during preparation steps.
- Write outside app-controlled staging directories or the user-approved, validated SD card volume.
- Automatically eject the SD card.
- Guess when disk, scoped-access, recipe, source, checksum, archive, signature, or verification metadata is ambiguous.

When in doubt, fail safe.

## Architecture Expectations

Swift files should have a focused purpose. Follow the ownership boundaries, dependency direction, and file header expectations in `Docs/Architecture.md`.

Views should present state and collect user intent. Business logic belongs in coordinators, services, models, or utilities.

Avoid:

- Views that scan disks, download files, parse recipes, or write to storage
- Services that mix unrelated responsibilities
- `WorkflowCoordinator` performing service work directly instead of coordinating it
- Views or `WorkflowCoordinator` manually sequencing download, checksum, extraction, and staging instead of delegating preparation to `ItemPreparationService`
- Internal workflow views bypassing `ItemPreparationService` to call low-level download, checksum, archive extraction, or staging services directly
- `DownloadService` owning source trust, checksum policy, extraction policy, or workflow decisions
- `SourcePolicy` guessing official upstream sources at runtime
- Shell commands or command-line fallbacks unless a future implementation review explicitly proves that a required task cannot be done safely with native APIs

## UI Guidelines

Homebrew Assistant should feel like a native macOS utility: calm, clear, opinionated, and difficult to misuse.

UI contributions should:

- Use SwiftUI-first native macOS patterns.
- Use the generated sidebar/detail workflow layout defined in `Docs/Workflow.md`.
- Keep non-passive or risky actions from becoming default buttons.
- Communicate state with text, SF Symbols, layout, and accessibility labels, not color alone.
- Use asset-catalog colors and icons.
- Use localization resources for user-facing text.
- Avoid emoji as icons, graphics, or status indicators.

## Disk and Scoped Access Changes

Disk and scoped-access behavior is security-sensitive.

Homebrew Assistant’s preferred filesystem model is user-selected, scoped access to one SD card volume. Selection grants scoped filesystem access; Disk Arbitration validation determines SD card eligibility.

Disk-related changes must preserve the rule that a valid SD card candidate is accepted only when native Disk Arbitration metadata reports the protocol name exactly as:

```text
Secure Digital
```

Removable, ejectable, external, or writable traits may inform diagnostics, but they are not enough by themselves.

The app must not request broad Full Disk Access for the preferred workflow. It must not inspect, read, write, modify, reset, repair, or otherwise depend on private TCC database state.

## Recipe and Trust Changes

Recipe-related changes must follow `Docs/RecipeTrustModel.md`.

Important boundaries:

- Public recipes are declarative app-defined instructions, not executable scripts.
- Public recipes must be loaded only through the verified Homebrew Assistant Recipes signed catalog.
- Public recipes must not declare browser-based exploit/bootstrap flows.
- Public recipes must not request user-selected local files.
- Wilbrand and HackMii are app-owned internal/bootstrap workflows.
- Homebrew Assistant Recipes updates must never add, replace, override, or modify Wilbrand or HackMii.
- Loose cached recipes must not be trusted merely because they exist on disk.
- Archive extraction must enforce destination containment before writing extracted files.
- Private signing keys must never be committed, bundled, logged, or stored in the app repository.

## Tests

Add or update tests when changing logic-heavy or safety-sensitive code.

Prioritize tests for:

- Disk classification using injected or fixture metadata
- Scoped-access lifecycle behavior
- Workflow availability and navigation
- SourcePolicy trust decisions
- Signed recipe index verification behavior
- RecipeCatalogLoader unavailable, invalid, and empty catalog behavior
- ItemPreparationService preparation sequencing and failure mapping
- RecipeLoader validation and rejection behavior
- Checksum verification
- Archive extraction safety, including Zip Slip prevention and destination containment
- Staging cleanup boundaries
- SD write planning and verification
- Persistence boundaries
- Localization coverage

Tests should not require physical SD cards, USB drives, external SSDs, disk images, or network volumes when fixture metadata can verify the behavior.

## Pull Request Checklist

Before opening a pull request, check that your change:

- Preserves the core safety rules.
- Keeps file responsibilities focused and consistent with `Docs/Architecture.md`.
- Updates the correct source-of-truth doc when behavior, architecture, workflow, structure, or trust rules change.
- Uses localized strings for user-facing text.
- Avoids raw colors outside asset catalogs.
- Avoids shell commands unless a future implementation review explicitly approves the exception.
- Adds tests for safety-sensitive or logic-heavy behavior.
- Does not introduce arbitrary recipe execution or untrusted recipe intake.
- Does not add destructive disk operations.
- Does not persist session-scoped workflow state across launches.
- Does not persist selected SD cards, granted mounted paths, active scoped-access state, downloads, staged files, prepared layouts, or write manifests across launches.
- Does not include secrets, private keys, or sensitive local paths.

## Commit Messages

Use concise, descriptive commit messages.

Examples:

```text
Create initial SwiftUI app shell
Document recipe trust model
Add disk metadata fixture tests
Refine workflow step state model
```

## Reporting Security Concerns

If you notice a possible security issue, unsafe trust path, disk-safety problem, recipe-tampering path, scoped-access problem, archive traversal issue, or privacy concern, raise it clearly before implementation proceeds.

Security concerns are not bikeshedding. They are part of the product design.
