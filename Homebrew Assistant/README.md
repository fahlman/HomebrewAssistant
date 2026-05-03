# Homebrew Assistant

Homebrew Assistant is a native macOS SwiftUI app for safely preparing a removable SD card for selected Wii homebrew.

The app guides users through a fixed workflow: verify required macOS permissions, select a real Secure Digital card, prepare selected items in temporary staging, review the planned SD card layout, then copy and verify files during the final write step.

## Project Status

Homebrew Assistant is in early development. The codebase is being built from project documentation and focused file-purpose contracts.

## Key Principles

- Native macOS app targeting macOS 14 Sonoma or newer.
- SwiftUI-first interface with native macOS APIs preferred over shell commands.
- No disk formatting, erasing, repartitioning, repairing, or destructive disk operations.
- Real SD-card detection is based on Disk Arbitration reporting the protocol name `Secure Digital`.
- Downloads, imports, extraction, validation, and prepared layouts happen in temporary staging.
- Files are copied to the selected SD card only during **Write and Verify Files**.
- Recipes are declarative instructions, not executable scripts.
- Ambiguous disk, permission, recipe, or source state fails safe.

## Documentation

Project documentation lives in `Docs/`:

- `Docs/ProjectSpec.md` — readable project specification
- `Docs/Architecture.md` — file responsibilities and dependency boundaries
- `Docs/RecipeTrustModel.md` — recipe, payload, signed-index, and key-handling rules
- `Docs/Workflow.md` — workflow steps, gating, button behavior, and session state
- `Docs/ProjectStructure.md` — planned folder and file layout

## Development Notes

The app should feel like a native macOS utility: calm, clear, opinionated, and difficult to misuse.

When in doubt, Homebrew Assistant should fail safe rather than guess.
