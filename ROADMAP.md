# Homebrew Assistant Roadmap

## 1.0 — Internal Workflows

Goal: Ship a complete macOS app that writes built-in Homebrew workflows to a user-selected SD card.

Scope:

- Sign and notarize the app for Developer ID distribution.
- Add Sparkle auto-update before the first public release.
- Grant disk access through the macOS file picker.
- Validate that the selected drive is a writable SD card.
- Show no-selection, invalid-drive, and valid-SD-card states clearly.
- Let the user choose built-in Homebrew workflows.
- Stage internal workflow files.
- Write staged files to the SD card.
- Verify the written files.
- Open the selected SD card in Finder.
- Eject the selected SD card after writing succeeds.
- Show clear success and failure recovery messaging.

Out of scope:

- App Sandbox.
- Public recipe handling.
- Public recipe catalog updates.

## 1.1 — App Sandbox

Goal: Ship the same internal-workflow feature set with App Sandbox enabled.

Scope:

- Enable App Sandbox.
- Keep user-selected read/write access working for the SD card.
- Confirm scoped access lifecycle works during validation, staging, writing, verifying, Finder open, and eject flows.
- Add security-scoped bookmarks only if persistence across launches becomes necessary.
- Re-test the full 1.0 internal-workflow write path under sandbox rules.

Out of scope:

- Public recipe handling.
- Public recipe catalog updates.

## 1.2 — Public Recipes

Goal: Download, verify, parse, stage, write, and verify public Homebrew Assistant recipes from the Homebrew Assistant Recipes repo.

Definitions:

- Recipes are Homebrew Assistant Property List files hosted in the Homebrew Assistant Recipes GitHub repository.
- Recipes describe what should be added to a workflow and where those files should be staged on the SD card.
- Homebrew refers to Wii homebrew apps and related files that run on a modified Wii.
- Homebrew files are often ZIP archives hosted by non-affiliated or third-party sources, often also on GitHub.
- A recipe may reference one or more Homebrew items, but the recipe itself is not the Homebrew app.

Scope:

- Load the public recipe catalog.
- Verify recipe catalog trust.
- Download recipe files into app-controlled storage.
- Verify recipe checksums/signatures before parsing or staging.
- Parse Homebrew Assistant recipe files.
- Download any Homebrew files referenced by selected recipes from their upstream third-party sources.
- Verify downloaded Homebrew files before staging.
- Extract Homebrew archives through a dedicated archive extraction service.
- Stage parsed recipe output.
- Write staged Homebrew files to the SD card.
- Verify written Homebrew files.
- Keep recipes as verified data only; do not run scripts or executable recipe logic.

Out of scope:

- Running recipe scripts or executable recipe logic.
- Treating recipes themselves as Wii homebrew apps.

## 1.3 — Final Polish and Maintenance

Goal: Finish the app with polish, diagnostics, and final bug fixes.

Scope:

- Improve diagnostics and support-log export.
- Improve failure recovery messages.
- Polish release notes and update messaging.
- Fix issues discovered from 1.0 through 1.2.
- Keep the app focused on macOS-only Homebrew Assistant workflows.

Out of scope:

- New major feature areas.
