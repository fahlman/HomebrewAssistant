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
