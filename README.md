# Homebrew Assistant

Homebrew Assistant is a native macOS SwiftUI app for safely preparing a removable SD card for selected Wii homebrew workflows.

The app helps users choose an SD card, choose which internal workflows and public recipes to prepare, stage and verify files safely, review the planned SD card layout, then write and verify files during the final write step.

## Project Status

Homebrew Assistant is in early development. The codebase is being built from project documentation, focused file-purpose contracts, and safety-first workflow rules.

## What It Does

At a high level, Homebrew Assistant guides users through:

1. Selecting an SD card volume.
2. Choosing app-owned internal workflows and verified public recipes.
3. Preparing selected items in app-controlled staging.
4. Reviewing the target SD card and write plan.
5. Writing and verifying files.
6. Showing success, next steps, and user-initiated eject guidance.

There is no Full Disk Access gate in the preferred workflow. The app uses sandbox-friendly scoped filesystem access for the SD card volume the user chooses, then validates that selected volume as Secure Digital media before enabling writes.

## Key Principles

- Native macOS app targeting macOS 14 Sonoma or newer.
- SwiftUI-first interface with native macOS APIs preferred.
- No broad Full Disk Access requirement for the preferred workflow.
- No TCC database inspection.
- No shell commands or command-line fallbacks unless a future implementation review explicitly proves that a required task cannot be done safely with native APIs.
- No disk formatting, erasing, repartitioning, repairing, or destructive disk operations.
- Real SD-card detection is based on Disk Arbitration reporting the protocol name `Secure Digital`.
- Downloads, imports, extraction, validation, and prepared layouts happen in app-controlled staging.
- Files are copied to the selected, validated SD card only during **Write and Verify Files**.
- Public recipes are declarative instructions, not executable scripts.
- Public recipes are Homebrew Assistant Property List files, not Wii homebrew apps.
- Homebrew refers to Wii homebrew apps and related files that run on a modified Wii.
- Homebrew payloads referenced by recipes may be ZIP archives hosted by non-affiliated or third-party upstream sources, often also on GitHub.
- Public recipes are loaded through the verified Homebrew Assistant Recipes signed catalog.
- Wilbrand and HackMii remain app-owned internal/bootstrap workflows.
- Ambiguous disk, scoped-access, recipe, source, archive, signature, or verification state fails safe.

## Documentation

Project documentation lives in `Docs/`:

- `Docs/Specification.md` — product goals, non-goals, major design decisions, and documentation sources of truth
- `Docs/Structure.md` — planned folder and file layout
- `Docs/Architecture.md` — file responsibilities, dependency direction, and responsibility boundaries
- `Docs/Workflow.md` — generated workflow behavior, step behavior, button behavior, retry behavior, and session state
- `Docs/RecipeTrustModel.md` — recipe, payload, signed-index, archive-safety, internal workflow, source-policy, and key-handling rules

Public security posture and vulnerability reporting are documented in `SECURITY.md`.

Contributor expectations and pull request guidance are documented in `CONTRIBUTING.md`.

## Development Notes

The app should feel like a native macOS utility: calm, clear, opinionated, and difficult to misuse.

When in doubt, Homebrew Assistant should fail safe rather than guess.
