# Homebrew Assistant — Repository Instructions

Read the shared `AGENTS.md` first. These instructions apply to the Homebrew
Assistant app in `fahlman/Homebrew-Assistant`.

## Purpose and ownership

- This SwiftUI macOS app prepares a user-selected SD card for Wii homebrew.
  App-owned workflow controllers coordinate selection, validation, preparation,
  and saving; views present that workflow.
- Public recipes are declarative metadata from the official verified catalog.
  Recipe authoring belongs in the separate Homebrew Assistant Recipes repository.
- Read `README.md`, `CONTRIBUTING.md`, and the specifications under
  `Homebrew Assistant/Docs/`: `Specification.md`, `Architecture.md`,
  `Workflow.md`, and `RecipeTrustModel.md`.

## Product constraints

- Restrict writes to the validated SD volume chosen by the user, using scoped
  access. Disk Arbitration metadata must identify the supported Secure Digital
  device; uncertain device identity, paths, or trust must fail closed.
- Do not format, erase, repartition, repair, or write to internal disks. Saving
  requires the user's explicit action; ejecting remains a user action.
- Do not add arbitrary recipe scripting, local untrusted recipe import, a Full
  Disk Access gate, or inspection of private TCC databases. The current README
  and the later scoped-access section of `CONTRIBUTING.md` describe this model;
  the earlier duplicated Full Disk Access guidance in that file is obsolete.
- Route preparation through the existing preparation service and workflow
  owners. Keep session-only selection, scoped access, downloads, and preparation
  state within the current session, as described in `CONTRIBUTING.md`.
- Preserve checksum verification, catalog trust, and archive/path containment.
  Wilbrand and HackMii preparation have app-owned workflows and focused tests.

## Project and verification

- Use `Homebrew Assistant.xcodeproj`, its shared `Homebrew Assistant` scheme,
  and `Homebrew Assistant.xctestplan`. Test targets are
  `Homebrew AssistantTests` and `Homebrew AssistantUITests`.
- Choose relevant existing workflow, disk validation, preparation, and
  localization tests. Use injected disk metadata and services for verification;
  do not make a real SD-card write part of an ordinary automated test.

## Toolchain and platforms

Settings inspected on 2026-09-25 in `Homebrew Assistant.xcodeproj/project.pbxproj`.

- Selected local tools: Xcode 27.0 (`27A266a`), Apple Swift 6.4
  (`swiftlang-6.4.0.34.1`). These exact versions are not pinned by the project.
- Swift language mode: 6.0 (`SWIFT_VERSION`) for all Swift targets.
- SDK: `SDKROOT = macosx`, with no SDK version pin; the selected macOS SDK is 27.0.
- Deployment targets: macOS 26.4 for the app and both test targets.

The selected local tools are a dated snapshot. Existing project settings describe
current configuration; they do not override the shared latest-stable policy.
Handle upgrades as separate tasks.
