# Homebrew Assistant Specification

Homebrew Assistant is a macOS SwiftUI app that guides users through safely preparing a removable SD card for selected Wii homebrew workflows. The app should feel native, calm, and utility-focused while avoiding hidden side effects and unsafe shortcuts.

This document is the high-level product spec. It records the product’s goals, non-goals, major design decisions, and documentation sources of truth. Detailed workflow behavior, file ownership, project structure, and recipe trust rules live in their dedicated documents.

## Documentation Rule

Each topic should have one source of truth. Other documents may summarize a concept briefly, but they should reference the canonical document instead of duplicating detailed rules.

- User-visible workflow behavior belongs in `Workflow.md`.
- File ownership, dependency direction, and responsibility boundaries belong in `Architecture.md`.
- Folder and file hierarchy belongs in `ProjectStructure.md`.
- Recipe trust, signed index behavior, source policy, payload rules, archive trust, and internal workflow trust boundaries belong in `RecipeTrustModel.md`.
- Public security posture and vulnerability reporting belong in `SECURITY.md`.
- Contributor expectations and pull request process belong in `CONTRIBUTING.md`.
- Repository introduction, build/run basics, and links belong in `README.md`.

## Product Summary

Homebrew Assistant prepares a user-selected SD card for selected Wii homebrew workflows.

The app does not modify the user’s Mac broadly. It uses sandbox-friendly scoped filesystem access for the SD card volume the user chooses, validates that selected volume as Secure Digital media, prepares selected items in app-controlled staging, shows a reviewable write plan, writes only during the final write step, verifies copied files, and provides clear next-step guidance.

## Goals

- Build a macOS 14 Sonoma or newer SwiftUI app.
- Use native Apple/macOS APIs where possible.
- Use sandbox-friendly scoped filesystem access instead of requiring Full Disk Access.
- Validate the user-selected SD card volume as real Secure Digital media before allowing writes.
- Let the user choose which internal workflows and public recipes to prepare.
- Load public recipes from the verified Homebrew Assistant Recipes signed catalog.
- Keep Wilbrand and HackMii app-owned internal workflows even when presented beside public recipes.
- Stage all downloads, imports, extraction, validation, and prepared layouts before writing.
- Review the user-approved, validated SD card volume and write plan before copying files.
- Copy prepared files only during Write and Verify Files.
- Verify copied files after writing.
- Present clear success, next-step, and user-initiated eject guidance.

## Non-Goals

Homebrew Assistant must not:

- Require Full Disk Access for the preferred workflow.
- Inspect or depend on private TCC database state.
- Use shell commands or command-line fallbacks unless a future implementation review explicitly proves that a required task cannot be done safely with native APIs.
- Format, erase, repartition, repair, or destructively modify disks.
- Modify internal disks.
- Install directly to a console.
- Execute arbitrary recipe scripts.
- Accept arbitrary recipes or payloads from drag-and-drop, manually entered URLs, user-selected local files, alternative repositories, mirrors, or rehosts.
- Allow public recipes to add, replace, override, or modify app-owned internal/bootstrap workflows such as Wilbrand or HackMii.
- Write outside app-controlled staging directories or the user-approved, validated SD card volume.
- Automatically eject the SD card.
- Guess when disk, scoped-access, recipe, source, archive, signature, or verification metadata is ambiguous.

## Major Design Decisions

### Scoped SD Card Access

Homebrew Assistant’s preferred filesystem model is user-selected, scoped access to one SD card volume. The app validates that selected volume before enabling preparation or writes.

Detailed user-visible behavior is defined in `Workflow.md`. File ownership for scoped access and disk validation is defined in `Architecture.md`.

### Generated Workflow

The app uses a generated workflow based on the user’s selected items rather than a fixed sidebar containing every possible recipe.

At a high level, the flow is:

1. SD Card Selection
2. Choose Items
3. Prepare Selected Items
4. Review Setup
5. Write and Verify Files
6. Success / Next Steps

Detailed step behavior, button behavior, retry behavior, session state, and sidebar behavior are defined in `Workflow.md`.

### Internal Workflows and Public Recipes

Wilbrand and HackMii are app-owned internal/bootstrap workflows. They may be presented to the user beside public recipes in Choose Items, but they are not public recipes and are not controlled by Homebrew Assistant Recipes updates.

Public recipes come from the verified Homebrew Assistant Recipes signed catalog and describe only safe app-defined operations.

Detailed trust rules are defined in `RecipeTrustModel.md`. File ownership for internal workflows and recipe services is defined in `Architecture.md`.

### Staging Before Writing

Downloads, imports, extraction, validation, and preparation happen in app-controlled staging. The SD card is not written until the user reviews the write plan and starts Write and Verify Files.

Detailed workflow behavior is defined in `Workflow.md`. Staging, preparation, archive extraction, and write-service ownership are defined in `Architecture.md`.

### Fail-Safe Behavior

Ambiguous or failed disk validation, scoped access, recipe trust, source trust, archive extraction, signature verification, checksum verification, writing, or post-copy verification must fail safe with clear user-actionable messaging.

Detailed user-facing failure behavior is defined in `Workflow.md`. Detailed trust behavior is defined in `RecipeTrustModel.md`.

## Platform Standards

- Use Swift 6 and SwiftUI unless project build settings require otherwise.
- Target macOS 14 Sonoma or newer.
- Prefer native Apple/macOS APIs.
- Use AppKit bridging only where SwiftUI does not provide the required macOS behavior.
- Route user-facing text through localization resources such as `Localizable.xcstrings`.
- Store visual assets, semantic colors, app icons, and accent colors in `Assets.xcassets`.
- Use SF Symbols and asset-catalog imagery; do not use emoji as icons, graphics, or status indicators.
- Keep UI accessible with VoiceOver labels, keyboard navigation, sufficient contrast, clear focus order, and meaningful non-color state indicators.

## Safety Summary

Homebrew Assistant’s core safety promise is:

> Homebrew Assistant only writes reviewed, prepared files to the SD card the user selected after the app verifies that it is actually an SD card.

The detailed workflow safety checklist belongs in `Workflow.md`. The detailed recipe and source trust model belongs in `RecipeTrustModel.md`. Public security posture belongs in `SECURITY.md`.

## Documentation Sources of Truth

Use these documents as the canonical references:

| Topic | Source of truth |
| --- | --- |
| Product goals and major design decisions | `ProjectSpec.md` |
| Folder and file hierarchy | `ProjectStructure.md` |
| File ownership and dependency boundaries | `Architecture.md` |
| User-visible workflow behavior | `Workflow.md` |
| Recipe trust, signed index, source policy, and internal workflow trust boundaries | `RecipeTrustModel.md` |
| Public security posture and vulnerability reporting | `SECURITY.md` |
| Contributor process and pull request expectations | `CONTRIBUTING.md` |
| Repository introduction and build/run basics | `README.md` |
