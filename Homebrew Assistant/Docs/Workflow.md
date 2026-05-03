# Workflow

Homebrew Assistant uses a generated, user-driven workflow to prepare a removable SD card for selected Wii homebrew workflows. The app guides the user from SD card selection through item selection, preparation, review, writing, verification, and success.

This document is the source of truth for user-visible workflow behavior: step order, screen behavior, button behavior, sidebar behavior, retry behavior, and session state. File ownership belongs in `Architecture.md`; recipe trust and signing rules belong in `RecipeTrustModel.md`.

The workflow must avoid hidden side effects. The app should not scan, download, write, delete, eject, open external tools, or change device state without clear UI state and user intent.

## Workflow Overview

The v1 workflow is generated from user choices:

1. SD Card Selection
2. Choose Items
3. Prepare Selected Items
4. Review Setup
5. Write and Verify Files
6. Success / Next Steps

There is no Full Disk Access step. Homebrew Assistant does not prompt the user to open System Settings for broad disk access. The user grants access only to the SD card volume they choose through the normal macOS selection flow.

Unselected optional items are not shown as skipped workflow steps. They simply do not appear in the generated workflow.

Progression is enabled only when required state exists, such as a validated SD card, at least one selected item, and a prepared/reviewed manifest.

## Layout Model

Homebrew Assistant uses a native macOS sidebar/detail layout.

- The left sidebar lists generated workflow steps in safe app-defined order and communicates each step’s state.
- The right detail pane shows the selected step content.
- A bottom navigation bar provides step-specific actions.
- SD Card Selection starts the workflow and may offer Quit in the lower-left if appropriate.
- Later reachable screens use Back in the lower-left.
- Lower-right buttons are step-specific.

Step state must be communicated through text, SF Symbols, layout, and accessibility labels, not color alone.

## Button Rules

Non-passive or risky actions are never default buttons.

Examples of non-default actions:

- Choose SD Card…
- Open Browser
- Choose File…
- Download
- Retry Catalog Load
- Open Disk Utility
- Write
- Eject
- Continue from destructive-warning dialogs

Navigation buttons should communicate what happens next. Preparation steps enable Next only after the selected item has been successfully prepared or the workflow no longer needs that item.

There is no Skip-as-default model. Users choose items up front in Choose Items. Items not selected are omitted from the generated workflow instead of appearing as skipped steps.

## Step States

Workflow state should distinguish concepts such as:

- Unavailable
- Not started
- In progress
- Preparing
- Prepared
- Completed
- Failed

Do not collapse visibility, requiredness, reachability, completion, and availability into a single ambiguous concept.

Unavailable steps are not permission gates. Progression is enabled when the required state for the next action exists.

## 1. SD Card Selection

SD Card Selection is the first normal workflow step.

The preferred flow is user selection followed by app validation. The user selects the intended mounted SD card volume once through a sandbox-compatible system access flow. Homebrew Assistant receives scoped access to that selected volume and then validates that exact selected mounted volume using native Disk Arbitration metadata before enabling preparation or writes.

A selected volume is accepted only when Disk Arbitration reports its protocol name exactly as:

```text
Secure Digital
```

Selection grants scoped filesystem access. Disk Arbitration validation determines eligibility.

This step:

- Provides Choose SD Card… as the primary non-default action.
- May provide Open Disk Utility for formatting, erasing, partitioning, or repair outside Homebrew Assistant.
- Keeps progression unavailable until the user-selected volume is validated as a writable Secure Digital card.
- Shows clear validation results and user-actionable errors.

The app must reject generic USB drives, external SSDs, internal disks, disk images, network volumes, and ambiguous devices whose Secure Digital identity cannot be confirmed.

The app must not trust a volume merely because the user selected it. If the selected volume is not confirmed as Secure Digital, the app should show a clear explanation and keep progression unavailable.

Non-FAT32 SD cards are not formatted by Homebrew Assistant. The app may guide the user to Disk Utility with clear warning text.

## 2. Choose Items

Choose Items lets the user decide what to prepare.

The list combines two sources:

- App-owned internal workflows, such as Wilbrand and HackMii.
- Public recipes loaded from the verified Homebrew Assistant Recipes catalog.

Wilbrand and HackMii may appear alongside public recipe choices, but they remain app-owned internal workflows controlled by bundled Homebrew Assistant app code. They are not public recipes and cannot be modified by Homebrew Assistant Recipes updates.

Public recipes appear only after the signed Homebrew Assistant Recipes catalog has been loaded and verified.

If the public recipe catalog is unavailable, invalid, or empty:

- Internal workflows remain available.
- The public recipe area shows an actionable unavailable state.
- The user may retry catalog loading.
- The user may continue with internal workflows only if at least one internal workflow is selected.

The app should not show unverified public recipes as selectable.

After the user confirms selected items, the sidebar/workflow is generated from the selected items in a safe app-defined order.

If the user returns to Choose Items and changes the selected item list, Homebrew Assistant must update the generated workflow to match the new selection. Items removed from the selection are removed from the workflow, and their prepared state, staged outputs, and manifest entries are discarded from the active session.

## 3. Prepare Selected Items

Prepare Selected Items represents the preparation steps for the items the user selected.

The generated workflow includes only selected items. Preparation steps may include:

- Wilbrand preparation
- HackMii preparation
- Public recipe preparation, such as Priiloader, d2x cIOS, USB Loader GX, or future verified public recipes

Preparation happens in app-controlled staging. No files are written to the SD card during preparation.

Preparation may involve:

- Opening an approved browser page
- Selecting a generated file through a controlled macOS file picker
- Downloading an approved payload
- Verifying checksums
- Extracting archives with path-containment checks
- Rejecting unsafe archive entries
- Staging prepared files
- Producing prepared item metadata for Review Setup

Preparation is coordinated by `ItemPreparationService`. Views should present state and user intent; they should not manually sequence download, checksum, extraction, and staging.

## Wilbrand Preparation

Wilbrand is an optional app-owned internal workflow item.

Wilbrand does not provide a direct Download button because the user must visit the approved Wilbrand webpage and enter Wii-specific information to generate a custom exploit archive.

When selected, the Wilbrand preparation step:

- Provides a non-default Open Browser button.
- Enables a non-default Choose File… button when appropriate.
- Uses a controlled macOS file picker for the generated archive.
- Does not allow drag-and-drop file intake.
- Validates the selected archive for expected Wilbrand output shape.
- Rejects unsafe paths, symlinks, hard links, absolute paths, and traversal attempts during validation/extraction.
- Stages the validated result in the session temporary directory only.
- Enables Next after successful validation and staging.

No Wilbrand files are written to the SD card until Write and Verify Files.

## HackMii Preparation

HackMii is an optional app-owned internal/bootstrap workflow item.

When selected, the HackMii preparation step:

- Presents the approved HackMii source and instructions.
- Provides a non-default Download action when applicable.
- Downloads only from the app-approved HackMii source.
- Verifies expected files and checksums when available.
- Stages downloaded and verified content only.
- Enables Next after successful preparation.

No HackMii files are written to the SD card until Write and Verify Files.

## Public Recipe Preparation

Public recipe preparation steps are generated from verified public recipe metadata.

When selected, a public recipe step:

- Presents localized recipe title, summary, instructions, warnings, and status.
- Provides a non-default Download action when applicable.
- Downloads only from the recipe’s approved upstream source.
- Verifies downloaded content against trusted metadata.
- Extracts archives safely when required.
- Stages prepared files in the active session directory.
- Enables Next after successful preparation.

Public recipe steps must not execute arbitrary scripts, request user-selected local files, declare browser actions, or perform internal/bootstrap behavior.

No public recipe files are written to the SD card until Write and Verify Files.

## 4. Review Setup

Review Setup summarizes the complete write plan before any files are copied to the SD card.

This step should display:

- User-approved, validated SD card name
- Granted mounted volume path or display location
- Capacity and free space
- Selected/prepared internal workflows and public recipes
- Staged files to be copied
- Destination paths
- Required space
- Overwrite warnings
- Verification expectations
- Any relevant source or trust warnings

The app must clearly identify the target volume and any overwrite risk before writing begins.

Review Setup must never rely on stale manifests from previous app launches.

The Write action is non-default because it changes files on removable storage.

## 5. Write and Verify Files

Write and Verify Files is the only step that copies prepared files to the user-approved, validated SD card volume.

This step:

- Uses the current session manifest.
- Copies from the prepared staging layout to the user-approved, validated SD card volume.
- Limits writes to the approved SD card volume destination.
- Shows per-file and overall progress.
- Shows the current operation.
- Performs post-copy verification.
- Reports recoverable and fatal errors.
- Supports cancellation when safe.
- Writes diagnostics for troubleshooting.

This step must not format, erase, repartition, repair, or modify disk structure.

Verification is part of this step in v1 rather than a separate sidebar step.

## 6. Success / Next Steps

Success confirms that writing and verification completed.

This step should display:

- Completion confirmation
- Included/prepared items
- Verification status
- User-approved, validated SD card name
- Clear next-step instructions
- User-initiated Eject button
- Start New Workflow action

Eject is never the default button because it changes device state.

If eject succeeds:

- Confirm it is safe to remove the SD card.
- Disable the Eject action.

If eject fails:

- Show an actionable error.
- Explain that another app may be using the SD card.
- Suggest closing Finder windows or other apps using the card.
- Allow retry.
- Remind the user they can eject manually in Finder.

Starting a new workflow clears session-scoped state, active scoped-access state, and staging data, then returns to SD Card Selection.

## Session State

Workflow execution state is session-scoped.

Changing the selected item list during the active session invalidates preparation state for removed items. Removed items must not remain in Review Setup, Write and Verify Files, diagnostics summaries, or the final success summary.

The app must not persist across launches:

- Selected SD card identity
- Granted mounted volume paths or active scoped-access state
- Downloaded payloads
- Extracted archives
- Wilbrand imports
- Prepared SD layouts
- Write manifests
- Write session state

On launch, the app starts fresh at SD Card Selection.

## Failure and Retry Behavior

Failure states should be actionable.

The app should explain:

- What failed
- Why the app cannot continue yet
- What the user can do next
- Whether retrying is safe

Examples:

- Invalid selected volume: choose a different SD card or open Disk Utility.
- Public recipe catalog unavailable: retry catalog loading or continue with internal workflows only.
- Download failure: retry download when safe.
- Checksum mismatch: reject the payload and require a fresh trusted download.
- Unsafe archive entry: reject extraction and avoid staging unsafe content.
- Write failure: stop safely, report the affected file, and avoid pretending the workflow succeeded.
- Verification failure: report the mismatch and show troubleshooting guidance.
- Eject failure: allow retry and suggest manual Finder eject.

The app must never silently continue after a trust, validation, extraction, write, or verification failure.

## Safety Principles

The workflow should follow these principles:

- No Full Disk Access gate.
- No hidden permission maze.
- User selection grants scoped filesystem access; Disk Arbitration validation determines SD card eligibility.
- Internal workflows and public recipes are selected up front in Choose Items.
- Unselected optional items do not appear as skipped workflow steps.
- Preparation steps never write directly to the SD card.
- Downloads, imports, extraction, and validation happen in staging.
- Archive extraction must enforce destination containment before writing extracted files.
- The final write happens only after Review Setup and only to the user-approved, validated SD card volume.
- Risky actions require clear user intent and are never default buttons.
- Destructive disk operations are out of scope.
- Ambiguous disk, scoped-access, recipe, source, archive, signature, or verification state fails safe.
